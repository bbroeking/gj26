// Bramblewood dungeon editor — a standalone 2D top-down painter that
// produces JSON layouts compatible with src/scene/dungeon.js.
//
// Schema (matches what generateDungeonLayout returns, plus authoring meta):
// {
//   name: string,
//   scope: 'briar_maze' | 'sunken_hut' | 'delve' | 'hollow',
//   size: { w: number, h: number },
//   grid: string[][],           // 'wall' | 'floor', indexed [y][x]
//   entry: { x, y },
//   exit:  { x, y },
//   chestTile: { x, y } | null,
//   decor: Array<{ kind, x, y, item? }>,
//   spawns: Array<{ kind, x, y }>,
//   bossKind: string | null,
// }

const TILE_PX = 22;

// Palette definitions. Color = preview swatch + canvas paint.
const TILES = [
  { id: 'wall',  name: 'Wall',  color: '#3a2a1c' },
  { id: 'floor', name: 'Floor', color: '#8a7a58' },
];
const MARKERS = [
  { id: 'entry',     name: 'Entry stair', color: '#6f8a3f', glyph: 'E' },
  { id: 'exit',      name: 'Exit stair',  color: '#d4af37', glyph: 'X' },
  { id: 'chestTile', name: 'Chest',       color: '#b8722e', glyph: 'C' },
  { id: 'staircase', name: 'Staircase →', color: '#9a6ec4', glyph: 'S' },
];
const DECOR = [
  { id: 'ore_rock',     name: 'Ore rock',     color: '#7a6a58', glyph: 'o' },
  { id: 'thorn_pillar', name: 'Thorn pillar', color: '#5a4030', glyph: '*' },
  { id: 'puddle',       name: 'Puddle',       color: '#3a4a5e', glyph: '~' },
  { id: 'boulder',      name: 'Boulder',      color: '#6e6862', glyph: '○' },
  { id: 'mossfloor',    name: 'Moss floor',   color: '#4a6a3a', glyph: '·' },
];
// Room intent tags — author drops one tile per painted room. Scaffold
// loader looks up which room contains each tag and stores it on the
// room. Spawn loop dispatches off room.tag so the author conveys intent
// without painting every spawn.
const ROOMTAGS = [
  { id: 'mob',      name: 'Mob room (default)', color: '#a85838', glyph: 'M' },
  { id: 'boss',     name: 'Boss room',          color: '#9a1a4a', glyph: 'B' },
  { id: 'treasure', name: 'Treasure room',      color: '#d4af37', glyph: 'T' },
  { id: 'shrine',   name: 'Shrine room',        color: '#88a050', glyph: 'S' },
  { id: 'puzzle',   name: 'Puzzle (no mob)',    color: '#6080a0', glyph: 'P' },
  { id: 'safe',     name: 'Safe (no mob)',      color: '#7a7060', glyph: '·' },
];
// Trap kinds — paint a tile, runtime applies damage when player steps on
// it. Spike consumes after firing (one-shot); bramble persists.
const TRAPS = [
  { id: 'spike',   name: 'Spike trap (3 dmg, one-shot)',  color: '#c46624', glyph: '^' },
  { id: 'bramble', name: 'Bramble trap (1 dmg, stays)',   color: '#4a6630', glyph: '*' },
];

// Door colors — paint blocks the tile until the player has the matching
// key (iron_key / gold_key / thorn_key). Used to gate treasure or boss rooms.
const DOORS = [
  { id: 'iron',  name: 'Iron door (iron_key)',   color: '#6e6862', glyph: 'D' },
  { id: 'gold',  name: 'Gold door (gold_key)',   color: '#d4af37', glyph: 'D' },
  { id: 'thorn', name: 'Thorn door (thorn_key)', color: '#6f8a3f', glyph: 'D' },
];
const SPAWNS = [
  { id: 'bramble_imp',     name: 'Bramble imp',     color: '#8a4a3a', glyph: 'i' },
  { id: 'bramble_cap',     name: 'Bramble cap',     color: '#a85838', glyph: 'I' },
  { id: 'iron_gob',        name: 'Iron goblin',     color: '#6a6e7a', glyph: 'g' },
  { id: 'skitterling',     name: 'Skitterling',     color: '#5a5840', glyph: 's' },
  { id: 'marsh_rat',       name: 'Marsh rat',       color: '#6a5840', glyph: 'r' },
  { id: 'tusker_sow',      name: 'Tusker sow',      color: '#5a3030', glyph: 'T' },
  { id: 'bramble_archer',  name: 'Bramble archer',  color: '#7a3a6a', glyph: 'A' },
  { id: 'bramble_charger', name: 'Bramble charger', color: '#a04030', glyph: 'C' },
  { id: 'hedgewolf',       name: 'Hedgewolf',       color: '#3a3a3a', glyph: 'w' },
  { id: 'wolf_alpha',      name: 'Wolf alpha',      color: '#1a1a1a', glyph: 'W' },
  { id: 'hedgemother',     name: 'Hedgemother',     color: '#5a1a4a', glyph: 'H' },
];

// ---- editor state -------------------------------------------------------

const state = {
  name: 'untitled-dungeon',
  scope: 'briar_maze',
  mode: 'authored',
  procgenPadding: true,           // scaffold-only: add 1-3 random extra rooms
  useBrushes: false,              // scaffold-only: stamp 2-4 brushes from library
  w: 22,
  h: 22,
  grid: [],                      // 2D string array
  entry: { x: 3, y: 3 },
  exit:  { x: 18, y: 18 },
  chestTile: null,
  decor: [],                     // [{kind, x, y, item?}]
  spawns: [],                    // [{kind, x, y}]
  staircases: [],                // [{x, y, target: 'libraryName'}]
  roomTags: [],                  // [{x, y, tag}] — Stage B per-room intent
  traps: [],                     // [{x, y, kind}] — 'spike' | 'bramble'
  doors: [],                     // [{x, y, color, locked}] — 'iron'|'gold'|'thorn'
  bossKind: '',
  // Procgen knobs (Stage A): exposed so the editor is a control panel for
  // the existing dungeon procgen — not a rebuild of it.
  tier: 1,                       // 1..5; biases enemy difficulty + loot
  runeEffect: '',                // '' | 'fire' | 'earth' | 'water' | 'air'
  seed: '',                      // blank = random; numeric string = deterministic
  affixIds: [],                  // ['tyrannical', 'mineral_vein', ...]
  brush: { kind: 'tile', id: 'wall' },   // current paint
};

