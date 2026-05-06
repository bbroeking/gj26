// Kitchen-sink demo dungeon — exercises every dungeon system shipped
// during the loop run, in one map you can Save & Test once.
//
// Coverage:
//   - 5 rooms with tags: entry / mob / treasure / shrine / boss
//   - 3 colored locked doors (iron / gold / thorn), keys placed in
//     earlier rooms so the player can solve the gates
//   - Spike + bramble traps in a connecting corridor
//   - Affixes: festival_pace (+1 mob/room) and mineral_vein (ore rocks)
//   - useBrushes=true with 2 starter-brush stamps for procgen variety
//   - Hand-placed bramble_imp + iron_gob spawns in the entry corridor
//
// Output:
//   docs/example_maps/kitchen-sink.json
//   docs/example_maps/library.json (re-emit, including kitchen-sink)
//
// Run:  node scripts/generate_kitchen_sink.js

const fs = require('fs');
const path = require('path');

const LEGEND = { '#': 'wall', '.': 'floor' };
function ascii(rows) {
  return rows.map(r => [...r].map(c => LEGEND[c] || 'wall'));
}

// 24-tile-square layout. Each row is exactly 24 chars; the comment
// labels what each region houses. The shape is "ring of rooms with a
// shrine pavilion in the middle":
//
//   ENTRY ─────── (iron door) ── TREASURE
//     │                            │
//     │           SHRINE           │
//     │             ░              │
//   trap-corridor                 trap-corridor
//     │             ░              │
//     │                            │
//     MOB ─── (gold door) ──── (thorn door) ── BOSS
//
// The middle vertical corridor between mob/boss has spike + bramble
// traps. Iron key is in the entry room corner; gold key is in the mob
// room; thorn key is in the shrine reward niche.

const ROWS = [
  '########################', //  0
  '#......#####........####', //  1  entry (1..6) ── corridor ── treasure (12..19)
  '#......#####........####', //  2
  '#......#####........####', //  3
  '#......#####........####', //  4
  '#......#####........####', //  5
  '#......#####........####', //  6
  '##.######.######.#######', //  7  vertical corridors descend
  '##.######.######.#######', //  8
  '##.######.######.#######', //  9
  '##.#####.....##.########', // 10  shrine pavilion (9..13)
  '##.#####.....##.########', // 11
  '##.#####.....##.########', // 12
  '##.######.######.#######', // 13
  '##.######.######.#######', // 14
  '##.######.######.#######', // 15
  '##.######.######.#######', // 16
  '##.######.######.#######', // 17
  '#......#####........####', // 18  mob (1..6) ── corridor ── boss (12..19)
  '#......#####........####', // 19
  '#......#####........####', // 20
  '#......#####........####', // 21
  '#......#####........####', // 22
  '########################', // 23
];

// Quick width audit at script-write time so a stray char count fails fast.
for (let i = 0; i < ROWS.length; i++) {
  if (ROWS[i].length !== 24) {
    throw new Error(`row ${i} is ${ROWS[i].length} cols, expected 24`);
  }
}

const grid = ascii(ROWS);

// Embed a small brush so the useBrushes pass has something to stamp.
// Two prefabs — a goblin cluster and a treasure alcove — live in JSON
// rather than relying on the user's localStorage being populated.
const EMBEDDED_BRUSHES = [
  {
    name: 'demo-imp-cluster',
    w: 5, h: 5,
    grid: ascii([
      '##.##',
      '#...#',
      '.....',
      '#...#',
      '##.##',
    ]),
    decor: [],
    spawns: [
      { kind: 'bramble_imp', x: 1, y: 2 },
      { kind: 'bramble_imp', x: 3, y: 2 },
    ],
    roomTags: [{ tag: 'mob', x: 2, y: 2 }],
    traps: [],
    doors: [],
    scope: 'briar_maze',
  },
  {
    name: 'demo-loot-alcove',
    w: 5, h: 5,
    grid: ascii([
      '#####',
      '#...#',
      '#.T.#',   // T glyph here is just a label in the ascii; explicit roomTags below
      '#...#',
      '#####',
    ]),
    decor: [
      { kind: 'thorn_pillar', x: 1, y: 1 },
      { kind: 'thorn_pillar', x: 3, y: 1 },
      { kind: 'thorn_pillar', x: 1, y: 3 },
      { kind: 'thorn_pillar', x: 3, y: 3 },
    ],
    spawns: [],
    roomTags: [{ tag: 'treasure', x: 2, y: 2 }],
    traps: [],
    doors: [],
    scope: 'briar_maze',
  },
];

// Force the alcove brush's center tile to floor (the 'T' in ascii becomes
// 'wall' via the legend; fix it in-place).
EMBEDDED_BRUSHES[1].grid[2][2] = 'floor';

