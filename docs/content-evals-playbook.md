---
tags: [playbook, evals, content, gj26]
---

# Content Evals Playbook

How to run **evals on game content output** — items, NPCs, enemies, story — to keep them consistent, balanced, and on-voice as we generate at scale.

This applies the [[evals-and-harnesses-research|2026 eval discipline]] to gj26's [[content-generation-playbook|content pipeline]]. The premise from the research:

> *Evals are product specs. They make fuzzy goals concrete. Code-based when verifiable, LLM-grader when not. Grade the trace, not just the output. Cross-model graders. Eval the system, not the model. Continuous post-launch.*

We translate every one of those rules to game content.

---

## 1. The five layers of content evals

Game content has five orthogonal failure modes. Each gets its own eval layer, each cheap to add.

| Layer | What fails | Eval kind |
|---|---|---|
| **1. Schema** | Missing required field, wrong type, duplicate ID | **Code-based** (cheap, run on every change) |
| **2. Tier conformance** | Stats over/under tier budget | **Code-based** |
| **3. Cross-reference integrity** | Item/NPC/monster ID referenced but doesn't exist | **Code-based** |
| **4. Voice & style** | Description doesn't match the game's voice | **LLM-grader** (with sample auditing) |
| **5. Lore & worldbuilding** | Item / character contradicts established lore | **LLM-grader** + WORLD_BIBLE.md context |

Plus two cross-cutting:

| Layer | What it checks | Eval kind |
|---|---|---|
| **Balance sim** | TTK / win rate / progression pacing | **Code-based** Monte Carlo simulation |
| **Soul check** | Does the content evoke the intended feelings? | **LLM-grader** using [[evoke-online-game-feel|the rubric]] |

Run the cheap ones (1, 2, 3) on every change in CI. Run the expensive ones (4, 5, balance, soul) on each new batch of generated content before shipping.

---

## 2. Layer 1 — Schema evals (code-based)

The cheapest eval. Runs in <1 second. Catches silent bugs.

```js
// evals/schema.eval.js
import { ITEMS } from '../src/data/items.js';

const REQUIRED_ITEM_FIELDS = ['name', 'icon', 'stack', 'desc'];
const VALID_SLOTS = ['weapon', 'body', 'shield', 'helmet', 'boots', 'cape'];

export function evalItemSchema() {
  const errors = [];
  const seenIds = new Set();
  
  for (const [id, item] of Object.entries(ITEMS)) {
    // ID format
    if (!/^[a-z0-9_]+$/.test(id)) {
      errors.push(`item ${id}: id must be snake_case`);
    }
    if (seenIds.has(id)) {
      errors.push(`item ${id}: duplicate id`);
    }
    seenIds.add(id);
    
    // Required fields
    for (const field of REQUIRED_ITEM_FIELDS) {
      if (item[field] === undefined) {
        errors.push(`item ${id}: missing field "${field}"`);
      }
    }
    
    // Type checks
    if (typeof item.name !== 'string') errors.push(`item ${id}: name must be string`);
    if (typeof item.stack !== 'boolean') errors.push(`item ${id}: stack must be boolean`);
    
    // Slot validity
    if (item.slot && !VALID_SLOTS.includes(item.slot)) {
      errors.push(`item ${id}: invalid slot "${item.slot}"`);
    }
    
    // equipBonus shape
    if (item.equipBonus) {
      const { atk, str, def } = item.equipBonus;
      if (typeof atk !== 'number' || typeof str !== 'number' || typeof def !== 'number') {
        errors.push(`item ${id}: equipBonus must have atk/str/def numbers`);
      }
    }
    
    // Description length sanity
    if (item.desc && item.desc.length < 10) {
      errors.push(`item ${id}: desc too short (likely placeholder)`);
    }
    if (item.desc && item.desc.length > 250) {
      errors.push(`item ${id}: desc too long (cozy items want 1-2 sentences)`);
    }
  }
  
  return errors;
}
```

