# Implementation notes — 22-playtest-feel-tuning

## Decisions
- **`docs/PLAYTEST.md` is a 21-row checklist** — one row per feel dimension,
  each naming the controlling constant + its current value + a rating
  field. Covers movement, fire, hit-feel, AI, the boss, pathfinding,
  camera, and the procedural anims (specs 18/21).
- **Build re-exported for the playtest.** The web build was stale (spec-16
  era); re-exported with specs 17–21 — the export `include_filter` gained
  `boss.gd`, `boss_bar.gd`, `ranger_anim.gd`, `rat_anim.gd`, `hitstop.gd`,
  `BossBar.tscn` (the "scenes" filter still doesn't follow preloads).

## Deviations
- _none — this spec is a checklist + a tuning pass; the tuning half is
  pending the user's playtest._

## Surprises
- **Web build rendered enemies as chrome spheres.** The Meshy GLB materials
  carry a metallic value that Godot's desktop Forward+ renderer handles
  subtly but the web **Compatibility** renderer blows out into mirror
  chrome. Fixed with `layout_loader._unmetal()` — zeroes `metallic` on
  every enemy/boss surface material at spawn; matte in both renderers.
  (Not a feel issue, but it would have wrecked a browser playtest.)

## Followups
- **The tuning pass itself** — apply the constant changes the user's
  filled-in `PLAYTEST.md` calls for, then re-run `test_combat.gd`. Pending
  the playtest.
- Any *structural* problem the playtest surfaces becomes its own spec
  (per the spec's scope), not a constant tweak here.

## Status
PREPARED — awaiting the user's playtest. `docs/PLAYTEST.md` checklist is
written; the build is current and renders correctly (browser + native).
The tuning pass + eval re-run happen once the user has played and rated.
