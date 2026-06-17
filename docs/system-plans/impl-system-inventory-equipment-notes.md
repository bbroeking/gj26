# Implementation notes — system-inventory-equipment

The delta between the build doc and what actually shipped. Not a restatement of
the spec.

## Decisions
- **Task 9 (compare-on-hover) shipped first**, as the doc's "Order of work"
  recommended — it was the only gap flagged *(blocker for feel)*. Implemented
  in `inventory_panel.gd` as `_tooltip_lines` → `_compare_lines` +
  `_accumulate_stats` helpers. Deltas reuse `Affixes.format_affix` on the
  magnitude, then re-sign (▲ green gain `Color(0.20,0.52,0.24)` / ▼ terracotta
  loss `WyrdUi.TERRACOTTA`), so the percent/round rules match the affix lines
  above them. Compare only fires on a **grid** hover (`_cursor_cell.x >= 0`),
  never a slot hover (the slot item *is* the equipped one).
- Deltas that round to a no-op on screen are dropped (`format_affix` on the
  magnitude begins with `+0 ` or `+0%`), so e.g. two crit items differing by
  0.004 don't show a "▲ +0%" line. The "vs. equipped <Slot>" header is built
  *after* the rows, so it never appears over an empty compare.

## Surprises
- **Consumable stacking (Phase 2, Tasks 2–5) is moot as written.** The doc
  assumed draughts/tonics are grid items needing `stack_max`/`stack_count` in
  `items.gd:KINDS` and a `find_stack_cell` path. They are not: `items.gd:KINDS`
  holds **only gear** (weapons, armor, rings, trade tools). Draughts/tonics are
  defined in `data/crafting.gd` (`DRAUGHTS`, `BUFF_DRAUGHTS`) and live in the
  **satchel as counted materials** — quaffed via `game.spend_materials({id:1})`
  / `has_material`. They already "stack" as an unbounded integer count and
  never occupy a Tetris cell. Adding `stack_max`/`stack_count` to gear KINDS
  would be dead fields. **Not implemented** — the feature the doc describes does
  not exist in this inventory model.

## Followups
- If a future design *does* put usable consumables in the grid (e.g. a thrown
  flask that takes a cell), revisit Tasks 2–5 then — the `find_stack_cell` /
  badge-render / save-roundtrip plan is sound, it just has no subject today.
- The compare-on-hover is validated by a direct logic check (upgrade ▲, down-
  grade ▼/−, identical→empty), not yet by an automated suite — no suite loads
  `inventory_panel.gd`. A headless test would need to instantiate the Control
  and call `_compare_lines` directly (as the throwaway check did).
