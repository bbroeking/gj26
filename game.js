'use strict';

// =============================================================
// AGENT SPRITE FORGE — LEVEL 1: LUMBRIDGE PLAINS
// A self-contained top-down RPG demo. All sprites & tiles are
// procedurally drawn from char-grid pixel art at runtime.
// =============================================================

// ---------- canvas ----------
const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');
ctx.imageSmoothingEnabled = false;

const TILE = 32;
const COLS = 32;             // world width in tiles
const ROWS = 24;             // world height in tiles
const WORLD_W = COLS * TILE; // 1024
const WORLD_H = ROWS * TILE; // 768
const VIEW_W = canvas.width; // 800
const VIEW_H = canvas.height;// 576
// retained for backwards-compat in some calls (now world dims)
const VW = WORLD_W;
const VH = WORLD_H;

const camera = { x: 0, y: 0 };
function updateCamera() {
  const tx = player.px + 16 - VIEW_W / 2;
  const ty = player.py + 16 - VIEW_H / 2;
  camera.x = Math.max(0, Math.min(WORLD_W - VIEW_W, tx));
  camera.y = Math.max(0, Math.min(WORLD_H - VIEW_H, ty));
}

// ---------- palette ----------
const PAL = {
  '.': null, ' ': null,
  '0': '#0a0a0a',  // black outline
  '1': '#1f1410',  // dark brown outline
  '2': '#2d4a1f',  // dark grass
  '3': '#4a7a2f',  // grass
  '4': '#6ba03d',  // light grass
  '5': '#5a3a1a',  // dark wood / pants
  '6': '#8a5a2a',  // wood / dirt
  '7': '#caa37b',  // path
  '8': '#dec295',  // path light
  '9': '#2d4a8a',  // water
  'A': '#4a6cba',  // water hl
  'B': '#5e5e66',  // dark stone
  'C': '#9a9aa2',  // stone
  'D': '#c8c8d0',  // light stone
  'E': '#fcd1a4',  // skin
  'F': '#c0392b',  // tunic red
  'G': '#ecc94b',  // gold/hair
  'H': '#ffffff',  // white
  'I': '#4ab07c',  // goblin green
  'J': '#2c6e4d',  // goblin dark
  'K': '#a3d27a',  // goblin light
  'L': '#b07c9a',  // robe pink
  'M': '#5e88c8',  // mage blue
  'N': '#a5523a',  // chicken brown
  'O': '#f25c4f',  // chicken comb
  'P': '#fff8c8',  // log highlight
  'Q': '#d4af37',  // gold
  'R': '#7cc14a',  // leaf
  'S': '#3a8a5a',  // leaf dark
  'T': '#5d2c14',  // tree trunk dark
  'U': '#8a4a1c',  // tree trunk
  'V': '#241408',  // very dark
  'W': '#80553a',  // bark hl
  'X': '#1c1c24',  // outline cool
  'Y': '#f4f4f4',  // bone white
};

// ---------- sprite data (16x16 char grids) ----------
// Each row is 16 chars; '.' / ' ' = transparent.
const SPR = {};

SPR.player_down = [
  '................',
  '......0FF0......',
  '.....0FFFF0.....',
  '....0BCCCCB0....',
  '....0CCCCCC0....',
  '....0EEEEEE0....',
  '....0E0EE0E0....',
  '.....0EEEE0.....',
  '....0FFFFFF0....',
  '...0FFFFFFFF0...',
  '...0FGGGGGGF0...',
  '...0FFFFFFFF0...',
  '....0F5555F0....',
  '.....55..55.....',
  '.....55..55.....',
  '.....00..00.....',
];

SPR.player_up = [
  '................',
  '......0FF0......',
  '.....0FFFF0.....',
  '....0BCCCCB0....',
  '....0CCCCCC0....',
  '....0CCCCCC0....',
  '.....0CCCC0.....',
  '....0FFFFFF0....',
  '...0FFFFFFFF0...',
  '...0FGGGGGGF0...',
  '...0FFFFFFFF0...',
  '....0F5555F0....',
  '.....55..55.....',
  '.....55..55.....',
  '.....00..00.....',
  '................',
];

SPR.player_left = [
  '................',
  '......0FF0......',
  '.....0FFFF0.....',
  '....0BCCCCB0....',
  '....0CCCCCC0....',
  '....0EEEEEE0....',
  '....0EE0EE00....',
  '.....0EEEE0.....',
  '....0FFFFFF0....',
  '...0FFFFFFF0....',
  '...0FGGGGGF0....',
  '...0FFFFFFF0....',
  '....0F555F0.....',
  '.....55.55......',
  '.....55.55......',
  '.....00.00......',
];

SPR.player_right = [
  '................',
  '......0FF0......',
  '.....0FFFF0.....',
  '....0BCCCCB0....',
  '....0CCCCCC0....',
  '....0EEEEEE0....',
  '....00EE0EE0....',
  '.....0EEEE0.....',
  '....0FFFFFF0....',
  '....0FFFFFFF0...',
  '....0FGGGGGF0...',
  '....0FFFFFFF0...',
  '.....0F555F0....',
  '......55.55.....',
  '......55.55.....',
  '......00.00.....',
];

// Walk-cycle alternates: legs spread + 1px body shift = "step" pose
SPR.player_down_walk = [
  '................',
  '......0FF0......',
  '.....0FFFF0.....',
  '....0BCCCCB0....',
  '....0CCCCCC0....',
  '....0EEEEEE0....',
  '....0E0EE0E0....',
  '.....0EEEE0.....',
  '....0FFFFFF0....',
  '...0FFFFFFFF0...',
  '...0FGGGGGGF0...',
  '...0FFFFFFFF0...',
  '....0F5555F0....',
  '....55....55....',
  '....55....55....',
  '....00....00....',
];

SPR.player_up_walk = [
  '................',
  '......0FF0......',
  '.....0FFFF0.....',
  '....0BCCCCB0....',
  '....0CCCCCC0....',
  '....0CCCCCC0....',
  '.....0CCCC0.....',
  '....0FFFFFF0....',
  '...0FFFFFFFF0...',
  '...0FGGGGGGF0...',
  '...0FFFFFFFF0...',
  '....0F5555F0....',
  '....55....55....',
  '....55....55....',
  '....00....00....',
  '................',
];

SPR.player_left_walk = [
  '................',
  '......0FF0......',
  '.....0FFFF0.....',
  '....0BCCCCB0....',
  '....0CCCCCC0....',
  '....0EEEEEE0....',
  '....0EE0EE00....',
  '.....0EEEE0.....',
  '....0FFFFFF0....',
  '...0FFFFFFF0....',
  '...0FGGGGGF0....',
  '...0FFFFFFF0....',
  '....0F555F0.....',
  '....55..55......',
  '....55..55......',
  '....00..00......',
];

SPR.player_right_walk = [
  '................',
  '......0FF0......',
  '.....0FFFF0.....',
  '....0BCCCCB0....',
  '....0CCCCCC0....',
  '....0EEEEEE0....',
  '....00EE0EE0....',
  '.....0EEEE0.....',
  '....0FFFFFF0....',
  '....0FFFFFFF0...',
  '....0FGGGGGF0...',
  '....0FFFFFFF0...',
  '.....0F555F0....',
  '......55..55....',
  '......55..55....',
  '......00..00....',
];

// Boss goblin — horns, white menacing eyes, fangs, same body proportions
SPR.goblin_boss = [
  '...0.....0......',
  '..0J0...0J0.....',
  '...JJ...JJ......',
  '....0II0II0.....',
  '....0IIIIII0....',
  '....0IKKKKI0....',
  '....0H0II0H0....',
  '.....0IIII0.....',
  '.....0HH0H0.....',
  '....0JJJJJJ0....',
  '...0JJIIIIJJ0...',
  '...0JJJJJJJJ0...',
  '...0JJJJJJJJ0...',
  '....0JJJJJJ0....',
  '.....055055.....',
  '.....000.000....',
];

// Goblin v2 — pointed ears, fangs, hunched
SPR.goblin = [
  '................',
  '....00...00.....',
  '....0II0II0.....',
  '....0IIIIII0....',
  '....0IKKKKI0....',
  '....0I0II0I0....',
  '.....0IIII0.....',
  '.....0HH0H0.....',
  '....0JJJJJJ0....',
  '...0JJIIIIJJ0...',
  '...0JJJJJJJJ0...',
  '...0JJJJJJJJ0...',
  '....0JJJJJJ0....',
  '.....055055.....',
  '.....055055.....',
  '.....000.000....',
];

// Wizard Aric v2 — pointed hat with gold star, white beard, blue+pink robe
SPR.npc = [
  '.......00.......',
  '......0MQ0......',
  '.....0MMMM0.....',
  '....0MMMMMM0....',
  '....0MMGGMM0....',
  '...0MMMMMMMM0...',
  '....0EEEEEE0....',
  '....0E0EE0E0....',
  '....0EHHHHE0....',
  '...0HHHHHHHH0...',
  '...0LLLLLLLL0...',
  '...0LLMMMMLL0...',
  '...0LLMQQMLL0...',
  '...0LLLLLLLL0...',
  '....0LLLLLL0....',
  '.....000000.....',
];

