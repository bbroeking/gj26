// Rune Magic — Phase B (full catalog).
// 22 spells across Common attacks / Utility / Buffs / Travel / Tier-2 attacks /
// Nature / Risk / Endgame. See docs/rune-magic-design.md for the full design.
//
// A spell either has `effect: 'damage'` (rolls dmg in [minDmg, maxDmg] on
// the locked target) or `effect: 'utility'` (the cast handler in main.js
// runs a custom function — keyed off spell.id).

import { ITEMS } from '../data/items.js';

/** @typedef {Object} SpellDef
 *  @property {string} id
 *  @property {string} name
 *  @property {string} element
 *  @property {Object<string,number>} cost
 *  @property {number} reqLevel
 *  @property {string} desc
 *  @property {number} xpOnCast
 *  @property {'damage'|'utility'|'buff'|'travel'} effect
 *  @property {number} [range]
 *  @property {number} [minDmg]
 *  @property {number} [maxDmg]
 *  @property {number} [duration]
 *  @property {string} [tier]
 */

/** @type {Record<string, SpellDef>} */
export const SPELLS = {
  // ---------- Common attack ----------
  wind_strike: {
    id: 'wind_strike', name: 'Wind Strike', element: 'air', tier: 1,
    cost: { rune_air: 1, rune_mind: 1 },
    reqLevel: 1, range: 6, minDmg: 3, maxDmg: 6, effect: 'damage',
    desc: 'A thin slice of air strikes a target in sight.',
    xpOnCast: 12,
  },
  water_strike: {
    id: 'water_strike', name: 'Water Strike', element: 'water', tier: 1,
    cost: { rune_water: 1, rune_mind: 1 },
    reqLevel: 5, range: 6, minDmg: 4, maxDmg: 8, effect: 'damage',
    desc: 'A pressure-wedge of water strikes the target. Slows water-vulnerable foes.',
    xpOnCast: 16,
  },
  earth_strike: {
    id: 'earth_strike', name: 'Earth Strike', element: 'earth', tier: 1,
    cost: { rune_earth: 1, rune_mind: 1 },
    reqLevel: 9, range: 6, minDmg: 5, maxDmg: 10, effect: 'damage',
    desc: 'A small stone-shard strikes the target. +50% vs wood foes.',
    xpOnCast: 20,
  },
  fire_strike: {
    id: 'fire_strike', name: 'Fire Strike', element: 'fire', tier: 1,
    cost: { rune_fire: 1, rune_mind: 1 },
    reqLevel: 13, range: 6, minDmg: 6, maxDmg: 11, effect: 'damage',
    desc: 'A spark scorches the target. Lights bramble-imps on fire.',
    xpOnCast: 24,
  },

  // ---------- Utility ----------
  sense_aggro: {
    id: 'sense_aggro', name: 'Sense Aggro', element: 'mind', tier: 1,
    cost: { rune_mind: 1, rune_air: 1 },
    reqLevel: 6, effect: 'utility', duration: 60,
    desc: 'Reveals all aggroed enemies on the minimap for 60 seconds.',
    xpOnCast: 18,
  },
  quench_stamina: {
    id: 'quench_stamina', name: 'Quench Stamina', element: 'water', tier: 1,
    cost: { rune_water: 1, rune_body: 1 },
    reqLevel: 8, effect: 'utility',
    desc: 'Refills 30 stamina from the player\'s connection to water.',
    xpOnCast: 18,
  },
  ignite: {
    id: 'ignite', name: 'Ignite', element: 'fire', tier: 1,
    cost: { rune_fire: 1, rune_air: 1 },
    reqLevel: 14, effect: 'utility',
    desc: 'Lights a target tile on fire — useful at dungeon braziers.',
    xpOnCast: 22, stub: true,
  },
  quiet_thought: {
    id: 'quiet_thought', name: 'Quiet Thought', element: 'mind', tier: 2,
    cost: { rune_mind: 2, rune_chaos: 1 },
    reqLevel: 18, effect: 'utility', duration: 8,
    desc: 'Enemies near the player lose aggro for 8 seconds.',
    xpOnCast: 30, stub: true,
  },

  // ---------- Buff ----------
  stone_skin: {
    id: 'stone_skin', name: 'Stone Skin', element: 'earth', tier: 1,
    cost: { rune_earth: 1, rune_body: 1 },
    reqLevel: 12, effect: 'buff', duration: 30,
    desc: '+30% defence for 30 seconds.',
    xpOnCast: 22,
  },
  vigor: {
    id: 'vigor', name: 'Vigor', element: 'body', tier: 2,
    cost: { rune_body: 2, rune_cosmic: 1 },
    reqLevel: 30, effect: 'utility',
    desc: 'Restores 30 HP over 10 seconds (3 HP/sec).',
    xpOnCast: 40,
  },

  // ---------- Travel ----------
  levitate: {
    id: 'levitate', name: 'Levitate', element: 'air', tier: 2,
    cost: { rune_air: 2, rune_cosmic: 1 },
    reqLevel: 16, effect: 'utility',
    desc: 'Crosses a 3-tile water gap — step onto the surface and walk.',
    xpOnCast: 28, stub: true,
  },
  teleport_bramblewood: {
    id: 'teleport_bramblewood', name: 'Teleport: Bramblewood', element: 'cosmic', tier: 3,
    cost: { rune_law: 1, rune_air: 3 },
    reqLevel: 33, effect: 'utility',
    desc: 'Warp to the village spawn from anywhere outdoors.',
    xpOnCast: 50,
  },
  teleport_chartmaker: {
    id: 'teleport_chartmaker', name: 'Teleport: Last Chartmaker', element: 'cosmic', tier: 3,
    cost: { rune_law: 1, rune_cosmic: 3 },
    reqLevel: 35, effect: 'utility',
    desc: 'Warp back to the chartmaker\'s stone from any explored tile.',
    xpOnCast: 55,
  },

  // ---------- Tier-2 attack ----------
  wind_wave: {
    id: 'wind_wave', name: 'Wind Wave', element: 'air', tier: 2,
    cost: { rune_air: 3, rune_mind: 1, rune_chaos: 1 },
    reqLevel: 24, range: 4, minDmg: 8, maxDmg: 14, effect: 'damage',
    desc: 'AoE knockback in a 3-tile radius around the target.',
    xpOnCast: 38, aoe: 3,
  },
  water_wave: {
    id: 'water_wave', name: 'Water Wave', element: 'water', tier: 2,
    cost: { rune_water: 3, rune_mind: 1, rune_chaos: 1 },
    reqLevel: 28, range: 4, minDmg: 10, maxDmg: 16, effect: 'damage',
    desc: 'AoE damage + slow in a 3-tile radius.',
    xpOnCast: 42, aoe: 3,
  },

  // ---------- Nature ----------
  bind_plant: {
    id: 'bind_plant', name: 'Bind Plant', element: 'nature', tier: 2,
    cost: { rune_nature: 1, rune_earth: 2 },
    reqLevel: 38, range: 5, effect: 'utility', duration: 6,
    desc: 'Roots an enemy in place for 6 seconds.',
    xpOnCast: 50, stub: true,
  },
  animal_sight: {
    id: 'animal_sight', name: 'Animal Sight', element: 'nature', tier: 2,
    cost: { rune_nature: 1, rune_air: 2 },
    reqLevel: 41, effect: 'utility', duration: 30,
    desc: 'Falcon scouts a 5-tile radius for 30 seconds.',
    xpOnCast: 55, stub: true,
  },

  // ---------- Hold / Bind ----------
  holdinghut: {
    id: 'holdinghut', name: 'Holdinghut', element: 'cosmic', tier: 3,
    cost: { rune_law: 1, rune_cosmic: 1, rune_nature: 1 },
    reqLevel: 50, effect: 'utility',
    desc: 'Bind a "home tile" — teleport here free for 1 game-day.',
    xpOnCast: 80, stub: true,
  },

  // ---------- Death / Risk / Endgame ----------
  deaths_whisper: {
    id: 'deaths_whisper', name: "Death's Whisper", element: 'death', tier: 3,
    cost: { rune_death: 1, rune_chaos: 1, rune_fire: 2 },
    reqLevel: 60, range: 7, minDmg: 18, maxDmg: 28, effect: 'damage',
    desc: 'High damage; the dying enemy briefly fights for you.',
    xpOnCast: 110,
  },
  blood_pact: {
    id: 'blood_pact', name: 'Blood Pact', element: 'blood', tier: 3,
    cost: { rune_blood: 1, rune_fire: 2, rune_chaos: 1 },
    reqLevel: 70, effect: 'buff',
    desc: '-2 HP self → +200% damage on next swing.',
    xpOnCast: 120, stub: true,
  },
  soul_bind: {
    id: 'soul_bind', name: 'Soul Bind', element: 'soul', tier: 4,
    cost: { rune_soul: 1, rune_law: 1 },
    reqLevel: 85, effect: 'utility',
    desc: 'Force the next slain rare to drop a unique always.',
    xpOnCast: 200, stub: true,
  },
};