// All exposed affix ids — kept in sync with src/data/affixes.js by hand
// for now (the editor is a static page, no module imports across boundaries).
// Each entry is its presentation label; the id is the dict key.
const AFFIX_DEFS = {
  // Boss
  hedgemother_den: 'Hedgemother\'s Den (boss)',
  burrow_boar_den: 'Burrow Boar\'s Wallow (boss)',
  wolf_alpha_den:  'Wolf Alpha\'s Roost (boss)',
  // Resource bias
  mineral_vein:    'Mineral Vein (ore rocks)',
  bramble_bloom:   'Bramble Bloom (forage spawns)',
  tinder_cache:    'Tinder Cache (logs)',
  ink_spring:      'Ink Spring (refined ink)',
  wood_grove:      'Wood Grove (chest +logs)',
  herbal_patch:    'Herbal Patch (chest +herbs)',
  gilded_seam:     'Gilded Seam (chest +coin)',
  gem_seam:        'Gem Seam (chest +coin)',
  // Combat modifiers
  tyrannical:      'Tyrannical (+50% HP, +30% XP)',
  bursting:        'Bursting (death AoE)',
  frenzied:        'Frenzied (low-HP rage)',
  fog_of_hedge:    'Fog of Hedge (vision +XP)',
  festival_pace:   'Festival Pace (extra mob/room)',
};

function newGrid(w, h, fill = 'wall') {
  return Array.from({ length: h }, () => Array(w).fill(fill));
}

function inside(x, y) {
  return x >= 0 && y >= 0 && x < state.w && y < state.h;
}

// ---- DOM refs -----------------------------------------------------------

const canvas = document.getElementById('grid');
const ctx = canvas.getContext('2d');
const statusEl = document.getElementById('status');
const jsonPane = document.getElementById('json-pane');
const statsEl = document.getElementById('stats');

// ---- palette UI ---------------------------------------------------------

function renderSwatches(containerId, items, brushKind) {
  const el = document.getElementById(containerId);
  el.innerHTML = '';
  for (const it of items) {
    const div = document.createElement('div');
    div.className = 'swatch';
    div.dataset.id = it.id;
    div.dataset.kind = brushKind;
    div.innerHTML = `<span class="chip" style="background:${it.color}"></span><span>${it.name}</span>`;
    div.addEventListener('click', () => setBrush(brushKind, it.id));
    el.appendChild(div);
  }
}

function setBrush(kind, id) {
  state.brush = { kind, id };
  // active styling
  for (const sw of document.querySelectorAll('.swatch')) {
    sw.classList.toggle('active', sw.dataset.kind === kind && sw.dataset.id === id);
  }
  status(`Brush: ${kind}/${id}`);
}

renderSwatches('palette-tiles',    TILES,    'tile');
renderSwatches('palette-markers',  MARKERS,  'marker');
renderSwatches('palette-decor',    DECOR,    'decor');
renderSwatches('palette-spawns',   SPAWNS,   'spawn');
renderSwatches('palette-roomtags', ROOMTAGS, 'roomtag');
renderSwatches('palette-traps',    TRAPS,    'trap');
renderSwatches('palette-doors',    DOORS,    'door');
setBrush('tile', 'wall');

// ---- canvas + paint -----------------------------------------------------

function resizeCanvas() {
  canvas.width  = state.w * TILE_PX;
  canvas.height = state.h * TILE_PX;
  draw();
}

function draw() {
  ctx.fillStyle = '#0e0a08';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  // tiles
  for (let y = 0; y < state.h; y++) {
    for (let x = 0; x < state.w; x++) {
      const t = state.grid[y][x];
      const def = TILES.find(d => d.id === t);
      ctx.fillStyle = def ? def.color : '#222';
      ctx.fillRect(x * TILE_PX, y * TILE_PX, TILE_PX, TILE_PX);
    }
  }

  // grid lines
  ctx.strokeStyle = 'rgba(0,0,0,0.25)';
  ctx.lineWidth = 1;
  for (let x = 0; x <= state.w; x++) {
    ctx.beginPath();
    ctx.moveTo(x * TILE_PX, 0); ctx.lineTo(x * TILE_PX, state.h * TILE_PX);
    ctx.stroke();
  }
  for (let y = 0; y <= state.h; y++) {
    ctx.beginPath();
    ctx.moveTo(0, y * TILE_PX); ctx.lineTo(state.w * TILE_PX, y * TILE_PX);
    ctx.stroke();
  }

  // decor
  for (const d of state.decor) drawGlyph(d.x, d.y, d, DECOR);
  // spawns
  for (const s of state.spawns) drawGlyph(s.x, s.y, s, SPAWNS);
  // room-tag intent badges (rendered with .tag instead of .kind)
  for (const r of state.roomTags) drawGlyph(r.x, r.y, { kind: r.tag }, ROOMTAGS);
  // trap glyphs
  for (const t of state.traps) drawGlyph(t.x, t.y, { kind: t.kind }, TRAPS);
  // door glyphs (color is the brush id)
  for (const d of state.doors) drawGlyph(d.x, d.y, { kind: d.color }, DOORS);
  // Scaffold preview: outline each detected room so the author can see what
  // the loader will treat as a room. Only when mode=scaffold; otherwise this
  // would just be visual noise.
  if (state.mode === 'scaffold') drawScaffoldRooms();
  // markers (last so they render on top)
  drawMarker(state.entry, 'entry');
  drawMarker(state.exit,  'exit');
  if (state.chestTile) drawMarker(state.chestTile, 'chestTile');
  for (const sc of state.staircases) drawMarker(sc, 'staircase');

  // Box-paint preview while alt-dragging.
  if (boxAnchor && boxCursor) drawBoxPreview(boxAnchor, boxCursor);

  // Stamp ghost preview — outline the brush at the cursor with a faint
  // floor fill, so you can see where it'll land before clicking.
  if (state.brush.kind === 'stamp' && hoverTile && state.brush.brush) drawStampGhost(hoverTile);

  refreshStats();
}

function drawGlyph(x, y, item, palette) {
  const def = palette.find(d => d.id === item.kind);
  if (!def) return;
  ctx.fillStyle = def.color;
  ctx.fillRect(x * TILE_PX + 3, y * TILE_PX + 3, TILE_PX - 6, TILE_PX - 6);
  ctx.fillStyle = '#fff';
  ctx.font = `bold ${TILE_PX - 8}px monospace`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(def.glyph, x * TILE_PX + TILE_PX / 2, y * TILE_PX + TILE_PX / 2 + 1);
}

function drawMarker(pt, id) {
  if (!pt) return;
  const def = MARKERS.find(m => m.id === id);
  ctx.strokeStyle = def.color;
  ctx.lineWidth = 2;
  ctx.strokeRect(pt.x * TILE_PX + 1, pt.y * TILE_PX + 1, TILE_PX - 2, TILE_PX - 2);
  ctx.fillStyle = def.color;
  ctx.font = `bold ${TILE_PX - 6}px monospace`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(def.glyph, pt.x * TILE_PX + TILE_PX / 2, pt.y * TILE_PX + TILE_PX / 2 + 1);
}

