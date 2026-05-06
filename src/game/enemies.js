// Cows — 3D meshes + grid AI. Idle wander; aggro on player swing; melee adjacent.
import * as THREE from 'three';
import { spawnFloat } from '../core/floaters.js';

// ---------------------------------------------------------------------------
// Hades-style attack-token cap. The room has a global pool of windup tokens;
// non-boss enemies must claim one before starting a wind-up. Without this,
// 5+ enemies in a room all wind up simultaneously and the screen turns into
// soup; with it, fights read as choreographed because only N enemies are
// "swinging" at any moment. Bosses bypass the cap — their attacks are
// always essential and never gated. See AI research notes (Hades / Halo
// clump system).
let _activeWindups = 0;
const MAX_WINDUPS = 2;
export function takeWindupToken(e) {
  if (e.isBoss) return true;
  if (_activeWindups >= MAX_WINDUPS) return false;
  _activeWindups++;
  e._holdsWindupToken = true;
  return true;
}
export function releaseWindupToken(e) {
  if (!e._holdsWindupToken) return;
  e._holdsWindupToken = false;
  _activeWindups = Math.max(0, _activeWindups - 1);
}
export function getActiveWindups() { return _activeWindups; }
// Window-level reset (used when entering / leaving a dungeon to avoid
// dangling tokens from interrupted setTimeouts).
export function resetWindupTokens() { _activeWindups = 0; }

/** Cancel an enemy's queued attack and put them in a brief stagger.
 *  Returns true if there was an attack to interrupt. Bosses ignore the
 *  interrupt — their windups are non-cancellable so the fight stays
 *  threatening even with full combo flow. */
export function interruptEnemy(e) {
  if (!e || !e.alive) return false;
  if (e.isBoss) return false;
  if (!e.queuedHit) return false;
  clearTimeout(e.queuedHit);
  e.queuedHit = null;
  releaseWindupToken(e);
  e.staggered = true;
  e.attackCd = 110;            // long recovery — about 1.8s
  e.attackAnimT = 0;
  e.flashT = 0.30;
  setTimeout(() => { e.staggered = false; }, 600);
  return true;
}

// Subtitle line shown under boss intro banners. Tied to enemy.kind so we
// don't have to thread a string through every spawn factory.
function bossSubtitle(e) {
  switch (e.kind) {
    case 'goblin': return 'Crowned in Bramble';
    case 'wolf':   return 'Pack-Leader of the Wolds';
    case 'boar':   return 'Of the Burrowed Earth';
    default:       return '';
  }
}
import { buildCowMesh, buildGoblinMesh, buildChickenMesh, buildHareMesh, buildBoarMesh, buildHedgewightMesh, buildBurrowBoarMesh, buildWolfAlphaMesh, buildHedgemotherMesh, buildFalconMesh, buildSkitterlingMesh, buildMarshRatMesh, buildIronGobMesh, buildTuskerSowMesh, buildBrambleArcherMesh, buildBrambleChargerMesh, buildEnemyHealthBar, buildBacksideArrow, varyInstance } from '../scene/characters.js';
import { rollEnemySwing, damagePlayer } from './combat.js';
import { spawnGroundLoot } from './groundLoot.js';
import { rollMobDrop } from '../data/lootTables.js';

/**
 * Drop helper — emits ground-loot at an enemy's tile. Items with
 * `chance < 1` only roll if random < chance.
 */
function dropAt(enemy, scene, drops) {
  const pos = new THREE.Vector3(enemy.x + 0.5, 0.4, enemy.y + 0.5);
  for (const d of drops) {
    if (d.chance != null && Math.random() >= d.chance) continue;
    spawnGroundLoot(scene, pos, d.id, d.qty || 1);
  }
}

const FACING_ANGLE = {
  down: 0, up: Math.PI, right: Math.PI / 2, left: -Math.PI / 2,
};

function manhattan(a, b) { return Math.abs(a.x - b.x) + Math.abs(a.y - b.y); }

/** Bresenham-style line-of-sight check between two tiles. Returns true if
 *  every intermediate cell (excluding both endpoints) is walkable per the
 *  isBlocked predicate. Used by the archer retreat AI to find tiles that
 *  break LOS to the player. */
function losClear(fromX, fromY, toX, toY, isBlocked) {
  const dx = Math.abs(toX - fromX);
  const dy = Math.abs(toY - fromY);
  const sx = fromX < toX ? 1 : -1;
  const sy = fromY < toY ? 1 : -1;
  let err = dx - dy;
  let x = fromX, y = fromY;
  let safety = 32;
  while (safety-- > 0) {
    const e2 = 2 * err;
    if (e2 > -dy) { err -= dy; x += sx; }
    if (e2 <  dx) { err += dx; y += sy; }
    if (x === toX && y === toY) return true;
    if (isBlocked(x, y, null)) return false;
  }
  return true;
}

export function spawnGoblin(x, y, scene) {
  const mesh = buildGoblinMesh();
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);                       // scene-space so squash doesn't warp it
  return {
    kind: 'goblin',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.28,
    dir: 'down',
    hp: 6, hpMax: 6,
    atkLv: 2, defLv: 1, maxHit: 1,
    alive: true, aggro: false,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    aggroRadius: 4,
    hpBar,
    // hit-react / attack-anim state — durations in seconds
    hitReactT: 0,
    attackAnimT: 0,
    knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('bramble_imp'));
      log('combat', '+ Bramble-imp slain.');
    },
  };
}

export function spawnCow(x, y, scene) {
  const mesh = buildCowMesh();
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'cow',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false,
    moveT: 0,
    moveDur: 0.30,
    dir: 'down',
    hp: 8, hpMax: 8,
    atkLv: 1, defLv: 1, maxHit: 1,
    alive: true,
    aggro: false,
    hurtT: 0,
    attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    hpBar,
    hitReactT: 0,
    attackAnimT: 0,
    knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('brindlecow'));
      log('combat', '+ Brindlecow slain.');
      if (player.quest) player.quest.cowKilled++;
    },
  };
}

// Chicken — passive farmstead critter. Wanders, drops raw_pippin + downfeather.
export function spawnChicken(x, y, scene) {
  const mesh = buildChickenMesh();
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'chicken',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.22,
    dir: 'down',
    hp: 2, hpMax: 2,
    atkLv: 1, defLv: 1, maxHit: 0,
    alive: true, aggro: false,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('pippin'));
      log('combat', '+ Pippin caught.');
    },
  };
}

