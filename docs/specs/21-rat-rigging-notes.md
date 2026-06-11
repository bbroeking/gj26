# Implementation notes — 21-rat-rigging

## Decisions
- **Approach A — procedural** (grill decision). `rat_anim.gd` is a
  `RefCounted` the rat's Combatant owns and ticks.
- **Whole-mesh hop-bob**, not body/tail rotation. The spec preferred
  rotating separable body/tail nodes; I went straight to the documented
  fallback — bob the rat GLB instance's `position.y` with `abs(sin)` (a
  hop that never dips below the floor). It works regardless of the GLB's
  node structure, needs no probing, and reads as a scurrying critter at
  the ARPG zoom. Idle = slow gentle bob; moving = faster, bigger hop.
- **Driven via `combatant._proc_anim`** — a new optional field on
  Combatant; if set, `_tick_ai` ticks it with the same `moving` flag the
  clip driver gets. `layout_loader` attaches a `rat_anim` to the rat
  (enemy model index 1) only.

## Deviations
- Body/tail-rotation path skipped in favour of the whole-mesh bob — see
  Decisions. The bob is the spec's stated fallback; chosen up-front for
  reliability (one fewer GLB-structure assumption).

## Tradeoffs
- A pure vertical bob has no leg/tail motion — minimal, but unambiguous and
  zero-risk. A tail waggle would add character if the GLB exposes a tail
  node — left as a followup.

## Surprises
- _none_

## Followups
- If `enemy_rat_v1.glb` exposes a separable tail node, add a tail waggle on
  top of the bob for more character.

## Status
COMPLETE. The rat hop-bobs (idle + scurry) via `rat_anim.gd`, driven by its
Combatant. Rigged enemies unaffected; `test_combat.gd` 20/20; World boots
clean.
