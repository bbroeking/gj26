---
title: Items, Rarities & Gear Affixes
domain: Gather · Craft · Economy
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Items, Rarities & Gear Affixes

> The data layer (kinds, rarities, `make_item`, affix rolls, tooltip formatter) is fully wired; the main gap is the missing `ledger.gd` that would make boss trophies a live stat source — ADR 0013's third power pillar is architecturally seamed but unbuilt.

## Current state

**`wyrd/data/items.gd`** defines 14 gear kinds across 7 categories (weapon, helmet, chest, boots, ring, pickaxe, axe). Rarity is 4-tier: `normal` (0 affixes), `magic` (1), `rare` (3), `unique` (fixed). The `make_item(kind_id, rarity)` factory (`items.gd:118`) returns a full item dict: `kind_id`, `category`, `size`, `base_stat`, `base_value`, `rarity`, `affixes[]`, `icon_color`, `name`. Graceful-fallback for unknown kinds (push_warning + empty dict) and for unique kinds without a `UNIQUES` entry (downgrades to rare, `items.gd:141`). Only 2 uniques are defined: `Whispering Yew` (shortbow) and `Coatcap of the Bramble` (leather_helm) (`items.gd:87–108`).

**`wyrd/data/affixes.gd`** has 6 prefixes and 7 suffixes covering `hp`, `damage`, `crit_chance`, `crit_mult`, `fire_rate`, `move_speed`, `cooldown_reduction`. `roll_affixes()` (`affixes.gd:29`) gives the correct magic/rare split (50/50 for magic, ≥1 prefix + ≥1 suffix for rare). `format_affix()` (`affixes.gd:93`) formats every stat key. `compose_name()` (`affixes.gd:80`) names magic items only (rare/unique keep the kind name — which means rare items display as plain kind names, not composites with affixes).

**`player_controller._derive_stats()`** (`player_controller.gd:1082`) sums all equipped item `base_stat`/`base_value` and rolled affixes into `derived_stats`. Per **ADR 0013** (`docs/adr/0013-vertical-progression.md`), the ADR 0010 freeze-filter was removed — gear now confers full combat power again, with `LEVEL_POWER = 1.25` scaling both player and den sides. Trade tools (`pickaxe`, `axe`) are excluded from the combat-stat sums by equipment slot ordering; `gather_node.gd:304` reads tool `base_value` directly to compute channel time, intentionally bypassing the affix system.