// Stamp ghost preview — paint the brush's floor cells faintly at the
// hover position, with a gold outline so the bounds read clearly. Cells
// that would conflict with existing floor are tinted red.
function drawStampGhost(at) {
  const br = state.brush.brush;
  if (!br) return;
  const sx = at.x, sy = at.y;
  ctx.save();
  for (let dy = 0; dy < br.h; dy++) {
    for (let dx = 0; dx < br.w; dx++) {
      const tx = sx + dx, ty = sy + dy;
      if (!inside(tx, ty)) continue;
      const isFloor = br.grid[dy][dx] === 'floor';
      const conflict = isFloor && state.grid[ty][tx] === 'floor';
      if (!isFloor && !conflict) continue;
      ctx.fillStyle = conflict ? 'rgba(196, 102, 128, 0.35)' : 'rgba(212, 175, 55, 0.30)';
      ctx.fillRect(tx * TILE_PX, ty * TILE_PX, TILE_PX, TILE_PX);
    }
  }
  ctx.strokeStyle = 'rgba(212, 175, 55, 0.85)';
  ctx.lineWidth = 2;
  ctx.strokeRect(sx * TILE_PX + 1, sy * TILE_PX + 1, br.w * TILE_PX - 2, br.h * TILE_PX - 2);
  ctx.restore();
}

// Live preview rect for alt-drag box paint. Tints the area in the brush's
// own color so the user sees what the apply will produce.
function drawBoxPreview(a, b) {
  const x0 = Math.min(a.x, b.x), x1 = Math.max(a.x, b.x);
  const y0 = Math.min(a.y, b.y), y1 = Math.max(a.y, b.y);
  let color = '#ffffff';
  const all = [TILES, MARKERS, DECOR, SPAWNS];
  for (const list of all) {
    const found = list.find(d => d.id === state.brush.id);
    if (found) { color = found.color; break; }
  }
  ctx.save();
  ctx.fillStyle = color + '55';   // ~33% alpha hex
  ctx.fillRect(
    x0 * TILE_PX, y0 * TILE_PX,
    (x1 - x0 + 1) * TILE_PX, (y1 - y0 + 1) * TILE_PX,
  );
  ctx.strokeStyle = color;
  ctx.lineWidth = 2;
  ctx.strokeRect(
    x0 * TILE_PX + 1, y0 * TILE_PX + 1,
    (x1 - x0 + 1) * TILE_PX - 2, (y1 - y0 + 1) * TILE_PX - 2,
  );
  // Dimensions label
  ctx.fillStyle = '#fff';
  ctx.font = `bold ${TILE_PX - 6}px monospace`;
  ctx.textAlign = 'left';
  ctx.textBaseline = 'top';
  ctx.fillText(`${x1 - x0 + 1}×${y1 - y0 + 1}`, x0 * TILE_PX + 4, y0 * TILE_PX + 2);
  ctx.restore();
}

// Scaffold-mode preview: outline each detected room with a faint dashed
// rect + room number, so the author can see what the loader will treat as
// a room before clicking Test. Procgen padding rooms appear at runtime
// only — we don't try to predict them here (RNG is seeded by name+now).
function drawScaffoldRooms() {
  const rooms = detectRooms();
  if (!rooms.length) return;
  ctx.save();
  ctx.strokeStyle = 'rgba(212, 175, 55, 0.55)';   // soft gold, matches --gold token
  ctx.lineWidth = 2;
  ctx.setLineDash([4, 3]);
  for (let i = 0; i < rooms.length; i++) {
    const r = rooms[i];
    ctx.strokeRect(
      r.x * TILE_PX + 1, r.y * TILE_PX + 1,
      r.w * TILE_PX - 2, r.h * TILE_PX - 2,
    );
  }
  ctx.setLineDash([]);
  // Room labels — small index in upper-left of each detected room
  ctx.fillStyle = 'rgba(212, 175, 55, 0.85)';
  ctx.font = `bold ${TILE_PX - 10}px monospace`;
  ctx.textAlign = 'left';
  ctx.textBaseline = 'top';
  for (let i = 0; i < rooms.length; i++) {
    const r = rooms[i];
    ctx.fillText(`r${i}`, r.x * TILE_PX + 4, r.y * TILE_PX + 2);
  }
  ctx.restore();
}

// ---- mouse paint --------------------------------------------------------

let painting = false;
let paintButton = 0;
// Box-paint state: while alt is held during a drag, we don't apply on each
// move — we record the anchor tile and the cursor tile, draw a live preview
// rectangle, and apply on mouseup over the full extent.
let boxAnchor = null;       // { x, y } | null
let boxCursor = null;       // { x, y } | null — last hovered tile during drag
let boxButton = 0;          // mouse button that started the box (0 left, 2 right)
// Last completed alt-drag rectangle bounds — used by "Save brush" to know
// what region to capture. Persists until the next alt-drag.
let lastSelection = null;   // { x0, y0, x1, y1 } | null

function tileAt(ev) {
  const r = canvas.getBoundingClientRect();
  return {
    x: Math.floor((ev.clientX - r.left) / TILE_PX),
    y: Math.floor((ev.clientY - r.top)  / TILE_PX),
  };
}

