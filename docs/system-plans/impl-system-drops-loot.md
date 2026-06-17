---
title: Drops & Loot Tables — Implementation Plan
parent: "[[system-drops-loot]]"
domain: Gather · Craft · Economy
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Drops & Loot Tables — Implementation Plan

> Build doc for [[system-drops-loot]]. Done when: shrine dead-code is resolved, every boss kind guarantees a signature drop, `_pick_kind` is depth-gated, and `test_drops.gd` asserts the rarity math — all gates green.

## Definition of done

- `"shrine"` constant is either wired (shrine interaction spawns a pickup 25% of the time) or deleted (buff-only, no dead constant).
- Killing a boss with a mapped `BOSS_SPECIFIC_DROPS` entry always includes its targeted kind in the drop pile (confirmed by headless assertion).
- `_pick_kind` rejects kinds below their `KIND_DEPTH_MIN` threshold; `longbow` never appears at depth 0.
- `test_drops.gd` (already exists at `wyrd/test_drops.gd`) is extended with rarity-math assertions (D6–D10) that all pass headless and are added to the CI gate alongside the existing five suites.
- Plan.md B4 pickup-feel work is **not** duplicated here — cross-linked only.

## Preconditions / dependencies

- [[impl-system-items-affixes]] — `_pick_kind` pulls from `Items.kind_ids()` and `Items.KINDS`; `Items.make_item` does affix rolling. Must be stable before depth-gating extends the filter.
- [[impl-system-inventory-equipment]] — `ItemPickup.try_take` calls `inv.find_first_fit` / `inv.try_place`; no structural changes needed here, but the inventory must be importable in headless tests.
- [[impl-system-bosses]] — `layout_loader.gd:669` already sets `boss.kind = boss_kind`; Task 3 below reads that field from `combatant.gd:_spawn_drops`. Requires `boss.kind` var to exist on the combatant — it does NOT currently; see Task 3.
- [[impl-system-multiplayer-netcode]] — the co-op drop pipe (`net_game.gd:357–372`) broadcasts `(kind_id, rarity, pos)`. Task 3's targeted boss drop must also route through this pipe when `multiplayer.is_server()`.
- **Plan.md Part B / Phase B4** — pickup feel (beacon suck, satchel slot pulse, chime) is owned there. This plan does not re-plan those beats.
- **No missing files**: `test_drops.gd` already exists (`wyrd/test_drops.gd`); it will be extended, not created.

## Tasks (ordered)

### Phase 1 — Shrine dead-code resolution

1. **Decide shrine intent in `drops.gd:9–22`** — `data/drops.gd:9` (`ROLE_DROP_CHANCE`) and `data/drops.gd:20` (`ROLE_TIER_BIAS`) both contain a `"shrine"` entry that is unreachable because `shrine.gd:apply` never calls `roll_drop`. **Option A (item bonus):** keep constants, wire drop in Task 2. **Option B (buff-only):** delete both `"shrine"` lines, add comment `# shrines are buff-only — no item drop`. This is the only design decision needed before coding. _Verify:_ no test fails after either change; grep confirms constant is gone (Option B) or newly called (Option A). _Effort:_ S.

