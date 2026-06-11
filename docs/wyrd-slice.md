# Wyrd — the cartography vertical slice

*Wyrd* (Old English: fate as a woven thread) is the working name for the Godot game at `wyrd/`,
forked 2026-06-09 from the `godot/` evaluation project. This doc specifies the **slice 2 loop**
from ADR 0003: town → craft a chart → enter the dungeon it describes → gather/fight → return.

The spine stays cozy-skilling (ADR 0003). The chart system is the keystone design in
`docs/cartography-keystone-design.md`, with the *shipped* three.js numbers
(`src/ui/charting.js`, `src/data/affixes.js`, `src/data/affixWeights.js`) as the
source of truth wherever the two disagree.

## The loop

```
TOWN (Bramblewood edge — the Chartmaker's Yard)
  forage hedge herbs  →  mix hedge ink  →  inscribe a chart (pick template,
  slot inks, roll affixes w/ good–bad twins)  →  socket chart at the Waystone
        ↓
DUNGEON (procgen, parameterized by the chart)
  bias affixes spawn ore/forage/log nodes  →  modifier affixes change combat math
  →  boss affix replaces the deepest room  →  reach the exit waystone
        ↓
RETURN (Wayfinding XP = tier×75 + good×40 + bad×10)  →  level up → deeper templates
```

## Decisions (and why)