function applyBrush(x, y, button, shift) {
  if (!inside(x, y)) return;
  const eraseToFloor = button === 2;
  const sample = shift;

  if (sample) {
    // sample: pick whatever's at (x, y) into the brush
    const m = ['entry', 'exit', 'chestTile'].find(id =>
      state[id] && state[id].x === x && state[id].y === y);
    if (m) { setBrush('marker', m); return; }
    if (state.staircases.find(s => s.x === x && s.y === y)) { setBrush('marker', 'staircase'); return; }
    const rt = state.roomTags.find(s => s.x === x && s.y === y);
    if (rt) { setBrush('roomtag', rt.tag); return; }
    const tr = state.traps.find(t => t.x === x && t.y === y);
    if (tr) { setBrush('trap', tr.kind); return; }
    const dr = state.doors.find(d => d.x === x && d.y === y);
    if (dr) { setBrush('door', dr.color); return; }
    const sp = state.spawns.find(s => s.x === x && s.y === y);
    if (sp) { setBrush('spawn', sp.kind); return; }
    const dc = state.decor.find(d => d.x === x && d.y === y);
    if (dc) { setBrush('decor', dc.kind); return; }
    setBrush('tile', state.grid[y][x]);
    return;
  }

  if (eraseToFloor) {
    // right-click also exits stamp mode — back to the wall brush.
    if (state.brush.kind === 'stamp') {
      state.brush = { kind: 'tile', id: 'wall' };
      status('Stamp mode cancelled.');
      return;
    }
    // right-click clears decor / spawns / markers / staircases at this tile
    state.decor      = state.decor.filter(d => !(d.x === x && d.y === y));
    state.spawns     = state.spawns.filter(s => !(s.x === x && s.y === y));
    state.staircases = state.staircases.filter(s => !(s.x === x && s.y === y));
    state.roomTags   = state.roomTags.filter(s => !(s.x === x && s.y === y));
    state.traps      = state.traps.filter(t => !(t.x === x && t.y === y));
    state.doors      = state.doors.filter(d => !(d.x === x && d.y === y));
    if (state.chestTile && state.chestTile.x === x && state.chestTile.y === y) state.chestTile = null;
    state.grid[y][x] = 'floor';
    draw();
    return;
  }

  // Stamp mode: left-click drops the active brush at top-left = (x, y).
  if (state.brush.kind === 'stamp') {
    stampBrushAt(x, y);
    return;
  }

  const b = state.brush;
  if (b.kind === 'tile') {
    state.grid[y][x] = b.id;
  } else if (b.kind === 'marker') {
    if (b.id === 'entry')     state.entry = { x, y };
    if (b.id === 'exit')      state.exit  = { x, y };
    if (b.id === 'chestTile') state.chestTile = { x, y };
    if (b.id === 'staircase') {
      // Prompt for target layout — pick from library if any are saved.
      const lib = readLibrary();
      const names = Object.keys(lib);
      const hint = names.length
        ? `Target layout name (saved: ${names.slice(0, 6).join(', ')}${names.length > 6 ? '…' : ''}):`
        : 'Target layout name (no saved layouts yet — save one first, then come back):';
      const existing = state.staircases.find(s => s.x === x && s.y === y);
      const target = prompt(hint, existing?.target || (names[0] || ''));
      if (target == null) return;        // cancelled
      state.staircases = state.staircases.filter(s => !(s.x === x && s.y === y));
      if (target.trim()) state.staircases.push({ x, y, target: target.trim() });
    }
    // markers force the underlying tile to floor so the player can stand there
    state.grid[y][x] = 'floor';
  } else if (b.kind === 'decor') {
    // replace any existing decor on this tile, then add
    state.decor = state.decor.filter(d => !(d.x === x && d.y === y));
    state.decor.push({ kind: b.id, x, y });
    state.grid[y][x] = 'floor';
  } else if (b.kind === 'spawn') {
    state.spawns = state.spawns.filter(s => !(s.x === x && s.y === y));
    state.spawns.push({ kind: b.id, x, y });
    state.grid[y][x] = 'floor';
  } else if (b.kind === 'roomtag') {
    // One tag per tile; loader looks up the containing room at scaffold time.
    state.roomTags = state.roomTags.filter(s => !(s.x === x && s.y === y));
    state.roomTags.push({ tag: b.id, x, y });
    state.grid[y][x] = 'floor';
  } else if (b.kind === 'trap') {
    state.traps = state.traps.filter(t => !(t.x === x && t.y === y));
    state.traps.push({ kind: b.id, x, y });
    state.grid[y][x] = 'floor';
  } else if (b.kind === 'door') {
    state.doors = state.doors.filter(d => !(d.x === x && d.y === y));
    state.doors.push({ color: b.id, locked: true, x, y });
    state.grid[y][x] = 'floor';
  }
  draw();
}

canvas.addEventListener('mousedown', ev => {
  ev.preventDefault();
  const { x, y } = tileAt(ev);
  if (ev.altKey && inside(x, y)) {
    // Begin box-paint — defer the actual painting to mouseup.
    boxAnchor = { x, y };
    boxCursor = { x, y };
    boxButton = ev.button;
    draw();
    return;
  }
  painting = true;
  paintButton = ev.button;
  applyBrush(x, y, ev.button, ev.shiftKey);
});
window.addEventListener('mouseup', ev => {
  if (boxAnchor && boxCursor) {
    lastSelection = {
      x0: Math.min(boxAnchor.x, boxCursor.x),
      y0: Math.min(boxAnchor.y, boxCursor.y),
      x1: Math.max(boxAnchor.x, boxCursor.x),
      y1: Math.max(boxAnchor.y, boxCursor.y),
    };
    applyBoxBrush(boxAnchor, boxCursor, boxButton, ev.shiftKey);
    boxAnchor = boxCursor = null;
    draw();
  }
  painting = false;
});
let hoverTile = null;       // { x, y } — for stamp ghost preview
canvas.addEventListener('mousemove', ev => {
  const { x, y } = tileAt(ev);
  if (inside(x, y)) status(`(${x}, ${y})`);
  if (boxAnchor) {
    if (inside(x, y)) {
      boxCursor = { x, y };
      draw();
    }
    return;
  }
  if (state.brush.kind === 'stamp') {
    if (inside(x, y) && (!hoverTile || hoverTile.x !== x || hoverTile.y !== y)) {
      hoverTile = { x, y };
      draw();
    }
    return;
  }
  hoverTile = null;
  if (!painting) return;
  applyBrush(x, y, paintButton, ev.shiftKey);
});
canvas.addEventListener('mouseleave', () => {
  if (hoverTile) { hoverTile = null; draw(); }
});
canvas.addEventListener('contextmenu', ev => ev.preventDefault());

// Paint the current brush across every tile in the rectangle defined by
// (a, b). Markers are single-instance so we only place one at the b corner;
// every other brush kind iterates the whole rect.
function applyBoxBrush(a, b, button, shift) {
  const x0 = Math.min(a.x, b.x), x1 = Math.max(a.x, b.x);
  const y0 = Math.min(a.y, b.y), y1 = Math.max(a.y, b.y);
  if (state.brush.kind === 'marker') {
    applyBrush(b.x, b.y, button, shift);
    return;
  }
  for (let y = y0; y <= y1; y++) {
    for (let x = x0; x <= x1; x++) applyBrushNoDraw(x, y, button, shift);
  }
  draw();
}

// Same as applyBrush but doesn't redraw — caller redraws once at the end.
// applyBrush itself already calls draw() per-tile, which we don't want
// firing thousands of times for a 30×30 box-paint.
function applyBrushNoDraw(x, y, button, shift) {
  if (!inside(x, y)) return;
  const eraseToFloor = button === 2;
  if (shift) return;   // sample-mode is meaningless for box; ignore
  if (eraseToFloor) {
    state.decor      = state.decor.filter(d => !(d.x === x && d.y === y));
    state.spawns     = state.spawns.filter(s => !(s.x === x && s.y === y));
    state.staircases = state.staircases.filter(s => !(s.x === x && s.y === y));
    state.roomTags   = state.roomTags.filter(s => !(s.x === x && s.y === y));
    state.traps      = state.traps.filter(t => !(t.x === x && t.y === y));
    state.doors      = state.doors.filter(d => !(d.x === x && d.y === y));
    if (state.chestTile && state.chestTile.x === x && state.chestTile.y === y) state.chestTile = null;
    state.grid[y][x] = 'floor';
    return;
  }
  const b = state.brush;
  if (b.kind === 'tile') {
    state.grid[y][x] = b.id;
  } else if (b.kind === 'decor') {
    state.decor = state.decor.filter(d => !(d.x === x && d.y === y));
    state.decor.push({ kind: b.id, x, y });
    state.grid[y][x] = 'floor';
  } else if (b.kind === 'spawn') {
    state.spawns = state.spawns.filter(s => !(s.x === x && s.y === y));
    state.spawns.push({ kind: b.id, x, y });
    state.grid[y][x] = 'floor';
  } else if (b.kind === 'roomtag') {
    state.roomTags = state.roomTags.filter(s => !(s.x === x && s.y === y));
    state.roomTags.push({ tag: b.id, x, y });
    state.grid[y][x] = 'floor';
  } else if (b.kind === 'trap') {
    state.traps = state.traps.filter(t => !(t.x === x && t.y === y));
    state.traps.push({ kind: b.id, x, y });
    state.grid[y][x] = 'floor';
  } else if (b.kind === 'door') {
    state.doors = state.doors.filter(d => !(d.x === x && d.y === y));
    state.doors.push({ color: b.id, locked: true, x, y });
    state.grid[y][x] = 'floor';
  }
  // Skip 'marker' here — box paint of markers is handled at the caller level.
}

