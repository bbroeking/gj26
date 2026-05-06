// Combat formulas. Anchored hit-splats use 3D positions of the entity meshes.
import { CONFIG } from '../data/config.js';
import { ITEMS } from '../data/items.js';
import { awardCombatXp } from './skills.js';
import { spawnSplat, spawnFloat } from '../core/floaters.js';
import { triggerSwing, triggerPowerSwing, triggerHurt } from '../anim/procedural.js';
import * as THREE from 'three';

function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

/** Look up the equipped weapon's class modifiers. Returns
 *  { cdMul, dmgMul, weaponClass } with sane defaults if no weapon
 *  equipped (bare-fist baseline = same as a sword: cdMul 1.0, dmgMul 1.0).
 *  Used by combat to make daggers swing-faster-but-hit-softer than swords.
 *  Per docs/design/06-equipment-progression.md §5.
 */
function weaponMods(player) {
  const id = player.inventory.equipped.weapon;
  if (!id) return { cdMul: 1.0, dmgMul: 1.0, weaponClass: 'fist' };
  const item = ITEMS[id];
  return {
    cdMul: item?.cdMul ?? 1.0,
    dmgMul: item?.dmgMul ?? 1.0,
    weaponClass: item?.weaponClass ?? 'sword',
  };
}

function entityWorldPos(e, yOffset = 1.0) {
  // mesh.position lives at tile center. Lift hit-splat above the head.
  return new THREE.Vector3(e.mesh.position.x, e.mesh.position.y + yOffset, e.mesh.position.z);
}

// ---------------------------------------------------------------------------
// Player damage roll (post combat-style pivot).
//
// Old model: hitChance gated whether the swing did 0 or [0..maxHit].
// New model: every swing connects. hitChance is now a QUALITY knob — high
// quality skews the random toward maxHit, low quality skews toward 1.
// Floor is always at least 1, so misses-feel is gone.
// ---------------------------------------------------------------------------
function _rollDamage(player, target, dmgMul = 1) {
  const c = CONFIG.combat;
  const atkLv = player.skills.atk.lv;
  const strLv = player.skills.str.lv;
  const atkBonus = player.inventory.totalEquipBonus('atk');
  const strBonus = player.inventory.totalEquipBonus('str');
  const quality = clamp(
    c.hitBase + c.atkContrib * (atkLv + atkBonus) - c.defContrib * (target.defLv || 1),
    c.hitLo, c.hitHi
  );
  const baseMax = Math.max(c.minMaxHit, Math.floor(c.strBase + c.strContrib * (strLv + strBonus)));
  const maxHit = Math.max(c.minMaxHit, Math.round(baseMax * dmgMul));
  // Weighted roll: pull the random toward 1 (low quality) or maxHit (high).
  // At quality=1.0 → biased ≈ 0.7+ (mostly upper half). At 0.4 → biased ≈ 0.3
  // (mostly lower half). Floors at 1 so a "bad swing" still chips.
  const r = Math.random();
  const biased = r * (1 - quality * 0.6) + Math.pow(r, 2) * (quality * 0.6);
  const dmg = Math.max(1, Math.round(1 + biased * (maxHit - 1)));
  return { dmg, maxHit };
}

export function rollPlayerSwing(player, target) {
  return _rollDamage(player, target).dmg;
}

/** Same as rollPlayerSwing but also reports the maxHit so the caller can
 *  detect crits without redoing the calculation. */
export function rollPlayerSwingDetailed(player, target) {
  const { dmgMul } = weaponMods(player);
  return _rollDamage(player, target, dmgMul);
}

export function rollEnemySwing(enemy, player) {
  const c = CONFIG.combat;
  const defLv = player.skills.def.lv;
  const defBonus = player.inventory.totalEquipBonus('def');
  // Enemy hit chance uses its own (lower-capped) bounds so the player
  // gets reliable dodge windows and isn't death-spiraled in pulls. Hit
  // floor 10%, ceiling 85% — bosses never auto-hit.
  const hitChance = clamp(
    c.enemyHitBase + c.atkContrib * (enemy.atkLv || 1) - c.defContrib * (defLv + defBonus),
    c.enemyHitLo, c.enemyHitHi
  );
  if (Math.random() < hitChance) return Math.floor(Math.random() * ((enemy.maxHit || 1) + 1));
  return 0;
}

