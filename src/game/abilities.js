// ARPG-style active abilities. Each slot 1..4 maps to one ABILITY id.
// Activating an ability:
//   - Checks the player's level on its required skill (locked = won't fire)
//   - Checks the per-ability cooldown stored on player.abilityCd[slot]
//   - Runs the effect (immediate or async with a small wind-up)
//   - Resets that slot's cooldown
//
// All effects route through the existing combat formulas, so equipment +
// skill levels still matter — abilities just shape WHEN and WHERE damage
// lands. The default cooldown values are seconds.
//
// Public API:
//   ABILITIES                       — id → AbilityDef
//   slotForKey(key)                 — '1'..'4' → ability id
//   isAbilityUnlocked(player, id)   — level gate
//   tryActivate(player, slot, ctx)  — main entry; returns true if fired

import * as THREE from 'three';
import { rollPlayerSwingDetailed } from './combat.js';
import { spawnSplat } from '../core/floaters.js';
import { awardCombatXp } from './skills.js';
import { triggerSwing } from '../anim/procedural.js';

// Slot → ability id. Keep stable so the UI can render labels.
// Default slot bindings — one ability per skill tree so a fresh save sees
// the breadth of the catalog. The OLD all-atk default (cleave/leap/rend/
// whirlwind) hid 8 of 12 abilities behind the rebinding UI; players who
// never opened that menu literally never used the str/def/hp trees. See
// docs/design/09-active-abilities.md §1a for the full audit.
//
// Per-player saved bindings (`player.actionBar`) still override these
// defaults at slot resolution time (see slotForKey usage at line ~694).
export const SLOT_BINDINGS = {
  1: 'cleave',         // atk tree, lv 5  — early-game starter, kept
  2: 'shield_bash',    // def tree, lv 8  — introduces defensive vocabulary
  3: 'bull_rush',      // str tree, lv 10 — introduces str-tree
  4: 'last_stand',     // hp tree, lv 25  — endgame panic-button slot
};

export function slotForKey(slot) {
  return SLOT_BINDINGS[slot] || null;
}

/**
 * @typedef {object} AbilityDef
 * @property {string} id
 * @property {string} name
 * @property {string} icon            single emoji or short text glyph
 * @property {string} reqSkill        e.g. 'atk' / 'str' / 'def' (must exist on player.skills)
 * @property {number} reqLevel        unlock level on the required skill
 * @property {number} cooldown        seconds
 * @property {string} desc            tooltip line
 * @property {(player,ctx)=>void} run effect
 */

// Direction vectors for facing → tile-step.
const FACING_DELTA = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] };

/** Run an AoE swing on every alive enemy in a square radius around (cx, cy).
 *  Used by Leap, Cleave, and Whirlwind. Detects per-target crits and emits
 *  brighter sparks + crit log entries (capped to one log per swing so the
 *  combat chronicle doesn't spam). */