// ---- top bar actions ----------------------------------------------------

document.getElementById('btn-new').addEventListener('click', () => {
  state.grid = newGrid(state.w, state.h, 'wall');
  state.decor = [];
  state.spawns = [];
  state.staircases = [];
  state.roomTags = [];
  state.traps = [];
  state.doors = [];
  state.entry = { x: 3, y: 3 };
  state.exit  = { x: state.w - 4, y: state.h - 4 };
  state.chestTile = null;
  draw();
  syncJsonPane();
  status('Cleared.');
});
document.getElementById('btn-fill-walls').addEventListener('click', () => {
  state.grid = newGrid(state.w, state.h, 'wall');
  draw();
  status('Walls reset.');
});

// 3D preview — runs the actual game render path on the current state so
// you see what index.html would draw. Toggling re-snapshots the state;
// in-overlay Refresh re-snapshots without losing camera position.
let _previewOn = false;
let _previewBusy = false;
document.getElementById('btn-3d').addEventListener('click', async () => {
  if (_previewBusy) return;
  _previewBusy = true;
  try {
    const mod = await import('./preview3d.js');
    if (_previewOn) {
      mod.hide3DPreview();
      _previewOn = false;
      document.getElementById('btn-3d').classList.remove('on');
      status('Back to paint mode.');
    } else {
      await mod.show3DPreview(state);
      _previewOn = true;
      document.getElementById('btn-3d').classList.add('on');
      status('3D preview · drag to rotate, scroll to zoom · Refresh to re-roll procgen · click 3D preview again to return.');
    }
  } catch (e) {
    status('3D preview failed: ' + (e.message || e));
    console.error(e);
  } finally {
    _previewBusy = false;
  }
});
document.getElementById('btn-3d-refresh').addEventListener('click', async () => {
  const mod = await import('./preview3d.js');
  // Push the latest state through and re-roll procgen.
  await mod.show3DPreview(state);
  status('3D preview refreshed.');
});
document.getElementById('btn-export').addEventListener('click', () => {
  syncJsonPane();
  jsonPane.select();
  navigator.clipboard?.writeText(jsonPane.value);
  status('Exported to clipboard.');
});
document.getElementById('btn-test').addEventListener('click', () => testInGame());
document.getElementById('btn-save-test').addEventListener('click', () => {
  saveCurrent();
  testInGame();
});

// Validate the layout, write to the test slot, and open the game in a new
// tab. Reused by both Test and Save & Test.
function testInGame() {
  const json = toJson();
  // Authored: must be reachable. Scaffold: procgen carves corridors, so
  // disconnected rooms are fine — but we still need at least 2 rooms.
  if (state.mode === 'authored' && !reachableFloor()) {
    status('Entry → exit not reachable. Fix the layout before testing.');
    return;
  }
  if (state.mode === 'scaffold' && detectRooms().length < 2) {
    status('Scaffold needs at least 2 rooms to connect.');
    return;
  }
  try {
    localStorage.setItem('gj26.authored_dungeon', JSON.stringify(json));
  } catch (e) {
    status('localStorage write failed: ' + e.message);
    return;
  }
  status('Launching test in new tab…');
  window.open('index.html#authored', '_blank');
}
document.getElementById('btn-import').addEventListener('click', () => {
  const txt = prompt('Paste dungeon JSON:');
  if (txt) applyJsonText(txt);
});
document.getElementById('btn-save').addEventListener('click', saveCurrent);
document.getElementById('btn-load').addEventListener('click', openLoadPicker);
document.getElementById('library-close').addEventListener('click', () => {
  document.getElementById('library-modal').style.display = 'none';
});

// ---- layout library (multi-slot localStorage) -------------------------
// Storage shape: gj26.dungeon_library = { [name]: { savedAt, json } }
// Distinct from gj26.authored_dungeon (the single "currently testing"
// slot the game reads on boot).

const LIB_KEY = 'gj26.dungeon_library';

function readLibrary() {
  try {
    const raw = localStorage.getItem(LIB_KEY);
    if (!raw) return {};
    const obj = JSON.parse(raw);
    return obj && typeof obj === 'object' ? obj : {};
  } catch (_) { return {}; }
}
function writeLibrary(lib) {
  try { localStorage.setItem(LIB_KEY, JSON.stringify(lib)); }
  catch (e) { status('Library save failed: ' + e.message); }
}

function saveCurrent() {
  const json = toJson();
  const name = (state.name || '').trim();
  if (!name || name === 'untitled-dungeon') {
    const proposed = prompt('Name this layout:', 'my-dungeon');
    if (!proposed) return;
    state.name = proposed;
    document.getElementById('prop-name').value = proposed;
    json.name = proposed;
  }
  const lib = readLibrary();
  lib[json.name] = { savedAt: Date.now(), json };
  writeLibrary(lib);
  status(`Saved "${json.name}".`);
}

function openLoadPicker() {
  const lib = readLibrary();
  const list = document.getElementById('library-list');
  const entries = Object.entries(lib).sort((a, b) => (b[1].savedAt || 0) - (a[1].savedAt || 0));
  if (!entries.length) {
    list.innerHTML = `<div style="color:var(--text-dim); padding:8px;">No saved layouts yet. Click <b>Save</b> to add the current one.</div>`;
  } else {
    list.innerHTML = '';
    for (const [name, rec] of entries) {
      const j = rec.json || {};
      const when = rec.savedAt ? new Date(rec.savedAt).toLocaleString() : '?';
      const dims = j.size ? `${j.size.w}×${j.size.h}` : '?';
      const isCurrent = name === state.name;
      const row = document.createElement('div');
      row.style.cssText = isCurrent
        ? 'display:flex; align-items:center; gap:8px; padding:6px 8px; border:1px solid var(--gold,#d4af37); border-radius:2px; background:rgba(212,175,55,0.08);'
        : 'display:flex; align-items:center; gap:8px; padding:6px 8px; border:1px solid var(--border); border-radius:2px;';
      row.innerHTML = `
        <div style="flex:1;">
          <div>
            <b>${escapeHtml(name)}</b>
            ${isCurrent ? '<span style="color:var(--gold,#d4af37); font-size:11px; margin-left:6px;">● open in editor</span>' : ''}
            <span style="color:var(--text-dim); font-size:11px;">${escapeHtml(j.scope || '')} · ${escapeHtml(j.mode || 'authored')} · ${dims}</span>
          </div>
          <div style="color:var(--text-dim); font-size:11px;">${when}</div>
        </div>
        <button data-act="load">${isCurrent ? 'Reload' : 'Load'}</button>
        <button data-act="delete" style="border-color:#c46680; color:#c46680;">Delete</button>
      `;
      row.querySelector('[data-act="load"]').addEventListener('click', () => {
        applyJsonText(JSON.stringify(j));
        document.getElementById('library-modal').style.display = 'none';
        status(`Loaded "${name}".`);
      });
      row.querySelector('[data-act="delete"]').addEventListener('click', () => {
        if (!confirm(`Delete "${name}"?`)) return;
        const next = readLibrary();
        delete next[name];
        writeLibrary(next);
        openLoadPicker();   // refresh
      });
      list.appendChild(row);
    }
  }
  document.getElementById('library-modal').style.display = 'flex';
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"]/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;' }[c]));
}

