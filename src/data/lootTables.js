// Centralised loot tables — single file a balance pass touches.
//
// Two systems:
//   CHEST_TABLES     — dungeon chest drops, keyed by tier+scope
//   MOB_DROP_TABLES  — per-enemy ground loot, keyed by lootKind
//
// Both go through table-driven rollers (rollChest / rollMobDrop) that
// return [{id, qty}]. Callers (src/scene/dungeon.js's generateDungeonLoot
// and src/game/enemies.js's onDeath) just spawn the result.
//
// Drop entry shape:
//   { id: string, qty: number | [lo, hi], chance: 0..1 (default 1) }
// If qty is a [lo, hi] tuple, an integer in that range is rolled at
// drop time. If chance < 1, the drop only fires when Math.random() < chance.

import { pickRandomLoreParchment } from './items.js';

// ---- helpers ----------------------------------------------------------

function _rollEntry(entry) {
  if (entry.chance != null && Math.random() >= entry.chance) return null;
  let qty = entry.qty;
  if (Array.isArray(qty)) {
    const [lo, hi] = qty;
    qty = lo + Math.floor(Math.random() * (hi - lo + 1));
  }
  if (qty <= 0) return null;
  return { id: entry.id, qty };
}

function _rollEntries(entries) {
  const out = [];
  for (const e of entries) {
    const r = _rollEntry(e);
    if (r) out.push(r);
  }
  return out;
}

// ---- chest tables -----------------------------------------------------
//
// Per-tier base table + per-scope flavor bundle. Coin scales with tier;
// gear chance is uniform but the gear pool is tier-locked. Refined ink
// + lore parchment are global rare adds.

const TIER_GEAR = {
  1: ['brindle_dagger', 'leather_body', 'wooden_shield'],
  2: ['bogiron_dagger', 'bogiron_axe',  'bogiron_pickaxe'],
  3: ['bogiron_sword',  'bogiron_shield','bogiron_cuirass'],
  4: ['cinderbloom_dagger', 'cinderbloom_axe', 'cinderbloom_pickaxe'],
  5: ['cinderbloom_sword',  'cinderbloom_helm', 'cinderbloom_shield'],
};

// Scope-flavored bonus drops — biases the haul toward the dungeon theme.
export const SCOPE_LOOT_BUNDLES = {
  briar_maze: [
    { id: 'thorn_essence',  qty: [2, 4] },
    { id: 'bramble_resin',  qty: [2, 5] },
    { id: 'hedge_ink',      qty: [3, 6] },
  ],
  sunken_hut: [
    { id: 'rivermud',       qty: [3, 6] },
    { id: 'raw_tusker',     qty: [1, 3] },
    { id: 'raw_hedgewight', qty: [1, 2] },
  ],
  delve: [
    { id: 'bogiron_ore',    qty: [3, 6] },
    { id: 'palechalk_ore',  qty: [2, 4] },
    { id: 'refined_ink',    qty: 1, chance: 0.30 },
  ],
  hollow: [
    { id: 'wild_herb',      qty: [2, 4] },
    { id: 'hedge_ink',      qty: [2, 4] },
  ],
};

// Door-key drops gated to scopes that thematically house them: iron in
// the smith-y delve, thorn in the briar_maze. Gold keys are rare cross-
// scope. Tier filtering happens in rollChest below — tier 1 dungeons
// don't yet need locked-room gating.
const KEY_DROPS = {
  delve:      { id: 'iron_key',  qty: 1, chance: 0.25 },
  briar_maze: { id: 'thorn_key', qty: 1, chance: 0.15 },
};

/**
 * Roll a chest's full drop list.
 * @param {number} tier      1-5
 * @param {string} [scope]   'briar_maze' | 'sunken_hut' | 'delve' | 'hollow'
 * @param {Array}  [affixes] [{id, good}]
 * @returns {Array<{id, qty}>}
 */