2. **(Option A only) Wire shrine item drop** — `scripts/shrine.gd:apply()` (line 101). Add `var depth: int = 0` field to `Shrine` (above line 29). In `layout_loader.gd:_build_interactable` (line 606), after `s.seed_value = ...`, add `s.depth = depth` (same pattern as `c.depth = depth` for chests at line 603). In `shrine.gd:apply()`, after `player.apply_shrine_buff` (line 106), add:

   ```gdscript
   const Drops := preload("res://data/drops.gd")
   var pile: Array = Drops.roll_drop("shrine", depth)
   for it: Dictionary in pile:
       var ang: float = randf() * TAU
       var kick := Vector3(cos(ang), 0.0, sin(ang)) * randf_range(0.5, 1.0)
       ItemPickup.spawn(get_parent(), it, global_position + kick)
   ```

   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` stays green. _Effort:_ S.

### Phase 2 — Headless rarity math tests (extend `test_drops.gd`)

3. **Add D6 — boss always rare+** — `test_drops.gd` after line 116 (before `quit`). Call `Drops.roll_drop("boss", 5)` in a loop of 200 iterations; collect all rarities; assert no `"normal"` in the result set.

   ```gdscript
   # D6 — boss never yields normal rarity
   const Drops2 := preload("res://data/drops.gd")
   var boss_normals := 0
   for _i in 200:
       for it: Dictionary in Drops2.roll_drop("boss", 5):
           if String(it.get("rarity", "")) == "normal":
               boss_normals += 1
   _check("D6", boss_normals == 0, "boss: %d normal drops (expect 0)" % boss_normals)
   ```

   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_drops.gd` — D6 PASS. _Effort:_ S.

4. **Add D7 — elite bias ≥60% magic+** — Same file. 500 rolls of `roll_drop("elite", 0)`, assert ≥60% are `"magic"` or better. Mirrors parent note Phase 2 spec exactly. _Verify:_ D7 PASS headless. _Effort:_ S.

5. **Add D8 — depth scaling** — Same file. 1000 rolls each of `_roll_tier("combat", 0)` vs `_roll_tier("combat", 8)`. Expose `_roll_tier` as a `static` callable (it already is, line 43 of `drops.gd`) — call directly via `Drops._roll_tier(...)`. Assert depth-8 mean ≥ depth-0 mean + 3. _Verify:_ D8 PASS headless. _Effort:_ S.

6. **Add D9 — trade tools excluded** — 500 rolls of `roll_drop("combat", 0)`. Assert no item has `category in ["pickaxe", "axe"]` and no `kind_id in ["warbow", "starsilver_band"]`. (These are already filtered by `_pick_kind:63–65`; this test locks the behaviour.) _Verify:_ D9 PASS headless. _Effort:_ S.

7. **Register `test_drops.gd` in the CI gate** — `CLAUDE.md` lists five headless suites; add `test_drops.gd` to that list. Also add it to any CI script that runs the suite (grep for the existing five test invocations to find the script). _Verify:_ CI gate invokes all six scripts. _Effort:_ S.

### Phase 3 — Boss targeted drops