// Hare — fast passive critter. Drops raw_whicker + whicker_pelt.
export function spawnHare(x, y, scene) {
  const mesh = buildHareMesh();
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'hare',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.18,
    dir: 'down',
    hp: 3, hpMax: 3,
    atkLv: 1, defLv: 2, maxHit: 0,
    alive: true, aggro: false,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      const drops = rollMobDrop('whickerhare');
      // Withering's quest target — only drops while the quest is open.
      if (player?.quest?.flags?.witheringAccepted &&
          !player?.quest?.flags?.witheringFinished &&
          Math.random() < 0.45) {
        drops.push({ id: 'whickerhares_foot', qty: 1 });
      }
      dropAt({ x, y }, scene, drops);
      log('combat', '+ Whickerhare caught.');
    },
  };
}

// Wild boar — Medium-tier hostile (Iron-tier player level). Aggressive when
// approached. Drops raw_tusker always, tusker_tusk often, bogiron_ore rarely (a
// player on a long walk might find one). HP/atk/def per skill's tier table:
// Medium = HP 25-60, atk 6-10, def 4-6, maxHit 3.
export function spawnBoar(x, y, scene) {
  const mesh = buildBoarMesh();
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'boar',
    displayName: 'Wild Boar',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.26,
    dir: 'down',
    hp: 28, hpMax: 28,
    atkLv: 7, defLv: 5, maxHit: 3,
    alive: true, aggro: false,
    aggroRadius: 4,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('tuskersnout'));
      log('combat', '+ Tuskersnout slain.');
    },
  };
}

// Hedge wolf — Hard-tier predator that hunts the Bramblewolds at dusk.
// Uses the boar mesh as a placeholder, retinted cool grey + slightly
// elongated. A real wolf.glb should replace this in a follow-up build.
// Stats per skill's Hard-tier table: HP 60-180, atk 12-20, def 8-12, maxHit 5.
export function spawnHedgeWolf(x, y, scene) {
  // Real hedgewight GLB; per-instance tint applied inside the builder.
  const mesh = buildHedgewightMesh();
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'wolf',
    displayName: 'Hedge Wolf',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.20,
    dir: 'down',
    hp: 80, hpMax: 80,
    atkLv: 14, defLv: 9, maxHit: 5,
    alive: true, aggro: false,
    aggroRadius: 6,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('hedgewight_overworld'));
      log('combat', '+ Hedgewight slain.');
    },
  };
}

// Bramble-cap — mid-tier bramble-imp. Same goblin model with hue/scale
// shift so it reads as a bigger, mossier cousin. Drops thorn_essence.
// HEDGEMOTHER — Boss-tier matriarch bramble-imp. Slow but punishing.
// Boss-tier per skill table: HP 200-400, atk 22-32, def 14-20, maxHit 7.
// Drops: thorn_essence ×3 always, mother_tooth (boss specimen) 80%,
// guaranteed iron-tier gear, 30% steel-tier gear, big coin pile.
// Spawned by the dungeon generator when a "Hedgemother's Den" affix is
// active on the chart (post-V1 affix wiring).
export function spawnHedgemother(x, y, scene) {
  const mesh = buildHedgemotherMesh();
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'goblin',                 // engine kind keeps it on the goblin AI/anim hooks
    displayName: 'Hedgemother',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.50,   // slow, deliberate
    dir: 'down',
    hp: 220, hpMax: 220,
    atkLv: 22, defLv: 16, maxHit: 7,
    alive: true, aggro: false,
    aggroRadius: 7,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    isBoss: true,                   // for any future per-boss FX hooks
    parryOnly: true,                // her thorn-slam is RED — Riposte only
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('hedgemother'));
      log('quest', '★ The Hedgemother falls. The brambles around you slacken.');
    },
  };
}

/** Burrow Boar — Hard-tier boss boar. Heavier than the Hedgemother on
 *  raw HP/atk but slower and more open to kiting. Triggered by the
 *  burrow_boar_den affix on a chart, or as a standalone Bramblewolds
 *  encounter. */
export function spawnBurrowBoar(x, y, scene) {
  const mesh = buildBurrowBoarMesh();
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'boar',
    displayName: 'Burrow Boar',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.42,
    dir: 'down',
    hp: 280, hpMax: 280,
    atkLv: 24, defLv: 14, maxHit: 8,
    alive: true, aggro: false,
    aggroRadius: 6,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    isBoss: true,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('burrow_boar'));
      log('quest', '★ The Burrow Boar topples. The earth quiets.');
    },
  };
}

/** Wolf Alpha — boss-tier hedgewight pack leader. Faster than the
 *  Burrow Boar, hits a little less hard, glowing-blue eyes by night. */
export function spawnWolfAlpha(x, y, scene) {
  const mesh = buildWolfAlphaMesh();
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'wolf',
    displayName: 'Wolf Alpha',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.30,
    dir: 'down',
    hp: 240, hpMax: 240,
    atkLv: 26, defLv: 12, maxHit: 7,
    alive: true, aggro: false,
    aggroRadius: 8,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    isBoss: true,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('wolf_alpha'));
      log('quest', '★ The Wolf Alpha falls. The pack scatters into the brambles.');
    },
  };
}

export function spawnBrambleCap(x, y, scene) {
  const mesh = buildGoblinMesh();
  // post-process the GLB clone: bigger + mossier-green skin + larger club
  mesh.scale.multiplyScalar(1.30);
  if (mesh.children[0]) {
    varyInstance(mesh.children[0], {
      scaleJitter: 0,
      tintTargets: ['Skin', 'SkinDark', 'SkinLight'],
      hueShift: () => 0.04,    // shift toward yellow-green
      satScale: () => 1.20,
      lumOffset:() => -0.06,   // darker
    });
  }
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'goblin',         // engine kind stays 'goblin' so AI/anim hooks work
    displayName: 'Bramble-cap',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh,
    targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.30,
    dir: 'down',
    hp: 12, hpMax: 12,
    atkLv: 4, defLv: 3, maxHit: 2,
    alive: true, aggro: false,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0,
    aggroRadius: 5,
    hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('bramble_cap'));
      log('combat', '+ Bramble-cap slain.');
    },
  };
}

// ---------------------------------------------------------------------------
// Variant spawns — same GLBs, retuned stats + tinted materials. These give
// the dungeon spawn tables more flavor without authoring new meshes.
// ---------------------------------------------------------------------------

/** Skitterling — small thorn-fae. Uses goblin GLB at 0.7× scale, dark green tint.
 *  Trivial-tier swarm enemy. Drops a sliver of thorn essence. */
