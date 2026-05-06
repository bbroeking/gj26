# Art Style Guide — Agent Sprite Forge

Rules and conventions for adding/editing pixel art in `game.js`. Every visual asset is *data*, baked at runtime — no PNG files. Stay consistent and the game looks cohesive.

---

## 1. Format

All sprites are **16 × 16 character grids** stored as JS arrays of 16 strings, each 16 chars long. Each character maps to a palette key in the `PAL` lookup; `.` and ` ` are transparent.

```js
SPR.example = [
  '................',    // 16 chars
  '......0FF0......',
  '.....0FFFF0.....',
  ...
];
```

Sprites are baked once at boot to a 32×32 offscreen canvas (2× scale) and `drawImage`-blitted each frame.

### Validation rule
A sprite must be **exactly 16 rows of 16 chars**. Run `node` validator after any edit:

```bash
node -e "const c=require('fs').readFileSync('game.js','utf8'); ..."
```

(The build script in `Bash` history checks all sprites at once.)

---

## 2. Palette

Single 25-key palette shared by all sprites and tile bakers. Keys are case-sensitive single chars.

| Key | Hex | Use |
|---|---|---|
| `0` | `#0a0a0a` | outline (use on every sprite) |
| `1` | `#1f1410` | dark-brown outline alt |
| `2` | `#2d4a1f` | dark grass / shadow |
| `3` | `#4a7a2f` | grass base |
| `4` | `#6ba03d` | grass highlight |
| `5` | `#5a3a1a` | dark wood / pants |
| `6` | `#8a5a2a` | wood / dirt |
| `7` | `#caa37b` | path |
| `8` | `#dec295` | path light |
| `9` | `#2d4a8a` | water deep |
| `A` | `#4a6cba` | water highlight |
| `B` | `#5e5e66` | dark stone |
| `C` | `#9a9aa2` | stone |
| `D` | `#c8c8d0` | light stone |
| `E` | `#fcd1a4` | skin |
| `F` | `#c0392b` | tunic red |
| `G` | `#ecc94b` | gold / hair |
| `H` | `#ffffff` | white |
| `I` | `#4ab07c` | goblin green |
| `J` | `#2c6e4d` | goblin dark |
| `K` | `#a3d27a` | goblin highlight |
| `L` | `#b07c9a` | robe pink |
| `M` | `#5e88c8` | mage blue |
| `N` | `#a5523a` | chicken brown |
| `O` | `#f25c4f` | chicken comb / fire |
| `P` | `#fff8c8` | log highlight |
| `Q` | `#d4af37` | gold accent |
| `R` | `#7cc14a` | leaf |
| `S` | `#3a8a5a` | leaf dark |
| `T` | `#5d2c14` | trunk dark |
| `U` | `#8a4a1c` | trunk |
| `V` | `#241408` | very dark / apron |
| `W` | `#80553a` | bark highlight |
| `X` | `#1c1c24` | cool outline alt |
| `Y` | `#f4f4f4` | bone white |

### Palette rules
- **Always outline** entity sprites with `0` — black outline reads cleanly on any tile.
- **Tiles** don't get outlines — they tile seamlessly.
- **Don't add new palette keys casually.** If a sprite needs a new color, propose it; we keep the palette ≤ 32 keys for cohesion.
- **Pair colors:** every form should use a "shade + base + highlight" trio. Examples already in palette:
  - Skin: (no shade) + `E`
  - Stone: `B` + `C` + `D`
  - Goblin: `J` + `I` + `K`
  - Trunk: `T` + `U` + `W`

---

## 3. Sprite anatomy

A typical entity sprite (player / NPC / goblin) divides into three vertical zones in 16×16:

```
Rows 0-1:   plume / hat tip / antennae       (optional, tall things)
Rows 2-7:   head + neck                      (~6 rows = "head zone")
Rows 8-12:  body / torso                     (~5 rows)
Rows 13-15: legs + feet                      (~3 rows)
```

Body width: typically 6-8 chars wide, with `0` outline column on each side. Most sprites span cols 4-11 (8 wide + 2 outline).

### Outline rules
1. Every body region has a 1-pixel `0` border.
2. Legs/feet split with a 2-char gap: `'.....55..55.....'` (5 dot pad, 2 leg, 2 gap, 2 leg, 5 dot pad).
3. Boots/feet use `0` (black) for grounded effect.

---

## 4. Rim lighting (automatic)

Sprites in the `RIM_SPRITES` set get an automatic 1-pixel white-22%-alpha highlight on their **upper-left** edges (light source = upper-left). This happens in `bakeSprite(grid, scale, rim=true)`.

To opt a sprite into rim lighting, add its key to the `RIM_SPRITES` set in `game.js`.

