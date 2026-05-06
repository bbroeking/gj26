# Cartography — Skill Design (the map-making verb)

> Companion to `docs/cartography-keystone-design.md`. That doc covers *how charts behave inside dungeons*. This one covers *how the player levels Cartography by making maps in the first place*. The two together are the full Cartography vertical.

## The problem with "walk = XP"

Cartography in v1 awarded **+5 XP per never-visited tile**. That's a tracker, not a craft. A real cartographer doesn't level by accidentally walking — they level by surveying, sketching, triangulating, and inscribing. Walking is the *cost*, not the verb.

This doc replaces the per-tile XP grant with a four-phase active verb shape that distinguishes Cartography from every other skill in the game.

## Vision: the four-phase loop

```
   ┌─────── PHASE 1 SURVEY ───────┐
   │ Place a Surveyor's Pole at a │       ┌─ PHASE 2 SKETCH ─┐
   │ vista. Take bearing readings │  ──→  │ Stand near a      │
   │ on visible landmarks.        │       │ feature, channel  │
   │ XP per landmark "fixed."     │       │ a sketch. Page    │
   └──────────────────────────────┘       │ goes to journal.  │
                  │                       └───────────────────┘
                  ↓                                    │
       ┌── PHASE 4 PASSIVE ──┐                         ↓
       │  Walked tiles fade  │       ┌── PHASE 3 INSCRIBE ──────┐
       │  if not refreshed.  │  ──→  │ At the chartmaker's desk, │
       │  New paths grant    │       │ spend pages + ink + vellum │
       │  small XP for        │       │ to inscribe an output:    │
       │  discovery.          │       │ chart_blank, route_card,  │
       └─────────────────────┘       │ specialty chart, treasure  │
                                     │ map, keystone chart.       │
                                     └────────────────────────────┘
```

Each phase grants its own XP; the *combination* defines progress. Walk without sketching → little XP. Sketch without inscribing → no maps to sell. Inscribe without surveying first → poor stability.

## Phase 1 — SURVEY (vistas + triangulation)

The cartographer's signature verb. Most XP-dense activity at mid-level.

### Mechanic

1. Player places a **Surveyor's Pole** (placeable item, stack of 5 in starter inventory) on any tile they're standing on.
2. The pole "establishes a sightline" — fixes every visible landmark within 12 tiles in a 360° arc.
3. **XP per landmark fixed**, scaled by:
   - Already known? +5 XP (refresh, decay reset)
   - First fix? +25 XP (discovery)
   - Vista tile (height ≥ +2)? +50 XP and unlocks a "Vista Sightline" badge
   - Three poles triangulating one feature? Bonus +75 XP and the feature is "fixed in master atlas" (never decays)

### Vistas

Vistas are specific high tiles flagged in the world (peaks, towers, balconies, signposts on hills). The world has a pre-baked list of vista tiles in `world.vistas[]`. Standing on a vista doubles all survey XP and reveals an extra tile of fog around the player.

### Why it feels right

- Walking far to find a vista = real cost, real reward
- Choosing where to plant your pole = strategic decision
- Triangulation = math you can *feel*, not a recipe
- The "establish sightline" animation: the pole drops, a thin gold beam sweeps the visible arc once, fixing landmarks

## Phase 2 — SKETCH (the field journal)

A Pokédex-shaped feature. Builds out a personal record of everything in the world.

### Mechanic

1. Player walks within 2 tiles of a sketchable feature.
2. Pressing **N** (sketch) opens a 1.5s channel — player must stand still or the sketch fails.
3. On success, a journal page is added: `{ subject, sketchedAt, season, quality }`.
4. Each subject has a quality cap based on Cartography level — high-level cartographers produce richer sketches.

### Sketchable subjects (categories)

| Category | Examples | XP base | Notes |
|---|---|---|---|
| Terrain | river bend, cliff, bog, hill | 10 | Re-sketchable each season |
| Flora | herb cluster, mushroom ring, ancient oak | 15 | Plant species — one per species |
| Creature | bramble-imp, hedge-wolf, falcon | 25 | One per species, drift bad if old sketch |
| Curiosity | standing stone, abandoned cart, fae-circle | 50 | Hand-placed only, rare |
| Settlement | cottage, forge, herbalist hut | 30 | One per named location |
| Vista | from a Surveyor's Pole | 75 | Combines with Phase 1 |

### The Field Journal UI

Bound to **N** (currently no binding). Opens a parchment-styled modal listing all journaled subjects with:
- Subject name + sketch quality
- "First sketched" date (Bramblewood game-time)
- Season tag (sketches drift if too old)
- Reward badges: **Catalogued** (3+ sketches in a category), **Master Sketch** (Lv 75+ quality)

Mirrors the existing tool-button pattern (B / K / J / M / **N**).

### Sketch decay (the bad twin layer)

