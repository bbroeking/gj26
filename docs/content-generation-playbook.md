# Content Generation Playbook

How to generate, balance, validate, and ship new **skills, gear, items, enemies, and NPCs** for gj26 — using LLM-assisted templates that keep the new content coherent with what already exists.

The goal: you (or a future Claude session) say *"give me 5 mid-tier swords"* and get back drop-in JS objects that match the schema, fit the tier budget, and read like the rest of the game.

This pairs with the `game-content-generator` skill (the action lever) — this doc is the reference (schemas, tiers, tables).

---

## 1. The four content axes

| Axis | Schema source | Where it lives |
|---|---|---|
| **Items** (gear, food, materials, tools) | `src/data/items.js` | One big `ITEMS` object, key = id, value = entry |
| **Skills** | `src/game/skills.js` (`SKILL_KEYS`) + XP curves in `data/config.js` | Hardcoded list; adding a skill is a design event |
| **Enemies** | `src/game/enemies.js` (`spawnGoblin`, `spawnCow`, …) | Per-kind spawn factory |
| **NPCs** | `src/data/npcs.js` | One object, key = id, value = dialog/schedule |

---

## 2. The tier system — the spine

Every content piece sits at a tier. Tiers gate stats, level requirements, drops, and naming. **Stick to the tiers and the game stays balanced. Break them and it doesn't.**

### 2.1 Gear tiers (RuneScape lineage, 6 tiers)

| Tier | Level req | Material name | Total weapon (atk+str) | Body (def) | Shield (def) | Helmet (def) |
|---|---|---|---|---|---|---|
| **Bronze** | 1–15 | bronze | 3 | 2 | 1 | 1 |
| **Iron** | 15–30 | iron | 6 | 4 | 2 | 2 |
| **Steel** | 30–45 | steel | 9 | 6 | 3 | 3 |
| **Mithril** | 45–60 | mithril | 12 | 8 | 4 | 4 |
| **Adamant** | 60–75 | adamant | 15 | 10 | 5 | 5 |
| **Rune** | 75–99 | rune | 18 | 12 | 6 | 6 |

**Rule:** total stat bonus on a single piece of gear = (tier index × 3) for weapons, (× 2) for body, (× 1) for shield/helmet. Linear scaling. Easy to extend with a 7th tier (e.g. dragon: weapon 21, body 14).

**Weapon split:** for a weapon-tier budget of N, distribute across `atk` and `str`. Common splits:
- Sword: balanced (1:2 or 2:1 atk:str)
- Mace: heavy str, low atk (2:4 in bronze)
- Dagger: high atk, low str (2:1 in bronze)
- Spear: balanced, +reach future tag
- Bow / wand: future skills (range/magic)

### 2.2 Consumable tiers (food, potions)

| Tier | Heal range | Source |
|---|---|---|
| Snack | 1–2 | berries, mushrooms |
| Small | 3–5 | cooked sardine, raw fish cooked low-level |
| Medium | 6–10 | cooked beef, cooked salmon |
| Large | 12–18 | full meals, rare fish |
| Feast | 20–30 | cooked from boss drops |

Heal value tracks roughly **level / 4 of the cooking requirement** — bronze-tier player needs snacks, rune-tier player wants feasts.

### 2.3 Enemy tiers

| Tier | Player level target | HP | atkLv | defLv | maxHit | combat XP per kill | drops |
|---|---|---|---|---|---|---|---|
| **Trivial** | 1–5 | 4–10 | 1–2 | 1 | 1 | 5–10 | 1 raw mat |
| **Easy** | 5–15 | 10–25 | 3–5 | 2–3 | 2 | 10–35 | 1–2 raw mat + chance bronze |
| **Medium** | 15–30 | 25–60 | 6–10 | 4–6 | 3 | 35–90 | 1–3 raw mat + chance iron |
| **Hard** | 30–60 | 60–180 | 12–20 | 8–12 | 5 | 90–280 | 2–4 raw mat + chance steel/mith |
| **Elite** | 60–80 | 200–400 | 22–32 | 14–20 | 7 | 280–600 | adamant chance |
| **Boss** | 80+ | 500+ | 35+ | 25+ | 10+ | 800+ | rune chance + uniques |

