# Implementation notes — 04-crypt-enemies

## Decisions
- **Stat tuning** (`src/data/enemy-defs.js`): rat trivial (8 hp / 2 atk), skeleton easy (18/5), ghost medium (22/5), hedge_sprite hard (32/6). Stat curve matches the existing `tier:` ladder (trivial → hard) so MOB_CRYPT weights mesh with floor-tier scaling already in dungeon code.
- **Ghost rig is `static`** (no limbs). Added `_STATIC_RIG_PARTS = ['Body','Head']` in characters.js so the GLB → enemy pipeline accepts a third rig variant. Ghost gets a custom animator (`anim/ghost.js`) doing whole-mesh Y-bob + Body sway + Head drift instead of leg-cycle.
- **Rat animator wraps `animateQuadruped`** with tuned `legSwingAmp` + `legSwingHz` opts — small fast-skittering critter feel, not the lumbering boar default.
- **MOB_CRYPT weights**: tier 1-2 skeleton-heavy with rat chaff; tier 3 adds ghost; tier 4-5 lean on hedge_sprite. Mirrors the briar/sunken/delve scope tables which transition from "low-tier chaff" to "high-tier signature" between tier 1 and 5.
- **Cleanup tris budgets**: skeleton 5000, rat 3000, ghost 3000, hedge_sprite 5000. Quadruped and static get the smaller budget; humanoids the larger one.

## Deviations
- Spec implied "fall back to procedural if GLB missing" was already in place. It is — `_buildEnemyFromGLB` returns null on a missing GLB key, which causes `buildSkeletonMesh` etc. to fall through to a procedural cube fallback. Confirmed by the live boot: even before the skeleton GLB was downloaded the game ran with placeholder boxes.

## Tradeoffs
- **Cache-bust per import**: I had to bump version strings on three modules (`main.js`, `enemies.js`, `characters.js`) because ES module imports without versioned URLs were aggressively browser-cached. Adopted a uniform `?v=20260520-spec04b` token across the imports touching the new exports. The `?v=` lives on the imported URL, not just the entry script — leaving any single one stale breaks the import chain with `does not provide an export named X`.
- **Ghost mesh height + float**: spawn factory sets `y = 0.6` above terrain. Picked 0.6 m as a compromise between "obviously floating" (≥1 m looks cartoonish) and "ground-grazing" (≤0.3 m reads as static). The Y-bob in the animator adds ±0.1 m on top.

## Surprises
- The "Geometric Skull Sentinel" Meshy job was 8.9 MB raw → 124 KB after `clean_ai_mesh.py` decimation. The skeleton had detached arms/legs in the source mesh; the script's slice-by-cuts (head_z=1.37, legs_z=0.85, arm_x=±0.18) caught them anyway because the cuts are world-space planes, not per-island.
- Meshy reported `Mesh1.003` and `Mesh1.002` as "not valid" warnings on export but the resulting GLB is fine in three.js. Suspect these are the very-thin spinal segments that ended up below the post-decimation min-tri threshold.
- The cache-bust issue ate ~10 minutes of debugging. The browser cached `enemies.js?v=20260520-spec04` with the OLD enemies.js content (no version-bust on the inner characters.js import), so even though the file on disk was correct, the served module was stale. Lesson: when you add a version-bust to a *previously unversioned* URL, the first cache slot uses whatever content the server returned right then — and stays there.

## Followups
- **Boss room hookup**: `layout.bossKind` for crypt arcs still resolves to non-crypt bosses (hedgemother only on the final floor — that one IS thematic). Mid-boss at floor `ceil(N/2)` is wolf_alpha which doesn't fit the crypt visually. Consider authoring a crypt-themed mini-boss (e.g. a beefier skeleton variant) and routing it through the spec 03 mid-boss hook.
- **Guard pool**: `GUARD_BY_TIER` is still global (brambleCap/ironGob/hedgewolf) — penultimate rooms in the crypt will spawn forest-themed guards. Either add a per-scope `GUARD_BY_SCOPE` table or accept the mix.
- **Drops**: `boneshard`, `rat_tail`, `wisp_essence`, `thorn_essence` are referenced in enemy `drops:` arrays but I didn't verify each one exists in `ITEMS`. Spot-check before next playtest, or the drop call will silently noop.
- **Animator polish**: ghost's animator is the most untested — only verified via `buildGhostMesh()` returning the right rig. Watch it in-game and tune drift amplitude / sway speed once observed.
