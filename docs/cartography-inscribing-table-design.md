# Inscribing Table — Design Doc

> The crafting heart of the Cartography vertical. Replaces the current "click an affix from a list" UI with a **two-tier alchemical loop**: ingredients arranged on a 3×3 grid produce **inks** (recipe-shape matters); inks combined with vellum produce **charts** (random rolls biased by which inks were used).
>
> Companion to:
> - `cartography-skill-design.md` — the full skill
> - `cartography-keystone-design.md` — what the chart does inside the dungeon
> - `cartography-skill-explorations.md` — alternatives we considered

## Vision

The cartographer's desk is **the puttering hub**. It's where you sit, mix, fail, discover, brag. It evokes:

- Minecraft's pre-recipe-book era — *trying things just to see what happens*
- Skyrim alchemy when it's working — combinatorial mastery feels like *magic you earned*
- The Slime Rancher / Stardew art table — a place you *come back to*

Three things the system has to do:

1. **Reward arrangement** — same ingredients in different patterns produce different inks. Position is meaningful.
2. **Reward discovery** — recipes are not handed to the player. Finding them is the verb.
3. **Reward bias-not-control** — inks change the *odds* of a chart's affixes, not the affixes themselves. Random feels random; mastery feels meaningful.

The system fails if any of those three break.

## The two crafting tiers

```
   ┌───── TIER 1 ─────┐         ┌───── TIER 2 ─────┐
   │  Inscribing      │         │  Chart           │
   │  Table           │         │  Inscription     │
   │                  │         │                  │
   │  3×3 grid        │   ─→    │  Pick template + │
   │  ingredients     │   inks  │  drop in inks    │
   │  → recipe match  │         │  → roll affixes  │
   │  → produce ink   │         │  → output chart  │
   └──────────────────┘         └──────────────────┘
```

**Tier 1** is *deterministic on the recipe side, fuzzy on the failure side*. If you hit a known pattern, you get the named ink every time. If you don't, you get one of three things: a smudge (lose ingredients), a wild ink (random low-tier), or — rarely — a serendipity (a rare ink you weren't trying for).

**Tier 2** is *fuzzy on output*. Even with a perfect ink loadout, the chart's affix roll is RNG, weighted by your inks. Same loadout twice = different charts.

The handoff between tiers is the inks themselves — *items in your bag*, stackable, tradeable.

---

## Tier 1 — The Inscribing Table

### Apparatus

A wooden desk in the **chartmaker's stone clearing** (and later, in the **herbalist's hut interior**). Click it → opens the table UI.

### The 3×3 grid

```
┌─────┬─────┬─────┐
│  ?  │  ?  │  ?  │   ← top row
├─────┼─────┼─────┤             ╔════════════╗
│  ?  │ [C] │  ?  │   ── → →   ║  Ink Well  ║   ← output
├─────┼─────┼─────┤             ╚════════════╝
│  ?  │  ?  │  ?  │   ← bottom row
└─────┴─────┴─────┘
   [ Inscribe ]                ← button stays below the grid
```

The output **Ink Well sits to the right of the grid**, not below it — Minecraft-style flow. The Inscribe button stays below the grid as the action commit. This keeps the visual scan order: ingredients on left → place into grid → arrow flows right to output → press Inscribe to commit.

The center slot is the **anchor**. Most recipes care about the center + relative positions (cross, T, line, X). Some care about the corners only. A few are **mixed-rotation invariant** (any 90° rotation of the same shape produces the same ink).

### Why position matters

It's a **spatial puzzle layer** on top of "have the right items." Same bag of ingredients, different shapes, different inks. This separates novices (who try one shape) from masters (who know rotations and substitutions).

### How an attempt resolves

Player drags ingredients into the grid. Clicks **Inscribe**.

```
                   ┌────────────────────────────┐
                   │ Match table grid pattern?  │
                   └────────────────────────────┘
                                │
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                 ▼
       known recipe      no known match    cursed/forbidden
              │                 │                 │
       ★ Produce          🎲 60% smudge      💀 lose extra
        named ink         (lose ingredients)  + wild bad-ink
       +50 carto XP       30% common ink
       (first time)       10% rare ink
              │                 │                 │
              ▼                 ▼                 ▼
       Add to Codex     +5 XP per attempt   +0 XP, log entry
```

The **smudge state is generous on purpose**: lose the ingredients, but keep one charcoal back as a consolation, and the failure still teaches *what doesn't work*. Cozy-friendly.

