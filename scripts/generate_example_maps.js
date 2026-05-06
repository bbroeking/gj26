// Generate five sample dungeon layouts that exercise the full editor →
// procgen pipeline. Each maps cleanly onto a feature category:
//
//   1. tutorial-hollow  — authored mode, hand-placed mobs (Stage 0)
//   2. briar-maze       — scaffold + procgen padding + boss tag (Stage A+B)
//   3. sunken-shrine    — scaffold + shrine tag + festival pace
//   4. delve-floor-1    — scaffold + treasure tag + boss tag + staircase
//   5. delve-floor-2    — paired with #4 via staircase (multi-floor)
//
// Output:
//   docs/example_maps/<name>.json       (one per map, paste into Import…)
//   docs/example_maps/library.json      (full bundle for localStorage)
//
// To load:
//   - Open editor.html, click Import…, paste the contents of one of the
//     .json files. Save & Test to play.
//   - Or paste this into devtools to install all five at once:
//       localStorage.setItem('gj26.dungeon_library',
//         JSON.stringify(/* contents of library.json */));

const fs = require('fs');
const path = require('path');

// ---- helpers -----------------------------------------------------------

const LEGEND = { '#': 'wall', '.': 'floor' };

/** ascii[row][col] → string[][] grid[y][x]. '.' = floor, anything else = wall. */
function ascii(rows) {
  return rows.map(row => [...row].map(c => LEGEND[c] || 'wall'));
}

function makeProcgen({ tier = 1, rune = null, seed = null, affixes = [] } = {}) {
  return { tier, runeEffect: rune, seed, affixIds: affixes };
}

function makeMap(opts) {
  const grid = ascii(opts.rows);
  const h = grid.length, w = grid[0].length;
  return {
    name: opts.name,
    scope: opts.scope,
    mode: opts.mode || 'authored',
    procgenPadding: opts.procgenPadding ?? true,
    size: { w, h },
    grid,
    entry: opts.entry,
    exit:  opts.exit,
    chestTile: opts.chestTile || null,
    decor: opts.decor || [],
    spawns: opts.spawns || [],
    staircases: opts.staircases || [],
    roomTags: opts.roomTags || [],
    bossKind: opts.bossKind || null,
    procgen: makeProcgen(opts.procgen),
  };
}

// ---- maps --------------------------------------------------------------

// 1) Tutorial Hollow — authored, two rooms + L-corridor, 3 imps. 14x14.
const tutorialHollow = makeMap({
  name: 'tutorial-hollow',
  scope: 'hollow',
  mode: 'authored',
  procgenPadding: false,
  rows: [
    '##############',
    '#.....########',
    '#.....########',
    '#.....########',
    '#.....########',
    '#####.########',
    '#####.########',
    '#####.########',
    '#####.########',
    '#####....#####',
    '########.....#',
    '########.....#',
    '########.....#',
    '##############',
  ],
  entry:     { x: 2, y: 2 },
  exit:      { x: 12, y: 12 },
  chestTile: { x: 11, y: 12 },
  spawns: [
    { kind: 'bramble_imp', x: 3, y: 3 },
    { kind: 'bramble_imp', x: 5, y: 7 },
    { kind: 'bramble_cap', x: 11, y: 11 },
  ],
  procgen: { tier: 1, affixes: [] },
});

// 2) Briar Maze — scaffold mode. 4 painted rooms, no corridors. Procgen
//    will detect rooms, carve corridors between them, and fill mob spawns.
//    Hedgemother awaits in the corner.
const briarMaze = makeMap({
  name: 'briar-maze',
  scope: 'briar_maze',
  mode: 'scaffold',
  procgenPadding: true,
  rows: [
    '######################',
    '#.....######.....#####',
    '#.....######.....#####',
    '#.....######.....#####',
    '#.....######.....#####',
    '#.....##############',
    '######################'.slice(0, 22),
    '######################'.slice(0, 22),
    '###############....###',
    '###############....###',
    '###############....###',
    '###############....###',
    '######################',
    '#####.....############',
    '#####.....############',
    '#####.....############',
    '#####.....############',
    '######################',
    '######################',
    '######################',
    '######################',
    '######################',
  ],
  entry: { x: 3, y: 3 },
  exit:  { x: 18, y: 10 },
  // Tag every painted room with its intent. Loader looks up which room
  // (by bbox) contains each tag tile.
  roomTags: [
    { x: 3,  y: 3,  tag: 'mob' },         // entry room (default)
    { x: 14, y: 3,  tag: 'treasure' },    // top-right room
    { x: 18, y: 10, tag: 'boss' },        // mid-right room → hedgemother
    { x: 7,  y: 14, tag: 'mob' },         // bottom-left room
  ],
  bossKind: 'hedgemother',
  procgen: { tier: 2, affixes: ['bramble_bloom', 'hedgemother_den'] },
});

