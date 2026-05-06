// Generate a sheet of random dungeons that respect the in-game Cartography
// rules. Each output is a scaffold-mode JSON layout you can drop into the
// editor's library; running Test in game spins up the dungeon as if it
// were inscribed at the given carto level.
//
// Usage:
//   node scripts/generate_random_dungeons.js [count] [cartoLv]
// Defaults: count=8, cartoLv=20.
//
// Output:
//   docs/example_maps/random/<name>.json    (per-map files)
//   docs/example_maps/random/library.json   (bundle, paste into localStorage)

const fs   = require('fs');
const path = require('path');

// ---- carto rules (mirrors src/data/affixes.js) -------------------------
//
// Every affix has a baseStab (good-outcome % at carto 1). At higher carto,
// the player both *unlocks* more affixes (reqCarto) and *stabilises* the
// roll (good % rises with carto). Refined ink is a one-shot 100% lock.
//
// maxSlots(tier, cartoLv) = min(tier, 1+floor(cartoLv/15), 2)   [V1 cap]
// effectiveStab = min(95, baseStab + cartoLv * 0.6)
//
// reqCarto determines what's even on the menu.

const AFFIXES = [
  // boss
  { id: 'hedgemother_den', kind: 'boss',     reqCarto: 8,  baseStab: 50 },
  { id: 'burrow_boar_den', kind: 'boss',     reqCarto: 12, baseStab: 48 },
  { id: 'wolf_alpha_den',  kind: 'boss',     reqCarto: 14, baseStab: 46 },
  // bias / resource
  { id: 'mineral_vein',    kind: 'bias',     reqCarto: 1,  baseStab: 55 },
  { id: 'bramble_bloom',   kind: 'bias',     reqCarto: 4,  baseStab: 55 },
  { id: 'tinder_cache',    kind: 'bias',     reqCarto: 6,  baseStab: 55 },
  { id: 'ink_spring',      kind: 'bias',     reqCarto: 18, baseStab: 42 },
  { id: 'wood_grove',      kind: 'bias',     reqCarto: 8,  baseStab: 50 },
  { id: 'herbal_patch',    kind: 'bias',     reqCarto: 10, baseStab: 48 },
  { id: 'gilded_seam',     kind: 'bias',     reqCarto: 14, baseStab: 45 },
  { id: 'gem_seam',        kind: 'bias',     reqCarto: 22, baseStab: 38 },
  // modifier (combat math)
  { id: 'tyrannical',      kind: 'modifier', reqCarto: 5,  baseStab: 52 },
  { id: 'bursting',        kind: 'modifier', reqCarto: 9,  baseStab: 50 },
  { id: 'frenzied',        kind: 'modifier', reqCarto: 12, baseStab: 48 },
  { id: 'fog_of_hedge',    kind: 'modifier', reqCarto: 17, baseStab: 45 },
  // pacing
  { id: 'festival_pace',   kind: 'pacing',   reqCarto: 7,  baseStab: 52 },
];

const BOSS_KINDS = { hedgemother_den: 'hedgemother', burrow_boar_den: 'burrow_boar', wolf_alpha_den: 'wolf_alpha' };
const SCOPES     = ['briar_maze', 'sunken_hut', 'delve', 'hollow'];
const RUNES      = [null, null, 'fire', 'earth', 'water', 'air'];   // mostly no rune

function maxSlots(tier, cartoLv) {
  return Math.min(Math.max(1, Math.min(5, tier)), 1 + Math.floor(cartoLv / 15), 2);
}
function effectiveStab(affix, cartoLv) {
  return Math.min(95, Math.round(affix.baseStab + cartoLv * 0.6));
}