### Recipe Codex (the discovery loop)

Every player has a Recipe Codex (separate tab in the field journal). It lists:

- **Discovered**: full recipe (pattern image + ingredients + ink it produces + carto XP per craft)
- **Hinted**: only the ink name and silhouette, no recipe (e.g., from an NPC quest reward or scroll)
- **Unknown**: blank, just a "?" placeholder

A discovered recipe **never has to be remembered** — at Cartography 50+, the table can auto-arrange the recipe for you (you still need the ingredients). At Lv 99, the table even tells you what's *adjacent* to a known recipe — "Hedge Ink + 1 ore dust in slot 3 = Refined Ink."

This gives a real long-tail goal: collect every recipe.

### Anchor patterns

Five canonical pattern shapes the recipes use. Most ink recipes are one of these:

| Pattern | Sketch | Recipe shape it implies |
|---|---|---|
| **Singleton** | `· · · / · X · / · · ·` | One thing in the center — refining or distilling |
| **Vertical line** | `X · · / X · · / X · ·` | Three of the same — bulk ink |
| **Cross (+)** | `· X · / X X X / · X ·` | Five-in-cross — balanced ink |
| **X-corners** | `X · X / · X · / X · X` | Four corners + center — focused ink |
| **T-shape** | `X X X / · X · / · X ·` | Top row + center column — directional ink |
| **L-shape** | `X · · / X · · / X X X` | Two arms — twisted ink |

Recipe quality varies by shape — singletons make low-tier inks; corners + center makes rarer inks. Players learn this *empirically*, not from a tutorial.

---

## The Reagent Catalog

Every ingredient has an **essence type** (one of four) plus a **rarity tier** (1–3). Recipes are written in terms of essences, not specific items, so substitutions work — `2× verdant T1` accepts any 2× tier-1 verdant herb.

### 🌿 Verdant (forest, foraging)

| Item | Tier | Source |
|---|---|---|
| `raw_mushroom` | 1 | forage in shaded tiles |
| `bramble_resin` | 1 | drop from bramble-imp |
| `wild_herb` | 1 | forage in any meadow tile (NEW) |
| `downfeather` | 2 | drop from chickens / falcons |
| `mossvine` | 2 | forage near water (NEW) |
| `whickerhares_foot` | 3 | rare drop, Withering's quest |

### 🪨 Earthen (mining, stone)

| Item | Tier | Source |
|---|---|---|
| `charcoal_stick` | 1 | hearth + log (existing) |
| `ore_dust` | 1 | smithing byproduct (NEW) |
| `salt_chip` | 1 | dungeon decor / cave (NEW) |
| `bogiron_ore` | 2 | mining nodes |
| `stone_chip` | 2 | breaking dungeon walls |
| `meteor_iron` | 3 | rare meteor strike (NEW, post-jam) |

### 🩸 Sanguine (combat, creature)

| Item | Tier | Source |
|---|---|---|
| `thorn_essence` | 1 | drop from bramble cap |
| `crow_feather` | 1 | rare daytime drop (NEW) |
| `boar_tusk` | 2 | Burrow Boar boss drop |
| `wightpelt` | 2 | hedgewight drop |
| `hedgemothers_thorn` | 3 | Hedgemother boss drop |

### 💧 Lumen (water, light)

| Item | Tier | Source |
|---|---|---|
| `pond_water` | 1 | dipped from any water tile (NEW) |
| `rivermud` | 1 | gathered at sand tiles (NEW) |
| `foxfire_glow` | 2 | rare night-only forage (NEW) |
| `morning_dew` | 2 | gathered at dawn from grass (NEW) |
| `aurora_shard` | 3 | rare, only during in-game aurora event (NEW) |

### Where the ingredients come from (ecosystem)

Most ingredients **already exist** or are **trivial to add**. The only meaningful new content is:
- 4 new "common" reagents: `wild_herb`, `mossvine`, `pond_water`, `rivermud`
- 3 new mid-tier: `salt_chip`, `crow_feather`, `morning_dew`, `foxfire_glow`
- 3 new endgame: `meteor_iron`, `aurora_shard`, plus quest reagents

---

## The Recipe Catalog (15 inks)

Each ink targets one or more **affix-bias families**. Inks are stackable items in the bag.

### Common Inks (Tier 1, easy patterns, used in almost every chart)

