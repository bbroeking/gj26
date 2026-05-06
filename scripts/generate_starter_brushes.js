// Bootstrap a starter brush library. The brush procgen-stamping pass
// (Stage C half 2) only does anything when there's a brush library, so
// shipping a starter set unlocks the feature for new authors.
//
// Each brush is a small rectangular prefab encoded in ASCII for readability:
//   '#' = wall, '.' = floor, glyph keys for decor / spawns / tags
//
// Usage:
//   node scripts/generate_starter_brushes.js
// Output:
//   docs/example_maps/starter_brushes.json   (paste into localStorage)
//
// Load into the editor:
//   fetch('docs/example_maps/starter_brushes.json')
//     .then(r => r.json())
//     .then(b => localStorage.setItem('gj26.dungeon_brushes', JSON.stringify(b)));

const fs   = require('fs');
const path = require('path');

// Brush authoring shorthand. Each row is the same length. Glyphs:
//   '#'  wall
//   '.'  floor
//   'M'  floor + mob roomtag
//   'B'  floor + boss roomtag
//   'T'  floor + treasure roomtag
//   'S'  floor + shrine roomtag
//   'P'  floor + puzzle roomtag
//   'i'  floor + bramble_imp spawn
//   'I'  floor + bramble_cap spawn
//   'g'  floor + iron_gob spawn
//   'a'  floor + bramble_archer spawn
//   'c'  floor + bramble_charger spawn
//   'h'  floor + hedgewolf spawn
//   '*'  floor + thorn_pillar decor
//   'o'  floor + ore_rock decor
//   '~'  floor + puddle decor
//   'b'  floor + boulder decor
//   'm'  floor + mossfloor decor
const ROOMTAG = { M: 'mob', B: 'boss', T: 'treasure', S: 'shrine', P: 'puzzle' };
const SPAWN   = { i: 'bramble_imp', I: 'bramble_cap', g: 'iron_gob',
                  a: 'bramble_archer', c: 'bramble_charger', h: 'hedgewolf' };
const DECOR   = { '*': 'thorn_pillar', o: 'ore_rock', '~': 'puddle',
                  b: 'boulder', m: 'mossfloor' };

function compileBrush({ name, scope, rows }) {
  const w = rows[0].length, h = rows.length;
  const grid = [], decor = [], spawns = [], roomTags = [];
  for (let y = 0; y < h; y++) {
    const gridRow = [];
    for (let x = 0; x < w; x++) {
      const c = rows[y][x];
      if (c === '#') {
        gridRow.push('wall');
        continue;
      }
      gridRow.push('floor');
      if (ROOMTAG[c]) roomTags.push({ tag: ROOMTAG[c], x, y });
      else if (SPAWN[c]) spawns.push({ kind: SPAWN[c], x, y });
      else if (DECOR[c]) decor.push({ kind: DECOR[c], x, y });
    }
    grid.push(gridRow);
  }
  return { name, w, h, grid, decor, spawns, roomTags, scope };
}

// ---- starter brushes ---------------------------------------------------

const BRUSHES = [
  // Tight ambush corridor — 2 imps tucked at corners. Reads as a chokepoint.
  compileBrush({
    name: 'imp-ambush',
    scope: 'briar_maze',
    rows: [
      '##i##',
      '#...#',
      'M...M',
      '#...#',
      '##i##',
    ],
  }),

  // Treasure chamber — chest implied by treasure tag, two thorn pillars.
  compileBrush({
    name: 'treasure-chamber',
    scope: 'briar_maze',
    rows: [
      '#######',
      '#*...*#',
      '#.....#',
      '#..T..#',
      '#.....#',
      '#*...*#',
      '#######',
    ],
  }),

  // Shrine (rune pedestal) — bigger room, central marker, no spawns.
  compileBrush({
    name: 'shrine-room',
    scope: 'hollow',
    rows: [
      '#######',
      '#.....#',
      '#.*.*.#',
      '#..S..#',
      '#.*.*.#',
      '#.....#',
      '#######',
    ],
  }),

  // Boss arena — wider room with two charger spawns and a boss tag.
  compileBrush({
    name: 'boss-arena',
    scope: 'delve',
    rows: [
      '#########',
      '#.......#',
      '#.b...b.#',
      '#...B...#',
      '#.c...c.#',
      '#.......#',
      '#########',
    ],
  }),

  // Ore vein — a delve-themed prefab with 4 ore rocks for mineral_vein flavor.
  compileBrush({
    name: 'ore-vein',
    scope: 'delve',
    rows: [
      '######',
      '#.o..#',
      '#..o.#',
      '#M..g#',
      '#.o..#',
      '#..o.#',
      '######',
    ],
  }),

  // Sunken puddle pool — sunken_hut flavor, marsh_rat-friendly mob room.
  compileBrush({
    name: 'puddle-pool',
    scope: 'sunken_hut',
    rows: [
      '########',
      '#.~~~..#',
      '#~~M~..#',
      '#.~~~..#',
      '#......#',
      '########',
    ],
  }),

  // Archer perch — narrow + tall, gives an archer a clean lane.
  compileBrush({
    name: 'archer-perch',
    scope: 'briar_maze',
    rows: [
      '###',
      '#.#',
      '#.#',
      '#a#',
      '#.#',
      '#.#',
      '#M#',
      '#.#',
      '#.#',
      '###',
    ],
  }),

  // Cozy alcove — small puzzle room (no mob), couple of decor pieces.
  compileBrush({
    name: 'cozy-alcove',
    scope: 'hollow',
    rows: [
      '#####',
      '#m.m#',
      '#.P.#',
      '#m.m#',
      '#####',
    ],
  }),
];

// ---- emit --------------------------------------------------------------

const outDir = path.resolve(__dirname, '../docs/example_maps');
fs.mkdirSync(outDir, { recursive: true });

const lib = {};
const now = Date.now();
for (const b of BRUSHES) lib[b.name] = { savedAt: now, brush: b };

const outPath = path.join(outDir, 'starter_brushes.json');
fs.writeFileSync(outPath, JSON.stringify(lib, null, 2));

console.log(`Wrote ${BRUSHES.length} starter brushes → ${path.relative(process.cwd(), outPath)}`);
for (const b of BRUSHES) {
  console.log(`  - ${b.name.padEnd(20)} ${b.w}×${b.h.toString().padEnd(2)} ${b.scope.padEnd(11)} `
    + `decor ${b.decor.length} spawns ${b.spawns.length} tags ${b.roomTags.length}`);
}
console.log('');
console.log('Load into the editor brush library:');
console.log('  fetch("docs/example_maps/starter_brushes.json")');
console.log('    .then(r => r.json())');
console.log('    .then(b => localStorage.setItem("gj26.dungeon_brushes", JSON.stringify(b)));');