export function attackEnemy(player, enemy, log) {
  if (!enemy.alive) return;
  // Lock on regardless of whether we can swing right now — auto-attack
  // tick (in main loop) keeps swinging once cooldown expires.
  player.combatTarget = enemy;
  if (player.attackCd > 0) return;
  // Weapon-class swing cooldown: dagger swings 25% faster (cdMul 0.75),
  // sword/axe at 1.0× / 1.4×. Daggers' faster cadence pairs with their
  // lower per-hit damage to keep DPS roughly even across weapon classes.
  const { cdMul } = weaponMods(player);
  player.attackCd = Math.round(CONFIG.player.attackCdFrames * cdMul);
  enemy.hurtT = 12;
  enemy.hitReactT = 0.18;          // squash + knockback duration
  enemy.flashT    = 0.18;          // material emissive flash (set by updateEnemy)
  // knockback away from player
  enemy.knockX = Math.sign(enemy.pos.x - player.pos.x) * 0.18;
  enemy.knockZ = Math.sign(enemy.pos.z - player.pos.z) * 0.18;
  enemy.aggro = true;
  // Pre-roll the swing so we know whether it's a power-strike *before*
  // we trigger the animation. Lets the third hit play the longer arc.
  const swingPredict = player.comboCount + 1 >= 3;
  if (player.animState) {
    if (swingPredict) triggerPowerSwing(player.animState);
    else              triggerSwing(player.animState);
  }

  let { dmg, maxHit } = rollPlayerSwingDetailed(player, enemy);
  const splatPos = entityWorldPos(enemy, 1.2);
  const enemyLabel = enemy.kind === 'goblin' ? 'Bramble-imp' : 'Cow';
  if (dmg === 0) {
    spawnSplat(splatPos, '0', 'miss');
    log('combat', `⚔ Miss. (${enemyLabel} ${enemy.hp}/${enemy.hpMax})`);
    // Misses don't advance the combo and reset the timer slightly so the
    // chain doesn't stall forever between attempts.
    if (player.comboT > 0) player.comboT = Math.max(0.6, player.comboT * 0.5);
    return;
  }
  // Combo: this is a successful hit. The third in a row becomes a power
  // swing (1.5× damage, capped at 2× maxHit). Resets after, so there's
  // a small payoff cycle independent of the crit roll.
  player.comboCount = (player.comboCount || 0) + 1;
  player.comboT = 2.0;
  const isPowerSwing = player.comboCount >= 3;
  if (isPowerSwing) {
    const boosted = Math.min(maxHit * 2, Math.round(dmg * 1.5));
    dmg = boosted;
    player.comboCount = 0;
    player.comboT = 0;
  }
  // Riposte counter — the parry window negated an incoming hit, so the
  // next swing gets a damage bonus + guaranteed crit-feel sparks.
  let isRiposte = false;
  if (player.riposteCounterReady) {
    player.riposteCounterReady = false;
    dmg = Math.min(maxHit * 3, Math.round(dmg * 2.0));
    isRiposte = true;
  }
  // Critical: any hit landing in the top 15% of the player's roll range.
  // maxHit ≥ 4 gate prevents trivially-frequent crits at very low Str.
  const isCrit = maxHit >= 4 && dmg >= Math.ceil(maxHit * 0.85);
  enemy.hp -= dmg;
  // Splat kind escalates by hit category: kill (red, biggest) > crit
  // (yellow, big) > hit (brown, default). Pillar-3 readability — bigger
  // numbers communicate "this hit mattered" at a glance.
  const willKill = enemy.hp <= 0;
  spawnSplat(splatPos, dmg, willKill ? 'kill' : isCrit ? 'crit' : 'hit');
  // Heavier knockback on power swings so the third hit reads physically
  if (isPowerSwing) {
    enemy.knockX *= 1.6;
    enemy.knockZ *= 1.6;
    enemy.hitReactT = 0.28;
    // Interrupt the enemy's queued attack (no-op for bosses).
    import('./enemies.js').then(m => {
      if (m.interruptEnemy(enemy)) {
        log('combat', `⚡ Interrupted!`);
      }
    });
    // Ground impact ring at the enemy's position — expanding warm-gold
    // halo so the strike reads as a heavy connect.
    import('../scene/impact.js').then(m => m.spawnImpactRing({
      x: enemy.pos.x, z: enemy.pos.z,
    }, { color: 0xffd864, life: 0.45, maxScale: 3.4 }));
  }
  if (isRiposte) {
    log('combat', `⚔ RIPOSTE ${dmg}!! (${enemyLabel} ${Math.max(0, enemy.hp)}/${enemy.hpMax})`);
    import('../core/sfx.js').then(m => m.sfx.riposte()).catch(() => {});
  }
  else if (isPowerSwing && isCrit) log('combat', `⚔ POWER CRIT ${dmg}!! (${enemyLabel} ${Math.max(0, enemy.hp)}/${enemy.hpMax})`);
  else if (isPowerSwing)      log('combat', `⚔ POWER ${dmg}! (${enemyLabel} ${Math.max(0, enemy.hp)}/${enemy.hpMax})`);
  else if (isCrit)            log('combat', `⚔ CRIT ${dmg}! (${enemyLabel} ${Math.max(0, enemy.hp)}/${enemy.hpMax})`);
  else                        log('combat', `⚔ Hit ${dmg}. (${enemyLabel} ${Math.max(0, enemy.hp)}/${enemy.hpMax})`);
  import('../core/sfx.js').then(m => m.sfx.hit());
  // Power swings + crits get layered audio + harder shake + a brief
  // FOV pulse so the camera "leans into" the hit. Stack: the third hit
  // always feels different even without a crit roll.
  if (isPowerSwing || isCrit) {
    const shakeBase = isPowerSwing ? 0.13 : 0.10;
    import('../core/camera.js').then(m => {
      m.shakeCamera(shakeBase + Math.min(0.10, dmg * 0.012));
      // Crit-feel layer: pillar-2 stacking. Crits get a stronger 5°
      // pulse (was 3.5°) so they read closer to power swings — a crit
      // SHOULD feel like a moment, not a number variance.
      m.fovPulse(isPowerSwing ? 5 : 5, 0.18);
    });
    import('../core/sfx.js').then(m => { setTimeout(() => m.sfx.craft(), 60); });
    // Hit-stop — brief time freeze so the hit "lands". Power gets a
    // beefier pause than a normal crit. Crits also get a slight bump
    // (0.05 → 0.07) so the bigger splat has time to register before
    // the screen unfreezes.
    import('../core/hitstop.js').then(m => {
      m.triggerHitStop(isPowerSwing ? 0.08 : 0.07, 0.05);
    });
  } else {
    import('../core/camera.js').then(m => m.shakeCamera(0.04 + Math.min(0.08, dmg * 0.012)));
  }
  // Spark burst — gold normal, white-gold crit, deep-red+white-gold power.
  let sparkColor = 0xf6c64a, sparkCount = Math.min(14, 6 + dmg), sparkSpread = 1.4 + Math.min(0.8, dmg * 0.08), sparkSize = 5, sparkLife = 0.32;
  if (isCrit)        { sparkColor = 0xfff2c0; sparkCount = Math.min(22, 12 + dmg); sparkSpread += 0.8; sparkSize = 7; sparkLife = 0.45; }
  if (isPowerSwing)  { sparkColor = 0xff8a3a; sparkCount = Math.min(28, 16 + dmg); sparkSpread += 1.0; sparkSize = 8; sparkLife = 0.55; }
  import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
    count: sparkCount, spread: sparkSpread, color: sparkColor, size: sparkSize, life: sparkLife,
  }));
  awardCombatXp(player, dmg, 'attacker', log, { worldPos: splatPos });

  if (enemy.hp <= 0) {
    // KILLING-BLOW FLOURISH (game-feel pillar 7+2)
    // The most important frame in the game. Stack: extra hit-stop, big
    // spark explosion, camera FOV-zoom, harder shake, dramatic log line.
    // All synchronized to the same frame so the player's brain reads
    // "the kill landed" as one thunderclap, not five sequential beats.
    import('../core/hitstop.js').then(m => m.triggerHitStop(0.12, 0.06));
    import('../core/camera.js').then(m => {
      m.shakeCamera(0.18 + Math.min(0.10, dmg * 0.012));
      m.fovPulse(-3, 0.15);   // ZOOM-IN micro-pause (negative = narrower fov)
    });
    // 24-spark warm-gold explosion ringing the death tile.
    import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
      count: 24, spread: 2.4, color: 0xffd864, size: 8, life: 0.65,
    }));
    // Ground impact ring at the death tile — wider + slower than the
    // power-swing variant so death reads as a punctuation.
    import('../scene/impact.js').then(m => m.spawnImpactRing({
      x: enemy.pos.x, z: enemy.pos.z,
    }, { color: 0xffd864, life: 0.6, maxScale: 4.0 }));
    enemy.alive = false;
    enemy.respawn = 60 * 30;
    enemy.mesh.visible = false;
    log('combat', `⚔ FELLED — ${enemyLabel} defeated.`);
    if (enemy.onDeath) enemy.onDeath(player, log);
  }
}

