// Skill XP + level-up. Combat XP split (Att/Str/Def/HP) follows OSRS-ish
// "controlled" style: shared across the trio + HP gets a slice from damage.
import { CONFIG, xpForLevel } from '../data/config.js';
import { spawnSparks, spawnText } from '../core/particles.js';

export const SKILL_KEYS = ['atk', 'str', 'def', 'hp', 'cook'];

export function makeSkills() {
  const out = {};
  for (const k of SKILL_KEYS) out[k] = { lv: 1, xp: 0 };
  out.hp.lv = 10; // OSRS-style: HP starts at 10
  return out;
}

function maybeLevelUp(player, skill, log) {
  while (player.skills[skill].xp >= xpForLevel(player.skills[skill].lv + 1)) {
    player.skills[skill].lv++;
    log('skill', `↑ ${skill.toUpperCase()} level up — now ${player.skills[skill].lv}`);
    spawnSparks(player.px + 16, player.py + 8, 16);
    spawnText(player.px + 16, player.py - 6, 'LEVEL UP!', '#ffd84a');
    if (skill === 'hp') player.hpMax = player.skills.hp.lv;
  }
}

export function awardXp(player, skill, amount, log) {
  player.skills[skill].xp += amount;
  maybeLevelUp(player, skill, log);
}

/**
 * Combat XP split — controlled style:
 *   damage -> {att, str} share + hp share
 *   defending hit lands -> def + hp share
 */
export function awardCombatXp(player, damage, role, log) {
  if (damage <= 0) return;
  const split = CONFIG.combat.xpSplit;
  if (role === 'attacker') {
    awardXp(player, 'atk', damage * split.att, log);
    awardXp(player, 'str', damage * split.str, log);
    awardXp(player, 'hp',  damage * split.hp,  log);
  } else if (role === 'defender') {
    awardXp(player, 'def', damage * split.def + damage * 1.5, log); // hit-taken xp
    awardXp(player, 'hp',  damage * split.hp, log);
  }
}

export function xpProgress(player, skill) {
  const lv = player.skills[skill].lv;
  const cur = xpForLevel(lv);
  const nxt = xpForLevel(lv + 1);
  return Math.max(0, Math.min(100, 100 * (player.skills[skill].xp - cur) / (nxt - cur)));
}