export function rollChest(tier, scope = undefined, affixes = []) {
  tier = Math.max(1, Math.min(5, tier | 0));
  const drops = [];

  // 1) Coin — guaranteed payout, scales with tier (×1 to ×1.4 jitter).
  drops.push({ id: 'coin', qty: Math.round(50 * tier * (0.8 + Math.random() * 0.4)) });

  // 2) Affix-flavored adds.
  for (const a of affixes) {
    if (a.id === 'mineral_vein' && a.good) {
      drops.push({ id: 'bogiron_ore', qty: 2 + Math.floor(Math.random() * 2) });
    }
  }

  // 3) Scope flavor — independent rolls per entry.
  const bundle = SCOPE_LOOT_BUNDLES[scope];
  if (bundle) drops.push(..._rollEntries(bundle));

  // 4) Random gear, 40% chance, tier-locked.
  if (Math.random() < 0.40) {
    const pool = TIER_GEAR[tier] || TIER_GEAR[1];
    drops.push({ id: pool[Math.floor(Math.random() * pool.length)], qty: 1 });
  }

  // 5) Rare reagent — feeds the cartography crafting loop.
  if (Math.random() < 0.08) drops.push({ id: 'refined_ink', qty: 1 });

  // 6) Rare lore parchment — discovery hook.
  if (Math.random() < 0.08) {
    const parch = pickRandomLoreParchment();
    if (parch) drops.push({ id: parch, qty: 1 });
  }

  // 7) Key drops — gate the locked-door system. Scope-themed iron/thorn
  //    keys roll at tier 2+. Gold keys are a 10% cross-scope rare at
  //    tier 3+ since gilded doors gate the meatiest treasure rooms.
  if (tier >= 2) {
    const themed = KEY_DROPS[scope];
    if (themed) {
      const r = _rollEntry(themed);
      if (r) drops.push(r);
    }
  }
  if (tier >= 3 && Math.random() < 0.10) {
    drops.push({ id: 'gold_key', qty: 1 });
  }

  return drops;
}

// ---- mob drop tables --------------------------------------------------
//
// Keyed by lootKind (a per-enemy identifier distinct from the engine
// `kind` which determines AI/anim). Each list is rolled independently
// per kill — every entry rolls its own chance.

