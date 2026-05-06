// Unified Actions registry. Wraps melee abilities + magic spells +
// ranged attacks behind one shape so the action bar can hold any mix.
//
// player.actionBar = [actionId | null] × 8.
//
// Public API:
//   ALL_ACTION_IDS()   — every known action id
//   getAction(id)      — normalized AbilityDef-shaped object
//   actionUnlocked(player, id)
//   actionCanAfford(player, id)
//   activateAction(player, id, ctx) — fires the action; returns truthy on success

import { ABILITIES } from './abilities.js';
import { SPELLS, castSpell } from './spells.js';
import { ITEMS } from '../data/items.js';

// ---- Ranged actions -------------------------------------------------
// Ranged kinds: stamina cost, line-of-sight damage, falconry XP.
const RANGED_ACTIONS = {
  quickshot: {
    id: 'quickshot',
    name: 'Quickshot',
    icon: '🏹',
    kind: 'ranged',
    reqSkill: 'falconry',
    reqLevel: 5,
    cooldown: 4,
    cost: { stamina: 8 },
    range: 8,
    minDmg: 4, maxDmg: 9,
    desc: 'A loosed arrow strikes a target up to 8 tiles away.',
    benefit: 'Reach. No melee adjacency required.',
    drawback: 'Long cooldown. Stamina cost.',
  },
  aimed_shot: {
    id: 'aimed_shot',
    name: 'Aimed Shot',
    icon: '🎯',
    kind: 'ranged',
    reqSkill: 'falconry',
    reqLevel: 15,
    cooldown: 12,
    cost: { stamina: 18 },
    range: 12,
    minDmg: 8, maxDmg: 15,
    desc: 'A patient draw lands heavy damage at long range.',
    benefit: 'Long range (12 tiles). Heavy damage.',
    drawback: 'Heavy stamina drain. Long cooldown.',
  },
  volley: {
    id: 'volley',
    name: 'Volley',
    icon: '🏹',
    kind: 'ranged',
    reqSkill: 'falconry',
    reqLevel: 30,
    cooldown: 18,
    cost: { stamina: 30 },
    range: 8,
    minDmg: 6, maxDmg: 10,
    aoe: 2,                 // hit all enemies within 2 tiles of the target
    desc: 'A scatter of arrows blankets a 2-tile radius around the target.',
    benefit: 'AoE — hits multiple foes.',
    drawback: 'Lower per-target damage. Long cooldown.',
  },
  falcon_strike: {
    id: 'falcon_strike',
    name: 'Falcon Strike',
    icon: '🦅',
    kind: 'ranged',
    reqSkill: 'falconry',
    reqLevel: 20,
    cooldown: 15,
    cost: { stamina: 20 },
    range: 10,
    minDmg: 10, maxDmg: 18,
    desc: 'Send your falcon to dive on a target. Heavy damage at range.',
    benefit: 'No projectile to dodge. Falcon does the work.',
    drawback: 'Long cooldown. Falcon must be idle.',
    isFalcon: true,
  },
};

// ---- Utility actions ----------------------------------------------
// Bindable verbs that aren't strictly damage. Quaff, eat, sketch.
const UTILITY_ACTIONS = {
  quaff_potion: {
    id: 'quaff_potion',
    name: 'Quaff Potion',
    icon: '🧪',
    kind: 'utility',
    reqSkill: 'hp',
    reqLevel: 1,
    cooldown: 1.5,
    cost: {},
    desc: 'Drink the smallest healing potion or food in your bag.',
    benefit: 'No stamina cost. Restores HP.',
    drawback: 'Consumes one consumable item.',
  },
  eat_food: {
    id: 'eat_food',
    name: 'Eat Food',
    icon: '🥩',
    kind: 'utility',
    reqSkill: 'hp',
    reqLevel: 1,
    cooldown: 2,
    cost: {},
    desc: 'Eat the largest-heal food in your bag.',
    benefit: 'Big HP restore. No stamina cost.',
    drawback: 'Consumes one food item.',
  },
  sketch_nearby: {
    id: 'sketch_nearby',
    name: 'Sketch Subject',
    icon: '📓',
    kind: 'utility',
    reqSkill: 'carto',
    reqLevel: 1,
    cooldown: 0.1,        // channel handles the real wait
    cost: {},
    desc: 'Sketch the nearest sketchable feature into your field journal.',
    benefit: 'Builds the journal. Discovery flavor.',
    drawback: 'Requires standing still during the channel.',
  },
};

