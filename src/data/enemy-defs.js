// Enemy data — single source of truth for the codex AND (eventually) the
// spawn factories in src/game/enemies.js. Today the spawn factories still
// hard-code their own HP / attack values; mirroring them here at least
// keeps the codex from drifting silently when a factory gets retuned.
//
// Fields:
//   kind     — engine identifier (matches the spawn factory's enemy.kind)
//   name     — display string
//   tier     — trivial | easy | medium | hard | elite | boss
//   hp / atk / def / maxHit — combat stats
//   heightM  — shoulder/withers height for quadrupeds, total for upright
//   drops    — item ids dropped (loot tables apply rarity weights)
//   desc     — codex card description
//   model    — GLB filename (for codex Models tab cross-reference)
//   scope    — optional: dungeon scope this enemy is restricted to

export const ENEMY_DEFS = [
  { kind: 'cow',          name: 'Brindlecow',    tier: 'trivial', hp: 8,   atk: 1,  def: 1,  maxHit: 1, heightM: 1.40,
    drops: ['raw_brindle', 'wool_flank', 'coin'],
    desc: 'Passive dairy beast of the south pasture. Cross when bramble-imps stir them.',
    model: 'cow.glb' },
  { kind: 'chicken',      name: 'Pippin Hen',    tier: 'trivial', hp: 2,   atk: 1,  def: 1,  maxHit: 0, heightM: 0.45,
    drops: ['raw_pippin', 'downfeather'],
    desc: 'Pecks the village paths. Easy XP for the freshly-arrived.',
    model: 'chicken.glb' },
  { kind: 'hare',         name: 'Whicker Hare',  tier: 'trivial', hp: 4,   atk: 1,  def: 1,  maxHit: 1, heightM: 0.40,
    drops: ['hare_pelt', 'whickerhares_foot'],
    desc: 'Skittish meadow hare. Bolts on first hit.',
    model: 'hare.glb' },
  { kind: 'skitterling',  name: 'Skitterling',   tier: 'trivial', hp: 4,   atk: 2,  def: 1,  maxHit: 1, heightM: 0.50,
    drops: ['thorn_essence', 'hedge_ink', 'coin'],
    desc: 'Tiny thorn-fae. Hops in twos and threes — a whisper of the bramblewolds.',
    model: 'goblin_v2.glb',
    scope: 'briar_maze, delve' },
  { kind: 'marsh_rat',    name: 'Marsh Rat',     tier: 'easy',    hp: 8,   atk: 4,  def: 2,  maxHit: 2, heightM: 0.55,
    drops: ['rivermud', 'whickerhares_foot', 'coin'],
    desc: 'Bog-soaked rodent with sharp teeth. Darts in to bite, then retreats 3 tiles. Hard to corner.',
    model: 'hare_v2.glb',
    scope: 'sunken_hut' },
  { kind: 'goblin',       name: 'Goblin',        tier: 'easy',    hp: 12,  atk: 4,  def: 2,  maxHit: 2, heightM: 1.20,
    drops: ['rusty_dagger', 'coin'],
    desc: 'Camp scavengers in the southeast. Nasty in numbers.',
    model: 'goblin.glb' },
  { kind: 'archer',       name: 'Bramble Archer', tier: 'easy',   hp: 14,  atk: 6,  def: 2,  maxHit: 3, heightM: 1.70,
    drops: ['crow_feather', 'hedge_ink', 'coin'],
    desc: 'Falcon-perched at the back of the room. Fires telegraphed shots from 3-6 tiles. Dodge or step off the marked tile.',
    model: 'falcon_v2.glb' },
  { kind: 'bramble_imp',  name: 'Bramble-Imp',   tier: 'easy',    hp: 10,  atk: 4,  def: 2,  maxHit: 2, heightM: 0.95,
    drops: ['bramble_resin'],
    desc: 'Thorn-fae goading the dairy herd. Drops bramble resin.',
    model: 'bramble_imp.glb' },
  { kind: 'iron_gob',     name: 'Iron Gob',      tier: 'medium',  hp: 28,  atk: 7,  def: 6,  maxHit: 3, heightM: 1.55,
    drops: ['bogiron_ore', 'bogiron_bar', 'hedge_ink', 'coin'],
    desc: 'Goblin in scavenged plate. Heavy as a sack of nails. Slow but punishing.',
    model: 'goblin_v2.glb',
    scope: 'delve' },
  { kind: 'bramble_cap',  name: 'Bramble-Cap',   tier: 'medium',  hp: 35,  atk: 7,  def: 4,  maxHit: 3, heightM: 1.40,
    drops: ['bramble_resin', 'thorn_crown', 'coin'],
    desc: 'Champion variant in the goblin camp. Slower, harder hitting.',
    model: 'bramble_imp.glb' },
  { kind: 'boar',         name: 'Wild Boar',     tier: 'medium',  hp: 40,  atk: 8,  def: 5,  maxHit: 3, heightM: 1.05,
    drops: ['raw_boar', 'tusk', 'coin'],
    desc: 'Wood-edge brute. Charges if you stare too long.',
    model: 'boar.glb' },
  { kind: 'charger',      name: 'Bramble Charger', tier: 'medium', hp: 36,  atk: 10, def: 5,  maxHit: 5, heightM: 1.20,
    drops: ['raw_tusker', 'tusker_tusk', 'bogiron_ore', 'coin'],
    desc: 'Dark-tinted boar that paints a yellow line and DASHES. Sidestep out of the lane — back-pedaling stays in the line.',
    model: 'boar_v2.glb' },
  { kind: 'tusker_sow',   name: 'Tusker Sow',    tier: 'hard',    hp: 70,  atk: 12, def: 8,  maxHit: 4, heightM: 1.45,
    drops: ['raw_tusker', 'tusker_tusk', 'bogiron_bar', 'coin'],
    desc: 'A matriarch boar. Long 0.85s windup → 3×3 amber AoE slam. Step off the marked tile or eat the full hit.',
    model: 'boar_v2.glb',
    scope: 'sunken_hut' },
  { kind: 'hedge_wolf',   name: 'Hedgewolf',     tier: 'hard',    hp: 80,  atk: 14, def: 9,  maxHit: 5, heightM: 1.10,
    drops: ['raw_hedgewight', 'wightpelt', 'coalrose', 'bogiron_bar', 'coin'],
    desc: 'Twilight hunter of the deep wolds. Fast, mean — actually a hedgewight in motion.',
    model: 'hedgewight_v2.glb' },
  { kind: 'burrow_boar',  name: 'Burrow Boar',   tier: 'hard',    hp: 110, atk: 16, def: 10, maxHit: 5, heightM: 1.50,
    drops: ['raw_boar', 'tusk', 'coin'],
    desc: 'Bigger cousin of the wood boar, lives in earth-warrens.',
    model: 'burrow_boar.glb' },
  { kind: 'wolf_alpha',   name: 'Alpha Hedgewolf', tier: 'elite', hp: 220, atk: 22, def: 14, maxHit: 7, heightM: 1.35,
    drops: ['wolf_alpha_pelt', 'fang', 'coin'],
    desc: 'Pack leader. Calls in two hedgewolves at half-HP.',
    model: 'wolf_alpha.glb' },
  { kind: 'hedgemother',  name: 'The Hedgemother', tier: 'boss',  hp: 480, atk: 32, def: 22, maxHit: 10, heightM: 2.40,
    drops: ['hedgemother_heart', 'thorn_crown', 'coin'],
    desc: 'Bramblewood matriarch. Quest-locked spawn. Drops the Heart for the late game.',
    model: 'hedgemother.glb' },
];

/** Look up a single enemy def by `kind`. Returns null if not found. */
export function enemyDef(kind) {
  for (const e of ENEMY_DEFS) if (e.kind === kind) return e;
  return null;
}