// Brawl Master — bulky red warrior
SPR.npc_warrior = [
  '................',
  '......0FF0......',
  '.....0FFFF0.....',
  '....0BCCCCB0....',
  '....0CCCCCC0....',
  '....0E0CC0E0....',
  '.....0EEEE0.....',
  '....0FFFFFF0....',
  '..0FFFFFFFFFF0..',
  '..0FFFFFFFFFF0..',
  '...0FFFFFFFF0...',
  '....0F5555F0....',
  '....055..550....',
  '....055..550....',
  '....000..000....',
  '................',
];

// Smith — bald, brown beard, dark apron
SPR.npc_smith = [
  '................',
  '................',
  '......0EE0......',
  '.....0EEEE0.....',
  '....0EEEEEE0....',
  '....0E0EE0E0....',
  '....0E5555E0....',
  '.....0EEEE0.....',
  '....0VVVVVV0....',
  '...0VVVVVVVV0...',
  '...0VFFFFFFV0...',
  '...0VVVVVVVV0...',
  '....0VVVVVV0....',
  '.....55..55.....',
  '.....00..00.....',
  '................',
];

// Chef — tall white hat, white robe, red apron stripe
SPR.npc_cook = [
  '.......00.......',
  '......0HH0......',
  '......0HH0......',
  '.....0HHHH0.....',
  '....0HHHHHH0....',
  '....0EEEEEE0....',
  '....0E0EE0E0....',
  '.....0EEEE0.....',
  '....0HHHHHH0....',
  '...0HHHHHHHH0...',
  '...0HHFFFFHH0...',
  '...0HHHHHHHH0...',
  '....0HHHHHH0....',
  '.....55..55.....',
  '.....00..00.....',
  '................',
];

// Cooking range (fire under stones)
SPR.range = [
  '................',
  '................',
  '................',
  '................',
  '.......00.......',
  '......0VG0......',
  '.....0OGOO0.....',
  '....0BBBBBB0....',
  '....0UUUWWU0....',
  '....0OFGGFO0....',
  '....0OGGOFO0....',
  '.....0OFFO0.....',
  '.....0BBBB0.....',
  '....0BBBBBB0....',
  '....000000000...',
  '................',
];

// Chicken v2 — proper bird shape with comb, beak, body, legs
SPR.chicken = [
  '................',
  '................',
  '......0OO0......',
  '.....0OOOO0.....',
  '....0HHHHHH0....',
  '....0H00HH0.....',
  '....0HHHOOH.....',
  '....0HHHHHH0....',
  '...0HHHHHHHH0...',
  '..0HHHHHHHHHH0..',
  '..0HHNNNNNNHH0..',
  '...0HHHHHHHH0...',
  '....0HHHHHH0....',
  '......G..G......',
  '.....G....G.....',
  '.....GG..GG.....',
];

// Tree (canopy + trunk, fills 32x32 spread across rows)
SPR.tree = [
  '......0000......',
  '....00RRRR00....',
  '...0RRSRSRR0....',
  '..0RRSRRRSRR0...',
  '..0RSRRRSRRSR0..',
  '.0RRSRSRRRSRRR0.',
  '.0RRRSRRSRSRRR0.',
  '.0SRRSRRRSRRRS0.',
  '..0RSRSRSRSRR0..',
  '...0RRRSRRSR0...',
  '....0RRSRRR0....',
  '......0UU0......',
  '......0UWU0.....',
  '......0UWU0.....',
  '......0UUU0.....',
  '....000000000...',
];

// Pine tree (taller, dark, conical)
SPR.tree_pine = [
  '.......00.......',
  '......0SS0......',
  '.....0SSRS0.....',
  '....0SRSSRS0....',
  '....0SSRSSR0....',
  '...0SRSRSRSS0...',
  '...0SSRSSRRS0...',
  '..0SRSSRSRSRS0..',
  '..0SSRSRSSRRS0..',
  '..0SRSSRRSRSS0..',
  '...0SRSSRSSR0...',
  '....0SSRSSR0....',
  '......0UU0......',
  '......0UWU0.....',
  '......0UUU0.....',
  '....000000000...',
];

SPR.stump = [
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '......0000......',
  '.....0UWUU0.....',
  '.....0UUWU0.....',
  '.....0UUUU0.....',
  '....000000000...',
];

SPR.log = [
  '................',
  '................',
  '................',
  '................',
  '....0000000.....',
  '...0UUWUWUW0....',
  '...0UWWUWWU0....',
  '...0UUWUUWU0....',
  '....0000000.....',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
];

// Rocks (copper / tin / iron use same shape, different accent)
SPR.rock_copper = [
  '................',
  '................',
  '................',
  '................',
  '......0000......',
  '.....0BBBB0.....',
  '....0BC66CB0....',
  '....0C66CC60....',
  '....0BCCC6CB0...',
  '....0C6CCCC6....',
  '....0BC66CB0....',
  '.....0BCCB0.....',
  '......0000......',
  '................',
  '................',
  '................',
];

SPR.rock_tin = [
  '................',
  '................',
  '................',
  '................',
  '......0000......',
  '.....0BBBB0.....',
  '....0BCDDCB0....',
  '....0CDDCCD0....',
  '....0BCCCDCB0...',
  '....0CDCCCCD....',
  '....0BCDDCB0....',
  '.....0BCCB0.....',
  '......0000......',
  '................',
  '................',
  '................',
];

SPR.rock_iron = [
  '................',
  '................',
  '................',
  '................',
  '......0000......',
  '.....0VVBV0.....',
  '....0VBVVBV0....',
  '....0BVVBBVV....',
  '....0VBBBVBV0...',
  '....0BVBBBBV....',
  '....0VBVVBV0....',
  '.....0BVBV0.....',
  '......0000......',
  '................',
  '................',
  '................',
];

SPR.rock_depleted = [
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '................',
  '......0000......',
  '.....0BCCB0.....',
  '....0BCBBCB0....',
  '....000000000...',
  '................',
];

// Furnace (chimney + glowing core)
SPR.furnace = [
  '......0000......',
  '.....0BCCB0.....',
  '.....0BCCB0.....',
  '.....0BCCB0.....',
  '....0BBBBBB0....',
  '...0BCCCCCCB0...',
  '...0BC0000CB0...',
  '...0BC0OO0CB0...',
  '...0BC0GG0CB0...',
  '...0BC0OO0CB0...',
  '...0BC0000CB0...',
  '...0BCCCCCCB0...',
  '...0BBBBBBBB0...',
  '....0BBBBBB0....',
  '................',
  '................',
];

// Anvil
SPR.anvil = [
  '................',
  '................',
  '................',
  '................',
  '....00000000....',
  '...0BBBBBBBB0...',
  '...0BCCCCCCB0...',
  '..0BBBBBBBBBB0..',
  '..0BCCCCCCCCB0..',
  '...0BBBBBBBB0...',
  '......0BB0......',
  '......0BB0......',
  '.....0BBBB0.....',
  '....0BBBBBB0....',
  '....00000000....',
  '................',
];

// Sword icon for inventory
SPR.sword = [
  '................',
  '................',
  '...........0H0..',
  '..........0HH0..',
  '.........0HH0...',
  '........0HH0....',
  '.......0HH0.....',
  '......0HH0......',
  '.....0HH0.......',
  '....0HH0........',
  '...0HH0G........',
  '..0GG0GG0.......',
  '...0GG00........',
  '....0G0.........',
  '................',
  '................',
];

// =============================================================
// SPRITE BAKING
// =============================================================
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
  // Rim light: faint white strip on the upper-left edge of each body pixel
  // touching outline / transparent. Light source = upper-left.
  if (rim) {
    cx.fillStyle = 'rgba(255,255,255,0.22)';
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const k = grid[y][x];
        if (!PAL[k] || k === '0') continue; // skip transparent and outline
        const above = y > 0 ? grid[y - 1][x] : '.';
        const left  = x > 0 ? grid[y][x - 1] : '.';
        const aboveDark = (above === '0' || !PAL[above]);
        const leftDark  = (left === '0' || !PAL[left]);
        if (aboveDark) cx.fillRect(x * scale, y * scale, scale, 1);
        if (leftDark)  cx.fillRect(x * scale, y * scale, 1, scale);
      }
    }
  }
  return c;
}

// Sprites that should receive automatic rim-lighting
const RIM_SPRITES = new Set([
  'player_down', 'player_up', 'player_left', 'player_right',
  'player_down_walk', 'player_up_walk', 'player_left_walk', 'player_right_walk',
  'goblin', 'goblin_boss', 'chicken',
  'npc', 'npc_warrior', 'npc_smith', 'npc_cook',
  'tree', 'tree_pine',
]);
const baked = {};
for (const k of Object.keys(SPR)) baked[k] = bakeSprite(SPR[k], 2, RIM_SPRITES.has(k));

// =============================================================
// TILE BAKING (procedural)
// =============================================================
function makeTile(drawFn) {
  const c = document.createElement('canvas');
  c.width = TILE; c.height = TILE;
  const cx = c.getContext('2d');
  cx.imageSmoothingEnabled = false;
  drawFn(cx);
  return c;
}

// stable pseudo-random per-tile based on coords
function srand(x, y, salt = 0) {
  let h = (x * 374761393 + y * 668265263 + salt * 2147483647) | 0;
  h = (h ^ (h >> 13)) * 1274126177;
  return ((h ^ (h >> 16)) >>> 0) / 4294967295;
}