8. **Add `boss_kind` var to `combatant.gd`** — `scripts/combatant.gd:59`. After `var depth := 0`, add:

   ```gdscript
   var boss_kind: String = ""   # set by layout_loader for boss combatants
   ```

   `layout_loader.gd:669` already sets `boss.kind = boss_kind` but `kind` is not a declared var — this assignment currently silently creates a dynamic property. Rename to `boss_kind` to use the explicit typed var; update `layout_loader.gd:669` accordingly: `boss.boss_kind = boss_kind`. _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` green. _Effort:_ S.

9. **Add `BOSS_SPECIFIC_DROPS` dict to `drops.gd`** — `data/drops.gd`, below the `BOSS_DROP_COUNT` constant (line 23). Maps boss kind string to a list of guaranteed kind IDs (one targeted item per boss, separate from the generic pile):

   ```gdscript
   const BOSS_SPECIFIC_DROPS: Dictionary = {
       "hedgemother":       ["shortbow"],        # Whispering Yew unique — its unique entry exists
       "burrow_boar":       ["leather_chest"],
       "wolf_alpha":        ["leather_boots"],
       "hedgemother_queen": ["warbow"],          # capstone boss; warbow unlocked here
   }
   ```

   Note: `warbow` and `starsilver_band` are excluded from the *generic* random pool by `_pick_kind:65`, but the boss targeted drop **bypasses** `_pick_kind` entirely — it calls `Items.make_item(kind_id, "rare")` directly. This is the intended design (trophy-quality items that can't appear elsewhere). _Verify:_ no runtime errors from constant addition alone. _Effort:_ S.

10. **Extend `roll_drop` signature for `boss_kind`** — `data/drops.gd:26`. Change:

    ```gdscript
    static func roll_drop(role: String, depth: int = 0) -> Array:
    ```
    to:
    ```gdscript
    static func roll_drop(role: String, depth: int = 0, boss_kind: String = "") -> Array:
    ```

    At the top of the function body, before the loop, insert:

    ```gdscript
    if boss_kind != "" and BOSS_SPECIFIC_DROPS.has(boss_kind):
        for tid: String in BOSS_SPECIFIC_DROPS[boss_kind]:
            var targeted: Dictionary = Items.make_item(tid, "rare")
            if not targeted.is_empty():
                out.append(targeted)
    ```

    The generic `BOSS_DROP_COUNT := 3` pile still runs after this block — targeted drop is **additive** (boss drops 4 total: 1 targeted + 3 generic `rare+`). If the design decision is subtractive (3 total), change `count := BOSS_DROP_COUNT` to `count := BOSS_DROP_COUNT - BOSS_SPECIFIC_DROPS.get(boss_kind, []).size()` — see Open Questions. _Verify:_ no test regressions. _Effort:_ S.

11. **Thread `boss_kind` through `_spawn_drops`** — `scripts/combatant.gd:820`. Change:

    ```gdscript
    var pile: Array = Drops.roll_drop(role, depth)
    ```
    to:
    ```gdscript
    var pile: Array = Drops.roll_drop(role, depth, boss_kind)
    ```

    Also update the co-op net pipe block (lines 828–831): `net_game.drop_event` currently sends `(kind_id, rarity, pos)` per item; this already handles targeted drops naturally since the targeted item lands in `pile` like any other item. No change needed to `net_game.gd`. _Verify:_ `test_wyrd_dungeon_scene.gd` green. _Effort:_ S.

12. **Add D10 — targeted boss drop headless assertion** — `test_drops.gd`. Call `Drops.roll_drop("boss", 9, "hedgemother")` 20 times; assert every pile contains at least one item with `kind_id == "shortbow"` (the hedgemother's targeted entry). Also assert generic pile still contains items of other kinds.

    ```gdscript
    var targeted_found := 0
    for _i in 20:
        var bpile: Array = Drops.roll_drop("boss", 9, "hedgemother")
        for it: Dictionary in bpile:
            if String(it.get("kind_id", "")) == "shortbow":
                targeted_found += 1
    _check("D10", targeted_found == 20,
        "hedgemother targeted drop: %d/20 piles had shortbow" % targeted_found)
    ```

    _Verify:_ D10 PASS headless. _Effort:_ S.

### Phase 4 — Depth-gated kind pool

13. **Add `KIND_DEPTH_MIN` to `drops.gd`** — below `BOSS_SPECIFIC_DROPS` (after Task 9). Maps kind ID to minimum depth at which it enters the random pool. Kinds absent from the dict default to 0 (available always):

    ```gdscript
    const KIND_DEPTH_MIN: Dictionary = {
        "longbow":        3,
        "starsilver_band": 7,
        "warbow":         8,    # still excluded from generic pool by _pick_kind; entry here is for future expansion
    }
    ```

    _Verify:_ constant addition causes no errors. _Effort:_ S.

14. **Update `_pick_kind` to accept depth and filter** — `data/drops.gd:60`. Change signature and body:

    ```gdscript
    static func _pick_kind(depth: int = 0) -> String:
        var ids: Array = Items.kind_ids().filter(func(id: String) -> bool:
            return String(Items.KINDS[id].category) not in ["pickaxe", "axe"] \
                and String(id) not in ["warbow", "starsilver_band"] \
                and int(KIND_DEPTH_MIN.get(id, 0)) <= depth)
        if ids.is_empty():
            return "shortbow"   # fallback — shortbow is always eligible
        return ids[randi() % ids.size()]
    ```

    Update the call site at `drops.gd:35` — change `_pick_kind()` to `_pick_kind(depth)`. _Verify:_ `test_drops.gd` full suite green. _Effort:_ S.

15. **Add D11 — depth pool assertions** — `test_drops.gd`. Assert `shortbow` appears in depth-0 rolls; assert `longbow` never appears at depth 0 (200 rolls); assert `starsilver_band` never appears below depth 7 but does appear at depth 7+ (note: `starsilver_band` is currently also excluded from `_pick_kind` via the hardcoded `not in ["warbow","starsilver_band"]` filter — if the design intent is that `starsilver_band` should appear at depth 7+ in the generic pool, **remove** it from that hardcoded exclusion in Task 14; otherwise add only the `longbow` depth assertion and leave `starsilver_band` as forge-only). See Open Questions.

    ```gdscript
    var lb_at_d0 := 0
    for _i in 200:
        for it: Dictionary in Drops.roll_drop("combat", 0):
            if String(it.get("kind_id", "")) == "longbow":
                lb_at_d0 += 1
    _check("D11", lb_at_d0 == 0,
        "longbow at depth 0: %d occurrences (expect 0)" % lb_at_d0)
    ```

    _Verify:_ D11 PASS headless. _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 3–7 only** (Phase 2 — headless math tests):

- Extend `test_drops.gd` with D6–D9 rarity-math assertions.
- Register `test_drops.gd` in CLAUDE.md CI gate.

Acceptance: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_drops.gd` runs with D1–D9 all PASS; no existing tests broken. This slice has zero production-code risk — it only adds test coverage, making all subsequent tasks provably safe to land.