A sketch's *quality* decays one step per real-world week of game time if not refreshed. Quality steps:

- **Vivid** (just drawn) → no penalty
- **Faded** (1 week) → -10% XP value when consumed for inscription
- **Stale** (2 weeks) → -25% XP, can produce bad-twin charts at higher rate
- **Lost** (3 weeks) → page is removed; subject must be re-sketched

This forces the cartographer to *return* to known places. Builds the persistent-world FOMO feeling without forcing daily login.

## Phase 3 — INSCRIBE (the chartmaker's desk)

Where journal pages + materials become items. The existing chartmaker's stone is the bootstrap version of this; v2 adds a desk in the herbalist's hut interior.

### Inputs

- **Journal pages** (consumed per inscription, source of map content)
- **Vellum** (paper substrate; new craftable from cowhide + 1 hedge_ink)
- **Hedge Ink** / **Refined Ink** (existing reagents)
- **Charcoal Stick** (new, hearth + logs → 5 charcoal; for sketching)

### Outputs (in dependency order)

| Output | Cost | Effect | Carto level |
|---|---|---|---|
| `chart_blank` | 1 vellum + 1 ink | Fast-travel currency (existing) | 1 |
| `route_card` | 2 vellum + 1 ink + 2 walked-path tiles | Reduces fast-travel cost on a specific named route from 1 chart_blank → 0 | 8 |
| `survey_map` | 3 vellum + 2 ink + 5 sketches in a region | Permanent +20% Cartography XP gain in that region for 1 game-day | 15 |
| `treasure_map` | 1 vellum + 2 refined_ink + 1 curiosity sketch | Reveals a hidden cache somewhere on the world map; reading the map adds an X-marks-spot icon | 20 |
| `chart_hollow / briar_maze / sunken_hut` | (see keystone doc) | Dungeon keys | 10–22 |
| `hydrographic_chart` | 4 vellum + 3 ink + 1 river/bog/water vista sketch | Specialty: dungeons rolled from this have +30% chance of water-themed rooms | 35 |
| `geological_chart` | 4 vellum + 3 ink + 1 ore-vein survey | Specialty: dungeons rolled from this have +50% mineral_vein affix landing on good twin | 40 |
| `biological_chart` | 4 vellum + 3 ink + 5 creature sketches | Specialty: dungeons rolled from this have +30% chance of boss room | 45 |
| `master_chart_bramblewood` | 1 of every specialty + 30 vellum + 20 refined_ink | Endgame: a wall-art map that reveals the entire overworld permanently | 75 |
| `atlas_of_bramblewood` | All 99-tier requirements + every species sketched + every vista triangulated | The Cartographer's cape unlock; +5% movement speed; cosmetic title | 99 |

### The desk UI

Three-panel modal (existing pattern from chart-crafting):
- **Left**: available recipes (locked greyed-out)
- **Middle**: ingredient slots — drag-drop pages from journal
- **Right**: predicted output preview + inscribe button

Reusing `src/ui/charting.js`'s structure, but the recipe set is broader than just "dungeon chart." The keystone-chart UI becomes a *tab* of the inscribe UI, not the whole thing.

## Phase 4 — PASSIVE (walked-path memory)

The current `exploredTiles` system, refined.

### Mechanic

- Tiles you walk are added to `exploredTiles` with a `lastSeenT` timestamp.
- Tiles older than 7 game-days fade on the world map (visualization only — game still treats them as known).
- Walking a path that connects two known landmarks for the first time generates a **route_token** (auto-creates a draft route_card you can inscribe later).

### XP

