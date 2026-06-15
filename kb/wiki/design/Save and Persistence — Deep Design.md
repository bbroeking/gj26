---
type: design
tags: [system-design, save-persistence]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/systems/Save System.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "wyrd/scripts/save_game.gd"
  - "wyrd/scripts/game.gd"
  - "wyrd/test_wyrd_loop.gd"
  - "kb/wiki/games/life-sim/Stardew Valley.md"
---

# Save and Persistence — Deep Design

> Forward-looking deep design. Current-state: [[Save System]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

Persistence is invisible when it works and catastrophic when it doesn't. The cozy promise is *"your village is still there when you come back, and nothing you earned is gone."* The Wayfinder closes the lantern, walks away, and the next session reopens in town with every trade level, every chart, every restored corner intact — never a "version mismatch, starting fresh" that erases ten hours of remembering paths. Save/persist is the load-bearing wall under [[Trades and Leveling|the four trades]], the [[Charts|chart case]], and the [[Living Atlas|growing village]]. It is not a feature the player names; it is the trust that lets the spine matter. This doc's center of gravity is the §9 step-1 work: **replace the destructive reset with an ordered migration ladder** so the village survives every patch.

## What ships today (grounded in code — cite files/functions you read)

Today the whole cross-scene state lives on the `Game` autoload (`wyrd/scripts/game.gd`) and round-trips through `SaveGame` (`wyrd/scripts/save_game.gd`) to a single JSON file, `SAVE_PATH := "user://wayfinder_save.json"`, at schema `VERSION := 1`.

- **`SaveGame.save(game)`** writes one dict: `trades`, `materials`, `charts`, `gold`, `summit_cleared`, `muted`, `loadout`, `discovered_inks`, `seen_hints`, `tutorial_step`, `player_hp`, `inventory`, `equipment`. Written synchronously via `FileAccess`, called by `Game.save_now()` after every meaningful mutation and on `NOTIFICATION_WM_CLOSE_REQUEST`.
- **`SaveGame.load_into(game)`** is the defect site. Line 53: `if int(data.get("version", 0)) != VERSION:` → `push_warning("version mismatch — starting fresh"); return false`. **A v0 save is discarded, not migrated.** Two ad-hoc backfills already do migrator work informally: the Huntcraft key (lines 70–72, ADR 0005) and the pre-discovery ink set (lines 81–86, spec 43).
- **`_encode`/`_decode`** wrap `Vector2i` as `{"__v2":[x,y]}` and `Color` as `{"__col":[r,g,b,a]}` (JSON can't hold them); inventory items re-place into the Tetris grid on load via `find_first_fit`.
- **What does NOT persist** (correct, keep): `buffs` (a sip never outlives the session), `active_chart`/`in_dungeon` (mid-run close saves the chart consumed, reopens in town), `pending_toasts`.
- **`WYRD_NO_SAVE=1`** sets `persistence_enabled = false` so the four headless suites don't clobber the real save.
- **The destructive test:** `test_wyrd_loop.gd::_test_save_roundtrip` (line 606) writes the *real* `SAVE_PATH`, doctors it, and ends with `SaveGame.clear()` — if killed mid-run it leaves the player's save partial or deleted ([[Save System]] caveat).
- **Co-op:** each peer keeps its own `Game` and its own save; guests never write the host's file (the [[Save System]] page and the host-authoritative co-op contract).

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

**1. The migration ladder (DEMO, §9 step 1).** Replace the line-53 discard with an ordered run of migrators. Each migrator is a pure `Dictionary → Dictionary` function keyed to the version it upgrades *from*; on load, run every migrator from `data.version` up to `VERSION`, then proceed. The two existing backfills become **migrator #1 (Huntcraft key)** and **migrator #2 (pre-43 inks)**, lifted out of `load_into` into the ladder so the load path reads clean. A genuinely unreadable save (corrupt JSON, a *future* version) still fails safe — but a known *older* version always migrates. Bump `VERSION` only when a migrator is added.

**2. Non-destructive roundtrip test (DEMO).** Back up `SAVE_PATH` to a temp path at test entry, restore it at exit (and on early failure), or — cleaner — point the test at a `SAVE_PATH_OVERRIDE` injected via env so it never touches the real file. The test must exercise the *ladder*, not just one backfill: feed it a hand-written v0 blob and assert it lands at `VERSION` with no data loss.

**3. Save-size budget (DEMO).** One player's JSON, pretty-stringified, must stay well under **256 KB** — comfortable for the demo's bounded inventory + ~17-level trades + a chart case of tens. The on-demand check is a one-line assert in the roundtrip test on `JSON.stringify(...).length()`. This budget is the seam that keeps the Horizon (Codex, Almanac progress) from silently bloating saves.

**4. Co-op shared-data persistence on host change (DEMO contract, not full build).** Resolve the *question*, ship the *minimum*. Each peer's character save is theirs (today's model — keep). The one piece of genuinely *shared* state is per-party run context (the socketed chart's seed, who's downed). Demo answer: **shared run state is host-RAM-only and dies with the session** (matches `active_chart` already being non-persistent); on host migration the run ends gracefully to town rather than transferring a logbook. The persisted *party logbook / Charter* is **Horizon** — but the schema reserves a top-level `charter` key now (absent = legacy) so it can be added without a destructive reset.

### Data model & formulas (concrete, GDScript-flavored; use tables)

```gdscript
const VERSION := 2  # bump when a migrator is appended
# Ordered: index i upgrades a save AT version i to version i+1.
const MIGRATORS := [_m0_to_1, _m1_to_2]  # Func refs

static func _migrate(data: Dictionary) -> Dictionary:
    var v := int(data.get("version", 0))
    while v < VERSION:
        data = MIGRATORS[v].call(data)  # each returns a v+1 dict
        v += 1
        data["version"] = v
    return data
```

| Migrator | From→To | What it does | Provenance |
|---|---|---|---|
| `_m0_to_1` | 0→1 | backfill `trades.hunt = {lv:1,xp:0}` | ADR 0005, `game.gd` line 71 |
| `_m1_to_2` | 1→2 | if no `discovered_inks`, set `["hedge_ink","stoneground_ink","refined_ink"]` | spec 43, `save_game.gd` line 86 |
| *(future)* | 2→3 | e.g. add `almanac` page-state default `{}` | Pillar One |

| Persisted (keep) | Runtime-only (never persist) | Horizon-reserved key |
|---|---|---|
| trades, materials, charts, gold | buffs, active_chart, in_dungeon | `charter` (co-op logbook) |
| summit_cleared, muted, loadout | pending_toasts, modal_count | `almanac` (page progress) |
| discovered_inks, seen_hints, tutorial_step | net peer state | `codex` (first-discovery set) |
| player_hp, inventory, equipment | | `deepening` (depth ranks) |

**Failure-mode rule (cozy):** load NEVER throws away earned state on a *recognized older* version. The only discard path is genuinely-corrupt JSON or a *newer-than-known* version (a downgrade), both of which warn and fall back to a fresh game — and even then, write the unreadable blob to `SAVE_PATH.bak` first so a future patch can recover it.

### Content to author (tiers / tables / worked examples)

**Worked migration example.** A v0 save from a pre-Huntcraft, pre-discovery build: `trades` lacks `hunt`, no `discovered_inks` key. `_migrate` runs `_m0_to_1` (adds `hunt`), then `_m1_to_2` (adds the three legacy inks), stamps `version: 2`, loads. Player keeps their level-9 Earthcraft and full chart case. **Today this exact save is deleted at line 54.**

**Author per Pillar:** one migrator *if and only if* a release changes the schema shape (a new persisted field with a non-trivial default, or a renamed key). Most content (new affixes, inks, enemies) needs *zero* migrators — they're data, not save shape. The discipline: **a migrator is the contract that the previous schema is forever loadable.** Append-only; never edit a shipped migrator.

### Edge cases, failure modes, anti-frustration

| Case | Behavior |
|---|---|
| Corrupt JSON | warn, copy to `.bak`, fresh game (today's behavior, kept) |
| Older known version | **migrate through the ladder** (the fix) |
| Newer version (downgrade after a patch revert) | warn, `.bak`, fresh — don't half-read a future shape |
| Saved Tetris position no longer valid (grid shrank) | `find_first_fit` re-places (already implemented) |
| Save written mid-scene-change | synchronous `FileAccess` already completes before swap |
| Test kills mid-roundtrip | backup/restore guard means the real save is untouched |
| Co-op host crash mid-run | run ends to town; no shared file to corrupt |

## Interlocks — how this feeds/uses other systems

Persistence is the substrate under nearly everything: it stores [[Trades and Leveling]] XP/levels, the [[Charts|chart case]], [[Gathering|the materials satchel]], [[Economy|gold]], [[Inks|discovered ink recipes]], [[Skills|the loadout]], and [[Items and Gear|inventory + worn equipment]]. It gates the [[Onboarding and Tutorial]] (`tutorial_step`) and the [[Affixes|first-time-affix teaching]] flag. It is the place where [[Living Atlas|town-growth]] state will live (Almanac page completions → restored corners), and where the Horizon [[Wayfarer's Codex|Codex]] first-discovery set and [[Deepening]] depth ranks will register. It interlocks with [[Multiplayer Co-op]] via the host-authoritative contract: each peer saves independently, and the reserved `charter` key is the seam for any future shared logbook. The [[Balance Philosophy]] no-frustration guardrails extend here as the *"never discard earned state"* invariant.

## Demo scope vs Horizon (respect the P7 cut-line and P1 spine-growth)

| Feature | Scope |
|---|---|
| Migration ladder + two existing backfills as migrators | **DEMO** (Phase 0, §9 step 1) |
| Non-destructive roundtrip test | **DEMO** (Phase 0 exit criterion) |
| Save-size budget assert (<256 KB) | **DEMO** |
| Versioned schema with reserved Horizon keys | **DEMO** (cheap; enables non-destructive future) |
| Co-op host-change *contract resolved*, run state host-RAM-only | **DEMO** (Phase 0 locks the contract) |
| Persisted party logbook / Charter | **HORIZON** (key reserved, not built) — P7: ships only when co-op together-play does |
| Parallel-slot file format (Wandering Seasons / multiple saves) | **HORIZON** — versioned so it's an additive seam, never a destructive reset |
| Almanac / Codex / Deepening persisted state | **HORIZON** — defaults supplied by future migrators |

Per **P7**, no persistence feature ships ahead of the region that uses it; the demo builds only the ladder + test + budget + contract. Per **P1**, this protects the spine without spending design budget on it — it is plumbing for cozy depth, not a system the player engages.

## Implementation notes (Godot)

- **`wyrd/scripts/save_game.gd`** — add `MIGRATORS`, `_migrate`, the two migrator funcs (lift from `game.gd` lines 71–72 and `save_game.gd` lines 81–86); replace the line-53 discard with `data = _migrate(data)` then proceed; add the `.bak` copy on unreadable saves. Bump `VERSION` to 2.
- **`wyrd/scripts/game.gd`** — `_ready` already calls `SaveGame.load_into`; the inline Huntcraft/ink backfills (lines 70–72, 81–86) move *out* into migrators (keep behavior identical — net zero player-visible change, cleaner load path).
- **`wyrd/test_wyrd_loop.gd::_test_save_roundtrip`** (line 606) — wrap in backup/restore or a `SAVE_PATH` override; add a hand-written-v0 fixture asserting the ladder lands at `VERSION` with no loss; add the size-budget assert. This is the suite that guards persistence.
- **Test suite that guards it:** `test_wyrd_loop` (carries the roundtrip + economy-gate). Must stay green per CLAUDE.md; run with `WYRD_NO_SAVE=1`.

## Open questions

- Should `.bak` recovery be surfaced to the player ("we kept your old save — tell Mara") or stay silent dev-only?
- For Wandering Seasons (Horizon), is the parallel slot a *separate file* (`wayfinder_save_<slot>.json`, Stardew's per-farm model) or a slots array inside one file? Leaning separate-file for isolation.
- Co-op: when the Charter ships, does the host's machine own the canonical logbook (host-authoritative) or does each peer cache a copy reconciled on join?
- Do we want an explicit `save_now()` debounce, or is synchronous-on-every-mutation fine at demo save sizes? (Currently fine; revisit if the Almanac balloons writes.)

## See also / Sources

- [[Save System]] — current-state systems page
- [[Universe Build-Out Plan]] — §9 step 1, §6 persistence workstream, P7 cut-line
- [[Multiplayer Co-op]] — host-authoritative contract, the reserved Charter seam
- [[Balance Philosophy]] — the never-discard-earned-state cozy invariant
- [[Trades and Leveling]], [[Charts]], [[Items and Gear]] — the chief persisted state
- `wyrd/scripts/save_game.gd`, `wyrd/scripts/game.gd`, `wyrd/test_wyrd_loop.gd`
- [[Stardew Valley]] (per-farm single-file + co-op cabin slots), [[RuneScape]] (server-authoritative durable account state), [[EVE Online]] (single shard, append-only economic history) — persistence-model references