function aoeSwing(player, ctx, cx, cy, radius, opts = {}) {
  const targets = ctx.enemies.filter(e => e.alive
    && Math.abs(e.x - cx) <= radius
    && Math.abs(e.y - cy) <= radius);
  let hits = 0;
  let crits = 0;
  let bestCrit = 0;
  let bestCritName = null;
  for (const enemy of targets) {
    const { dmg, maxHit } = rollPlayerSwingDetailed(player, enemy);
    const isCrit = maxHit >= 4 && dmg >= Math.ceil(maxHit * 0.85);
    const splatPos = new THREE.Vector3(enemy.mesh.position.x, enemy.mesh.position.y + 1.2, enemy.mesh.position.z);
    enemy.knockX = Math.sign(enemy.pos.x - (cx + 0.5)) * (isCrit ? 0.42 : 0.30);
    enemy.knockZ = Math.sign(enemy.pos.z - (cy + 0.5)) * (isCrit ? 0.42 : 0.30);
    enemy.hurtT = 12;
    enemy.hitReactT = isCrit ? 0.28 : 0.22;
    enemy.flashT = isCrit ? 0.26 : 0.20;
    enemy.aggro = true;
    if (dmg === 0) {
      spawnSplat(splatPos, '0', 'miss');
    } else {
      enemy.hp -= dmg;
      spawnSplat(splatPos, dmg, 'hit');
      awardCombatXp(player, dmg, 'attacker', ctx.log, { worldPos: splatPos });
      hits++;
      if (isCrit) {
        crits++;
        if (dmg > bestCrit) {
          bestCrit = dmg;
          bestCritName = enemy.displayName || (enemy.kind === 'goblin' ? 'Bramble-imp' : enemy.kind);
        }
      }
      import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
        count:  isCrit ? Math.min(22, (opts.sparkCount ?? 12) + 8) : (opts.sparkCount ?? 12),
        spread: isCrit ? (opts.sparkSpread ?? 2.0) + 0.6 : (opts.sparkSpread ?? 2.0),
        color:  isCrit ? 0xfff2c0 : (opts.sparkColor ?? 0xffd864),
        size:   isCrit ? 7 : 5,
        life:   isCrit ? 0.45 : 0.32,
      }));
      if (enemy.hp <= 0) {
        enemy.alive = false;
        enemy.respawn = 60 * 30;
        enemy.mesh.visible = false;
        ctx.log('combat', `☠ ${enemy.displayName || (enemy.kind === 'goblin' ? 'Bramble-imp' : enemy.kind)} defeated.`);
        if (enemy.onDeath) enemy.onDeath(player, ctx.log);
      }
    }
  }
  if (crits > 0 && bestCritName) {
    ctx.log('combat', `⚔ CRIT ×${crits} (best ${bestCrit} on ${bestCritName})`);
  }
  return { struck: hits, considered: targets.length, crits };
}

