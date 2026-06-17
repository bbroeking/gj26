---
title: Economy, Gold & Vendor — Implementation Plan
parent: "[[system-economy]]"
domain: Gather · Craft · Economy
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Economy, Gold & Vendor — Implementation Plan

> Build doc for [[system-economy]]. The anti-arbitrage gate is enforced in code, trophies can never reach the sell counter, gold has real periodic sinks, and Hod's shelf scales with Wayfinding level — ending the state where a freshly minted character can bypass the gather loop by spending gold.

## Definition of done

- `buy_ware()` in `game.gd` rejects any purchase where the player's Wayfinding level is below the ware's minimum threshold, emitting a Hod-voiced notify; greyed-out in the panel.
- `sell_item()` silently returns `0` for any item with `category == "trophy"`; the vendor panel never renders a trophy row.
- At least two gold sinks beyond Hod's material shelf are live: chart-tier entry fee and a repair-all ware.
- Hod's shelf is dynamic — `wares_for_level(lv)` returns a longer list as Wayfinding level grows.
- `quill_npc.gd` opens a real buy panel (Quill's convenience shelf) on E.
- The `+5` bulk-buy shortcut on buy cards writes exactly one `save_now()` per click.
- All five headless suites stay green throughout.

## Preconditions / dependencies

- **`ledger.gd` is out of scope here** — it is owned by [[impl-system-trades-progression]] (tasks 11–13 there). The trophy-sell block in this plan (task 2) is the economy-side enforcement; the ledger stat seam is the progression-side enforcement. Both must ship, but they are independent tasks in different impl notes.
- [[impl-system-trades-progression]] — `trade_lv()` already exists at `game.gd:276` and returns an int. The anti-arbitrage gate (task 1) depends only on this function being stable.
- [[impl-system-bosses]] — trophy item `category` field must be defined before task 2 can be end-to-end tested in a real run. Logic works even with a hand-crafted trophy dict in the headless test.
- [[impl-system-npc-story-tutorial]] — Quill's dialog panel (task 8) must not be broken by task 8's panel swap. Quill currently opens `dialog_panel.gd` on E (`quill_npc.gd:29–36`); task 8 replaces that with a two-mode interact (buy or talk).
- [[impl-system-charts-wayfinding]] — `charts.gd` tier data (`TEMPLATES[id].tier`, `charts.gd:30–59`) backs the chart-entry fee logic in task 5. Tier values are stable (snug=1, tier_1=1, hollow=2, briar_maze=2, summit=3).
- **`data/ledger.gd` is MISSING** — this plan does NOT create it (see above). The economy tasks here are independent of it.
- **`wyrd/scripts/ui/quill_panel.gd` does NOT exist** — task 7 creates it.

## Tasks (ordered)

### Phase 1 — Safety rails (anti-arbitrage + trophy block)

1. **Add `_WARE_MIN_LV` table and `ware_min_lv()` helper in `data/economy.gd`** — `economy.gd` after the `WARES` const (line 30). Add a const dict mapping each ware id to the Wayfinding level required to buy it, and a static lookup:
   ```gdscript
   const _WARE_MIN_LV := {
       "wild_herb": 1, "logs": 1, "bogiron_ore": 2,
       "hedge_ink": 2, "stoneground_ink": 4, "refined_ink": 6,
   }
   static func ware_min_lv(id: String) -> int:
       return int(_WARE_MIN_LV.get(id, 1))
   ```
   _Verify:_ `test_wyrd_loop.gd` — assert `EconomyData.ware_min_lv("refined_ink") == 6`, `EconomyData.ware_min_lv("wild_herb") == 1`. Headless: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`. _Effort:_ XS.

2. **Gate `buy_ware()` on Wayfinding level in `game.gd`** — `game.gd:339–346` (the `buy_ware` function). After the gold check, add a level guard:
   ```gdscript
   const EconomyData = preload("res://data/economy.gd")   # already used via buy_ware
   func buy_ware(id: String, price: int) -> bool:
       if gold < price:
           return false
       if trade_lv() < EconomyData.ware_min_lv(id):
           notify("Hod eyes you. \"That ink's not for beginners.\"")
           return false
       # ... existing gold/material logic unchanged
   ```
   _Verify:_ Add cases to `test_wyrd_loop.gd` in `_test_chain_and_economy()` (after line 89): `game.trades.wayfinding.lv = 1; game.gold = 100; assert not game.buy_ware("refined_ink", 38)` (gate blocks); `game.trades.wayfinding.lv = 6; assert game.buy_ware("refined_ink", 38)` (gate passes). _Effort:_ S.

3. **Block trophy sells in `game.gd:sell_item()`** — `game.gd:328`. Add a category guard as the first check inside `sell_item`:
   ```gdscript
   func sell_item(item: Dictionary) -> int:
       if String(item.get("category", "")) == "trophy":
           notify("Trophies pass through the hollows, not the counter.")
           return 0
       if inventory == null or not inventory.items.has(item):
           return 0
       # ... existing price/remove/emit logic unchanged
   ```
   _Verify:_ `test_wyrd_loop.gd` — add `assert game.sell_item({"category": "trophy", "rarity": "unique"}) == 0` and `assert int(game.gold) == 0` (gold unchanged) after the existing economy assertions. _Effort:_ XS.

4. **Filter trophy rows out of the sell column in `vendor_panel.gd:_render()`** — `vendor_panel.gd:152–173` (the `for item in items` loop). Belt-and-suspenders on task 3: skip items whose category is `"trophy"` before building a `_VendorCard`:
   ```gdscript
   for item in items:
       var it: Dictionary = item
       if String(it.get("category", "")) == "trophy":
           continue
       # ... existing card setup unchanged
   ```
   _Verify:_ Screenshot via `WYRD_UI_SHOT=vendor` — no trophy row appears in the sell column even when a trophy dict exists in `game.inventory.items` (inject one in the dev boot path for the shot). _Effort:_ XS.

### Phase 2 — Vendor panel gate feedback

5. **Grey out locked wares in `vendor_panel.gd:_render()`** — `vendor_panel.gd:176–189` (the `for ware in EconomyData.WARES` loop). Compute a `locked` boolean per ware and pass it through to `_VendorCard.setup_buy`:
   ```gdscript
   var lv_ok: bool = game.trade_lv() >= EconomyData.ware_min_lv(id)
   var affordable: bool = int(game.gold) >= price and lv_ok
   card.setup_buy(GatherDefs.material_name(id), price, have, affordable,
       GatherDefs.material_icon(id), lv_ok)
   ```
   In `_VendorCard.setup_buy`, add an optional `_locked: bool = false` param. In `_draw()`, if `_locked`, render the name in `WyrdUi.INK_MID` (dim) and append a small `"Lv %d" % min_lv` note next to the price. Never call `pressed.emit()` if locked (guard in `_gui_input`). _Verify:_ `WYRD_UI_SHOT=vendor` at Wayfinding lv 1 — refined_ink row dimmed with "Lv 6" note; at lv 6 it is normal. _Effort:_ S.

### Phase 3 — Gold sinks

6. **Add `CHART_TIER_FEE` and `chart_entry_fee()` in `data/economy.gd`** — `economy.gd` after the `_WARE_MIN_LV` block. Define fees and a static lookup. Fee waived if the player holds the relevant boss trophy in `game.trophies` (once `impl-system-bosses` ships that dict; for now, always charge):
   ```gdscript
   const CHART_TIER_FEE := {1: 0, 2: 15, 3: 30}
   static func chart_entry_fee(tier: int) -> int:
       return int(CHART_TIER_FEE.get(tier, 0))
   ```
   _Verify:_ Unit test in `test_wyrd_loop.gd` — `assert EconomyData.chart_entry_fee(2) == 15`, `assert EconomyData.chart_entry_fee(1) == 0`. _Effort:_ XS.

7. **Charge chart entry fee in `game.gd:enter_dungeon()`** — `game.gd:662–688`. After `charts.erase(chart)` and before `active_chart = chart`, add a fee check:
   ```gdscript
   var tier: int = int(chart.get("tier", 1))
   var fee: int = EconomyData.chart_entry_fee(tier)
   if fee > 0:
       if gold < fee:
           notify("The deeper hollows ask %dg to cross. Come back richer." % fee)
           charts.append(chart)   # re-add the consumed chart
           charts_changed.emit()
           return
       gold -= fee
       gold_changed.emit(gold)
       notify("Crossed into the hollow — %dg paid." % fee)
   ```
   _Verify:_ `test_wyrd_loop.gd` — game with tier-2 chart, `gold = 10` → `enter_dungeon` returns early and chart is back in `charts`; `gold = 20` → proceeds normally and `gold == 5`. _Effort:_ S.

8. **Add a `repair_all` ware to `data/economy.gd`** — Append to `WARES` (line 23–30). Repair price is computed from equipped item count; keep it simple as a flat constant for the first pass:
   ```gdscript
   {"id": "repair_all", "price": 20, "label": "Repair all gear"},
   ```
   In `game.gd`, add a `repair_all_gear()` helper that checks `gold >= 20`, deducts, emits `gold_changed`, calls `notify("Hod hammers your gear square. 20g.")`, and returns `true`. In `vendor_panel.gd:_render()` detect `id == "repair_all"` and wire the card to call `game.repair_all_gear()` instead of `buy_ware`. _Verify:_ Manual playtest — Repair row appears on Hod's shelf, deducts 20g, toast fires. `test_wyrd_loop.gd` assert `repair_all_gear()` deducts 20g and returns `true`; returns `false` with `gold < 20`. _Effort:_ S.

### Phase 4 — Level-scaled wares

9. **Refactor `WARES` to `wares_for_level(lv)` in `data/economy.gd`** — Replace the flat `WARES` const with a static function. Keep the original entries as a base tier and add deeper materials at higher levels:
   ```gdscript
   static func wares_for_level(lv: int) -> Array:
       var w: Array = [
           {"id": "wild_herb",       "price": 3},
           {"id": "logs",            "price": 4},
           {"id": "bogiron_ore",     "price": 7},
           {"id": "hedge_ink",       "price": 12},
       ]
       if lv >= 4:
           w.append({"id": "stoneground_ink", "price": 18})
       if lv >= 6:
           w.append({"id": "refined_ink",     "price": 38})
       if lv >= 8:
           w.append({"id": "hedgesteel_ore",  "price": 22})
           w.append({"id": "moonsilver_ore",  "price": 35})
       w.append({"id": "repair_all", "price": 20, "label": "Repair all gear"})
       return w
   ```
   Keep `const WARES` as a backward-compat alias pointing at `wares_for_level(1)` for any callsite that uses it (only `vendor_panel.gd:176` — update it in the next task). _Verify:_ Unit test: `assert EconomyData.wares_for_level(1).size() == 5`, `assert EconomyData.wares_for_level(8).size() == 8`. _Effort:_ S.

10. **Update `vendor_panel.gd:_render()` to use `wares_for_level()`** — `vendor_panel.gd:176`. Replace `for ware in EconomyData.WARES:` with `for ware in EconomyData.wares_for_level(game.trade_lv()):`. No other change. _Verify:_ `WYRD_UI_SHOT=vendor` at lv 1 shows 5 rows (base tier + repair); at `WYRD_DEV_LEVEL=8` shows 8 rows. _Effort:_ XS.

### Phase 5 — Quill's convenience shelf

11. **Create `wyrd/scripts/ui/quill_panel.gd`** (new file — does not exist). Mirrors `vendor_panel.gd`'s CanvasLayer structure but buy-only (no sell column). Title: "Quill's Still". Wares defined inline as a const; markup over Hod's prices (~1.5×) to reinforce gathering as the value path:
    ```gdscript
    const QUILL_WARES := [
        {"id": "wild_herb",  "price": 5},
        {"id": "hedge_ink",  "price": 18},
        {"id": "common_chart_snug", "price": 12, "label": "Snug Chart (pre-rolled)"},
    ]
    ```
    Wire buy cards to `game.buy_ware(id, price)`. Preload all icons in `_ready` (white-rect-in-`_draw` guard). Do NOT use `class_name` (headless constraint). _Verify:_ `WYRD_UI_SHOT=quill` screenshot shows the three-ware shelf. `test_wyrd_loop.gd` — instantiate the panel script (`preload`), call its internal render path, assert no errors. _Effort:_ M.

12. **Wire `quill_npc.gd` to open `quill_panel.gd` on E** — `quill_npc.gd:11, 29–36`. Add a `const QuillPanelScript = preload("res://scripts/ui/quill_panel.gd")` preload. In `interact()`, replace `DialogPanelScript.new()` with a two-branch choice: if the player has ≥ 1 wild_herb (i.e., they've gathered), open the buy panel; otherwise open the dialog (tutorial path). Sketch:
    ```gdscript
    func interact(_player: Node) -> void:
        var game := get_tree().root.get_node_or_null("Game")
        if game != null and int(game.material_count("wild_herb")) > 0:
            var panel := QuillPanelScript.new()
            get_tree().current_scene.add_child(panel)
        else:
            var dlg: CanvasLayer = DialogPanelScript.new()
            dlg.open("Quill, the Herbalist", [...])
            get_tree().current_scene.add_child(dlg)
    ```
    _Verify:_ Playtest — before gathering, Quill opens dialog; after having herbs, she opens the shop. `WYRD_UI_SHOT=quill` confirms panel. _Effort:_ S.

### Phase 6 — Bulk-buy UX

13. **Add `+5` bulk-buy button in `_VendorCard.setup_buy()`** — `vendor_panel.gd:226–234` (`_VendorCard.setup_buy`). Store a `_bulk_enabled: bool` var (true when `gold >= price * 5` and not locked). In `_draw()`, render a small "×5" chip right of the price column when `_bulk_enabled`. Add a second `signal bulk_pressed` emitted when the ×5 zone is clicked (check x-offset in `_gui_input`). In the outer `_render()` loop, connect `bulk_pressed` to a closure that calls `buy_ware` five times then calls `save_now()` once:
    ```gdscript
    card.bulk_pressed.connect(func():
        for _i in 5:
            _game.buy_ware(bid, bprice)
        _game.save_now()   # one write for the batch
        _render())
    ```
    _Verify:_ Manual test — click ×5 on wild_herb (3g each): gold drops 15, satchel +5, log shows one save_now call. `test_wyrd_loop.gd` — assert `buy_ware` called 5× and gold deducted correctly. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1 + 2 + 3** — `_WARE_MIN_LV` table in `economy.gd`, the level gate in `game.gd:buy_ware`, and the trophy block in `game.gd:sell_item`. All three are purely additive changes with no UI impact. Acceptance: `test_wyrd_loop.gd` green with new assertions: `buy_ware("refined_ink", 38)` returns false at lv 1 and true at lv 6; `sell_item({category:"trophy"})` returns 0.

## Test & verification plan

| Task | Suite / Method | What it checks |
|---|---|---|
| 1 — ware_min_lv | `test_wyrd_loop.gd` | `ware_min_lv("refined_ink") == 6`, `"wild_herb" == 1` |
| 2 — buy gate | `test_wyrd_loop.gd` | buy blocked at lv 1, passes at lv 6 |
| 3 — trophy sell block | `test_wyrd_loop.gd` | `sell_item({category:"trophy"})` == 0, gold unchanged |
| 4 — panel filter | `WYRD_UI_SHOT=vendor` | no trophy row in sell column |
| 5 — grey-out panel | `WYRD_UI_SHOT=vendor` (lv 1 + lv 6) | refined_ink dimmed at 1, live at 6 |
| 6 — chart fee data | `test_wyrd_loop.gd` | `chart_entry_fee(2) == 15`, `chart_entry_fee(1) == 0` |
| 7 — chart entry gate | `test_wyrd_loop.gd` | enter blocked with gold < fee; proceeds with gold >= fee; gold deducted |
| 8 — repair ware | playtest + `test_wyrd_loop.gd` | repair row on shelf, 20g deducted, toast fires |
| 9 — wares_for_level | `test_wyrd_loop.gd` | `wares_for_level(1).size()==5`, `wares_for_level(8).size()==8` |
| 10 — panel uses level | `WYRD_UI_SHOT=vendor` at lv 1 and `WYRD_DEV_LEVEL=8` | row counts differ |
| 11 — quill_panel.gd | `WYRD_UI_SHOT=quill` | three-ware shelf renders |
| 12 — Quill wire | playtest (with/without herbs) | dialog vs. panel branch |
| 13 — bulk buy | manual + `test_wyrd_loop.gd` | gold −15, satchel +5, one save_now |

All headless runs: `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`. All four existing suites must stay green after every task.

## Risks & open questions

1. **`repair_all` ware price** — 20g is a placeholder. The right value depends on how fast gold pools at mid-level play. One playtest pass at Wayfinding lv 5–8 should calibrate it. Hold price tuning until after the chart entry fee (task 7) ships — the two sinks interact.
2. **Chart fee re-add on block** — task 7 re-appends the chart to `game.charts` when the fee blocks entry. This works for offline play. In co-op (spec 46), the host already erased the chart via RPC before the fee check; the re-add creates a divergence. Flag as a known follow-up for [[impl-system-multiplayer-netcode]].
3. **`hedgesteel_ore` / `moonsilver_ore` in `wares_for_level()`** — these material IDs are assumed but may not exist yet in `data/gather.gd` or `items.gd`. Confirm before shipping task 9; if they are absent, stub with `TODO` comments and gate on a follow-up that defines the tier-2 materials.
4. **Quill's "pre-rolled chart" ware** — `buy_ware("common_chart_snug", price)` calls `add_material`, but charts live in `game.charts`, not `game.materials`. Quill's chart ware needs a separate `buy_chart()` verb in `game.gd` rather than `buy_ware`. Task 11 must either stub this as a dialog-only hint or implement `buy_chart()` in the same commit.
5. **`_WARE_MIN_LV` vs. `WARES` ordering** — task 9 replaces `const WARES` with `wares_for_level()`; the backward-compat alias is only needed if any other file references `EconomyData.WARES` directly. Confirm with `grep -rn "EconomyData.WARES"` before shipping task 9 — only `vendor_panel.gd:176` currently references it.
6. **Tutorial step 1 not blocked** — the tutorial asks the player to forage herbs (step 1) before any gold exists, so the lv-gate (task 2) cannot block that path. Wild herbs are min_lv 1, so the gate is already safe — but confirm tutorial_step ordering before shipping.

## Build status — 2026-06-16

**Completed (in-scope only):**

- **Task 1 (ware_min_lv):** `_WARE_MIN_LV` const and `ware_min_lv()` static func added to `economy.gd`.
- **Task 6 (chart_entry_fee):** `CHART_TIER_FEE` const and `chart_entry_fee()` static func added to `economy.gd`.
- **Task 9 (wares_for_level):** `wares_for_level(lv)` static func added to `economy.gd`; `const WARES` kept as backward-compat alias. `repair_all` ware (20g) always appended. `hedgesteel_ore` added at lv 8. `moonsilver_ore` skipped — not defined in `gather.gd`; risk 3 above is resolved by omitting it.
- **Task 11 (quill_panel.gd):** New file `wyrd/scripts/ui/quill_panel.gd` — buy-only panel, kit-styled (WyrdUi tokens + `_QuillCard` drawn cards). Wares: wild_herb 5g, hedge_ink 18g, quickroot_tonic 14g. Level-gate via `ware_min_lv()`: locked wares dim with a "Wayfinding N" note. Quill's pre-rolled chart ware stubbed out (deferred — needs `buy_chart()` in game.gd).
- **New test:** `wyrd/test_economy.gd` — headless suite for `ware_min_lv`, `chart_entry_fee`, `wares_for_level`, WARES compat alias, `sell_value`. Run: `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_economy.gd`.

**Deferred (require out-of-scope edits):**

- **Task 2 (buy gate in game.gd):** The `buy_ware()` level gate must be added to `game.gd:353`. Blocked — game.gd is out of scope.
- **Task 3 (trophy sell block in game.gd):** The `sell_item()` trophy guard must be added to `game.gd:342`. Blocked — game.gd is out of scope.
- **Task 4 (trophy filter in vendor_panel.gd):** Belt-and-suspenders trophy skip in sell column. Blocked — vendor_panel.gd out of scope.
- **Task 5 (grey-out locked wares in vendor_panel.gd):** `lv_ok` dim + "Lv N" note on buy cards. Blocked — vendor_panel.gd out of scope.
- **Task 7 (chart entry fee in game.gd):** `enter_dungeon()` fee deduction. Blocked — game.gd out of scope.
- **Task 8 (repair_all ware wiring in game.gd + vendor_panel.gd):** `repair_all_gear()` helper + card routing. Blocked — both files out of scope.
- **Task 10 (vendor_panel uses wares_for_level):** Replace `for ware in EconomyData.WARES` with `wares_for_level(game.trade_lv())`. Blocked — vendor_panel.gd out of scope.
- **Task 12 (quill_npc.gd wiring):** Two-branch interact (buy vs. dialog). Blocked — quill_npc.gd out of scope.
- **Task 13 (bulk-buy ×5 in vendor_panel.gd):** Blocked — vendor_panel.gd out of scope.

**Known issues / watch items:**
- `repair_all` appears in `wares_for_level()` but NOT in `WARES` compat alias — this keeps `_test_economy_gate` clean (the gate loop only checks items that are forge-smithable, not services). Confirmed safe.
- `EconomyData.WARES` is referenced in `game.gd:735` (`_cheapest_material`) and `test_wyrd_loop.gd:323` — both callers continue to see the 6-entry base shelf, which is correct.
- `vendor_panel.gd:176` still uses `EconomyData.WARES`; task 10 (deferred) will switch it to `wares_for_level()`.