export function spawnSkitterling(x, y, scene) {
  const mesh = buildSkitterlingMesh() || buildGoblinMesh();
  if (mesh.userData.glbKey !== 'skitterling') {
    mesh.scale.multiplyScalar(0.70);
    if (mesh.children[0]) {
      varyInstance(mesh.children[0], {
        scaleJitter: 0, tintTargets: ['Skin', 'SkinDark', 'SkinLight'],
        hueShift: () => 0.06, satScale: () => 1.10, lumOffset: () => -0.10,
      });
    }
  }
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'goblin', displayName: 'Skitterling',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh, targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.18,    // fast
    dir: 'down',
    hp: 4, hpMax: 4,
    atkLv: 2, defLv: 1, maxHit: 1,
    alive: true, aggro: false,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0, aggroRadius: 3, hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('skitterling'));
      log('combat', '+ Skitterling slain.');
    },
  };
}

/** Marsh Rat — soggy hare variant. Faster than the wild hare, hits harder.
 *  Easy-tier swarm enemy. Drops marsh-flavored bits. */
export function spawnMarshRat(x, y, scene) {
  const mesh = buildMarshRatMesh() || buildHareMesh();
  if (mesh.userData.glbKey !== 'marshRat' && mesh.children[0]) {
    varyInstance(mesh.children[0], {
      scaleJitter: 0, tintTargets: ['HareTan', 'HareLight', 'HareShadow'],
      hueShift: () => -0.08, satScale: () => 0.6, lumOffset: () => -0.18,
    });
  }
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'hare', displayName: 'Marsh Rat',
    behavior: 'kiter', kiterRetreat: 0,
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh, targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.16,    // very fast
    dir: 'down',
    hp: 8, hpMax: 8,
    atkLv: 4, defLv: 2, maxHit: 2,
    alive: true, aggro: false,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0, aggroRadius: 4, hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('marsh_rat'));
      log('combat', '+ Marsh rat slain.');
    },
  };
}

/** Iron Gob — armored goblin variant. Slower, more HP, hits harder.
 *  Medium-tier blocker. */
export function spawnIronGob(x, y, scene) {
  const mesh = buildIronGobMesh() || buildGoblinMesh();
  if (mesh.userData.glbKey !== 'ironGob') {
    mesh.scale.multiplyScalar(1.05);
    if (mesh.children[0]) {
      varyInstance(mesh.children[0], {
        scaleJitter: 0, tintTargets: ['Skin', 'SkinDark', 'SkinLight'],
        hueShift: () => -0.20, satScale: () => 0.6, lumOffset: () => -0.20,
      });
    }
  }
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'goblin', displayName: 'Iron Gob',
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh, targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.34,    // slower
    dir: 'down',
    hp: 28, hpMax: 28,
    atkLv: 7, defLv: 6, maxHit: 3,
    alive: true, aggro: false,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0, aggroRadius: 5, hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('iron_gob'));
      log('combat', '+ Iron Gob slain.');
    },
  };
}

/** Archer — ranged enemy. Uses falcon mesh, fires at 3-6 tile range, retreats
 *  if player closes inside 3 tiles. Telegraphs shots with a 0.6s wind-up so
 *  the player can step off the marked tile or dodge through. Easy tier. */
export function spawnArcher(x, y, scene) {
  const mesh = buildBrambleArcherMesh() || buildFalconMesh();
  if (mesh.userData.glbKey !== 'brambleArcher') {
    mesh.scale.multiplyScalar(1.3);  // slightly bigger than perch falcon for readability
  }
  mesh.position.set(x + 0.5, 0.4, y + 0.5);   // perched on a slight rise
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'archer', displayName: 'Bramble Archer',
    behavior: 'ranged',          // <-- triggers the ranged AI branch
    attackRange: 6,              // fires at up to 6 tiles
    minRange: 3,                 // retreats if closer than this
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh, targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.22,
    dir: 'down',
    hp: 14, hpMax: 14,
    atkLv: 6, defLv: 2, maxHit: 3,
    alive: true, aggro: false,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0, aggroRadius: 8, hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('bramble_archer'));
      log('combat', '+ Bramble archer slain.');
    },
  };
}

/** Charger — line-dash boar variant. Uses boar mesh, tinted dark + scaled
 *  larger. Charges along axis-aligned lines when the player gets in front,
 *  forcing a sidestep instead of a back-pedal. */
export function spawnCharger(x, y, scene) {
  const mesh = buildBrambleChargerMesh() || buildBoarMesh();
  if (mesh.userData.glbKey !== 'brambleCharger') {
    mesh.scale.multiplyScalar(1.05);
    if (mesh.children[0]) {
      varyInstance(mesh.children[0], {
        scaleJitter: 0,
        tintTargets: ['BoarDark', 'BoarMid', 'BoarLight'],
        hueShift: () => -0.06,
        satScale: () => 1.35,
        lumOffset: () => -0.18,
      });
    }
  }
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'boar', displayName: 'Bramble Charger',
    behavior: 'charger', chargeRange: 5,
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh, targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.26,
    dir: 'down',
    hp: 36, hpMax: 36,
    atkLv: 10, defLv: 5, maxHit: 5,                // bigger hits than regular boar
    alive: true, aggro: false,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0, aggroRadius: 7, hpBar,            // sees you from far so it can line up
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('bramble_charger'));
      log('combat', '+ Bramble charger slain.');
    },
  };
}

/** Target Dummy — training-arena enemy. Very high HP that regenerates,
 *  no aggro, no attacks, no movement. Tagged so the main loop's HP
 *  regen tick can refill it. Reuses the goblin mesh tinted cool grey to
 *  read distinctly from real goblins. */
export function spawnTargetDummy(x, y, scene) {
  const mesh = buildGoblinMesh();
  if (mesh.children[0]) {
    varyInstance(mesh.children[0], {
      scaleJitter: 0,
      tintTargets: ['Skin', 'SkinDark', 'SkinLight'],
      hueShift: () => -0.40,    // away from green, toward cool grey
      satScale: () => 0.10,
      lumOffset: () => 0.10,
    });
  }
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'goblin', displayName: 'Training Dummy',
    isTargetDummy: true,                       // main loop reads this for HP regen
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh, targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.3,
    dir: 'down',
    hp: 500, hpMax: 500,                       // high enough that crits show big numbers
    atkLv: 0, defLv: 5, maxHit: 0,             // can't attack
    alive: true, aggro: false,
    hurtT: 0, attackCd: 99999,                 // never swings
    moveTimer: 0, respawn: 0, aggroRadius: 0,  // never aggros
    hpBar, hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      // Should never fire (HP regenerates faster than typical damage),
      // but if it does, just respawn instantly.
      log('hint', '[dummy] Defeated — respawning...');
    },
  };
}