// Grass: pixel tufts on cohesive base instead of random dots
function bakeGrass() {
  return makeTile(cx => {
    cx.fillStyle = PAL['3'];
    cx.fillRect(0, 0, TILE, TILE);
    // dark base flecks (subtle)
    cx.fillStyle = PAL['2'];
    for (let i = 0; i < 6; i++) {
      cx.fillRect(((i * 11) % TILE), ((i * 17 + 3) % TILE), 1, 1);
    }
    // grass tufts: 3-pixel inverted-V shapes
    const tufts = [
      [4, 6], [12, 10], [22, 5], [27, 18],
      [9, 22], [18, 26], [3, 29],
    ];
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
    // pebbles
    cx.fillRect(5, 7, 2, 2);
    cx.fillRect(20, 12, 2, 1);
    cx.fillRect(11, 22, 1, 2);
    cx.fillRect(26, 24, 2, 2);
    cx.fillRect(4, 27, 1, 1);
    cx.fillStyle = PAL['8'];
    cx.fillRect(15, 5, 2, 1);
    cx.fillRect(8, 17, 2, 1);
    cx.fillRect(23, 28, 2, 1);
  });
}

function bakeStone() {
  return makeTile(cx => {
    // mortar
    cx.fillStyle = '#3a3a44';
    cx.fillRect(0, 0, TILE, TILE);
    // running-bond bricks
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
    // highlight on top of each brick
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
    cx.fillStyle = '#7a5a35';  // warm wood floor
    cx.fillRect(0, 0, TILE, TILE);
    // plank lines
    cx.fillStyle = '#5a3a1a';
    cx.fillRect(0, 10, TILE, 1);
    cx.fillRect(0, 21, TILE, 1);
    // grain dots
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
    for (let i = 0; i < 10; i++) {
      cx.fillRect(((i * 47) % TILE), ((i * 113) % TILE), 2, 1);
    }
    cx.fillStyle = '#e8d0a4';
    for (let i = 0; i < 6; i++) {
      cx.fillRect(((i * 31 + 5) % TILE), ((i * 91 + 7) % TILE), 1, 1);
    }
  });
}

// Animated water: bake 4 phase-shifted frames
function bakeWaterFrames() {
  const frames = [];
  for (let f = 0; f < 4; f++) {
    frames.push(makeTile(cx => {
      cx.fillStyle = PAL['9'];
      cx.fillRect(0, 0, TILE, TILE);
      cx.fillStyle = PAL['A'];
      // wave stripes that drift sideways with frame
      const off = f * 4;
      cx.fillRect((4 + off) % TILE, 6, 8, 2);
      cx.fillRect((18 + off) % TILE, 14, 10, 2);
      cx.fillRect((6 - off + 32) % TILE, 22, 6, 2);
      cx.fillRect((20 + off) % TILE, 26, 8, 2);
      // foam dots that twinkle
      cx.fillStyle = PAL['H'];
      if (f === 0) cx.fillRect(10, 10, 1, 1);
      if (f === 1) cx.fillRect(22, 18, 1, 1);
      if (f === 2) cx.fillRect(6, 26, 1, 1);
      if (f === 3) cx.fillRect(26, 6, 1, 1);
    }));
  }
  return frames;
}

const TILES = {
  grass: bakeGrass(),
  path: bakePath(),
  water: bakeWaterFrames(), // array of 4
  stone: bakeStone(),
  floor: bakeFloor(),
  sand: bakeSand(),
};

// =============================================================
// WORLD MAP
// =============================================================
// G grass, P path, W water, S stone wall, F castle floor, _ sand
// T tree (entity slot, walks as grass under), N npc spawn (grass)
// X player spawn (grass)
// Tutorial Island map. NPCs on stations, mining SW, fishing+cooking S.
// Legend: W=water S=stoneWall F=castleFloor P=path G=grass _=sand
//         T=tree N=Aric(wizard) B=Brawler M=Smith C=Chef X=playerSpawn
//         u=furnace v=anvil k=cookingRange r=copperRock t=tinRock i=ironRock
//         f=fishingSpot (water tile) e=bossSpawnMarker
const MAP = [
  'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',
  'WGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGW',
  'WGGSSSSSSSGGGGGGGTGTGTGTGTGGGGGW',
  'WGGSFuFFFSGGGGGGGGTGTGTGTGGGGGGW',
  'WGGSFFFFvSGGGGGGGTGTGTGTGTGGGGGW',
  'WGGSFFFFFSGGGGGGGGGGGGGGGGGGGGGW',
  'WGGSSSFSSSGGGGGGGGGGGGGGGGGGGGGW',
  'WGGGGGFGGGMGGGGGGGGGGGGGGGGGGGGW',
  'WGGGGGFPPPPPPPPPPPPPPGGGGGGGGGGW',
  'WGGGNGGGGGGGGGGGGGGPGGGGGGGGGGGW',
  'WGGGGGGGGGGGGGGGGGGPGGGGGGGGGGGW',
  'WGGGGGeXGGGGGGGBGGGPGGGGGGGGGGGW',
  'WGGGGGGGGGGGGGGGGGGPGGGGGGGGGGGW',
  'WGGGGGGGGGGGGGGGGGGPGGGGGGGGGGGW',
  'WGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGW',
  'WGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGW',
  'W_GGGGGGGGGGGGGGGGGGGGGGGGGGGGGW',
  'W_GrtGGGGGGGGGGGGGGGGGGGGGGGGGGW',
  'W__rtiGGGGGGGGGGGGGGGGGGGGGGGGGW',
  'W_GGGGGGGGGGGGGGGGGGGGGGGGGGGGGW',
  'W___GGGGGGGGGGCkGGGGGGGGGGGGGGGW',
  'W___GGGGGGGGGGGGGGGGGGGGGGGGGGGW',
  'WWWWWWWWWWWWWfWfWWWWWWWWWWWWWWWW',
  'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',
];

// Build tile layer + walkability + interactables from map
const tileGrid = []; // base tile name per cell
const blocked = []; // walk-blocked
let spawnX = 12, spawnY = 11;

const treeList = [];
const rockList = [];   // {x, y, ore: 'copper'|'tin'|'iron', depleted, regrow}
let furnacePos = null;
let anvilPos = null;
let rangePos = null;     // cooking range tile
let bossSpawn = null;    // {x, y} where boss appears for final test

const NPC_DEFS = {
  aric:    { sprite: 'npc',         name: 'Wizard Aric' },
  brawler: { sprite: 'npc_warrior', name: 'Brawl Master' },
  smith:   { sprite: 'npc_smith',   name: 'Smith' },
  chef:    { sprite: 'npc_cook',    name: 'Chef Mira' },
};
const npcs = [];        // [{x, y, role}]
const fishingSpots = []; // [{x, y, depleted, regrow}]

for (let y = 0; y < ROWS; y++) {
  tileGrid.push([]);
  blocked.push([]);
  for (let x = 0; x < COLS; x++) {
    const ch = MAP[y][x];
    let tile = 'grass';
    let walk = true;
    switch (ch) {
      case 'W': tile = 'water'; walk = false; break;
      case 'P': tile = 'path'; break;
      case 'S': tile = 'stone'; walk = false; break;
      case 'F': tile = 'floor'; break;
      case '_': tile = 'sand'; break;
      case 'T':
        tile = 'grass';
        walk = false;
        treeList.push({
          x, y, chopped: 0, regrow: 0,
          kind: srand(x, y, 7) > 0.55 ? 'pine' : 'oak',
        });
        break;
      case 'r':
        tile = 'sand'; walk = false;
        rockList.push({ x, y, ore: 'copper', depleted: 0, regrow: 0, swings: 0 });
        break;
      case 't':
        tile = 'sand'; walk = false;
        rockList.push({ x, y, ore: 'tin', depleted: 0, regrow: 0, swings: 0 });
        break;
      case 'i':
        tile = 'sand'; walk = false;
        rockList.push({ x, y, ore: 'iron', depleted: 0, regrow: 0, swings: 0 });
        break;
      case 'u':
        tile = 'floor'; walk = false;
        furnacePos = { x, y };
        break;
      case 'v':
        tile = 'floor'; walk = false;
        anvilPos = { x, y };
        break;
      case 'k':
        tile = 'grass'; walk = false;
        rangePos = { x, y };
        break;
      case 'f':
        tile = 'water'; walk = false;
        fishingSpots.push({ x, y, depleted: 0, regrow: 0 });
        break;
      case 'N': npcs.push({ x, y, role: 'aric' }); break;
      case 'B': npcs.push({ x, y, role: 'brawler' }); break;
      case 'M': npcs.push({ x, y, role: 'smith' }); break;
      case 'C': npcs.push({ x, y, role: 'chef' }); break;
      case 'e': bossSpawn = { x, y }; break; // marker — does not block, no entity until spawned
      case 'X': spawnX = x; spawnY = y; break;
    }
    tileGrid[y].push(tile);
    blocked[y].push(!walk);
  }
}

// =============================================================
// ENTITIES
// =============================================================
const player = {
  x: spawnX, y: spawnY,        // tile coords
  px: spawnX * TILE, py: spawnY * TILE, // pixel coords
  dir: 'down',
  moving: false,
  moveT: 0,
  hp: 10, hpMax: 10,
  atkLv: 1, atkXp: 0,
  wcLv: 1, wcXp: 0,
  miningLv: 1, miningXp: 0,
  smeltLv: 1, smeltXp: 0,
  smithLv: 1, smithXp: 0,
  fishLv: 1, fishXp: 0,
  cookLv: 1, cookXp: 0,
  equippedSword: null,         // null | 'bronze_sword' | 'iron_sword'
  inv: [],                     // {type, qty}
  attackCd: 0,
  hurtT: 0,
  bobT: 0,
};

