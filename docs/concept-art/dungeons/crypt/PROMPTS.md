# Crypt biome — tile asset spec + Midjourney/Meshy prompts

First dungeon biome. **Mossy fairytale crypt** — stone bricks, brazier glow,
mossy floors, soft storybook palette (not gothic-dark). Matches the FATE-style
isometric ARPG reference. Same pipeline as the ranger props: Midjourney →
save PNG → Meshy Image-to-3D → `clean_ai_mesh.py --rig static` → drop in
`models/`. After all 20 land I wire up the dungeon parser.

## Conventions

- **Concept art PNGs** → save here as `dungeon-crypt-<piece>.png` (e.g.
  `dungeon-crypt-floor-brick.png`).
- **Final GLBs** → `models/dungeon_crypt_<piece>_v1.glb`.
- **Layout files** → `docs/dungeons/<level_name>.txt` (ASCII grid — format
  proposal at the bottom of this doc).
- All pieces are sized for a **1 × 1 m tile grid**. Walls are 2 m tall.
  Props fit within one cell unless noted.
- **Atmosphere reference**: `../../dungeon-interior-1.png` —
  pass as `--cref` on every Midjourney call so palette/style stay locked.

## Master prompt stem

Every prompt below is the same stem with the per-piece bit swapped in.
Keep `--cref` and `--cw 50` constant across the whole set so the tiles
feel like one room.

```
chunky low-poly stylized fairytale dungeon <PIECE>, mossy grey stone, cozy storybook game asset, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look, soft chunky shapes, centered, even soft lighting --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, UI, HUD, multiple objects, scenery, background, text
```

## Meshy settings (same for every tile)

