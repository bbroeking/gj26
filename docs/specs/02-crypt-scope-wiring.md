# 02 — Wire the 'crypt' scope into the existing dungeon system

> **Outcome**: walk into a dungeon with `scope === 'crypt'` and see the niji 6 crypt assets in place of the current procedural meshes, lit with a crypt-appropriate palette. No other scope is affected.

## Why

`src/scene/dungeon.js` already procgens layouts, places enemies, drops loot, manages multi-floor authored staircases, and renders meshes — but it does so with procedural `BoxGeometry` shapes via `buildWoodFloorTile`, `buildStoneWallTile`, and the inline decor switch in `buildDungeonGroup`. Spec 01 produces 16 cleaned GLBs. This spec connects them.

The four existing scopes (`briar_maze`, `sunken_hut`, `delve`, `hollow`) keep their current procedural look. Crypt is the first scope to use real GLB assets and becomes the template for moving other scopes onto GLBs later (out of scope here).

## Scope

**In:**
- Add `'crypt'` to `SCOPE_MOB_TABLES` (initially copy `MOB_DEFAULT` or a hand-picked subset; full enemy roster lands in spec 04).
- Add a `'crypt'` entry to the `SCOPE_LIGHT` map in `buildDungeonGroup` (cool blue-violet ambient torch).
- Add a `'crypt'` entry to the `themeMap` decor scatter in `generateDungeonLayout` so `decor[]` entries get a crypt-themed `kind` (e.g. `bones`, `pottery`, `cobweb`).
- In `buildDungeonGroup`, branch on `layout.scope === 'crypt'` so floor/wall/decor placement loads the crypt GLBs from `models/dungeon_crypt_*.glb` instead of calling `buildWoodFloorTile` / `buildStoneWallTile` / inline procedural decor switches.
- Reuse the existing `_loadOnce` GLB-cache pattern from `src/scene/characters.js` for the crypt assets.
- Wall orientation: for each `'wall'` cell, look at the 4 cardinal neighbors and pick the right crypt wall GLB (`wall_straight` vs `wall_corner_inner` vs `wall_corner_outer`) and rotate it accordingly.
- Crypt-specific decor kinds: `column` (C), `brazier` (B + adds an extra warm-orange `PointLight` with flicker), `torch_wall` (t + same), `sarcophagus` (S), `altar` (a), `chest_crypt` (c — overrides default chest mesh), `bookshelf` (b), `rug` (R), `web` (w), `bones` (o), `pottery` (p).
- Verify `enterDungeon(useTier, affixes, runeEffect, 'crypt', layout)` works end-to-end and the procgen scope picker can be told to roll a crypt floor.

**Out:**
- New procgen rules — keep rooms-and-corridors from `generateDungeonLayout` exactly as-is. Only the visuals change.
- Multi-floor descent — that's spec 03.
- Crypt enemies — spec 04 (this spec uses whatever enemy roster lands first; default subset is fine).
- Hedgemother — spec 05.
- Porting the four existing scopes off procedural meshes — leave them alone.
- A "second biome" port — spec 02's pattern is the template for forge cellar later; not implemented here.

## Files

| Path | Action |
|---|---|
| `src/scene/dungeon.js` | modify — extend `SCOPE_LIGHT`, `themeMap`, `buildDungeonGroup` decor switch |
| `src/data/dungeonSpawns.js` | modify — add `MOB_CRYPT` table + `SCOPE_MOB_TABLES['crypt']` |
| `src/data/dungeonTilesCrypt.js` | new — glyph/kind → GLB URL registry, plus per-decor anchor/rotation rules |
| `src/scene/cryptAssets.js` | new (optional) — `_loadOnce` cache + `buildCryptFloor/Wall/Decor(kind, layout)` factories |
| `src/main.js` | modify — wherever `enterDungeon` is called (chart open, dev console), allow `scope='crypt'` as a valid value |

## Acceptance criteria

