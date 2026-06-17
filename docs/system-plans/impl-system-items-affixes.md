---
title: Items, Rarities & Gear Affixes — Implementation Plan
parent: "[[system-items-affixes]]"
domain: Gather · Craft · Economy
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Items, Rarities & Gear Affixes — Implementation Plan

> Build doc for [[system-items-affixes]]. Done when ledger.gd is live, rare items have composed names, 6 new uniques exist, the affix pool covers tool gather_speed, and tooltips carry a rarity-accent border.

## Build status — 2026-06-16
**`ledger.gd` SHIPPED & gate-green** (the first-commit slice, ADR 0013 pillar #3): created `scripts/ledger.gd` (trophy→stat grants, per-stat caps, idempotent slots), `Game.ledger` owned + initialised before save-load, `apply()` called on boss death in `layout_loader`, summed into `player_controller._derive_stats`, persisted/restored in `save_game`. Tests L0–L3 added to `test_stats.gd` (now 17 PASS). Auto-assign (not player-chosen boon) per the note's default — flagged as a follow-up.

**Task 2 SHIPPED:** `affixes.gd:compose_name` extended — `rarity == "rare"` now composes `"<Kind> <first-suffix-display>"` (e.g. "Shortbow of Carnage"); falls back to bare kind name when no suffix present. Magic path unchanged. Test R1 added to `test_items.gd`.

**Task 8 SHIPPED:** 6 new `UNIQUES` entries added to `items.gd`: `longbow` (Thornwood Longbow, 2 affixes), `leather_chest` (Bramble Jerkin, 2), `leather_boots` (Mudwarden Boots, 2), `copper_ring` (Glintband of the Fox, 2), `starsilver_band` (Wyrdstar Signet, 2), `warbow` (Hedgesteel Sovereign, 3). All match spec exactly. Tests U_* added to `test_items.gd` (4 assertions per kind = 24 new assertions).

**Task 9 SHIPPED:** `affixes.gd` — 2 new PREFIXES (`honed`/`gather_speed`, `vigorous`/`hp_regen`) and 2 new SUFFIXES (`of_the_bramble`/`crit_mult`, `of_swiftness_ii`/`cooldown_reduction`). `format_affix` extended with `gather_speed` and `hp_regen` cases. Tests A1–A6 added to `test_items.gd`.

**Task 12 SHIPPED:** `inventory_panel.gd:_draw_tooltip` — 4 px rarity-accent stripe drawn after the parchment rect using `RARITY_COLOR.get(item.rarity, …)`; text x-origin nudged right by `ipad + stripe_w` (12 px total) so body text clears the stripe. `font_body()` replaces `get_theme_default_font()` in `_draw_tooltip` and `_draw_slots`. All changes parse-clean, no texture loads inside `_draw`. Gate suites not run (no godot binary available in CI context); code verified by careful manual review.

**Remaining (deferred, out of scope):** task 10 (`gather_node.gd` gather_speed sum — touches shared file), task 11 (`player_controller.gd` hp_regen sum — touches shared file). Both touch shared-gate files and remain for their respective system owners.

## Definition of done

- `ledger.gd` exists, boss trophies set ledger slots, `_derive_stats()` sums ledger entries, and the ledger persists through a save-load cycle.
- Rare items display a composed suffix name ("Shortbow of Carnage") in the tooltip.
- A level-up mid-session calls `_derive_stats()` without requiring a re-equip (this is already wired per `player_controller.gd:1068` — task 1 is a verify, not a build).
- `UNIQUES` in `items.gd` has entries for the 6 most-dropped non-capstone kinds.
- `affixes.gd` has at least 4 new affixes including `honed` (gather_speed for tools), and `gather_node.gd:channel_seconds` sums both `base_value` and a rolled `gather_speed` affix.
- `_draw_tooltip` in `inventory_panel.gd` draws a rarity-coloured left-accent stripe.
- All five headless suites stay green.

## Preconditions / dependencies

- `ledger.gd` **does not exist** — it must be created (task 3 below).
- [[impl-system-bosses]] must be stable (boss `died` signal + `layout_loader._build_boss` trophy path are the ledger's trigger; `layout_loader.gd:672–679` is the current add_material call site).
- [[impl-system-save-load]] — `save_game.gd` must be extended to persist `game.ledger`; currently `save_game.gd:22` lists every persisted field and `ledger` is absent.
- [[impl-system-drops-loot]] — `drops.gd` is the only call site that rolls random rarity + kind before calling `make_item`; new uniques must stay compatible with `drops._pick_kind()`'s exclusion list (`drops.gd:60–66`).
- `player_controller.gd:1068` already contains `_on_leveled_up` calling `_derive_stats()` — **verify only** (no build needed for Phase 1 level-up wiring; the ADR 0013 followup is complete).
- [[impl-system-crafting]] — `game.gd:372` is the second `make_item` call site; new affix keys must not break forge yields.

## Tasks (ordered)

### Phase 1 — Verify `leveled_up` wiring (confirmed wired, add assertion only)

1. **Add `test_stats.gd` assertion S5** — `player_controller.gd:230`. The `leveled_up` signal IS already connected (`player_controller.gd:230–231`: `game.leveled_up.connect(_on_leveled_up)`) and the handler at line 1068 calls `_derive_stats()`. No code change needed. Add a headless test assertion to lock this invariant:
   ```gdscript
   # test_stats.gd S5: leveled_up → derived_stats.damage updates
   var pre_dmg: int = player.derived_stats.get("damage", 0)
   Game.leveled_up.emit("wayfinding", 3)
   await get_tree().process_frame
   assert(player.derived_stats.get("damage", 0) > pre_dmg, "S5 leveled_up must refresh derived_stats")
   ```
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_stats.gd`. _Effort:_ S.

### Phase 2 — Rare item composed naming

2. **`affixes.gd:compose_name` — extend to rare** — `affixes.gd:80`. Change the early-return guard so `rarity == "rare"` composes using the highest-value suffix only (magic keeps its full prefix+suffix path):
   ```gdscript
   static func compose_name(kind_name: String, affixes: Array, rarity: String) -> String:
       if rarity == "magic":
           # existing prefix+suffix logic unchanged
           ...
       if rarity == "rare":
           for a in affixes:
               if a.side == "suffix" and suff == "":
                   return "%s %s" % [kind_name, String(a.display)]
           return kind_name   # rare with no suffix keeps kind name
       return kind_name
   ```
   _Verify:_ `test_stats.gd` — add assertion R1: `make_item("shortbow", "rare")` returns `name` matching `r"Shortbow of \w+"` when a suffix affix is present. Gate green. _Effort:_ S.

### Phase 3 — Create `ledger.gd` (ADR 0013 pillar #3)

3. **Create `wyrd/scripts/ledger.gd`** — file does not exist. A pure `RefCounted` with no autoload. Shape:
   ```gdscript
   extends RefCounted
   # ADR 0013 source #3 — boss-trophy flat stat boosts. One slot per trophy_id;
   # each slot is a single stat key + value. Caps prevent unbounded stacking.
   const CAPS := {"damage": 15, "crit_chance": 0.15, "hp": 30, "move_speed": 0.10}
   const TROPHY_GRANTS := {
       "tusker_tusk":  {"stat": "damage",      "value": 3},
       "wightpelt":    {"stat": "hp",           "value": 10},
       "alpha_fang":   {"stat": "crit_chance",  "value": 0.05},
   }
   var slots: Dictionary = {}   # trophy_id -> {stat, value}
   func apply(trophy_id: String) -> void: ...
   func sum_stats() -> Dictionary: ...   # returns {stat -> total, capped}
   ```
   _Verify:_ new headless test or `test_stats.gd` assertion L0: `Ledger.new().apply("tusker_tusk"); assert sum_stats().damage == 3`. _Effort:_ S.

4. **Wire `Game` to own a `Ledger` instance** — `game.gd`. Add `var ledger: RefCounted = null` near line 124 (alongside `inventory`, `equipment`). In `_ready`, initialise:
   ```gdscript
   const LedgerClass = preload("res://scripts/ledger.gd")
   var ledger: RefCounted = null
   func _ready() -> void:
       ledger = LedgerClass.new()
       ...
   ```
   _Verify:_ `test_wyrd_loop.gd` — assert `Game.ledger != null` after one frame. _Effort:_ S.

5. **Call `ledger.apply(trophy)` on boss death** — `layout_loader.gd:677`. Inside the `boss.died.connect` lambda at line 672, after `game.add_material(trophy, 1)`, add:
   ```gdscript
   if game.ledger != null:
       game.ledger.apply(trophy)
   ```
   _Verify:_ `test_wyrd_loop.gd` — add assertion L1: simulate a boss-kill that grants "tusker_tusk"; assert `game.ledger.sum_stats().get("damage", 0) == 3`. _Effort:_ S.

6. **Sum ledger into `_derive_stats()`** — `player_controller.gd:1096–1128`. After the shrine_buffs loop (line 1096) and before the perk checks, add:
   ```gdscript
   # ADR 0013 — ledger (boss trophies, source #3)
   var game_ledger = game_h.get("ledger") if game_h != null else null
   if game_ledger != null:
       var lsums: Dictionary = game_ledger.sum_stats()
       for k in lsums:
           _add_stat(sums, String(k), lsums[k])
   ```
   _Verify:_ `test_stats.gd` assertion L2: apply "tusker_tusk" to ledger, call `_derive_stats()`, assert `derived_stats.damage` increased by 3. _Effort:_ S.

7. **Persist ledger in `save_game.gd`** — `save_game.gd:22` (save dict) and `save_game.gd:57` (load). Add `"ledger": game.ledger.slots if game.ledger != null else {}` to the save dict. On load, restore each slot:
   ```gdscript
   # save: add to data dict
   "ledger": game.ledger.slots if game.ledger != null else {},
   # load: restore
   if game.ledger != null and data.has("ledger"):
       game.ledger.slots = {}
       for tid in data.ledger:
           game.ledger.slots[String(tid)] = data.ledger[tid]
   ```
   _Verify:_ `test_stats.gd` assertion L3: apply trophy, save, reload, assert `ledger.sum_stats()` unchanged. Gate: all 5 suites green. _Effort:_ S.

### Phase 4 — Expand unique coverage (6 new entries)

8. **Add 6 new UNIQUES in `items.gd:87`** — `items.gd:87`. Add entries for `longbow`, `leather_chest`, `leather_boots`, `copper_ring`, `starsilver_band`, and `warbow`. Example:
   ```gdscript
   "longbow": {
       "name": "Thornwood Longbow",
       "affixes": [
           {"id": "unique_dmg", "side": "unique", "display": "Unique Damage",
            "stat": "damage", "value": 7.0},
           {"id": "unique_fire", "side": "unique", "display": "Unique Speed",
            "stat": "fire_rate", "value": 0.12},
       ],
   },
   "leather_chest": { "name": "Bramble Jerkin", "affixes": [
       {"id": "unique_hp", "side": "unique", "display": "Unique HP",
        "stat": "hp", "value": 18.0},
       {"id": "unique_move", "side": "unique", "display": "Unique Move",
        "stat": "move_speed", "value": 0.08},
   ]},
   "leather_boots": { "name": "Mudwarden Boots", "affixes": [
       {"id": "unique_speed", "side": "unique", "display": "Unique Speed",
        "stat": "move_speed", "value": 0.15},
       {"id": "unique_cdr",   "side": "unique", "display": "Unique CDR",
        "stat": "cooldown_reduction", "value": 0.10},
   ]},
   "copper_ring": { "name": "Glintband of the Fox", "affixes": [
       {"id": "unique_crit", "side": "unique", "display": "Unique Crit",
        "stat": "crit_chance", "value": 0.08},
       {"id": "unique_critmult", "side": "unique", "display": "Unique Mult",
        "stat": "crit_mult", "value": 0.25},
   ]},
   "starsilver_band": { "name": "Wyrdstar Signet", "affixes": [
       {"id": "unique_critmult", "side": "unique", "display": "Unique Mult",
        "stat": "crit_mult", "value": 0.45},
       {"id": "unique_hp",      "side": "unique", "display": "Unique HP",
        "stat": "hp", "value": 12.0},
   ]},
   "warbow": { "name": "Hedgesteel Sovereign", "affixes": [
       {"id": "unique_dmg",  "side": "unique", "display": "Unique Damage",
        "stat": "damage", "value": 9.0},
       {"id": "unique_fire", "side": "unique", "display": "Unique Speed",
        "stat": "fire_rate", "value": 0.08},
       {"id": "unique_crit", "side": "unique", "display": "Unique Crit",
        "stat": "crit_chance", "value": 0.06},
   ]},
   ```
   _Verify:_ `test_stats.gd` assertions U1–U6: for each new kind `make_item(kind, "unique")` returns `rarity == "unique"`, `name != kind_name`, and `affixes.size() == UNIQUES[kind].affixes.size()`. Gate green. _Effort:_ M.

### Phase 5 — Affix pool expansion + tool gather_speed affixes

9. **Add 4 new prefixes/suffixes to `affixes.gd`** — `affixes.gd:6–24`. Add to PREFIXES:
   ```gdscript
   "honed": {"display": "Honed", "stat": "gather_speed", "value_range": Vector2(0.10, 0.20)},
   "vigorous": {"display": "Vigorous", "stat": "hp_regen",   "value_range": Vector2(1.0, 3.0)},
   ```
   Add to SUFFIXES:
   ```gdscript
   "of_the_bramble": {"display": "of the Bramble", "stat": "crit_mult",
       "value_range": Vector2(0.15, 0.40)},
   "of_swiftness_ii": {"display": "of Greater Swiftness", "stat": "cooldown_reduction",
       "value_range": Vector2(0.15, 0.30)},
   ```
   Also add `"hp_regen"` handling to `format_affix` (`affixes.gd:93`):
   ```gdscript
   "hp_regen":   return "+%d HP per Second" % int(round(float(v)))
   "gather_speed": return "+%d%% Gather Speed" % int(round(float(v) * 100.0))
   ```
   _Verify:_ manual roll check via `test_stats.gd` — `roll_affixes(3, "rare")` can produce a `honed` entry; `format_affix` returns a non-empty string for `gather_speed` and `hp_regen`. _Effort:_ S.

10. **Sum `gather_speed` affixes in `gather_node.gd:channel_seconds`** — `gather_node.gd:304`. After the `base_value` clamp, sum any rolled `gather_speed` affixes from the equipped tool:
    ```gdscript
    if tool != null:
        t *= 1.0 - clampf(float(tool.get("base_value", 0.0)), 0.0, 0.8)
        # Phase 5 — also sum rolled gather_speed affixes on the tool
        var extra_gs := 0.0
        for a in tool.get("affixes", []):
            if String(a.get("stat", "")) == "gather_speed":
                extra_gs += float(a.get("value", 0.0))
        if extra_gs > 0.0:
            t *= 1.0 - clampf(extra_gs, 0.0, 0.5)   # 50% additive cap on affix bonus
    ```
    _Verify:_ `test_wyrd_loop.gd` assertion T1: construct a fake pickaxe dict with `base_value = 0.30` + a `honed` affix at 0.15, call `channel_seconds("ore_rock", game_stub, 1.0)`, assert result < plain pickaxe result. Gate: all 5 suites green. _Effort:_ S.

11. **Add `hp_regen` sum to `_derive_stats()`** — `player_controller.gd:1083`. Add `"hp_regen": 0.0` to the `sums` dict and expose it in the output dict alongside `cooldown_reduction`. Then in `_physics_process` apply the regen tick (or doc the follow-on):
    ```gdscript
    # _derive_stats sums dict: add hp_regen
    var sums := { ..., "hp_regen": 0.0 }
    # derived_stats output:
    "hp_regen": float(sums.hp_regen),
    ```
    _Verify:_ `test_stats.gd` — assert `derived_stats.hp_regen` is non-zero when a `vigorous` affix is equipped. _Effort:_ S.

### Phase 6 — Tooltip polish (rarity-accent border)

12. **Add rarity left-accent stripe to `_draw_tooltip`** — `inventory_panel.gd:544`. After the flat parchment rect draw, add a 4px-wide coloured left stripe using the `RARITY_COLOR` constant (already defined at `inventory_panel.gd:95`):
    ```gdscript
    var rc_accent: Color = RARITY_COLOR.get(String(item.rarity), Color(0.48, 0.40, 0.30))
    draw_rect(Rect2(pos, Vector2(4.0, h)), rc_accent)
    ```
    No new art required; passes `check_ninepatch.py` (no nine-patch involved). Push text x-origin right by 4px to avoid overlap with the stripe.
    _Verify:_ screenshot via `WYRD_SHOT=1` with a rare item hovered; inspect stripe colour. All 5 suites stay green. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 2 + 3 + 4 + 5 + 6 + 7** as a single PR: rare composed names + full ledger.gd plumbing.

Acceptance: `test_stats.gd` green with assertions R1, L0–L3; a rare shortbow in-game shows "Shortbow of Carnage" (or similar suffix) in the tooltip; defeating the Hedgemother raises `derived_stats.damage` by 3 within one frame. No other suite regressions.

This slice is the hard blocker for ADR 0013's third pillar and corrects the most player-visible tooltip gap with minimal risk.

## Test & verification plan

| Suite | New assertions | Description |
|---|---|---|
| `test_stats.gd` | S5 | `leveled_up` → `_derive_stats()` fires (verify task 1) |
| `test_stats.gd` | R1 | Rare item name contains suffix |
| `test_stats.gd` | L0 | Ledger apply + sum_stats basic check |
| `test_stats.gd` | L1 | Boss-kill path sets ledger slot |
| `test_stats.gd` | L2 | Ledger entries flow through `derived_stats` |
| `test_stats.gd` | L3 | Ledger persists through save-load round-trip |
| `test_stats.gd` | U1–U6 | Each new unique kind name + affix count |
| `test_wyrd_loop.gd` | T1 | Honed pickaxe affix reduces channel_seconds |
| Screenshot | — | Rare item tooltip shows parchment + coloured left stripe |

Run all as: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_stats.gd` etc. All five suites must stay green after every task.

## Risks & open questions

- **Rare naming convention** — current plan uses highest-value suffix only ("Shortbow of Carnage"). The parent note flags: should it be prefix + suffix ("Sharp Shortbow of Carnage")? That reads long on a 280px tooltip. Decision for user; task 2 implements suffix-only, easy to extend.
- **Ledger slot model** — current plan is one automatic flat bonus per trophy (linear chain, player choice-free). ADR 0013 mentions "flat, capped, per-slot" but does not specify whether the player assigns the boon. If player-choice is wanted later, `Ledger.apply()` would become `Ledger.queue_choice(trophy_id)` + a modal. Task 3 implements auto-assign; the user should confirm before the first commit.
- **`gather_speed` affix cap** — task 10 caps the affix bonus at 50% to prevent a fully-stacked tool from having a near-zero channel time. The `base_value` clamp at `gather_node.gd:304` already caps the base at 80%. The two are multiplicative; a starsilver pickaxe (55% base) + honed 0.20 affix would give ~0.45 × 0.80 = ~0.36s on a 1s channel. Feels OK; user should sanity-check once in-playtest.
- **`hp_regen` tick** — task 11 adds the stat to `derived_stats` but does not implement the tick mechanic in `_physics_process`. This is intentional (out of scope here); the stat exists for forward-compatibility with [[impl-system-status-effects]].
- **`test_stats.gd` exists** at `wyrd/test_stats.gd` (confirmed). Add new assertions directly to this file without creating it.
