// Procedural dungeon — first slice of the "Bramblewood Charters" pivot.
//
// What this does today (V1):
//   - Carve a small grid of rooms + corridors (rooms-and-corridors algorithm)
//   - Place an entry stair, an exit stair (currently a portal back to village)
//   - Spawn a handful of bramble-imps + an optional bramble-cap
//   - Walls + floor reuse the existing buildStoneWallTile / buildWoodFloorTile
//
// What this does NOT do yet (planned, see WORLD_BIBLE.md / loop comments):
//   - Multiple floors / staircase down
//   - Affixes (Tyrannical / Bursting / etc — Mythic+ overlay)
//   - Boss rooms / treasure rooms
//   - Themed sub-dungeons (Hollow / Sunken Hut / Hedgemother's Den)
//   - Heirloom retirement
//
// The dungeon shares the main three.js Scene with the overworld; we toggle
// visibility instead of swapping scenes (simpler save/load story for V1).

import * as THREE from 'three';
import { buildStoneWallTile, buildWoodFloorTile } from './characters.js';
import { pickRandomLoreParchment } from '../data/items.js';
import { rollChest } from '../data/lootTables.js';
import { placeById } from '../data/echo-places.js';

const ROOM_MIN = 4, ROOM_MAX = 7;
const GRID = 22;          // dungeon side, in tiles

/**
 * Echo layout — read a chunk of the live overworld around an anchor tile
 * and produce a dungeon layout that mirrors its walkable shape. Tile
 * mapping: walkable → 'floor', blocked (wall/water/tree) → 'wall'. Entry
 * is the center of the snapshot; exit + chest land on the far edge.
 *
 * @param {object} world      — World instance with tileGrid + blocked
 * @param {string} scope      — echo place id (e.g. 'echo_village')
 * @param {object} anchor     — { x, y } the center tile in world coords
 * @param {Array}  affixes    — same affix list as procgen layouts
 */
export function generateEchoLayout(world, scope, anchor, affixes = []) {
  const place = placeById(scope);
  if (!place) throw new Error(`generateEchoLayout: unknown scope ${scope}`);
  const radius = place.radius;
  const size = radius * 2 + 3;       // +3 = 1 padding ring + center

  const grid = Array.from({ length: size }, () => Array(size).fill('wall'));
  const offsetX = anchor.x - radius - 1;
  const offsetY = anchor.y - radius - 1;
  const COLS = world.tileGrid[0]?.length || 0;
  const ROWS = world.tileGrid.length;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const wx = x + offsetX;
      const wy = y + offsetY;
      if (wx < 0 || wy < 0 || wx >= COLS || wy >= ROWS) continue;
      grid[y][x] = world.blocked[wy][wx] ? 'wall' : 'floor';
    }
  }

  // Entry: floor tile nearest the snapshot center (so the player wakes
  // up "at the heart" of the echoed place).
  const cx = radius + 1, cy = radius + 1;
  const entry = nearestFloor(grid, cx, cy);

  // Exit: floor tile on the far edge from entry. We try the four corners
  // and keep the first walkable one.
  const candidates = [
    { x: 1,        y: 1 },
    { x: size - 2, y: 1 },
    { x: 1,        y: size - 2 },
    { x: size - 2, y: size - 2 },
  ];
  let exit = null;
  for (const c of candidates) {
    const f = nearestFloor(grid, c.x, c.y);
    if (f && (f.x !== entry.x || f.y !== entry.y)) { exit = f; break; }
  }
  if (!exit) exit = entry;
  grid[entry.y][entry.x] = 'floor';
  grid[exit.y][exit.x]   = 'floor';

  // Chest sits one tile in front of the exit if possible.
  let chestTile = null;
  for (const [dx, dy] of [[0,-1],[0,1],[-1,0],[1,0]]) {
    const tx = exit.x + dx, ty = exit.y + dy;
    if (tx < 0 || ty < 0 || tx >= size || ty >= size) continue;
    if (grid[ty][tx] === 'floor' && !(tx === entry.x && ty === entry.y)) {
      chestTile = { x: tx, y: ty }; break;
    }
  }
  if (!chestTile) chestTile = { x: exit.x, y: exit.y };

  // Hostile spawns. Distribute across floor tiles avoiding entry/exit/chest.
  // Authored-spawn shape matches the editor's so loadAuthoredLayout users
  // and main.js's enterDungeon both consume it.
  const reservedKeys = new Set([
    entry.x + ',' + entry.y,
    exit.x + ',' + exit.y,
    chestTile.x + ',' + chestTile.y,
  ]);
  const floorTiles = [];
  for (let y = 1; y < size - 1; y++) {
    for (let x = 1; x < size - 1; x++) {
      if (grid[y][x] !== 'floor') continue;
      const key = x + ',' + y;
      if (reservedKeys.has(key)) continue;
      floorTiles.push({ x, y });
    }
  }
  // Deterministic shuffle so the same seed gives the same spawn pattern.
  const rng = mulberry32((anchor.x * 73856093 ^ anchor.y * 19349663) >>> 0);
  for (let i = floorTiles.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [floorTiles[i], floorTiles[j]] = [floorTiles[j], floorTiles[i]];
  }
  const authoredSpawns = [];
  let cursor = 0;
  for (const e of place.enemies) {
    for (let k = 0; k < e.n && cursor < floorTiles.length; k++) {
      const t = floorTiles[cursor++];
      authoredSpawns.push({ kind: e.kind, x: t.x, y: t.y });
    }
  }

  return {
    grid,
    entry, exit,
    rooms: [{ x: 1, y: 1, w: size - 2, h: size - 2 }],
    decor: [],
    affixes,
    scope,
    chestTile,
    chestLooted: false,
    bossRoom: null,
    bossKind: null,
    authored: true,                    // hits the same code path as editor levels
    authoredName: place.name,
    authoredSpawns,
    staircases: [],
    traps: [],
    echo: true,
    echoPlaceId: place.id,
    blocked: (x, y) =>
      x < 0 || y < 0 || x >= size || y >= size || grid[y][x] === 'wall',
  };
}

function nearestFloor(grid, cx, cy) {
  const size = grid.length;
  if (grid[cy]?.[cx] === 'floor') return { x: cx, y: cy };
  // Spiral outward
  for (let r = 1; r < size; r++) {
    for (let dy = -r; dy <= r; dy++) {
      for (let dx = -r; dx <= r; dx++) {
        if (Math.abs(dx) !== r && Math.abs(dy) !== r) continue;
        const x = cx + dx, y = cy + dy;
        if (x < 0 || y < 0 || x >= size || y >= size) continue;
        if (grid[y][x] === 'floor') return { x, y };
      }
    }
  }
  return { x: cx, y: cy };
}