// ---- deterministic RNG so the same seed reproduces the dungeon ----------
function mulberry32(a) {
  return function () {
    let t = (a += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
function pick(rng, arr) { return arr[Math.floor(rng() * arr.length)]; }

// ---- dungeon recipe -----------------------------------------------------
//
// Each generated layout is a scaffold-mode level with two small painted
// rooms (entry + exit). Procgen padding adds 1-3 random rooms; corridor
// carving connects everything. Affixes are rolled per the carto rules so
// the loaded run reflects what an in-game chart at this carto level would
// produce.

function ascii(rows) {
  return rows.map(r => [...r].map(c => c === '.' ? 'floor' : 'wall'));
}

const SHELL_22 = [
  '######################',
  '#......###############',
  '#......###############',
  '#......###############',
  '#......###############',
  '######################',
  '######################',
  '######################',
  '######################',
  '######################',
  '######################',
  '######################',
  '######################',
  '######################',
  '######################',
  '######################',
  '######################',
  '###############......#',
  '###############......#',
  '###############......#',
  '###############......#',
  '######################',
];

function rollAffixes(rng, tier, cartoLv) {
  const slots = maxSlots(tier, cartoLv);
  const eligible = AFFIXES.filter(a => a.reqCarto <= cartoLv);
  // Don't roll two boss affixes (only one boss room per dungeon).
  const out = [];
  let bossPicked = false;
  while (out.length < slots && eligible.length > 0) {
    const a = pick(rng, eligible);
    if (a.kind === 'boss' && bossPicked) continue;
    if (out.find(x => x.id === a.id)) continue;
    if (a.kind === 'boss') bossPicked = true;
    // Roll good/bad twin.
    const stab = effectiveStab(a, cartoLv);
    const good = rng() * 100 < stab;
    out.push({ id: a.id, good, resolvedId: good ? a.id : `${a.id}__bad`, kind: a.kind });
    if (out.length >= slots) break;
    if (out.length >= eligible.length) break;
  }
  return out;
}

function makeRandomLayout(rng, seed, idx, cartoLv) {
  const tier = 1 + Math.floor(rng() * 5);
  const scope = pick(rng, SCOPES);
  const runeEffect = pick(rng, RUNES);
  const affixRolls = rollAffixes(rng, tier, cartoLv);
  // Boss room: only if a boss affix landed *good*.
  const bossAffix = affixRolls.find(a => a.kind === 'boss' && a.good);
  const bossKind  = bossAffix ? BOSS_KINDS[bossAffix.id] : null;
  // Filter to ids the loader expects (bad twins still count for runtime
  // effects; main.js only fires "good" branches but the affix is in play).
  const affixIds = affixRolls.filter(a => a.good).map(a => a.id);

  return {
    name: `random-${String(idx + 1).padStart(2, '0')}-${scope}-t${tier}`,
    scope,
    mode: 'scaffold',
    procgenPadding: true,
    useBrushes: false,
    brushes: null,
    size: { w: 22, h: 22 },
    grid: ascii(SHELL_22),
    entry: { x: 3, y: 3 },
    exit:  { x: 18, y: 19 },
    chestTile: null,    // scaffold places it near exit, treasure tag overrides
    decor: [],
    spawns: [],
    staircases: [],
    roomTags: [
      { x: 3,  y: 3,  tag: 'mob' },
      { x: 18, y: 19, tag: bossKind ? 'boss' : 'mob' },
    ],
    bossKind,
    procgen: {
      tier,
      runeEffect,
      seed: String(seed),
      affixIds,
    },
    // Diagnostic — not read by the loader, but useful to inspect the roll.
    _carto: {
      cartoLv,
      maxSlots: maxSlots(tier, cartoLv),
      rolls: affixRolls.map(a => ({
        id: a.id,
        good: a.good,
        stab: effectiveStab(AFFIXES.find(x => x.id === a.id), cartoLv),
      })),
    },
  };
}

// ---- driver ------------------------------------------------------------

const argv = process.argv.slice(2);
const count    = parseInt(argv[0], 10) || 8;
const cartoLv  = parseInt(argv[1], 10) || 20;
const baseSeed = Math.floor(Math.random() * 0xffffffff);

const outDir = path.resolve(__dirname, '../docs/example_maps/random');
fs.rmSync(outDir, { recursive: true, force: true });
fs.mkdirSync(outDir, { recursive: true });

const layouts = [];
for (let i = 0; i < count; i++) {
  const seed = (baseSeed ^ (i * 2654435761)) >>> 0;
  const rng  = mulberry32(seed);
  const m = makeRandomLayout(rng, seed, i, cartoLv);
  layouts.push(m);
  fs.writeFileSync(path.join(outDir, m.name + '.json'), JSON.stringify(m, null, 2));
}

const library = {};
const now = Date.now();
for (const m of layouts) library[m.name] = { savedAt: now, json: m };
fs.writeFileSync(path.join(outDir, 'library.json'), JSON.stringify(library, null, 2));

console.log(`Generated ${layouts.length} dungeons at carto ${cartoLv} (slots/tier capped at ${maxSlots(5, cartoLv)})`);
console.log('');
console.log('  Name                              tier  scope        rune    boss          affixes');
console.log('  --------------------------------  ----  -----------  ------  ------------  ----------------');
for (const m of layouts) {
  const aff = m.procgen.affixIds.length ? m.procgen.affixIds.join(',') : '—';
  console.log(`  ${m.name.padEnd(34)}  t${m.procgen.tier}    `
    + `${m.scope.padEnd(11)}  ${(m.procgen.runeEffect || '—').padEnd(6)}  `
    + `${(m.bossKind || '—').padEnd(12)}  ${aff}`);
}
console.log('');
console.log('Loaded into editor library:');
console.log('  fetch("docs/example_maps/random/library.json")');
console.log('    .then(r => r.json())');
console.log('    .then(lib => localStorage.setItem("gj26.dungeon_library", JSON.stringify(lib)));');
