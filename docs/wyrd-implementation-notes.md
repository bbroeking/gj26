# Wyrd slice — implementation notes (2026-06-09)

Companion to `docs/wyrd-slice.md` (the design). This file records what was
actually built, decisions made outside the design doc, and known gaps.

## What runs

`wyrd/` is a full fork of `godot/` (everything the eval project had still
works) plus the slice. Boot: `godot --path wyrd` → Town. The loop:

talk to Mara → forage 3 herbs → mix hedge ink → inscribe a Snug at the
table → socket it at the Waystone → snug cellar (28-grid, no boss, gentle
density) → far waystone → back to town, +75 Wayfinding XP (level 2) → Tier 1
chart with a real affix slot → tutorial done.

## Verification

- `test_wyrd_loop.gd` — 38 checks: weights gating, ink bias, stability cap,
  inscribe shapes, completion XP, satchel/mix/tutorial logic, cfg-driven
  generation, gather decor counts, bad-twin omission, determinism.
- `test_wyrd_dungeon_scene.gd` — 5 checks: real World.tscn build from a
  chart (gather nodes, exit waystone, boss-as-affix, enemies).
- `test_wyrd_transitions.gd` — 26 checks: the full tutorial loop through
  REAL scene changes, including chart consumption, XP, level-up, and
  input-map hygiene across re-instanced players.
- Pre-existing suites re-run green (procgen, typed rooms, items, inventory,
  drops — drops D5 patched for the intentionally-shared inventory).

Dev helpers: `WYRD_SHOT=1` self-screenshots Town (`/tmp/wyrd_town.png`) or a
dungeon (`/tmp/godot_selfshot.png`); `WYRD_DEV_CHART=tier_1` boots straight
into a chart run with all gather affixes landed good.

## Decisions made during implementation (beyond the design doc)

- **Autoloads load in `--script` mode in Godot 4.6.** Tests must reuse the
  real `Game` autoload (mounting a second node named "Game" gets renamed and
  silently shadows nothing). Burned an hour; recorded here so it doesn't again.
- **`Game` lookups use `get_tree().root.get_node_or_null("Game")`** instead
  of `"/root/Game"` — identical in production, and it also resolves under the
  SceneTree-script test harness.
- **GLB sizing**: AI-generated GLBs carry internal node transforms, so the
  naive `get_aabb()` merge under-measures them (Mara spawned 4 m tall). The
  shared `scripts/glb_fit.gd` accumulates transforms; everything that places
  a GLB by target height uses it.
- **Dialog `finished` fires exactly once** (`_done` guard) — without it,
  mashing E on the last page advanced the tutorial several steps at once.
- **Snug density**: templates can carry `enemy_density` in their gen block
  (snug = 0.5) — multiplies with the festival_pace twins.
- **Exit waystone in a boss chart** rises only when the boss dies (it would
  otherwise spawn inside her on the same tile).
- **E-key conflict resolved toward interact**: keyboard camera yaw moved from
  Q/E to Z/C (right-drag orbit unchanged).

## Adversarial review round (same day)

A 4-lens review (GDScript correctness / cross-scene lifecycle / player-facing
honesty / conventions-vs-docs) with per-finding adversarial verification
confirmed ~19 issues, all fixed:

- **Critical** — dying to the Hedgemother sealed the run forever (gates stay
  raised, exit waystone only spawns on her death). Player now emits `died`;
  layout_loader drops the gates and `boss.reset_fight()` resets the encounter.
- **Major** — the dead-input gate in `_physics_process` sat *below* input
  handling, so a dead player could bank the run at the exit waystone during
  the white-out. Gate moved above inputs + a belt-and-suspenders check in
  `ExitWaystone.interact`.
- **Major** — run-completion/level-up toasts were emitted into the dungeon HUD
  one frame before it was freed. `Game.notify()` buffers across scene changes;
  the next HUD drains `pending_toasts` in `_ready`.
- **Major** — Snug charged for a slotted ink that biased nothing (0 affix
  slots). Snug is now 0 ink slots, and `craft_cost` never charges inks on a
  slotless template.
- **Major** — `Game.skills` collided with the blessed hotbar-Skill term →
  renamed to **trades** (`trade_lv`, `TRADE_NAMES`); CONTEXT.md Language
  extended with Trade / Chart / Affix / GatherNode / Waystone / Satchel.
