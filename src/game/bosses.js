// Spec 05 — Hedgemother phase machine + attack dispatcher.
//
// One state machine per boss enemy, stored at `enemy.bossState`. The
// machine ticks once per frame, picks an attack from the current phase's
// menu, plays a 1s telegraph (ground-decal mesh), then applies effect.
//
// Visuals (ground decals) are added to the scene as flat CircleGeometry
// meshes that fade in opacity over the telegraph duration; the dispatcher
// removes them when the hit lands.

import * as THREE from 'three';
import { HEDGEMOTHER_ATTACKS, phaseForHpFrac } from '../data/bossAttacks.js';

// Module-level: how many sprites the boss has summoned this fight.
// Capped per attack call by `dispatcher` reading current scene state.

/** Initialize state on a newly-spawned boss enemy. */
export function initBossState(enemy, kind = 'hedgemother') {
  if (!enemy) return;
  enemy.bossState = {
    kind,
    cooldowns: {},                    // attackName -> seconds remaining before next attempt
    activeTelegraph: null,            // { attackName, t, mesh, targetPos }
    initialized: false,
  };
}

/** Lazy first-tick init — fill cooldowns once we know what attacks exist. */
function _ensureCooldowns(state, attacks) {
  if (state.initialized) return;
  for (const a of attacks) {
    if (state.cooldowns[a] === undefined) {
      // Stagger initial cooldowns so the first attack lands ~1s after engagement
      state.cooldowns[a] = (a === 'thorn_sweep') ? 1.0 : (HEDGEMOTHER_ATTACKS[a]?.cooldown || 4) * 0.5;
    }
  }
  state.initialized = true;
}

/** Update a boss enemy each frame.
 *
 *  ctx = { scene, player, dt, dungeon, spawnHedgeSprite, damagePlayer, log }
 */
export function updateBoss(enemy, ctx) {
  if (!enemy || !enemy.bossState || !enemy.alive) return;
  if (enemy.bossState.kind !== 'hedgemother') return;   // future bosses go here
  const state = enemy.bossState;
  const dt = ctx.dt;

  // Phase resolution.
  const frac = Math.max(0, enemy.hp) / (enemy.hpMax || 1);
  const phaseAttacks = phaseForHpFrac(frac);
  _ensureCooldowns(state, phaseAttacks);

  // 1. Telegraph in progress?
  if (state.activeTelegraph) {
    const tg = state.activeTelegraph;
    tg.t -= dt;
    const def = HEDGEMOTHER_ATTACKS[tg.attackName];
    if (tg.mesh) {
      // ease opacity in from 0.2 → 0.65 over the telegraph
      const elapsed = (def.telegraph - Math.max(0, tg.t)) / Math.max(0.01, def.telegraph);
      tg.mesh.material.opacity = 0.2 + 0.45 * Math.min(1, elapsed);
    }
    if (tg.t <= 0) {
      _resolveAttack(enemy, tg.attackName, tg.targetPos, ctx);
      if (tg.mesh && ctx.scene) ctx.scene.remove(tg.mesh);
      state.activeTelegraph = null;
      state.cooldowns[tg.attackName] = def.cooldown;
    }
    return;
  }

  // 2. Tick cooldowns + pick a ready attack from this phase.
  for (const a of phaseAttacks) {
    if (state.cooldowns[a] > 0) state.cooldowns[a] -= dt;
  }
  // Only fire if not currently mid-hit-react (don't attack while staggered).
  if ((enemy.hitReactT || 0) > 0.3) return;

  // Pick the first ready attack with a satisfied "can-fire" precondition.
  for (const a of phaseAttacks) {
    if (state.cooldowns[a] > 0) continue;
    if (a === 'summon') {
      const cap = HEDGEMOTHER_ATTACKS.summon.effectArgs.max;
      const alive = (ctx.dungeon?.enemies || []).filter(e => e.kind === 'hedge_sprite' && e.alive).length;
      if (alive >= cap) {
        // Skip — push cooldown forward a tad so we don't re-check every frame.
        state.cooldowns[a] = 1.5;
        continue;
      }
    }
    _startTelegraph(enemy, a, ctx);
    return;
  }
}