| Ink | Pattern | Recipe (essence) | Affix bias |
|---|---|---|---|
| **Hedge Ink** 🟢 | Vertical line | 3× verdant T1 | baseline ink, no special bias |
| **Stoneground Ink** ⚫ | Vertical line | 3× earthen T1 | +10% mineral_vein roll |
| **Bramblepress Ink** 🔴 | Vertical line | 3× sanguine T1 | +10% tyrannical roll |
| **Wellspring Ink** 🔵 | Vertical line | 3× lumen T1 | +10% bramble_bloom roll |
| **Charcoal Bind** ⚫️ | Singleton (1× charcoal) | 1× charcoal | gives +1 affix slot stability % |

### Refined Inks (Tier 2, two-essence patterns)

| Ink | Pattern | Recipe | Affix bias |
|---|---|---|---|
| **Refined Ink** ⚪ | T-shape | 1× hedge ink + 2× earthen T2 | +5% to every roll's good-twin chance |
| **Bog Ink** 🟦 | Cross (+) | 1× lumen T1 (center) + 4× verdant T1 | +30% fog_of_hedge or bramble_bloom |
| **Ember Ink** 🟠 | X-corners | 4× sanguine T1 (corners) + 1× charcoal (center) | +30% tyrannical or bursting |
| **Hush Ink** 🟪 | X-corners | 4× downfeather + 1× charcoal | +30% lockstep (bad-twin festival_pace inverted) |
| **Lustrous Ink** ✨ | Cross (+) | 4× ore_dust + 1× refined ink | +30% mineral_vein, +10% gilded_seam |

### Rare Inks (Tier 3, hard to make, big payoff)

| Ink | Pattern | Recipe | Affix bias |
|---|---|---|---|
| **Aurora Ink** 🌌 | T-shape | 1× aurora_shard + 2× foxfire_glow + lumen frame | +50% on rare boss affixes (hedgemother, briar_king) |
| **Wightblood Ink** 🩸 | L-shape | 2× wightpelt + 1× sanguine T3 + thorn frame | unlocks `wolf_alpha_den` boss roll bias |
| **Tideink** 🌊 | Mixed rotation invariant | 4× lumen T2 + 1× refined ink | +40% bog_stag_mire, hydrographic chart only |
| **Coalrose Ink** 🔥 | Cross (+) | 4× coalrose + 1× refined ink | +40% sprinter (pace affix) — burns fast |
| **Atlas Ink** 📜 | All 9 slots filled | 1× of every essence × 2 + atlas anchor | endgame: lets you re-roll one affix free |

### A worked example

Player wants to roll a chart that's likely to land **mineral_vein + tyrannical**. They craft:

1. **Lustrous Ink** (cross, 4× ore_dust + 1× refined ink) → +30% mineral_vein
2. **Ember Ink** (X-corners, 4× bramble_resin + 1× charcoal) → +30% tyrannical
3. Pick a **Hollow chart** (T2, 2 affix slots)
4. Drop both inks into the inscription
5. Hit Inscribe

The roll for slot 1: weights are now `mineral_vein: 60% (was 30%), other affixes: 40%`. The roll for slot 2: similar but biased to tyrannical. Result: **probably** the chart they wanted. Sometimes neither lands. Sometimes both. The chart stays the verb, not a recipe to execute.

---

## Tier 2 — Chart Inscription

The existing keystone-chart UI evolves. The "pick affix from list" model is replaced with **drop inks into ink-slots**. The number of ink-slots equals the chart's affix count + 1 (one universal slot for chart-wide modifiers).

### Layout

```
   ┌─ Templates ─┐  ┌─ Inscription ─────────────────┐  ┌─ Predicted ─┐
   │ ◉ Snug      │  │ Chart: HOLLOW                  │  │             │
   │ ◉ Tier 1    │  │                                │  │ Slot 1:     │
   │ ● Hollow    │  │  [ Universal ink ] ← chart-mod │  │ ▮▮▮▮▮▯ 60%  │
   │ ◉ Briar Maze│  │  [   Slot 1     ]              │  │   mineral   │
   │ ◉ Sunken    │  │  [   Slot 2     ]              │  │             │
   │ ◉ Delve     │  │                                │  │ Slot 2:     │
   │             │  │  Cost: 3× Hedge Ink            │  │ ▮▮▮▯▯▯ 30%  │
   │             │  │                                │  │   tyrannical│
   │             │  │  [ Inscribe ]                  │  │             │
   └─────────────┘  └────────────────────────────────┘  └─────────────┘
```

