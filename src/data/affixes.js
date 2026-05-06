// Wayfinding affix data. Every affix has a "good" outcome and a "bad twin" —
// when you craft, stability % decides which lands. Stability comes from
// Wayfinding level + ink quality. See src/ui/charting.js for the crafting
// UI; src/scene/dungeon.js reads chart.affixes at generation time.

/**
 * @typedef {object} AffixDef
 * @property {string}  id          unique identifier
 * @property {string}  name        good-twin display name
 * @property {string}  badName     bad-twin display name (what lands on failure)
 * @property {string}  goodDesc    short, in-world good-outcome flavor
 * @property {string}  badDesc     short, in-world bad-outcome flavor
 * @property {'bias'|'modifier'|'boss'|'pacing'|'risk'} kind
 * @property {object}  cost        items consumed when applying this affix
 *                                 e.g. { hedge_ink: 1 }
 * @property {number}  reqCarto    Wayfinding level needed to even pick it
 * @property {number}  baseStab    base stability % at Carto lvl 1
 *                                 effective stab = baseStab + cartoLv * 0.6,
 *                                 capped at 95. Refined ink locks at 100.
 */

/** @type {Record<string, AffixDef>} */
export const AFFIXES = {
  mineral_vein: {
    id: 'mineral_vein',
    name: 'Mineral Vein',
    badName: 'Barren',
    goodDesc: 'Ore deposits seam through the dungeon. 3–5 mineable rocks appear inside.',
    badDesc: 'The ink ran dry. The dungeon comes up barren — no ore.',
    kind: 'bias',
    cost: { hedge_ink: 1 },
    reqCarto: 1,
    baseStab: 55,
  },
  hedgemother_den: {
    id: 'hedgemother_den',
    name: "Hedgemother's Den",
    badName: 'Empty Throne',
    goodDesc: 'The deepest room becomes her thorn-arena. Drops her crown for the worthy.',
    badDesc: 'You find her empty bramble-throne. Whatever lived here has gone.',
    kind: 'boss',
    cost: { hedge_ink: 2, thorn_essence: 1 },
    reqCarto: 8,
    baseStab: 50,
  },
  burrow_boar_den: {
    id: 'burrow_boar_den',
    name: "Burrow Boar's Wallow",
    badName: 'Empty Wallow',
    goodDesc: 'A great Burrow Boar takes the deepest room. Heavier loot, slower fight.',
    badDesc: 'The wallow is fresh-dug but empty. Whatever rooted here has moved on.',
    kind: 'boss',
    cost: { hedge_ink: 2, raw_tusker: 1 },
    reqCarto: 12,
    baseStab: 48,
  },
  wolf_alpha_den: {
    id: 'wolf_alpha_den',
    name: "Wolf Alpha's Roost",
    badName: 'Cold Trail',
    goodDesc: 'A pack-leader hedgewight haunts the deepest room. Fast, sharp, glow-eyed.',
    badDesc: 'Only fur and a cold trail — the pack moved on hours ago.',
    kind: 'boss',
    cost: { hedge_ink: 2, wightpelt: 1 },
    reqCarto: 14,
    baseStab: 46,
  },
  // ---- bias (resource layer) ----
  bramble_bloom: {
    id: 'bramble_bloom',
    name: 'Bramble Bloom',
    badName: 'Wilted',
    goodDesc: 'The hollow blooms with bramble — 4-6 forage spawns appear inside.',
    badDesc: 'The vines have withered to nothing. No forage in this run.',
    kind: 'bias',
    cost: { hedge_ink: 1 },
    reqCarto: 4,
    baseStab: 55,
  },
  tinder_cache: {
    id: 'tinder_cache',
    name: 'Tinder Cache',
    badName: 'Damp Wood',
    goodDesc: 'A trapper left three log piles inside. Free wood for the picking.',
    badDesc: 'The hollow is wet. Stamina regen suffers.',
    kind: 'bias',
    cost: { hedge_ink: 1, logs: 1 },
    reqCarto: 6,
    baseStab: 55,
  },
  ink_spring: {
    id: 'ink_spring',
    name: 'Ink Spring',
    badName: 'Ink Salt',
    goodDesc: 'A side room hides 2-3 refined-ink rocks. Rare pull.',
    badDesc: 'The ink is salt-stained. Hedge ink yields will halve in this run.',
    kind: 'bias',
    cost: { hedge_ink: 2, refined_ink: 1 },
    reqCarto: 18,
    baseStab: 42,
  },

  // ---- modifier (combat math) ----
  tyrannical: {
    id: 'tyrannical',
    name: 'Tyrannical',
    badName: 'Erratic',
    goodDesc: 'Enemies are fattened up — +50% HP, +30% XP.',
    badDesc: 'Each enemy rolls its own random mod. Chaotic.',
    kind: 'modifier',
    cost: { hedge_ink: 2 },
    reqCarto: 5,
    baseStab: 52,
  },
  bursting: {
    id: 'bursting',
    name: 'Bursting',
    badName: 'Spongy',
    goodDesc: 'Enemies pop on death — small AoE burst. Dodge it for the bonus.',
    badDesc: 'Enemies absorb 30% of incoming damage. Slower kills.',
    kind: 'modifier',
    cost: { hedge_ink: 2 },
    reqCarto: 9,
    baseStab: 50,
  },
  frenzied: {
    id: 'frenzied',
    name: 'Frenzied',
    badName: 'Sluggish',
    goodDesc: 'Below 30% HP, enemies attack 30% faster. More XP per kill.',
    badDesc: 'Enemies attack 30% slower. Easier — but the haul is thinner.',
    kind: 'modifier',
    cost: { hedge_ink: 2 },
    reqCarto: 12,
    baseStab: 48,
  },
  quiver: {
    id: 'quiver',
    name: 'Quiver',
    badName: 'Stoneskin',
    goodDesc: 'Enemies dodge 15% of attacks but die in fewer hits when struck.',
    badDesc: 'Enemies start with 4 armor. Tougher openings.',
    kind: 'modifier',
    cost: { hedge_ink: 2 },
    reqCarto: 16,
    baseStab: 46,
  },

  // ---- pacing ----
  festival_pace: {
    id: 'festival_pace',
    name: 'Festival Pace',
    badName: 'Lockstep',
    goodDesc: '+50% enemy density inside. The hollow is thick with imps.',
    badDesc: 'Enemies patrol fixed routes only. Predictable, less XP.',
    kind: 'pacing',
    cost: { hedge_ink: 2 },
    reqCarto: 7,
    baseStab: 52,
  },
  sprinter: {
    id: 'sprinter',
    name: "Sprinter's Run",
    badName: "Heart's Stone",
    goodDesc: '5-minute timer. Beat it for double chest loot.',
    badDesc: 'No timer, but stamina regen is halved for the whole run.',
    kind: 'pacing',
    cost: { hedge_ink: 2, refined_ink: 1 },
    reqCarto: 17,
    baseStab: 44,
  },

  // ---- bias (resource pumps) ----
  wood_grove: {
    id: 'wood_grove',
    name: 'Wood Grove',
    badName: 'Stripped Grove',
    goodDesc: 'A trapper has been chopping. 3-5 log piles wait inside the chart.',
    badDesc: 'The grove is stripped bare — no logs, dim mood.',
    kind: 'bias',
    cost: { hedge_ink: 1, logs: 1 },
    reqCarto: 7,
    baseStab: 55,
  },
  herbal_patch: {
    id: 'herbal_patch',
    name: 'Herbal Patch',
    badName: 'Frostbit Patch',
    goodDesc: 'A wild herb patch crowns the chart — 4-6 forage spawns.',
    badDesc: 'The patch is frost-bit. Forage yields halved, no extras.',
    kind: 'bias',
    cost: { hedge_ink: 1, raw_mushroom: 1 },
    reqCarto: 14,
    baseStab: 55,
  },
  gem_seam: {
    id: 'gem_seam',
    name: 'Gem Seam',
    badName: 'Pyrite Seam',
    goodDesc: 'A chest-room rare-gemstone drop (sapphire / emerald / amber).',
    badDesc: 'Fool\'s gold — the gem you find is worthless.',
    kind: 'bias',
    cost: { hedge_ink: 2, refined_ink: 1 },
    reqCarto: 30,
    baseStab: 48,
  },

  // ---- atmosphere ----
  fog_of_hedge: {
    id: 'fog_of_hedge',
    name: 'Fog of Hedge',
    badName: "Lantern's Friend",
    goodDesc: 'Minimap is dark. +20 carto XP on completion for the discipline.',
    badDesc: 'Minimap fully reveals — and the hollow knows you cheated. -10 carto XP.',
    kind: 'atmosphere',
    cost: { hedge_ink: 1 },
    reqCarto: 10,
    baseStab: 55,
  },
};

/**
 * Effective stability for the player. Higher = more likely the good twin lands.
 * Capped at 95 unless `lockedByRefined` (then 100).
 */
export function effectiveStability(affix, cartoLv, lockedByRefined = false) {
  if (lockedByRefined) return 100;
  return Math.min(95, Math.round((affix.baseStab || 50) + cartoLv * 0.6));
}

/**
 * Roll the affix at craft time. Returns the *resolved* outcome name
 * (good or bad) plus a flag so callers can show "you got the good one."
 */
export function rollAffix(affix, cartoLv, lockedByRefined = false) {
  const stab = effectiveStability(affix, cartoLv, lockedByRefined);
  const good = Math.random() * 100 < stab;
  return { good, resolvedId: good ? affix.id : `${affix.id}__bad` };
}

/**
 * How many affix slots the chart can hold given (tier, cartoLv).
 * V1 caps at 2 slots; V2 will go to 5 at Carto 75+.
 */
export function maxSlots(tier, cartoLv) {
  const byTier  = Math.max(1, Math.min(5, tier));
  const byLevel = 1 + Math.floor(cartoLv / 15);
  return Math.min(byTier, byLevel, 2);   // V1 hard-cap at 2
}
