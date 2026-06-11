# Implementation notes — 38-tools-mute-globes-ui

## Decisions
- **Mute = F10 + master bus.** `AudioServer.set_bus_mute(0, …)` silences the
  one-shot pool and the music channel in one flip; state lives on `Game.muted`,
  persists in the save, restores in `Game._ready`. HUD shows "F10 mutes" dim /
  "MUTED · F10" terracotta under the Focus globe. No clickable icon — the
  label + keybind covered the acceptance and a button invited mis-clicks next
  to the action bar.
- **Tool slots sit as a third doll row** (Pickaxe at (6,268), Axe at (88,268)),
  grouped under the body column; the gold readout moved down to y=364 to clear
  them.
- **Tool speed −30%** via the item's `base_value` (0.30) read by
  `GatherNode.channel_seconds()` — so better tools later just carry a bigger
  number, and the Earthcraft-10 perk stacks multiplicatively (1.6s → 1.12s →
  0.73s).
- **Tools use `base_stat: "gather_speed"`** — `_derive_stats`' `_add_stat`
  ignores unknown keys, so tools never leak into combat stats.
- **Globes are `_draw`-painted** (circular-segment polygon for the liquid,
  meniscus line, glass highlight, double ink rim) — no textures, dodging the
  first-load-in-_draw white-texture bug entirely.
- **Bottom cluster geometry (raw px):** globes at ±220 from bottom-center,
  R=44; skill slots 72px between them (±156); draught chip centered under the
  HP globe, mute hint under Focus.

## Deviations
- **Spec said "small clickable speaker icon"** under open decisions — shipped
  label-only (see Decisions).
- **Charts-tab capture shows the empty state** (dev boot has no charts) — the
  audit reviewed it as-is; a stocked-charts capture needs a dev hook that
  pre-adds charts (Followups).

## Tradeoffs
- **Template buttons in the Inscribing Table now `clip_text`** with fixed
  225px width — "Chart of the Summit — Wayfinder 16" truncates, tooltip
  carries the full line. The alternative (auto-width buttons) was what pushed
  column 3 off the panel edge.

## Surprises
- **The skill bar had been rendering off-screen everywhere.** Spec-35's
  `UI_SCALE` CanvasLayer transform scales anchored children's resolved
  positions — bottom-anchored slots land at y≈936 on a 720px window. The
  player_hud's matching transform was never actually applied (comment only),
  which is why HUD elements showed. Removed the transform and sized the bar
  in raw pixels. **B1's icons/tooltips had never actually been visible in a
  capture.**
- **The dialog frame PNG carried an opaque black matte** — stripped to alpha
  with a luminance feather in place (`assets/ui/dialog_frame.png` modified
  in-repo).
- **`_test_save_roundtrip` writes and then deletes the REAL save path**
  (`SaveGame.save` → `SaveGame.clear()`). No real save existed so no harm,
  but any future real progress would be destroyed by a loop-test run.

## Followups
- Back up/restore the player save around `_test_save_roundtrip` (or point
  SAVE_PATH at a test file via env) — flagged above.
- Painted icons for pickaxe/axe (flat color plates now) + ICON_TEX entries.
- Tool tiers (brindle/cinderbloom GLBs already exist in models/) wait on A6
  node tiers.
- Dev hook to pre-stock charts for a non-empty charts-tab capture.
- Globe juice: low-HP pulse and a slosh tween on damage — static liquid now.
- The equipped-tool GLB could render in the player's hand during the gather
  channel (models exist, anim hookup is the work).