/**
 * Generate a dungeon layout. Pure data — no three.js.
 * Affixes change what gets baked into the layout (decoration spawns,
 * boss substitution, etc.). Scope themes the visual decor (briar_maze →
 * thorn pillars, sunken_hut → puddles, delve → boulders).
 *
 * @param {number} seed
 * @param {Array<{id:string, good:boolean, resolvedId:string}>} affixes
 * @param {string} [scope]  'briar_maze' | 'sunken_hut' | 'delve' | 'hollow'
 */
export function generateDungeonLayout(seed = Date.now(), affixes = [], scope = undefined) {
  const rng = mulberry32(seed >>> 0);

  const grid = Array.from({ length: GRID }, () => Array(GRID).fill('wall'));
  const rooms = [];

  // Rooms: try N times, drop overlapping ones.
  const TRIES = 60;
  for (let i = 0; i < TRIES && rooms.length < 8; i++) {
    const w = ROOM_MIN + Math.floor(rng() * (ROOM_MAX - ROOM_MIN));
    const h = ROOM_MIN + Math.floor(rng() * (ROOM_MAX - ROOM_MIN));
    const x = 1 + Math.floor(rng() * (GRID - w - 2));
    const y = 1 + Math.floor(rng() * (GRID - h - 2));
    const overlap = rooms.some(r =>
      x < r.x + r.w + 1 && x + w + 1 > r.x &&
      y < r.y + r.h + 1 && y + h + 1 > r.y
    );
    if (overlap) continue;
    rooms.push({ x, y, w, h });
  }

  // Carve room floors
  for (const r of rooms) {
    for (let yy = r.y; yy < r.y + r.h; yy++) {
      for (let xx = r.x; xx < r.x + r.w; xx++) {
        grid[yy][xx] = 'floor';
      }
    }
  }

  // Connect rooms with L-corridors (each consecutive pair connects)
  for (let i = 1; i < rooms.length; i++) {
    const a = rooms[i - 1], b = rooms[i];
    const ax = a.x + ((a.w / 2) | 0), ay = a.y + ((a.h / 2) | 0);
    const bx = b.x + ((b.w / 2) | 0), by = b.y + ((b.h / 2) | 0);
    // Random elbow direction for variety
    if (rng() < 0.5) {
      hCorridor(grid, ax, bx, ay);
      vCorridor(grid, ay, by, bx);
    } else {
      vCorridor(grid, ay, by, ax);
      hCorridor(grid, ax, bx, by);
    }
  }

  if (rooms.length < 2) {
    // Degenerate — punt with a fallback corridor across the middle
    for (let x = 2; x < GRID - 2; x++) grid[GRID >> 1][x] = 'floor';
    rooms.push({ x: 2, y: GRID >> 1, w: 1, h: 1 });
    rooms.push({ x: GRID - 3, y: GRID >> 1, w: 1, h: 1 });
  }

  // Pick entry + exit at the two rooms farthest apart
  const farPair = pickFarthest(rooms);
  const entry = roomCenter(farPair[0]);
  const exit  = roomCenter(farPair[1]);
  grid[entry.y][entry.x] = 'floor';
  grid[exit.y][exit.x]   = 'floor';

  // ---- affix → decoration plumbing ----
  // Each entry in `decor` becomes a placed prop in buildDungeonGroup.
  const decor = [];
  const hasGood = (id) => affixes.some(a => a.id === id && a.good);

  // Helper to drop a clump of `n` decor entries on random non-entry/exit
  // floor tiles. Skips already-occupied tiles. Returns how many were placed.
  function _scatter(n, makeEntry) {
    let placed = 0, tries = 0;
    while (placed < n && tries < 200) {
      tries++;
      const r = rooms[1 + Math.floor(rng() * (rooms.length - 1))] || rooms[0];
      const x = r.x + Math.floor(rng() * r.w);
      const y = r.y + Math.floor(rng() * r.h);
      if (x === entry.x && y === entry.y) continue;
      if (x === exit.x  && y === exit.y)  continue;
      if (decor.some(d => d.x === x && d.y === y)) continue;
      decor.push(Object.assign({ x, y, depleted: false }, makeEntry()));
      placed++;
    }
    return placed;
  }

  if (hasGood('mineral_vein')) {
    // 3-5 ore rocks scattered through floor tiles. Skip entry/exit cells.
    // Ore type biases by scope: delve→palechalk, sunken_hut→bogiron, hollow→mosswort.
    const oreItem = scope === 'delve'      ? 'palechalk_ore'
                  : scope === 'sunken_hut' ? 'bogiron_ore'
                  : scope === 'hollow'     ? 'mosswort_ore'
                  : 'bogiron_ore';
    _scatter(3 + Math.floor(rng() * 3), () => ({ kind: 'ore_rock', item: oreItem }));
  }
  // 'mineral_vein__bad' (Barren) → no ore. That's the whole effect.

  if (hasGood('bramble_bloom')) {
    // 4-6 berry / mushroom spawns. Promise of the affix description.
    const choices = ['whitleberry', 'hedgecap', 'wishrose'];
    _scatter(4 + Math.floor(rng() * 3), () => ({
      kind: 'forage_node',
      item: choices[Math.floor(rng() * choices.length)],
    }));
  }
  if (hasGood('herbal_patch')) {
    // 4-6 herb spawns — Onywyn's foxglove, Quill's bramble resin.
    const choices = ['foxglove', 'bramble_resin', 'wishrose'];
    _scatter(4 + Math.floor(rng() * 3), () => ({
      kind: 'forage_node',
      item: choices[Math.floor(rng() * choices.length)],
    }));
  }
  if (hasGood('wood_grove')) {
    // 3-5 log piles scattered as wood-cutting nodes.
    _scatter(3 + Math.floor(rng() * 3), () => ({ kind: 'log_pile', item: 'logs' }));
  }

  // Boss affixes: Hedgemother's Den / Burrow Boar's Wallow.
  // Each flags the room nearest the exit as the boss room. The main loop
  // substitutes the appropriate boss spawn there and skips the usual
  // mid-tier bramble-cap. `bossKind` tells main.js which factory to use.
  let bossRoom = null;
  let bossKind = null;
  if (hasGood('hedgemother_den')) bossKind = 'hedgemother';
  else if (hasGood('burrow_boar_den')) bossKind = 'burrow_boar';
  else if (hasGood('wolf_alpha_den'))  bossKind = 'wolf_alpha';
  if (bossKind) {
    bossRoom = rooms.find(r =>
      exit.x >= r.x && exit.x < r.x + r.w &&
      exit.y >= r.y && exit.y < r.y + r.h
    ) || rooms[rooms.length - 1];
  }

  // ---- scope-themed decor ----
  // Each scope adds 4-8 themed props to non-entry, non-exit floor tiles.
  // Pure data; buildDungeonGroup looks at d.kind to render the right mesh.
  if (scope) {
    const themeMap = {
      briar_maze: { kind: 'thorn_pillar', count: [5, 8] },
      sunken_hut: { kind: 'puddle',       count: [6, 10] },
      delve:      { kind: 'boulder',      count: [4, 7] },
      hollow:     { kind: 'mossfloor',    count: [4, 6] },
    };
    const theme = themeMap[scope];
    if (theme) {
      const target = theme.count[0] + Math.floor(rng() * (theme.count[1] - theme.count[0] + 1));
      let placed = 0, tries = 0;
      while (placed < target && tries < 250) {
        tries++;
        const r = rooms[1 + Math.floor(rng() * (rooms.length - 1))] || rooms[0];
        const x = r.x + Math.floor(rng() * r.w);
        const y = r.y + Math.floor(rng() * r.h);
        if (x === entry.x && y === entry.y) continue;
        if (x === exit.x  && y === exit.y)  continue;
        if (decor.some(d => d.x === x && d.y === y)) continue;
        decor.push({ kind: theme.kind, x, y });
        placed++;
      }
    }
  }

  // Reward chest sits one tile in front of the exit stair, on a floor tile
  // if available. Players see it before they take the stairs (Fate-style).
  let chestTile = null;
  for (const [dx, dy] of [[0, -1], [0, 1], [-1, 0], [1, 0]]) {
    const cx = exit.x + dx, cy = exit.y + dy;
    if (cx < 0 || cy < 0 || cx >= GRID || cy >= GRID) continue;
    if (grid[cy][cx] === 'floor' && !(cx === entry.x && cy === entry.y)) {
      chestTile = { x: cx, y: cy }; break;
    }
  }
  if (!chestTile) chestTile = { x: exit.x, y: exit.y };

  return {
    grid,
    entry,
    exit,
    rooms,
    decor,
    affixes,
    scope,
    chestTile,
    chestLooted: false,
    bossRoom,        // truthy when a boss-affix is active
    bossKind,        // 'hedgemother' | 'burrow_boar' | null
    blocked: (x, y) =>
      x < 0 || y < 0 || x >= GRID || y >= GRID || grid[y][x] === 'wall',
  };
}