Existing examples:
- Goblin: HP 6, atk 2, def 1, maxHit 1 → **Trivial** ✅
- Cow: HP 8 → **Trivial** (technically not aggressive, scaled to mid-trivial for cowhide value)

### 2.4 Skill tiers (the same 99 levels split into player journeys)

| Stage | Levels | What it feels like |
|---|---|---|
| Apprentice | 1–15 | Learning the verb, 1 unlock per ~3 levels |
| Journeyman | 15–40 | Real activity, multiple recipes/yields |
| Expert | 40–70 | Optimization, rare drops |
| Master | 70–90 | Endgame, boss-tier sources |
| Legend | 90–99 | Vanity, skill cape, prestige |

Each skill should have **at least 5 unlocks per stage** — new tiles, recipes, areas, tools — so progression is visible. RuneScape's woodcutting unlocks: oak → willow → maple → yew → magic. Apply the same structure.

---

## 3. Schemas (drop-in copy for new content)

### 3.1 Items — gear

```js
// In src/data/items.js
weapon_id: {
  name: 'Display Name',
  icon: '🗡',                    // emoji or URL to PNG
  stack: false,
  slot: 'weapon',                 // weapon | body | shield | helmet | boots | cape
  equipBonus: { atk: 0, str: 0, def: 0 },
  reqSkill: 'atk',                // what skill gates equip
  reqLevel: 1,                    // gate level
  desc: 'A {tier} {type}. {flavor sentence}.',
  // optional:
  tier: 'bronze',                 // for filtering / future smithing
  twoHand: false,                 // if true, blocks shield slot
},
```

### 3.2 Items — consumable

```js
food_id: {
  name: 'Cooked Salmon',
  icon: '🍣',
  stack: true,
  food: { heal: 8 },              // hp restored on use
  desc: 'A nicely cooked salmon. Restores 8 HP.',
  reqSkill: 'cook',               // skill needed to make
  reqLevel: 25,
}
```

### 3.3 Items — material / tool

```js
material_id: {
  name: 'Iron Ore',
  icon: '🟫',
  stack: true,
  desc: 'Mined from iron rocks. Smelts into iron bars.',
  // optional:
  source: { skill: 'mine', level: 15 },
  refines: { skill: 'smith', level: 15, into: 'iron_bar' },
}

tool_id: {
  name: 'Iron Pickaxe',
  icon: '⛏',
  stack: false,
  tool: 'pickaxe',
  reqLevel: 15,                   // can't equip without level
  desc: 'An iron pickaxe. Mines iron and copper.',
}
```

### 3.4 Enemies (spawn factory)

```js
// In src/game/enemies.js, mirroring spawnGoblin/spawnCow
export function spawnBandit(x, y, scene) {
  const mesh = buildBanditMesh();    // requires /models/bandit.glb
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'bandit',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.28,
    dir: 'down',
    hp: 18, hpMax: 18,                  // tier: easy
    atkLv: 4, defLv: 2, maxHit: 2,
    alive: true, aggro: false,
    aggroRadius: 5,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    hpBar,
    hitReactT: 0, attackAnimT: 0,
    knockX: 0, knockZ: 0,
    drops: [
      { item: 'cowhide', chance: 0.7 },
      { item: 'bronze_dagger', chance: 0.05 },
    ],
    onDeath: (player, log) => {
      log('combat', '+ Bandit slain.');
    },
  };
}
```

### 3.5 NPCs (dialog + schedule)

```js
// In src/data/npcs.js
npc_cynthia: {
  name: 'Cook Cynthia',
  role: 'shopkeeper',
  schedule: [
    { from: 6,  to: 18, location: 'cottage_kitchen' },
    { from: 18, to: 6,  location: 'cottage_bedroom' },
  ],
  dialog: {
    greeting: ['Welcome to my kitchen, dear.', 'Smells like supper, doesn\'t it?'],
    quest: { /* tutorial bindings */ },
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

## 4. The generator — LLM prompt templates

The "generator" is **a structured prompt + the tier table + a schema example**. Hand it to Claude (or any capable LLM) and it produces drop-in entries.

### 4.1 Universal prompt skeleton

```
You are generating new game content for gj26, a cozy RuneScape-flavored
browser RPG. The game's design vision is in DESIGN_VISION.md (locked
genre call: toon-painted RuneScape × Harvest Moon hybrid).