// ---- brush library (Stage C, half 1) ----------------------------------
// A brush = small rectangular prefab the author can stamp anywhere. Stored
// separately from layouts because brushes are stamps, not playable levels.
// Schema: gj26.dungeon_brushes = { [name]: { savedAt, brush } }
//   brush = { name, w, h, grid, decor, spawns, roomTags, scope }
// Coordinates inside the brush are 0-indexed from the brush's top-left.

const BRUSH_KEY = 'gj26.dungeon_brushes';

function readBrushes() {
  try {
    const raw = localStorage.getItem(BRUSH_KEY);
    if (!raw) return {};
    const obj = JSON.parse(raw);
    return obj && typeof obj === 'object' ? obj : {};
  } catch (_) { return {}; }
}
function writeBrushes(b) {
  try { localStorage.setItem(BRUSH_KEY, JSON.stringify(b)); }
  catch (e) { status('Brush save failed: ' + e.message); }
}

document.getElementById('btn-save-brush').addEventListener('click', saveSelectionAsBrush);
document.getElementById('btn-brushes').addEventListener('click', openBrushesPicker);
document.getElementById('brushes-close').addEventListener('click', () => {
  document.getElementById('brushes-modal').style.display = 'none';
});

function saveSelectionAsBrush() {
  if (!lastSelection) {
    status('Alt-drag a rectangle first to define the brush area.');
    return;
  }
  const { x0, y0, x1, y1 } = lastSelection;
  const w = x1 - x0 + 1, h = y1 - y0 + 1;
  // Snapshot grid + objects in the rectangle, translated to brush-local
  // coordinates (0,0 = top-left of the brush).
  const grid = [];
  for (let y = y0; y <= y1; y++) {
    grid.push(state.grid[y].slice(x0, x1 + 1));
  }
  const inRect = (a) => a.x >= x0 && a.x <= x1 && a.y >= y0 && a.y <= y1;
  const localize = (arr) => arr.filter(inRect).map(a => ({ ...a, x: a.x - x0, y: a.y - y0 }));
  const name = (prompt('Brush name:', 'unnamed-brush') || '').trim();
  if (!name) return;
  const brush = {
    name, w, h, grid,
    decor:    localize(state.decor),
    spawns:   localize(state.spawns),
    roomTags: localize(state.roomTags),
    traps:    localize(state.traps),
    doors:    localize(state.doors),
    scope:    state.scope,
  };
  const lib = readBrushes();
  lib[name] = { savedAt: Date.now(), brush };
  writeBrushes(lib);
  status(`Saved brush "${name}" (${w}×${h})`);
}

function openBrushesPicker() {
  const lib = readBrushes();
  const list = document.getElementById('brushes-list');
  const entries = Object.entries(lib).sort((a, b) => (b[1].savedAt || 0) - (a[1].savedAt || 0));
  if (!entries.length) {
    list.innerHTML = `<div style="color:var(--text-dim); padding:8px;">
      No brushes saved yet. Alt-drag a rectangle, then click <b>Save brush</b>.
    </div>`;
  } else {
    list.innerHTML = '';
    for (const [name, rec] of entries) {
      const br = rec.brush || {};
      const when = rec.savedAt ? new Date(rec.savedAt).toLocaleString() : '?';
      const isActive = state.brush.kind === 'stamp' && state.brush.id === name;
      const row = document.createElement('div');
      row.style.cssText = isActive
        ? 'display:flex; align-items:center; gap:8px; padding:6px 8px; border:1px solid var(--gold,#d4af37); border-radius:2px; background:rgba(212,175,55,0.08);'
        : 'display:flex; align-items:center; gap:8px; padding:6px 8px; border:1px solid var(--border); border-radius:2px;';
      row.innerHTML = `
        <div style="flex:1;">
          <div>
            <b>${escapeHtml(name)}</b>
            ${isActive ? '<span style="color:var(--gold,#d4af37); font-size:11px; margin-left:6px;">● active brush</span>' : ''}
            <span style="color:var(--text-dim); font-size:11px;">${escapeHtml(br.scope || '')} · ${br.w}×${br.h} · decor ${(br.decor||[]).length} · spawns ${(br.spawns||[]).length}</span>
          </div>
          <div style="color:var(--text-dim); font-size:11px;">${when}</div>
        </div>
        <button data-act="use">${isActive ? 'In use' : 'Use'}</button>
        <button data-act="delete" style="border-color:#c46680; color:#c46680;">Delete</button>
      `;
      row.querySelector('[data-act="use"]').addEventListener('click', () => {
        state.brush = { kind: 'stamp', id: name, brush: br };
        for (const sw of document.querySelectorAll('.swatch')) sw.classList.remove('active');
        document.getElementById('brushes-modal').style.display = 'none';
        status(`Brush: stamp/${name} · left-click to stamp at cursor`);
      });
      row.querySelector('[data-act="delete"]').addEventListener('click', () => {
        if (!confirm(`Delete brush "${name}"?`)) return;
        const next = readBrushes();
        delete next[name];
        writeBrushes(next);
        openBrushesPicker();
      });
      list.appendChild(row);
    }
  }
  document.getElementById('brushes-modal').style.display = 'flex';
}

// Stamp the active brush at top-left = (sx, sy). Cells where state.grid is
// already 'floor' are skipped (non-overlapping). Decor / spawns / roomTags
// are translated to absolute coords and skipped if their target cell wasn't
// successfully carved.
function stampBrushAt(sx, sy) {
  if (state.brush.kind !== 'stamp' || !state.brush.brush) return;
  const br = state.brush.brush;
  for (let dy = 0; dy < br.h; dy++) {
    for (let dx = 0; dx < br.w; dx++) {
      const tx = sx + dx, ty = sy + dy;
      if (!inside(tx, ty)) continue;
      // Non-overlap rule: leave existing floor alone (don't overwrite an
      // adjacent room with brush walls).
      if (state.grid[ty][tx] === 'floor') continue;
      if (br.grid[dy][dx] === 'floor') state.grid[ty][tx] = 'floor';
    }
  }
  const stampObj = (arr, dest, key = 'kind') => {
    for (const a of arr || []) {
      const tx = sx + a.x, ty = sy + a.y;
      if (!inside(tx, ty)) continue;
      if (state.grid[ty][tx] !== 'floor') continue;
      // Replace any existing object at this tile with the brush's version.
      const idx = dest.findIndex(e => e.x === tx && e.y === ty);
      if (idx >= 0) dest.splice(idx, 1);
      dest.push({ ...a, x: tx, y: ty });
    }
  };
  stampObj(br.decor,    state.decor);
  stampObj(br.spawns,   state.spawns);
  stampObj(br.roomTags, state.roomTags, 'tag');
  stampObj(br.traps,    state.traps);
  stampObj(br.doors,    state.doors);
  draw();
}