Run as part of the build:

```bash
node evals/schema.eval.js  # exits non-zero if any errors
```

**Always run on every commit.** This is cheap; failures here are silent runtime bugs.

---

## 3. Layer 2 — Tier conformance (code-based)

The tier tables in [[content-generation-playbook]] §2 are the spec. Validate that nothing exceeds them.

```js
// evals/tier-budget.eval.js
import { ITEMS } from '../src/data/items.js';

const WEAPON_TIER_BUDGET = {
  bronze: 3, iron: 6, steel: 9, mithril: 12, adamant: 15, rune: 18,
};
const BODY_TIER_BUDGET = {
  bronze: 2, iron: 4, steel: 6, mithril: 8, adamant: 10, rune: 12,
};
const SHIELD_TIER_BUDGET = {
  bronze: 1, iron: 2, steel: 3, mithril: 4, adamant: 5, rune: 6,
};

const TIER_LEVEL_RANGE = {
  bronze:  [1, 15],
  iron:    [15, 30],
  steel:   [30, 45],
  mithril: [45, 60],
  adamant: [60, 75],
  rune:    [75, 99],
};

export function evalTierBudget() {
  const errors = [];
  
  for (const [id, item] of Object.entries(ITEMS)) {
    if (!item.tier) continue;
    
    const tier = item.tier;
    const e = item.equipBonus || { atk: 0, str: 0, def: 0 };
    
    // Weapon budget = atk + str
    if (item.slot === 'weapon') {
      const total = e.atk + e.str;
      const budget = WEAPON_TIER_BUDGET[tier];
      if (total !== budget) {
        errors.push(`item ${id}: weapon tier "${tier}" expects atk+str=${budget}, got ${total}`);
      }
    }
    
    // Body budget = def
    if (item.slot === 'body') {
      const budget = BODY_TIER_BUDGET[tier];
      if (e.def !== budget) {
        errors.push(`item ${id}: body tier "${tier}" expects def=${budget}, got ${e.def}`);
      }
    }
    
    // Shield budget = def
    if (item.slot === 'shield') {
      const budget = SHIELD_TIER_BUDGET[tier];
      if (e.def !== budget) {
        errors.push(`item ${id}: shield tier "${tier}" expects def=${budget}, got ${e.def}`);
      }
    }
    
    // reqLevel within tier range
    if (item.reqLevel !== undefined) {
      const [min, max] = TIER_LEVEL_RANGE[tier] || [1, 99];
      if (item.reqLevel < min || item.reqLevel > max) {
        errors.push(`item ${id}: reqLevel ${item.reqLevel} outside tier "${tier}" range [${min}, ${max}]`);
      }
    }
  }
  
  return errors;
}
```

This is the eval that **closes the loop on `game-content-generator`**: anything the generator outputs gets validated. If the generator hallucinates a 4-atk-3-str bronze sword (total 7, tier budget 3), this rejects it.

---

## 4. Layer 3 — Cross-reference integrity (code-based)

The single biggest source of "silent broken" bugs in game data: an NPC gives you a quest to find `bronze_lockpick`, which doesn't exist. The quest never completes; nobody notices for weeks.