/** Tusker Sow — bigger boar. Slow, very high HP, big crits. Hard tier. */
export function spawnTuskerSow(x, y, scene) {
  const mesh = buildTuskerSowMesh() || buildBoarMesh();
  if (mesh.userData.glbKey !== 'tuskerSow') {
    mesh.scale.multiplyScalar(1.20);
    if (mesh.children[0]) {
      varyInstance(mesh.children[0], {
        scaleJitter: 0, tintTargets: ['BoarDark', 'BoarMid', 'BoarLight'],
        hueShift: () => -0.04, satScale: () => 1.10, lumOffset: () => -0.10,
      });
    }
  }
  mesh.position.set(x + 0.5, 0, y + 0.5);
  scene.add(mesh);
  const hpBar = buildEnemyHealthBar();
  scene.add(hpBar);
  return {
    kind: 'boar', displayName: 'Tusker Sow',
    slam: true,                                // 3×3 telegraphed AoE
    x, y, homeX: x, homeY: y,
    pos: new THREE.Vector3(x + 0.5, 0, y + 0.5),
    mesh, targetX: x, targetY: y,
    moving: false, moveT: 0, moveDur: 0.32,
    dir: 'down',
    hp: 70, hpMax: 70,
    atkLv: 12, defLv: 8, maxHit: 4,
    alive: true, aggro: false,
    hurtT: 0, attackCd: 0,
    moveTimer: Math.floor(Math.random() * 60),
    respawn: 0, aggroRadius: 5, hpBar,
    hitReactT: 0, attackAnimT: 0, knockX: 0, knockZ: 0,
    onDeath: (player, log) => {
      dropAt({ x, y }, scene, rollMobDrop('tusker_sow'));
      log('combat', '+ Tusker Sow slain.');
    },
  };
}

// Kinds that never vocalize, even if they ever aggro. Cows/chickens are
// peaceful by design; if either is ever flagged hostile by a quirk of
// state, we still don't want them growling.
const _SILENT_KINDS = new Set(['cow', 'chicken']);

// ---------- Bramble-pull helpers (Hedgemother phase-2 mechanic) ----------

/** 2D point-to-segment distance on the X/Z plane. Returns true if (px,pz)
 *  lies within `tol` tiles of the line segment (ax,az)→(bx,bz). Used by
 *  the bramble-pull resolution to check if the player has stepped off
 *  the telegraphed vine line during the windup. */
function _pointNearLine(px, pz, ax, az, bx, bz, tol) {
  const dx = bx - ax, dz = bz - az;
  const len2 = dx * dx + dz * dz;
  if (len2 < 1e-6) {
    // Degenerate: line is a single point.
    const ddx = px - ax, ddz = pz - az;
    return ddx * ddx + ddz * ddz <= tol * tol;
  }
  let t = ((px - ax) * dx + (pz - az) * dz) / len2;
  t = Math.max(0, Math.min(1, t));      // clamp to segment
  const cx = ax + t * dx, cz = az + t * dz;
  const ex = px - cx, ez = pz - cz;
  return ex * ex + ez * ez <= tol * tol;
}

/** Step the player N tiles toward the boss along their cardinal-snapped
 *  vector. Stops short if blocked. Mutates player.x/y/pos and the mesh.
 *  Used by the bramble-pull resolution. */
function _pullPlayerToward(player, boss, tiles, isBlocked) {
  const dx = boss.x - player.x, dy = boss.y - player.y;
  const stepX = Math.abs(dx) >= Math.abs(dy) ? Math.sign(dx) : 0;
  const stepY = Math.abs(dy) > Math.abs(dx) ? Math.sign(dy) : 0;
  if (stepX === 0 && stepY === 0) return;
  for (let i = 0; i < tiles; i++) {
    const nx = player.x + stepX, ny = player.y + stepY;
    if (isBlocked(nx, ny, null)) break;       // wall — pull as far as possible
    if (Math.abs(nx - boss.x) + Math.abs(ny - boss.y) === 0) break;   // adjacent already
    player.x = nx; player.y = ny;
  }
  // Snap mesh + path state so the player visibly arrives at the new tile.
  player.targetX = player.x; player.targetY = player.y;
  player.path = [];
  player.onPathDone = null;
  player.moving = false;
  player.moveT = 0;
  player.pos.x = player.x + 0.5;
  player.pos.z = player.y + 0.5;
}