/**
 * Hand-authored layout loader. Accepts the JSON shape exported by
 * editor.html (`{ name, scope, size, grid, entry, exit, chestTile,
 * decor, spawns, bossKind }`) and returns the same layout shape that
 * generateDungeonLayout produces, so the rest of the engine doesn't
 * care whether a level was authored or generated.
 *
 * Authored layouts pass `spawns` through verbatim on `layout.authoredSpawns`
 * — main.js's enterDungeon honours that list instead of rolling from the
 * procedural pools.
 */
export function loadAuthoredLayout(json, affixes = []) {
  if (!json || !Array.isArray(json.grid)) {
    throw new Error('loadAuthoredLayout: invalid grid');
  }
  const grid = json.grid;
  const gh = grid.length, gw = grid[0]?.length || 0;
  const entry = json.entry || { x: 1, y: 1 };
  const exit  = json.exit  || { x: gw - 2, y: gh - 2 };
  const chestTile = json.chestTile || { x: exit.x, y: exit.y };
  const decor = Array.isArray(json.decor) ? json.decor.slice() : [];
  const authoredSpawns = Array.isArray(json.spawns) ? json.spawns.slice() : [];
  // Synthesize a single "room" wrapping the entry tile so existing room-
  // driven code paths (festival pace fallback, penultimate-room logic) have
  // something to chew on. Authored levels normally bypass enemy procgen via
  // authoredSpawns, so this is just a safety net.
  const rooms = [{ x: entry.x, y: entry.y, w: 1, h: 1 }];

  return {
    grid,
    entry,
    exit,
    rooms,
    decor,
    affixes,
    scope: json.scope || 'hollow',
    chestTile,
    chestLooted: false,
    bossRoom: null,
    bossKind: json.bossKind || null,
    authored: true,
    authoredName: json.name || 'untitled',
    authoredSpawns,
    staircases: Array.isArray(json.staircases) ? json.staircases.slice() : [],
    traps: Array.isArray(json.traps) ? json.traps.slice() : [],
    doors: Array.isArray(json.doors) ? json.doors.map(d => ({ ...d })) : [],
    blocked(x, y) {
      if (x < 0 || y < 0 || x >= gw || y >= gh) return true;
      if (grid[y][x] === 'wall') return true;
      // Locked doors block movement until unlocked. Once unlocked, they
      // remain in the array but with locked=false, so the runtime can
      // still find their tile to render the open mesh.
      if (this.doors.some(d => d.x === x && d.y === y && d.locked !== false)) return true;
      return false;
    },
  };
}

/**
 * Scaffold-mode loader. Author paints the *bones* of a level — a few key
 * rooms, the entry/exit, maybe a boss-room hint — and procgen does the
 * connecting + filling work. Author's hand-placed spawns ride on top of
 * the procgen room-loop spawns (set on `scaffoldExtraSpawns`).
 *
 * What scaffold preserves from author input:
 *   - The grid (walls/floors painted by hand)
 *   - entry / exit / chestTile / decor / spawns (verbatim)
 *   - bossKind (drives boss substitution in farthest room)
 *
 * What scaffold adds via procgen:
 *   - Auto-detects rooms via flood-fill over connected floor regions
 *   - Carves L-corridors between consecutive rooms (existing helpers)
 *   - Picks farthest pair as entry/exit if author didn't mark them
 *   - Leaves enemy spawning to main.js's procgen branch + author's extras
 */