```js
// evals/cross-refs.eval.js
import { ITEMS } from '../src/data/items.js';
import { NPCS } from '../src/data/npcs.js';
import { ENEMIES } from '../src/game/enemies.js';
// (or wherever each registry lives)

export function evalCrossRefs() {
  const errors = [];
  const itemIds = new Set(Object.keys(ITEMS));
  const npcIds = new Set(Object.keys(NPCS));
  
  // NPC gift lists must reference real items
  for (const [npcId, npc] of Object.entries(NPCS)) {
    const allGifts = [
      ...(npc.dialog?.gifts?.loved || []),
      ...(npc.dialog?.gifts?.liked || []),
      ...(npc.dialog?.gifts?.hated || []),
    ];
    for (const giftId of allGifts) {
      if (!itemIds.has(giftId)) {
        errors.push(`npc ${npcId}: gift "${giftId}" doesn't exist in items.js`);
      }
    }
  }
  
  // Enemy drops must reference real items
  for (const [enemyKind, def] of Object.entries(ENEMIES)) {
    for (const drop of (def.drops || [])) {
      if (!itemIds.has(drop.item)) {
        errors.push(`enemy ${enemyKind}: drop "${drop.item}" doesn't exist`);
      }
    }
  }
  
  // Cooking recipes — cooked items reference raw items
  for (const [id, item] of Object.entries(ITEMS)) {
    if (id.startsWith('cooked_')) {
      const rawId = id.replace('cooked_', 'raw_');
      if (!itemIds.has(rawId)) {
        errors.push(`item ${id}: implied raw "${rawId}" doesn't exist`);
      }
    }
    if (id.startsWith('burnt_')) {
      const rawId = id.replace('burnt_', 'raw_');
      if (!itemIds.has(rawId)) {
        errors.push(`item ${id}: implied raw "${rawId}" doesn't exist`);
      }
    }
  }
  
  // (extend with: quest targets, NPC schedules referencing locations, etc.)
  
  return errors;
}
```

Add this to CI. **Cross-ref errors are 90% of "silent" content bugs.**

---

## 5. Layer 4 — Voice & style (LLM-grader)

The cheap evals catch syntax. The LLM evals catch *texture*.

The voice rule from [[content-generation-playbook]] §3.4:

> *Medieval-cozy with a hint of quirky charm. Specific over generic. Story implied. Sensory detail. No fourth-wall breaks. No mechanical readouts.*

### The grader prompt

```
You are evaluating game item descriptions for a stylized fantasy RPG.
The voice rules are:

DO:
- Specific comparisons ("Heavier than bronze, less polished than steel.")
- Story implied ("The hilt is wrapped in someone else's leather.")
- Sensory detail ("Smells faintly of brine.")
- Specific in-world readers ("Favored by tomb-robbers and corner-dwellers.")

DON'T:
- Generic praise ("A great sword for any adventurer.")
- Mechanical readout ("Provides +4 defense bonus when equipped.")
- Tier-aware ("The best sword in its tier.")
- Clichés ("Crafted by the dwarves of olden times.")

Below is a description. Score it from 1–7 on voice fit. Output only a JSON
object: {"score": <number>, "rationale": "<one sentence>"}.

Description:
"""
{description}
"""
```

### Run protocol

```js
// evals/voice.eval.js — pseudo
import Anthropic from '@anthropic-ai/sdk';
import { ITEMS } from '../src/data/items.js';

const client = new Anthropic();

async function evalVoice(description) {
  const message = await client.messages.create({
    model: 'claude-sonnet-4-6',  // cross-family from generator (use Claude here, GPT-5 for generation)
    max_tokens: 200,
    messages: [{ role: 'user', content: voicePromptWith(description) }],
  });
  return JSON.parse(extractJSON(message.content[0].text));
}

export async function evalAllVoices() {
  const failures = [];
  for (const [id, item] of Object.entries(ITEMS)) {
    if (!item.desc) continue;
    const { score, rationale } = await evalVoice(item.desc);
    if (score < 5) {
      failures.push({ id, score, rationale, desc: item.desc });
    }
  }
  return failures;
}
```

**Cost notes:**
- ~$0.001 per item with Sonnet — 100 items = $0.10
- Run on each generation batch, not every commit
- **Cross-family rule**: if you generated content with GPT, grade with Claude (and vice versa)

### Sample for human audit

LLM graders drift. Sample 10% of grader output for human review monthly:

```js
// evals/voice-audit.js
const sample = pickRandom(allEvalResults, Math.ceil(allEvalResults.length * 0.1));
console.log('Audit these by hand — does the grader actually agree?');
sample.forEach(r => console.log(`[score: ${r.score}] ${r.desc}`));
```

If the human disagrees with the grader >20% of the time, retune the grader rubric.

---

## 6. Layer 5 — Lore consistency (LLM-grader)

This eval needs **the world bible as context**. The grader reads `WORLD_BIBLE.md` then judges new content.

### The grader prompt

```
You are checking new game content for consistency with established lore.