// Equipment damage bonuses
const SWORD_BONUS = { bronze_sword: 1, iron_sword: 2 };
const SWORD_NAME = { bronze_sword: 'Bronze Sword', iron_sword: 'Iron Sword' };

const goblins = [
  spawnGoblin(20, 10),
  spawnGoblin(22, 14),
];

// =============================================================
// PARTICLES — damage numbers, dust puffs, XP popups
// =============================================================
const particles = [];

function spawnDamageNumber(wx, wy, text, color) {
  particles.push({
    kind: 'text',
    x: wx, y: wy,
    vx: (Math.random() - 0.5) * 0.6,
    vy: -1.4,
    text, color,
    life: 50, maxLife: 50,
  });
}
function spawnPuff(wx, wy, color, count = 5) {
  for (let i = 0; i < count; i++) {
    particles.push({
      kind: 'puff',
      x: wx + (Math.random() - 0.5) * 8,
      y: wy + (Math.random() - 0.5) * 4,
      vx: (Math.random() - 0.5) * 2.4,
      vy: -0.8 - Math.random() * 1.6,
      gravity: 0.18,
      size: 2,
      color,
      life: 22 + Math.random() * 12,
      maxLife: 32,
    });
  }
}
function spawnSparks(wx, wy, count = 6) {
  for (let i = 0; i < count; i++) {
    particles.push({
      kind: 'puff',
      x: wx, y: wy,
      vx: (Math.random() - 0.5) * 4,
      vy: (Math.random() - 0.5) * 3 - 1,
      gravity: 0.22,
      size: 1,
      color: Math.random() < 0.5 ? '#ffd84a' : '#fff8c8',
      life: 14 + Math.random() * 10,
      maxLife: 24,
    });
  }
}
function updateParticles() {
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.x += p.vx;
    p.y += p.vy;
    if (p.gravity) p.vy += p.gravity;
    p.life--;
    if (p.life <= 0) particles.splice(i, 1);
  }
}
function renderParticles() {
  for (const p of particles) {
    const a = Math.min(1, p.life / 18);
    ctx.globalAlpha = a;
    if (p.kind === 'text') {
      ctx.font = 'bold 12px monospace';
      ctx.textAlign = 'center';
      ctx.lineWidth = 3;
      ctx.strokeStyle = '#000';
      ctx.strokeText(p.text, p.x, p.y);
      ctx.fillStyle = p.color;
      ctx.fillText(p.text, p.x, p.y);
    } else {
      ctx.fillStyle = p.color;
      ctx.fillRect(Math.floor(p.x), Math.floor(p.y), p.size, p.size);
    }
  }
  ctx.globalAlpha = 1;
}

function spawnGoblin(x, y) {
  return {
    x, y,
    px: x * TILE, py: y * TILE,
    homeX: x, homeY: y,
    hp: 5, hpMax: 5,
    alive: true,
    attackCd: 0,
    hurtT: 0,
    moveT: 0,
    aggro: false,
    respawn: 0,
    bobT: Math.random() * 100,
  };
}

const chickens = [
  { x: 14, y: 16, px: 14*TILE, py: 16*TILE, dir: 1, moveT: 0, alive: true, hp: 1 },
  { x: 16, y: 15, px: 16*TILE, py: 15*TILE, dir: -1, moveT: 30, alive: true, hp: 1 },
];

// =============================================================
// QUEST SYSTEM
// =============================================================
const QUEST = {
  steps: [
    { id: 'aric_intro', text: 'Speak with Wizard Aric',                       done: false },
    { id: 'brawler',    text: 'Visit Brawl Master & defeat a goblin',         done: false },
    { id: 'smith',      text: 'Visit the Smith & forge a Bronze Sword',       done: false },
    { id: 'chef',       text: 'Visit Chef Mira: catch & cook a fish',         done: false },
    { id: 'final',      text: 'Return to Aric and pass the final test',       done: false },
  ],
  active: 0,
  finished: false,
  flags: {
    aric_intro: false,
    brawler_talked: false,
    killed_a_goblin: false,
    smith_talked: false,
    chef_talked: false,
    aric_final_talked: false,
    boss_dead: false,
  },
};

function questAdvance(id) {
  for (const s of QUEST.steps) {
    if (s.id === id && !s.done) {
      s.done = true;
      QUEST.active++;
      log('quest', '★ Quest updated: ' + s.text);
      renderQuest();
      const allDone = QUEST.steps.every(st => st.done);
      if (allDone) {
        QUEST.finished = true;
        const stats = [
          'Attack Lv ' + player.atkLv,
          'Woodcut Lv ' + player.wcLv,
          'Mining Lv ' + player.miningLv,
          'Smelt Lv ' + player.smeltLv,
          'Smith Lv ' + player.smithLv,
          'Fishing Lv ' + player.fishLv,
          'Cooking Lv ' + player.cookLv,
        ].join(' · ');
        showOverlay('GRADUATED', 'You leave Tutorial Island a hero.\n' + stats);
      }
      return true;
    }
  }
  return false;
}

// =============================================================
// LOGGING / UI
// =============================================================
const logEl = document.getElementById('log');
const logEntries = [];
function log(kind, msg) {
  logEntries.push({ kind, msg });
  if (logEntries.length > 14) logEntries.shift();
  logEl.innerHTML = logEntries.map(e =>
    '<div class="entry ' + e.kind + '">' + escapeHtml(e.msg) + '</div>').join('');
}
function escapeHtml(s) {
  return s.replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
}

function renderQuest() {
  const el = document.getElementById('quest');
  const firstUndone = QUEST.steps.findIndex(s => !s.done);
  el.innerHTML = QUEST.steps.map((s, i) => {
    const cls = s.done ? 'done' : (i === firstUndone ? 'active' : '');
    const mark = s.done ? '✓' : (i === firstUndone ? '▶' : '·');
    return '<div class="step ' + cls + '">' + mark + ' ' + escapeHtml(s.text) + '</div>';
  }).join('');
}

const INV_SLOTS = 16;
const ITEM_ICONS = {
  log: '🪵', feather: '🪶', axe: '🪓', coin: '🪙', pickaxe: '⛏',
  copper_ore: '🟠', tin_ore: '⚪', iron_ore: '⚫',
  bronze_bar: '🟫', iron_bar: '⬛',
  bronze_sword: '🗡', iron_sword: '⚔',
  raw_fish: '🐟', cooked_fish: '🍣', burnt_fish: '⬛',
};
const ITEM_NAMES = {
  log: 'Log', feather: 'Feather', pickaxe: 'Pickaxe', axe: 'Axe',
  copper_ore: 'Copper Ore', tin_ore: 'Tin Ore', iron_ore: 'Iron Ore',
  bronze_bar: 'Bronze Bar', iron_bar: 'Iron Bar',
  bronze_sword: 'Bronze Sword', iron_sword: 'Iron Sword',
  raw_fish: 'Raw Fish', cooked_fish: 'Cooked Fish (click to eat)',
  burnt_fish: 'Burnt Fish (oops)',
};
function renderInv() {
  const el = document.getElementById('inv');
  let html = '';
  for (let i = 0; i < INV_SLOTS; i++) {
    const item = player.inv[i];
    if (item) {
      const icon = ITEM_ICONS[item.type] || '•';
      const name = ITEM_NAMES[item.type] || item.type;
      const equipped = player.equippedSword === item.type ? ' ★' : '';
      html += '<div class="slot" data-idx="' + i + '" title="' + name + equipped + '">' +
        '<div class="icon">' + icon + '</div>' +
        (item.qty > 1 ? item.qty : '') +
        '</div>';
    } else {
      html += '<div class="slot"></div>';
    }
  }
  el.innerHTML = html;
  // wire click-to-equip on swords
  el.querySelectorAll('.slot[data-idx]').forEach(slot => {
    slot.addEventListener('click', () => {
      const idx = +slot.dataset.idx;
      const it = player.inv[idx];
      if (!it) return;
      if (it.type === 'bronze_sword' || it.type === 'iron_sword') {
        player.equippedSword = (player.equippedSword === it.type) ? null : it.type;
        log('hint', player.equippedSword ?
          ('Equipped ' + SWORD_NAME[player.equippedSword] + '.') :
          'Unequipped weapon.');
        renderEquipped();
        renderInv();
      } else if (it.type === 'cooked_fish') {
        eatFood(idx);
      }
    });
  });
}

function renderEquipped() {
  const el = document.getElementById('equipped');
  if (!el) return;
  if (player.equippedSword) {
    const bonus = SWORD_BONUS[player.equippedSword];
    el.innerHTML = '<span style="color:#d4af37">' +
      ITEM_ICONS[player.equippedSword] + ' ' + SWORD_NAME[player.equippedSword] +
      '</span> <span style="color:#888">(+' + bonus + ' dmg)</span>';
  } else {
    el.innerHTML = '<span style="color:#666">Fists (no weapon)</span>';
  }
}

