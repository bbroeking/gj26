# Implementation notes — 27f-polish

## Decisions
- **Tooltip rendered inside `inventory_panel._draw`** (not a separate
  scene/node) — one redraw owns the whole panel; one less Control to
  position; tooltip stays in the same paint pass as the held-item preview.
- **Hovered-item resolution** — `_hovered_item()` checks grid first, slot
  second; returns null while dragging (`_held_item != null`) so tooltips
  don't fight the drag preview.
- **Tooltip lines** — name (rarity colour, 14pt), `<Rarity> <Category>`
  (grey, 11pt), spacer, base stat (cream, 12pt), each affix (blue, 12pt).
  Uses `Affixes.format_affix()` from 27a so the readout is consistent with
  the in-fact-applied stat (e.g. *"+12 Maximum Health"* not raw `hp 12`).
- **Tooltip position** clamps to screen edges — flips to the left of the
  cursor if it would overflow right; bottom-aligned if it overflows down.
- **Loot-rain stagger** runs only when `pile.size() > 1` — single-drop
  enemies stay instant; boss kills cascade 80 ms apart. The combatant
  captures its world position *before* scheduling, since the body
  `queue_free`s during the death tween and a deferred call wouldn't see
  the stale `global_position` reliably.
- **SFX wired in three places:**
  - `player._try_grab` success → `Sfx.play("pickup")`.
  - `player._on_gear_changed` (covers both equip + unequip via the
    `Equipment.changed` signal) → `Sfx.play("equip")`.
  - `inventory_panel.toggle()` → `Sfx.play("inv_open")` (open *and* close).
- **Always redraw on mouse-motion** when the panel is visible — the
  tooltip needs to follow the cursor; `_draw` is cheap enough (a handful of
  rects + text) that throttling isn't worth it.

## Deviations
- **Ground-pickup hover tooltip — deferred.** The spec mentioned hovering
  the world-space pickup label would also show a tooltip. That needs a
  camera-ray-cast on mouse motion (or a 3D `_input_event` on the pickup's
  Area3D), and the world label already shows the name in the rarity
  colour. Marked as a followup.
- **Cell hover-highlight + slot-type icons — deferred.** The spec listed
  them as "polish v1." The existing rarity borders + slot text labels are
  legible; bespoke art is a clear v2 polish pass.

## Tradeoffs
- **Tooltip inside `_draw` vs as a separate Control** — separate would let
  Godot's UI theme system style it. In-panel `_draw` is simpler + matches
  the rest of the panel's render style. Trade theming for cohesion.
- **`equip` SFX fires for both equip *and* unequip** (one signal). Two
  sounds would be more readable but cost double the credits and complicate
  the `Equipment.changed` payload. Lean: one is fine for v1.

## Surprises
- **The loot bug from playtest** ("we can't loot") was actually a *bug*,
  not a 27f scope item: pickup `setup()` called `monitorable = true`
  inside the arrow-hit signal callback chain, which Godot blocks with a
  C++ error → pickup never became detectable. The fix was to *remove* the
  explicit set — Area3D defaults to `monitorable = true` already, which is
  what we want, so the fix was simpler than expected. Captured as part of
  this pass since the user reported it alongside 27f.

## Followups
- **Ground-pickup hover tooltip** — needs a 3D-space hover-detect; the
  pickup label is already informative enough that this is a "nice to
  have."
- **Cell hover-highlight + slot-type glyphs** — bespoke art polish.
- **Character-sheet panel** — show the totals from `derived_stats` (HP,
  damage, crit chance, etc.) so the player sees the cumulative effect of
  their gear without inspecting each tooltip. Natural next polish.
- **Hedgemother feedback from playtest** — the user reported "the
  hedgemother fight doesn't work" alongside the loot bug. The loot bug
  fix may resolve it indirectly (the monitorable error fired during the
  boss kill too, which could have cascaded). Needs a fresh playtest with
  the fix in place to confirm — and a more specific symptom if it's still
  broken.
- **Long-running sessions** — pickups never time out; old loot piles
  accumulate. A pickup max-age (~60 s) is a polish task.

## Status
COMPLETE — hover tooltips render in the panel for grid items *and*
equipment slots; multi-drops cascade 80 ms apart; pickup / equip / inv-
open SFX play via ElevenLabs-generated files. **All seven harnesses
green (59 evals: items 7 · inventory 8 · drops 5 · equipment 7 · stats 5 ·
movement 6 · combat 21)**, World boots score 0.93–1.00. Spec 27 (the full
item / loot / inventory / equipment / stats / polish loop) is fully
shipped.