export function damagePlayer(player, dmg, log, source = 'enemy', opts = {}) {
  if (player.hurtT > 0) return;
  // Riposte parry window: negate the hit and queue a free counter-strike.
  // Checked BEFORE dodge i-frames so red parry-only attacks are still
  // parry-able even if the player happened to be mid-dodge.
  if (player.riposteT > 0) {
    const splatPos = new THREE.Vector3(player.pos.x, player.pos.y + 1.5, player.pos.z);
    spawnFloat(splatPos, 'Parried!', 'level');
    player.riposteT = 0;
    player.riposteCounterReady = true;
    import('../core/sfx.js').then(m => m.sfx.parry()).catch(() => {});
    return;
  }
  // Dodge i-frames negate normal hits but NOT parry-only (red) attacks.
  // The fairness contract: red attacks demand a parry, full stop.
  if (player.iframeT > 0 && !opts.parryOnly) {
    const splatPos = new THREE.Vector3(player.pos.x, player.pos.y + 1.5, player.pos.z);
    spawnFloat(splatPos, 'Dodged!', 'miss');
    import('../core/sfx.js').then(m => m.sfx.miss()).catch(() => {});
    return;
  }
  const splatPos = new THREE.Vector3(player.pos.x, player.pos.y + 1.5, player.pos.z);
  if (dmg === 0) {
    spawnSplat(splatPos, '0', 'miss');
    return;
  }
  if (typeof window !== 'undefined' && window.__godMode && window.__godMode()) {
    spawnSplat(splatPos, '0', 'miss');
    return;
  }
  // Defensive Stance — halve incoming damage while the buff is active.
  if (player.defensiveT > 0) {
    dmg = Math.max(1, Math.floor(dmg * 0.5));
  }
  // Stone Skin (rune magic) — -30% incoming damage while active.
  if (player.stoneSkinT > 0) {
    dmg = Math.max(1, Math.floor(dmg * 0.7));
  }
  player.hp -= dmg;
  player.hurtT = 18;
  // Taking a hit breaks the player's combo chain.
  player.comboCount = 0;
  player.comboT = 0;
  // Hurt vignette — strength scales with damage taken; CSS handles the
  // ease-out fade. Cleared on the next damagePlayer call by re-applying.
  if (typeof document !== 'undefined') {
    const v = document.getElementById('hurt-vignette');
    if (v) {
      const strength = Math.min(0.95, 0.55 + dmg * 0.06);
      v.style.setProperty('--vignette-strength', String(strength));
      v.classList.add('show');
      clearTimeout(v._hideTimer);
      v._hideTimer = setTimeout(() => v.classList.remove('show'), 180);
    }
  }
  if (player.animState) triggerHurt(player.animState);
  spawnSplat(splatPos, dmg, 'hit');
  import('../core/sfx.js').then(m => m.sfx.hit());
  // Screen-shake scales with damage — feels meaningful, doesn't nausea
  import('../core/camera.js').then(m => m.shakeCamera(0.06 + Math.min(0.16, dmg * 0.03)));
  // Red-orange sparks on the player to read as 'they hit me'
  import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
    count: Math.min(14, 6 + dmg),
    spread: 1.5 + Math.min(0.9, dmg * 0.08),
    color: 0xc63030,
  }));
  log('combat', `⚔ ${source} hits you for ${dmg}.`);
  awardCombatXp(player, dmg, 'defender', log, { worldPos: splatPos });
  if (player.hp <= 0) {
    // Don't reset here — main.js polls this flag and handles the full
    // death flow (modal + dungeon exit + ground-loot wipe + respawn).
    player.hp = 0;
    player._justDied = true;
  }
}