function addItem(type, qty = 1) {
  for (const it of player.inv) {
    if (it.type === type) { it.qty += qty; renderInv(); return; }
  }
  if (player.inv.length < INV_SLOTS) {
    player.inv.push({ type, qty });
    renderInv();
  }
}
function hasItem(type) {
  return player.inv.some(it => it.type === type && it.qty > 0);
}
function itemCount(type) {
  const it = player.inv.find(it => it.type === type);
  return it ? it.qty : 0;
}
function consumeItem(type, qty = 1) {
  const idx = player.inv.findIndex(it => it.type === type);
  if (idx === -1) return false;
  player.inv[idx].qty -= qty;
  if (player.inv[idx].qty <= 0) player.inv.splice(idx, 1);
  renderInv();
  return true;
}

const SKILL_DEFS = [
  { key: 'atk',    label: 'Attack' },
  { key: 'wc',     label: 'Woodcut' },
  { key: 'mining', label: 'Mining' },
  { key: 'smelt',  label: 'Smelt' },
  { key: 'smith',  label: 'Smith' },
  { key: 'fish',   label: 'Fishing' },
  { key: 'cook',   label: 'Cooking' },
];
function renderStats() {
  document.getElementById('hp-num').textContent = Math.max(0, player.hp);
  document.getElementById('hp-max').textContent = player.hpMax;
  document.getElementById('hp-bar').style.width = (100 * player.hp / player.hpMax) + '%';
  const sk = document.getElementById('skills');
  if (sk) {
    sk.innerHTML = SKILL_DEFS.map(s => {
      const lv = player[s.key + 'Lv'];
      const xp = player[s.key + 'Xp'];
      const pct = xpProgress(xp, lv);
      return '<div class="sk">' +
        '<div class="row"><span>' + s.label + '</span><span class="lv">Lv ' + lv + '</span></div>' +
        '<div class="bar tiny"><div class="bar-fill xp" style="width:' + pct + '%"></div></div>' +
        '</div>';
    }).join('');
  }
}
function xpForLevel(lv) { return (lv - 1) * (lv - 1) * 8; }
function xpProgress(xp, lv) {
  const cur = xpForLevel(lv);
  const next = xpForLevel(lv + 1);
  return Math.max(0, Math.min(100, 100 * (xp - cur) / (next - cur)));
}
function levelUpFX() {
  spawnSparks(player.px + 16, player.py + 8, 18);
  spawnDamageNumber(player.px + 16, player.py - 6, 'LEVEL UP!', '#ffd84a');
}

function gainXp(skill, amount) {
  if (skill === 'atk') {
    player.atkXp += amount;
    while (player.atkXp >= xpForLevel(player.atkLv + 1)) {
      player.atkLv++;
      player.hpMax += 2; player.hp += 2;
      log('skill', '↑ Attack level up! Now level ' + player.atkLv);
      levelUpFX();
    }
  } else if (skill === 'wc') {
    player.wcXp += amount;
    while (player.wcXp >= xpForLevel(player.wcLv + 1)) {
      player.wcLv++;
      log('skill', '↑ Woodcutting level up! Now level ' + player.wcLv);
      levelUpFX();
    }
  } else if (skill === 'mining') {
    player.miningXp += amount;
    while (player.miningXp >= xpForLevel(player.miningLv + 1)) {
      player.miningLv++;
      log('skill', '↑ Mining level up! Now level ' + player.miningLv);
      if (player.miningLv === 5) log('quest', '✦ Mining Lv 5 — you can now mine Iron!');
      levelUpFX();
    }
  } else if (skill === 'smelt') {
    player.smeltXp += amount;
    while (player.smeltXp >= xpForLevel(player.smeltLv + 1)) {
      player.smeltLv++;
      log('skill', '↑ Smelting level up! Now level ' + player.smeltLv);
      if (player.smeltLv === 5) log('quest', '✦ Smelting Lv 5 — Iron bars unlocked!');
      levelUpFX();
    }
  } else if (skill === 'smith') {
    player.smithXp += amount;
    while (player.smithXp >= xpForLevel(player.smithLv + 1)) {
      player.smithLv++;
      log('skill', '↑ Smithing level up! Now level ' + player.smithLv);
      if (player.smithLv === 5) log('quest', '✦ Smithing Lv 5 — Iron Sword recipe unlocked!');
      levelUpFX();
    }
  } else if (skill === 'fish') {
    player.fishXp += amount;
    while (player.fishXp >= xpForLevel(player.fishLv + 1)) {
      player.fishLv++;
      log('skill', '↑ Fishing level up! Now level ' + player.fishLv);
      levelUpFX();
    }
  } else if (skill === 'cook') {
    player.cookXp += amount;
    while (player.cookXp >= xpForLevel(player.cookLv + 1)) {
      player.cookLv++;
      log('skill', '↑ Cooking level up! Now level ' + player.cookLv);
      levelUpFX();
    }
  }
  renderStats();
}

// =============================================================
// INPUT
// =============================================================
const keys = {};
window.addEventListener('keydown', e => {
  const k = e.key.toLowerCase();
  keys[k] = true;
  if (['arrowup','arrowdown','arrowleft','arrowright',' '].includes(k)) {
    e.preventDefault();
  }
  if (k === ' ' || k === 'e' || k === 'enter') {
    pendingInteract = true;
  }
});
window.addEventListener('keyup', e => { keys[e.key.toLowerCase()] = false; });

let pendingInteract = false;
const FACING = {
  down:  [0,  1],
  up:    [0, -1],
  left:  [-1, 0],
  right: [1,  0],
};
function interact() {
  if (player.moving) return;
  const [dx, dy] = FACING[player.dir];
  const tx = player.x + dx;
  const ty = player.y + dy;
  // Reuse the existing per-target dispatch; dist is always 1 from here.
  if (!handleInteract(tx, ty)) {
    // also try the tile the player is standing on (for stuff right under)
    if (!handleInteract(player.x, player.y)) {
      log('hint', 'Nothing in front of you.');
    }
  }
}

// =============================================================
// MOVEMENT / COMBAT HELPERS
// =============================================================
function isBlocked(tx, ty) {
  if (tx < 0 || ty < 0 || tx >= COLS || ty >= ROWS) return true;
  if (blocked[ty][tx]) return true;
  for (const t of treeList) if (t.chopped === 0 && t.x === tx && t.y === ty) return true;
  for (const r of rockList) if (r.depleted === 0 && r.x === tx && r.y === ty) return true;
  for (const g of goblins) if (g.alive && g.x === tx && g.y === ty) return true;
  for (const n of npcs) if (n.x === tx && n.y === ty) return true;
  if (furnacePos && furnacePos.x === tx && furnacePos.y === ty) return true;
  if (anvilPos && anvilPos.x === tx && anvilPos.y === ty) return true;
  if (rangePos && rangePos.x === tx && rangePos.y === ty) return true;
  return false;
}

function tryMove(entity, dx, dy) {
  if (entity.moving) return false;
  const nx = entity.x + dx;
  const ny = entity.y + dy;
  if (isBlocked(nx, ny)) return false;
  entity.x = nx; entity.y = ny;
  entity.moving = true;
  entity.moveT = 0;
  return true;
}

function tileDist(a, b) {
  return Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
}

function attackGoblin(g) {
  if (!g.alive || player.attackCd > 0) return;
  player.attackCd = 60; // ~1s at 60fps
  g.hurtT = 12;
  g.aggro = true;
  const swordBonus = SWORD_BONUS[player.equippedSword] || 0;
  const dmg = 1 + Math.floor(Math.random() * (1 + player.atkLv)) + swordBonus;
  g.hp -= dmg;
  log('combat', '⚔ You hit Goblin for ' + dmg + ' (' + Math.max(0,g.hp) + '/' + g.hpMax + ')');
  spawnDamageNumber(g.px + 16, g.py + 8, '-' + dmg, '#ff6e6e');
  spawnSparks(g.px + 16, g.py + 16, 5);
  if (g.hp <= 0) {
    g.alive = false;
    g.respawn = g.isBoss ? 0 : 60 * 30; // boss doesn't respawn
    const xpAmt = g.isBoss ? 30 : 10;
    gainXp('atk', xpAmt);
    spawnPuff(g.px + 16, g.py + 16, PAL['I'], 14);
    spawnSparks(g.px + 16, g.py + 16, 10);
    spawnDamageNumber(g.px + 16, g.py - 2, '+' + xpAmt + ' Attack', '#9cffa0');
    if (g.isBoss) {
      log('combat', '☠ Boss Goblin slain! (+30 Attack XP)');
      QUEST.flags.boss_dead = true;
    } else {
      log('combat', '☠ Goblin defeated! +10 Attack XP');
      QUEST.flags.killed_a_goblin = true;
      if (QUEST.flags.brawler_talked) checkBrawlerStep();
    }
  }
}

function chopTreeProper(t) {
  if (t.chopped >= 1 || player.attackCd > 0) return;
  player.attackCd = 45;
  t.swings = (t.swings || 0) + 1;
  log('skill', '🪓 *thunk*');
  if (t.swings >= 3) {
    t.chopped = 1;
    t.regrow = 60 * 25;
    t.swings = 0;
    addItem('log', 1);
    gainXp('wc', 8);
    log('skill', '🌲 The tree falls! +1 Log, +8 Woodcutting XP');
    spawnPuff(t.x * TILE + 16, t.y * TILE + 24, PAL['U'], 8);
    spawnDamageNumber(t.x * TILE + 16, t.y * TILE + 16, '+8 WC', '#7cc14a');
  } else {
    spawnPuff(t.x * TILE + 16, t.y * TILE + 22, PAL['U'], 3);
  }
}