### How inks influence rolls

Each ink has a **weight modifier**: `+30% mineral_vein roll`, `+10% bramble_bloom roll`, etc. The roll engine:

1. Build a base weight table for the chart's tier (each affix has a default chance to land).
2. For each ink in slots, multiply matching affix weights.
3. Normalize to 100%.
4. Roll for each slot independently.
5. Each rolled affix then resolves its own good/bad-twin based on the existing stability% formula.

The **predicted outcome panel** shows live, per-slot probabilities. Players can experiment with ink loadouts before spending materials.

### Cost

Each chart costs:
- 1× vellum (substrate)
- 1× hedge ink (binding agent — every chart needs the baseline)
- 0–N specialty inks (scaling with tier)
- Plus a Cartography level threshold

### Roll example end-to-end

Player wants Hollow + tyrannical + mineral_vein. They drop in 1× Ember Ink (slot 1), 1× Lustrous Ink (slot 2), 1× Hedge Ink (universal).

- **Slot 1 roll**: tyrannical 60%, frenzied 15%, bursting 15%, festival_pace 10% → tyrannical lands. Stability% check: 70% good, 30% bad-twin (Erratic).
- **Slot 2 roll**: mineral_vein 60%, hedgemother_den 8%, others 32% → mineral_vein lands. Stability check: 65% good, 35% bad-twin (Barren).

Output: `chart_hollow` with `[tyrannical (good)] [mineral_vein (good)]`.

If they had used 2× Hedge Ink instead, the rolls would have been baseline distribution — random across 12+ affixes.

---

## Discovery + Mastery Loop

The **discovery loop** is the heart of why this system feels good.

### How recipes are discovered

1. **Trial**: player tries random patterns. ~10% chance to hit a recipe blind. Each smudge teaches "that wasn't it."
2. **Hint**: NPCs hand out hints in dialogue. Quill: "I always thought hedge ink wanted three of the same in a column." Hod: "When the smith works iron, the dust is heavier than the ash." (Hint: ore-dust patterns.)
3. **Scroll**: rare drops in dungeons give a complete recipe entry. Lv 30+ chests have 5% chance. Boss rooms have a guaranteed scroll.
4. **NPC quests**: side quests reward recipe entries directly. Brother Pell's curiosity sketches give curio-related ink recipes.

### Codex tab in the Field Journal

The Codex shows discovered recipes:

```
RECIPE CODEX                    [4 / 15 known]

▼ Common Inks
  ● Hedge Ink     • • •  | recipe known
                          [verdant T1] × 3 in a column
                          made: 12  ·  Lv 1 unlocked
  ● Charcoal Bind  · · ·  | recipe known
                          [charcoal] × 1 center
                          made: 3
  ◌ Stoneground   • · · | hinted by Hod
                          (try 3× of something earthen?)
  ◌ ???           ? · ? | unknown — keep experimenting
  ...

▼ Refined Inks
  ◌ ???           ? · ? | unknown — try mixing inks?
```

### Mastery rewards

| Lv | Unlock |
|---|---|
| 10 | Ink Codex tab opens in field journal |
| 15 | "Common" inks show their ingredient categories (still need to discover the shape) |
| 25 | At known recipes, the table can auto-arrange ingredients (one click) |
| 50 | Hinted recipes show ingredient categories — only shape stays unknown |
| 75 | All Common + Refined recipes unlocked automatically |
| 99 | All Rare recipes unlocked + an extra 4th ink slot per chart |

This creates a real long-tail. A Lv 99 cartographer is **mechanically more efficient at the table**, not just numerically stronger.

---

## UI Structure

The Inscribing Table modal:

```
┌──────────────────────────────────────────────────────────────────────┐
│  THE INSCRIBING TABLE                              Carto Lv 18  ×    │
├──────────────────┬──────────────────────────┬──────────────────────┤
│ INGREDIENTS      │       RECIPE              │  CODEX               │
│  (filtered to    │                            │  ───────────         │
│   ingredients-   │   ┌───┬───┬───┐            │  Hedge Ink     ✓     │
│   only)          │   │ . │ . │ . │            │  Charcoal Bind ✓     │
│                  │   ├───┼───┼───┤            │  Stoneground   ?     │
│  🌿 wild_herb 12 │   │ . │ * │ . │  ← anchor  │  ???           ?     │
│  🌿 mushroom  4  │   ├───┼───┼───┤            │  ???           ?     │
│  🪨 ore_dust  9  │   │ . │ . │ . │            │  ───────────         │
│  🪨 charcoal  6  │   └───┴───┴───┘            │                      │
│  🩸 thorn     2  │                            │  Discovered: 4/15    │
│  💧 pond_water 7 │   [ Output Ink ]           │                      │
│                  │       (empty)              │                      │
│                  │                            │                      │
│                  │     [ INSCRIBE ]           │                      │
└──────────────────┴──────────────────────────┴──────────────────────┘
```