export function loadScaffoldLayout(json, tier = 1, affixes = []) {
  if (!json || !Array.isArray(json.grid)) {
    throw new Error('loadScaffoldLayout: invalid grid');
  }
  // Copy the grid so we can carve corridors without mutating the JSON.
  const grid = json.grid.map(row => row.slice());
  const gh = grid.length, gw = grid[0]?.length || 0;
  // Seed: if json.procgen.seed is set, use it verbatim for deterministic
  // padding/decor (great for testing). Otherwise mix the layout name with
  // the current time so each test run varies.
  const explicitSeed = json.procgen && json.procgen.seed != null && json.procgen.seed !== ''
    ? Number(json.procgen.seed) | 0
    : null;
  const nameSeed = (json.name || '').split('').reduce((a, c) => a + c.charCodeAt(0), 0);
  const rng = mulberry32((explicitSeed ?? (nameSeed ^ Date.now())) >>> 0);

  // 1. Detect rooms = connected floor regions, with bounding box + center.
  const rooms = _detectRooms(grid, gw, gh);
  if (rooms.length < 2) {
    // Degenerate — fall back to authored mode behaviour.
    return loadAuthoredLayout(json, affixes);
  }

  // 1b. Procgen padding: 1-3 random extra rooms in unfilled wall space.
  //     Default ON (set procgenPadding: false on the JSON to suppress).
  if (json.procgenPadding !== false) {
    const target = 1 + Math.floor(rng() * 3);   // 1..3
    const added = _addPaddingRooms(grid, gw, gh, rooms, rng, target);
    rooms.push(...added);
  }

  // 1c. Procgen brush stamping (Stage C half 2). Picks 2-4 random brushes
  //     from the embedded brush library and tries to fit each one into
  //     wall space, copying its grid + decor + spawns + roomTags. Each
  //     successful stamp is treated as a new room (mob loop fills it).
  const stampedDecor = [];
  const stampedSpawns = [];
  const stampedTraps = [];
  const stampedDoors = [];
  if (json.useBrushes && Array.isArray(json.brushes) && json.brushes.length) {
    const targetN = 2 + Math.floor(rng() * 3);   // 2..4
    const stamped = _stampBrushes(grid, gw, gh, rooms, rng, json.brushes, targetN,
                                   stampedDecor, stampedSpawns, stampedTraps, stampedDoors);
    rooms.push(...stamped);
  }

  // 2. Promote the room containing entry to index 0 so the procgen mob loop
  //    treats it as the entry (no spawn).
  let entry = json.entry || null;
  let exit  = json.exit  || null;
  if (!entry || !exit) {
    const far = pickFarthest(rooms);
    if (!entry) entry = { x: roomCenter(far[0]).x, y: roomCenter(far[0]).y };
    if (!exit)  exit  = { x: roomCenter(far[1]).x, y: roomCenter(far[1]).y };
  }
  const entryIdx = rooms.findIndex(r =>
    entry.x >= r.x && entry.x < r.x + r.w &&
    entry.y >= r.y && entry.y < r.y + r.h);
  if (entryIdx > 0) { const [er] = rooms.splice(entryIdx, 1); rooms.unshift(er); }

  // 3. Connect rooms with L-corridors. Each consecutive pair links so
  //    every room is reachable from rooms[0] (entry).
  for (let i = 1; i < rooms.length; i++) {
    const a = rooms[i - 1], b = rooms[i];
    const ac = roomCenter(a), bc = roomCenter(b);
    if (rng() < 0.5) {
      hCorridor(grid, ac.x, bc.x, ac.y);
      vCorridor(grid, ac.y, bc.y, bc.x);
    } else {
      vCorridor(grid, ac.y, bc.y, ac.x);
      hCorridor(grid, ac.x, bc.x, bc.y);
    }
  }

  // 4a. Per-room intent tags (Stage B). For each authored roomTag, find
  //     the room whose bbox contains the tag tile and stash it on the
  //     room. main.js's spawn loop dispatches off room.tag.
  const tags = Array.isArray(json.roomTags) ? json.roomTags : [];
  for (const t of tags) {
    const r = rooms.find(rr =>
      t.x >= rr.x && t.x < rr.x + rr.w &&
      t.y >= rr.y && t.y < rr.y + rr.h
    );
    if (r) r.tag = t.tag;
  }

  // 4b. Boss room — author can mark it via bossKind + a tagged room (the
  //     room with tag=='boss'). If neither tag nor explicit chestTile is
  //     specified, fall back to "farthest room from entry" as before.
  let bossRoom = rooms.find(r => r.tag === 'boss') || null;
  const bossKind = json.bossKind || null;
  if (!bossRoom && bossKind) {
    let bestD = -1;
    for (const r of rooms) {
      const c = roomCenter(r);
      const d = (c.x - entry.x) ** 2 + (c.y - entry.y) ** 2;
      if (d > bestD) { bestD = d; bossRoom = r; }
    }
  }

  // 5. Decor: mix author's hand placements with scope-themed extras so the
  //    level still reads as the chosen biome. Brush-stamped decor merges
  //    in here so it gets the same treatment.
  const decor = (Array.isArray(json.decor) ? json.decor.slice() : []);
  decor.push(...stampedDecor);
  const scope = json.scope || 'hollow';
  const themeMap = {
    briar_maze: { kind: 'thorn_pillar', count: [3, 6] },
    sunken_hut: { kind: 'puddle',       count: [4, 8] },
    delve:      { kind: 'boulder',      count: [3, 6] },
    hollow:     { kind: 'mossfloor',    count: [3, 5] },
  };
  const theme = themeMap[scope];
  if (theme) {
    const target = theme.count[0] + Math.floor(rng() * (theme.count[1] - theme.count[0] + 1));
    let placed = 0, tries = 0;
    while (placed < target && tries < 200) {
      tries++;
      const r = rooms[1 + Math.floor(rng() * (rooms.length - 1))] || rooms[0];
      const x = r.x + Math.floor(rng() * r.w);
      const y = r.y + Math.floor(rng() * r.h);
      if (grid[y]?.[x] !== 'floor') continue;
      if (x === entry.x && y === entry.y) continue;
      if (x === exit.x  && y === exit.y)  continue;
      if (decor.some(d => d.x === x && d.y === y)) continue;
      decor.push({ kind: theme.kind, x, y });
      placed++;
    }
  }

  // 4c. Treasure-tagged room steals the chestTile so the chest spawns
  //     where the author wants it, not at the exit-adjacent default.
  const treasureRoom = rooms.find(r => r.tag === 'treasure');
  const chestTile = treasureRoom
    ? roomCenter(treasureRoom)
    : (json.chestTile || { x: exit.x, y: exit.y });

  return {
    grid,
    entry,
    exit,
    rooms,
    decor,
    affixes,
    scope,
    chestTile,
    chestLooted: false,
    bossRoom,
    bossKind,
    authored: true,                 // tells buildDungeonGroup to use grid dims
    authoredName: (json.name || 'untitled') + ' (scaffold)',
    // No `authoredSpawns` — main.js falls through to its procgen mob loop.
    // Author's hand-placed spawns + brush-stamped spawns ride on top via
    // this side-channel.
    scaffoldExtraSpawns: [
      ...(Array.isArray(json.spawns) ? json.spawns : []),
      ...stampedSpawns,
    ],
    staircases: Array.isArray(json.staircases) ? json.staircases.slice() : [],
    traps: [
      ...(Array.isArray(json.traps) ? json.traps : []),
      ...stampedTraps,
    ],
    doors: [
      ...(Array.isArray(json.doors) ? json.doors.map(d => ({ ...d })) : []),
      ...stampedDoors,
    ],
    blocked(x, y) {
      if (x < 0 || y < 0 || x >= gw || y >= gh) return true;
      if (grid[y][x] === 'wall') return true;
      if (this.doors.some(d => d.x === x && d.y === y && d.locked !== false)) return true;
      return false;
    },
  };
}