function mineRock(r) {
  if (r.depleted > 0 || player.attackCd > 0) return;
  if (!hasItem('pickaxe')) {
    log('hint', 'You need a pickaxe to mine rocks.');
    return;
  }
  const oreLvReq = { copper: 1, tin: 1, iron: 5 };
  if (player.miningLv < oreLvReq[r.ore]) {
    log('hint', 'You need Mining Lv ' + oreLvReq[r.ore] + ' to mine ' + r.ore + '.');
    return;
  }
  player.attackCd = 50;
  r.swings++;
  log('skill', '⛏ *clank*');
  spawnPuff(r.x * TILE + 16, r.y * TILE + 14, PAL['C'], 4);
  if (r.swings >= 3) {
    r.depleted = 1;
    r.regrow = 60 * 25;
    r.swings = 0;
    addItem(r.ore + '_ore', 1);
    const xpAmt = r.ore === 'iron' ? 14 : 8;
    gainXp('mining', xpAmt);
    log('skill', '⛏ Mined a chunk of ' + r.ore + ' ore. (+' + xpAmt + ' Mining XP)');
    spawnDamageNumber(r.x * TILE + 16, r.y * TILE + 8, '+' + xpAmt + ' Mining', '#cccccc');
  }
}

function smeltAt() {
  if (player.attackCd > 0) return;
  // Try iron first if eligible & has stock
  const fxAt = furnacePos ? { x: furnacePos.x * TILE + 16, y: furnacePos.y * TILE + 12 } : null;
  if (player.smeltLv >= 5 && hasItem('iron_ore')) {
    consumeItem('iron_ore', 1);
    addItem('iron_bar', 1);
    gainXp('smelt', 12);
    log('skill', '🔥 Smelted an Iron Bar. (+12 Smelting XP)');
    if (fxAt) { spawnSparks(fxAt.x, fxAt.y, 8); spawnDamageNumber(fxAt.x, fxAt.y - 4, '+12 Smelt', '#ffb84a'); }
    player.attackCd = 60;
    return;
  }
  if (hasItem('copper_ore') && hasItem('tin_ore')) {
    consumeItem('copper_ore', 1);
    consumeItem('tin_ore', 1);
    addItem('bronze_bar', 1);
    gainXp('smelt', 6);
    log('skill', '🔥 Smelted a Bronze Bar. (+6 Smelting XP)');
    if (fxAt) { spawnSparks(fxAt.x, fxAt.y, 6); spawnDamageNumber(fxAt.x, fxAt.y - 4, '+6 Smelt', '#ffb84a'); }
    player.attackCd = 60;
    return;
  }
  log('hint', 'Furnace needs 1 copper ore + 1 tin ore (or iron at Lv 5+).');
}

function smithAt() {
  if (player.attackCd > 0) return;
  if (player.smithLv >= 5 && itemCount('iron_bar') >= 1) {
    consumeItem('iron_bar', 1);
    addItem('iron_sword', 1);
    gainXp('smith', 24);
    log('skill', '🔨 Forged an Iron Sword! (+24 Smithing XP)');
    autoEquipBest();
    player.attackCd = 70;
    if (QUEST.flags.smith_talked) checkSmithStep();
    return;
  }
  if (itemCount('bronze_bar') >= 1) {
    consumeItem('bronze_bar', 1);
    addItem('bronze_sword', 1);
    gainXp('smith', 14);
    log('skill', '🔨 Forged a Bronze Sword! (+14 Smithing XP)');
    if (anvilPos) {
      spawnSparks(anvilPos.x * TILE + 16, anvilPos.y * TILE + 14, 12);
      spawnDamageNumber(anvilPos.x * TILE + 16, anvilPos.y * TILE + 4, '+14 Smith', '#ffd84a');
    }
    autoEquipBest();
    player.attackCd = 70;
    if (QUEST.flags.smith_talked) checkSmithStep();
    return;
  }
  log('hint', 'Anvil needs 1 bronze bar (or iron at Lv 5+).');
}

function autoEquipBest() {
  const has = (t) => itemCount(t) > 0;
  if (has('iron_sword')) player.equippedSword = 'iron_sword';
  else if (has('bronze_sword')) player.equippedSword = 'bronze_sword';
  renderEquipped();
}

function catchFish(spot) {
  if (spot.depleted > 0 || player.attackCd > 0) return;
  player.attackCd = 50;
  spot.swings = (spot.swings || 0) + 1;
  log('skill', '🎣 *cast*');
  if (spot.swings >= 3) {
    spot.depleted = 1;
    spot.regrow = 60 * 20;
    spot.swings = 0;
    addItem('raw_fish', 1);
    gainXp('fish', 8);
    log('skill', '🐟 Caught a fish! (+8 Fishing XP)');
    spawnSparks(spot.x * TILE + 16, spot.y * TILE + 16, 6);
    spawnDamageNumber(spot.x * TILE + 16, spot.y * TILE + 4, '+8 Fishing', '#69cfff');
    if (QUEST.flags.chef_talked) checkChefStep();
  }
}

function cookFish() {
  if (player.attackCd > 0) return;
  if (!hasItem('raw_fish')) {
    log('hint', 'You need a Raw Fish to cook.');
    return;
  }
  consumeItem('raw_fish', 1);
  player.attackCd = 60;
  // burn chance decreases with cookLv
  const burnChance = Math.max(0, 0.4 - 0.07 * (player.cookLv - 1));
  if (Math.random() < burnChance) {
    addItem('burnt_fish', 1);
    log('skill', '🔥 Oh no, you burned the fish!');
    gainXp('cook', 1);
  } else {
    addItem('cooked_fish', 1);
    gainXp('cook', 6);
    log('skill', '🍣 Cooked a fish nicely. (+6 Cooking XP)');
    if (rangePos) {
      spawnSparks(rangePos.x * TILE + 16, rangePos.y * TILE + 16, 8);
      spawnDamageNumber(rangePos.x * TILE + 16, rangePos.y * TILE + 4, '+6 Cook', '#ffaa55');
    }
    if (QUEST.flags.chef_talked) checkChefStep();
  }
}

function eatFood(idx) {
  const it = player.inv[idx];
  if (!it) return;
  if (it.type !== 'cooked_fish') return;
  if (player.hp >= player.hpMax) {
    log('hint', 'You are at full health.');
    return;
  }
  consumeItem('cooked_fish', 1);
  const heal = 4;
  player.hp = Math.min(player.hpMax, player.hp + heal);
  log('skill', '🍴 Ate cooked fish. +' + heal + ' HP');
  renderStats();
}

function checkBrawlerStep() {
  if (QUEST.flags.brawler_talked && QUEST.flags.killed_a_goblin) {
    questAdvance('brawler');
  }
}
function checkSmithStep() {
  if (QUEST.flags.smith_talked && (hasItem('bronze_sword') || hasItem('iron_sword'))) {
    questAdvance('smith');
  }
}
function checkChefStep() {
  if (QUEST.flags.chef_talked && hasItem('cooked_fish')) {
    questAdvance('chef');
  }
}

function npcHasQuestMarker(n) {
  // Aric: marker if first interaction pending OR if final step ready
  if (n.role === 'aric') {
    if (!QUEST.flags.aric_intro) return true;
    if (allDoneExceptFinal() && !QUEST.steps[4].done) return true;
    return false;
  }
  // Brawler: until brawler step is done
  if (n.role === 'brawler') return !QUEST.steps[1].done && QUEST.steps[0].done;
  if (n.role === 'smith')   return !QUEST.steps[2].done && QUEST.steps[0].done;
  if (n.role === 'chef')    return !QUEST.steps[3].done && QUEST.steps[0].done;
  return false;
}

function spawnBoss() {
  if (!bossSpawn) return;
  const b = spawnGoblin(bossSpawn.x, bossSpawn.y);
  b.hpMax = 24; b.hp = 24;
  b.isBoss = true;
  b.aggro = true;
  goblins.push(b);
  log('quest', '⚔ A massive goblin lumbers out of the bushes!');
}

function talkToNpc(npc) {
  const role = npc.role;
  if (role === 'aric') {
    if (!QUEST.flags.aric_intro) {
      log('quest', 'Aric: "Welcome to Tutorial Island, adventurer."');
      log('quest', 'Aric: "Speak with the Brawl Master east of here to begin."');
      QUEST.flags.aric_intro = true;
      questAdvance('aric_intro');
    } else if (allDoneExceptFinal()) {
      if (!QUEST.flags.aric_final_talked) {
        log('quest', 'Aric: "One last test — defeat the giant goblin behind you!"');
        QUEST.flags.aric_final_talked = true;
        spawnBoss();
      } else if (QUEST.flags.boss_dead) {
        log('quest', 'Aric: "You have graduated, hero."');
        questAdvance('final');
      } else {
        log('quest', 'Aric: "The boss still stalks. Fell it!"');
      }
    } else {
      log('quest', 'Aric: "Continue your training. Find each station-master in turn."');
    }
  } else if (role === 'brawler') {
    QUEST.flags.brawler_talked = true;
    log('quest', 'Brawl Master: "Click an adjacent goblin to swing at it."');
    log('quest', 'Brawl Master: "Defeat one and we\'ll talk again."');
    if (QUEST.flags.killed_a_goblin) checkBrawlerStep();
  } else if (role === 'smith') {
    QUEST.flags.smith_talked = true;
    log('quest', 'Smith: "Mine copper and tin (south-west), smelt at my furnace,"');
    log('quest', 'Smith: "then forge a Bronze Sword on the anvil."');
    if (hasItem('bronze_sword') || hasItem('iron_sword')) checkSmithStep();
  } else if (role === 'chef') {
    QUEST.flags.chef_talked = true;
    log('quest', 'Chef Mira: "Fish from the pond south, then cook on my range."');
    log('quest', 'Chef Mira: "Click a fishing spot, then click my range."');
    if (hasItem('cooked_fish')) checkChefStep();
  }
}