/** @type {Record<string, AbilityDef>} */
export const ABILITIES = {
  cleave: {
    id: 'cleave',
    name: 'Cleave',
    icon: '🪓',
    reqSkill: 'atk',
    reqLevel: 5,
    cooldown: 5,
    staminaCost: 25,
    desc: 'Sweeping arc. Strike every adjacent enemy at once.',
    run(player, ctx) {
      if (player.animState) triggerSwing(player.animState);
      const { struck, considered } = aoeSwing(player, ctx, player.x, player.y, 1, { sparkCount: 10, sparkSpread: 1.8 });
      if (considered === 0) {
        ctx.log('combat', 'Cleave finds nothing to bite.');
        return;
      }
      ctx.log('combat', `⚔ Cleave! ${struck}/${considered} struck.`);
      import('../core/sfx.js').then(m => m.sfx.craft());
      import('../core/camera.js').then(m => m.shakeCamera(0.10));
    },
  },

  rend: {
    id: 'rend',
    name: 'Rend',
    icon: '🩸',
    reqSkill: 'atk',
    reqLevel: 18,
    cooldown: 12,
    staminaCost: 30,
    desc: 'Heavy strike on the tile in front. Bleeds the target for 5s.',
    run(player, ctx) {
      const [dx, dy] = FACING_DELTA[player.dir] || [0, 1];
      const tx = player.x + dx, ty = player.y + dy;
      const target = ctx.enemies.find(e => e.alive && e.x === tx && e.y === ty);
      if (!target) {
        ctx.log('combat', 'Rend finds nothing in front of you.');
        return;
      }
      if (player.animState) triggerSwing(player.animState);
      const { dmg, maxHit } = rollPlayerSwingDetailed(player, target);
      // Heavy strike: 1.5× the rolled damage, capped at 2× maxHit.
      const heavy = Math.min(maxHit * 2, Math.round(dmg * 1.5));
      const splatPos = new THREE.Vector3(target.mesh.position.x, target.mesh.position.y + 1.2, target.mesh.position.z);
      target.knockX = Math.sign(target.pos.x - player.pos.x) * 0.30;
      target.knockZ = Math.sign(target.pos.z - player.pos.z) * 0.30;
      target.hurtT = 12;
      target.hitReactT = 0.22;
      target.flashT = 0.22;
      target.aggro = true;
      if (heavy === 0) {
        spawnSplat(splatPos, '0', 'miss');
        ctx.log('combat', '⚔ Rend whiffs.');
      } else {
        target.hp -= heavy;
        spawnSplat(splatPos, heavy, 'hit');
        ctx.log('combat', `⚔ Rend ${heavy}!`);
        awardCombatXp(player, heavy, 'attacker', ctx.log, { worldPos: splatPos });
        // Apply bleed: 25% of the strike per tick, 5 ticks at 1s each.
        const bleedDmg = Math.max(1, Math.floor(heavy * 0.25));
        target.bleed = { dmg: bleedDmg, tickT: 1.0, ticksLeft: 5 };
        import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
          count: 18, spread: 1.6, color: 0xb14c33, size: 6, life: 0.5,
        }));
      }
      if (target.hp <= 0) {
        target.alive = false;
        target.respawn = 60 * 30;
        target.mesh.visible = false;
        ctx.log('combat', `☠ ${target.displayName || (target.kind === 'goblin' ? 'Bramble-imp' : target.kind)} defeated.`);
        if (target.onDeath) target.onDeath(player, ctx.log);
      }
      import('../core/sfx.js').then(m => m.sfx.craft());
      import('../core/camera.js').then(m => m.shakeCamera(0.16));
    },
  },

  whirlwind: {
    id: 'whirlwind',
    name: 'Whirlwind',
    icon: '🌀',
    reqSkill: 'atk',
    reqLevel: 25,
    cooldown: 20,
    staminaCost: 50,
    desc: 'Spin: three AoE strikes around you over ~1s. Move freely between hits.',
    run(player, ctx) {
      // Three cycles, 0.4s apart. Each cycle hits the 8-tile area
      // around the player's CURRENT tile, so chasing during channel
      // works. Skips if the player has died mid-channel.
      const cycles = 3;
      for (let i = 0; i < cycles; i++) {
        setTimeout(() => {
          if (player.hp <= 0) return;
          if (player.animState) triggerSwing(player.animState);
          const { struck, considered } = aoeSwing(player, ctx, player.x, player.y, 1, {
            sparkCount: 8, sparkSpread: 1.6, sparkColor: 0xfff2c0,
          });
          if (i === cycles - 1) {
            // Final spin — louder, and only log a summary at the end so
            // the chronicle doesn't fill with three near-identical lines.
            ctx.log('combat', `⚔ Whirlwind ends. Final flurry struck ${struck}/${considered}.`);
            import('../core/camera.js').then(m => m.shakeCamera(0.18));
          }
          import('../core/sfx.js').then(m => m.sfx.craft());
        }, i * 400);
      }
      ctx.log('combat', '⚔ You spin into a whirlwind.');
    },
  },

  leap: {
    id: 'leap',
    name: 'Leap',
    icon: '🦘',
    reqSkill: 'atk',
    reqLevel: 12,
    cooldown: 10,
    staminaCost: 35,
    desc: 'Bound 2 tiles forward; strike a 3×3 patch on landing.',
    run(player, ctx) {
      const [dx, dy] = FACING_DELTA[player.dir] || [0, 1];
      // Find the farthest unblocked landing tile up to range 2.
      let landingX = player.x, landingY = player.y, hops = 0;
      for (let step = 1; step <= 2; step++) {
        const nx = player.x + dx * step;
        const ny = player.y + dy * step;
        if (ctx.isBlocked && ctx.isBlocked(nx, ny)) break;
        landingX = nx; landingY = ny; hops = step;
      }
      if (hops === 0) {
        ctx.log('hint', 'No room to leap.');
        return;
      }
      // Telegraph the landing tile briefly so it reads as a leap.
      import('../scene/telegraph.js').then(m => m.spawnTileTelegraph(landingX, landingY, 0.25, { color: 0xf6c64a }));
      // Brief i-frame window during the hop, plus a small camera kick.
      player.iframeT = Math.max(player.iframeT || 0, 0.22);
      import('../core/camera.js').then(m => m.shakeCamera(0.14));
      // Snap the player to the landing tile + sync the mesh.
      player.x = landingX; player.y = landingY;
      player.targetX = landingX; player.targetY = landingY;
      player.pos.x = landingX + 0.5;
      player.pos.z = landingY + 0.5;
      player.mesh.position.x = player.pos.x;
      player.mesh.position.z = player.pos.z;
      player.path = [];
      player.onPathDone = null;
      player.moving = false;
      if (player.animState) triggerSwing(player.animState);
      const { struck, considered } = aoeSwing(player, ctx, landingX, landingY, 1, { sparkCount: 16, sparkSpread: 2.4, sparkColor: 0xffd864 });
      ctx.log('combat', considered === 0
        ? `Leap! No-one in the landing zone.`
        : `⚔ Leap! ${struck}/${considered} struck on landing.`);
      import('../core/sfx.js').then(m => m.sfx.craft());
    },
  },

  // ---- Def tree --------------------------------------------------------
  shield_bash: {
    id: 'shield_bash',
    name: 'Shield Bash',
    icon: '🛡',
    reqSkill: 'def',
    reqLevel: 8,
    cooldown: 8,
    staminaCost: 20,
    desc: 'Bash the tile in front: light damage, interrupts the target\'s attack, brief stagger.',
    run(player, ctx) {
      const [dx, dy] = FACING_DELTA[player.dir] || [0, 1];
      const tx = player.x + dx, ty = player.y + dy;
      const target = ctx.enemies.find(e => e.alive && e.x === tx && e.y === ty);
      if (!target) {
        ctx.log('combat', 'Shield Bash finds nothing to hit.');
        return;
      }
      if (player.animState) triggerSwing(player.animState);
      // Light damage — half of a normal swing.
      const { dmg, maxHit } = rollPlayerSwingDetailed(player, target);
      const halfDmg = Math.max(1, Math.floor(dmg * 0.5));
      const splatPos = new THREE.Vector3(target.mesh.position.x, target.mesh.position.y + 1.2, target.mesh.position.z);
      target.knockX = Math.sign(target.pos.x - player.pos.x) * 0.40;
      target.knockZ = Math.sign(target.pos.z - player.pos.z) * 0.40;
      target.hurtT = 12;
      target.hitReactT = 0.32;
      target.flashT = 0.22;
      target.aggro = true;
      // Always interrupt + stagger — that's the value, not the damage.
      import('./enemies.js').then(m => { m.interruptEnemy?.(target); });
      target.staggered = true;
      setTimeout(() => { if (target) target.staggered = false; }, 1000);   // 1s stun
      target.attackCd = Math.max(target.attackCd, 60);                     // ~1s additional CD
      target.hp -= halfDmg;
      spawnSplat(splatPos, halfDmg, 'hit');
      ctx.log('combat', `🛡 Shield Bash! Staggered for 1s.`);
      awardCombatXp(player, halfDmg, 'attacker', ctx.log, { worldPos: splatPos });
      import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
        count: 14, spread: 1.4, color: 0xc8d8e0, size: 6, life: 0.4,
      }));
      if (target.hp <= 0) {
        target.alive = false;
        target.respawn = 60 * 30;
        target.mesh.visible = false;
        ctx.log('combat', `☠ ${target.displayName || target.kind} defeated.`);
        if (target.onDeath) target.onDeath(player, ctx.log);
      }
      import('../core/sfx.js').then(m => m.sfx.hit());
      import('../core/camera.js').then(m => m.shakeCamera(0.10));
    },
  },

  defensive_stance: {
    id: 'defensive_stance',
    name: 'Defensive Stance',
    icon: '🛡',
    reqSkill: 'def',
    reqLevel: 14,
    cooldown: 25,
    staminaCost: 30,
    desc: 'Brace: 50% damage reduction for 4s. Take a beating, then strike back.',
    run(player, ctx) {
      player.defensiveT = Math.max(player.defensiveT || 0, 4.0);   // seconds; ticked in player.js
      ctx.log('combat', '🛡 Defensive Stance — incoming damage halved for 4s.');
      import('../core/sfx.js').then(m => m.sfx.craft());
      // Brief golden glow burst around the player so the buff reads.
      const splatPos = new THREE.Vector3(player.pos.x, player.pos.y + 1.0, player.pos.z);
      import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
        count: 18, spread: 1.6, color: 0xeed8a8, size: 6, life: 0.7,
      }));
    },
  },

  // ---- Str tree --------------------------------------------------------
  sunder: {
    id: 'sunder',
    name: 'Sunder',
    icon: '⚒',
    reqSkill: 'str',
    reqLevel: 15,
    cooldown: 15,
    staminaCost: 40,
    desc: 'Heavy strike that breaks armor — target\'s defense halved for 8s.',
    run(player, ctx) {
      const [dx, dy] = FACING_DELTA[player.dir] || [0, 1];
      const tx = player.x + dx, ty = player.y + dy;
      const target = ctx.enemies.find(e => e.alive && e.x === tx && e.y === ty);
      if (!target) {
        ctx.log('combat', 'Sunder finds nothing in front of you.');
        return;
      }
      if (player.animState) triggerSwing(player.animState);
      // Apply armor break BEFORE rolling damage so the strike benefits.
      if (target._sunderUntil === undefined) target._origDefLv = target.defLv;
      const origDef = target._origDefLv;
      target.defLv = Math.max(1, Math.floor(origDef * 0.5));
      target._sunderUntil = (target._sunderUntil || 0);
      // Schedule restore in 8 seconds. setTimeout chain is fine for jam scope.
      const expiry = Date.now() + 8000;
      target._sunderUntil = Math.max(target._sunderUntil, expiry);
      setTimeout(() => {
        if (target && target._sunderUntil <= Date.now() + 50) {
          target.defLv = target._origDefLv;
          target._sunderUntil = 0;
        }
      }, 8000);

      const { dmg, maxHit } = rollPlayerSwingDetailed(player, target);
      // Heavy: 1.4× the rolled damage.
      const heavy = Math.min(maxHit * 2, Math.round(dmg * 1.4));
      const splatPos = new THREE.Vector3(target.mesh.position.x, target.mesh.position.y + 1.2, target.mesh.position.z);
      target.knockX = Math.sign(target.pos.x - player.pos.x) * 0.30;
      target.knockZ = Math.sign(target.pos.z - player.pos.z) * 0.30;
      target.hurtT = 12;
      target.hitReactT = 0.26;
      target.flashT = 0.26;
      target.aggro = true;
      target.hp -= heavy;
      spawnSplat(splatPos, heavy, 'hit');
      ctx.log('combat', `⚒ Sunder ${heavy}! Armor broken (8s, def halved).`);
      awardCombatXp(player, heavy, 'attacker', ctx.log, { worldPos: splatPos });
      import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
        count: 20, spread: 1.8, color: 0xa28860, size: 7, life: 0.5,
      }));
      if (target.hp <= 0) {
        target.alive = false;
        target.respawn = 60 * 30;
        target.mesh.visible = false;
        ctx.log('combat', `☠ ${target.displayName || target.kind} defeated.`);
        if (target.onDeath) target.onDeath(player, ctx.log);
      }
      import('../core/sfx.js').then(m => m.sfx.hit());
      import('../core/camera.js').then(m => m.shakeCamera(0.18));
    },
  },

  bull_rush: {
    id: 'bull_rush',
    name: 'Bull Rush',
    icon: '🐂',
    reqSkill: 'str',
    reqLevel: 10,
    cooldown: 12,
    staminaCost: 35,
    desc: 'Charge 3 tiles forward, knocking back and stunning every enemy you pass through.',
    run(player, ctx) {
      const [dx, dy] = FACING_DELTA[player.dir] || [0, 1];
      // Walk up to 3 tiles, hitting any enemy on the path.
      let landingX = player.x, landingY = player.y, hops = 0;
      const struck = [];
      for (let step = 1; step <= 3; step++) {
        const nx = player.x + dx * step;
        const ny = player.y + dy * step;
        if (ctx.isBlocked && ctx.isBlocked(nx, ny)) break;
        // Pick up enemies on the rush path
        const e = ctx.enemies.find(en => en.alive && en.x === nx && en.y === ny);
        if (e) struck.push(e);
        landingX = nx; landingY = ny; hops = step;
      }
      if (hops === 0) {
        ctx.log('hint', 'No room to charge.');
        return;
      }
      // Snap player to landing tile + i-frames during charge
      player.iframeT = Math.max(player.iframeT || 0, 0.30);
      player.x = landingX; player.y = landingY;
      player.targetX = landingX; player.targetY = landingY;
      player.pos.x = landingX + 0.5;
      player.pos.z = landingY + 0.5;
      player.mesh.position.x = player.pos.x;
      player.mesh.position.z = player.pos.z;
      player.path = [];
      player.onPathDone = null;
      player.moving = false;
      if (player.animState) triggerSwing(player.animState);
      // Damage + stagger every struck enemy. Damage is light (60% of normal).
      for (const target of struck) {
        const { dmg } = rollPlayerSwingDetailed(player, target);
        const hit = Math.max(1, Math.floor(dmg * 0.60));
        const splatPos = new THREE.Vector3(target.mesh.position.x, target.mesh.position.y + 1.2, target.mesh.position.z);
        // Big knockback in the rush direction
        target.knockX = dx * 0.55;
        target.knockZ = dy * 0.55;
        target.hurtT = 12;
        target.hitReactT = 0.32;
        target.flashT = 0.22;
        target.aggro = true;
        target.staggered = true;
        setTimeout(() => { if (target) target.staggered = false; }, 800);
        target.attackCd = Math.max(target.attackCd, 50);
        target.hp -= hit;
        spawnSplat(splatPos, hit, 'hit');
        awardCombatXp(player, hit, 'attacker', ctx.log, { worldPos: splatPos });
        if (target.hp <= 0) {
          target.alive = false;
          target.respawn = 60 * 30;
          target.mesh.visible = false;
          if (target.onDeath) target.onDeath(player, ctx.log);
        }
        import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
          count: 14, spread: 1.6, color: 0xc88838, size: 6, life: 0.4,
        }));
      }
      ctx.log('combat', struck.length === 0
        ? `🐂 Bull Rush — clear path, ${hops} tiles.`
        : `🐂 Bull Rush! ${struck.length} struck and staggered.`);
      import('../core/sfx.js').then(m => m.sfx.craft());
      import('../core/camera.js').then(m => m.shakeCamera(0.16));
    },
  },

  backstab: {
    id: 'backstab',
    name: 'Backstab',
    icon: '🗡',
    reqSkill: 'atk',
    reqLevel: 20,
    cooldown: 14,
    staminaCost: 30,
    desc: 'Strike the tile in front. From behind the target, 2× damage and ignores armor.',
    run(player, ctx) {
      const [dx, dy] = FACING_DELTA[player.dir] || [0, 1];
      const tx = player.x + dx, ty = player.y + dy;
      const target = ctx.enemies.find(e => e.alive && e.x === tx && e.y === ty);
      if (!target) {
        ctx.log('combat', 'Backstab finds nothing in front of you.');
        return;
      }
      // Are we BEHIND the target? Compare player's tile vs the tile the
      // target's "back" points to. e.dir is the direction the enemy is
      // facing; their back is the opposite.
      const enemyFacing = FACING_DELTA[target.dir] || [0, 1];
      // Player is behind if the vector from enemy to player matches
      // the OPPOSITE of enemy's facing (i.e., player is on enemy's back).
      const px = player.x - target.x, py = player.y - target.y;
      const isBehind = (Math.sign(px) === -Math.sign(enemyFacing[0]))
                    && (Math.sign(py) === -Math.sign(enemyFacing[1]));
      if (player.animState) triggerSwing(player.animState);
      // Save + halve def for backstab (armor pierce), then roll, then restore.
      const origDef = target.defLv;
      if (isBehind) target.defLv = Math.max(1, Math.floor(origDef * 0.5));
      const { dmg, maxHit } = rollPlayerSwingDetailed(player, target);
      target.defLv = origDef;
      const final = isBehind
        ? Math.min(maxHit * 3, Math.round(dmg * 2.0))
        : Math.max(1, Math.floor(dmg));
      const splatPos = new THREE.Vector3(target.mesh.position.x, target.mesh.position.y + 1.2, target.mesh.position.z);
      target.knockX = Math.sign(target.pos.x - player.pos.x) * 0.30;
      target.knockZ = Math.sign(target.pos.z - player.pos.z) * 0.30;
      target.hurtT = 12;
      target.hitReactT = isBehind ? 0.30 : 0.20;
      target.flashT = 0.22;
      target.aggro = true;
      target.hp -= final;
      spawnSplat(splatPos, final, isBehind ? 'crit' : 'hit');
      if (isBehind) ctx.log('combat', `🗡 BACKSTAB ${final}!`);
      else          ctx.log('combat', `🗡 Backstab ${final} (frontal — needs flank).`);
      awardCombatXp(player, final, 'attacker', ctx.log, { worldPos: splatPos });
      import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
        count: isBehind ? 22 : 14,
        spread: isBehind ? 2.0 : 1.4,
        color: isBehind ? 0xff8a3a : 0xc63030,
        size: isBehind ? 7 : 5,
        life: isBehind ? 0.5 : 0.32,
      }));
      if (target.hp <= 0) {
        target.alive = false;
        target.respawn = 60 * 30;
        target.mesh.visible = false;
        ctx.log('combat', `☠ ${target.displayName || target.kind} defeated.`);
        if (target.onDeath) target.onDeath(player, ctx.log);
      }
      import('../core/sfx.js').then(m => m.sfx.hit());
      import('../core/camera.js').then(m => m.shakeCamera(isBehind ? 0.18 : 0.10));
      if (isBehind) {
        import('../core/hitstop.js').then(m => m.triggerHitStop(0.07, 0.05));
      }
    },
  },

  aimed_shot: {
    id: 'aimed_shot',
    name: 'Aimed Shot',
    icon: '🏹',
    reqSkill: 'atk',
    reqLevel: 16,
    cooldown: 10,
    staminaCost: 25,
    desc: 'Pick the nearest enemy in front (up to 5 tiles), fire a delayed shot for 1.5× damage.',
    run(player, ctx) {
      const [dx, dy] = FACING_DELTA[player.dir] || [0, 1];
      // Walk the line up to 5 tiles, pick first enemy hit. LOS interrupted
      // by walls (isBlocked). Doesn't pierce.
      let target = null;
      let landingX = player.x, landingY = player.y;
      for (let step = 1; step <= 5; step++) {
        const tx = player.x + dx * step;
        const ty = player.y + dy * step;
        if (ctx.isBlocked && ctx.isBlocked(tx, ty)) break;
        landingX = tx; landingY = ty;
        const e = ctx.enemies.find(en => en.alive && en.x === tx && en.y === ty);
        if (e) { target = e; break; }
      }
      // Telegraph the shot path with a tile marker on the landing tile —
      // small 0.25s window so it reads as "fast aim, then loose."
      import('../scene/telegraph.js').then(m => {
        m.spawnTileTelegraph(landingX, landingY, 0.25, { color: 0xffd864 });
      });
      if (player.animState) triggerSwing(player.animState);
      if (!target) {
        ctx.log('combat', 'Aimed Shot — no target in line of sight.');
        return;
      }
      // 0.30s flight delay — short enough to feel responsive, long enough
      // for the player to register the telegraph.
      setTimeout(() => {
        if (!target || !target.alive) return;
        const { dmg, maxHit } = rollPlayerSwingDetailed(player, target);
        const heavy = Math.min(maxHit * 2, Math.round(dmg * 1.5));
        const splatPos = new THREE.Vector3(target.mesh.position.x, target.mesh.position.y + 1.2, target.mesh.position.z);
        target.knockX = Math.sign(target.pos.x - player.pos.x) * 0.20;
        target.knockZ = Math.sign(target.pos.z - player.pos.z) * 0.20;
        target.hurtT = 12;
        target.hitReactT = 0.22;
        target.flashT = 0.22;
        target.aggro = true;
        if (heavy === 0) {
          spawnSplat(splatPos, '0', 'miss');
          ctx.log('combat', '🏹 Aimed Shot whiffs.');
        } else {
          target.hp -= heavy;
          spawnSplat(splatPos, heavy, 'hit');
          ctx.log('combat', `🏹 Aimed Shot ${heavy}!`);
          awardCombatXp(player, heavy, 'attacker', ctx.log, { worldPos: splatPos });
          import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
            count: 18, spread: 1.6, color: 0xffd864, size: 6, life: 0.5,
          }));
        }
        if (target.hp <= 0) {
          target.alive = false;
          target.respawn = 60 * 30;
          target.mesh.visible = false;
          ctx.log('combat', `☠ ${target.displayName || target.kind} defeated.`);
          if (target.onDeath) target.onDeath(player, ctx.log);
        }
        import('../core/sfx.js').then(m => m.sfx.hit());
        import('../core/camera.js').then(m => m.shakeCamera(0.10));
      }, 300);
    },
  },

  riposte: {
    id: 'riposte',
    name: 'Riposte',
    icon: '⚔',
    reqSkill: 'def',
    reqLevel: 22,
    cooldown: 18,
    staminaCost: 25,
    desc: 'Open a 2s parry window: the next hit you take is negated and triggers a free counter-strike.',
    run(player, ctx) {
      player.riposteT = 2.0;
      ctx.log('combat', '⚔ Riposte ready — 2s parry window.');
      const splatPos = new THREE.Vector3(player.pos.x, player.pos.y + 1.6, player.pos.z);
      import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
        count: 12, spread: 1.0, color: 0xfff2c0, size: 5, life: 0.4,
      }));
      import('../core/sfx.js').then(m => m.sfx.craft());
    },
  },

  // ---- HP tree --------------------------------------------------------
  last_stand: {
    id: 'last_stand',
    name: 'Last Stand',
    icon: '❤',
    reqSkill: 'hp',
    reqLevel: 25,
    cooldown: 60,
    staminaCost: 50,
    desc: 'Heal half the health you\'re missing. Long cooldown — save it for the brink.',
    run(player, ctx) {
      const missing = (player.hpMax || 1) - (player.hp || 0);
      if (missing <= 0) {
        ctx.log('hint', 'Last Stand — already at full HP, the cry rings hollow.');
        return;
      }
      const heal = Math.max(1, Math.floor(missing * 0.5));
      player.hp = Math.min(player.hpMax, player.hp + heal);
      ctx.log('combat', `❤ Last Stand! +${heal} HP.`);
      const splatPos = new THREE.Vector3(player.pos.x, player.pos.y + 1.5, player.pos.z);
      spawnSplat(splatPos, `+${heal}`, 'level');
      import('../core/sfx.js').then(m => m.sfx.craft());
      import('../scene/sparks.js').then(m => m.spawnHitSparks(splatPos, {
        count: 22, spread: 1.5, color: 0xfff2c0, size: 7, life: 0.7,
      }));
      import('../core/camera.js').then(m => m.fovPulse(4, 0.25));
    },
  },
};

