// Tile baking + main render dispatch. y-sort entities; particles drawn last.
import { ctx, TILE, COLS, ROWS, VIEW_W, VIEW_H } from './canvas.js';
import { camera } from './camera.js';
import { baked } from './sprite.js';
import { renderParticles } from './particles.js';
import { PAL } from '../data/sprites.js';

// ---------- TILE BAKERS ----------
function makeTile(drawFn) {
  const c = document.createElement('canvas');
  c.width = TILE; c.height = TILE;
  const cx = c.getContext('2d');
  cx.imageSmoothingEnabled = false;
  drawFn(cx);
  return c;
}

function bakeGrass() {
  return makeTile(cx => {
    cx.fillStyle = PAL['3'];
    cx.fillRect(0, 0, TILE, TILE);
    cx.fillStyle = PAL['2'];
    for (let i = 0; i < 6; i++) cx.fillRect((i * 11) % TILE, (i * 17 + 3) % TILE, 1, 1);
    const tufts = [[4, 6], [12, 10], [22, 5], [27, 18], [9, 22], [18, 26], [3, 29]];
    for (const [tx, ty] of tufts) {
      cx.fillStyle = PAL['2'];
      cx.fillRect(tx, ty, 1, 2);
      cx.fillRect(tx + 1, ty - 1, 1, 2);
      cx.fillRect(tx + 2, ty, 1, 2);
      cx.fillStyle = PAL['4'];
      cx.fillRect(tx + 1, ty - 1, 1, 1);
    }
  });
}

function bakePath() {
  return makeTile(cx => {
    cx.fillStyle = PAL['7'];
    cx.fillRect(0, 0, TILE, TILE);
    cx.fillStyle = PAL['6'];
    cx.fillRect(5, 7, 2, 2);
    cx.fillRect(20, 12, 2, 1);
    cx.fillRect(11, 22, 1, 2);
    cx.fillRect(26, 24, 2, 2);
    cx.fillStyle = PAL['8'];
    cx.fillRect(15, 5, 2, 1);
    cx.fillRect(8, 17, 2, 1);
    cx.fillRect(23, 28, 2, 1);
  });
}

function bakeStone() {
  return makeTile(cx => {
    cx.fillStyle = '#3a3a44';
    cx.fillRect(0, 0, TILE, TILE);
    cx.fillStyle = PAL['B'];
    const bw = 14, bh = 7;
    for (let row = 0; row < 5; row++) {
      const offX = (row % 2) ? -bw / 2 : 0;
      const y = row * (bh + 1) - 2;
      for (let col = -1; col < 4; col++) {
        const x = col * (bw + 1) + offX;
        cx.fillRect(x, y, bw, bh);
      }
    }
    cx.fillStyle = PAL['C'];
    for (let row = 0; row < 5; row++) {
      const offX = (row % 2) ? -bw / 2 : 0;
      const y = row * (bh + 1) - 2;
      for (let col = -1; col < 4; col++) {
        const x = col * (bw + 1) + offX;
        cx.fillRect(x, y, bw, 1);
      }
    }
  });
}

function bakeFloor() {
  return makeTile(cx => {
    cx.fillStyle = '#7a5a35';
    cx.fillRect(0, 0, TILE, TILE);
    cx.fillStyle = '#5a3a1a';
    cx.fillRect(0, 10, TILE, 1);
    cx.fillRect(0, 21, TILE, 1);
    cx.fillStyle = '#9a7a55';
    cx.fillRect(4, 4, 2, 1);
    cx.fillRect(20, 14, 2, 1);
    cx.fillRect(10, 25, 2, 1);
  });
}

function bakeSand() {
  return makeTile(cx => {
    cx.fillStyle = PAL['8'];
    cx.fillRect(0, 0, TILE, TILE);
    cx.fillStyle = PAL['7'];
    for (let i = 0; i < 10; i++) cx.fillRect((i * 47) % TILE, (i * 113) % TILE, 2, 1);
    cx.fillStyle = '#e8d0a4';
    for (let i = 0; i < 6; i++) cx.fillRect((i * 31 + 5) % TILE, (i * 91 + 7) % TILE, 1, 1);
  });
}

function bakeWaterFrames() {
  const frames = [];
  for (let f = 0; f < 4; f++) {
    frames.push(makeTile(cx => {
      cx.fillStyle = PAL['9'];
      cx.fillRect(0, 0, TILE, TILE);
      cx.fillStyle = PAL['A'];
      const off = f * 4;
      cx.fillRect((4 + off) % TILE, 6, 8, 2);
      cx.fillRect((18 + off) % TILE, 14, 10, 2);
      cx.fillRect((6 - off + 32) % TILE, 22, 6, 2);
      cx.fillRect((20 + off) % TILE, 26, 8, 2);
      cx.fillStyle = PAL['H'];
      if (f === 0) cx.fillRect(10, 10, 1, 1);
      if (f === 1) cx.fillRect(22, 18, 1, 1);
      if (f === 2) cx.fillRect(6, 26, 1, 1);
      if (f === 3) cx.fillRect(26, 6, 1, 1);
    }));
  }
  return frames;
}

export const TILES = {
  grass: bakeGrass(),
  path: bakePath(),
  stone: bakeStone(),
  floor: bakeFloor(),
  sand: bakeSand(),
  water: bakeWaterFrames(),  // array of 4 frames
};

// ---------- DRAW HELPERS ----------
export function drawSprite(name, px, py, opts = {}) {
  const img = baked[name];
  if (!img) return;
  const offY = opts.bob || 0;
  if (opts.flash) {
    ctx.globalAlpha = 0.6;
    ctx.drawImage(img, px - 1, py + offY - 1);
    ctx.globalAlpha = 1;
  }
  ctx.drawImage(img, px, py + offY);
}

// ---------- MAIN RENDER ----------
export function render(world, drawables) {
  ctx.fillStyle = '#000';
  ctx.fillRect(0, 0, VIEW_W, VIEW_H);
  ctx.save();
  ctx.translate(-Math.floor(camera.x), -Math.floor(camera.y));

  const waterFrame = Math.floor(Date.now() / 280) % 4;
  const startX = Math.max(0, Math.floor(camera.x / TILE));
  const startY = Math.max(0, Math.floor(camera.y / TILE));
  const endX = Math.min(COLS, Math.ceil((camera.x + VIEW_W) / TILE) + 1);
  const endY = Math.min(ROWS, Math.ceil((camera.y + VIEW_H) / TILE) + 1);
  for (let y = startY; y < endY; y++) {
    for (let x = startX; x < endX; x++) {
      const k = world.tileGrid[y][x];
      const t = TILES[k];
      const img = Array.isArray(t) ? t[waterFrame] : t;
      ctx.drawImage(img, x * TILE, y * TILE);
    }
  }

  // shadows + entities
  drawables.sort((a, b) => a.y - b.y);
  for (const d of drawables) d.draw();

  renderParticles(ctx);
  ctx.restore();
}
