# Implementation notes — 02-crypt-scope-wiring

## Decisions

- **Crypt MOB roster** (spec Q1, revisited via grill): user rejected goblin-as-skeleton placeholder for lore reasons. `MOB_CRYPT` is now `{1:[], 2:[], 3:[], 4:[], 5:[]}` — crypt runs are exploration-only until spec 04 ships niji 6 enemies. `pickFor` now returns `null` when a scope's pool is explicitly empty (vs the old "fall back to goblin"); main.js mob/guard spawn callers `continue` on null. The penultimate-room guard is also suppressed when the scope's mob table is empty — full silence.
- **Crypt themeMap entry shape**: introduced `kind: null` sentinel meaning "roll a kind per-cell from `pickCryptDecorKind()`" so the single-kind contract of the other scopes stays untouched. Same change applied to both `generateDungeonLayout` (procgen) and `loadAuthoredLayout` (authored) paths.
- **Decor weights** in `dungeonTilesCrypt.js#CRYPT_DECOR_WEIGHTS` lean on `bones / pottery / column / sarcophagus / bookshelf` (the chunky shape-readers) with smaller weights for `brazier / torch_wall / altar / rug / web`. Spec didn't specify; tuned by feel from the 16 GLBs available.
- **Decor count for crypt**: 10–16 (procgen) and 6–12 (authored). Higher than other scopes (4–10) because crypt visual identity is in the props, not the wall material — leaning into more props makes the scope feel different at a glance.
- **Crypt scope-light** = `{ color: 0x8a9aa8, intensity: 0.5, range: 14 }` (spec Q5 recommendation). The warm pools come from the per-prop brazier + torch_wall flickering point-lights.
- **Brazier light**: `(0xff8030, 2.5, 7, 2)` matching `rig_test_dungeon.html` recommendation (Q4). Torch_wall uses same color/range but mounts at y=1.2 instead of 0.8.
- **Flicker animation strategy** — self-managed `requestAnimationFrame` loop attached to the dungeon group in `attachCryptFlicker(group)`, with a stop hook on `group.userData.flickerStop`. Avoids touching main.js's animate loop. RAF auto-stops when the group has no parent (i.e. exitDungeon removes it). For belt-and-suspenders, `exitDungeon` should also call the stop hook — see followup.
- **Chest override**: when `layout.scope === 'crypt'`, swap `buildCryptChest()` (uses `models/dungeon_crypt_chest_v1.glb`) for the procedural wood+gold chest. The gold `PointLight` glow above the chest is kept so the player-eye affordance survives.
- **Floor**: per-tile mesh approach (matches existing `buildWoodFloorTile` pattern). PlaneGeometry(1,1) rotated -π/2, with `dungeon-crypt-floor-brick-v2.png` as a `MeshToonMaterial.map`. Texture cached after first load; tiles created before the texture lands paint grey and upgrade once the load resolves.
- **Web as billboard** (per spec 01 followup): `PlaneGeometry(0.95, 0.95)` with `MeshBasicMaterial({ map: web-v2.png, transparent: true, alphaTest: 0.1, side: DoubleSide })`, tilted 15° backwards and floated to y=0.65 so it reads as a hanging cobweb rather than a floor decal.

## Tradeoffs

- **Synchronous placement vs awaiting GLBs.** Chose synchronous (`_instantiateOrDefer`) — place an empty `Group` at the right transform, attach the loaded scene as a child when the promise lands. Players see slots fill in over ~200 ms after entering. Awaiting all loads before adding the group would have meant a noticeable "stutter" entering the dungeon. Less elegant but better UX.
- **Tris budgets on cleaned GLBs were 3k–8k.** Walls run 292 cells × ~5k tris = ~1.5M tris in a worst-case crypt. Toon shading + no shadows = should be fine on any GPU. If FPS suffers, instancing the wall variants is the obvious next step (only 3 wall meshes, just rotated).
- **Wall variant picker** uses a 4-bit bitmask covering all 16 cases. `count===0` and `count===4` both fall back to `straight` (these only happen for buried interior walls / isolated pillars — rare in well-formed layouts and not visible anyway).

## Surprises

- **Wall GLBs from niji 6 have decorative tops** (battlement crenellations from the source PNGs). They look fine in-engine but make the walls visually taller than the procedural ones. Not blocking, but contributes to the spec 01 followup about re-rolling wall pieces.
- **`window.__game` doesn't expose `dungeon`** — the runtime state lives in a module-scoped `dungeon` var inside main.js. Smoke tests have to traverse the scene for `DungeonGroup`. Not a defect; just a discovery during testing.
- **`generateDungeonLayout` is not exported on `window`** — pulled via `await import('./src/scene/dungeon.js')` for the smoke test. Fine; matches the project's "thin glue + small modules" style.

## Followups

1. **Wall re-roll** — the niji 6 wall pieces have battlement tops (especially the corner variants) which make the dungeon read slightly castle-y rather than crypt-y. A re-roll with sharper "L-shape corner, flat top, no crenellations" prompts would land cleaner pieces. (Carried forward from spec 01.)
2. **Hook flicker-stop into exitDungeon** — `attachCryptFlicker` self-stops when the group has no parent, but a defensive call to `group.userData.flickerStop?.()` from main.js's exitDungeon would be cheap insurance.
3. **Floor + web textures moved to `assets/textures/`** — currently loaded from `docs/concept-art/dungeons/crypt/`. Spec 01 followup #3 says move; not critical for v1.
4. **Door GLB swap** — the existing locked-door rendering still uses the procedural arch even for crypt scopes. Spec 02 stays out of the doors (`layout.doors[]` is affix-driven, not scope-driven), but a future polish pass could route through `dungeon_crypt_door-wood_v1.glb` when `layout.scope === 'crypt'`.
5. **Stairs GLB unused** — `dungeon_crypt_stairs_v1.glb` will be used by spec 03 (multi-floor descent) for the purple-disc staircase props. Wired up here as part of `CRYPT_DECOR_MODELS` so it's preloaded, but no rendering call yet.
6. **Mesh instancing** if the per-wall draw-call count becomes a FPS issue. Three.js `InstancedMesh` works well for the 3 wall variants — flatten the GLB scenes to a single mesh per variant, then place by transform matrix.