// 3) Sunken Shrine — scaffold mode, 3 rooms, middle room is a shrine
//    (no mob, thorn-pillar drops in as the rune-pedestal placeholder).
//    Festival pace adds an extra mob to the other rooms.
const sunkenShrine = makeMap({
  name: 'sunken-shrine',
  scope: 'sunken_hut',
  mode: 'scaffold',
  procgenPadding: true,
  rows: [
    '##################',
    '#......###########',
    '#......###########',
    '#......###########',
    '#......###########',
    '##################',
    '######......######',
    '######......######',
    '######......######',
    '######......######',
    '##################',
    '###########......#',
    '###########......#',
    '###########......#',
    '###########......#',
    '##################',
    '##################',
    '##################',
  ],
  entry: { x: 3, y: 3 },
  exit:  { x: 14, y: 13 },
  roomTags: [
    { x: 3,  y: 3,  tag: 'mob' },
    { x: 9,  y: 8,  tag: 'shrine' },     // middle = shrine, no mob
    { x: 14, y: 13, tag: 'mob' },
  ],
  procgen: { tier: 3, affixes: ['festival_pace', 'mineral_vein'] },
});

// 4) Delve Floor 1 — scaffold, treasure room + boss (burrow boar). The
//    entry room contains a staircase down to delve-floor-2.
const delveF1 = makeMap({
  name: 'delve-floor-1',
  scope: 'delve',
  mode: 'scaffold',
  procgenPadding: true,
  rows: [
    '######################',
    '#......###############',
    '#......###############',
    '#......###############',
    '#......###############',
    '######################',
    '#####............#####',
    '#####............#####',
    '#####............#####',
    '######################',
    '######################',
    '##############.......#',
    '##############.......#',
    '##############.......#',
    '##############.......#',
    '######################',
    '######################',
    '#####.....############',
    '#####.....############',
    '#####.....############',
    '######################',
    '######################',
  ],
  entry: { x: 3, y: 3 },
  exit:  { x: 17, y: 13 },
  roomTags: [
    { x: 3,  y: 3,  tag: 'mob' },
    { x: 10, y: 7,  tag: 'treasure' },   // wide center room → chest moves here
    { x: 17, y: 13, tag: 'boss' },       // boss room → burrow_boar
    { x: 7,  y: 18, tag: 'mob' },
  ],
  staircases: [
    { x: 4, y: 3, target: 'delve-floor-2' },
  ],
  bossKind: 'burrow_boar',
  procgen: { tier: 4, affixes: ['mineral_vein', 'burrow_boar_den'] },
});

// 5) Delve Floor 2 — paired with floor 1 via staircase. Wolf alpha boss,
//    gem seam loot bias, no treasure room (chest defaults near exit).
const delveF2 = makeMap({
  name: 'delve-floor-2',
  scope: 'delve',
  mode: 'scaffold',
  procgenPadding: true,
  rows: [
    '######################',
    '#......###############',
    '#......###############',
    '#......###############',
    '######################',
    '######################',
    '#####............#####',
    '#####............#####',
    '#####............#####',
    '#####............#####',
    '######################',
    '######################',
    '#############........#',
    '#############........#',
    '#############........#',
    '######################',
    '######################',
    '######################',
    '######################',
    '######################',
    '######################',
    '######################',
  ],
  entry: { x: 3, y: 2 },
  exit:  { x: 17, y: 13 },
  roomTags: [
    { x: 3,  y: 2,  tag: 'mob' },
    { x: 10, y: 7,  tag: 'mob' },
    { x: 17, y: 13, tag: 'boss' },       // wolf_alpha
  ],
  staircases: [
    { x: 4, y: 2, target: 'delve-floor-1' },
  ],
  bossKind: 'wolf_alpha',
  procgen: { tier: 5, affixes: ['gem_seam', 'wolf_alpha_den'] },
});

// ---- write outputs -----------------------------------------------------

const ALL = [tutorialHollow, briarMaze, sunkenShrine, delveF1, delveF2];

const outDir = path.resolve(__dirname, '../docs/example_maps');
fs.mkdirSync(outDir, { recursive: true });

// Per-map files for one-at-a-time Import…
for (const m of ALL) {
  fs.writeFileSync(
    path.join(outDir, m.name + '.json'),
    JSON.stringify(m, null, 2),
  );
}

// Library bundle for direct localStorage paste. Shape matches the editor's
// `gj26.dungeon_library` schema: { [name]: { savedAt, json } }.
const library = {};
const now = Date.now();
for (const m of ALL) library[m.name] = { savedAt: now, json: m };
fs.writeFileSync(
  path.join(outDir, 'library.json'),
  JSON.stringify(library, null, 2),
);

console.log(`Wrote ${ALL.length} maps + library.json to docs/example_maps/`);
for (const m of ALL) {
  console.log(`  - ${m.name.padEnd(18)} ${m.mode.padEnd(8)} `
    + `${m.scope.padEnd(11)} t${m.procgen.tier} `
    + `${m.size.w}×${m.size.h}  rooms=${m.roomTags.length}  `
    + `affixes=${m.procgen.affixIds.length}`);
}