| Decision | Choice | Why |
|---|---|---|
| Map-item model | **Chart + affix list** `[{id, good, resolvedId}]` | The shipped consumer (`src/scene/dungeon.js:253`) reads exactly this; the rival "orb forge" was dev-console-only, consumed by nothing. |
| Boss presence | **Boss-as-affix** (no affix → no boss; exit room has waystone + chest) | Keystone design; makes `hedgemother_den` mean something; tutorial Snug run stays calm. |
| Movement | **Keep WASD** + Space-roll + 1-4 hotbar | The controller is tuned (spec 36); click-to-move would forfeit dash/roll i-frames. Revisit post-slice. |
| Materials | **Keyed satchel** `Game.materials = {id: count}`, not Tetris cells | The Tetris inventory has no stacking; gear and reagents are different verbs (sibling project's 3-tab pattern). |
| Charts | **Chart case** `Game.charts: Array` — shown at the Waystone + Inscribing Table | Charts are consumed artefacts, not gear; keeps the Tetris grid for loot. |
| Trades (v1) | `carto`, `earth`, `wilds` with `xpForLevel(n) = (n-1)²·8 + (n-1)·32` | The three.js consolidation (10 skills) minus what the slice doesn't touch. "Trade" is the code term (CONTEXT.md — "Skill" is reserved for hotbar abilities). Combat XP is post-slice. |
| Affix list (v1) | Only affixes whose effects are **actually implemented** are rollable | No false promises in the preview UI. See table below. |
| Completion XP | On **exit via waystone** (chest-looted gate dropped) | Friction without value in v1; deviation noted. |
| Chart consumed | **On entry** | Keystone doc V1 ruling. Death inside = chart spent, lesson learned. |
| Player-facing name | **Wayfinding** (code key `carto`) | Commit 7a3484f rename is canon. |

## v1 affix table (7 of the 16 designed)

| id | good twin | bad twin | implemented effect |
|---|---|---|---|
| `mineral_vein` | Mineral Vein: 3–5 ore rocks | Barren: none | gather nodes (earth XP) |
| `bramble_bloom` | Bramble Bloom: 4–6 forage | Wilted: none | gather nodes (wilds XP) |
| `wood_grove` | Wood Grove: 3–5 log piles | Stripped: none | gather nodes (wilds XP) |
| `herbal_patch` | Herbal Patch: 6–9 herbs (the Lv-14 yield upgrade over bramble_bloom) | Frostbit: none | gather nodes (wilds XP) |
| `tyrannical` | +50% enemy HP, +30% chart XP | Erratic: per-enemy size+HP jitter | HP mult at spawn; ×1.3 completion XP |
| `festival_pace` | +50% enemy density | Lockstep: −25% density | density mult at spawn |
| `hedgemother_den` | Hedgemother boss in deepest room | Empty Throne: no boss | existing boss machinery |

The other 9 (bursting, frenzied, quiver, sprinter, fog_of_hedge, ink_spring, gem_seam,
tinder_cache, + 2 boss dens without GLBs) are not ported to `wyrd/data/charts.gd` yet —
they live in the design docs and the three.js prototype (`src/data/affixes.js`), gated
on their effects landing. Only implemented affixes appear in the data, so the UI never lies.

## Chart templates (v1)

| id | tier | reqCarto | affix slots | ink slots | cost | gen params |
|---|---|---|---|---|---|---|
| `snug` | 1 | 1 | 0 | 0 | 1× hedge_ink | 28-grid, rooms 6–9, gentle density, no boss ever |
| `tier_1` | 1 | 1 | 1 | 2 | 2× hedge_ink | 36-grid, rooms 7–11 |
| `hollow` | 2 | 10 | 2 | 3 | 3× hedge_ink | 48-grid (current defaults) |
| `briar_maze` | 2 | 15 | 2 | 3 | 3× hedge_ink | 48-grid, rooms 6–10, loop edges 0.55 (corridor-y) |

Score-config bands scale with grid area so the 0.70 acceptance gate keeps meaning.

## Materials & inks (v1)

- `wild_herb` — foraged in town (respawning patches) and via `herbal_patch`/`bramble_bloom`
- `bogiron_ore` — mined via `mineral_vein` nodes (dungeon-only → charts are the ore source, per the vision)
- `logs` — chopped via `wood_grove`
- `thorn_essence` — *planned*: enemy drop, to be charged by boss-affix costs;
  defined in MATERIALS but not yet dropped or spent in v1 (see implementation notes)
- `hedge_ink` — **mix 3× wild_herb** at the Inscribing Table
- `stoneground_ink` — **mix 2× bogiron_ore**; ×2.5 mineral_vein bias when slotted
- `refined_ink` — **mix 2× hedge_ink + 1× bogiron_ore** (slice-simplified recipe); +10% stability per pot when slotted

Ink bias (multiplies affix weights when slotted): hedge_ink ×2 on verdant biases
(bramble_bloom, herbal_patch, wood_grove); stoneground_ink ×2.5 on mineral_vein;
refined_ink biases nothing but adds stability.

## Town — the Chartmaker's Yard

Authored in code (`scripts/town.gd`, `scenes/Town.tscn`), a ~40×40 clearing:

- **Mara Linnet, the Wayfinder** (`wanderer_v3.glb`) — tutorial NPC, Bramblewood voice
- **Inscribing Table** (`chartmaker_stone_v2.glb` + `cartographer_compass.glb`) — Mix Ink / Inscribe Chart panel
- **The Waystone** (`waypoint_cairn.glb`) — socket a chart, step through
- **Herb patches** (forage nodes, respawn 20s) + oaks (`oak_v4.glb`), well, signpost dressing
- Existing Player/CameraRig/HUD/SkillBar instanced same as World.tscn

## Tutorial beats (tracked in `Game.tutorial_step`, objective line on HUD)

1. *Speak with Mara Linnet* → she explains charts
2. *Forage 3 hedge herbs* (glowing patches in the yard)
3. *Mix a pot of hedge ink* at the table
4. *Inscribe a Snug chart*
5. *Socket it at the Waystone and step through*
6. *(in dungeon)* — *Find the far waystone* (loot what you like on the way)
7. Return → first Wayfinding XP → *"Inscribe a Tier 1 chart — this time with an affix slot"* → tutorial done

## Architecture changes (wyrd/ vs the godot/ fork point)

- **`Game` autoload** (`scripts/game.gd`) — owns skills/xp, materials satchel, chart case,
  `active_chart`, scene routing (`enter_dungeon`/`return_to_town`), run results, tutorial step.
  Player state (hp, inventory, equipment) snapshots into it across scene changes.
- **`DungeonGen.generate(seed, cfg)`** — cfg from the chart: grid size, room bands,
  loop-edge fraction, `affixes`, `tier`, `boss_kind` (null unless boss affix good).
  Emits gather-node decor entries (`ore_rock`/`forage_node`/`log_pile` + item id).
- **`layout_loader.gd`** — reads `Game.active_chart`; spawns `GatherNode` interactables
  for gather decor; applies density/HP mults; boss block now conditional; spawns
  `ExitWaystone` at the exit tile.
- **Input fixes** — camera yaw moves E→C (Z/C pair; E stays interact); `_bind()`
  early-returns when the action exists (kills the duplicate-event leak on re-instance).
- **Death in town impossible**; death in dungeon keeps white-out respawn (chart not refunded).

## Deviations from the keystone doc

- Completion XP formula is the shipped `tier×75 + good×40 + bad×10`, not the doc's `tier×30…`.
- Chest-looted XP gate dropped (XP on waystone exit).
- Ink recipes simplified (no mortar/grindstone stations yet — the table mixes directly).
- maxSlots V1 hard-cap (2) honored via template `affixSlots` ≤ 2 in v1 templates.
- Refined ink no longer locks stability at 100% (keystone §affix design space) — it
  grants +10pp good-twin stability per pot (cap +50pp), and effective stability is
  hard-capped at 95%.
- Inscribe-time Wayfinding XP (shipped three.js: `tier×100 + good×40 + bad×15` at the
  chartmaker) dropped — XP lands only on completion, so the first level-up happens on
  the first return (tutorial beat 7).
