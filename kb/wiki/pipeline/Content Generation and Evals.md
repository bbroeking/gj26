---
type: pipeline
tags: [content-generation, evals, llm, pipeline, balance, quality]
status: draft
updated: 2026-06-13
sources:
  - "docs/content-generation-playbook.md"
  - "docs/content-evals-playbook.md"
  - "docs/evals-and-harnesses-research.md"
---

# Content Generation and Evals

The AI-assisted content-generation pipeline for Wayfinder game content (items, enemies, NPCs, skills) and the eval/harness methodology that gates quality before shipping.

---

## The Core Idea

Content generation is **a structured prompt + the tier table + a schema example** handed to an LLM. The result is drop-in JS objects that match the schema, fit the tier budget, and read like the rest of the game. This is coupled to an eval pipeline that runs code-based checks (cheap, every commit) and LLM-grader checks (expensive, each batch) before anything ships.

> "Evals are product specs. They make fuzzy goals concrete. Code-based when verifiable, LLM-grader when not. Grade the trace, not just the output. Cross-model graders. Eval the system, not the model. Continuous post-launch." — `docs/content-evals-playbook.md`, citing the 2026 eval discipline

---

## The Four Content Axes

| Axis | Schema location | Notes |
|---|---|---|
| **Items** (gear, food, materials, tools) | `src/data/items.js` | One big `ITEMS` object; key = id, value = entry |
| **Skills** | `src/game/skills.js` (`SKILL_KEYS`) + XP curves in `data/config.js` | Hardcoded list; adding a skill is a design event |
| **Enemies** | `src/game/enemies.js` (`spawnGoblin`, `spawnCow`, …) | Per-kind spawn factory |
| **NPCs** | `src/data/npcs.js` | One object; key = id, value = dialog/schedule |

---

## Tier Tables

**Tier tables are the spine. Break them and the game loses balance.**

### Gear tiers (6 tiers, RuneScape lineage)

| Tier | Level req | Weapon (atk+str) | Body (def) | Shield (def) | Helmet (def) |
|---|---|---|---|---|---|
| Bronze | 1–15 | 3 | 2 | 1 | 1 |
| Iron | 15–30 | 6 | 4 | 2 | 2 |
| Steel | 30–45 | 9 | 6 | 3 | 3 |
| Mithril | 45–60 | 12 | 8 | 4 | 4 |
| Adamant | 60–75 | 15 | 10 | 5 | 5 |
| Rune | 75–99 | 18 | 12 | 6 | 6 |

**Stat split guidance:**
- Sword: balanced (1:2 or 2:1 atk:str)
- Mace: heavy str, low atk
- Dagger: high atk, low str
- Bow / wand: future range/magic skills

### Consumable tiers

| Tier | Heal range | Typical source |
|---|---|---|
| Snack | 1–2 | Berries, mushrooms |
| Small | 3–5 | Cooked sardine, low-level fish |
| Medium | 6–10 | Cooked beef, cooked salmon |
| Large | 12–18 | Full meals, rare fish |
| Feast | 20–30 | Cooked from boss drops |

Heal value tracks roughly `level / 4` of the cooking requirement.

### Enemy tiers

| Tier | Player lvl | HP | atkLv | defLv | maxHit | XP/kill | Drops |
|---|---|---|---|---|---|---|---|
| Trivial | 1–5 | 4–10 | 1–2 | 1 | 1 | 5–10 | 1 raw mat |
| Easy | 5–15 | 10–25 | 3–5 | 2–3 | 2 | 10–35 | 1–2 raw + chance bronze |
| Medium | 15–30 | 25–60 | 6–10 | 4–6 | 3 | 35–90 | 1–3 raw + chance iron |
| Hard | 30–60 | 60–180 | 12–20 | 8–12 | 5 | 90–280 | 2–4 raw + chance steel/mith |
| Elite | 60–80 | 200–400 | 22–32 | 14–20 | 7 | 280–600 | Adamant chance |
| Boss | 80+ | 500+ | 35+ | 25+ | 10+ | 800+ | Rune chance + uniques |

Existing baseline: Goblin HP 6, atk 2, def 1, maxHit 1 → Trivial ✅