Below is the WORLD BIBLE for the project:

"""
{contents of WORLD_BIBLE.md}
"""

And below is a new piece of content (item, NPC, enemy, or quest):

"""
{new content as JSON or markdown}
"""

Check for:
1. Does this content reference any place, character, faction, or concept
   that contradicts the world bible?
2. Does it invent new lore (places, factions, named characters) that
   isn't in the world bible? (Sometimes OK; flag for human decision.)
3. Does it fit the tone and era of the world bible?

Output only JSON: {"verdict": "consistent" | "contradiction" | "new_lore" | "tone_mismatch", "details": "..."}
```

### Run protocol

```js
async function evalLoreConsistency(content) {
  const worldBible = await fs.readFile('docs/WORLD_BIBLE.md', 'utf8');
  const message = await client.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 400,
    messages: [{ role: 'user', content: lorePrompt(worldBible, content) }],
  });
  return JSON.parse(extractJSON(message.content[0].text));
}
```

Run **only on new content** (not full re-evals; expensive). Specifically when generating NPCs and quests, since those carry the most lore weight.

---

## 7. Balance sim (Monte Carlo, code-based)

For combat balance — does this gear/enemy actually work in tier?

```js
// evals/balance-sim.js
import { rollMeleeDamage, rollHitChance } from '../src/game/combat.js';

function simFight(player, enemy, n = 10000) {
  let wins = 0, totalTurns = 0;
  for (let i = 0; i < n; i++) {
    const p = clone(player), e = clone(enemy);
    let turns = 0;
    while (p.hp > 0 && e.hp > 0 && turns < 100) {
      // player swings
      if (Math.random() < rollHitChance(p, e)) {
        e.hp -= rollMeleeDamage(p, e, p.weapon);
      }
      // enemy swings if alive
      if (e.hp > 0 && Math.random() < rollHitChance(e, p)) {
        p.hp -= rollMeleeDamage(e, p, e.weapon || { baseDamage: e.atkLv, skillKey: 'melee' });
      }
      turns++;
    }
    if (p.hp > 0) wins++;
    totalTurns += turns;
  }
  return { winRate: wins / n, avgTTK: totalTurns / n };
}

// For each tier, sim tier-appropriate player vs tier-appropriate enemy
const targets = {
  trivial: { winRate: [0.85, 1.0], ttk: [3, 6] },     // sweep
  easy:    { winRate: [0.75, 0.95], ttk: [4, 8] },
  medium:  { winRate: [0.55, 0.85], ttk: [6, 12] },
  hard:    { winRate: [0.30, 0.65], ttk: [10, 20] },
};

export function evalBalance() {
  const failures = [];
  for (const [tier, target] of Object.entries(targets)) {
    const player = standardPlayerForTier(tier);
    const enemy  = standardEnemyForTier(tier);
    const { winRate, avgTTK } = simFight(player, enemy);
    
    if (winRate < target.winRate[0] || winRate > target.winRate[1]) {
      failures.push(`${tier}: win rate ${winRate.toFixed(2)} outside target ${target.winRate}`);
    }
    if (avgTTK < target.ttk[0] || avgTTK > target.ttk[1]) {
      failures.push(`${tier}: TTK ${avgTTK.toFixed(1)}s outside target ${target.ttk}`);
    }
  }
  return failures;
}
```

Run before each balance pass. See [[game-balance-playbook]] §6 for the full balance loop.

---

## 8. Soul check (LLM-grader using `evoke-online-game-feel`)

The big-picture eval: does this content advance the design philosophy?

```
Below is a new game feature / content piece.