/** Can the player afford this spell? */
export function canCast(player, spellId) {
  const s = SPELLS[spellId];
  if (!s) return false;
  if ((player.skills.magic?.lv || 1) < s.reqLevel) return false;
  for (const [k, n] of Object.entries(s.cost)) {
    if (player.inventory.count(k) < n) return false;
  }
  return true;
}

/** Returns the runes the player is short on for a spell. */
export function missingRunes(player, spellId) {
  const s = SPELLS[spellId];
  if (!s) return [];
  const out = [];
  for (const [k, n] of Object.entries(s.cost)) {
    const have = player.inventory.count(k);
    if (have < n) out.push({ id: k, need: n, have });
  }
  return out;
}

/** Cast a spell at the player's current combat target. Returns:
 *    { ok: true,  dmg, target, spell }  — landed (for damage spells)
 *    { ok: true,  spell, kind:'utility' } — cast successfully (utility)
 *    { ok: false, reason }                — could not cast
 *
 *  Damage application happens here. Utility effect handlers run in
 *  main.js (different verbs need different game-state access).
 */
export function castSpell(player, spellId, log) {
  const s = SPELLS[spellId];
  if (!s) return { ok: false, reason: 'Unknown spell.' };
  if (s.stub) return { ok: false, reason: `${s.name} isn't implemented yet.` };
  if ((player.skills.magic?.lv || 1) < s.reqLevel) {
    return { ok: false, reason: `Magic Lv ${s.reqLevel} required.` };
  }
  const missing = missingRunes(player, spellId);
  if (missing.length) {
    const list = missing.map(m => `${m.need - m.have}× ${ITEMS[m.id]?.name || m.id}`).join(', ');
    return { ok: false, reason: `Need: ${list}.` };
  }
  if (s.effect === 'damage') {
    const target = player.combatTarget;
    if (!target || !target.alive) {
      return { ok: false, reason: 'No target. Click an enemy to lock on, then cast.' };
    }
    const dx = target.x - player.x, dy = target.y - player.y;
    const dist = Math.sqrt(dx*dx + dy*dy);
    if (dist > (s.range || 6)) {
      return { ok: false, reason: `Out of range (${dist.toFixed(0)} > ${s.range}).` };
    }
    // Spend
    for (const [k, n] of Object.entries(s.cost)) player.inventory.remove(k, n);
    // Roll
    const dmg = s.minDmg + Math.floor(Math.random() * (s.maxDmg - s.minDmg + 1));
    target.hp = Math.max(0, target.hp - dmg);
    target.flashT = 0.2;
    target.hurtT = 8;
    return { ok: true, dmg, target, spell: s };
  }
  // Utility / buff / travel — caller wires the effect by spell.id
  for (const [k, n] of Object.entries(s.cost)) player.inventory.remove(k, n);
  return { ok: true, kind: 'utility', spell: s };
}

/** All spells the player meets the level requirement for, sorted by reqLevel. */
export function spellsKnown(player) {
  const lv = player.skills.magic?.lv || 1;
  return Object.values(SPELLS).filter(s => s.reqLevel <= lv).sort((a, b) => a.reqLevel - b.reqLevel);
}

/** All spells (for the spellbook display, locked + unlocked). */
export function allSpells() {
  return Object.values(SPELLS).sort((a, b) => a.reqLevel - b.reqLevel);
}

/** Map ink → matching rune element for the Pedestal. */
export const INK_TO_RUNE = {
  hedge_ink:        'rune_air',
  stoneground_ink:  'rune_earth',
  bramblepress_ink: 'rune_fire',
  wellspring_ink:   'rune_water',
  charcoal_bind:    'rune_mind',
  refined_ink:      'rune_body',
  bog_ink:          'rune_chaos',
  lustrous_ink:     'rune_cosmic',
  ember_ink:        'rune_fire',     // alt path
  // Future: aurora_ink → rune_blood, atlas_ink → rune_law/soul, etc.
};
