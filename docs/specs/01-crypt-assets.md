# 01 — Crypt asset set: PNGs → GLBs

> **Outcome**: 16 cleaned crypt-tile GLBs sitting in `models/`, plus 3 floor PNGs ready to use as tileable textures. Every reference in `docs/concept-art/dungeons/crypt/PROMPTS.md`'s legend resolves to a real file on disk.

## Why

Goal 2 (`src/scene/dungeon.js`) needs real meshes to instantiate per cell. Without these, every other goal stays blocked. The niji 6 PNGs are already on disk — this spec is the last-mile cleanup.

## Scope

**In:**
- Identify the 4 `_UNK_<jobid>` files (wall-corner-inner, wall-corner-outer, archway, brazier) and rename them.
- Pick the best variant (v0/v1/v2/v3) for each of the 16 mesh pieces.
- Run each chosen PNG through Meshy Image-to-3D with the settings from `docs/character-pipeline/MESHY_OPERATIONS.md` recipe C.
- Run each Meshy output through `scripts/clean_ai_mesh.py --rig static` with appropriate `--tris` per piece category.
- Drop the cleaned GLB at `models/dungeon_crypt_<piece>_v1.glb`.
- For the 3 floors: keep the chosen PNG (or a clean 512×512 crop) as the canonical texture, no GLB needed.

**Out:**
- Walls' orientation logic — that's goal 2's parser.
- Animation rigs — these are static props (the cleanup script uses `--rig static`).
- Mood/lighting decisions in-engine — that's goal 2 / rig_test_dungeon.
- Enemies — goal 8.

## Files

| Path | Action |
|---|---|
| `docs/concept-art/dungeons/crypt/dungeon-crypt-_UNK_*.webp` | rename to canonical names |
| `docs/concept-art/dungeons/crypt/` | one chosen-variant PNG per piece marked (filename or sidecar) |
| `models/dungeon_crypt_floor_brick_v1.png` (or stay as `.webp`) | floor texture (no GLB) |
| `models/dungeon_crypt_floor_mossy_v1.png` | floor texture |
| `models/dungeon_crypt_floor_cracked_v1.png` | floor texture |
| `models/dungeon_crypt_wall_straight_v1.glb` | new |
| `models/dungeon_crypt_wall_corner_inner_v1.glb` | new |
| `models/dungeon_crypt_wall_corner_outer_v1.glb` | new |
| `models/dungeon_crypt_archway_v1.glb` | new |
| `models/dungeon_crypt_door_wood_v1.glb` | new |
| `models/dungeon_crypt_stairs_v1.glb` | new |
| `models/dungeon_crypt_column_v1.glb` | new |
| `models/dungeon_crypt_brazier_v1.glb` | new |
| `models/dungeon_crypt_torch_wall_v1.glb` | new |
| `models/dungeon_crypt_sarcophagus_v1.glb` | new |
| `models/dungeon_crypt_altar_v1.glb` | new |
| `models/dungeon_crypt_chest_v1.glb` | new |
| `models/dungeon_crypt_bookshelf_v1.glb` | new |
| `models/dungeon_crypt_rug_v1.glb` | new (the rug *is* meshed — chunky, walkable cell) |
| `models/dungeon_crypt_web_v1.glb` | new |
| `models/dungeon_crypt_bones_v1.glb` | new |
| `models/dungeon_crypt_pottery_v1.glb` | new |

## Acceptance criteria

1. Running `ls models/dungeon_crypt_*` lists all 16 expected `*.glb` files.
2. Running `ls models/dungeon_crypt_floor_*` lists 3 PNGs (or webps).
3. Loading any one GLB in `rig_test.html` (swap `BODY_URL`) renders cleanly — no inverted normals, no exploded vertices, recognizable silhouette.
4. Polycount is reasonable per cleanup settings (≤8k tris for furniture, ≤3k for tiny doodads).
5. No `_UNK_*` filenames remain in the concept-art folder.

## Open decisions

- **Variant choice per piece.** Many pieces have 4 viable variants. Recommend the one with: cleanest silhouette, most readable iron-band detail, fewest extraneous flourishes. Notes file records each pick + one-line reason.
- **Floor format: keep `.webp` or convert to `.png`.** Meshy/Three.js accept both. PNG is more universally tooled; webp is smaller. Recommend `.png` for simplicity; convert via `sips -s format png in.webp --out out.png`.
- **Floor texture size.** MJ outputs ~640×640. For tileability the chosen PNG may need cropping to a clean 512×512 square. Recommend Photoshop-style center crop; flag if seamless tiling needs the edges blended.
- **Polycount targets.** Suggested: 3k tris for floors/walls/small doodads, 5k for furniture, 8k for chest/sarcophagus/door (more silhouette detail). Override per piece if cleanup script over-decimates a feature.
- **Rug — texture or GLB?** PROMPTS.md says "the rug is *meshed* — chunky walkable cell". Recommend GLB for consistency with all other props; this is a tabled decision the implementer can flip if the texture path is dramatically easier.

## References

- Pipeline recipe: [`docs/character-pipeline/MESHY_OPERATIONS.md`](../character-pipeline/MESHY_OPERATIONS.md) recipe C
- Cleanup script: `scripts/clean_ai_mesh.py`
- Tile legend: [`docs/concept-art/dungeons/crypt/PROMPTS.md`](../concept-art/dungeons/crypt/PROMPTS.md) bottom section
- Asset overview: [`docs/ASSET_PIPELINE.md`](../ASSET_PIPELINE.md)

## Done check

- [ ] All 4 `_UNK_*` files identified and renamed.
- [ ] One chosen variant per piece recorded in notes.
- [ ] 16 GLBs in `models/dungeon_crypt_*.glb`.
- [ ] 3 floor textures in `models/dungeon_crypt_floor_*`.
- [ ] One quick visual sanity-check (load each in `rig_test.html`).
- [ ] PROMPTS.md legend rows have ✅ next to completed pieces.
