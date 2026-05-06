// Per-tier + per-scope enemy spawn tables for procedural dungeons.
//
// Two-axis lookup:
//   - tier: 1..5 (chart difficulty)
//   - scope: which themed dungeon ('briar_maze' | 'sunken_hut' | 'delve' | 'hollow' | undefined)
//   - slot: 'mob' (regular) | 'guard' (penultimate room mini-boss)
//
// Boss rooms are NOT in this table — they're affix-driven and resolved
// by `layout.bossKind` in dungeon.js. This table only fills the rest.

/** Default mob pool by tier. Used when scope is unknown. */
const MOB_DEFAULT = {
  1: [['goblin', 45], ['hare', 25], ['skitterling', 20], ['archer', 10]],
  2: [['goblin', 30], ['hare', 15], ['skitterling', 15], ['marshRat', 15], ['boar', 10], ['archer', 15]],
  3: [['goblin', 15], ['boar', 20], ['hedgewolf', 15], ['ironGob', 15], ['brambleCap', 10], ['archer', 15], ['charger', 10]],
  4: [['ironGob', 15], ['hedgewolf', 25], ['tuskerSow', 15], ['brambleCap', 15], ['archer', 15], ['charger', 15]],
  5: [['hedgewolf', 25], ['tuskerSow', 15], ['brambleCap', 20], ['ironGob', 15], ['archer', 10], ['charger', 15]],
};

/** Briar Maze — thorn-themed. Heavy bramble enemies. */
const MOB_BRIAR = {
  1: [['skitterling', 60], ['goblin', 40]],
  2: [['skitterling', 40], ['goblin', 35], ['marshRat', 25]],
  3: [['skitterling', 25], ['goblin', 25], ['ironGob', 30], ['brambleCap', 20]],
  4: [['ironGob', 30], ['brambleCap', 50], ['hedgewolf', 20]],
  5: [['brambleCap', 60], ['ironGob', 20], ['hedgewolf', 20]],
};

/** Sunken Hut — bog-themed. Heavy marsh enemies. */
const MOB_SUNKEN = {
  1: [['marshRat', 50], ['hare', 30], ['goblin', 20]],
  2: [['marshRat', 50], ['boar', 30], ['goblin', 20]],
  3: [['marshRat', 30], ['boar', 35], ['tuskerSow', 25], ['hedgewolf', 10]],
  4: [['boar', 25], ['tuskerSow', 45], ['hedgewolf', 30]],
  5: [['tuskerSow', 50], ['hedgewolf', 40], ['boar', 10]],
};

/** Delve — deep stone. Heavy iron-gob enemies. */
const MOB_DELVE = {
  1: [['goblin', 70], ['skitterling', 30]],
  2: [['goblin', 50], ['ironGob', 30], ['skitterling', 20]],
  3: [['ironGob', 50], ['goblin', 25], ['hedgewolf', 25]],
  4: [['ironGob', 60], ['hedgewolf', 30], ['brambleCap', 10]],
  5: [['ironGob', 50], ['hedgewolf', 35], ['brambleCap', 15]],
};

const SCOPE_MOB_TABLES = {
  briar_maze: MOB_BRIAR,
  sunken_hut: MOB_SUNKEN,
  delve:      MOB_DELVE,
  hollow:     MOB_DEFAULT,    // default mix for hollow
  snug:       MOB_DEFAULT,    // tiny "pocket cellar" charts share the default mix
};

/** Penultimate-room "guard" — last barrier before the chest/exit.
 *  Always more dangerous than the mob pool. */
const GUARD_BY_TIER = {
  1: [['brambleCap', 100]],
  2: [['brambleCap', 70], ['ironGob', 30]],
  3: [['brambleCap', 50], ['ironGob', 30], ['hedgewolf', 20]],
  4: [['brambleCap', 30], ['hedgewolf', 50], ['tuskerSow', 20]],
  5: [['hedgewolf', 50], ['tuskerSow', 35], ['brambleCap', 15]],
};

/** Pick a spawn-fn key by weighted roll.
 *  @param {number} tier  1..5
 *  @param {'mob'|'guard'} slot
 *  @param {string|undefined} scope  'briar_maze' | 'sunken_hut' | 'delve' | 'hollow'
 *  @param {() => number} [rng=Math.random]
 */
export function pickFor(tier, slot, scope, rng = Math.random) {
  const t = Math.max(1, Math.min(5, tier | 0));
  let pool;
  if (slot === 'guard') {
    pool = GUARD_BY_TIER[t];
  } else {
    const table = SCOPE_MOB_TABLES[scope] || MOB_DEFAULT;
    pool = table[t];
  }
  if (!pool || !pool.length) return 'goblin';
  const total = pool.reduce((s, [, w]) => s + w, 0);
  let r = rng() * total;
  for (const [key, w] of pool) {
    r -= w;
    if (r <= 0) return key;
  }
  return pool[pool.length - 1][0];
}