function allDoneExceptFinal() {
  return QUEST.steps.slice(0, 4).every(s => s.done);
}

// =============================================================
// GOBLIN AI
// =============================================================
function updateGoblin(g, dt) {
  if (!g.alive) {
    g.respawn--;
    if (g.respawn <= 0) {
      g.x = g.homeX; g.y = g.homeY;
      g.px = g.x * TILE; g.py = g.y * TILE;
      g.hp = g.hpMax; g.alive = true; g.aggro = false;
    }
    return;
  }

  if (g.hurtT > 0) g.hurtT--;
  if (g.attackCd > 0) g.attackCd--;

  // smooth movement to grid pos
  const tx = g.x * TILE;
  const ty = g.y * TILE;
  if (g.px !== tx || g.py !== ty) {
    g.px += Math.sign(tx - g.px) * Math.min(2, Math.abs(tx - g.px));
    g.py += Math.sign(ty - g.py) * Math.min(2, Math.abs(ty - g.py));
    return;
  }

  g.bobT++;

  // aggro range
  const d = tileDist(g, player);
  if (d <= 4) g.aggro = true;
  if (d > 8) g.aggro = false;

  if (g.aggro && d > 1) {
    g.moveT++;
    if (g.moveT < 30) return;
    g.moveT = 0;
    // step toward player
    const dx = Math.sign(player.x - g.x);
    const dy = Math.sign(player.y - g.y);
    if (dx !== 0 && !isBlocked(g.x + dx, g.y)) { g.x += dx; }
    else if (dy !== 0 && !isBlocked(g.x, g.y + dy)) { g.y += dy; }
  } else if (g.aggro && d === 1) {
    // attack player
    if (g.attackCd <= 0 && player.hurtT <= 0) {
      g.attackCd = 70;
      const dmg = (g.isBoss ? 2 : 1) + (Math.random() < 0.3 ? 1 : 0);
      player.hp -= dmg;
      player.hurtT = 18;
      log('combat', '⚔ Goblin hits you for ' + dmg);
      spawnDamageNumber(player.px + 16, player.py + 8, '-' + dmg, '#ff8a8a');
      spawnPuff(player.px + 16, player.py + 18, '#a52', 3);
      if (player.hp <= 0) {
        log('combat', '☠ You died! Respawning at the path...');
        player.hp = player.hpMax;
        player.x = spawnX; player.y = spawnY;
        player.px = player.x * TILE; player.py = player.y * TILE;
        // drop half xp as penalty? skip for demo
      }
      renderStats();
    }
  } else {
    // idle wander
    g.moveT++;
    if (g.moveT > 90 + Math.floor(Math.random() * 60)) {
      g.moveT = 0;
      const choices = [[1,0],[-1,0],[0,1],[0,-1]];
      const [dx, dy] = choices[Math.floor(Math.random() * 4)];
      const nx = g.x + dx, ny = g.y + dy;
      if (Math.abs(nx - g.homeX) <= 3 && Math.abs(ny - g.homeY) <= 3 && !isBlocked(nx, ny)) {
        g.x = nx; g.y = ny;
      }
    }
  }
}

function updateChicken(c) {
  if (!c.alive) return;
  // smooth move
  const tx = c.x * TILE, ty = c.y * TILE;
  if (c.px !== tx || c.py !== ty) {
    c.px += Math.sign(tx - c.px);
    c.py += Math.sign(ty - c.py);
    return;
  }
  c.moveT++;
  if (c.moveT > 60 + Math.random() * 60) {
    c.moveT = 0;
    const dx = Math.random() < 0.5 ? c.dir : 0;
    const dy = dx === 0 ? (Math.random() < 0.5 ? 1 : -1) : 0;
    const nx = c.x + dx, ny = c.y + dy;
    if (!isBlocked(nx, ny) && nx >= 14 && nx <= 22 && ny >= 14 && ny <= 16) {
      c.x = nx; c.y = ny;
    } else {
      c.dir = -c.dir;
    }
  }
}