export const MOB_DROP_TABLES = {
  // Bramble-imp — most common foe. Hedge ink staple, 35% bramble resin
  // for the Quill quest, occasional refined ink.
  bramble_imp: [
    { id: 'hedge_ink',     qty: 1,      chance: 0.60 },
    { id: 'refined_ink',   qty: 1,      chance: 0.08 },
    { id: 'bramble_resin', qty: 1,      chance: 0.35 },
    { id: 'coin',          qty: [2, 5] },
  ],

  // Bramble-cap — mid-tier thorn-fae. Bigger thorn essence yield + a
  // chance at the prized refined ink.
  bramble_cap: [
    { id: 'thorn_essence', qty: [1, 2], chance: 0.85 },
    { id: 'bramble_resin', qty: [1, 2], chance: 0.55 },
    { id: 'hedge_ink',     qty: 1,      chance: 0.45 },
    { id: 'refined_ink',   qty: 1,      chance: 0.12 },
    { id: 'coin',          qty: [4, 9] },
  ],

  // Iron Gob — armored variant, drops palechalk ore (Hod's quest) and
  // occasionally an iron key — the smith-themed enemy is the natural
  // place to find iron keys outside chests.
  iron_gob: [
    { id: 'palechalk_ore', qty: [1, 2], chance: 0.65 },
    { id: 'bogiron_ore',   qty: 1,      chance: 0.40 },
    { id: 'hedge_ink',     qty: 1,      chance: 0.35 },
    { id: 'iron_key',      qty: 1,      chance: 0.08 },
    { id: 'coin',          qty: [3, 7] },
  ],

  // Skitterling — small thorn-fae scout.
  skitterling: [
    { id: 'thorn_essence', qty: 1,      chance: 0.55 },
    { id: 'hedge_ink',     qty: 1,      chance: 0.35 },
    { id: 'coin',          qty: [1, 3] },
  ],

  // Marsh Rat — sunken_hut native, drops rivermud + low coin.
  marsh_rat: [
    { id: 'rivermud',      qty: [1, 2], chance: 0.70 },
    { id: 'whicker_pelt',  qty: 1,      chance: 0.25 },
    { id: 'coin',          qty: [1, 3] },
  ],

  // Bramble Archer — ranged thorn-fae, drops crow feathers (fletching).
  bramble_archer: [
    { id: 'crow_feather',  qty: 1,      chance: 0.60 },
    { id: 'hedge_ink',     qty: 1,      chance: 0.45 },
    { id: 'coin',          qty: [4, 8] },
  ],

  // Bramble Charger — heavy line-dasher (overworld + dungeon).
  bramble_charger: [
    { id: 'raw_tusker',  qty: 1, chance: 0.50 },
    { id: 'tusker_tusk', qty: 1, chance: 0.20 },
    { id: 'bogiron_ore', qty: 1, chance: 0.30 },
    { id: 'coin',        qty: [7, 12] },
  ],

  // Tusker Sow — Maud's sunken-hut quest target.
  tusker_sow: [
    { id: 'raw_tusker',  qty: 2 },
    { id: 'tusker_tusk', qty: 1, chance: 0.45 },
    { id: 'bogiron_bar', qty: 1, chance: 0.15 },
    { id: 'coin',        qty: [10, 17] },
  ],

  // Hedgewolf — pack hunter. Pelt + fang reagents.
  hedgewolf: [
    { id: 'wightpelt',     qty: 1,      chance: 0.55 },
    { id: 'hedge_ink',     qty: 1,      chance: 0.30 },
    { id: 'coin',          qty: [3, 7] },
  ],

  // Hedgewight — undead pack-leader variant.
  hedgewight: [
    { id: 'wightpelt',     qty: 1,      chance: 0.75 },
    { id: 'raw_hedgewight', qty: 1,     chance: 0.50 },
    { id: 'hedge_ink',     qty: 1,      chance: 0.40 },
    { id: 'coin',          qty: [4, 9] },
  ],

  // Brindlecow — overworld farm critter. Mostly meat + wool.
  brindlecow: [
    { id: 'raw_brindle',   qty: 1,      chance: 0.95 },
    { id: 'wool_flank',    qty: [1, 2], chance: 0.60 },
  ],

  // Pippin (chicken)
  pippin: [
    { id: 'raw_pippin',    qty: 1,      chance: 0.95 },
    { id: 'downfeather',   qty: [1, 2], chance: 0.60 },
  ],

  // Whickerhare
  whickerhare: [
    { id: 'raw_whicker',   qty: 1,      chance: 0.95 },
    { id: 'whicker_pelt',  qty: 1,      chance: 0.50 },
  ],

  // Tuskersnout (overworld boar) — distinct from boss-tier Tusker Sow.
  tuskersnout: [
    { id: 'raw_tusker',    qty: 1,      chance: 0.85 },
    { id: 'wool_flank',    qty: 1,      chance: 0.20 },
    { id: 'coin',          qty: [1, 4] },
  ],

  // Hedgewight — overworld undead pack-leader.
  hedgewight_overworld: [
    { id: 'raw_hedgewight', qty: 1 },
    { id: 'wightpelt',      qty: 1,      chance: 0.65 },
    { id: 'coalrose',       qty: [1, 2], chance: 0.20 },
    { id: 'bogiron_bar',    qty: 1,      chance: 0.05 },
    { id: 'coin',           qty: [8, 15] },
  ],

  // ---- bosses -------------------------------------------------------
  // Boss drops — guaranteed signature items + gear pool + heavy coin.

  hedgemother: [
    { id: 'thorn_essence',   qty: 3 },
    { id: 'refined_ink',     qty: [1, 2] },
    { id: 'bogiron_bar',     qty: 2 },
    { id: 'cinderbloom_bar', qty: 1,  chance: 0.30 },
    { id: 'bogiron_sword',   qty: 1,  chance: 0.20 },
    { id: 'bogiron_cuirass', qty: 1,  chance: 0.15 },
    { id: 'thorn_crown',     qty: 1 },              // guaranteed for quest
    { id: 'coin',            qty: [80, 159] },
  ],

  burrow_boar: [
    { id: 'raw_tusker',       qty: 2 },
    { id: 'tusker_tusk',      qty: 1, chance: 0.55 },
    { id: 'cinderbloom_bar',  qty: 1, chance: 0.40 },
    { id: 'bogiron_axe',      qty: 1, chance: 0.18 },
    { id: 'cinderbloom_helm', qty: 1, chance: 0.10 },
    { id: 'coin',             qty: [70, 159] },
  ],

  wolf_alpha: [
    { id: 'hedgewight_strip',   qty: 2 },
    { id: 'wightpelt',          qty: 1, chance: 0.70 },
    { id: 'thorn_essence',      qty: 1, chance: 0.45 },
    { id: 'cinderbloom_bar',    qty: 1, chance: 0.35 },
    { id: 'bogiron_dagger',     qty: 1, chance: 0.20 },
    { id: 'cinderbloom_dagger', qty: 1, chance: 0.10 },
    { id: 'coin',               qty: [60, 139] },
  ],
};

/**
 * Roll a mob's drops. Returns [{id, qty}].
 * @param {string} lootKind  e.g. 'bramble_imp', 'iron_gob', 'hedgemother'
 */
export function rollMobDrop(lootKind) {
  const table = MOB_DROP_TABLES[lootKind];
  if (!table) return [];
  const drops = _rollEntries(table);
  // Rare: any combat drop has a tiny chance of carrying a stolen lore
  // parchment — surfaces whispered-legend content from the wild side.
  if (Math.random() < 0.015) {
    const parch = pickRandomLoreParchment();
    if (parch) drops.push({ id: parch, qty: 1 });
  }
  return drops;
}