- New tile: +2 XP (down from +5 — was the only verb in v1; now it's the *trickle*)
- New tile on a vista: +10 XP
- Connecting two landmarks via a brand-new path: +50 XP (one-time per landmark pair)

This makes walking still feel rewarded without making it the whole skill.

## Specialty paths (Lv 35+)

A cartographer's late-game identity comes from specializing. Each specialty unlocks a **chart type** that biases its dungeon toward a theme.

### Hydrographic (water/coast)
- Sketch rivers, bogs, water vistas
- Inscribe `hydrographic_chart` → dungeons get extra wet rooms, mistwoven affix lands more often
- Style: blue-green journal pages

### Geological (terrain/ore)
- Sketch cliffs, ore veins, hilltops
- Inscribe `geological_chart` → dungeons get +50% mineral_vein landing rate, extra rocks
- Style: ochre/grey journal pages

### Biological (creatures/flora)
- Sketch every species, every plant
- Inscribe `biological_chart` → dungeons get +30% boss room rate, ecosystem affixes (festival_pace, frenzied) lands more often
- Style: green journal pages with watercolor wash

You can pursue all three; the player is gated by the time investment, not a hard pick. But specialties unlock chart variants only that style can produce, giving a long-tail collection goal.

## NPC integration

Cartography is anti-loner: the cartographer's craft only matters if it changes someone else's life. Five NPC hooks:

### The Chartmaker
- Promote the existing standing stone to a *named* NPC (bring concept art forward)
- **Commissions**: "Bring me a sketch of the river bend north of Hod's", "Triangulate the bog stag mire", "Inscribe me a hydrographic chart"
- Pays in coin + rare ink

### Sir Withering (falconer)
- At Cartography 30+: ask Withering to *send the falcon* to scout a tile
- The falcon flies out, sketches the tile remotely (costs 1 falcon's whistle charge)
- Lets you sketch unreachable peaks / islands / dangerous boss rooms

### Quill the Herbalist
- Trades **flora sketches** for hedge_ink at a 1:1 rate (her field reference)
- "Bring me 5 mushroom-ring sketches and I'll teach you a tincture recipe"

### Hod the Smith
- Trades **ore-vein survey sketches** for refined ingots (one specific recipe per geological feature)
- Gives the cartographer a way to convert geology XP into combat gear

### Brother Pell of the Stone Cloister (new NPC, see concept-art-prompts-next.md)
- Buys **curiosity sketches** at high coin (he's compiling a book)
- His commissions are weird and specific: "Sketch a fae-circle at exactly midnight", "Document the third standing stone north"

## Risk / failure modes (the bad-twin layer)

Every phase has a botch state to keep the verb tense:

| Verb | Failure | Effect |
|---|---|---|
| Sketch (moved during channel) | "Smudged" sketch | -50% XP, page cannot be inscribed |
| Sketch (same species in same season) | "Stale" sketch | -25% XP, page degrades faster |
| Inscribe (insufficient ink) | "Bleeds" | Output is consumed but tier drops one step |
| Inscribe (faded pages) | "Inkfade" | Higher chance of bad-twin affixes |
| Survey (non-vista pole) | "Bare bearing" | No bonus, just 5 XP per landmark fixed |
| Triangulation (poles overlap < 4 tiles) | "Crowded" | No triangulation bonus |
| Treasure map (game-day > 30 since X-mark fix) | "Drifted" | X is now ±3 tiles from true location |

Failure should *teach*, not punish — a bad sketch is still 1-2 XP. The cartographer learns where they can stand still, what season is right, how much ink to budget.

## Progression milestones (rewrite)

The **keystone milestones** (CARTO_MILESTONES in `worldMap.js`) cover map-display unlocks. The **skill milestones** below cover map-*making* unlocks. Both apply at the same level.

| Lv | Title | Skill verb unlock |
|---|---|---|
| 1 | Apprentice | Walk → memory tiles. Sketch flora/terrain. |
| 5 | Field Surveyor | Place Surveyor's Poles. Sketch creatures. |
| 10 | Hedgewalker | Inscribe `chart_blank` and `route_card`. |
| 15 | Pathfinder | Inscribe `chart_hollow` keystone. Triangulation gives 2× XP. |
| 20 | Marker | Inscribe `treasure_map`. Place named waypoints (existing). |
| 25 | Surveyor | Inscribe `survey_map`. Vistas grant 3× XP. |
| 35 | Hydrographer | Inscribe `hydrographic_chart`. |
| 40 | Geologist | Inscribe `geological_chart`. |
| 45 | Biologist | Inscribe `biological_chart`. |
| 50 | Master Charter | Walk-the-perimeter reveal (existing). |
| 60 | Falconer-Cartographer | Use Sir Withering's falcon to sketch remotely. |
| 75 | Grand Charter | Inscribe `master_chart_bramblewood`. |
| 90 | Atlas-bearer | Begin atlas commission chain. |
| 99 | Grand Cartographer | Inscribe `atlas_of_bramblewood`. Cape + +5% move speed + cosmetic title. |

## Endgame: the Atlas of Bramblewood

A long-tail collection meta-goal that ties the whole skill together.

### Requirements

- Every species sketched (count = number of unique enemy/creature kinds in the world)
- Every vista triangulated (count = number of vista tiles)
- Every named landmark surveyed at least once
- One of each specialty chart inscribed
- 99 Cartography

### Reward

- **Cosmetic**: Cartographer's Cape (back slot) — wobbly hand-drawn parchment-style
- **Mechanical**: +5% movement speed, +10% sketch XP forever, +1 affix slot ceiling on every keystone chart
- **Title**: "Grand Cartographer of the Bramblewood"
- **Diegetic**: a giant unfurled wall-art map appears in the player's cottage (or hub) showing every place they've been, painted in over time

This is a "I played the game *all the way*" trophy. ~50-100 hours estimated.

## Open design questions

1. **Sketch reliability vs frustration** — should the channel be 1.5s (fast, easy) or 4s (cinematic, missable)? Lean 1.5s with 2× XP for a held-still sketch.
2. **Vellum scarcity** — should it be common (1 vellum = 1 cowhide) or scarce (1 vellum = 3 cowhide + 1 ink)? Lean common-ish; the bottleneck should be sketches, not paper.
3. **Auto-sketch on first encounter** — should walking past a brand-new species auto-grant a low-quality sketch? Lean **yes** — discovery should always grant something. Then the player upgrades it by deliberately re-sketching.
4. **Falcon recon** — does the falcon's remote sketch require line-of-sight from Sir Withering's tile, or can it scout anywhere? Lean LoS-based for grounding (no abuse to scout dungeon floors).
5. **Specialty exclusivity** — should pursuing all three specialties be possible, or should the player pick one? Lean all-three-possible; specialization is about *time investment*, not lockout. (Locking creates regret.)
6. **Treasure map content** — what's *in* a treasure cache? Lean: ink, vellum, occasionally a unique cosmetic item. Not gear — keep it cartography-themed.
7. **Atlas redo** — once you finish the Atlas, can you start a "second pass" with bonuses? Lean **no**; legendary should be once-only.

## Implementation roadmap

The skill is large. Here's a build order that gives playable wins each turn.

### Phase A (next turn — minimum playable)
1. Add `field_journal` item (always in inventory, never droppable)
2. Add `surveyors_pole`, `vellum`, `charcoal_stick` items
3. Bind **N** to a sketch action (channel UI)
4. Implement subject detection: tree, oak, herb, mushroom, NPC, named landmark
5. Drop per-tile XP from +5 → +2 (move bulk of XP to sketches)
6. Field Journal UI showing sketches grouped by category

### Phase B
7. Surveyor's Pole placement + sightline arc visualization
8. Vista detection (read `world.vistas[]` flag list — needs world.js update)
9. Triangulation bonus

### Phase C
10. Inscribe UI revamp — keystone-chart UI becomes a tab
11. New recipes: `route_card`, `survey_map`, `treasure_map`
12. Sketch decay tick on game-day rollover

### Phase D
13. Specialty charts (`hydrographic`, `geological`, `biological`)
14. NPC commission system (Chartmaker NPC promoted from stone)
15. Falcon remote sketch (Sir Withering integration)

### Phase E (endgame)
16. Master chart inscription
17. Atlas tracker UI
18. Cartographer's Cape cosmetic
19. Wall-art map placeable in cottage

Each phase is shippable as a coherent slice — the player gains a real new verb at each step.

## Why this design works

Reading against the **evoke-online-game-feel** skill's nine feelings:

- **Wonder**: vistas reward exploration, sketching unknowns is novelty-seeking — ✓ strong
- **Earned mastery**: 99 carto + Atlas is real status, visible cape — ✓ strong
- **Belonging**: NPC commissions tie cartographer to community — ✓ medium
- **Hangout**: chartmaker's desk is a "hub for puttering" — ✓ medium
- **Persistent FOMO**: sketch decay forces returns — ✓ medium-strong (gentle)
- **Quirky charm**: hand-written subject names, weird commissions — ✓ strong (depends on flavor pass)
- **Identity expression**: specialties (hydrographic vs biological) shape your cartographer — ✓ strong
- **Slow time**: walking real distance, channeling sketches, refreshing decayed pages — ✓ strong
- **Discovery**: every species/vista is a one-time first-find — ✓ strong

Score: **~16/18**. This is on-brand for the era this game is reaching for. The skill becomes a *reason to play* rather than a stat that ticks up.

## References

- `docs/cartography-keystone-design.md` — companion doc on the dungeon side
- `docs/online-games-2000-2010-survey.md` — relevant inspirations (RuneScape Slayer log, EVE survey scanner, Habbo collection)
- `docs/cozy-life-sim-design-playbook.md` — sketch decay echoes Stardew's farming season pressure
- `docs/concept-art-prompts-next.md` Group F — items already prompted that this design needs (chart_blank, surveyor's pole, cartographer's compass, master chart, waypoint cairn)
- `src/ui/worldMap.js` — current overworld map UI; will host the milestone hooks
- `src/ui/charting.js` — current keystone UI; will become the "Inscribe" tab in v2

## TL;DR

Cartography is a **four-phase active craft**, not a passive walk-tracker:

1. **Survey** with poles at vistas (combat with terrain)
2. **Sketch** features into a Pokédex-shaped journal (collection)
3. **Inscribe** journal pages into chart products (crafting)
4. **Walk** new paths, refresh old ones (passive trickle)

Specialties at Lv 35+ make every cartographer different. NPCs commission your sketches and pay coin. Endgame is the **Atlas of Bramblewood** — every species, every vista, every landmark. Cape, +5% move speed, title.

Build order is in the **Implementation roadmap** above. Phase A is the next playable slice — sketch verb, journal UI, drop per-tile XP to a trickle.