### Skill stages

| Stage | Levels | Character |
|---|---|---|
| Apprentice | 1–15 | Learning the verb, 1 unlock per ~3 levels |
| Journeyman | 15–40 | Real activity, multiple recipes/yields |
| Expert | 40–70 | Optimization, rare drops |
| Master | 70–90 | Endgame, boss-tier sources |
| Legend | 90–99 | Vanity, skill cape, prestige |

Each skill should have at least 5 unlocks per stage — new tiles, recipes, areas, tools — so progression is visible at all times.

---

## Content Schemas

### Gear item
```js
weapon_id: {
  name: 'Display Name',
  icon: '🗡',
  stack: false,
  slot: 'weapon',               // weapon | body | shield | helmet | boots | cape
  equipBonus: { atk: 0, str: 0, def: 0 },
  reqSkill: 'atk',
  reqLevel: 1,
  desc: 'A {tier} {type}. {flavor sentence}.',
  tier: 'bronze',               // for filtering / future smithing
  twoHand: false,               // if true, blocks shield slot
},
```

### Consumable
```js
food_id: {
  name: 'Cooked Salmon',
  icon: '🍣',
  stack: true,
  food: { heal: 8 },
  desc: 'A nicely cooked salmon. Restores 8 HP.',
  reqSkill: 'cook',
  reqLevel: 25,
}
```

### Enemy spawn factory (mirrors `spawnGoblin`)
```js
export function spawnBandit(x, y, scene) {
  // mesh, hpBar, position.set(x+0.5, 0, y+0.5)
  return {
    kind: 'bandit',
    x, y, homeX: x, homeY: y,
    hp: 18, hpMax: 18,           // tier: easy
    atkLv: 4, defLv: 2, maxHit: 2,
    aggroRadius: 5,
    drops: [
      { item: 'cowhide', chance: 0.7 },
      { item: 'bronze_dagger', chance: 0.05 },
    ],
    onDeath: (player, log) => { log('combat', '+ Bandit slain.'); },
  };
}
```

### NPC
```js
npc_cynthia: {
  name: 'Cook Cynthia',
  role: 'shopkeeper',
  schedule: [
    { from: 6,  to: 18, location: 'cottage_kitchen' },
    { from: 18, to: 6,  location: 'cottage_bedroom' },
  ],
  dialog: {
    greeting: ['Welcome to my kitchen, dear.', 'Smells like supper, doesn\'t it?'],
    gifts: {
      loved: ['cooked_beef'],
      liked: ['raw_sardine', 'logs'],
      hated: ['burnt_beef'],
    },
  },
  hearts: { current: 0, max: 5 },
  birthday: { day: 7, season: 'spring' },
}
```

---

## Generator Prompt Templates

### Universal skeleton
```
You are generating new game content for gj26, a cozy RuneScape-flavored browser RPG.

Style stem (always preserved):
- Names: short, fantasy-medieval, no apostrophes
- Descriptions: 1–2 sentences, in-world voice, hint of quirky charm
  (specific over generic; story implied; sensory detail)
- Stats: must obey the tier table
- Output: JS object literals, copy-pasteable

[Tier table rows for the relevant type]
[2–3 existing examples from the codebase]
[Schema for the type being generated]

Task: Generate {N} new {tier} {type} entries. {Specific theme or constraint}.
```

### Per-type prompts (keys)

**Weapons:** `Generate 5 new {TIER} weapons. Tier budget (atk+str total): {N}. Variety: sword + mace + dagger + 2 unusual.`

**Armor:** `Generate 3 new {TIER} body armor pieces. Variety: heavy plate + mid leather/chain + robe.`

**Consumables:** `Generate 4 new cooked foods for the {STAGE} cooking skill stage. Heal range: {range}. Include raw item + cooked item pairs.`

**Enemies:** `Generate 3 new {TIER} enemies for {ZONE THEME}. Each should feel distinct mechanically (one tanky, one fast, one mage — not stat-shifted clones).`

**NPCs:** `Generate 1 new NPC. Role: {role}. Voice: {descriptor}. Dialog must reveal one ongoing personal thread. Gifts must reference real item IDs.`

