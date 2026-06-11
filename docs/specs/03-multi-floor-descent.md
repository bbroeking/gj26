# 03 — Multi-floor descent for procgen crypt arc

> **Outcome**: enter the crypt → on most floors a purple staircase tile (`staircases[0]`) leads down to a fresh procgen floor at depth+1. After 10 floors you can't descend further; floor 10's Hedgemother (spec 05) gates the gold-exit. Depth shows in HUD. State (depth, baseSeed) survives floor swaps.

## Why

Authored layouts already support multi-floor (`switchAuthoredLayout` walks the `staircases[]` array). Procgen dungeons currently emit zero staircases — once you walk in, you can only exit via the gold portal back to town. This spec closes that gap and pins it to a 10-floor crypt arc per the Hades-style decision.

## Scope

**In:**
- Extend `generateDungeonLayout(seed, affixes, scope, depth)` to add a `depth` parameter (default 1) and emit a `staircases: [{ x, y, targetSeed }]` entry on floors 1–9 of a crypt arc (no staircase on the boss floor or the last floor — gold exit only).
- The staircase position: by default one tile in front of `exit`, opposite side from `chestTile`. If no valid floor tile exists there, fall back to `exit` itself with no separate disc.
- Each crypt arc has one `baseSeed` rolled at the entry; floor N's `seed = baseSeed * 31 + depth` (mirror the existing pattern in main.js so it's already discoverable).
- Track current depth on the dungeon state object: `dungeon.depth`, `dungeon.baseSeed`, `dungeon.arcScope = 'crypt'`.
- Wire the purple-disc click/walk-on behavior in `enterDungeon` (or wherever the existing staircase walks-onto logic lives — check `dungeon.layout.staircases` callsite in main.js): on stepping on a crypt staircase, generate the next floor via `generateDungeonLayout(baseSeed * 31 + (depth+1), [], 'crypt', depth+1)`, rebuild via `buildDungeonGroup`, swap meshes, respawn at the new floor's entry tile, increment `dungeon.depth`.
- Boss-floor gating: on `depth === 5` and `depth === 10`, generate the floor with `bossKind` forced (Hedgemother for floor 10, a mid-tier boss like `burrow_boar` or a new mini-boss for floor 5). On floors with a boss, suppress the staircase and require the boss dead before the gold exit "succeeds".
- HUD: a small text element near the existing FPS/title showing `Crypt — Floor N` while `dungeon.active && dungeon.arcScope === 'crypt'`.
- Death-during-arc behavior (matches Q3 decision): on player death inside the arc, return to town with full HP + inventory intact, but `dungeon.depth` resets to 0 (next entry starts at floor 1 with a fresh `baseSeed`).
- "Clear floor" requirement before descending: stepping on the staircase only triggers descent if all hostile enemies in the current floor are dead. Otherwise show a "Enemies remain" log line. Spec covers the gating; combat already exists.
- Replayability: beating Hedgemother on floor 10 → "Crypt cleared" flag on the player → return to town with the floor-10 loot. Re-entering generates a fresh `baseSeed` and resets `depth = 0`.

**Out:**
- Stairs *up* — descent only. (Note in implementation notes.)
- Variable-length arcs / configurable floor counts — hardcode 10 for v1.
- Multiple parallel arcs — only "the crypt" exists. Forge cellar etc. comes later.
- Save state across browser refresh — the run is in-memory only. Death/refresh = new arc.

## Files

| Path | Action |
|---|---|
| `src/scene/dungeon.js` | modify — `generateDungeonLayout` accepts `depth`, emits crypt staircases |
| `src/main.js` | modify — `enterDungeon` records arc state; staircase step triggers `_descendCryptFloor()`; depth HUD; "clear floor" gating |
| `src/ui/hud.js` (or wherever the title/FPS overlay lives) | add depth indicator |
| `src/game/cryptArc.js` | new (optional) — orchestrates `enter`, `descend`, `clear`, `die` transitions for the arc state machine |

## Acceptance criteria