/** Is the ability unlocked by the player's current skill levels? */
export function isAbilityUnlocked(player, abilityId) {
  const def = ABILITIES[abilityId];
  if (!def) return false;
  const skill = player.skills?.[def.reqSkill];
  if (!skill) return false;
  return skill.lv >= def.reqLevel;
}

/**
 * Try to activate the ability bound to a slot (1..4). Returns true if it
 * fired (and the cooldown was set). Returns false on any of:
 *   - empty slot
 *   - locked by skill level (and logs a hint)
 *   - on cooldown (silent — player can see the bar sweep)
 *   - player dead / mid-dodge
 *
 * `ctx` is `{ enemies, log }`.
 */
export function tryActivate(player, slot, ctx) {
  if (player.hp <= 0) return false;
  // Prefer the player's mutable action bar binding; fall back to the
  // legacy SLOT_BINDINGS for callers that don't have actionBar yet.
  const id = (player.actionBar?.[slot - 1]) || SLOT_BINDINGS[slot];
  if (!id) return false;
  // Skip if the bound id isn't actually a melee ability — magic + ranged
  // dispatch through their own paths.
  if (!ABILITIES[id]) return false;
  const def = ABILITIES[id];
  if (!def) return false;
  if (!isAbilityUnlocked(player, id)) {
    const skill = player.skills?.[def.reqSkill];
    const have = skill ? skill.lv : 0;
    ctx.log('hint', `${def.name} locked — needs ${def.reqSkill.toUpperCase()} ${def.reqLevel} (you are ${have}).`);
    return false;
  }
  // Per-action cooldown is keyed by id (so re-binding to a different
  // slot doesn't reset the cooldown). The legacy abilityCd[slot] map is
  // gone; main.js's render reads player.actionCd[id] directly.
  player.actionCd ||= {};
  if ((player.actionCd[id] || 0) > 0) return false;
  // Stamina gate — pulses the HUD on failure so the input registers.
  const cost = def.staminaCost || 0;
  if (cost > 0 && (player.stamina ?? 0) < cost) {
    player.staminaPulseT = 0.4;
    ctx.log('hint', `${def.name} needs ${cost} stamina (you have ${Math.floor(player.stamina ?? 0)}).`);
    return false;
  }
  def.run(player, ctx);
  if (cost > 0) {
    player.stamina = Math.max(0, (player.stamina ?? 0) - cost);
    // Drained the pool → mark exhausted (slower regen + slower walk).
    if (player.stamina <= 0) player.exhaustedT = Math.max(player.exhaustedT || 0, 3.0);
  }
  player.actionCd[id] = def.cooldown;
  player.actionFireT ||= {};
  player.actionFireT[id] = 0.25;
  return true;
}