## Test & verification plan

| Suite | When to run | What it guards |
|---|---|---|
| `test_drops.gd` (D1–D11) | After every task in this plan | Rarity math, boss targeted, shrine 25%, depth gating, trade-tool exclusion |
| `test_wyrd_dungeon_scene.gd` | After Tasks 2, 8, 11 | Shrine/boss wiring doesn't break the full dungeon build |
| `test_wyrd_loop.gd` | After Task 2, 10 | Shrine + boss drops don't break the game loop |

All five existing CI suites must stay green throughout. `test_drops.gd` is added as the sixth CI gate in Task 7.

**Playtest** (not headless): after Task 11, load a crypt chart, kill the Hedgemother, confirm the drop pile contains a Shortbow alongside the generic `rare+` cascade. After Task 2 (Option A), pray at a shrine and observe an item pickup spawning 1 in 4 runs over ~20 attempts.

## Risks & open questions

- **Shrine intent (Task 1 decision gate):** the whole of Phase 1 depends on this call. Option A adds ~15 LOC; Option B removes 2 lines. Either closes the dead-code gap. Recommend Option B unless the design explicitly wants shrine item rewards.

- **Boss targeted drop count (Task 10 / Open Q):** current plan is additive (boss drops 4 total). If budget is subtractive (keep at 3), adjust `count` in Task 10 as noted. Either is a single-line change; decide before shipping Task 10.

- **`starsilver_band` in generic pool (Task 15 / Open Q):** `starsilver_band` is currently hardcoded out of `_pick_kind` (forge-only). If the design wants it to appear in the generic pool at depth 7+, it must be removed from the hardcoded exclusion in Task 14 — but then it would no longer be guaranteed forge-only, which may undercut the crafting progression in [[impl-system-items-affixes]]. Safest default: leave it forge-only, test only `longbow` depth-gating in D11.

- **`boss.kind` dynamic property (Task 8):** `layout_loader.gd:669` currently writes `boss.kind = boss_kind` which silently creates a dynamic property (Godot 4 allows this on non-typed nodes). Task 8 adds an explicit `var boss_kind: String = ""` and renames the write site. This is safe but is a one-line rename that must happen before Task 11 can read the field reliably.

- **Affix-modified drop rates:** `ROLE_TIER_BIAS` is a `const` — a future `Bountiful` chart affix that bumps drop rates would need it converted to a runtime `var`. Not in scope here; flag for [[impl-system-charts-wayfinding]] if that affix is designed.