Currently rim-lit:
- All player directions
- Goblin, chicken
- All NPC sprites
- Tree, pine tree

**Don't rim-light**: tiles, fishing spots, sword icons (too small to read), inventory icons. Rim light is for "characters with mass."

---

## 5. Animation conventions

### 5.1 Bob (idle/walking shimmer)
The render loop adds a 1-pixel y-offset based on `bobT` (frame counter):

```js
const bob = entity.moving ? Math.floor(Math.sin(entity.bobT * 0.4) * 1) : 0;
drawSprite(name, x, y, { bob });
```

This makes static sprites feel alive without needing extra frames. Walking has more bob.

### 5.2 Hurt flash
On hit: `entity.hurtT = 12` (12 frames). During flash, sprite is drawn with `globalAlpha = 0.6` shifted -1px (white edge effect).

### 5.3 Attack swing FX
Drawn as a half-second white circle stroke at 8px radius, expanding from player position in their facing direction. Hand-coded, not sprite-based.

### 5.4 Tile animations
Animated tiles bake an array of frames; the render loop picks one based on `Date.now() / N % frames.length`:
- Water: 4 frames, 280 ms each
- Furnace ember: drawn procedurally each frame (sin-based alpha)
- Range ember: same
- Fishing-spot bubbles: drawn procedurally (sin-offset white pixels)

---

## 6. Tile bakers

Tiles are 32×32 canvases. They use programmatic drawing (`fillRect`, brick patterns, tufts), not char grids. Each baker is a function `() => Canvas`.

Pattern for adding a new tile:

```js
function bakeMyTile() {
  return makeTile(cx => {
    cx.fillStyle = PAL['3'];     // base color
    cx.fillRect(0, 0, TILE, TILE);
    // detail pass: tufts, pebbles, ripples...
    cx.fillStyle = PAL['4'];
    // place ~5-8 detail elements per tile
    // use small fixed positions (not random) for cohesion at scale
  });
}
```

### Tile rules
1. **No noise loops with `Math.random()`** — use deterministic positions or `srand(x, y)` so adjacent tiles look intentional, not chaotic.
2. **Edge consistency:** detail elements should be ≥ 2 px from tile edges, so two tiles tile seamlessly.
3. **Limit detail density:** 5-10 detail pixels per 32×32 tile. More = noisy.
4. **Use the palette.** No raw hex codes inside bakers — go through `PAL[key]`.

---

## 7. Entity render order

The y-sort pass (`drawables.sort((a,b) => a.y - b.y)`) ensures southern entities render in front. When adding a new entity:
- Use `y: entityWorldY * TILE + 24` as the sort key (the +24 puts the foot-line just below the entity).
- Tall entities (trees) need adjusted +24 to keep their canopy behind shorter entities in front of them.

---

## 8. Common pitfalls

- **Using a transparent key for outline.** Outline must be `0` (or `1`/`X` for warm/cool variants). `.` lets background show through.
- **Sprite drift left/right.** Asymmetric padding makes sprites appear offset on tile. Center-check by counting leading vs trailing dots per row.
- **Mixed widths.** Every row must be exactly 16 chars or `bakeSprite` produces broken art. Always validate.
- **Palette key collisions.** Don't reuse `T` (trunk) for a hat color in a new sprite — consistent meaning across sprites.
- **Forgetting to add to `RIM_SPRITES`.** New character sprites without rim look flatter than the rest.

---

## 9. Adding a new sprite — checklist

1. [ ] Write the 16-row, 16-char grid. Pick palette keys.
2. [ ] Append `SPR.my_sprite = [...]` near similar sprites (NPCs together, tiles together).
3. [ ] Run sprite validator: `node` script that walks every `SPR.X = [...]`.
4. [ ] If it's an entity (character / mob), add to `RIM_SPRITES`.
5. [ ] If interactive, add to `isBlocked`, click handler, render's drawable list.
6. [ ] If named, add to `ITEM_NAMES` / `ITEM_ICONS` (for inventory).
7. [ ] Test in browser — does it read at 1× scale? Does it y-sort correctly with neighbors?

---

## 10. Future improvements (logged, not built)

- **Walk cycle:** 2-frame leg alternation per direction. ~4 new sprites.
- **Tile transition tiles:** corner tiles for grass↔sand, grass↔path edges. ~8 tiles.
- **Goblin knockback flash:** white silhouette flash on hit (currently only alpha dim).
- **Character customization** via Pixelweaving — see GDD §6.
- **Higher-res mode:** 24×24 sprites if 16×16 reads too cramped on high-DPI screens.
- **Particle system:** for damage numbers, XP popups, level-up bursts.