- Image-to-3D · Stylized · `model_type: lowpoly` · `topology: triangle`
- `pose_mode: ` (leave empty — props aren't characters)
- `target_polycount: 3000` for floors/walls/small props · `5000` for
  furniture · `2000` for tiny doodads
- `should_texture: yes` · `enable_pbr: yes` · `ai_model: meshy-6` (pinned)
- Use the master `dungeon-interior-1.png` as the **Style Image** on every call
- Cleanup: `clean_ai_mesh.py --rig static --tris <as above>`

---

## 1–3. Floor tiles

Floors are special — they need a clean **top-down shot** so the tile reads
flat. Each is a 1 × 1 m square that tiles seamlessly when placed edge-to-edge.

### `dungeon-crypt-floor-brick.png` — standard floor
```
top-down view of a single square stone brick floor tile, weathered grey limestone, subtle mortar lines, a slight crack or two, chunky low-poly stylized fairytale dungeon asset, one tile only filling the frame, plain flat neutral grey background outside the tile, Wind Waker cel-shaded look, soft chunky shapes --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, UI, multiple tiles, perspective view, scenery
```

### `dungeon-crypt-floor-mossy.png` — overgrown variant
```
top-down view of a single square stone brick floor tile overgrown with patches of bright green moss in the cracks, weathered grey limestone, chunky low-poly stylized fairytale dungeon asset, one tile only, plain flat background outside the tile, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, UI, multiple tiles, perspective, scenery
```

### `dungeon-crypt-floor-cracked.png` — broken variant
```
top-down view of a single square stone brick floor tile, badly cracked with a fault line running diagonally and small pieces missing, weathered grey, chunky low-poly stylized fairytale dungeon asset, one tile only, plain flat background outside the tile, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, UI, multiple tiles, perspective, scenery
```

---

## 4–8. Walls

Walls are 1 m wide × 2 m tall × 0.2 m thick segments that tile sideways
to form long walls. They go on the edges of cells. Three-quarter view for
generation so Meshy understands the front face.

### `dungeon-crypt-wall-straight.png` — straight wall segment
```
a single short straight section of mossy stone brick dungeon wall, about as wide as it is tall, weathered grey bricks with mortar lines and moss patches near the base, chunky low-poly stylized fairytale, one object only, three-quarter front view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, UI, multiple walls, scenery, corridor
```

### `dungeon-crypt-wall-corner-inner.png` — L-shaped inside corner
```
a single L-shaped inside-corner section of mossy stone brick dungeon wall meeting at 90 degrees, weathered grey bricks, chunky low-poly stylized fairytale, one object only, three-quarter view showing both faces, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, UI, multiple walls, scenery
```

### `dungeon-crypt-wall-corner-outer.png` — L-shaped outside corner (pillar-like edge)
```
a single outside-corner section of mossy stone brick dungeon wall — a vertical edge where two wall faces meet at 90 degrees pointing outward, weathered grey bricks, chunky low-poly stylized fairytale, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, UI, multiple walls, scenery
```

### `dungeon-crypt-archway.png` — open arched doorway
```
a single round-arched stone doorway, mossy grey brick frame with no door in it, opening you can walk through, chunky low-poly stylized fairytale dungeon, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, door slab, gate, UI, scenery
```

### `dungeon-crypt-door-wood.png` — heavy wooden door in a stone frame
```
a single heavy wooden dungeon door in a mossy stone arched frame, iron bands and a round iron handle, dark oak planks, closed, chunky low-poly stylized fairytale, one object only, front three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, opening, UI, scenery
```

---

## 9–10. Vertical + structural

### `dungeon-crypt-stairs.png` — short stone stairway
```
a single short flight of stone dungeon stairs, about five wide steps rising one metre over two metres, mossy weathered grey stone, chunky low-poly stylized fairytale, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, banister, railing, UI, scenery
```

### `dungeon-crypt-column.png` — standalone stone column
```
a single tall round stone column, weathered grey limestone with a simple square base and a square capital, faint moss near the base, chunky low-poly stylized fairytale dungeon, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, multiple columns, scenery
```

---

## 11–12. Light sources (point lights attached in code)

### `dungeon-crypt-brazier.png` — floor brazier
```
a single iron tripod brazier holding a shallow bowl with glowing orange flames and a few embers, chunky low-poly stylized fairytale dungeon prop, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look, warm flame glow --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, multiple braziers, smoke filling the frame, scenery
```

### `dungeon-crypt-torch-wall.png` — wall sconce torch
```
a single iron wall-sconce torch with a wrapped wooden handle and a small flame, mounted on a stone bracket, chunky low-poly stylized fairytale dungeon prop, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look, warm flame glow --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, wall behind filling frame, multiple torches, scenery
```

---

## 13–16. Furniture

### `dungeon-crypt-sarcophagus.png`
```
a single stone sarcophagus, rectangular about two metres long, weathered grey with carved leaf-and-vine motifs along the side and a slightly askew heavy stone lid, mossy patches, chunky low-poly stylized fairytale dungeon prop, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, skeleton inside, person, UI, multiple sarcophagi, scenery
```

### `dungeon-crypt-altar.png`
```
a single small stone altar, square pedestal about half a metre tall with simple carved runes on the front face and two melted-down candle stubs on top, mossy weathered grey, chunky low-poly stylized fairytale dungeon prop, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, glowing magical effects, UI, scenery
```

### `dungeon-crypt-chest.png` — wooden treasure chest
```
a single heavy wooden treasure chest, dark oak with iron bands and a brass lock, closed, slightly mossy at the base, chunky low-poly stylized fairytale dungeon prop, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, gold coins, open lid, UI, multiple chests, scenery
```

### `dungeon-crypt-bookshelf.png`
```
a single tall narrow wooden bookshelf, dark oak with three or four shelves, a handful of leather-bound books and a couple of jars, slightly rotten at the base with cobwebs, chunky low-poly stylized fairytale dungeon prop, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, multiple bookshelves, full library, scenery
```

---

## 17–20. Floor dressing / doodads

### `dungeon-crypt-rug.png` — frayed rug
```
a single frayed faded red dungeon rug, rectangular about two by three metres, simple geometric border pattern, dusty and worn at the edges, lying flat, chunky low-poly stylized fairytale, one object only, top-down view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 16:9 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, furniture, multiple rugs, scenery
```

### `dungeon-crypt-web.png` — cobweb cluster
```
a single cluster of dusty white cobwebs strung across a corner, chunky low-poly stylized fairytale dungeon doodad, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, spider, person, multiple webs, scenery
```

### `dungeon-crypt-bones.png` — small bone pile
```
a single small pile of weathered grey bones and a single intact skull on a stone floor, chunky low-poly stylized fairytale dungeon doodad, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, full skeleton, blood, UI, scenery
```

### `dungeon-crypt-pottery.png` — broken pottery shards
```
a single small pile of broken terracotta pottery shards, a few large fragments mixed with smaller chips, chunky low-poly stylized fairytale dungeon doodad, one object only, three-quarter view, plain flat neutral grey background, Wind Waker cel-shaded look --ar 1:1 --cref ../../dungeon-interior-1.png --cw 50 --no character, person, intact pot, multiple piles, scenery
```

---

## Shortcut for floor tiles

If Meshy struggles with "single flat top-down tile" (it usually wants
volume), the easier path for floors is to **skip Meshy** and use the
generated PNG **as a tileable texture** on a `THREE.PlaneGeometry`. Crop
the PNG to a clean 512×512 square, set `texture.wrapS/T = RepeatWrapping`,
and tile it across the dungeon floor in code. The dungeon parser handles
this — you can just point at the PNG, no GLB needed. Walls and props all
still go through full Meshy Image-to-3D.

---

## Layout file format (what the parser will read)

ASCII grid, one cell per character, same shape as `src/data/map.txt` but
with a dungeon-specific legend. Sketch:

```
WWWWWWWWWWWWWWWWWWWW
W..................W
W..C..........C....W
W..................W
W......B.......S...W
W..................W
W..C..........C....W
W........R.........W
W..................W
W.D..............A.W
WWWWWWWWWWWWWWWWWWWW
```

Legend (the parser maps each char → which GLB to spawn):

| Char | Meaning | GLB |
|---|---|---|
| `.` | floor | `dungeon_crypt_floor_brick_v1.glb` |
| `,` | mossy floor | `dungeon_crypt_floor_mossy_v1.glb` |
| `!` | cracked floor | `dungeon_crypt_floor_cracked_v1.glb` |
| `W` | wall (parser figures out straight/corner/which way to rotate) | wall pieces |
| `A` | archway | `dungeon_crypt_archway_v1.glb` |
| `D` | door | `dungeon_crypt_door_wood_v1.glb` |
| `>` `<` | stairs up / down | `dungeon_crypt_stairs_v1.glb` |
| `C` | column | `dungeon_crypt_column_v1.glb` |
| `B` | brazier (also spawns a PointLight) | `dungeon_crypt_brazier_v1.glb` |
| `t` | wall torch (also spawns a PointLight on the adjacent wall) | `dungeon_crypt_torch_wall_v1.glb` |
| `S` | sarcophagus | `dungeon_crypt_sarcophagus_v1.glb` |
| `a` | altar | `dungeon_crypt_altar_v1.glb` |
| `c` | chest | `dungeon_crypt_chest_v1.glb` |
| `b` | bookshelf | `dungeon_crypt_bookshelf_v1.glb` |
| `R` | rug | `dungeon_crypt_rug_v1.glb` |
| `w` | cobweb cluster | `dungeon_crypt_web_v1.glb` |
| `o` | bone pile | `dungeon_crypt_bones_v1.glb` |
| `p` | broken pottery | `dungeon_crypt_pottery_v1.glb` |
| `@` | player spawn | (marker, no mesh) |
| `g` | enemy spawn (generic) | (marker, no mesh) |

When the 20 GLBs are in `models/`, ping me — I'll write the parser
(`src/scene/dungeon.js`, ~150 lines, follows the `src/scene/world.js`
pattern) plus a top-down/iso camera + the brazier point lights, and a
tiny demo level file in `docs/dungeons/crypt_demo.txt`.

## After all 20 land

```
1. Generate the 20 PNGs in Midjourney (this folder)         ← you
2. Meshy Image-to-3D each → ~/Downloads/                    ← you
3. clean_ai_mesh.py --rig static on each → models/          ← can be scripted; I batch it
4. Write the dungeon parser + camera + lighting             ← me
5. Author a demo crypt layout file in docs/dungeons/         ← you (or me + you tweak)
6. Sandbox page: rig_test_dungeon.html to walk it           ← me
```

Future biomes (bramble warren, forge cellar, sunken hall) follow the
same template — copy this file, change the master `--cref`, swap the
per-piece descriptions, rename `crypt → <biome>`.