// =============================================================
// RENDER
// =============================================================
function drawSprite(name, px, py, opts = {}) {
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

function render() {
  // clear (in case world doesn't fill viewport during edge cases)
  ctx.fillStyle = '#000';
  ctx.fillRect(0, 0, VIEW_W, VIEW_H);

  ctx.save();
  ctx.translate(-Math.floor(camera.x), -Math.floor(camera.y));

  // tiles — cull to viewport
  const waterFrame = Math.floor(Date.now() / 280) % 4;
  const startX = Math.max(0, Math.floor(camera.x / TILE));
  const startY = Math.max(0, Math.floor(camera.y / TILE));
  const endX = Math.min(COLS, Math.ceil((camera.x + VIEW_W) / TILE) + 1);
  const endY = Math.min(ROWS, Math.ceil((camera.y + VIEW_H) / TILE) + 1);
  for (let y = startY; y < endY; y++) {
    for (let x = startX; x < endX; x++) {
      const k = tileGrid[y][x];
      const t = TILES[k];
      const img = Array.isArray(t) ? t[waterFrame] : t;
      ctx.drawImage(img, x * TILE, y * TILE);
    }
  }

  // shadows under entities
  ctx.fillStyle = 'rgba(0,0,0,0.18)';
  for (const t of treeList) {
    ctx.beginPath();
    ctx.ellipse(t.x * TILE + 16, t.y * TILE + 28, 10, 4, 0, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.beginPath();
  ctx.ellipse(player.px + 16, player.py + 28, 9, 3, 0, 0, Math.PI * 2);
  ctx.fill();
  for (const g of goblins) if (g.alive) {
    ctx.beginPath();
    ctx.ellipse(g.px + 16, g.py + 28, 8, 3, 0, 0, Math.PI * 2);
    ctx.fill();
  }

  // collect drawables for y-sort
  const drawables = [];

  for (const t of treeList) {
    drawables.push({
      y: t.y * TILE + 24,
      draw: () => {
        if (t.chopped === 0) {
          drawSprite(t.kind === 'pine' ? 'tree_pine' : 'tree', t.x * TILE, t.y * TILE);
        } else {
          drawSprite('stump', t.x * TILE, t.y * TILE);
        }
      }
    });
  }
  for (const r of rockList) {
    drawables.push({
      y: r.y * TILE + 24,
      draw: () => {
        if (r.depleted === 0) drawSprite('rock_' + r.ore, r.x * TILE, r.y * TILE);
        else drawSprite('rock_depleted', r.x * TILE, r.y * TILE);
      }
    });
  }
  if (furnacePos) {
    drawables.push({
      y: furnacePos.y * TILE + 24,
      draw: () => {
        drawSprite('furnace', furnacePos.x * TILE, furnacePos.y * TILE);
        // animated ember glow
        const t = Date.now() / 120;
        const a = 0.3 + Math.sin(t) * 0.15;
        ctx.fillStyle = 'rgba(255,170,40,' + a + ')';
        ctx.fillRect(furnacePos.x * TILE + 14, furnacePos.y * TILE + 14, 4, 6);
      }
    });
  }
  if (anvilPos) {
    drawables.push({
      y: anvilPos.y * TILE + 24,
      draw: () => drawSprite('anvil', anvilPos.x * TILE, anvilPos.y * TILE)
    });
  }
  for (const c of chickens) if (c.alive) {
    drawables.push({
      y: c.py + 24,
      draw: () => drawSprite('chicken', c.px, c.py)
    });
  }
  for (const g of goblins) if (g.alive) {
    drawables.push({
      y: g.py + 24,
      draw: () => {
        const bob = Math.floor(Math.sin(g.bobT * 0.2) * 1);
        const sprite = g.isBoss ? 'goblin_boss' : 'goblin';
        drawSprite(sprite, g.px, g.py, { bob, flash: g.hurtT > 0 });
        if (g.hp < g.hpMax) {
          const w = g.isBoss ? 24 : 20;
          ctx.fillStyle = '#000';
          ctx.fillRect(g.px + 16 - w/2, g.py + (g.isBoss ? -4 : 2), w, 4);
          ctx.fillStyle = g.isBoss ? '#e44' : PAL['F'];
          ctx.fillRect(g.px + 16 - w/2 + 1, g.py + (g.isBoss ? -3 : 3), Math.max(0, (w - 2) * g.hp / g.hpMax), 2);
        }
      }
    });
  }
  for (const n of npcs) {
    drawables.push({
      y: n.y * TILE + 24,
      draw: () => {
        const def = NPC_DEFS[n.role];
        drawSprite(def.sprite, n.x * TILE, n.y * TILE);
        if (npcHasQuestMarker(n) && !QUEST.finished) {
          const markerY = n.y * TILE - 10 + Math.sin(Date.now() / 250) * 2;
          ctx.fillStyle = PAL['G'];
          ctx.font = 'bold 14px monospace';
          ctx.textAlign = 'center';
          ctx.fillText('!', n.x * TILE + 16, markerY);
        }
      }
    });
  }
  for (const s of fishingSpots) {
    if (s.depleted > 0) continue;
    drawables.push({
      y: s.y * TILE + 24,
      draw: () => {
        // animated bubbles
        const t = Date.now() / 400;
        ctx.fillStyle = '#fff';
        ctx.globalAlpha = 0.7 + Math.sin(t) * 0.3;
        ctx.fillRect(s.x * TILE + 10 + Math.sin(t * 1.4) * 2, s.y * TILE + 12, 2, 2);
        ctx.fillRect(s.x * TILE + 18 + Math.cos(t * 1.7) * 2, s.y * TILE + 18, 2, 2);
        ctx.fillRect(s.x * TILE + 14, s.y * TILE + 22 + Math.sin(t * 2) * 2, 2, 2);
        ctx.globalAlpha = 1;
      }
    });
  }
  if (rangePos) {
    drawables.push({
      y: rangePos.y * TILE + 24,
      draw: () => {
        drawSprite('range', rangePos.x * TILE, rangePos.y * TILE);
        // ember shimmer
        const t = Date.now() / 100;
        const a = 0.3 + Math.sin(t) * 0.2;
        ctx.fillStyle = 'rgba(255,180,60,' + a + ')';
        ctx.fillRect(rangePos.x * TILE + 13, rangePos.y * TILE + 18, 6, 4);
      }
    });
  }
  drawables.push({
    y: player.py + 24,
    draw: () => {
      const bob = player.moving ? Math.floor(Math.sin(player.bobT * 0.4) * 1) : 0;
      const stepFrame = player.moving && (Math.floor(player.bobT / 8) % 2) === 1;
      const sprite = 'player_' + player.dir + (stepFrame ? '_walk' : '');
      drawSprite(sprite, player.px, player.py, { bob, flash: player.hurtT > 0 });
    }
  });

  drawables.sort((a, b) => a.y - b.y);
  for (const d of drawables) d.draw();

  // attack swing fx
  if (player.attackCd > 50) {
    const fxAlpha = (player.attackCd - 50) / 10;
    ctx.globalAlpha = fxAlpha;
    ctx.strokeStyle = PAL['H'];
    ctx.lineWidth = 2;
    ctx.beginPath();
    let cx = player.px + 16, cy = player.py + 16;
    if (player.dir === 'down') cy += 14;
    if (player.dir === 'up') cy -= 14;
    if (player.dir === 'left') cx -= 14;
    if (player.dir === 'right') cx += 14;
    ctx.arc(cx, cy, 8, 0, Math.PI * 2);
    ctx.stroke();
    ctx.globalAlpha = 1;
  }

  // particles drawn last (above everything)
  renderParticles();

  // facing-tile interact prompt
  if (!player.moving) {
    const [dx, dy] = FACING[player.dir];
    const tx = player.x + dx;
    const ty = player.y + dy;
    const label = interactLabel(tx, ty);
    if (label) {
      const px = tx * TILE + 16;
      const py = ty * TILE + 32;
      // soft outline behind text
      ctx.font = 'bold 10px monospace';
      ctx.textAlign = 'center';
      ctx.lineWidth = 3;
      ctx.strokeStyle = 'rgba(0,0,0,0.85)';
      ctx.strokeText('[Space] ' + label, px, py);
      ctx.fillStyle = '#ffd84a';
      ctx.fillText('[Space] ' + label, px, py);
    }
  }

  ctx.restore();
}

function interactLabel(tx, ty) {
  for (const n of npcs) if (n.x === tx && n.y === ty) return 'Talk to ' + NPC_DEFS[n.role].name;
  for (const g of goblins) if (g.alive && g.x === tx && g.y === ty) return g.isBoss ? 'Attack Boss' : 'Attack Goblin';
  for (const s of fishingSpots) if (s.depleted === 0 && s.x === tx && s.y === ty) return 'Fish';
  if (rangePos && rangePos.x === tx && rangePos.y === ty) return 'Cook';
  for (const t of treeList) if (t.chopped === 0 && t.x === tx && t.y === ty) return 'Chop';
  for (const r of rockList) if (r.depleted === 0 && r.x === tx && r.y === ty) return 'Mine';
  if (furnacePos && furnacePos.x === tx && furnacePos.y === ty) return 'Smelt';
  if (anvilPos && anvilPos.x === tx && anvilPos.y === ty) return 'Forge';
  for (const c of chickens) if (c.alive && c.x === tx && c.y === ty) return 'Grab feather';
  return null;
}

// =============================================================
// UPDATE
// =============================================================
function updatePlayer() {
  if (player.attackCd > 0) player.attackCd--;
  if (player.hurtT > 0) player.hurtT--;

  // smooth grid-tween movement
  const tx = player.x * TILE;
  const ty = player.y * TILE;
  if (player.px !== tx || player.py !== ty) {
    const dx = Math.sign(tx - player.px);
    const dy = Math.sign(ty - player.py);
    player.px += dx * 4;
    player.py += dy * 4;
    if (Math.abs(player.px - tx) < 4) player.px = tx;
    if (Math.abs(player.py - ty) < 4) player.py = ty;
    player.moving = true;
    player.bobT++;
  } else {
    player.moving = false;
    player.bobT = 0;

    // queue next step
    let dx = 0, dy = 0;
    if (keys['arrowup'] || keys['w']) { dy = -1; player.dir = 'up'; }
    else if (keys['arrowdown'] || keys['s']) { dy = 1; player.dir = 'down'; }
    else if (keys['arrowleft'] || keys['a']) { dx = -1; player.dir = 'left'; }
    else if (keys['arrowright'] || keys['d']) { dx = 1; player.dir = 'right'; }
    if (dx || dy) {
      const nx = player.x + dx;
      const ny = player.y + dy;
      if (!isBlocked(nx, ny)) {
        player.x = nx; player.y = ny;
      }
    }
  }

  // process queued interact (Space / E / Enter) — only when player is settled
  if (pendingInteract && !player.moving) {
    pendingInteract = false;
    interact();
  }
}

// Returns true if a target was found at (tx, ty) and an action was attempted.
// Caller is responsible for ensuring (tx, ty) is the player's facing tile.
function handleInteract(tx, ty) {
  for (const n of npcs) {
    if (n.x === tx && n.y === ty) { talkToNpc(n); return true; }
  }
  for (const s of fishingSpots) {
    if (s.x === tx && s.y === ty && s.depleted === 0) {
      if (!QUEST.flags.chef_talked) {
        log('hint', 'Speak with Chef Mira first to learn how to fish.');
        return true;
      }
      catchFish(s);
      return true;
    }
  }
  if (rangePos && rangePos.x === tx && rangePos.y === ty) { cookFish(); return true; }
  for (const g of goblins) {
    if (g.alive && g.x === tx && g.y === ty) { attackGoblin(g); return true; }
  }
  for (const t of treeList) {
    if (t.chopped === 0 && t.x === tx && t.y === ty) { chopTreeProper(t); return true; }
  }
  for (const r of rockList) {
    if (r.depleted === 0 && r.x === tx && r.y === ty) { mineRock(r); return true; }
  }
  if (furnacePos && furnacePos.x === tx && furnacePos.y === ty) { smeltAt(); return true; }
  if (anvilPos && anvilPos.x === tx && anvilPos.y === ty) { smithAt(); return true; }
  for (const c of chickens) {
    if (c.alive && c.x === tx && c.y === ty) {
      c.alive = false;
      addItem('feather', 1);
      gainXp('atk', 2);
      log('combat', 'You snatched a feather. (+2 Attack XP)');
      return true;
    }
  }
  return false;
}

function updateTrees() {
  for (const t of treeList) {
    if (t.chopped > 0) {
      t.regrow--;
      if (t.regrow <= 0) {
        t.chopped = 0; t.swings = 0;
      }
    }
  }
  for (const r of rockList) {
    if (r.depleted > 0) {
      r.regrow--;
      if (r.regrow <= 0) {
        r.depleted = 0; r.swings = 0;
      }
    }
  }
  for (const s of fishingSpots) {
    if (s.depleted > 0) {
      s.regrow--;
      if (s.regrow <= 0) {
        s.depleted = 0; s.swings = 0;
      }
    }
  }
}

// =============================================================
// MAIN LOOP
// =============================================================
function loop() {
  updatePlayer();
  for (const g of goblins) updateGoblin(g);
  for (const c of chickens) updateChicken(c);
  updateTrees();
  updateParticles();
  updateCamera();
  render();
  if (player.hp < player.hpMax && (Math.random() < 0.005)) {
    player.hp = Math.min(player.hpMax, player.hp + 1);
    renderStats();
  }
  requestAnimationFrame(loop);
}

// =============================================================
// OVERLAY
// =============================================================
function showOverlay(title, text) {
  const o = document.getElementById('overlay');
  document.getElementById('overlay-title').textContent = title;
  document.getElementById('overlay-text').textContent = text;
  o.style.display = 'flex';
}
document.getElementById('overlay-btn').addEventListener('click', () => {
  location.reload();
});

// =============================================================
// BOOT
// =============================================================
addItem('pickaxe', 1);
addItem('axe', 1);
log('hint', 'Welcome to Tutorial Island.');
log('hint', 'Move with WASD/arrows. Press Space (or E) to interact.');
log('hint', 'Face Wizard Aric (gold ! marker) and press Space to begin.');
renderQuest();
renderInv();
renderStats();
renderEquipped();
requestAnimationFrame(loop);