1. Enter the crypt via dev-console / a future entry prop → spawn on floor 1 with `dungeon.depth === 1` and "Crypt — Floor 1" visible.
2. Kill all enemies on floor 1, step on the purple disc → fade → floor 2 renders, depth indicator updates.
3. Re-running the same `baseSeed` reproduces the floor sequence.
4. Floor 5 spawns a mid-boss; staircase doesn't appear until the boss is dead.
5. Floor 10 spawns Hedgemother; gold exit doesn't function until she's dead.
6. Beating Hedgemother → "Crypt cleared" log + return to town with inventory.
7. Death anywhere in the arc → return to town; re-entering rolls a fresh arc (different `baseSeed`).
8. No memory leak after 3 descent cycles (meshes/textures from prior floor disposed).

## Open decisions

- **Boss floors: 5 and 10? Or 5/10 only on a specific scope?** Recommend: only `scope === 'crypt'` runs the depth-based gating. Other scopes keep affix-driven bosses. Notes confirm.
- **Mid-boss at floor 5.** No floor-5 boss exists for the crypt theme yet. Recommend: reuse `burrow_boar` or `wolf_alpha` as a thematic stand-in, OR introduce a new `bossKind: 'crypt_warden'` (matches spec 04's mini-boss enemy if that lands first). Notes record final.
- **"Floor cleared" check.** Currently nothing enforces clearing a floor before exit. Recommend: count `dungeon.enemies.filter(e => !e.dead).length === 0` as the gate. Note: this lets players sneak past in v1 if they avoid all enemies; that's fine — the staircase still requires zero alive hostiles.
- **Staircase visual.** Existing purple disc works. Recommend keep it; consider a subtle pulse animation. Notes record.
- **Gold exit on non-final floors.** Should the gold "return to town" disc still exist on floors 1–9? Recommend yes — players may want to bail with their loot. (Per Q3, voluntary return keeps loot.) Notes confirm.
- **HP between floors.** Q3 decided: full HP on death-return-to-town. Between floors during a single run: recommend *don't* heal. Players must manage HP across the arc (FATE feel).
- **Floor size scaling.** Should floor 10 be larger than floor 1? Recommend: hold GRID = 22 across floors for v1. Difficulty scales via tier/enemy density, not map size. Notes record.
- **Enemy density per depth.** Recommend: `tier = ceil(depth / 2)` so floors 1–2 are tier 1, floors 3–4 tier 2, etc. Tier 5 enemies appear on floors 9–10.
- **Affixes per floor.** Recommend: roll 1 affix on floors 1, 3, 6, 8; floors 2/4/5/7/9/10 are clean. Notes record actual cadence.
- **Where in `enterDungeon` does descent live?** Read existing `switchAuthoredLayout` for the pattern — recommend a sibling `_descendCryptFloor()` that mirrors it but pulls from `generateDungeonLayout` instead of authored JSON.

## References

- Existing scope-aware procgen: [`src/scene/dungeon.js`](../../src/scene/dungeon.js) `generateDungeonLayout`, `buildDungeonGroup`
- Existing floor swap: `switchAuthoredLayout` in `src/main.js` (the pattern to mirror for procgen descent)
- Existing dungeon state: `dungeon.active`, `dungeon.layout`, `dungeon.enemies` in `src/main.js`
- Boss factories: search `bossKind` in main.js — `hedgemother`, `burrow_boar`, `wolf_alpha` already exist
- PRNG: `mulberry32` exported at bottom of `src/scene/dungeon.js`
- Run-shape decision: docs/specs Q&A — Hades-style finite 10-floor arc

## Done check

- [ ] `generateDungeonLayout` accepts `depth`, emits a staircase on non-boss, non-final floors of crypt arc.
- [ ] HUD shows `Crypt — Floor N`.
- [ ] Descent works end-to-end through 10 floors.
- [ ] Boss gating works at 5 and 10.
- [ ] Cleared floors disposed (no leak).
- [ ] Death returns to town and resets the arc.
- [ ] Voluntary return preserves loot.
- [ ] Replayable: re-entering rolls a fresh `baseSeed`.
