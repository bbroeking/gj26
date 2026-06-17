---
title: Economy, Gold & Vendor
domain: Gather · Craft · Economy
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Economy, Gold & Vendor

> The faucet (sell gear to Hod) and the sink (buy materials/inks at convenience-tax prices) are wired and working; the anti-arbitrage gate, more gold sinks, and a second vendor remain unbuilt.

## Current state

`wyrd/data/economy.gd` (lines 10–30) defines the full data layer: `SELL_BY_RARITY` (normal 4g → unique 90g) and six `WARES` entries (wild_herb 3g through refined_ink 38g). The comment on line 6 states the design intent — "buying is a convenience tax, not a bypass of the chart loop" — but no code enforces this; a player with enough gold can bypass gathering entirely by buying stacks of refined_ink from Hod.

`wyrd/scripts/vendor_npc.gd` (lines 9–31) is a thin `Interactable` that spawns `npc_hod_v3.glb`, normalises his height, and opens `vendor_panel.gd` on E. The GLB and the panel are both live.

`wyrd/scripts/ui/vendor_panel.gd` (lines 146–189) renders a two-column counter: sell (left, scrollable) pulls `game.inventory.items` and calls `game.sell_item()`; buy (right) iterates `EconomyData.WARES` and calls `game.buy_ware()`. The `_VendorCard` inner class (lines 198–289) uses the WyrdUi Kit correctly — icons pre-loaded in `_ready` (line 44–47) to avoid the white-rect-in-`_draw` gotcha. Gold readout updates live via `_render()`.

`wyrd/scripts/game.gd` (lines 328–346) implements `sell_item` and `buy_ware`; both emit `gold_changed` and call `save_now()`. There is **no sell-block for trophies** — `sell_item` removes any item that exists in `inventory.items` without checking category. Boss trophies would be sold if they ever land in the Tetris inventory. Per `economy.gd` line 21–22 the comment says "Boss trophies are NEVER sold" but this is not enforced in code. `ledger.gd` is also listed as a followup in ADR 0013 (line 99) and does not exist yet.

Gold sinks currently: Hod's six material/ink wares only. Chart inscribing costs inks (material spend), not gold. No repair, no map-buying, no unlock fees.

**Status correction:** pre-filled guess was `complete`. The data layer and the counter UI are solid, but the anti-arbitrage gate is absent, `ledger.gd` is missing, and the gold-sink surface is thin. Correct status: `partial`.

## Gaps — what needs fleshing out