// ---- Normalize ability + spell shapes into one ----------------------

function elementIcon(el) {
  return ({
    air: '🌬', water: '💧', earth: '🪨', fire: '🔥',
    mind: '🧠', body: '💪', chaos: '🌀', cosmic: '⚖',
    law: '🚪', nature: '🌫', death: '☠', blood: '🩸', soul: '✨',
  })[el] || '✦';
}

export function ALL_ACTION_IDS() {
  return [
    ...Object.keys(ABILITIES),
    ...Object.keys(SPELLS),
    ...Object.keys(RANGED_ACTIONS),
    ...Object.keys(UTILITY_ACTIONS),
  ];
}

export function getAction(id) {
  const ab = ABILITIES[id];
  if (ab) {
    return {
      id: ab.id, name: ab.name, icon: ab.icon, kind: 'melee',
      reqSkill: ab.reqSkill, reqLevel: ab.reqLevel,
      cooldown: ab.cooldown,
      cost: { stamina: ab.staminaCost || 0 },
      desc: ab.desc,
      benefit: 'Stamina-only cost. Combat XP grant.',
      drawback: ab.staminaCost > 30 ? 'Heavy stamina drain.' : 'Adjacency-required.',
      _ability: ab,
    };
  }
  const sp = SPELLS[id];
  if (sp) {
    const runeCost = Object.entries(sp.cost).map(([k, n]) => `${n}× ${ITEMS[k]?.name || k}`).join(' + ');
    return {
      id: sp.id, name: sp.name, icon: elementIcon(sp.element), kind: 'magic',
      reqSkill: 'magic', reqLevel: sp.reqLevel,
      cooldown: 2.5,
      cost: { runes: { ...sp.cost } },
      desc: sp.desc,
      benefit: sp.range ? `Ranged (${sp.range} tiles). Magic XP grant.` : 'Utility — no melee needed.',
      drawback: `Consumes runes: ${runeCost}.`,
      element: sp.element,
      stub: !!sp.stub,
      _spell: sp,
    };
  }
  const rg = RANGED_ACTIONS[id];
  if (rg) {
    return {
      ...rg,
      _ranged: true,
    };
  }
  const ut = UTILITY_ACTIONS[id];
  if (ut) {
    return {
      ...ut,
      _utility: true,
    };
  }
  return null;
}

export function actionUnlocked(player, id) {
  const a = getAction(id);
  if (!a) return false;
  const skill = player.skills?.[a.reqSkill];
  if (!skill) return false;
  return skill.lv >= a.reqLevel;
}

export function actionCanAfford(player, id) {
  const a = getAction(id);
  if (!a) return false;
  if (a.cost?.stamina && (player.stamina ?? 0) < a.cost.stamina) return false;
  if (a.cost?.runes) {
    for (const [k, n] of Object.entries(a.cost.runes)) {
      if (player.inventory.count(k) < n) return false;
    }
  }
  if (a.cost?.ammo) {
    for (const [k, n] of Object.entries(a.cost.ammo)) {
      if (player.inventory.count(k) < n) return false;
    }
  }
  return true;
}

/** Returns a string describing what's missing for a cast/activation. */
export function actionMissingReason(player, id) {
  const a = getAction(id);
  if (!a) return 'Unknown action.';
  if (!actionUnlocked(player, id)) {
    const have = player.skills?.[a.reqSkill]?.lv || 0;
    return `${a.name} locked — needs ${a.reqSkill.toUpperCase()} ${a.reqLevel} (you are ${have}).`;
  }
  if (a.cost?.stamina && (player.stamina ?? 0) < a.cost.stamina) {
    return `${a.name} needs ${a.cost.stamina} stamina.`;
  }
  if (a.cost?.runes) {
    const missing = Object.entries(a.cost.runes)
      .filter(([k, n]) => player.inventory.count(k) < n)
      .map(([k, n]) => `${n - player.inventory.count(k)}× ${ITEMS[k]?.name || k}`);
    if (missing.length) return `${a.name} needs: ${missing.join(', ')}.`;
  }
  return null;
}
