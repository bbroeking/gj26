// Crypt-tile registry — maps procgen `decor.kind` strings (and the
// implicit floor / wall / chest cells) to the GLBs produced by spec 01.
// Pure data; src/scene/cryptAssets.js consumes this.

/** kind → { url, y, scale } for static GLB props placed on a floor cell. */
export const CRYPT_DECOR_MODELS = {
  altar:        { url: 'models/dungeon_crypt_altar_v1.glb',         y: 0, scale: 1.0 },
  bones:        { url: 'models/dungeon_crypt_bones_v1.glb',         y: 0, scale: 1.0 },
  bookshelf:    { url: 'models/dungeon_crypt_bookshelf_v1.glb',     y: 0, scale: 1.0 },
  brazier:      { url: 'models/dungeon_crypt_brazier_v1.glb',       y: 0, scale: 1.0 },
  column:       { url: 'models/dungeon_crypt_column_v1.glb',        y: 0, scale: 1.0 },
  pottery:      { url: 'models/dungeon_crypt_pottery_v1.glb',       y: 0, scale: 1.0 },
  rug:          { url: 'models/dungeon_crypt_rug_v1.glb',           y: 0.01, scale: 1.0 },
  sarcophagus:  { url: 'models/dungeon_crypt_sarcophagus_v1.glb',   y: 0, scale: 1.0 },
  stairs:       { url: 'models/dungeon_crypt_stairs_v1.glb',        y: 0, scale: 1.0 },
  torch_wall:   { url: 'models/dungeon_crypt_torch-wall_v1.glb',    y: 0, scale: 1.0 },
};

/** Wall variants. Orientation is picked at placement time from a 4-bit
 *  cardinal-neighbor bitmask (see cryptAssets.js → cryptWallVariant()). */
export const CRYPT_WALL_MODELS = {
  straight:     { url: 'models/dungeon_crypt_wall-straight_v1.glb' },
  cornerInner:  { url: 'models/dungeon_crypt_wall-corner-inner_v1.glb' },
  cornerOuter:  { url: 'models/dungeon_crypt_wall-corner-outer_v1.glb' },
};

/** Door uses door-wood-v2 (currently swapped in via the existing door
 *  override only; standard `layout.doors` rendering still uses the
 *  procedural arch for non-crypt scopes). */
export const CRYPT_DOOR_MODEL = {
  url: 'models/dungeon_crypt_door-wood_v1.glb',
};

/** Chest override — replaces the procedural wood/gold chest when
 *  layout.scope === 'crypt'. */
export const CRYPT_CHEST_MODEL = {
  url: 'models/dungeon_crypt_chest_v1.glb', y: 0, scale: 1.0,
};

/** Floor tile texture (no Meshy — PNG used as MeshToonMaterial.map on a
 *  PlaneGeometry per cell, matching the existing buildWoodFloorTile pattern). */
export const CRYPT_FLOOR_TEXTURE = 'docs/concept-art/dungeons/crypt/dungeon-crypt-floor-brick-v2.png';

/** Web — Meshy failed on the radial pattern (too thin to volumize).
 *  Rendered as a transparent PlaneGeometry billboard instead. */
export const CRYPT_WEB_TEXTURE = 'docs/concept-art/dungeons/crypt/dungeon-crypt-web-v2.png';

/** Decor kinds that emit a flickering warm point-light (brazier + torch). */
export const CRYPT_FLICKER_KINDS = new Set(['brazier', 'torch_wall']);

/** Weighted decor scatter for the crypt scope. generateDungeonLayout reads
 *  this when scope === 'crypt' to roll a per-tile `kind` instead of using
 *  the single-kind themeMap entry that other scopes use. */
export const CRYPT_DECOR_WEIGHTS = [
  ['bones',       18],
  ['pottery',     14],
  ['column',      12],
  ['sarcophagus', 10],
  ['bookshelf',   10],
  ['brazier',      8],
  ['torch_wall',   8],
  ['altar',        6],
  ['rug',          6],
  ['web',          8],
];

/** Roll a crypt decor kind by weight. */
export function pickCryptDecorKind(rng = Math.random) {
  const total = CRYPT_DECOR_WEIGHTS.reduce((s, [, w]) => s + w, 0);
  let r = rng() * total;
  for (const [k, w] of CRYPT_DECOR_WEIGHTS) {
    r -= w;
    if (r <= 0) return k;
  }
  return CRYPT_DECOR_WEIGHTS[0][0];
}