1. **[blocker] Anti-arbitrage gate** — `sell_item` (game.gd:328) has no level-or-chart gate. A fresh character can sell one Unique and buy 18 refined_inks outright, bypassing all gather progression. The comment in `economy.gd` line 5–7 states the intent but nothing enforces it. Fix: gate `buy_ware` on `trade_lv("wayfinding") >= tier_threshold(ware_id)`.
2. **Trophy sell block** — trophies must never reach Hod's counter (economy.gd:21). Currently no category check in `sell_item`. Add a guard: `if item.get("category") == "trophy": return 0`.
3. **`ledger.gd` missing** — ADR 0013 followup (line 99). Boss trophies are stated as a live, capped stat source (source #3 in the ADR), but the seam is unwired. The Ledger is part of the economy because it replaces gold-purchased power with chart-gated power.
4. **Gold sink surface is thin** — only six buy lines. Once a player is well-stocked, gold pools with no outlet. Planned sinks: chart-tier unlock fee (gold + trophies), Hod's repair slot (small recurring drain), Quill's lore-items shelf.
5. **Single vendor** — `town.gd` spawns one `VendorScript` (line 13, near FORGE_POS). `quill_npc.gd` exists (line 14) but Quill has no buy/sell panel. A second vendor (herbalist/alchemist at QUILL_POS / STILL_POS) would separate the material shelf from a lore-items/convenience shelf and give the yard more economy texture.
6. **Level-scaling wares** — Hod's shelf is static. At higher Wayfinding levels deeper inks (not yet in `WARES`) and tier-2 materials should appear. `WARES` should be a function of `trade_lv`, not a flat const.
7. **Buy quantity** — `buy_ware` always purchases exactly 1. No bulk-buy shortcut. Minor friction, worth a `+5` button for inks.

## Plan

### Phase 1 — Safety rails (anti-arbitrage + trophy block)

- Add `_ware_min_lv` table to `economy.gd` mapping each `WARES` id to the minimum Wayfinding level required to purchase (e.g. `hedge_ink`: 2, `refined_ink`: 6).
- In `game.gd:buy_ware` (line 339), check `trade_lv("wayfinding") >= EconomyData.ware_min_lv(id)`; on fail: `notify("Hod eyes you. 'That ink's not for beginners.'")`
- In `game.gd:sell_item` (line 328), add: `if String(item.get("category","")) == "trophy": return 0` before the price lookup. Toast: `"Trophies pass through the hollows, not the counter."` (consistent with economy.gd line 21 comment).
- Unit test: add a case to `test_wyrd_loop.gd` asserting `buy_ware("refined_ink", 38)` returns `false` at Wayfinding lv 1, and `true` at lv 6.
- **DoD:** headless `test_wyrd_loop.gd` green; manual vendor test shows refined_ink greyed-out at lv 1; a dummy trophy item cannot be sold (returns 0 and stays in inventory).
- **Effort:** S

### Phase 2 — `ledger.gd` stub + trophy-sell enforcement

- Create `wyrd/data/ledger.gd` as a `RefCounted` data class: `TROPHY_SLOTS` dict (boss_id → `{stat, cap, per_trophy}`), `static func bonus(trophies: Dictionary, stat: String) -> float`.
- Wire `game.gd` `trophies` dict (already tracked in save via `save_game.gd`) into `player_controller._derive_stats()` alongside gear bonuses.
- The stat boost is capped per slot (matching ADR 0013 source #3), so buying any amount of gear can never replicate it.
- Update `vendor_panel.gd` sell column: filter out items where `category == "trophy"` before building the sell list (belt-and-suspenders on top of Phase 1's `sell_item` guard).
- **DoD:** `_derive_stats()` returns a higher `damage` value when a boss trophy is in `game.trophies`; headless stats suite (`test_stats.gd` if it exists, or a new case in `test_wyrd_loop.gd`) asserts the bonus; vendor panel never shows trophy rows.
- **Effort:** M

### Phase 3 — Expanded gold sinks

- **Chart unlock fee:** `game.gd:enter_dungeon` checks if the chart's tier requires a gold fee (e.g. tier 3+: 25g per chart). Defined in `economy.gd` as `CHART_TIER_FEE := {3: 25, 4: 50, ...}`. The fee is waived if the player has the relevant boss trophy (completing the chart loop rewards that run as "free").
- **Hod's repair slot:** add a "Repair all gear" ware to `WARES` at a price proportional to equipped item count/rarity. This gives a recurring small drain without grinding.
- **DoD:** A Wayfinding 7 player entering a tier-3 chart is charged 25g (toast confirms it); entering with insufficient gold is blocked (toast). Repair ware appears on Hod's shelf and deducts gold correctly.
- **Effort:** M

### Phase 4 — Level-scaled wares + Quill's shelf (expansion)

- Refactor `WARES` in `economy.gd` from a flat Array to a `static func wares_for_level(lv: int) -> Array` that adds deeper-tier materials (e.g. `hedgesteel_ore`, `moonsilver_ore`) and tier-2 inks as lv increases.
- Update `vendor_panel.gd:_render()` to call `EconomyData.wares_for_level(game.trade_lv("wayfinding"))` instead of `EconomyData.WARES`.
- Give `quill_npc.gd` a buy panel with lore-items / convenience goods (e.g. pre-rolled common charts, a satchel upgrade token). Wire via a second `VendorPanelScript`-style panel on `QuillScript.interact()`. Keep Quill's wares gold-priced at a steeper markup than Hod to reinforce that gathering is always cheaper.
- **DoD:** At lv 1 Hod's shelf shows 4 wares; at lv 7 it shows 8+. Quill opens a working buy panel. No regressions on the headless suites.
- **Effort:** L

### Phase 5 — Bulk-buy UX (polish)

- Add a `+5` ghost button to each buy card in `_VendorCard.setup_buy()` (visible only when `have >= 0` and `gold >= price * 5`). Calls `buy_ware` five times in a loop (keeping `save_now()` outside the loop — one write).
- **DoD:** Player can buy 5 wild_herbs in one click; gold decrements by 15; satchel shows 5 herbs. No double-save.
- **Effort:** S

## Dependencies & links

- [[system-charts-wayfinding]] — Chart-tier unlock fees (Phase 3) gate on chart tier and trophy possession; economy.gd's `CHART_TIER_FEE` must align with the tier definitions here.
- [[system-bosses]] — Trophies are the anti-arbitrage anchor for Ledger (Phase 2) and chart-fee waivers (Phase 3); boss design sets the trophy cadence that keeps the economy gated.
- [[system-gathering]] — Hod's wares must stay 3-4× the effective time-cost of gathering the same material; any gather-speed changes should trigger a re-check of `WARES` prices.
- [[system-crafting]] — Ink recipes at the Inscribing Table are the primary sink for gathered materials; gold buys inks only as a convenience bypass gated by Wayfinding level (Phase 1).
- [[system-items-affixes]] — `SELL_BY_RARITY` values must remain lower than the crafting cost to forge an item of that rarity (otherwise selling and re-buying is a gold exploit).
- [[system-drops-loot]] — Loot drop rates are the faucet on the sell side; if drops are generous the sell-side gold inflow rises and sink expansion (Phase 3) becomes more urgent.
- [[system-trades-progression]] — Wayfinding level is the gate for Phase 1 (ware access) and the scaling axis for Phase 4 (level-scaled shelf); the ladder must be stable before tuning.
- [[system-npc-story-tutorial]] — Quill NPC (Phase 4) needs dialog wired; tutorial step 1 (forage herbs) must not be blocked by an un-affordable ware gate.
- **Plan.md Part B / Phase B3** — level-up moment (toast + burst) is the feedback beat that makes the Phase 1 gate *felt*. Do not re-plan the level-up animation here; wire the economy gate to the existing `leveled_up` signal once B3 ships.

## Verification

- **Phase 1:** `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` — add assertions: `buy_ware("refined_ink", 38)` returns false at lv 1, true at lv 6; `sell_item({category:"trophy"})` returns 0.
- **Phase 2:** Extend the above suite — `_derive_stats()` with a mocked trophy entry returns `damage > base_damage`. Screenshot (`WYRD_UI_SHOT=vendor`) confirms no trophy row in the sell column.
- **Phase 3:** Manual playtest at lv 7 with a tier-3 chart; confirm gold is deducted on enter and blocked if insufficient. Headless loop test asserts `enter_dungeon` with tier-3 chart and `gold < 25` is rejected.
- **Phase 4:** `WYRD_UI_SHOT=vendor` screenshot at lv 1 and lv 7 side-by-side; count ware rows. Quill screenshot (`WYRD_UI_SHOT=quill`) shows buy panel. All four headless suites stay green.
- **Phase 5:** Manual test — click +5 wild_herb, verify gold − 15, satchel + 5, single save call (check logs for duplicate save_now).

## Open questions

- **Chart-tier fee amount** — 25g / 50g / ... per tier is a placeholder. What is the right fee relative to a full delve's expected sell yield? This needs one playtest pass once lv-scaling (Phase 4) is in to set empirically.
- **Quill's wares** — what non-material items belong on Quill's shelf? Pre-rolled charts, satchel upgrades, cosmetic dyes? Needs a design beat before Phase 4.
- **Repair mechanic** — is "repair all gear" a gold drain players enjoy, or does it feel like a chore tax? One playtest pass will tell; hold it in Phase 3 behind the chart-fee first.
