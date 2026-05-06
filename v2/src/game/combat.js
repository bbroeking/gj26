// Combat formulas + swing dispatch. OSRS-loose:
//   hit_chance = clamp(base + atkContrib*(atkLv+atkBonus) - defContrib*defLv, lo, hi)
//   max_hit    = max(1, floor(strBase + strContrib * (strLv + strBonus)))
//   on_swing   = roll(hit_chance) ? roll(0..max_hit) : 0
import { CONFIG } from '../data/config.js';
import { spawnHitSplat, spawnPuff, spawnSparks } from '../core/particles.js';
import { awardCombatXp } from './skills.js';

function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

export function rollPlayerSwing(player, target) {
  const atkLv = player.skills.atk.lv;
  const strLv = player.skills.str.lv;
  const atkBonus = player.inventory.totalEquipBonus('atk');
  const strBonus = player.inventory.totalEquipBonus('str');
  const c = CONFIG.combat;
  const hitChance = clamp(
    c.hitBase + c.atkContrib * (atkLv + atkBonus) - c.defContrib * (target.defLv || 1),
    c.hitLo, c.hitHi);
  const maxHit = Math.max(c.minMaxHit, Math.floor(c.strBase + c.strContrib * (strLv + strBonus)));
  if (Math.random() < hitChance) {
    return Math.floor(Math.random() * (maxHit + 1));
  }
  return 0;
}

export function rollEnemySwing(enemy, player) {
  const c = CONFIG.combat;
  const defLv = player.skills.def.lv;
  const defBonus = player.inventory.totalEquipBonus('def');
  const hitChance = clamp(
    c.hitBase + c.atkContrib * (enemy.atkLv || 1) - c.defContrib * (defLv + defBonus),
    c.hitLo, c.hitHi);
  const maxHit = enemy.maxHit || 1;
  if (Math.random() < hitChance) return Math.floor(Math.random() * (maxHit + 1));
  return 0;
}

export function attackEnemy(player, enemy, log) {
  if (!enemy.alive || player.attackCd > 0) return;
  player.attackCd = CONFIG.player.attackCdFrames;
  enemy.hurtT = 12;
  enemy.aggro = true;

  const dmg = rollPlayerSwing(player, enemy);
  if (dmg === 0) {
    spawnHitSplat(enemy.px + 16, enemy.py + 6, '0', 'miss');
    log('combat', `⚔ Miss. (Cow: ${enemy.hp}/${enemy.hpMax})`);
    return;
  }
  enemy.hp -= dmg;
  spawnHitSplat(enemy.px + 16, enemy.py + 6, dmg, 'hit');
  spawnSparks(enemy.px + 16, enemy.py + 16, 5);
  log('combat', `⚔ Hit ${dmg}. (Cow: ${Math.max(0,enemy.hp)}/${enemy.hpMax})`);

  awardCombatXp(player, dmg, 'attacker', log);

  if (enemy.hp <= 0) {
    enemy.alive = false;
    enemy.respawn = 60 * 30;
    spawnPuff(enemy.px + 16, enemy.py + 16, '#a5523a', 14);
    log('combat', `☠ Cow defeated.`);
    if (enemy.onDeath) enemy.onDeath(player, log);
  }
}

export function damagePlayer(player, dmg, log, source = 'enemy') {
  if (player.hurtT > 0) return; // i-frames
  if (dmg === 0) {
    spawnHitSplat(player.px + 16, player.py + 6, '0', 'miss');
    return;
  }
  player.hp -= dmg;
  player.hurtT = 18;
  spawnHitSplat(player.px + 16, player.py + 6, dmg, 'hit');
  spawnPuff(player.px + 16, player.py + 18, '#a52', 3);
  log('combat', `⚔ ${source} hits you for ${dmg}.`);
  awardCombatXp(player, dmg, 'defender', log);
  if (player.hp <= 0) {
    log('combat', '☠ You died. Respawning...');
    player.hp = player.hpMax;
    player.x = player.spawnX; player.y = player.spawnY;
    player.px = player.x * 32; player.py = player.y * 32;
  }
}