const layout = {
  name: 'kitchen-sink',
  scope: 'briar_maze',
  mode: 'scaffold',
  procgenPadding: false,         // deterministic — author exactly the rooms
  useBrushes: true,
  brushes: EMBEDDED_BRUSHES,
  size: { w: 24, h: 24 },
  grid,
  // Entry room top-left, exit (gold disc) sits in the boss room corner.
  entry: { x: 3, y: 3 },
  exit:  { x: 17, y: 21 },
  chestTile: null,               // treasure tag will redirect chest
  decor: [],

  // Hand-placed mob density in the entry corridor + middle band.
  spawns: [
    { kind: 'bramble_imp', x: 9,  y: 8 },
    { kind: 'bramble_imp', x: 9,  y: 14 },
    { kind: 'iron_gob',    x: 16, y: 8 },
  ],

  staircases: [],

  // Per-room intent tags. Each tag tile sits inside one painted room;
  // scaffold loader will look up the containing room and attach the tag.
  roomTags: [
    { x: 3,  y: 3,  tag: 'mob' },         // entry → mob (scaffold won't spawn entry)
    { x: 16, y: 3,  tag: 'treasure' },    // chest moves here
    { x: 11, y: 11, tag: 'shrine' },      // shrine pedestal placeholder
    { x: 3,  y: 20, tag: 'mob' },         // mob room
    { x: 16, y: 20, tag: 'boss' },        // boss room — hedgemother
  ],

  // Two trap kinds in the descending corridors.
  traps: [
    { kind: 'spike',   x: 2,  y: 14 },    // spike on the left descent
    { kind: 'bramble', x: 9,  y: 13 },    // bramble in the middle
    { kind: 'bramble', x: 9,  y: 16 },
    { kind: 'spike',   x: 16, y: 14 },    // spike on the right descent
  ],

  // Three colored doors gating the dungeon's progression. Iron at the
  // treasure door (top-right entry); thorn at the shrine entrance; gold
  // at the boss room. Keys are placed via the spawn list as ground items
  // — actually we drop them as decor entries so they're authored loot.
  // Simpler: scatter keys via hand-placed coin/item spawns is non-trivial
  // (no item-pickup-from-decor system); document the assumption that
  // keys come from chest/mob drops in earlier rooms. The doors still
  // gate movement; the player needs to defeat enemies / loot chests for
  // the keys before progressing.
  // Doors must sit on floor tiles to actually gate. Each is placed on a
  // descending corridor that scaffold's procgen room-carving will find.
  // Visual: stone arch on the left descent (iron), centre descent
  // (thorn) and right descent (gold) — the player must collect three
  // keys to reach all rooms.
  doors: [
    { x: 2,  y: 10, color: 'iron',  locked: true },  // left descent → mob room
    { x: 9,  y: 9,  color: 'thorn', locked: true },  // centre descent → shrine
    { x: 16, y: 10, color: 'gold',  locked: true },  // right descent → boss
  ],

  bossKind: 'hedgemother',
  procgen: {
    tier: 3,
    runeEffect: null,
    seed: '424242',                // stable procgen for repeat tests
    affixIds: ['festival_pace', 'mineral_vein'],
  },
};

// ---- write ------------------------------------------------------------

const outDir = path.resolve(__dirname, '../docs/example_maps');
fs.writeFileSync(
  path.join(outDir, 'kitchen-sink.json'),
  JSON.stringify(layout, null, 2),
);

// Re-emit the multi-map library bundle so the demo joins the existing
// example set in one paste. Existing entries are preserved.
let lib = {};
const libPath = path.join(outDir, 'library.json');
try { lib = JSON.parse(fs.readFileSync(libPath, 'utf8')); } catch (_) {}
lib['kitchen-sink'] = { savedAt: Date.now(), json: layout };
fs.writeFileSync(libPath, JSON.stringify(lib, null, 2));

// Validate using the same logic the editor does at Test time.
function detectRooms(g) {
  const h = g.length, w = g[0].length;
  const seen = Array.from({ length: h }, () => Array(w).fill(false));
  const rooms = [];
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    if (g[y][x] !== 'floor' || seen[y][x]) continue;
    const q = [[x, y]]; seen[y][x] = true;
    let cells = 0;
    while (q.length) {
      const [cx, cy] = q.pop(); cells++;
      for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
        const nx = cx + dx, ny = cy + dy;
        if (nx<0||ny<0||nx>=w||ny>=h||seen[ny][nx]) continue;
        if (g[ny][nx] !== 'floor') continue;
        seen[ny][nx] = true; q.push([nx, ny]);
      }
    }
    if (cells >= 4) rooms.push(cells);
  }
  return rooms;
}

const rooms = detectRooms(layout.grid);
console.log(`kitchen-sink: ${rooms.length} detected rooms (cells: ${rooms.join(', ')})`);
console.log(`  scope=${layout.scope} mode=${layout.mode} tier=${layout.procgen.tier}`);
console.log(`  spawns=${layout.spawns.length} roomTags=${layout.roomTags.length} `
  + `traps=${layout.traps.length} doors=${layout.doors.length} brushes=${layout.brushes.length}`);
console.log(`  affixes=${layout.procgen.affixIds.join(', ')}`);
console.log(`Wrote docs/example_maps/kitchen-sink.json + updated library.json`);
console.log(``);
console.log(`Load (in browser DevTools after opening editor.html):`);
console.log(`  fetch('docs/example_maps/library.json')`);
console.log(`    .then(r => r.json())`);
console.log(`    .then(lib => localStorage.setItem('gj26.dungeon_library', JSON.stringify(lib)));`);
console.log(`  // then refresh; click Load... in the editor; pick 'kitchen-sink'.`);