- **Honesty batch** — tyrannical's "+30% XP" now real (×1.3 completion XP);
  Erratic jitter drives visible enemy *scale* along with HP; Empty Throne
  stamps an actual sarcophagus; bossless exit rooms get the promised reward
  chest; herbal_patch is a 6–9 yield upgrade (was a bramble_bloom duplicate);
  the inscribe preview lists *all* eligible affixes (the cap hid exactly the
  low-weight boss affix); ink-bag counts subtract the template's base cost.
- **Tutorial robustness** — steps re-check on entry (pre-gathered herbs /
  pre-inscribed Snug no longer stall), mix step requires hedge ink
  specifically, and in-dungeon the HUD shows "Find the far waystone" instead
  of a frozen town objective.
- Plus: dialog advances only on left-click (wheel notches chewed pages),
  toast tweens are pause-immune, and the player is i-framed through the
  one-frame snapshot→scene-change gap.

Verified after the round: all wyrd suites green (38 + 5 + 28, including new
dead-player and toast-buffer regressions) and the pre-existing suites
unchanged (`test_skills` T4 fails identically in the original `godot/`
project — pre-existing, not a slice regression).

## Known gaps (deliberate, v1)

- ~~`thorn_essence` is defined but nothing drops it~~ — superseded by the
  Session 3 trophy chain below (elites drop it; the trophy slot spends it).
- Gathering is instant (no channel time, no tool gating).
- No combat XP; only carto/earth/wilds skills exist.
- Bad-twin effects beyond omission/jitter/density (e.g. Erratic's "random
  secondary mod") are approximations; 9 of the 16 designed affixes are not
  yet rollable (kept out of the data so the UI never lies).
- Materials satchel renders inside the Inscribing Table panel only; no
  standalone pouch UI.
- Death inside a chart respawns at hearth/entry (run continues); the chart
  is never refunded.
- Town visuals are a first pass (flat clearing + GLB dressing); concept-art
  pass and Bramblewood buildings are future work.

## Session 3 (2026-06-10) — economy + the endgame chain

Playtest feedback round (zoom, roll, UI, combat feel) was applied earlier the
same session; this round closed the loop the design runs on:

- **Camera** default zoom 17 → 12 (playtest: "a map screen, not a character").
- **Gold economy** — `Game.gold` (saved), `data/economy.gd` prices,
  `sell_item`/`buy_ware`, Hod Tenter (`vendor_npc.gd` + `ui/vendor_panel.gd`)
  at the forge. Selling gear is the faucet; his ware shelf is the sink.
- **Trophy chain** — boss dens removed from the random affix pool; a trophy
  slot at the Inscribing Table guarantees the matching den (stability still
  rolls). Elites drop thorn_essence (25%) → Hedgemother → tusker_tusk →
  Boar → wightpelt → Wolf → alpha_fang → **Chart of the Summit** (tier 3
  template) whose gen block names its own boss: the **Hedgemother Queen**
  (scale 4.6, 160 hp, 13 dmg). `summit_cleared` is saved and unlocks Mara's
  epilogue.
- **Per-kind boss damage** (`boss.damage` var) and **tier danger scaling**
  (+15% trash HP per tier past 1).
- Suites: 60 + 5 + 28 green, incl. trophy-forced inscribe, den-free random
  pool, summit cfg, sell/buy math, gold+flag save roundtrip.

### Town environment pass (same day — "too low poly / empty")

`scripts/town_environment.gd` owns the density layer: mottled two-green
noise ground shader (the flat plane was the real offender), a meandering
dirt-path web (plaza hub, 6 spokes, discs narrow at the hub so they don't
pool into mud), a 34+14 oak treeline ring enclosing the clearing, ~700
MultiMesh grass tufts + ~140 flower dots (kept off paths/stations), and
scatter dressing (lanterns, drying rack, practice dummy, brambles, bushes).
Four new Meshy props (~92 credits): `prop_fence_v1` (garden line + south
entrance wings, runs measured via GlbFit so segments join), `prop_flowers_v1`
clumps, `prop_market_stall_v1` at Hod's counter, and `building_cottage_v1` —
a thatched storybook cottage replacing the blocky `cottage_v3` placeholder.
Lesson reaffirmed: use Meshy's raw lowpoly GLBs directly (clean_ai_mesh.py
strips textures — its repaint flow is three.js-only).