**Skills (rare):** Define 5 stage milestones, XP source, dependent items, world affordance, 3 quirky details. Stop short of modifying `SKILL_KEYS` — that requires a separate design event.

### Voice rules for descriptions

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

---

## The Eval Pipeline (seven layers)

```
[ Generated content batch ]
    ↓ Layer 1: Schema eval         ← code-based, fail = BLOCK
    ↓ Layer 2: Tier budget eval    ← code-based, fail = BLOCK
    ↓ Layer 3: Cross-ref integrity ← code-based, fail = BLOCK (after merge)
    ↓ Layer 4: Voice & style       ← LLM-grader, score < 5 = flag
    ↓ Layer 5: Lore consistency    ← LLM-grader, contradiction = flag
    ↓ Layer 6: Balance sim         ← code-based Monte Carlo, out-of-band = flag
    ↓ Layer 7: Soul check          ← LLM-grader (major content only), <12 = rethink
    ↓
[ Ship to source files ]
```

### Layer 1 — Schema (code-based, <1 second)
Checks required fields, type correctness, duplicate IDs, valid slot names, `equipBonus` shape, description length (10–250 chars). Lives at `evals/schema.eval.js`. **Run on every commit.**

### Layer 2 — Tier conformance (code-based)
Validates stat totals match tier budget exactly. Weapon: `atk + str === WEAPON_TIER_BUDGET[tier]`. Body: `def === BODY_TIER_BUDGET[tier]`. Also checks `reqLevel` falls within the tier's level range. Lives at `evals/tier-budget.eval.js`. **This is the eval that closes the loop on the generator** — if the generator hallucinates a 4-atk-3-str bronze sword (total 7, budget 3), this rejects it.

### Layer 3 — Cross-reference integrity (code-based)
Checks that every item/NPC/enemy ID referenced elsewhere actually exists: NPC gift lists → `items.js`, enemy drops → `items.js`, `cooked_<x>` → `raw_<x>` exists. Lives at `evals/cross-refs.eval.js`. **Cross-ref errors are 90% of "silent" content bugs.** Run on every commit.

### Layer 4 — Voice & style (LLM-grader)
Scores each description 1–7 on voice fit using the DO/DON'T rules above. Uses `claude-sonnet-4-6` (cross-family: use Claude if content was generated by GPT, and vice versa to avoid same-family false positives). Cost: ~$0.001 per item. Run on each generation batch, not every commit. Sample 10% of grader output for human review monthly; if disagreement >20%, retune the rubric.

### Layer 5 — Lore consistency (LLM-grader)
Reads `WORLD_BIBLE.md` as context, then checks for contradictions, new-lore inventions, or tone mismatches. Output: `{"verdict": "consistent" | "contradiction" | "new_lore" | "tone_mismatch", "details": "..."}`. Run only on new content (especially NPCs and quests, which carry the most lore weight).

### Layer 6 — Balance simulation (code-based, Monte Carlo)
Simulates N=10,000 fights between a tier-appropriate player and a tier-appropriate enemy. Win-rate targets:
- Trivial: 0.85–1.0 win rate, 3–6 turns TTK
- Easy: 0.75–0.95, 4–8 turns
- Medium: 0.55–0.85, 6–12 turns
- Hard: 0.30–0.65, 10–20 turns

Lives at `evals/balance-sim.js`. Uses `rollMeleeDamage` and `rollHitChance` from `src/game/combat.js`. Run before each balance pass; warn but don't fail CI (balance tuning is iterative).

### Layer 7 — Soul check (LLM-grader, major content only)
Scores on 9 feelings from the `evoke-online-game-feel` rubric (Wonder, Earned mastery, Belonging, Hangout, Persistent FOMO, Quirky charm, Identity expression, Slow time, Discovery). Threshold: total ≥ 12 → ship; 8–11 → needs tweak; < 8 → rethink. Run on new skills, NPC arcs, and bosses — not individual items.

### Run-all orchestrator
```bash
# CI: cheap evals on every commit
node evals/run-all.js

# Monthly / pre-release: full evals including LLM graders
node evals/run-all.js --full
```

---

## Eval Directory Layout