**Style stem (always preserved):**
- Names: short, fantasy-medieval, no apostrophes, no double-words
  unless they're a real material ("Bronze Sword" yes, "Bronze-Steel" no)
- Descriptions: 1–2 sentences, in-world voice (no "this item is great
  for..."), with a hint of quirky charm (KoL voice — see
  evoke-online-game-feel skill, "quirky charm")
- Stats: must obey the tier table below
- Output format: JS object literals, copy-pasteable into the schema

**Tier table:**
[paste relevant tier rows]

**Existing examples (match this style):**
[paste 2–3 from the codebase]

**Schema:**
[paste schema for the type being generated]

**Task:**
Generate {N} new {tier} {type} entries. {Specific theme or constraint}.

Output as a JS object literal block, ready to paste into items.js.
```

### 4.2 Per-type prompt templates

#### Weapon generator

```
Generate 5 new {TIER} weapons.

Tier budget (atk + str total): {N from table}
reqLevel range: {min}-{max}
Slot: 'weapon'
Material: {tier name} (e.g. "iron")

Variety: include a sword, a mace, a dagger, and 2 unusual choices
(spear, halberd, club, scimitar, etc.).

Stat split guidance:
- Sword: balanced (e.g. 2 atk, 4 str at iron)
- Mace: heavy str (e.g. 1 atk, 5 str at iron)
- Dagger: heavy atk (e.g. 4 atk, 2 str at iron)

Naming: "{Material} {Type}", e.g. "Iron Mace", "Iron Halberd".

