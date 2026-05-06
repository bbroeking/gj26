# Asset Protocol — Lumbridge v2

Source of truth for sprite/tile dimensions, palette, and the sprite list. `data/sprites.js` is the implementation; this file is the spec.

## Palette (32 keys)

Single shared palette, single character per key. `.` and ` ` are transparent.

```
0  #0a0a0a  outline (default — use on every entity)
1  #1f1410  warm-dark outline alt
2  #2d4a1f  dark grass
3  #4a7a2f  grass base
4  #6ba03d  grass highlight
5  #5a3a1a  dark wood / pants
6  #8a5a2a  wood / dirt
7  #caa37b  path
8  #dec295  path light
9  #2d4a8a  water
A  #4a6cba  water highlight
B  #5e5e66  dark stone
C  #9a9aa2  stone
D  #c8c8d0  light stone
E  #fcd1a4  skin
F  #c0392b  red (tunic)
G  #ecc94b  gold / hair
H  #ffffff  white
I  #4ab07c  goblin / cow stains green
J  #2c6e4d  dark green
K  #a3d27a  light green
L  #b07c9a  pink robe
M  #5e88c8  mage blue
N  #a5523a  cow brown
O  #f25c4f  fire / blood
P  #fff8c8  highlight cream
Q  #d4af37  gold accent
R  #7cc14a  leaf
S  #3a8a5a  leaf dark
T  #5d2c14  trunk dark
U  #8a4a1c  trunk
V  #241408  very dark / apron
W  #80553a  bark highlight
X  #1c1c24  cool outline alt
Y  #f4f4f4  bone white
```

## Sprite sizing rules

- **Standard entity:** 16×16 char grid → baked at 2× = 32×32 px tile
- **Tile:** 32×32 px, drawn programmatically (no char grid)
- **Inventory icons:** emoji glyphs from `ITEM_ICONS`, no sprite
- **Particles:** drawn directly each frame (no sprite cache)

## Rim lighting

Entity sprites listed in `RIM_SPRITES` (in `data/sprites.js`) get an automatic 22% white pixel on their upper-left edges, giving a "lit" feel. **Don't** rim-light tiles or one-pixel UI glyphs.

## Sprite list (v2 MVP)

| Key | Purpose | Direction |
|---|---|---|
| `player_down` / `_up` / `_left` / `_right` | player idle | 4 dirs |
| `player_*_walk` | player walk frame 2 | 4 dirs |
| `cow` | enemy mob | omni |
| `cook` | NPC (chef hat, white robe) | omni |
| `fire` | cooking range tile-overlay | static |
| `tree` | obstacle | static |

Total: 4 + 4 + 1 + 1 + 1 + 1 = **12 sprites** (small set; v1 had 27).

## Tilemap legend (`data/map.txt`)

```
W  water (blocks)        T  tree (blocks)
G  grass                  N  Cook NPC spawn (blocks)
P  path                   X  player spawn
S  stone (blocks)         f  fire (blocks, interactable)
F  wood floor             c  cow spawn
_  sand
```

Rules:
1. Map is 40 cols × 28 rows; each row exactly 40 chars
2. World wraps to camera (clamped, not toroidal)
3. Spawn markers (X, N, c) become entities; their tile under is grass

## Adding a new sprite

1. Decide if it's an **entity** (use char grid) or **tile/particle** (use code)
2. Write the 16-row, 16-col char grid in `data/sprites.js` under `SPR.<name>`
3. Validate: every row exactly 16 chars, total exactly 16 rows
4. If it's a character/mob, append the key to `RIM_SPRITES`
5. If it has a render order concern (tall, like trees), set `y_sort_offset` in the consumer