```
gj26/
└── evals/
    ├── README.md                  # how to run evals
    ├── schema.eval.js             # layer 1 (code)
    ├── tier-budget.eval.js        # layer 2 (code)
    ├── cross-refs.eval.js         # layer 3 (code)
    ├── voice.eval.js              # layer 4 (LLM)
    ├── lore.eval.js               # layer 5 (LLM)
    ├── balance-sim.js             # layer 6 (code)
    ├── soul-check.js              # layer 7 (LLM)
    ├── prompts/
    │   ├── voice-grader.md
    │   ├── lore-grader.md
    │   └── soul-grader.md
    ├── audits/                    # human-audit samples saved here
    └── run-all.js                 # orchestrator
```

---

## The 2026 Eval Discipline (research summary)

Source: `docs/evals-and-harnesses-research.md`. Key findings from Anthropic, OpenAI, and the HN eval community as of April 2026:

**The central insight:** "Think of 'the AI' as the whole cybernetic system of feedback loops joining the LLM and its harness." A harness change on 15 LLMs improved all 15 at coding in a single afternoon — the model weights didn't change. **The harness is the product.**

**Anthropic's key finding:** Opus 4.5 scored 42% on CORE-Bench. After fixing harness bugs (rigid grading, ambiguous task specs, stochastic tasks, over-constrained scaffold) — **same model scored 95%.** A benchmark with bugs is a bug detector, not a model evaluator.

**Seven rules applied to Wayfinder content:**

| Rule | Wayfinder application |
|---|---|
| 1. Define goal first | Every new content type gets a one-line spec before any eval is written |
| 2. Code-based when verifiable | Layers 1, 2, 3, 6 — all code-based. Run on every commit. |
| 3. Grade the trace, not just output | Log prompt + output + eval scores in `evals/traces/` |
| 4. Cross-model graders | Use Claude for GPT-generated content and vice versa |
| 5. Audit graders regularly | 10% sample of LLM grader output reviewed monthly |
| 6. Eval the system, not the model | Eval the whole pipeline (generator + validators + ship) |
| 7. Continuous post-launch | Telemetry + lore re-checks + grader-drift audits after release |

**2026 tooling stack (engineer-owned, CI-first):**
- Testing: Promptfoo (CLI-driven prompt comparison + red-teaming) or DeepEval (pytest-style)
- Tracing: Arize Phoenix or Langfuse (both OSS, $0)
- All-in-one managed: Braintrust (1M trace spans/month free)

**Langfuse** was acquired by ClickHouse in January 2026; remains MIT-licensed and actively maintained.

---

## When NOT to Use the Generator

- **One-off hero items:** legendary sword or boss trophy should be hand-written
- **Quest-critical items:** anything tied to a script is hand-authored
- **First entry of a new category:** write the first 2–3 by hand to set the tone, then generate from that base
- **Onboarding items:** tutorial content must be predictable; don't auto-generate the bronze axe

---

## Story Consistency (special case)

For heart events and quest arcs: maintain `docs/STORY_BIBLE.md` as the canonical character-constraint file. Encode constraints as structured YAML:

```yaml
# evals/character-constraints.yml
cynthia:
  role: "cook + shopkeeper"
  personality: "warm, motherly, dislikes gossip"
  forbidden:
    - "speaks of magic"
    - "leaves the village"
```

The lore-grader checks new dialog against these constraints. For jam scope: 6 NPCs × 5 heart events = 30 story beats total. Hand-write them — AI generation often produces forgettable heart events.

---

## See also

- [[Economy]] — tier tables and drop probabilities as designed
- [[Enemies]] — enemy stat blocks and spawn functions
- [[NPCs]] — NPC schema, dialog patterns, gift preferences
- [[Items and Gear]] — item registry and slot conventions
- [[Trades and Leveling]] — skill stages and XP curves
- [[Balance Philosophy]] — the broader design philosophy that these evals enforce

## Sources

- `docs/content-generation-playbook.md` — schemas, tier tables, generator templates, worked examples
- `docs/content-evals-playbook.md` — 7-layer eval pipeline with full code examples
- `docs/evals-and-harnesses-research.md` — 2026 eval discipline (Anthropic, OpenAI, HN) and tooling landscape