// ---- keyboard shortcuts ------------------------------------------------
// Cmd/Ctrl+S      → Save
// Cmd/Ctrl+Enter  → Save & Test
// 1..4            → switch brush category (defaults to its first item)
// W / F           → wall / floor brush directly
//
// Suppressed when a text input or textarea has focus so name editing and
// JSON paste still work normally.
window.addEventListener('keydown', ev => {
  const t = ev.target;
  if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return;

  const mod = ev.metaKey || ev.ctrlKey;
  if (mod && ev.key === 's') {
    ev.preventDefault();
    saveCurrent();
    return;
  }
  if (mod && ev.key === 'Enter') {
    ev.preventDefault();
    saveCurrent();
    testInGame();
    return;
  }
  if (mod) return;   // anything else with mod we leave to the browser

  // Brush-category shortcuts. Pick the first item in the category if the
  // current brush isn't already in it; otherwise rotate through the list.
  const CAT_ITEMS = { tile: TILES, marker: MARKERS, decor: DECOR, spawn: SPAWNS };
  const CAT_BY_KEY = { '1': 'tile', '2': 'marker', '3': 'decor', '4': 'spawn' };
  const cat = CAT_BY_KEY[ev.key];
  if (cat) {
    ev.preventDefault();
    const items = CAT_ITEMS[cat];
    if (state.brush.kind === cat) {
      const i = items.findIndex(it => it.id === state.brush.id);
      const next = items[(i + 1) % items.length];
      setBrush(cat, next.id);
    } else {
      setBrush(cat, items[0].id);
    }
    return;
  }
  // W / F direct wall / floor brush.
  if (ev.key === 'w' || ev.key === 'W') { ev.preventDefault(); setBrush('tile', 'wall');  return; }
  if (ev.key === 'f' || ev.key === 'F') { ev.preventDefault(); setBrush('tile', 'floor'); return; }
});
document.getElementById('btn-apply-json').addEventListener('click', () => applyJsonText(jsonPane.value));
document.getElementById('btn-copy-json').addEventListener('click', () => {
  syncJsonPane();
  navigator.clipboard?.writeText(jsonPane.value);
  status('Copied JSON.');
});

// ---- inspector bindings -------------------------------------------------

document.getElementById('prop-name').addEventListener('input', e => { state.name = e.target.value; });
document.getElementById('prop-scope').addEventListener('change', e => { state.scope = e.target.value; });
document.getElementById('prop-mode').addEventListener('change', e => {
  state.mode = e.target.value;
  refreshPaddingRowVisibility();
  draw();
});
document.getElementById('prop-padding').addEventListener('change', e => { state.procgenPadding = e.target.checked; });
document.getElementById('prop-usebrushes').addEventListener('change', e => { state.useBrushes = e.target.checked; });

function refreshPaddingRowVisibility() {
  const padding = document.getElementById('prop-padding-row');
  const useBrush = document.getElementById('prop-usebrushes-row');
  const show = state.mode === 'scaffold' ? '' : 'none';
  if (padding)  padding.style.display  = show;
  if (useBrush) useBrush.style.display = show;
}
document.getElementById('prop-boss').addEventListener('change', e => { state.bossKind = e.target.value; });
document.getElementById('prop-tier').addEventListener('change', e => { state.tier = +e.target.value || 1; });
document.getElementById('prop-rune').addEventListener('change', e => { state.runeEffect = e.target.value; });
document.getElementById('prop-seed').addEventListener('input',  e => { state.seed = e.target.value.trim(); });

// Render the affix checkbox list once. Each row is a label+checkbox.
function renderAffixList() {
  const root = document.getElementById('prop-affixes');
  if (!root) return;
  root.innerHTML = '';
  for (const [id, label] of Object.entries(AFFIX_DEFS)) {
    const row = document.createElement('label');
    row.style.cssText = 'display:flex; gap:4px; align-items:center;';
    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.dataset.affixId = id;
    cb.checked = state.affixIds.includes(id);
    cb.addEventListener('change', () => {
      if (cb.checked) {
        if (!state.affixIds.includes(id)) state.affixIds.push(id);
      } else {
        state.affixIds = state.affixIds.filter(x => x !== id);
      }
    });
    row.appendChild(cb);
    const span = document.createElement('span');
    span.textContent = ' ' + label;
    row.appendChild(span);
    root.appendChild(row);
  }
}
renderAffixList();
document.getElementById('prop-w').addEventListener('change', e => { resizeBoard(+e.target.value, state.h); });
document.getElementById('prop-h').addEventListener('change', e => { resizeBoard(state.w, +e.target.value); });

function resizeBoard(w, h) {
  w = Math.max(6, Math.min(64, w));
  h = Math.max(6, Math.min(64, h));
  const old = state.grid;
  state.w = w; state.h = h;
  state.grid = newGrid(w, h, 'wall');
  for (let y = 0; y < Math.min(old.length, h); y++) {
    for (let x = 0; x < Math.min(old[0]?.length || 0, w); x++) {
      state.grid[y][x] = old[y][x];
    }
  }
  state.decor      = state.decor.filter(d => inside(d.x, d.y));
  state.spawns     = state.spawns.filter(s => inside(s.x, s.y));
  state.staircases = state.staircases.filter(s => inside(s.x, s.y));
  state.roomTags   = state.roomTags.filter(s => inside(s.x, s.y));
  state.traps      = state.traps.filter(t => inside(t.x, t.y));
  state.doors      = state.doors.filter(d => inside(d.x, d.y));
  if (!inside(state.entry.x, state.entry.y))     state.entry = { x: 3, y: 3 };
  if (!inside(state.exit.x, state.exit.y))       state.exit  = { x: w - 4, y: h - 4 };
  if (state.chestTile && !inside(state.chestTile.x, state.chestTile.y)) state.chestTile = null;
  resizeCanvas();
}

// ---- JSON serialization -------------------------------------------------