1. Calling `enterDungeon(1, [], null, 'crypt', generateDungeonLayout(seed, [], 'crypt'))` opens a dungeon that renders with crypt GLBs (no procedural box walls or wooden floors visible).
2. Walls correctly orient at corners (no z-fighting or wrong-facing tiles).
3. Brazier cells emit warm flickering point-lights with a visible flame mesh and pool of warm orange on the surrounding floor.
4. Torch-wall cells render their bracket against the adjacent wall and emit a smaller pool of light.
5. The four existing scopes (`briar_maze`, `sunken_hut`, `delve`, `hollow`) render identically to before — pixel-diff on a fixed seed should be unchanged.
6. Frame rate at GRID = 22 with crypt assets stays within 5% of the procedural-mesh baseline (the GLBs are low-poly so this should hold; if it doesn't, instancing is the followup).

## Open decisions

- **Crypt enemy roster for v1.** Until spec 04 ships the niji 6 enemies, pick the closest existing match. Recommend: `goblin` (skeleton stand-in) for early floors, `ironGob` for mid, `hedgewolf` for late. Notes record final.
- **Wall-neighbor algorithm.** 4-bit bitmask of `[N, E, S, W]` → 16 cases, collapsed to: straight (×2), inside corner (×4), outside corner (×4), T-junction (×4 — recommend reusing straight w/ flag), and isolated pillar (×1 — column). Notes record the exact table.
- **Floor variant assignment.** Decor `kind: 'mossfloor'` already exists in `themeMap['hollow']`. Recommend: for crypt, use `floor_mossy` as an *overlay* on top of the base floor for a small percentage of floor cells, with `floor_cracked` for damaged cells (around boss room or near walls). Default to `floor_brick` PNG as the base tileable texture.
- **Floor: single big plane vs per-tile mesh?** Current code does per-tile via `buildWoodFloorTile`. Recommend: per-tile for compatibility (matches existing pattern, simpler diff), revisit to a single tiled plane in a perf pass.
- **Brazier light color/intensity.** Recommend `(0xff8030, 2.5, 7, 2)` matching `rig_test_dungeon.html`. Notes confirm final.
- **Ambient/fog tint for crypt.** The existing `SCOPE_LIGHT.hollow` is cream; crypt should feel cooler/darker. Recommend `{ color: 0x8a9aa8, intensity: 0.5, range: 14 }` for the dim filler, and rely on the brazier/torch point-lights for the warm pools.
- **Niji floors as textures or per-cell meshes.** PROMPTS.md says "skip Meshy and use as tileable textures". Recommend the texture path; the floor PNG becomes the material's `map` on either the single-plane or per-tile mesh. Notes record final.
- **Should `decor` for crypt include a chest GLB?** `chestTile` is rendered separately in `buildDungeonGroup`. Recommend: override the chest mesh for crypt scope to use `dungeon_crypt_chest_v1.glb`.

## References

- Existing dungeon: [`src/scene/dungeon.js`](../../src/scene/dungeon.js) — see `generateDungeonLayout`, `buildDungeonGroup`, the `themeMap` switch, and `SCOPE_LIGHT`
- Existing spawns: [`src/data/dungeonSpawns.js`](../../src/data/dungeonSpawns.js)
- GLB cache pattern: [`src/scene/characters.js`](../../src/scene/characters.js) — `_loadOnce`, `varyInstance`, `toonifyMaterials`
- Asset filenames: `models/dungeon_crypt_*.glb` (produced by spec 01)
- Tile legend: [`docs/concept-art/dungeons/crypt/PROMPTS.md`](../concept-art/dungeons/crypt/PROMPTS.md)

## Done check

- [ ] `enterDungeon(... 'crypt' ...)` runs without error.
- [ ] Crypt scope renders with GLB walls + GLB props.
- [ ] Wall corners line up; no gaps; no wrong-rotation tiles.
- [ ] Brazier + torch lights flicker; warm orange visible.
- [ ] Existing four scopes look identical to before (regression check).
- [ ] FPS within 5% of pre-change baseline on the GRID = 22 default.