// Stamp `count` random brushes from `brushes` into wall-only space. Each
// successful stamp:
//   - copies the brush's 'floor' cells into `grid`
//   - pushes its decor / spawns into the out-arrays (caller merges these
//     into the final layout)
//   - returns a room rectangle (with optional .tag from brush.roomTags[0])
//     so main.js's spawn loop fills it like any other room
//
// Rejection rule: brush bbox must not overlap any existing room's bbox
// with a 1-tile buffer, AND no brush 'floor' cell may land on an existing
// 'floor' cell. This keeps stamps from accidentally bridging adjacent
// authored rooms.
function _stampBrushes(grid, gw, gh, existing, rng, brushes, count,
                       outDecor, outSpawns, outTraps, outDoors) {
  const TRIES_PER = 30;
  const stamped = [];
  for (let i = 0; i < count; i++) {
    const br = brushes[Math.floor(rng() * brushes.length)];
    if (!br || !Array.isArray(br.grid) || !br.grid.length) continue;
    const bw = br.w || br.grid[0].length;
    const bh = br.h || br.grid.length;
    if (gw - bw - 2 <= 0 || gh - bh - 2 <= 0) continue;

    for (let t = 0; t < TRIES_PER; t++) {
      const x = 1 + Math.floor(rng() * (gw - bw - 2));
      const y = 1 + Math.floor(rng() * (gh - bh - 2));
      // Bbox-with-buffer overlap check vs any existing room (detected,
      // padded, or previously stamped).
      const conflict = [...existing, ...stamped].some(r =>
        x < r.x + r.w + 1 && x + bw + 1 > r.x &&
        y < r.y + r.h + 1 && y + bh + 1 > r.y
      );
      if (conflict) continue;
      // Defensive cell-by-cell check — no brush floor on top of existing floor.
      let cellOK = true;
      for (let dy = 0; dy < bh && cellOK; dy++) {
        for (let dx = 0; dx < bw; dx++) {
          if (br.grid[dy][dx] !== 'floor') continue;
          if (grid[y + dy][x + dx] === 'floor') { cellOK = false; break; }
        }
      }
      if (!cellOK) continue;

      // Place the brush.
      for (let dy = 0; dy < bh; dy++) {
        for (let dx = 0; dx < bw; dx++) {
          if (br.grid[dy][dx] === 'floor') grid[y + dy][x + dx] = 'floor';
        }
      }
      for (const d of br.decor || []) outDecor.push({ ...d, x: x + d.x, y: y + d.y });
      for (const s of br.spawns || []) outSpawns.push({ ...s, x: x + s.x, y: y + s.y });
      for (const t of br.traps  || []) outTraps.push({ ...t, x: x + t.x, y: y + t.y });
      for (const d of br.doors  || []) outDoors.push({ ...d, x: x + d.x, y: y + d.y });
      const room = { x, y, w: bw, h: bh };
      // First roomTag in the brush sets the new room's tag so the spawn
      // loop dispatcher (Stage B) fires correctly.
      if (Array.isArray(br.roomTags) && br.roomTags.length) {
        room.tag = br.roomTags[0].tag;
      }
      stamped.push(room);
      break;
    }
  }
  return stamped;
}

// Drop 1-3 small rectangular rooms into wall-only space, avoiding overlap
// (with a 1-tile buffer) of any existing room. Mutates `grid` in place,
// returns the rooms it placed. Used by scaffold mode to pad sparse hand-
// painted layouts so the dungeon doesn't feel underfilled.
function _addPaddingRooms(grid, gw, gh, existing, rng, count) {
  const ROOM_MIN = 3, ROOM_MAX = 5;
  const TRIES = 50;
  const added = [];
  for (let i = 0; i < TRIES && added.length < count; i++) {
    const w = ROOM_MIN + Math.floor(rng() * (ROOM_MAX - ROOM_MIN + 1));
    const h = ROOM_MIN + Math.floor(rng() * (ROOM_MAX - ROOM_MIN + 1));
    if (gw - w - 2 <= 0 || gh - h - 2 <= 0) continue;
    const x = 1 + Math.floor(rng() * (gw - w - 2));
    const y = 1 + Math.floor(rng() * (gh - h - 2));
    const overlap = [...existing, ...added].some(r =>
      x < r.x + r.w + 1 && x + w + 1 > r.x &&
      y < r.y + r.h + 1 && y + h + 1 > r.y
    );
    if (overlap) continue;
    for (let yy = y; yy < y + h; yy++) {
      for (let xx = x; xx < x + w; xx++) grid[yy][xx] = 'floor';
    }
    added.push({ x, y, w, h });
  }
  return added;
}

// Flood-fill connected floor regions. Each region becomes a "room" with a
// bounding box, used by main.js's mob spawn loop. Discards cells < 4 to
// drop corridor noise.
function _detectRooms(grid, gw, gh) {
  const seen = Array.from({ length: gh }, () => Array(gw).fill(false));
  const rooms = [];
  for (let y = 0; y < gh; y++) {
    for (let x = 0; x < gw; x++) {
      if (grid[y][x] !== 'floor' || seen[y][x]) continue;
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
        for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          const nx = cx + dx, ny = cy + dy;
          if (nx < 0 || ny < 0 || nx >= gw || ny >= gh || seen[ny][nx]) continue;
          if (grid[ny][nx] !== 'floor') continue;
          seen[ny][nx] = true;
          q.push([nx, ny]);
        }
      }
      if (cells < 4) continue;
      rooms.push({
        x: minX, y: minY,
        w: maxX - minX + 1, h: maxY - minY + 1,
      });
    }
  }
  // Largest rooms last so the penultimate-room "guard" logic in main.js
  // tends to land on a substantial room rather than a closet.
  rooms.sort((a, b) => (a.w * a.h) - (b.w * b.h));
  return rooms;
}