Score it on each of the 9 feelings (0 = suppresses, 1 = neutral,
2 = produces) per the evoke-online-game-feel rubric:

1. Wonder
2. Earned mastery
3. Belonging
4. Hangout
5. Persistent FOMO
6. Quirky charm
7. Identity expression
8. Slow time
9. Discovery

Output JSON:
{
  "scores": { "wonder": <0|1|2>, ... },
  "total": <sum>,
  "verdict": "ship" | "needs_tweak" | "rethink",
  "weakest_feeling": "<feeling name>",
  "suggestion": "<one-sentence improvement>"
}

Targets:
- Total ≥ 12: ship
- Total 8–11: needs tweak (raise the weakest)
- Total < 8: rethink

Content:
"""
{feature description}
"""
```

Run on **major** new pieces — a new skill, a new NPC arc, a new boss. Not on every individual item.

---

## 9. Putting it all together — the eval pipeline

```
[ Generated content batch ]
        │
        ▼
[ Schema eval ]    ← layer 1, fail = block
        │
        ▼
[ Tier budget eval ]  ← layer 2, fail = block
        │
        ▼
[ Cross-ref eval ]    ← layer 3, fail = block (after merge)
        │
        ▼
[ Voice grader (LLM) ] ← layer 4, score < 5 = flag for human review
        │
        ▼
[ Lore grader (LLM) ]  ← layer 5, contradiction = flag
        │
        ▼
[ Balance sim ]        ← layer 6, out-of-band = flag
        │
        ▼
[ Soul check ]         ← layer 7 (only for major content), <12 = rethink
        │
        ▼
[ Ship to source files ]
```

### Continuous post-launch

Once the game is shipped:
- Sample player progression telemetry (which items used, never picked)
- Trace which NPCs get engaged vs ignored
- Check if balance targets hold in real play
- Re-run lore evals after every WORLD_BIBLE update
- Audit the LLM graders monthly for drift

---

## 10. The directory layout

```
gj26/
├── evals/
│   ├── README.md                  # how to run evals
│   ├── schema.eval.js             # layer 1 (code)
│   ├── tier-budget.eval.js        # layer 2 (code)
│   ├── cross-refs.eval.js         # layer 3 (code)
│   ├── voice.eval.js              # layer 4 (LLM)
│   ├── lore.eval.js               # layer 5 (LLM)
│   ├── balance-sim.js             # layer 6 (code)
│   ├── soul-check.js              # layer 7 (LLM)
│   ├── prompts/
│   │   ├── voice-grader.md
│   │   ├── lore-grader.md
│   │   └── soul-grader.md
│   ├── audits/                    # human-audit samples saved here
│   └── run-all.js                 # orchestrator: runs every eval, exits 1 on any fail
├── src/
│   └── data/
│       └── items.js
└── docs/
    └── content-evals-playbook.md  # this doc
```

---

## 11. The seven eval-discipline rules applied to gj26

From the [[evals-and-harnesses-research]]:

| Rule | gj26 application |
|---|---|
| **1. Define goal first** | Every new content type gets a one-line spec ("a sword should feel earned, not given") before any eval is written |
| **2. Code-based when verifiable** | Layers 1, 2, 3, 6 — all code-based. Run on every commit. |
| **3. Grade the trace, not just output** | When generator runs, log the prompt + output + eval scores. Trace stored in `evals/traces/` for review. |
| **4. Cross-model graders** | Use Claude for grading content GPT generated, and vice versa. Prevents same-family blindspots. |
| **5. Audit graders regularly** | 10% sample of LLM grader output reviewed monthly; rubric retuned if disagreement >20%. |
| **6. Eval the system, not the model** | Don't just eval the generator's output — eval the *whole pipeline* (generator + validators + ship). |
| **7. Continuous post-launch** | Telemetry + lore re-checks + grader-drift audits after release, not just at launch. |

---

## 12. The `run-all.js` orchestrator

```js
// evals/run-all.js
import { evalItemSchema } from './schema.eval.js';
import { evalTierBudget } from './tier-budget.eval.js';
import { evalCrossRefs } from './cross-refs.eval.js';
import { evalAllVoices } from './voice.eval.js';
import { evalBalance } from './balance-sim.js';