export function updateEnemy(e, player, isBlocked, log, dt) {
  if (!e.alive) {
    e.respawn--;
    if (e.respawn <= 0) {
      if (!isBlocked(e.homeX, e.homeY, e)) {
        e.x = e.homeX; e.y = e.homeY;
        e.pos.set(e.x + 0.5, 0, e.y + 0.5);
        e.mesh.position.copy(e.pos);
        e.mesh.visible = true;
        e.hp = e.hpMax;
        e.alive = true;
        e.aggro = false;
        e.hurtT = 0;
      }
    }
    return;
  }

  // ---- idle vocalizations ----
  // When aggro + nearby + not in mid-attack-windup, periodically growl.
  // Loaded lazily so the import cost is paid at most once per session.
  // Skipped for bosses (they have their own audio cues) and silent kinds.
  if (e.aggro && !e.isBoss && !_SILENT_KINDS.has(e.kind)) {
    const dx = player.pos.x - e.pos.x;
    const dz = player.pos.z - e.pos.z;
    const dist2 = dx * dx + dz * dz;
    if (dist2 < 100) {                          // 10-tile radius
      if (e._vocT === undefined) e._vocT = 2 + Math.random() * 4;
      e._vocT -= dt;
      if (e._vocT <= 0) {
        import('../core/sfx.js').then(m => m.sfx.growl()).catch(() => {});
        e._vocT = 4 + Math.random() * 4;        // 4-8s random next
      }
    }
  }

  // Lazy-attach the backside arrow once. Skips ranged enemies (perched
  // birds make the ground arrow look weird) and passive cows/chickens
  // (no point — you can't backstab them in any meaningful sense).
  if (!e.mesh.userData._backsideArrow) {
    const skipKinds = new Set(['cow', 'chicken', 'archer']);
    if (!skipKinds.has(e.kind)) {
      const arrow = buildBacksideArrow();
      e.mesh.add(arrow);
      e.mesh.userData._backsideArrow = arrow;
    } else {
      e.mesh.userData._backsideArrow = true;   // sentinel to skip retry
    }
  }

  if (e.hurtT > 0) e.hurtT--;
  if (e.attackCd > 0) e.attackCd--;
  if (e.kiterStunT > 0) e.kiterStunT = Math.max(0, e.kiterStunT - dt);
  // Boss soft-enrage timer. Each frame an aggroed boss spends in combat,
  // tick _enrageT. At 120s, trigger enrage: an extra 0.85 multiplier on
  // attackCdScale (stacks with phase 2's 0.7 → ~40% faster than baseline).
  // No damage change — pure tempo pressure to defeat turtle strategies.
  if (e.isBoss && e.aggro && !e.enraged) {
    e._enrageT = (e._enrageT || 0) + dt;
    if (e._enrageT >= 120) {
      e.enraged = true;
      e.attackCdScale = (e.attackCdScale || 1.0) * 0.85;
      log('combat', `★ ${e.displayName || 'Boss'} grows frenzied — windups quicken.`);
      const wp = new THREE.Vector3(e.mesh.position.x, e.mesh.position.y + 1.0, e.mesh.position.z);
      import('../scene/sparks.js').then(m => m.spawnHitSparks(wp, {
        count: 24, spread: 2.0, color: 0xff3030, size: 7, life: 0.8,
      }));
    }
  }

  // Boss phase-2 transition. When HP drops to 50%, lock the boss for ~1s
  // for a transition pose, emit sparks, and flip e.phase = 2. Phase 2
  // boss has shorter attackCd (faster windups) and alternates attacks.
  if (e.isBoss && !e.phase2Triggered && e.hp > 0 && e.hp <= e.hpMax * 0.5) {
    e.phase2Triggered = true;
    e.phase = 2;
    e.staggered = true;          // freeze for 1s
    e.attackCd = 60;             // 1s of recovery, no attack window
    e.flashT = 1.0;              // big bright flash so the transition reads
    e.attackCdScale = 0.7;       // future strikes spawn with shorter CD
    setTimeout(() => { if (e) e.staggered = false; }, 1000);
    log('combat', `★ ${e.displayName || 'Boss'} blooms wider — phase 2.`);
    // Spark burst at boss tile to telegraph the change
    const wp = new THREE.Vector3(e.mesh.position.x, e.mesh.position.y + 1.0, e.mesh.position.z);
    import('../scene/sparks.js').then(m => m.spawnHitSparks(wp, {
      count: 32, spread: 2.4, color: 0xff5050, size: 8, life: 0.9,
    }));
  }
  // Training dummy — fast HP regen + force aggro=false so it never
  // chases or swings. ~8 HP/sec; capped at hpMax.
  if (e.isTargetDummy) {
    e._regenAccum = (e._regenAccum || 0) + dt;
    while (e._regenAccum >= 0.125) {           // 8 ticks/sec
      e._regenAccum -= 0.125;
      if (e.hp < e.hpMax) e.hp = Math.min(e.hpMax, e.hp + 1);
    }
    e.aggro = false;
    e.moving = false;
    e.attackCd = 99999;                        // prevent any windup
  }
  // Frenzied affix — at <30% HP, attack cooldown ticks twice as fast.
  if (e.frenzied && e.attackCd > 0 && e.hp / (e.hpMax || 1) < 0.30) e.attackCd--;

  // ---- bleed / DoT tick ----
  // e.bleed = { dmg, tickT, ticksLeft }. Applied externally by abilities
  // (Rend) or future status effects. Resolves once per second; floats a
  // small red number above the enemy so the DoT reads.
  if (e.bleed && e.bleed.ticksLeft > 0) {
    e.bleed.tickT -= dt;
    if (e.bleed.tickT <= 0) {
      e.bleed.tickT += 1.0;
      e.bleed.ticksLeft--;
      const dmg = e.bleed.dmg;
      if (dmg > 0 && e.alive) {
        e.hp -= dmg;
        e.flashT = 0.12;
        const pos = e.mesh.position;
        const wp = new THREE.Vector3(pos.x, pos.y + 1.2, pos.z);
        spawnFloat(wp, `-${dmg}`, 'hit');
        if (e.hp <= 0) {
          e.alive = false;
          e.respawn = 60 * 30;
          e.mesh.visible = false;
          log('combat', `☠ ${e.displayName || (e.kind === 'goblin' ? 'Bramble-imp' : e.kind)} bleeds out.`);
          if (e.onDeath) e.onDeath(player, log);
        }
      }
      if (e.bleed.ticksLeft <= 0) e.bleed = null;
    }
  }

  // smooth tween for movement
  if (e.moving) {
    e.moveT += dt;
    const u = Math.min(1, e.moveT / e.moveDur);
    const fromX = e.x + 0.5, fromY = e.y + 0.5;
    const toX = e.targetX + 0.5, toY = e.targetY + 0.5;
    e.pos.x = fromX + (toX - fromX) * u;
    e.pos.z = fromY + (toY - fromY) * u;
    e.mesh.position.copy(e.pos);
    if (u >= 1) {
      e.x = e.targetX;
      e.y = e.targetY;
      e.moving = false;
      e.moveT = 0;
    }
    return;
  }

  // facing-direction rotation — exponential lerp so big direction
  // changes feel responsive without snapping. Bigger constant = faster
  // turn; we bump from 8 → 12 with a small bias for sharper deltas.
  //
  // Combat override: aggro'd enemies face the player directly (continuous
  // angle, computed each frame from the dx/dz delta) rather than snapping
  // to whichever cardinal direction they last walked. Reads correct when
  // they're standing adjacent and swinging, not just when actively moving.
  let targetA;
  if (e.aggro && player) {
    const dx = player.pos.x - e.pos.x;
    const dz = player.pos.z - e.pos.z;
    if (dx * dx + dz * dz > 1e-6) {
      // three.js convention: rotation.y = 0 faces -Z; positive Y rotates
      // toward +X. atan2(dx, -dz) gives the bearing from (0,0)→(dx,dz)
      // measured from -Z toward +X, which is exactly rotation.y.
      targetA = Math.atan2(dx, -dz);
    } else {
      targetA = FACING_ANGLE[e.dir];
    }
  } else {
    targetA = FACING_ANGLE[e.dir];
  }
  const cur = e.mesh.rotation.y;
  let delta = ((targetA - cur + Math.PI) % (Math.PI * 2)) - Math.PI;
  if (delta < -Math.PI) delta += Math.PI * 2;
  // larger absolute deltas (e.g. 180° flip) get a slight speed boost
  const sharpness = Math.min(1, Math.abs(delta) / Math.PI);
  const k = 1 - Math.exp(-dt * (12 + sharpness * 8));
  e.mesh.rotation.y = cur + delta * k;

  // ---- hit-react + attack-anim offsets ----
  if (e.hitReactT > 0)   e.hitReactT  = Math.max(0, e.hitReactT  - dt);
  if (e.attackAnimT > 0) e.attackAnimT = Math.max(0, e.attackAnimT - dt);

  // ---- material flash ----
  // Briefly brighten the enemy's emissive when struck so a hit reads
  // even if the splat number is missed. Materials are cached lazily on
  // first flash; restored to their original emissive once the flash
  // window expires so the toon shading stays clean.
  if (e.flashT !== undefined) {
    if (e.flashT > 0) {
      e.flashT = Math.max(0, e.flashT - dt);
      if (!e.mesh.userData._flashMats) {
        const mats = [];
        e.mesh.traverse(o => {
          if (o.isMesh) {
            const list = Array.isArray(o.material) ? o.material : [o.material];
            for (const m of list) {
              if (m && m.emissive) mats.push({ m, base: m.emissive.clone() });
            }
          }
        });
        e.mesh.userData._flashMats = mats;
      }
      const mats = e.mesh.userData._flashMats;
      const u = e.flashT / 0.18;             // 1 → 0
      const k = Math.sin(u * Math.PI);       // 0 → 1 → 0
      for (const { m, base } of mats) {
        m.emissive.setRGB(base.r + k * 0.9, base.g + k * 0.9, base.b + k * 0.9);
      }
      if (e.flashT === 0) {
        for (const { m, base } of mats) m.emissive.copy(base);
      }
    }
  }

  let offX = 0, offZ = 0, offY = 0;
  let scaleY = 1, scaleXZ = 1;

  if (e.hitReactT > 0) {
    const u = e.hitReactT / 0.18;            // 1 → 0
    const punch = Math.sin(u * Math.PI);     // 0 → 1 → 0
    scaleY  = 1 - punch * 0.15;
    scaleXZ = 1 + punch * 0.15;
    offX = e.knockX * u;
    offZ = e.knockZ * u;
  }
  if (e.attackAnimT > 0 && !e.moving) {
    const total = 0.35;
    const u = 1 - e.attackAnimT / total;     // 0 → 1
    const dx = Math.sign(player.x - e.x);
    const dz = Math.sign(player.y - e.y);
    let lunge;
    if (u < 0.3)        lunge = -(u / 0.3) * 0.10;          // wind-up back
    else if (u < 0.6)   lunge =  ((u - 0.3) / 0.3) * 0.30;  // strike forward
    else                lunge =  (1 - (u - 0.6) / 0.4) * 0.15; // recover
    offX += dx * lunge;
    offZ += dz * lunge;
  }
  if (e.hurtT > 0) offY += Math.sin(e.hurtT * 0.8) * 0.04;

  // mesh.position is reset to e.pos at the top of the moving branch; for the
  // settled branch we apply offsets directly here (main.js will add terrain
  // height afterward).
  e.mesh.position.set(e.pos.x + offX, offY, e.pos.z + offZ);
  e.mesh.scale.set(scaleXZ, scaleY, scaleXZ);

  const d = manhattan(e, player);
  const aggroR = e.aggroRadius || 3;
  const wasAggro = e.aggro;
  if (d <= aggroR) e.aggro = true;
  if (d > aggroR + 4) e.aggro = false;
  // Edge: just-spotted-you. Pop a bright "!" above the head so the
  // player has a clear "this thing is hostile now" beat. Bosses also
  // raise a centered banner with their display name (one-shot per
  // instance via _bossIntroShown).
  if (e.aggro && !wasAggro) {
    const wp = new THREE.Vector3(e.mesh.position.x, e.mesh.position.y + 1.6, e.mesh.position.z);
    spawnFloat(wp, '!', 'level');
    if (e.isBoss && !e._bossIntroShown) {
      e._bossIntroShown = true;
      const name = e.displayName || e.kind;
      const sub = bossSubtitle(e);
      if (typeof window !== 'undefined' && window.__gj26_showBossBanner) {
        window.__gj26_showBossBanner(name, sub);
      }
      // Scripted-opener tutorial line. Tells the player how to read the
      // boss's telegraph vocabulary BEFORE the first hit lands.
      if (e.parryOnly) {
        log('hint', '⚠ Her telegraph is RED — only Riposte (Def-tree, slot key) negates the strike.');
      }
    }
  }

  // ---- Ranged behavior (e.g. archer) ----
  // Stays at attackRange. Retreats if player is inside minRange. Fires a
  // telegraphed shot when player is between minRange and attackRange.
  if (e.aggro && e.behavior === 'ranged') {
    const minR = e.minRange || 3;
    const maxR = e.attackRange || 6;
    if (d < minR) {
      // Smart retreat: prefer tiles that BREAK line-of-sight to the
      // player. Falls back to "straight back" if no LOS-break is reachable.
      e.moveTimer++;
      if (e.moveTimer < 35) return;
      e.moveTimer = 0;
      const dirs = [
        [-Math.sign(player.x - e.x), 0],   // straight back X
        [0, -Math.sign(player.y - e.y)],   // straight back Y
        [-1, 0], [1, 0], [0, -1], [0, 1],  // four cardinal fallbacks
      ];
      // Score each candidate: LOS-broken tiles win, ties broken by
      // distance from player. Skip blocked or zero-direction options.
      let best = null;
      let bestScore = -Infinity;
      for (const [dx, dy] of dirs) {
        if (dx === 0 && dy === 0) continue;
        const nx = e.x + dx, ny = e.y + dy;
        if (isBlocked(nx, ny, e)) continue;
        const losBroken = !losClear(nx, ny, player.x, player.y, isBlocked);
        // Distance-from-player after the move (higher = better)
        const distAfter = Math.abs(nx - player.x) + Math.abs(ny - player.y);
        const score = (losBroken ? 100 : 0) + distAfter;
        if (score > bestScore) { bestScore = score; best = [dx, dy]; }
      }
      if (best) {
        const [dx, dy] = best;
        e.targetX = e.x + dx; e.targetY = e.y + dy;
        e.dir = dx === 1 ? 'right' : (dx === -1 ? 'left' : (dy === 1 ? 'down' : 'up'));
        e.moving = true; e.moveT = 0;
      }
      return;
    }
    if (d > maxR) {
      // Out of range — close in.
      e.moveTimer++;
      if (e.moveTimer < 35) return;
      e.moveTimer = 0;
      const dx = Math.sign(player.x - e.x);
      const dy = Math.sign(player.y - e.y);
      if (dx !== 0 && !isBlocked(e.x + dx, e.y, e)) {
        e.targetX = e.x + dx; e.targetY = e.y;
        e.dir = dx === 1 ? 'right' : 'left';
        e.moving = true; e.moveT = 0;
      } else if (dy !== 0 && !isBlocked(e.x, e.y + dy, e)) {
        e.targetX = e.x; e.targetY = e.y + dy;
        e.dir = dy === 1 ? 'down' : 'up';
        e.moving = true; e.moveT = 0;
      }
      return;
    }
    // In sweet spot — face + fire.
    const fdx = player.x - e.x, fdy = player.y - e.y;
    if (Math.abs(fdx) >= Math.abs(fdy)) e.dir = fdx > 0 ? 'right' : 'left';
    else                                e.dir = fdy > 0 ? 'down'  : 'up';
    if (e.attackCd <= 0) {
      // Try to claim a global windup token before committing to a shot.
      // If the pool is full, briefly defer — re-attempt on the next tick.
      if (!takeWindupToken(e)) {
        e.attackCd = 18;     // ~0.3s defer
        return;
      }
      e.attackCd = 110;
      e.attackAnimT = 0.55;
      const targetX = player.x, targetY = player.y;
      const _dmg = rollEnemySwing(e, player);
      const _label = e.displayName || 'Archer';
      // Archer's arrow lands as a single dodgeable tile — yellow per the
      // unified telegraph vocabulary (AOE / dodgeable).
      import('../scene/telegraph.js').then(m => {
        m.spawnTileTelegraph(targetX, targetY, 0.55, { color: m.TELEGRAPH_COLORS.AOE });
      });
      const strikeDelayMs = 600;
      e.queuedHit = setTimeout(() => {
        e.queuedHit = null;
        releaseWindupToken(e);
        if (!e.alive || e.staggered) return;
        if (player.x === targetX && player.y === targetY) {
          damagePlayer(player, _dmg, log, _label);
        } else {
          log('combat', `${_label}'s arrow whistles past.`);
        }
      }, strikeDelayMs);
    }
    return;
  }

  // ---- Charger behavior ----
  // When player is on the same row OR column within `chargeRange`, the
  // charger paints a yellow line from itself to the player and beyond,
  // then dashes along that line. Damage applies to every tile in the path.
  // Forces the player to *sidestep* out of the lane — back-pedaling stays
  // in the line and eats the dash.
  if (e.aggro && e.behavior === 'charger') {
    const sameRow = (e.y === player.y);
    const sameCol = (e.x === player.x);
    const range = e.chargeRange || 5;
    if ((sameRow || sameCol) && d <= range && e.attackCd <= 0) {
      if (!takeWindupToken(e)) { e.attackCd = 18; return; }
      // Dash line: from charger, past the player by 1 tile (or until wall).
      const dx = sameRow ? Math.sign(player.x - e.x) : 0;
      const dy = sameCol ? Math.sign(player.y - e.y) : 0;
      let endX = e.x, endY = e.y;
      const path = [];
      for (let step = 1; step <= range + 1; step++) {
        const nx = e.x + dx * step;
        const ny = e.y + dy * step;
        if (isBlocked(nx, ny, e)) break;
        path.push({ x: nx, y: ny });
        endX = nx; endY = ny;
      }
      e.attackCd = 140;             // long recovery — ~2.3s
      e.attackAnimT = 0.70;
      e.dir = dx === 1 ? 'right' : dx === -1 ? 'left' : (dy === 1 ? 'down' : 'up');
      const _dmg = rollEnemySwing(e, player);
      const _label = e.displayName || 'Charger';
      const pathTiles = path.slice();          // capture for the strike callback
      import('../scene/telegraph.js').then(m => {
        m.spawnLineTelegraph(e.x, e.y, endX, endY, 0.70, { color: m.TELEGRAPH_COLORS.AOE });
      });
      e.queuedHit = setTimeout(() => {
        e.queuedHit = null;
        releaseWindupToken(e);
        if (!e.alive || e.staggered) return;
        // Did the player stay in the lane?
        const hit = pathTiles.some(t => t.x === player.x && t.y === player.y);
        if (hit) damagePlayer(player, _dmg, log, _label);
        else log('combat', `${_label}'s charge thunders past.`);
        // Teleport charger to last tile of path so it's "shot through"
        if (pathTiles.length > 0) {
          const last = pathTiles[pathTiles.length - 1];
          if (!isBlocked(last.x, last.y, e)) {
            e.x = last.x; e.y = last.y;
            e.targetX = last.x; e.targetY = last.y;
            e.pos.x = last.x + 0.5;
            e.pos.z = last.y + 0.5;
          }
        }
      }, 700);
      return;
    }
    // Out of line / out of range — fall through to standard chase below
  }

  // Kiter post-strike stun — held still so the player gets a guaranteed
  // 400ms free-hit window after every kiter strike. Returns early so the
  // retreat block below doesn't fire yet.
  if (e.aggro && e.behavior === 'kiter' && e.kiterStunT > 0) {
    e.moving = false;        // freeze in place
    return;
  }

  // Kiter retreat — when this counter > 0, the kiter walks AWAY from the
  // player instead of chasing. Set after each successful hit to create a
  // swoop-in-and-fall-back pattern.
  if (e.aggro && e.behavior === 'kiter' && e.kiterRetreat > 0) {
    e.moveTimer++;
    if (e.moveTimer < 28) return;
    e.moveTimer = 0;
    const dx = -Math.sign(player.x - e.x);
    const dy = -Math.sign(player.y - e.y);
    if (dx !== 0 && !isBlocked(e.x + dx, e.y, e)) {
      e.targetX = e.x + dx; e.targetY = e.y;
      e.dir = dx === 1 ? 'right' : 'left';
      e.moving = true; e.moveT = 0;
      e.kiterRetreat--;
    } else if (dy !== 0 && !isBlocked(e.x, e.y + dy, e)) {
      e.targetX = e.x; e.targetY = e.y + dy;
      e.dir = dy === 1 ? 'down' : 'up';
      e.moving = true; e.moveT = 0;
      e.kiterRetreat--;
    } else {
      e.kiterRetreat = 0;  // can't retreat — drop the flag
    }
    return;
  }

  if (e.aggro && d > 1) {
    e.moveTimer++;
    if (e.moveTimer < 35) return;
    e.moveTimer = 0;
    const dx = Math.sign(player.x - e.x);
    const dy = Math.sign(player.y - e.y);
    if (dx !== 0 && !isBlocked(e.x + dx, e.y, e)) {
      e.targetX = e.x + dx; e.targetY = e.y;
      e.dir = dx === 1 ? 'right' : 'left';
      e.moving = true; e.moveT = 0;
    } else if (dy !== 0 && !isBlocked(e.x, e.y + dy, e)) {
      e.targetX = e.x; e.targetY = e.y + dy;
      e.dir = dy === 1 ? 'down' : 'up';
      e.moving = true; e.moveT = 0;
    }
  } else if (e.aggro && d === 1) {
    // Face the player before attacking so the headbutt aims correctly.
    const fdx = player.x - e.x, fdy = player.y - e.y;
    if (Math.abs(fdx) >= Math.abs(fdy)) {
      e.dir = fdx > 0 ? 'right' : 'left';
    } else {
      e.dir = fdy > 0 ? 'down' : 'up';
    }
    if (e.attackCd <= 0) {
      const isBoss = !!e.isBoss;
      // Try to claim a global windup token. Bosses always pass.
      // Non-bosses defer ~0.3s if the pool is full.
      if (!takeWindupToken(e)) {
        e.attackCd = 18;
        return;
      }
      // Phase-2 bosses cycle through three attack shapes: slam (3×3) →
      // lash (line of 4 in facing dir) → bramble pull (line from boss to
      // player, drags + roots). All carry parryOnly — but only the slam
      // and lash deal damage. Pull is pure setup: it pins the player so
      // the next slam connects. Anti-kite mechanic — player can't just
      // back away forever.
      let phase2Attack = 'slam';
      if (e.phase === 2) {
        e._brambleAlt = ((e._brambleAlt | 0) + 1) % 3;
        phase2Attack = ['slam', 'lash', 'pull'][e._brambleAlt];
      }
      const phase2Lash = phase2Attack === 'lash';
      const phase2Pull = phase2Attack === 'pull';
      // Boss-tier OR slam-tagged enemies hit a 3×3 area; they wind up
      // longer (0.75-0.9s) and telegraph wider so the player has a clear
      // "GET OFF THE WHOLE PATCH" cue.
      const isSlam = (isBoss || !!e.slam) && phase2Attack === 'slam';
      // attackCdScale shortens phase-2 cooldowns (set in transition block).
      const cdScale = e.attackCdScale || 1.0;
      e.attackCd  = Math.round((isSlam ? 110 : phase2Pull ? 110 : 75) * cdScale);
      e.attackAnimT = (isSlam ? (isBoss ? 0.75 : 0.90) : phase2Pull ? 0.85 : 0.55) * cdScale;
      // Lock impact tile + radius. Steps off (or dodges with i-frames) avoid it.
      const targetX = player.x, targetY = player.y;
      const radius = isSlam ? 1 : 0;
      const _dmg = rollEnemySwing(e, player);
      const _label = e.displayName || (e.kind === 'goblin' ? 'Bramble-imp' : e.kind);
      import('../scene/telegraph.js').then(m => {
        // Color by category — see TELEGRAPH_COLORS.
        let color;
        if (phase2Pull)        color = m.TELEGRAPH_COLORS.PULL;
        else if (e.parryOnly)  color = m.TELEGRAPH_COLORS.PARRY_ONLY;
        else if (isBoss)       color = m.TELEGRAPH_COLORS.BOSS;
        else if (isSlam)       color = m.TELEGRAPH_COLORS.AOE;
        else                   color = m.TELEGRAPH_COLORS.NORMAL;
        if (phase2Pull) {
          // Vine line from the boss to the player's current tile.
          // Pinned at windup-start; the resolution re-checks at fire time.
          m.spawnLineTelegraph(e.x, e.y, targetX, targetY, 0.85, { color });
        } else if (phase2Lash) {
          // Line of 4 tiles in the boss's facing direction.
          const facing = ({ down:[0,1], up:[0,-1], left:[-1,0], right:[1,0] })[e.dir] || [0,1];
          m.spawnLineTelegraph(e.x + facing[0], e.y + facing[1],
                                e.x + facing[0]*4, e.y + facing[1]*4,
                                0.85, { color });
        } else if (isSlam) {
          m.spawnAreaTelegraph(targetX, targetY, radius, isBoss ? 0.55 : 0.85, { color });
        } else {
          m.spawnTileTelegraph(targetX, targetY, 0.35, { color });
        }
      });
      const strikeDelayMs = isBoss ? 500 : (e.slam ? 850 : 350);
      // For phase-2 lash, capture the line tiles so the strike checks
      // against the lane, not the slam radius. Pull captures its own
      // line via the start-of-windup boss/player positions.
      let lashTiles = null;
      let pullLine = null;
      if (phase2Lash) {
        const facing = ({ down:[0,1], up:[0,-1], left:[-1,0], right:[1,0] })[e.dir] || [0,1];
        lashTiles = [1,2,3,4].map(s => ({ x: e.x + facing[0]*s, y: e.y + facing[1]*s }));
      }
      if (phase2Pull) {
        pullLine = { fromX: e.x, fromY: e.y, toX: targetX, toY: targetY };
      }
      e.queuedHit = setTimeout(() => {
        e.queuedHit = null;
        releaseWindupToken(e);
        if (!e.alive) return;
        if (e.staggered) {
          // Power-swing interrupted us — quiet skip.
          return;
        }
        // BRAMBLE PULL — vine yanks the player toward the boss + roots
        // them for 1s. No damage; the root sets up the next attack.
        // Dodge i-frames during the windup cleanly negate the pull.
        if (pullLine) {
          if (player.iframeT > 0) return;
          // Player must still be on the line at fire time. Tolerance
          // 0.6 tiles — a half-step dodge saves them.
          if (!_pointNearLine(player.x + 0.5, player.y + 0.5,
                              pullLine.fromX + 0.5, pullLine.fromY + 0.5,
                              pullLine.toX + 0.5, pullLine.toY + 0.5, 0.6)) {
            log('combat', `${_label}'s vine misses.`);
            return;
          }
          _pullPlayerToward(player, e, 2, isBlocked);
          player.rootedT = 1.0;
          log('combat', `${_label} drags you in!`);
          import('../core/sfx.js').then(m => m.sfx.thud?.()).catch(() => {});
          import('../core/camera.js').then(m => m.shakeCamera(0.10));
          return;
        }
        let inArea;
        if (lashTiles) {
          inArea = lashTiles.some(t => t.x === player.x && t.y === player.y);
        } else {
          inArea = Math.abs(player.x - targetX) <= radius
                && Math.abs(player.y - targetY) <= radius;
        }
        if (inArea) {
          damagePlayer(player, _dmg, log, _label, { parryOnly: !!e.parryOnly });
        } else {
          log('combat', `${_label}'s strike misses.`);
        }
        // Kiter post-hit pattern — first a 400ms stun (so the player gets
        // a guaranteed free-hit window per the AI research punish-window
        // rule), THEN retreat 3 tiles. kiterStunT counts down in seconds
        // and gates the retreat branch.
        if (e.behavior === 'kiter' && e.alive) {
          e.kiterStunT = 0.4;
          e.kiterRetreat = 3;
        }
      }, strikeDelayMs);
    }
  } else {
    e.moveTimer++;
    if (e.moveTimer > 100 + Math.random() * 80) {
      e.moveTimer = 0;
      const choices = [[1, 0], [-1, 0], [0, 1], [0, -1]];
      const [dx, dy] = choices[Math.floor(Math.random() * 4)];
      const nx = e.x + dx, ny = e.y + dy;
      if (Math.abs(nx - e.homeX) <= 3 && Math.abs(ny - e.homeY) <= 3 && !isBlocked(nx, ny, e)) {
        e.targetX = nx; e.targetY = ny;
        e.dir = dx === 1 ? 'right' : dx === -1 ? 'left' : dy === 1 ? 'down' : 'up';
        e.moving = true; e.moveT = 0;
      }
    }
  }
}