/** Build the dungeon's three.js group from a layout. Adds entry/exit
 *  marker meshes so the player can see where the stairs are, plus any
 *  decoration props from the affix-driven `decor` list. */
export function buildDungeonGroup(layout, affixes = []) {
  const group = new THREE.Group();
  group.name = 'DungeonGroup';

  // Floor tiles + walls — read dims from the layout so authored levels
  // (which can be any size) render at their declared dimensions.
  const gh = layout.grid.length;
  const gw = layout.grid[0]?.length || 0;
  for (let y = 0; y < gh; y++) {
    for (let x = 0; x < gw; x++) {
      if (layout.grid[y][x] === 'floor') {
        const f = buildWoodFloorTile();
        f.position.set(x + 0.5, 0, y + 0.5);
        group.add(f);
      } else {
        const w = buildStoneWallTile();
        w.position.set(x + 0.5, 0, y + 0.5);
        group.add(w);
      }
    }
  }

  // Entry stair — soft green light + glow disc on the floor
  const entryDisc = new THREE.Mesh(
    new THREE.CircleGeometry(0.4, 24),
    new THREE.MeshBasicMaterial({ color: 0x6f8a3f, transparent: true, opacity: 0.7 })
  );
  entryDisc.rotation.x = -Math.PI / 2;
  entryDisc.position.set(layout.entry.x + 0.5, 0.05, layout.entry.y + 0.5);
  group.add(entryDisc);

  // Exit stair — gold; this is the "go back to Bramblewood" affordance
  const exitDisc = new THREE.Mesh(
    new THREE.CircleGeometry(0.4, 24),
    new THREE.MeshBasicMaterial({ color: 0xd4af37, transparent: true, opacity: 0.85 })
  );
  exitDisc.rotation.x = -Math.PI / 2;
  exitDisc.position.set(layout.exit.x + 0.5, 0.05, layout.exit.y + 0.5);
  group.add(exitDisc);

  // Staircases to other authored floors — purple disc, pulses gently to read
  // as "go deeper" rather than "go home like the gold exit".
  for (const sc of layout.staircases || []) {
    const disc = new THREE.Mesh(
      new THREE.CircleGeometry(0.4, 24),
      new THREE.MeshBasicMaterial({ color: 0x9a6ec4, transparent: true, opacity: 0.85 })
    );
    disc.rotation.x = -Math.PI / 2;
    disc.position.set(sc.x + 0.5, 0.06, sc.y + 0.5);
    group.add(disc);
    // Tag for debug; runtime reads `layout.staircases` directly.
    disc.userData.staircase = sc;
  }

  // Soft ambient torch light — color depends on scope so each themed dungeon
  // has a distinct mood at a glance.
  const SCOPE_LIGHT = {
    briar_maze: { color: 0x88a050, intensity: 0.9, range: 18 },   // dim mossy green
    sunken_hut: { color: 0x6080a0, intensity: 0.7, range: 14 },   // cool damp blue
    delve:      { color: 0xffaa55, intensity: 1.0, range: 18 },   // warm forge amber
    hollow:     { color: 0xeed8a8, intensity: 0.85, range: 16 },  // soft cream lantern
  };
  const lightCfg = SCOPE_LIGHT[layout.scope] || { color: 0xffaa55, intensity: 0.8, range: 16 };
  const torch = new THREE.PointLight(lightCfg.color, lightCfg.intensity, lightCfg.range);
  torch.position.set(layout.entry.x + 0.5, 2, layout.entry.y + 0.5);
  group.add(torch);

  // Add a second matching light at the exit/chest end so the far half of the
  // dungeon also reads in the scope's color, not just the entry.
  const torch2 = new THREE.PointLight(lightCfg.color, lightCfg.intensity * 0.7, lightCfg.range);
  torch2.position.set(layout.exit.x + 0.5, 2, layout.exit.y + 0.5);
  group.add(torch2);

  // Affix + scope-driven decoration props
  for (const d of layout.decor || []) {
    let prop = null;
    if (d.kind === 'ore_rock') {
      prop = new THREE.Group();
      const stone = new THREE.Mesh(
        new THREE.BoxGeometry(0.55, 0.40, 0.55),
        new THREE.MeshToonMaterial({ color: 0x8a8278 })
      );
      stone.position.y = 0.20;
      prop.add(stone);
      // Vein color hints at ore type so a player can tell delve-palechalk
      // (cream) from sunken-hut bogiron (rust) at a glance.
      const veinColor = d.item === 'palechalk_ore' ? 0xe8d8b0
                       : d.item === 'mosswort_ore' ? 0x4f7a3a
                       : 0x6b3e2a;
      const vein = new THREE.Mesh(
        new THREE.BoxGeometry(0.30, 0.06, 0.20),
        new THREE.MeshToonMaterial({ color: veinColor })
      );
      vein.position.y = 0.42;
      prop.add(vein);
    } else if (d.kind === 'forage_node') {
      // Small bushy berry/mushroom/herb cluster — three colored cubes on
      // a stem so the player can spot it in a corridor.
      prop = new THREE.Group();
      const stem = new THREE.Mesh(
        new THREE.BoxGeometry(0.06, 0.18, 0.06),
        new THREE.MeshToonMaterial({ color: 0x4f6a3a })
      );
      stem.position.y = 0.09;
      prop.add(stem);
      const berryColor = d.item === 'foxglove'      ? 0xc88ad0
                       : d.item === 'bramble_resin' ? 0xc59560
                       : d.item === 'hedgecap'      ? 0xc04a3a
                       : d.item === 'wishrose'      ? 0xeec0d8
                       : 0x6633aa; // whitleberry
      for (let i = 0; i < 3; i++) {
        const ang = i * (Math.PI * 2 / 3);
        const berry = new THREE.Mesh(
          new THREE.BoxGeometry(0.10, 0.10, 0.10),
          new THREE.MeshToonMaterial({ color: berryColor })
        );
        berry.position.set(Math.cos(ang) * 0.07, 0.20, Math.sin(ang) * 0.07);
        prop.add(berry);
      }
    } else if (d.kind === 'log_pile') {
      // Stacked logs — three small cylinders / boxes.
      prop = new THREE.Group();
      const colorWood = 0x6e4a2a;
      for (let i = 0; i < 3; i++) {
        const log = new THREE.Mesh(
          new THREE.BoxGeometry(0.45, 0.10, 0.10),
          new THREE.MeshToonMaterial({ color: colorWood })
        );
        log.position.set(0, 0.05 + i * 0.10, (i % 2 === 0 ? 0 : 0.05));
        prop.add(log);
      }
    } else if (d.kind === 'thorn_pillar') {
      // briar_maze — twisted brown column with thorn rings
      prop = new THREE.Group();
      const trunk = new THREE.Mesh(
        new THREE.BoxGeometry(0.20, 1.10, 0.20),
        new THREE.MeshToonMaterial({ color: 0x4a3520 })
      );
      trunk.position.y = 0.55;
      prop.add(trunk);
      for (let i = 0; i < 3; i++) {
        const thorn = new THREE.Mesh(
          new THREE.BoxGeometry(0.30, 0.06, 0.30),
          new THREE.MeshToonMaterial({ color: 0x6b8a3a })
        );
        thorn.position.y = 0.25 + i * 0.30;
        thorn.rotation.y = i * 0.7;
        prop.add(thorn);
      }
    } else if (d.kind === 'puddle') {
      // sunken_hut — flat dark blue circle on the floor
      prop = new THREE.Mesh(
        new THREE.CircleGeometry(0.36, 16),
        new THREE.MeshToonMaterial({ color: 0x3a4a5e, transparent: true, opacity: 0.85 })
      );
      prop.rotation.x = -Math.PI / 2;
      prop.position.y = 0.02;
    } else if (d.kind === 'boulder') {
      // delve — chunky grey rock pile
      prop = new THREE.Group();
      const a = new THREE.Mesh(
        new THREE.BoxGeometry(0.45, 0.30, 0.45),
        new THREE.MeshToonMaterial({ color: 0x6e6862 })
      );
      a.position.set(0, 0.15, 0);
      prop.add(a);
      const b = new THREE.Mesh(
        new THREE.BoxGeometry(0.30, 0.20, 0.30),
        new THREE.MeshToonMaterial({ color: 0x8a8278 })
      );
      b.position.set(0.05, 0.42, 0.04);
      prop.add(b);
    } else if (d.kind === 'mossfloor') {
      // hollow — a moss patch on the floor
      prop = new THREE.Mesh(
        new THREE.PlaneGeometry(0.65, 0.65),
        new THREE.MeshToonMaterial({ color: 0x4a6a3a, transparent: true, opacity: 0.7 })
      );
      prop.rotation.x = -Math.PI / 2;
      prop.position.y = 0.025;
    } else if (d.kind === 'shrine_pedestal') {
      // Stage B fixture — placed in shrine-tagged rooms. Stone base wrapped
      // in briar, glowing rune-stamp pad, faceted gemstone on top with warm
      // emissive. A pleasant rest-point that signals "rune mechanics live
      // here" without being interactive yet.
      prop = new THREE.Group();
      // Stepped stone base — two tiers
      const baseLow = new THREE.Mesh(
        new THREE.BoxGeometry(0.70, 0.18, 0.70),
        new THREE.MeshToonMaterial({ color: 0x6a5e52 })
      );
      baseLow.position.y = 0.09;
      prop.add(baseLow);
      const baseUp = new THREE.Mesh(
        new THREE.BoxGeometry(0.55, 0.14, 0.55),
        new THREE.MeshToonMaterial({ color: 0x7a6e60 })
      );
      baseUp.position.y = 0.25;
      prop.add(baseUp);
      // Briar wraps — four short twigs at the corners of the lower tier
      const briarMat = new THREE.MeshToonMaterial({ color: 0x3a2a18 });
      for (const [bx, bz] of [[-0.30, -0.30], [0.30, -0.30], [-0.30, 0.30], [0.30, 0.30]]) {
        const briar = new THREE.Mesh(
          new THREE.BoxGeometry(0.06, 0.34, 0.06), briarMat,
        );
        briar.position.set(bx, 0.17, bz);
        briar.rotation.y = Math.atan2(bz, bx);
        prop.add(briar);
      }
      // Glowing rune disc on the upper tier
      const runePad = new THREE.Mesh(
        new THREE.CircleGeometry(0.20, 18),
        new THREE.MeshBasicMaterial({ color: 0xffc678, transparent: true, opacity: 0.85 }),
      );
      runePad.rotation.x = -Math.PI / 2;
      runePad.position.y = 0.33;
      prop.add(runePad);
      // Faceted gemstone — diamond-ish (octahedron) with warm emissive
      const gemMat = new THREE.MeshToonMaterial({
        color: 0xffb060,
        emissive: 0xffa040,
        emissiveIntensity: 0.95,
      });
      const gem = new THREE.Mesh(new THREE.OctahedronGeometry(0.13, 0), gemMat);
      gem.position.y = 0.55;
      gem.rotation.y = Math.PI / 4;
      prop.add(gem);
      // Soft point light so the shrine actually casts warm fill nearby
      const shrineLight = new THREE.PointLight(0xffb060, 0.55, 5);
      shrineLight.position.y = 0.6;
      prop.add(shrineLight);
    }
    if (prop) {
      prop.position.x = (d.x + 0.5);
      prop.position.z = (d.y + 0.5);
      prop.userData.affixDecor = d;
      // Two-way link so the gather-handler in main.js can hide the
      // mesh when its decor is depleted.
      d._mesh = prop;
      group.add(prop);
    }
  }

  // Trap props — small floor-level meshes. Spike traps are orange chevrons,
  // bramble traps are tangled green vines. Tagged via userData.trap so a
  // future tick can hide spent spikes without rebuilding the whole group.
  for (const t of layout.traps || []) {
    let trapProp = null;
    if (t.kind === 'spike') {
      // Three angled spikes radiating from a small base — chevron silhouette.
      trapProp = new THREE.Group();
      const baseSpike = new THREE.MeshToonMaterial({ color: 0xc46624 });
      for (let i = 0; i < 3; i++) {
        const sp = new THREE.Mesh(new THREE.ConeGeometry(0.06, 0.18, 6), baseSpike);
        const a = (i - 1) * 0.5;
        sp.position.set(Math.sin(a) * 0.10, 0.09, Math.cos(a) * 0.10);
        sp.rotation.x = a * 0.4;
        trapProp.add(sp);
      }
    } else if (t.kind === 'bramble') {
      // Tangled vines — flat splat plus a couple of upright thorn spikes.
      trapProp = new THREE.Group();
      const mat = new THREE.MeshToonMaterial({ color: 0x4a6630 });
      const splat = new THREE.Mesh(new THREE.CircleGeometry(0.32, 14), mat);
      splat.rotation.x = -Math.PI / 2;
      splat.position.y = 0.02;
      trapProp.add(splat);
      const thornMat = new THREE.MeshToonMaterial({ color: 0x2a3818 });
      for (let i = 0; i < 4; i++) {
        const th = new THREE.Mesh(new THREE.ConeGeometry(0.03, 0.12, 5), thornMat);
        const a = (i / 4) * Math.PI * 2;
        th.position.set(Math.sin(a) * 0.18, 0.06, Math.cos(a) * 0.18);
        trapProp.add(th);
      }
    }
    if (trapProp) {
      trapProp.position.x = t.x + 0.5;
      trapProp.position.z = t.y + 0.5;
      trapProp.userData.trap = t;
      group.add(trapProp);
    }
  }

  // Locked doors — stone arch + colored panel. Color encodes which key
  // unlocks: iron (dark grey), gold (warm brass), thorn (bramble green).
  // Unlocked doors are rendered with the panel slid aside so the player
  // can see the lock has been used. userData.door pins the data so
  // _checkDoorAt in main.js can find + mutate the right mesh.
  const DOOR_COLORS = {
    iron:  { panel: 0x4a4842, lock: 0x6e6862 },
    gold:  { panel: 0xb89236, lock: 0xd4af37 },
    thorn: { panel: 0x4a6630, lock: 0x6f8a3f },
  };
  for (const d of layout.doors || []) {
    const palette = DOOR_COLORS[d.color] || DOOR_COLORS.iron;
    const door = new THREE.Group();
    // Stone arch — left + right pillars + lintel.
    const stoneMat = new THREE.MeshToonMaterial({ color: 0x6a5e52 });
    for (const px of [-0.42, 0.42]) {
      const p = new THREE.Mesh(new THREE.BoxGeometry(0.16, 1.20, 0.20), stoneMat);
      p.position.set(px, 0.60, 0);
      door.add(p);
    }
    const lintel = new THREE.Mesh(new THREE.BoxGeometry(1.10, 0.18, 0.22), stoneMat);
    lintel.position.set(0, 1.30, 0);
    door.add(lintel);
    // Panel — slides off-center if unlocked so the door reads as "open".
    const panel = new THREE.Mesh(
      new THREE.BoxGeometry(0.78, 1.10, 0.10),
      new THREE.MeshToonMaterial({ color: palette.panel }),
    );
    panel.position.set(d.locked === false ? -0.55 : 0, 0.55, 0.05);
    panel.userData.role = 'panel';
    door.add(panel);
    // Lock plate — small accent on the panel; hidden when unlocked.
    const lock = new THREE.Mesh(
      new THREE.BoxGeometry(0.16, 0.16, 0.04),
      new THREE.MeshToonMaterial({ color: palette.lock }),
    );
    lock.position.set(0, 0.50, 0.12);
    lock.userData.role = 'lock';
    lock.visible = d.locked !== false;
    door.add(lock);
    door.position.set(d.x + 0.5, 0, d.y + 0.5);
    door.userData.door = d;
    group.add(door);
  }

  // Reward chest — wood box with a gold band, sits next to the exit
  if (layout.chestTile) {
    const chest = new THREE.Group();
    const box = new THREE.Mesh(
      new THREE.BoxGeometry(0.45, 0.32, 0.30),
      new THREE.MeshToonMaterial({ color: 0x6e4a2a })
    );
    box.position.y = 0.16;
    chest.add(box);
    const lid = new THREE.Mesh(
      new THREE.BoxGeometry(0.46, 0.10, 0.31),
      new THREE.MeshToonMaterial({ color: 0x8a6438 })
    );
    lid.position.y = 0.36;
    chest.add(lid);
    const band = new THREE.Mesh(
      new THREE.BoxGeometry(0.50, 0.05, 0.32),
      new THREE.MeshToonMaterial({ color: 0xb58637 })
    );
    band.position.y = 0.20;
    chest.add(band);
    // Soft gold glow above to draw the eye
    const glow = new THREE.PointLight(0xffcc66, 1.0, 6);
    glow.position.y = 1.2;
    chest.add(glow);
    chest.position.set(layout.chestTile.x + 0.5, 0, layout.chestTile.y + 0.5);
    chest.userData.kind = 'lootChest';
    group.add(chest);
    group.userData.chest = chest;
  }

  group.userData.entry = layout.entry;
  group.userData.exit  = layout.exit;
  group.userData.entryDisc = entryDisc;
  group.userData.exitDisc  = exitDisc;
  return group;
}

