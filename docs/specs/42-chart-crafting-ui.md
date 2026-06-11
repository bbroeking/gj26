# 42 — Chart crafting: placement UI + onboarding tutorial

> **Outcome**: inscribing a chart feels like crafting at a bench — you DRAG
> a chart base and ingredients into sockets, watch the result slot preview
> the chart and its odds live, and grab the finished chart out — and a
> reworked tutorial teaches the whole loop hands-on, gated step by step.

## Why

The Inscribing Table is the game's signature verb but plays like a settings
menu (click template in a list, click inks, press Inscribe). The user wants
the Minecraft read: physical placement → visible result. Crafting-by-
placement also makes the tutorial teachable by pointing ("drag the herb
pot HERE") instead of describing.

## Scope

**In:**
- **Phase 1 — the bench UI** (replaces `inscribing_panel.gd`'s interaction
  model; the logic layer is UNTOUCHED — see Contract):
  - Left: the **satchel tray** — draggable ingredient plates for every
    ownable input: chart bases (one per UNLOCKED template, shown as rolled
    parchment with name + tier), ink pots (hedge/stoneground/refined with
    counts), trophies. Locked templates show ghosted with "Wayfinder N".
  - Center: the **bench sockets** — 1 base socket (large, center), up to
    3 ink sockets (revealed by the placed base's `ink_slots`), 1 trophy
    socket (revealed when `affix_slots > 0`). Drag from tray to socket;
    click a socketed item to return it. Invalid drops snap back (reuse
    `inventory_panel.gd`'s drag pattern: `_held_item`/`_try_drop_at`/
    snap-back, lines 85–319).
  - Right: the **result slot** — once a base is placed, renders the chart
    preview: name, tier, and the live odds list (`compute_weights` +
    `effective_stability`), trophy guarantee line when slotted, and the
    full cost with have-counts (`craft_cost`). The result is grabbed OUT
    (drag or click) to craft: `spend_materials` → `inscribe` → `add_chart`
    — same call order as today (panel lines 379–392).
  - Ink mixing stays on this bench as a small **mixing pot** sub-area
    (drag herbs/ore onto the pot → `mix_ink`), so the whole material→ink→
    chart chain lives at one station.
  - Esc closes; pause semantics unchanged. Kit styling throughout
    (chips, wells, wood frame); design round in `wayfinder-ui` BEFORE
    implementation (one page: 'Crafting Bench'), per the design-pass loop.
- **Phase 2 — onboarding rework** (the tutorial must teach the bench):
  - Steps 2/3 (mix ink, inscribe Snug) become **guided crafts**: the bench
    highlights the exact socket/ingredient for the current step (pulsing
    kit-gold outline), other interactions soft-locked; Mara's step dialog
    rewrites to placement language ("Set the Snug parchment on the bench.
    Now the ink — pour it into the round socket.").
  - Step 6 (first affix chart) teaches odds reading: highlight the result
    slot's odds list; require one ink slotted before the craft unlocks.
  - First-time hint (`first_time_hint("bench")`) for post-tutorial visits.
  - Tutorial advancement keeps the SAME triggers (mix_ink → 2→3;
    add_chart snug → 3→4; add_chart non-snug at 6 → 6→7) so
    `test_wyrd_transitions.gd` beats stay valid.
- **Phase 3 — tests + audit**: transitions test drives the new flow
  programmatically (call the bench's socket/craft methods directly, not
  pixel drags); capture rounds; suites green.

**Out (explicit non-goals):**
- Any change to `data/charts.gd` math/signatures (see Contract).
- New templates/affixes/inks; recipe-grid crafting for ITEMS (the anvil/
  hearth keep their list UIs for now — one bench at a time).
- Gamepad/controller input.

## Contract (from the 2026-06-12 surface map — do not break)

- Same calls, same order, same types: `ChartsData.craft_cost(template_id,
  ink_ids: Array, trophy_id: String)`, `compute_weights(tier, ink_ids,
  carto_lv)`, `ink_stability_bonus(ink_ids)`, `effective_stability(id,
  carto_lv, bonus)`, `inscribe(template_id, ink_ids, carto_lv, trophy_id)`;
  `Game.mix_ink / can_afford / spend_materials / add_chart`.
- `craft_cost` already ignores inks/trophy when `affix_slots <= 0` — the
  bench mirrors that by not revealing those sockets.
- Tutorial triggers unchanged (game.gd 363–377, 514–527).
- Test contract: test_wyrd_loop.gd lines 48–228 (cost/weights/stability/
  inscribe shapes) and transitions beats 3–4 must pass unmodified except
  where they drive the PANEL (those may switch to bench methods).

## Files

| Path | Action |
|---|---|
| `wyrd/scripts/ui/crafting_bench.gd` | new — the placement UI |
| `wyrd/scripts/ui/inscribing_panel.gd` | delete after parity (bench replaces it) |
| `wyrd/scripts/inscribing_table.gd` | modify — opens the bench |
| `wyrd/scripts/game.gd` | modify — "bench" first-time hint; tutorial highlight state |
| `wyrd/scripts/wayfinder_npc.gd` | modify — steps 2/3/6 dialog in placement language |
| `wyrd/scripts/town.gd` | modify — WYRD_UI_SHOT=bench hook |
| `wyrd/test_wyrd_transitions.gd` | modify — drive bench methods |
| `docs/specs/42-chart-crafting-ui-notes.md` | new — deltas |

## Acceptance criteria

1. A new player can craft a Snug touching only the bench: drag base →
   sockets appear → result slot previews name/cost → grab result → chart
   in case. Zero list-menus involved.
2. Ink sockets/trophy socket appear only when the placed base supports
   them; odds update live as inks are socketed/removed; the trophy line
   shows the guaranteed den.
3. Mixing: dragging 3 herbs onto the pot yields hedge ink (and the other
   two recipes likewise), with counts visibly updating.
4. Tutorial steps 0–7 complete end-to-end on the bench with guided
   highlights; `test_wyrd_transitions.gd` passes; a fresh-save manual run
   reaches step 7 without reading any doc.
5. All three suites green; 'Crafting Bench' design page approved before
   implementation; captures match the design side-by-side.

## Open decisions

- **Result-grab gesture** — drag-out vs click-to-craft. Recommend: click
  crafts straight to the chart case (charts aren't grid items), with a
  satisfying stamp animation; note the deviation from literal Minecraft.
- **Mixing pot placement** — on-bench (recommended, keeps one station) vs
  a separate cauldron prop.
- **Highlight mechanism** — drawn pulse on socket rects (recommended) vs
  a darkened-screen cutout.

## References

- Surface map (2026-06-12 scout report) — panel lines, signatures, tests.
- `inventory_panel.gd` drag pattern; kit tokens in `wyrd_ui.gd`.
- Design-pass lessons (`wyrd-ui-design-pass.md`): short briefs, name every
  data point, one page per artboard file.
- Memory: white-texture gotcha (preload bench art in `_ready`).

## Done check

- [ ] Design page approved; bench implemented to the contract
- [ ] Sockets/preview/cost/odds all live; mixing on-bench works
- [ ] Tutorial rework teaches it hands-on; fresh-save run to step 7
- [ ] Suites green; inscribing_panel deleted; notes updated