**Tooltip rendering** (`inventory_panel.gd:495–552`) is complete: hover shows item name in rarity color, type line, base stat, and all rolled affixes via `format_affix`. Rarity colors are defined at `inventory_panel.gd:95–100`. The **ledger** (ADR 0013's third power source — boss trophies as capped flat stat boosts) is referenced in ADR 0013:43 as "not yet wired — `ledger.gd` is a followup; the seam exists" but `ledger.gd` does not exist anywhere in the repo. The `drops.gd:60–66` filter already excludes trade tools and capstone gear (`warbow`, `starsilver_band`) from random loot; those are forge-only.

**Status correction:** pre-filled guess was `complete` — corrected to `partial`. The data layer and `make_item` pipeline are complete; the tooltip renderer is complete; `_derive_stats` wiring is complete. The system is partial because: (a) `ledger.gd` (ADR 0013 source #3) is unbuilt, (b) only 2 of 14 kinds have unique definitions, (c) rare items display bare kind names without a composed affix hint, and (d) no affix-tooltip pick-up feel (see Plan.md Part B / Phase B4 for the pickup feel half; the stat-summary band / den-level card from ADR 0013 is also unbuilt).

## Gaps — what needs fleshing out

1. **`ledger.gd` unbuilt** *(hard blocker for ADR 0013 source #3)* — boss trophies should grant live, capped, per-slot stat boosts. `_derive_stats` has no ledger sum path. ADR 0013 names this as a followup (`docs/adr/0013-vertical-progression.md:99`). Until this ships, the "collect boss trophies → get permanently stronger" loop has no mechanical bite.
2. **12 of 14 kinds have no unique definition** — `UNIQUES` in `items.gd:87` covers only `shortbow` and `leather_helm`. Any other kind that rolls `unique` from `drops.gd:52` gracefully falls back to rare, silently diluting the unique tier. Flagged as graceful but no uniques for the warbow, longbow, boots, chest, ring, or any tool.
3. **Rare items have no composed name** — `compose_name` (`affixes.gd:80`) only builds a named string for `magic` rarity; rare items show the bare kind name (e.g., "Shortbow") even with 3 rolled affixes. This misses the ARPG convention of "Shortbow of Carnage" and can confuse players comparing two rares.
4. **Affix pool is thin** — 6 prefixes and 7 suffixes, all combat-only. No `gather_speed` affix for tools; no crafting/economy affixes; no utility affixes for trade tools. Depth-1 items feel samey late-game.
5. **Den-level summary card absent** — ADR 0013 followup: surface the den level + resulting difficulty band ("Den lv 8 · you lv 6 → very hard") before the player commits to a chart. Related to items but really a UI/chart concern.
6. **`leveled_up` → `_derive_stats()` not auto-fired mid-session** — ADR 0013 flags this: derived stats are refreshed on equip/load but not on level-up. A level-up in-dungeon won't reflect until the next equip or load (`player_controller.gd:1058–1070` shows equip-triggered calls, but no `leveled_up` handler visible).
7. **Affix tooltip is plain-rectangle styled** — `_draw_tooltip` at `inventory_panel.gd:525` uses a flat parchment rect. No Wayfinder UI Kit ornament (ink-border, rarity glow border) — just raw `draw_rect`.

## Plan

### Phase 1 — Rare item naming + `leveled_up` stat refresh
*Fixes the two lowest-effort correctness gaps that affect every playtest.*

- **Rare naming:** update `affixes.gd:compose_name` so `rarity == "rare"` composes using the highest-value suffix only (e.g., "Shortbow of Carnage") — one-line change keeping magic naming unchanged.
- **`leveled_up` wiring:** add a `_on_leveled_up()` handler in `player_controller.gd` that calls `_derive_stats()`, connected to `Game.leveled_up`. Mirror the existing `equipment.changed` → `_derive_stats()` pattern (`player_controller.gd:1058`).
- **DoD:** (a) A rare shortbow with `of_carnage` rolled displays "Shortbow of Carnage" in the inventory tooltip. (b) A headless logic test asserts that `derived_stats.damage` updates within one frame of `leveled_up` firing, before any re-equip. Gate green (all 5 suites, `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_stats.gd`).
- **Effort: S**

### Phase 2 — Expand unique coverage
*Corrects the silent rare-fallback dilution for common drop kinds.*

- Add `UNIQUES` entries in `items.gd:UNIQUES` for the 6 most-dropped non-capstone kinds: `longbow`, `leather_chest`, `leather_boots`, `copper_ring`, `leather_helm` (second unique option), and one more weapon. Each unique gets 2–3 fixed affixes with flavor-matching stats (a chest unique might be `+25 hp + 0.10 move_speed`; a ring might be `+15% crit_mult + unique crit_chance`).
- Keep the graceful fallback in `make_item:141` for any remaining unspecified kinds.
- **DoD:** `drops._pick_kind()` can produce all 6 new unique kinds; `make_item(kind_id, "unique")` returns a dict with `rarity == "unique"` and the correct fixed affixes for each. Headless test: assert unique kind names and affix counts match `UNIQUES` entries. Gate green.
- **Effort: S–M**

### Phase 3 — `ledger.gd` (ADR 0013 source #3)
*The missing third power pillar. Without this, the trophy chain has no mechanical payoff.*

- Create `wyrd/scripts/ledger.gd` as a `RefCounted` (or autoload dict on `Game`). Shape: `{ slot_id → { stat, value, trophy_id } }` — one flat-bonus slot per boss trophy collected. Cap per-stat totals (e.g., `damage` cap 15, `crit_chance` cap 0.15).
- Wire `game.gd` boss-victory path: on trophy added to `game.trophies`, `ledger.apply(trophy_id)` sets the corresponding slot.
- Wire `player_controller._derive_stats()` to sum `ledger` entries after the equipment loop, before the `pf` multiply — same `_add_stat` pattern already used for shrine buffs (`player_controller.gd:1096`).
- Expose `Game.ledger` for save/load (`save_game.gd` already persists `trophies`; persist the ledger dict alongside).
- **DoD:** Defeating a boss adds a ledger entry; `derived_stats.damage` (or whichever stat) increases immediately (within one frame of the trophy grant); a headless test asserts the delta matches the ledger entry's `value`. The ledger persists across a save-load cycle. Gate green (all 5 suites).
- **Effort: M**

### Phase 4 — Affix pool expansion + trade-tool affixes
*Adds depth to loot late-game and extends tools into the affix system.*

- Add 4–6 new prefixes/suffixes to `affixes.gd` covering: `forage_speed` (forage nodes), a second `crit_mult` tier, `hp_regen`, and at least one Wildcraft-flavored affix (e.g., `of_the_Bramble` → bleed chance — forward-compatible with status effects).
- Add a `gather_speed` affix entry to PREFIXES for tools (e.g., `"honed": { stat: "gather_speed", value_range: (0.10, 0.20) }` ). Update `gather_node.gd:channel_seconds` to sum both `base_value` and any rolled `gather_speed` affixes on the equipped tool.
- Keep trade tools out of `drops._pick_kind()` (they're forge-only per spec 38).
- **DoD:** A rolled tool can have a `honed` prefix that further reduces channel time on top of its `base_value`. The `channel_seconds` function sums both correctly. Headless test in `test_wyrd_loop.gd` asserts a honed pickaxe channels faster than a plain one. Gate green.
- **Effort: M**

### Phase 5 — Tooltip polish (Wayfinder UI Kit borders)
*Cosmetic — do last when the data is stable. See Plan.md Part B / Phase B4 for the pickup-feel side of this beat.*

- Replace the plain parchment rect in `inventory_panel._draw_tooltip` (`inventory_panel.gd:544`) with a nine-patch border using the Wayfinder UI Kit (`wyrd_ui.gd` styleboxes/tokens). Add a rarity-colored left-accent stripe (reuse `RARITY_COLOR` constants already defined at `inventory_panel.gd:95`).
- Any new art must pass `wyrd/tools/check_ninepatch.py`.
- **DoD:** Hovering a rare item shows the parchment tooltip with a gold left stripe and a UI-kit ink border. Screenshot-verified. Gate green.
- **Effort: S**

## Dependencies & links

- [[system-drops-loot]] — `drops.gd` is the only call site that rolls random rarity + kind before calling `make_item`; expanding uniques or affix coverage must stay compatible with the `_pick_kind` exclusion list.
- [[system-crafting]] — `game.gd:372` is the second `make_item` call site (forge yields); the gear power curve from ADR 0013 means crafted-tier weapons are the primary combat-power path, so the affix pool shapes the crafting endgame.
- [[system-inventory-equipment]] — `Equipment.SLOT_ORDER` and `inventory_panel` consume the item dict shape; any new category or affix key must be compatible with the slot-order and tooltip renderer.
- [[system-player-controller]] — `_derive_stats()` is the consumer of all item stats; Phase 1 wires `leveled_up` → `_derive_stats()`; Phase 3 adds the ledger sum.
- [[system-bosses]] — Phase 3 (`ledger.gd`) is directly triggered by boss kills; the trophy chain is the mechanical gate for ledger entries.
- [[system-economy]] — affix values and gear tiers participate in the no-arbitrage economy constraint (no smithed item sells for more than its forge inputs); Phase 4 affixes must not break `test_wyrd_loop.gd:342`'s forge-economics gate.
- [[system-charts-wayfinding]] — ADR 0013's den-level card (surface "Den lv 8 · you lv 6 → very hard" before committing to a chart) is the UI companion to gear power; not owned here but links to this system.
- [[system-trades-progression]] — `LEVEL_POWER = 1.25` is the multiplier applied in `_derive_stats` alongside gear; the cozy loop (gather → level) is the primary power engine per ADR 0013.
- **Plan.md Part B / Phase B4** — pickup feel (beacon suck + slot pulse) is the UX half of item acquisition; tooltip polish (Phase 5 here) is the item-inspection half of the same beat. Do not duplicate: B4 owns the motion, Phase 5 here owns the static tooltip frame.
- **Plan.md Part B / Phase B3** — level-up burst / perk banner is the felt side of the `leveled_up` signal that Phase 1 wires to `_derive_stats`. Do not duplicate: B3 owns the VFX, Phase 1 here owns the stat refresh.

## Verification

- **Phase 1:** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_stats.gd` — add S5 asserting `derived_stats.damage` increases within one frame of `leveled_up`. Visual check: rare item in inventory panel shows composed suffix name.
- **Phase 2:** headless `test_stats.gd` — add U1–U6 asserting each new unique kind returns correct affix count and names via `make_item(kind, "unique")`.
- **Phase 3:** headless `test_stats.gd` — add L1 asserting `derived_stats` delta equals ledger entry value post-trophy; add L2 asserting ledger persists through a save-load round-trip (`test_wyrd_loop.gd` save-roundtrip pattern). All 5 suites green.
- **Phase 4:** `test_wyrd_loop.gd` — add T1 asserting a tool with a rolled `gather_speed` affix produces a shorter `channel_seconds` result than the same tool without the affix.
- **Phase 5:** screenshot via `WYRD_SHOT=1` with a rare item hovered; inspect in the feel bench. `check_ninepatch.py` must pass on any new nine-patch art. Gate: all 5 suites remain green.

## Open questions

- **Rare naming convention** — should rare items use the highest-value suffix, the prefix, or both? (e.g., "Sharp Shortbow of Carnage" vs "Shortbow of Carnage"). The current `compose_name` magic-path uses both prefix and suffix; keeping both for rare may feel over-long on the tooltip.
- **Ledger slot model** — one flat bonus per boss trophy (linear chain) vs a player-choice selection from a set of trophy-unlocked options? The ADR 0013 wording says "flat, capped, per-slot" but does not define whether the player assigns the boon or it is automatic.
- **`gather_speed` affixes on tools** — should the rolled affix be additive on top of `base_value`, or replace it? Additive means high-tier tools with a rolled affix get very fast; a cap (matching the existing `clampf(base_value, 0, 0.8)` in `gather_node.gd:304`) may be needed.