/**
 * Pure-data chest loot generator. Thin wrapper over rollChest in
 * src/data/lootTables.js — that's the single file the balance team
 * touches when tuning. This shim stays so existing call sites in
 * main.js don't have to change.
 */
export function generateDungeonLoot(tier, affixes = [], scope = undefined) {
  return rollChest(tier, scope, affixes);
}

// ---- helpers ----------------------------------------------------------

function hCorridor(grid, x0, x1, y) {
  const [a, b] = x0 < x1 ? [x0, x1] : [x1, x0];
  for (let x = a; x <= b; x++) grid[y][x] = 'floor';
}
function vCorridor(grid, y0, y1, x) {
  const [a, b] = y0 < y1 ? [y0, y1] : [y1, y0];
  for (let y = a; y <= b; y++) grid[y][x] = 'floor';
}
function roomCenter(r) {
  return { x: r.x + ((r.w / 2) | 0), y: r.y + ((r.h / 2) | 0) };
}
function pickFarthest(rooms) {
  let best = [rooms[0], rooms[1] || rooms[0]];
  let bestD = 0;
  for (let i = 0; i < rooms.length; i++) {
    for (let j = i + 1; j < rooms.length; j++) {
      const a = roomCenter(rooms[i]), b = roomCenter(rooms[j]);
      const d = (a.x - b.x) ** 2 + (a.y - b.y) ** 2;
      if (d > bestD) { bestD = d; best = [rooms[i], rooms[j]]; }
    }
  }
  return best;
}

// Deterministic seedable RNG so the same chart can re-roll the same dungeon
// (useful when we ship affixes — keystone always opens the same layout).
function mulberry32(a) {
  return function () {
    let t = (a += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export const DUNGEON_GRID = GRID;