**Drag-drop**: ingredients in the left panel can be dragged onto grid slots. Right-click on a placed ingredient returns it. Click "Inscribe" runs the resolution.

**Input model fallback** (for accessibility): single-click an ingredient to "select" it, then click a grid slot to place. Works without drag.

### Real-time pattern recognition

As the player places ingredients, the right panel **highlights any partial-match recipes** ("you're 1 ingredient away from Hedge Ink"). This is a **gentle nudge for known recipes**, **silent for unknown ones**. Players learn the system without it doing the puzzle for them.

### Output well

A small bottle silhouette below the grid. After Inscribe:
- Match: bottle fills with the ink color, sparkle animation, "✦ Hedge Ink" floater
- Smudge: bottle fills with grey-black, sad puff animation, "Smudge" floater
- Wild ink: bottle fills with a faded color, "Wild ink — you're not sure what this is"

### Chart Inscription screen

A separate modal (existing keystone UI evolved). Drop inks into ink-slots, see live probability bars, click Inscribe. Detailed in §Tier 2 above.

---

## Era-feel Smoke Test

Per the `evoke-online-game-feel` skill, scoring 0/1/2 against the 9 feelings:

| Feeling | Score | Why |
|---|---|---|
| **Wonder** | 2 | Discovering recipes is the whole verb |
| **Earned mastery** | 2 | Codex grows visibly; Lv 99 unlocks |
| **Belonging** | 1 | NPCs trade hints + reagents |
| **Hangout** | 2 | The table IS a hangout — sit and putter |
| **Persistent FOMO** | 1 | Ink stocks deplete; quests need specific inks |
| **Quirky charm** | 2 | Voice on every ink ("Hedge Ink stains anything it touches") |
| **Identity expression** | 2 | Your ink palette = your style, visible to others |
| **Slow time** | 2 | Drag-drop, not click-click. Deliberate. |
| **Discovery** | 2 | Headline win — recipes hide behind experimentation |
| **Total** | **16/18** | strong, on-brand for the era |

The two feelings at 1 (Belonging, FOMO) bump up if the NPC commission system + ink trading post (from `cartography-skill-explorations.md`) gets built later.

---

## Implementation Roadmap

Three phases, each shippable.

### Phase 1 — The Apparatus (3-4 days dev)

- [ ] Add reagent items (4 new common, ~5 new mid-tier)
- [ ] Build the table UI (3-panel modal)
- [ ] Implement the 3×3 grid with drag-drop + click-place fallback
- [ ] Resolve clicks: pattern-match against a known-recipe table, output an ink
- [ ] Add 5 starter recipes (Hedge Ink, Stoneground, Bramblepress, Wellspring, Charcoal Bind)
- [ ] Smudge / wild-ink fallback
- [ ] Recipe Codex tab in field journal (just discovered list, no hints yet)

### Phase 2 — The Variety (2-3 days dev)

- [ ] Add 5 Refined-tier recipes
- [ ] NPC dialogue hints (Hod, Quill, Brother Pell)
- [ ] Real-time partial-match highlight in the table
- [ ] Auto-arrange known recipes at Lv 25+
- [ ] Recipe scrolls as rare dungeon drops

### Phase 3 — The Inscription (2 days dev)

- [ ] Refit the keystone-chart UI to use ink-slots instead of affix-list
- [ ] Implement ink → affix-weight modifiers
- [ ] Live probability preview panel
- [ ] Add 5 Rare-tier recipes
- [ ] Lv 99 mastery unlocks (all rare known, +1 ink slot)
- [ ] Migrate existing charting flow to the new system

---

## Open Design Questions

Things that need a paper-decide:

1. **Smudge severity** — lose all ingredients? Keep half? Right answer probably playtest-dependent. Lean: lose all but always return 1 charcoal.
2. **Ink stack size** — 1 ink = 1 chart? Or 1 ink = 5 charges? Lean: 1 ink = 1 chart so the economy is felt every time.
3. **Recipe count** — 15 is the Phase-1-3 target. Endgame should have ~30 for a real long-tail. When do we add the back-half? (Lean: Phase 4, post-jam.)
4. **Pattern rotation** — should the same shape rotated 90° produce the same ink, or different inks? Lean: same. Keeps the puzzle approachable.
5. **Ingredient substitution** — should a recipe accept "any verdant T1" or specifically "wild_herb"? Lean: essences (any verdant T1), with 5% bonus stability if you used the recipe's "preferred" ingredient.
6. **Wikis** — within a week, GameFAQs will have all 15 recipes. Lean: lean into it. Recipes are the obvious thing to look up; the *deciding which inks to use* is the actual skill.
7. **Cross-skill cost** — should ink crafting also award Cooking XP (it's a kind of mixing)? Or strictly Cartography? Lean: Cartography only, but reagents come from every skill (so all skills contribute).

---

## What this replaces / what stays

**Replaces**:
- The current keystone-chart UI's affix-picker list (no longer pick-from-list)
- The flat ink-cost in chart recipes (no longer "3× hedge_ink for chart X" — now "1× any ink that biases mineral_vein")
- The lone affix-stability roll mechanic (still rolls, but ink loadout shapes the distribution)

**Stays**:
- All 14 existing affixes (they're the rolled outcomes)
- The chart templates (Snug, Hollow, etc.)
- The dungeon generation pipeline (chart with affixes → dungeon, no change)
- The completion-XP formula

In other words: **Tier 1** is brand-new. **Tier 2** is the existing system with a new front-end.

---

## UI Design Prompts (drop into Midjourney / Imagen / Flux)

### Locked stem

```
hand-painted storybook concept art for a cozy fairytale RPG UI mockup,
parchment-cream backdrop with hand-drawn ink linework, warm earthy
palette (oak browns, mossy greens, parchment cream, hearth-orange
highlights), no photorealism, no glossy plastic, no cyberpunk, no
neon, no hard cel-shade outlines.
--ar 16:9 --stylize 250 --v 7
```

Negative prompt suffix: `no photorealism, no glossy plastic, no neon, no busy backgrounds`

### The hero shots (Phase 1 generation batch)

1. **The Inscribing Table — full UI mockup**: a 3-panel parchment screen for a fantasy crafting table. **Center panel**: a 3×3 wooden grid of empty inscribing slots, each slot with a faint ink corner-mark; **to the right of the grid**, a hand-drawn sepia arrow curves outward to a small bottle silhouette labeled "Ink Well" (empty) — the output sits beside the grid, not below it; below the grid a button "INSCRIBE" in Cinzel font. **Left panel**: a leather-bound ingredient drawer titled "INGREDIENTS" with hand-drawn ingredient miniatures (bundles of green herbs, ore-chip clusters, charcoal sticks, mushroom caps, dewdrops). **Right panel**: an open codex page titled "KNOWN INKS" with 8 hand-drawn ink-bottle silhouettes, two labeled (Hedge Ink, Charcoal Bind), six blacked out with question marks. *(slug: `ui-inscribing-table-hero`)*

2. **Recipe match — the moment of success**: 3×3 grid where 5 slots are filled with painted ingredient miniatures (3 green herb bundles in a vertical column, 2 charcoal sticks in opposite corners), the entire grid glows with soft gold light, an arrow points downward to a finished bottle of "Hedge Ink" with a luminous green-glowing top sitting in an ornate ink well. Background paper subtly shimmers. Hand-drawn sparkle marks around the bottle. *(slug: `ui-inscribing-success`)*

3. **The smudge — failure state**: a 3×3 grid where 4 ingredient miniatures have melted into a dark inky puddle pooling at the bottom of the grid, three thin grey smoke wisps rising. A single charcoal stub remains in the output well below. A hand-drawn frustrated face emoji watermark in the corner. Cozy not punishing. *(slug: `ui-inscribing-smudge`)*

4. **The Chart Inscription Screen — the second tier**: parchment-style window split into 3 panels. **Left**: a wooden chart-template rack with 6 rolled vellum scrolls (labels: Snug, Tier 1, Hollow, Briar Maze, Sunken Hut, Delve), one selected with a red ribbon. **Center**: a half-painted parchment chart with an ornate border and three glowing ink-slot circles (one filled with green hedge-ink-bottle, two empty); below is a "1× Vellum, 3× Hedge Ink" cost line and an "INSCRIBE" button in Cinzel. **Right**: a "PREDICTED OUTCOME" preview with hand-drawn bar-chart histograms — top bar 60% labeled "Mineral Vein" (ore icon), middle bar 30% "Barren" (cracked stone icon), bottom 10% "Other" (question-mark icon). *(slug: `ui-chart-inscription-hero`)*

5. **The ink shelf — collection display**: a long wooden shelf holding 12 ornate hand-blown ink bottles, each a different color: green Hedge Ink (round bottle), charcoal-grey Refined Ink (angular tall), red Ember Ink (small with cork), blue Bog Ink (squat wide), white-glow Lumen Ink (faintly shimmering), purple Aurora Ink (rare, with star on cork), each tagged with a hand-drawn label tied with twine. Soft warm lamp light from above-right. *(slug: `ui-ink-shelf`)*

6. **Recipe Codex page — open spread**: spread of an open leather-bound codex showing one fully-discovered ink recipe: top header "HEDGE INK" in illuminated script; below, a small 3×3 grid sketch with the pattern shown (3 herbs in a vertical column, two slots empty); arrow pointing right to a green ink bottle illustration; below, a 3-sentence in-world description in cursive ink. The opposite (right) page shows an undiscovered recipe — title "???", grid sketch faded with question marks, description blacked out. Edge of pages worn, ink stains. *(slug: `ui-codex-spread`)*

7. **Hovering reagent — pickup moment**: detail of one inscribing-table slot, empty with a faint hand-drawn herb silhouette as a placement hint at the bottom of the slot. Above the slot, a charcoal stick miniature is floating just above it (player about to drop), slight ink-trail wisps radiating downward. Soft drop-shadow on the slot. Other adjacent slots out of focus. *(slug: `ui-reagent-hover`)*

8. **Partial-match nudge**: 3×3 grid with 4 ingredients placed (3 green herbs in a column, 1 charcoal in center bottom). The right-side codex panel highlights an entry: "Hedge Ink — 1 ingredient away" with the missing slot highlighted gold in the codex's pattern preview. Soft gold glow connecting the grid to the codex entry. *(slug: `ui-partial-match`)*

9. **Quill at the table — character moment**: Quill the Herbalist seated at a wooden inscribing table in her hut interior, mid-mix, holding a charcoal stick over a half-built recipe in the 3×3 grid in front of her, expression of focused concentration, wild hair tied back, herb bundles hanging from rafters above, soft golden lamp light, a finished bottle of green Hedge Ink already on the corner of the desk. *(slug: `npc-quill-inscribing`)*

10. **The chartmaker's stone clearing — the apparatus in-world**: 3D in-world isometric view of the chartmaker's clearing — the standing stone center-back, a wooden inscribing desk in the foreground with a 3×3 slotted tray, ink bottles on a small wooden shelf, charcoal sticks in a clay jar, vellum sheets stacked, a candle burning, autumn leaves on the ground, soft mist in the trees. Storybook style, warm dawn light. *(slug: `landmark-inscribing-desk`)*

### How to use these prompts

Run them in batches of 3-5 (per the locked stem in `docs/concept-art-prompts-next.md`). Save outputs to `docs/concept-art/<slug>.png`. Once a hero (1 or 4) lands the look, pull it through `reference-to-ui` to translate into HTML+CSS. Then build out from there.

The two prompts to start with: **#1** (Inscribing Table hero) and **#4** (Chart Inscription hero). They're the two screens we need to ship Phase 1 + Phase 3.

---

## TL;DR

Two-tier alchemical crafting:

- **Tier 1**: 3×3 grid + ingredients → inks. Pattern matters. Discovery is the verb. 15 recipes target.
- **Tier 2**: Inks + vellum + chart template → randomized chart. Inks bias the affix roll. Random feels random; mastery feels meaningful.

Hooks into existing systems cleanly — affixes, charts, dungeon generation all stay. The new layer is the apparatus + the recipe codex.

Smoke test scores **16/18** against the era-feel rubric.

Ship in 3 phases: Apparatus → Variety → Inscription. ~7-9 days dev.

10 UI prompts ready to drop into Midjourney.

Want me to spin up Phase 1 — items + the table UI scaffolding — right now? Or do we pause to discuss any of the open design questions first?
