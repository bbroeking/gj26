// Living Atlas — region definitions for Wayfinding Depth #20.
//
// Every chart the player completes is tagged by its `scope` (snug, hollow,
// delve, sunken_hut, briar_maze, biome_*) — and each scope counts toward
// exactly one region. Once the player crosses a region's `threshold`,
// the listed `biomeUnlock` becomes a walkable destination from the Atlas.
//
// Scopes are a stable contract from items.js / charting.js (TEMPLATES
// table). New themed templates (Wayfinding Depth #1) would extend
// the `scopes` array of an existing region or define a new region.

export const ATLAS_REGIONS = [
  {
    id: 'bramble_hollows',
    name: 'Bramble Hollows',
    lore: 'The hedge above Bramblewood, knotted into pocket cellars and snug rooms. The first lines a cartographer walks.',
    scopes: ['snug', 'tier_1', 'hollow', 'briar_maze'],
    threshold: 3,
    biomeUnlock: 'biome_mossvale',
    biomeName: 'Mossvale',
    biomeDesc: 'A lichened glade beyond the hedge. Quiet, green, and waiting.',
  },
  {
    id: 'drowned_lanes',
    name: 'Drowned Lanes',
    lore: 'Where the wellsprings overflow into the old stone — sunken huts and half-flooded rooms.',
    scopes: ['sunken_hut'],
    threshold: 4,
    biomeUnlock: 'biome_stillwater',
    biomeName: 'Stillwater Fens',
    biomeDesc: 'A stilled marsh where the water remembers your steps.',
  },
  {
    id: 'earthroot_drifts',
    name: 'Earthroot Drifts',
    lore: 'Deep delves under the forge-line. Hot air, ore-veins, and harder enemies.',
    scopes: ['delve'],
    threshold: 5,
    biomeUnlock: 'biome_coalrose',
    biomeName: 'Coalrose Pits',
    biomeDesc: 'An ember-warm hollow where the rocks bloom red.',
  },
  {
    id: 'wightspires',
    name: 'Wightspires',
    lore: 'Old hedge-bones and bramble-thorned spires — sanguine lines run hot here.',
    scopes: ['biome_wightspire_pre'],   // placeholder: future themed templates
    threshold: 6,
    biomeUnlock: 'biome_wightspire',
    biomeName: 'Wightspire Reach',
    biomeDesc: 'A jagged red spire — the bramble-king\'s old roost.',
  },
  {
    id: 'echoes',
    name: 'The Echoes',
    lore: 'Reflections of the village walked by other shapes. Each echo cleared deepens your knowledge of the place.',
    scopes: ['echo_village', 'echo_forge', 'echo_perch'],
    threshold: 5,
    biomeUnlock: 'biome_echofold',
    biomeName: 'The Echofold',
    biomeDesc: 'A liminal hollow where every village you know overlaps at once.',
  },
];

/** Find which region a given chart scope counts toward. Returns null if
 *  the scope isn't tracked (e.g. biome scopes themselves don't recurse). */
export function regionForScope(scope) {
  if (!scope) return ATLAS_REGIONS[0];     // default: untyped charts → Bramble Hollows
  for (const r of ATLAS_REGIONS) {
    if (r.scopes.includes(scope)) return r;
  }
  return null;
}

/** Look up a region by id. */
export function regionById(id) {
  return ATLAS_REGIONS.find(r => r.id === id) || null;
}