async function main() {
  let exitCode = 0;
  
  console.log('=== Layer 1: Schema ===');
  const schemaErr = evalItemSchema();
  if (schemaErr.length) { console.error(schemaErr.join('\n')); exitCode = 1; }
  
  console.log('=== Layer 2: Tier budget ===');
  const tierErr = evalTierBudget();
  if (tierErr.length) { console.error(tierErr.join('\n')); exitCode = 1; }
  
  console.log('=== Layer 3: Cross-refs ===');
  const refErr = evalCrossRefs();
  if (refErr.length) { console.error(refErr.join('\n')); exitCode = 1; }
  
  console.log('=== Layer 6: Balance sim ===');
  const balErr = evalBalance();
  if (balErr.length) { console.warn(balErr.join('\n')); /* warn, not fail */ }
  
  // LLM graders are async + cost money — only run if --full flag passed
  if (process.argv.includes('--full')) {
    console.log('=== Layer 4: Voice (LLM) ===');
    const voiceErr = await evalAllVoices();
    if (voiceErr.length) {
      console.warn(`${voiceErr.length} items scored < 5 on voice; review ./evals/audits/`);
    }
  }
  
  process.exit(exitCode);
}

main();
```

```bash
# CI: cheap evals on every commit
node evals/run-all.js

# Monthly / pre-release: full evals including LLM graders
node evals/run-all.js --full
```

---

## 13. Story consistency — the special case

Story is the hardest content to eval because it's the most ambiguous. Two strategies:

### A. "Story bible" file (preferred)

Maintain `docs/STORY_BIBLE.md` as the canonical timeline / character arcs / unresolved threads. Every new quest / NPC arc gets eval'd against it (Layer 5 lore-grader pattern).

### B. Constraints on character behavior

Encode "Cynthia is the cook, lives in cottage, knows everyone, dislikes gossip" as structured constraints, then the lore-grader checks if a new dialog line contradicts.

```yaml
# evals/character-constraints.yml
cynthia:
  role: "cook + shopkeeper"
  location: "cottage_kitchen, cottage_bedroom"
  personality: "warm, motherly, dislikes gossip, secretly anxious"
  knows: ["wizard_aric", "farmer_brom", "smith_gareth", "all_villagers"]
  doesnt_know: ["far_lands", "ancient_lore"]
  forbidden:
    - "speaks of magic"
    - "leaves the village"
```

The grader checks new content against these constraints.

### C. Keep story small for jam

For jam scope: 6 NPCs × 5 heart events × 1 quest line = 30 story beats total. Hand-write them, let the lore-grader prevent contradictions but don't try to *generate* the heart events. Heart events are the moments players remember; AI generation often produces forgettable ones.

---

## 14. References

- [[evals-and-harnesses-research]] — the eval discipline this is built on
- [[content-generation-playbook]] — schemas + tier tables this validates
- [[game-balance-playbook]] — combat formulas the balance sim uses
- [[evoke-online-game-feel|evoke-online-game-feel skill]] — soul-check rubric
- [[WORLD_BIBLE]] — context for lore grader
- [[DESIGN_VISION]] — the goal everything is eval'd against

Skills:
- `/game-content-generator` — the generator we're wrapping with evals
- `/evoke-online-game-feel` — the philosophy gate

External:
- [Anthropic — Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- [OpenAI — Evaluation best practices](https://developers.openai.com/api/docs/guides/evaluation-best-practices)