Descriptions: 1–2 sentences. Mention what kind of fighter it suits.
Avoid generic ("a sturdy weapon"). Lean into specificity ("favored
by tomb-robbers" / "the haft is dented from real fights").
```

#### Armor generator

```
Generate 3 new {TIER} body armor pieces.

Tier budget (def): {N from table}
reqLevel: {min}-{max}
Slot: 'body'

Variety: include a heavy plate, a mid leather/chain, a robe (defensive
mage cloth — even if magic skill isn't shipped yet, lay groundwork).

Naming: "{Material} {Type}", e.g. "Steel Platebody", "Steel Chainmail",
"Steel Robe Top".

Descriptions: same constraints. Mention weight / wearer / look.
```

#### Consumable / food generator

```
Generate 4 new cooked foods that fit the {STAGE} cooking skill stage.

Heal range: {from tier table}
reqSkill: cook, reqLevel: {match stage}

Sources: each food should map to a raw material that the player would
have at this point in the game (e.g. fish from fishing, beef from cows,
herbs from foraging). Include the raw item key it cooks from.

Naming: "Cooked {Source}", "{Method} {Source}", or named recipe.

Output two objects per food: the raw item and the cooked item.
```

#### Material / gathering generator

```
Generate 3 new gathering materials at {SKILL} level {LEVEL}.

reqSkill: {skill} (mine | wc | fish | forage)
reqLevel: {level}

Each material should:
- Have a clear visual (icon: emoji or PNG)
- Imply a downstream use (smelting, crafting, cooking, brewing)
- Sit between existing tiers — not redundant with copper or iron

Naming: real-world or fantasy ore/wood/fish names.
```

#### Enemy generator

```
Generate 3 new {TIER} enemies for {ZONE THEME}.

Stats from table:
- HP: {range}
- atkLv: {range}
- defLv: {range}
- maxHit: {value}
- aggroRadius: 4-6 (default 4)

Required fields: kind, hp/hpMax, atkLv, defLv, maxHit, aggroRadius,
drops (1-3 items each with a probability), onDeath log message.

Drops should fit tier:
- Trivial: raw materials only (~70% chance) + tiny gold (1-3)
- Easy: + occasional bronze gear (~5%)
- Medium: + iron drops (~5%) + cooking ingredients
- Hard: + steel/mithril chance (~3%) + uniques

Theme: {bandits | undead | wildlife | ...}. Each enemy should feel
distinct mechanically (one tanky, one fast, one mage, etc.) — not
just stat-shifted clones.

Output: 3 spawnX(x, y, scene) factory functions in the same style as
spawnGoblin in src/game/enemies.js.
```

#### NPC generator

```
Generate 1 new NPC for the village. Theme: {role e.g. "the gardener"}.

Required fields: name, role, schedule (2 locations, day vs night),
greeting dialog (3-4 lines for variety), gift preferences (1 loved,
2 liked, 1 hated — drawn from existing items.js), hearts (max 5),
birthday (day + season).

Voice: {voice descriptor — gruff, scholarly, dreamy, anxious}.
Dialog should reveal one ongoing personal thread the player can
discover over heart events (e.g. "missing brother", "secret hobby",
"hates the smith").

Gifts must reference real items by id from items.js. Don't invent.

Output as a JS object entry for src/data/npcs.js.
```

#### Skill generator (rare — adding a new skill is a design event)

```
A new skill is being added to gj26. Existing skills: atk, str, def, hp,
cook, wc, fish, mine, smith, forage, carto, falconry.

Skill name: {name}.
Verb: {what does the player do? — e.g. "knit", "brew", "tame"}.

Define:
1. The 5 stages with what unlocks at each stage milestone (3, 15, 30,
   50, 70, 90).
2. The XP source (per action, per item, per minute).
3. Dependent items: tools, raw mats, finished products at each stage.
4. The world affordance: where's it done (kiln, loom, beehive)?
5. Three quirky charm details (a flavor item, a unique recipe name,
   a weird side-skill interaction).

Output: a design brief + draft entries for items.js. Stop short of
modifying skills.js — that change requires an update to the SKILL_KEYS
array and the level-up FX hooks.
```

---

## 5. Validation checklist

Before adding any new content, run through this:

### For all content
- [ ] Schema fields complete (no missing required keys)
- [ ] Naming follows convention (no apostrophes / double-words / quotes in id)
- [ ] Description is 1–2 sentences in-world voice
- [ ] No reference to items/skills that don't exist
- [ ] ID is unique across the file
- [ ] Icon renders (emoji works, PNG path resolves)

### For gear
- [ ] Total stat bonus matches tier budget exactly (not over, not under by >1)
- [ ] reqLevel within tier range
- [ ] slot is valid: weapon | body | shield | helmet | boots | cape
- [ ] equipBonus has all 3 keys (atk, str, def) even if some are 0
- [ ] If twoHand: true, that's documented in the desc

### For consumables
- [ ] Heal value matches tier (level/4 ± 1)
- [ ] reqLevel for cooking source within stage range
- [ ] Source raw item exists in items.js
- [ ] Cook + Burn variants both exist (cooked + burnt naming)

### For enemies
- [ ] HP/atk/def/maxHit all within tier table ranges
- [ ] aggroRadius reasonable (3-6 for ground, 8-10 for flying/ranged)
- [ ] Drop probabilities sum to <= 1.0 reasonably
- [ ] Drops reference real item IDs
- [ ] onDeath logs a one-line message (not silent)
- [ ] Spawn function follows spawnGoblin pattern (mesh, hpBar, position)

### For NPCs
- [ ] Schedule covers 24 hours with no gap
- [ ] Greeting has 3+ alternate lines
- [ ] Gifts: 1 loved, 2 liked, 1 hated — items reference real IDs
- [ ] Hearts max ≤ 5 for jam scope
- [ ] Birthday day is 1–28 and season is one of: spring (others post-jam)
- [ ] Voice is consistent across dialog lines

### For skills
- [ ] Verb is unique (not overlapping existing verbs)
- [ ] 5 stage milestones with unlocks
- [ ] XP curve matches `xpForLevel()` in config.js
- [ ] At least one "quirky" detail (a strange recipe name, weird unlock)
- [ ] Adds entry to SKILL_KEYS in skills.js
- [ ] Adds level-up SFX hook

---

## 6. Worked example — generating 5 iron weapons

**Prompt fed to Claude:**

> Generate 5 new Iron-tier weapons.
> Tier budget (atk + str total): 6
> reqLevel: 15-30
> Slot: 'weapon'
> Material: iron
> Variety: sword, mace, dagger, and 2 unusual.
>
> [+ schema, examples, style stem]

**Sample output:**

```js
iron_sword: {
  name: 'Iron Sword',
  icon: '🗡',
  stack: false,
  slot: 'weapon',
  equipBonus: { atk: 2, str: 4, def: 0 },
  reqSkill: 'atk', reqLevel: 15,
  tier: 'iron',
  desc: 'An honest iron sword. Heavier than bronze, less polished than steel.',
},
iron_mace: {
  name: 'Iron Mace',
  icon: '🔨',
  stack: false,
  slot: 'weapon',
  equipBonus: { atk: 1, str: 5, def: 0 },
  reqSkill: 'str', reqLevel: 15,
  tier: 'iron',
  desc: 'Crude iron head on an oak haft. Favored by smiths who never learned a guard.',
},
iron_dagger: {
  name: 'Iron Dagger',
  icon: '🔪',
  stack: false,
  slot: 'weapon',
  equipBonus: { atk: 4, str: 2, def: 0 },
  reqSkill: 'atk', reqLevel: 15,
  tier: 'iron',
  desc: 'Quick in the hand. The hilt is wrapped in someone else\'s leather.',
},
iron_halberd: {
  name: 'Iron Halberd',
  icon: '🪓',
  stack: false,
  slot: 'weapon',
  equipBonus: { atk: 3, str: 3, def: 0 },
  reqSkill: 'atk', reqLevel: 18,
  tier: 'iron',
  twoHand: true,
  desc: 'A two-handed polearm. Reach matters more than finesse.',
},
iron_scimitar: {
  name: 'Iron Scimitar',
  icon: '⚔',
  stack: false,
  slot: 'weapon',
  equipBonus: { atk: 4, str: 2, def: 0 },
  reqSkill: 'atk', reqLevel: 20,
  tier: 'iron',
  desc: 'Curved blade, light grip. Sailors and bandits favor it.',
},
```

**Validation:**
- All bonus totals = 6 ✅
- All reqLevels in 15–30 ✅
- Names follow "{Material} {Type}" convention ✅
- Descriptions are short, in-world, slightly quirky ✅
- Halberd twoHand flagged ✅

Drop-in ready. **This is what "the generator" produces.**

---

## 7. Iteration loop

When something feels off, here's the fix order:

1. **Stats wrong?** Re-run with the tier table emphasized in the prompt.
2. **Names generic?** Add 5+ existing examples to the prompt.
3. **Descriptions bland?** Add the "quirky charm" callout from `evoke-online-game-feel`.
4. **Output not parseable?** Constrain the format more strictly — "as a JS object literal, no Markdown, no comments outside fields."
5. **Doesn't fit the world?** Add a worldbuilding paragraph to the prompt: "the village is Lumbridge-flavored, medieval, no magic visible to new players, etc."
6. **Same archetype repeating?** Lower the `N`. Generate 3 at a time, refine, then 3 more.

---

## 8. When to NOT use the generator

- **One-off hero items.** The legendary sword should be hand-written. Generators are for the bulk content tier.
- **Quest-critical items.** Anything tied to a script is hand-authored.
- **First entry of a new category.** Write the first 2-3 by hand to set the tone, *then* generate from there.
- **Anything that affects onboarding.** Tutorial items must be predictable; let the generator do the slot 18 inventory overflow stuff, not the bronze axe.

---

## 9. References

- `src/data/items.js` — current item registry (style ground-truth)
- `src/game/skills.js` — skill keys and XP system
- `src/game/enemies.js` — spawn factory pattern
- `src/data/npcs.js` — NPC schema
- `docs/DESIGN_VISION.md` — genre call (informs naming, voice)
- `docs/ONBOARDING.md` — what tutorial NPCs need
- `docs/character-creator-research.md` — for character-related variants
- Skill: `evoke-online-game-feel` — for quirky-charm voice
- Skill: `game-content-generator` — the action lever for this playbook