function _startTelegraph(enemy, attackName, ctx) {
  const def = HEDGEMOTHER_ATTACKS[attackName];
  if (!def) return;
  const state = enemy.bossState;
  // Target position: thorn_sweep centred on the boss; root_stomp under the player; summon at boss.
  let target;
  if (attackName === 'root_stomp' && ctx.player) {
    target = new THREE.Vector3(ctx.player.pos.x, 0.04, ctx.player.pos.z);
  } else {
    target = new THREE.Vector3(enemy.pos.x, 0.04, enemy.pos.z);
  }

  let mesh = null;
  if (def.telegraph > 0 && ctx.scene) {
    const geo = new THREE.RingGeometry(def.radius * 0.85, def.radius, 32);
    geo.rotateX(-Math.PI / 2);
    const mat = new THREE.MeshBasicMaterial({
      color: def.decalColor || 0xaa3030,
      transparent: true,
      opacity: 0.2,
      depthWrite: false,
    });
    mesh = new THREE.Mesh(geo, mat);
    mesh.position.copy(target);
    ctx.scene.add(mesh);
  }

  state.activeTelegraph = {
    attackName,
    t: def.telegraph,
    mesh,
    targetPos: target.clone(),
  };

  // Log first occurrence of each attack so the player knows what's happening.
  if (ctx.log && !state.announced) state.announced = {};
  if (ctx.log && state.announced && !state.announced[attackName]) {
    state.announced[attackName] = true;
    const msg = attackName === 'thorn_sweep' ? 'Hedgemother winds up a thorn sweep.'
              : attackName === 'root_stomp'  ? 'Hedgemother slams the floor — roots erupt.'
              : 'Hedgemother calls — hedge-sprites tear through the bramble.';
    ctx.log('combat', msg);
  }
}

function _resolveAttack(enemy, attackName, targetPos, ctx) {
  const def = HEDGEMOTHER_ATTACKS[attackName];
  if (!def || !ctx.player) return;

  if (def.effect === 'damage') {
    // 180° forward arc (or full circle if no angle): test player distance + facing.
    const dx = ctx.player.pos.x - enemy.pos.x;
    const dz = ctx.player.pos.z - enemy.pos.z;
    const dist = Math.sqrt(dx * dx + dz * dz);
    if (dist <= def.radius) {
      // For thorn_sweep we don't check arc — boss faces the player anyway,
      // and the ring telegraph already shows the full circle. Simpler.
      if (ctx.damagePlayer) {
        ctx.damagePlayer(ctx.player, def.damage, ctx.log, 'hedgemother', { parryOnly: false });
      }
    }
  } else if (def.effect === 'root') {
    const dx = ctx.player.pos.x - targetPos.x;
    const dz = ctx.player.pos.z - targetPos.z;
    const dist = Math.sqrt(dx * dx + dz * dz);
    if (dist <= def.radius) {
      ctx.player.rootedT = Math.max(ctx.player.rootedT || 0, def.effectArgs.duration);
      if (ctx.log) ctx.log('combat', 'Roots seize your feet!');
    }
  } else if (def.effect === 'summon') {
    if (!ctx.spawnHedgeSprite) return;
    const count = def.effectArgs.count;
    const cap = def.effectArgs.max;
    const alreadyAlive = (ctx.dungeon?.enemies || []).filter(e => e.kind === 'hedge_sprite' && e.alive).length;
    const room = Math.max(0, cap - alreadyAlive);
    const toSpawn = Math.min(count, room);
    for (let i = 0; i < toSpawn; i++) {
      const angle = (i / Math.max(1, toSpawn)) * Math.PI * 2 + Math.random() * 0.3;
      const r = 1.6;
      const sx = Math.floor(enemy.pos.x + Math.cos(angle) * r);
      const sy = Math.floor(enemy.pos.z + Math.sin(angle) * r);
      const sprite = ctx.spawnHedgeSprite(sx, sy, ctx.scene);
      if (!sprite) continue;
      sprite.aggro = true;
      if (ctx.dungeon) {
        ctx.dungeon.enemies.push(sprite);
      }
      if (ctx.allEnemies) ctx.allEnemies.push(sprite);
    }
  }
}

