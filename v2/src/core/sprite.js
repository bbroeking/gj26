// Bake char-grid sprites at boot.
import { PAL, SPR, RIM_SPRITES } from '../data/sprites.js';

function bakeSprite(grid, scale = 2, rim = false) {
  const w = grid[0].length;
  const h = grid.length;
  const c = document.createElement('canvas');
  c.width = w * scale;
  c.height = h * scale;
  const cx = c.getContext('2d');
  cx.imageSmoothingEnabled = false;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const k = grid[y][x];
      const color = PAL[k];
      if (!color) continue;
      cx.fillStyle = color;
      cx.fillRect(x * scale, y * scale, scale, scale);
    }
  }
  if (rim) {
    cx.fillStyle = 'rgba(255,255,255,0.22)';
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const k = grid[y][x];
        if (!PAL[k] || k === '0') continue;
        const above = y > 0 ? grid[y - 1][x] : '.';
        const left = x > 0 ? grid[y][x - 1] : '.';
        const aboveDark = above === '0' || !PAL[above];
        const leftDark = left === '0' || !PAL[left];
        if (aboveDark) cx.fillRect(x * scale, y * scale, scale, 1);
        if (leftDark) cx.fillRect(x * scale, y * scale, 1, scale);
      }
    }
  }
  return c;
}

export const baked = {};
for (const k of Object.keys(SPR)) {
  baked[k] = bakeSprite(SPR[k], 2, RIM_SPRITES.has(k));
}