function toJson() {
  // When useBrushes is on, embed a snapshot of the current brush library
  // so the saved/tested JSON is self-contained. Without this, sharing a
  // layout would require sharing the user's localStorage too.
  const embeddedBrushes = state.useBrushes
    ? Object.values(readBrushes())
        .map(rec => rec.brush)
        .filter(b => b && Array.isArray(b.grid))
    : null;
  return {
    name: state.name,
    scope: state.scope,
    mode: state.mode,
    procgenPadding: state.procgenPadding,
    useBrushes: state.useBrushes,
    brushes: embeddedBrushes,
    size: { w: state.w, h: state.h },
    grid: state.grid,
    entry: state.entry,
    exit: state.exit,
    chestTile: state.chestTile,
    decor: state.decor,
    spawns: state.spawns,
    staircases: state.staircases,
    roomTags: state.roomTags,
    traps: state.traps,
    doors: state.doors,
    bossKind: state.bossKind || null,
    procgen: {
      tier: state.tier,
      runeEffect: state.runeEffect || null,
      seed: state.seed || null,
      affixIds: state.affixIds.slice(),
    },
  };
}

function syncJsonPane() {
  jsonPane.value = JSON.stringify(toJson(), null, 2);
}

function applyJsonText(txt) {
  let parsed;
  try { parsed = JSON.parse(txt); }
  catch (e) { status('JSON parse error: ' + e.message); return; }
  if (!parsed || !Array.isArray(parsed.grid)) { status('Bad JSON shape.'); return; }
  state.name = parsed.name || 'imported';
  state.scope = parsed.scope || 'briar_maze';
  state.mode = parsed.mode === 'scaffold' ? 'scaffold' : 'authored';
  state.procgenPadding = parsed.procgenPadding !== false;
  state.useBrushes     = parsed.useBrushes === true;
  state.w = parsed.size?.w || parsed.grid[0].length;
  state.h = parsed.size?.h || parsed.grid.length;
  state.grid = parsed.grid;
  state.entry = parsed.entry || { x: 1, y: 1 };
  state.exit  = parsed.exit  || { x: state.w - 2, y: state.h - 2 };
  state.chestTile = parsed.chestTile || null;
  state.decor      = Array.isArray(parsed.decor)      ? parsed.decor      : [];
  state.spawns     = Array.isArray(parsed.spawns)     ? parsed.spawns     : [];
  state.staircases = Array.isArray(parsed.staircases) ? parsed.staircases : [];
  state.roomTags   = Array.isArray(parsed.roomTags)   ? parsed.roomTags   : [];
  state.traps      = Array.isArray(parsed.traps)      ? parsed.traps      : [];
  state.doors      = Array.isArray(parsed.doors)      ? parsed.doors      : [];
  state.bossKind = parsed.bossKind || '';
  const pg = parsed.procgen || {};
  state.tier       = +pg.tier || 1;
  state.runeEffect = pg.runeEffect || '';
  state.seed       = pg.seed || '';
  state.affixIds   = Array.isArray(pg.affixIds) ? pg.affixIds.slice() : [];
  document.getElementById('prop-name').value  = state.name;
  document.getElementById('prop-scope').value = state.scope;
  document.getElementById('prop-mode').value  = state.mode;
  document.getElementById('prop-padding').checked = state.procgenPadding;
  document.getElementById('prop-usebrushes').checked = state.useBrushes;
  refreshPaddingRowVisibility();
  document.getElementById('prop-w').value     = state.w;
  document.getElementById('prop-h').value     = state.h;
  document.getElementById('prop-boss').value  = state.bossKind;
  document.getElementById('prop-tier').value  = String(state.tier || 1);
  document.getElementById('prop-rune').value  = state.runeEffect || '';
  document.getElementById('prop-seed').value  = state.seed || '';
  renderAffixList();   // re-render so checkboxes reflect imported affixIds
  resizeCanvas();
  status('Imported.');
}

// ---- stats panel --------------------------------------------------------

function refreshStats() {
  let floor = 0, wall = 0;
  for (const row of state.grid) for (const t of row) (t === 'floor' ? floor++ : wall++);
  const rooms = state.mode === 'scaffold' ? detectRooms() : null;
  const reachable = state.mode === 'scaffold' ? true : reachableFloor();
  statsEl.innerHTML = `
    <div>Mode: <b>${state.mode}</b></div>
    <div>Tiles: ${state.w}×${state.h} = ${state.w * state.h}</div>
    <div>Floor: ${floor} · Wall: ${wall}</div>
    <div>Decor: ${state.decor.length} · Spawns: ${state.spawns.length}</div>
    ${rooms ? `<div>Detected rooms: ${rooms.length}</div>` : ''}
    <div>Entry → Exit ${state.mode === 'scaffold' ? '(procgen will connect)' : 'reachable'}: ${reachable ? 'yes' : '<span style="color:#c46680">NO</span>'}</div>
  `;
}

// Same flood-fill the runtime uses, for the editor's stats preview + the
// scaffold-mode room outline overlay. Returns bounding boxes so the canvas
// can draw a rect around each detected room.
function detectRooms() {
  const seen = Array.from({ length: state.h }, () => Array(state.w).fill(false));
  const rooms = [];
  for (let y = 0; y < state.h; y++) {
    for (let x = 0; x < state.w; x++) {
      if (state.grid[y][x] !== 'floor' || seen[y][x]) continue;
      const q = [[x, y]];
      seen[y][x] = true;
      let cells = 0, minX = x, maxX = x, minY = y, maxY = y;
      while (q.length) {
        const [cx, cy] = q.pop();
        cells++;
        if (cx < minX) minX = cx;
        if (cx > maxX) maxX = cx;
        if (cy < minY) minY = cy;
        if (cy > maxY) maxY = cy;
        for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
          const nx = cx + dx, ny = cy + dy;
          if (nx<0||ny<0||nx>=state.w||ny>=state.h||seen[ny][nx]) continue;
          if (state.grid[ny][nx] !== 'floor') continue;
          seen[ny][nx] = true;
          q.push([nx, ny]);
        }
      }
      if (cells >= 4) {
        rooms.push({
          x: minX, y: minY,
          w: maxX - minX + 1, h: maxY - minY + 1,
          cells,
        });
      }
    }
  }
  return rooms;
}

// BFS from entry over floor tiles. Returns true if exit is reachable.
function reachableFloor() {
  const seen = Array.from({ length: state.h }, () => Array(state.w).fill(false));
  const q = [state.entry];
  seen[state.entry.y][state.entry.x] = true;
  while (q.length) {
    const { x, y } = q.shift();
    if (x === state.exit.x && y === state.exit.y) return true;
    for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
      const nx = x + dx, ny = y + dy;
      if (!inside(nx, ny) || seen[ny][nx]) continue;
      if (state.grid[ny][nx] !== 'floor') continue;
      seen[ny][nx] = true;
      q.push({ x: nx, y: ny });
    }
  }
  return false;
}

function status(msg) { statusEl.textContent = msg; }

// ---- boot ---------------------------------------------------------------

state.grid = newGrid(state.w, state.h, 'wall');
// seed with a small starter room so the canvas isn't a black wall
for (let y = 2; y < 8; y++) for (let x = 2; x < 8; x++) state.grid[y][x] = 'floor';
resizeCanvas();
syncJsonPane();
refreshPaddingRowVisibility();
status('Ready. Pick a brush and click to paint.');