/** Tear-down — call on boss death or dungeon exit. Cleans up any lingering decal. */
export function disposeBoss(enemy, scene) {
  if (!enemy?.bossState) return;
  const tg = enemy.bossState.activeTelegraph;
  if (tg?.mesh && scene) scene.remove(tg.mesh);
  enemy.bossState = null;
}

/** Seal the boss room: place a wall mesh on every doorway tile (an outside
 *  corridor cell adjacent to the room) and stash the room rect on
 *  `dungeon.bossSeal` so movement code can block exits from the rect.
 *  Pure additive — does not mutate the layout grid. */
export function sealBossRoom(dungeon, scene, layout, bossRoom) {
  if (!dungeon || !scene || !layout || !bossRoom) return;
  const grid = layout.grid;
  if (!grid) return;
  const meshes = [];
  const doorways = [];
  const r = bossRoom;
  const checkAndSeal = (cx, cy) => {
    if (cy < 0 || cy >= grid.length) return;
    if (cx < 0 || cx >= grid[0].length) return;
    if (grid[cy][cx] !== 'floor') return;
    // Skip cells already inside the bossRoom (we only want exit cells).
    if (cx >= r.x && cx < r.x + r.w && cy >= r.y && cy < r.y + r.h) return;
    doorways.push({ x: cx, y: cy });
    const stoneMat = new THREE.MeshStandardMaterial({
      color: 0x4a3a36, roughness: 0.9, metalness: 0.05,
    });
    const block = new THREE.Mesh(new THREE.BoxGeometry(1.0, 2.0, 1.0), stoneMat);
    block.position.set(cx + 0.5, 1.0, cy + 0.5);
    block.userData.bossSealMesh = true;
    scene.add(block);
    meshes.push(block);
  };
  // Walk the rect's perimeter; for each room-edge tile, check the OUTSIDE
  // neighbor in the cardinal direction the edge faces.
  for (let xx = r.x; xx < r.x + r.w; xx++) {
    checkAndSeal(xx, r.y - 1);          // top
    checkAndSeal(xx, r.y + r.h);        // bottom
  }
  for (let yy = r.y; yy < r.y + r.h; yy++) {
    checkAndSeal(r.x - 1, yy);          // left
    checkAndSeal(r.x + r.w, yy);        // right
  }
  dungeon.bossSeal = {
    active: true,
    room: { x: r.x, y: r.y, w: r.w, h: r.h },
    meshes,
    doorways,
  };
}

/** Lift the seal: remove wall meshes and clear the rect.
 *  Call on boss death. */
export function unsealBossRoom(dungeon, scene) {
  if (!dungeon?.bossSeal) return;
  for (const m of dungeon.bossSeal.meshes || []) {
    if (m && scene) scene.remove(m);
  }
  dungeon.bossSeal = null;
}

/** Movement-time check. Returns true if (fromX,fromY) → (toX,toY) would
 *  cross a boss seal (exit a sealed room). */
export function isSealBlocked(dungeon, fromX, fromY, toX, toY) {
  const seal = dungeon?.bossSeal;
  if (!seal || !seal.active) return false;
  const r = seal.room;
  const fromIn = fromX >= r.x && fromX < r.x + r.w && fromY >= r.y && fromY < r.y + r.h;
  const toIn   = toX   >= r.x && toX   < r.x + r.w && toY   >= r.y && toY   < r.y + r.h;
  return fromIn && !toIn;
}
