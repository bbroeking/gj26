// Skill XP + leveling. v2's logic, with renderless side-effects so the main
// loop can hook FX (level-up burst).
import { CONFIG, xpForLevel } from '../data/config.js';

// Skill consolidation per docs/design/skills-consolidation.md (2026-05-04):
// 13 → 10 skills. The 5 gathering skills (forage / fish / wc / mine / smith)
// merged into 2 umbrellas:
//   - wilds = forage + fish + wc (passive harvest from nature)
//   - earth = mine + smith       (extraction + working metal)
// Cooking stays separate (it's transformation, not gathering). Combat
// triple + carto/falconry/magic unchanged.
export const SKILL_KEYS = [
  'atk', 'str', 'def', 'hp',
  'wilds', 'earth', 'cook',
  'carto', 'falconry', 'magic',
];

// Old → new skill mapping. Used by:
//   - migrateSkills() for save-file upgrade
//   - the few places where a code path still passes the old name
//     (e.g. an old item's `source: { skill: 'mine' }`); we re-route the
//     award call here instead of replacing every call site at once.
export const SKILL_ALIAS = {
  forage: 'wilds', fish: 'wilds', wc: 'wilds',
  mine: 'earth',   smith: 'earth',
};
export function aliasSkill(name) { return SKILL_ALIAS[name] || name; }

export function makeSkills() {
  const out = {};
  for (const k of SKILL_KEYS) out[k] = { lv: 1, xp: 0 };
  out.hp.lv = 10;
  return out;
}

/** Migrate an old-schema save (forage/fish/wc/mine/smith as separate
 *  skills) to the new 10-skill shape. Idempotent: a save that already
 *  has wilds/earth keys is returned unchanged. Combines XP across merged
 *  sources and takes the MAX level (so a Forage-30 / Fish-5 player ends
 *  up at Wilds-30 with the combined XP, not penalized). */
export function migrateSkills(saved) {
  if (!saved || saved.wilds || saved.earth) return saved;
  const _ = (k) => saved[k] || { lv: 1, xp: 0 };
  const max3 = (a, b, c) => ({
    lv: Math.max(a.lv, b.lv, c.lv),
    xp: (a.xp || 0) + (b.xp || 0) + (c.xp || 0),
  });
  const max2 = (a, b) => ({
    lv: Math.max(a.lv, b.lv),
    xp: (a.xp || 0) + (b.xp || 0),
  });
  saved.wilds = max3(_('forage'), _('fish'), _('wc'));
  saved.earth = max2(_('mine'), _('smith'));
  delete saved.forage; delete saved.fish; delete saved.wc;
  delete saved.mine; delete saved.smith;
  return saved;
}

/** Convert HP level to hpMax. Doubled vs the OSRS 1:1 rule so a cozy-RPG
 *  player isn't two-shot by mid-tier enemies before HP-XP catches up. HP
 *  Lv 10 → 20, Lv 50 → 100, Lv 99 → 198. */
export function hpMaxForLv(lv) { return Math.max(1, lv) * 2; }

let levelUpHook = () => {};
let xpHook      = () => {};
export function setLevelUpHook(fn) { levelUpHook = fn; }
export function setXpHook(fn)      { xpHook = fn; }

function maybeLevelUp(player, skill, log) {
  while (player.skills[skill].xp >= xpForLevel(player.skills[skill].lv + 1)) {
    player.skills[skill].lv++;
    log('skill', `↑ ${skill.toUpperCase()} level up — now ${player.skills[skill].lv}`);
    levelUpHook(player, skill);
    if (skill === 'hp') player.hpMax = hpMaxForLv(player.skills.hp.lv);
  }
}

export function awardXp(player, skill, amount, log, ctx) {
  if (amount <= 0) return;
  // Auto-alias old skill names so we don't have to chase every call site
  // immediately. `awardXp(player, 'mine', 12, ...)` becomes Earth XP.
  const k = SKILL_ALIAS[skill] || skill;
  if (!player.skills[k]) return;
  player.skills[k].xp += amount;
  xpHook(player, k, amount, ctx);
  maybeLevelUp(player, k, log);
}

export function awardCombatXp(player, damage, role, log, ctx) {
  if (damage <= 0) return;
  const styleName = player.combatStyle || CONFIG.combat.defaultStyle;
  const s = CONFIG.combat.styles[styleName] || CONFIG.combat.styles.controlled;
  if (role === 'attacker') {
    awardXp(player, 'atk', damage * s.att, log, ctx);
    awardXp(player, 'str', damage * s.str, log, ctx);
    awardXp(player, 'hp',  damage * s.hp,  log, ctx);
  } else if (role === 'defender') {
    awardXp(player, 'def', damage * 4,     log, ctx);
    awardXp(player, 'hp',  damage * s.hp,  log, ctx);
  }
}

export function xpProgress(player, skill) {
  const lv = player.skills[skill].lv;
  const cur = xpForLevel(lv);
  const nxt = xpForLevel(lv + 1);
  return Math.max(0, Math.min(100, 100 * (player.skills[skill].xp - cur) / (nxt - cur)));
}
