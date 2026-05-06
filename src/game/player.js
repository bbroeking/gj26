// Player factory — owns 3D mesh, grid position, vec position, skills, inventory.
import * as THREE from 'three';
import { CONFIG } from '../data/config.js';
import { Inventory } from './inventory.js';
import { makeSkills, hpMaxForLv } from './skills.js';
import { makeQuest } from './quest.js';
import { buildPlayerMesh, buildKnightMesh, buildArchetypeMesh } from '../scene/characters.js';

const DEFAULT_LOADOUT = [
  'cape_red',                                        // back first so other gear renders on top
  'helmet_centurion', 'breastplate_olive', 'pauldrons_gold',
  'belt_leather', 'tunic_skirt_cream', 'boots_brown',
  'sword_short', 'shield_laurel',
];

export function createPlayer(spawnX, spawnY, archetype = null) {
  // v2: prefer the archetype-specific GLB if archetype is set + loaded.
  // Falls back to the legacy buildKnightMesh if no archetype, then to a
  // procedural mesh so the game still boots if assets fail.
  let mesh = null;
  if (archetype) mesh = buildArchetypeMesh(archetype);
  if (!mesh)     mesh = buildKnightMesh(DEFAULT_LOADOUT);
  if (!mesh)     mesh = buildPlayerMesh();
  const pos = new THREE.Vector3(spawnX + 0.5, 0, spawnY + 0.5);
  mesh.position.copy(pos);
  return {
    x: spawnX, y: spawnY,
    spawnX, spawnY,
    pos, mesh,
    archetype: archetype || 'Knight',
    targetX: spawnX, targetY: spawnY,
    moving: false,
    moveT: 0,
    moveDur: CONFIG.player.moveDuration,
    runHeld: false,                         // shift key state
    running: false,                         // derived per-frame: runHeld || chasing
    dir: CONFIG.player.spawnFacing,
    bobT: 0,
    // hpMax is derived from HP level via hpMaxForLv (Lv 10 → 20). The
    // CONFIG.player.hpMax constant is kept for legacy paths but not used
    // for player creation.
    hp: hpMaxForLv(10),
    hpMax: hpMaxForLv(10),
    attackCd: 0,
    hurtT: 0,
    // ARPG combat layer
    iframeT: 0,                              // seconds of damage immunity
    dodgeCd: 0,                              // seconds until next dodge
    actionCd: {},                            // unified per-action cooldowns (id-keyed)
    actionFireT: {},                         // brief activation flash (id-keyed)
    isDodging: false,                        // true during a dash step
    stamina: 100,                            // active resource for dodge / abilities
    staminaMax: 100,
    staminaPulseT: 0,                        // > 0 when an action just failed cost-check
    exhaustedT: 0,                           // > 0 → reduced regen + slower walk
    // Basic-swing combo: every successful hit advances comboCount; the
    // third successful hit lands as a power swing. Resets if the player
    // gets hit, or if 2s pass without a swing.
    comboCount: 0,
    comboT: 0,
    skills: makeSkills(),
    inventory: new Inventory(),
    // Bank storage (Coopers' Hold) — id -> qty map of stack-only items.
    // Populated by deposits at the bank tile; persisted via save.js.
    bank: {},
    quest: makeQuest(),
    // path navigation: list of {x,y} tiles to walk through.
    // After path completes, run `onPathDone` (e.g., trigger interact).
    path: [],
    onPathDone: null,
    clickMarker: { x: -1, y: -1, visible: false },
    // Per-character animation state for src/anim/procedural.js
    animState: {},
    // Combat
    combatTarget: null,
    combatStyle: CONFIG.combat.defaultStyle,
    // Wayfinding: which tiles have been visited. Awards 1 carto XP per new tile.
    // Restored from localStorage on boot; saved (debounced) by main.js.
    exploredTiles: (() => {
      try {
        const raw = localStorage.getItem('gj26.explored');
        if (raw) {
          const arr = JSON.parse(raw);
          if (Array.isArray(arr)) return new Set(arr);
        }
      } catch (_) {}
      return new Set([spawnX + ',' + spawnY]);
    })(),
    // Player-placed waypoints on the world map (Wayfinding 25+).
    waypoints: (() => {
      try {
        const raw = localStorage.getItem('gj26.waypoints');
        if (raw) {
          const arr = JSON.parse(raw);
          if (Array.isArray(arr)) return arr;
        }
      } catch (_) {}
      return [];
    })(),
    // Wayfinding sketches — the field journal. Each entry: { id, name,
    // category, sketchedAt (ms), quality (0..3) }. Persists across reloads.
    sketches: (() => {
      try {
        const raw = localStorage.getItem('gj26.sketches');
        if (raw) {
          const arr = JSON.parse(raw);
          if (Array.isArray(arr)) return arr;
        }
      } catch (_) {}
      return [];
    })(),
    // Ink recipes the player has been *hinted* about by NPCs (separate
    // from knownRecipes which tracks actually-discovered recipes). Hints
    // surface in the Inscribing Table's Hints tab.
    hintedRecipes: (() => {
      try {
        const raw = localStorage.getItem('gj26.hintedRecipes');
        if (raw) {
          const arr = JSON.parse(raw);
          if (Array.isArray(arr)) return new Set(arr);
        }
      } catch (_) {}
      return new Set();
    })(),
    // Action bar — 8 slots, each holds an action id (melee ability,
    // magic spell, or ranged attack). Bound via the Abilities Book UI.
    // Defaults to the four classic combat abilities + four empty.
    actionBar: (() => {
      try {
        const raw = localStorage.getItem('gj26.actionBar');
        if (raw) {
          const arr = JSON.parse(raw);
          if (Array.isArray(arr) && arr.length === 8) return arr;
        }
      } catch (_) {}
      return ['cleave', 'leap', 'rend', 'whirlwind', null, null, null, null];
    })(),
    // Active sketch channel state. sketchT counts down; sketchSubject is the
    // resolved subject that started the channel.
    sketchT: 0,
    sketchSubject: null,
    sketchAnchor: null,
    // Action lock for non-combat skill verbs (chop / forage / fish / mine).
    // Holds: { kind, target, cdFrames, onTick, onComplete }
    activeAction: null,
  };
}

const FACING_ANGLE = {
  down:  0,                  // +Z (toward camera)
  up:    Math.PI,            // -Z
  right: Math.PI / 2,        // +X
  left:  -Math.PI / 2,       // -X
};

/** Smooth-tween the player mesh from current pos toward (targetX, targetY). */
export function updatePlayerMovement(player, dt) {
  if (player.attackCd > 0) player.attackCd--;
  if (player.hurtT > 0) player.hurtT--;
  if (player.iframeT > 0) player.iframeT = Math.max(0, player.iframeT - dt);
  if (player.dodgeCd  > 0) player.dodgeCd  = Math.max(0, player.dodgeCd  - dt);
  if (player.defensiveT > 0) player.defensiveT = Math.max(0, player.defensiveT - dt);
  if (player.riposteT > 0) player.riposteT = Math.max(0, player.riposteT - dt);
  // Spell-buff timers (rune magic).
  if (player.stoneSkinT > 0) player.stoneSkinT = Math.max(0, player.stoneSkinT - dt);
  if (player.senseAggroT > 0) player.senseAggroT = Math.max(0, player.senseAggroT - dt);
  // Bramble-root (Hedgemother phase-2 mechanic) — gates movement, not
  // casting. Spells + abilities still fire while rooted.
  if (player.rootedT > 0) player.rootedT = Math.max(0, player.rootedT - dt);
  // Vigor: 3 HP/sec heal-over-time, total 30 over 10s. Accumulator handles
  // sub-integer fractions so a 60fps tick still actually heals.
  if (player.vigorT > 0) {
    player.vigorT = Math.max(0, player.vigorT - dt);
    player.vigorAcc = (player.vigorAcc || 0) + 3 * dt;
    if (player.vigorAcc >= 1 && player.hp < player.hpMax) {
      const heal = Math.min(Math.floor(player.vigorAcc), player.hpMax - player.hp);
      player.hp += heal;
      player.vigorAcc -= heal;
    }
  }
  // Unified action cooldowns / fire flashes — keyed by action id (mixed
  // melee + magic + ranged). Tick everything down each frame.
  if (player.actionCd) {
    for (const k in player.actionCd) {
      if (player.actionCd[k] > 0) player.actionCd[k] = Math.max(0, player.actionCd[k] - dt);
    }
  }
  if (player.actionFireT) {
    for (const k in player.actionFireT) {
      if (player.actionFireT[k] > 0) player.actionFireT[k] = Math.max(0, player.actionFireT[k] - dt);
    }
  }
  // Stamina regen — slower while a combat target is locked so the player
  // has to choose between aggression and recovery. Exhausted state cuts
  // it further so running dry has a real cost.
  if (player.exhaustedT > 0) {
    player.exhaustedT = Math.max(0, player.exhaustedT - dt);
  }
  if (player.stamina < player.staminaMax) {
    const inCombat = !!player.combatTarget;
    let regen = inCombat ? 8 : 15;
    if (player.exhaustedT > 0) regen *= 0.4;
    player.stamina = Math.min(player.staminaMax, player.stamina + regen * dt);
  }
  if (player.staminaPulseT > 0) {
    player.staminaPulseT = Math.max(0, player.staminaPulseT - dt);
  }
  // Combo chain timer — drains; combo resets when it expires.
  if (player.comboT > 0) {
    player.comboT = Math.max(0, player.comboT - dt);
    if (player.comboT === 0) player.comboCount = 0;
  }
  // Out-of-combat HP regen — slow drip to soften exploration without
  // making combat trivial. Ticks 1 HP every ~3s, gated on:
  //   - no locked combat target
  //   - hurtT cooldown (just took a hit) elapsed
  //   - hp not already full
  // The regen accumulator lets the rate stay smooth across frames.
  player.regenAcc = (player.regenAcc || 0);
  if (player.hp > 0 && player.hp < player.hpMax && !player.combatTarget && player.hurtT <= 0) {
    player.regenAcc += dt * (1 / 3);   // 1 HP per 3 seconds
    while (player.regenAcc >= 1) {
      player.regenAcc -= 1;
      player.hp = Math.min(player.hpMax, player.hp + 1);
      // Tiny green floater so the player can see the trickle. Loaded
      // lazily to keep this module import-cheap.
      import('../core/floaters.js').then(m => {
        const wp = new THREE.Vector3(player.pos.x, player.pos.y + 1.5, player.pos.z);
        m.spawnFloat(wp, '+1', 'heal');
      });
    }
  } else {
    player.regenAcc = 0;
  }

  if (player.moving) {
    player.moveT += dt;
    const u = Math.min(1, player.moveT / player.moveDur);
    // Smoothstep ease-in-out for tile movement. Linear `u` slammed each
    // step's start + end (robot-marching feel); smoothstep curves into
    // motion and out of it so the player reads as having weight. Bob
    // stays linear-into-sin since sin already self-eases.
    const eu = u * u * (3 - 2 * u);
    const fromX = player.x + 0.5;
    const fromY = player.y + 0.5;
    const toX = player.targetX + 0.5;
    const toY = player.targetY + 0.5;
    player.pos.x = fromX + (toX - fromX) * eu;
    player.pos.z = fromY + (toY - fromY) * eu;
    // small bob
    player.pos.y = Math.sin(u * Math.PI) * 0.06;
    player.bobT += dt * 12;
    if (u >= 1) {
      player.x = player.targetX;
      player.y = player.targetY;
      player.moving = false;
      player.moveT = 0;
      player.pos.y = 0;
      player.isDodging = false;
      onStepFinish(player);
    }
  } else {
    player.pos.y = 0;
    player.bobT = 0;
  }

  player.mesh.position.copy(player.pos);
  // facing rotation (smoothed)
  const targetA = FACING_ANGLE[player.dir];
  const cur = player.mesh.rotation.y;
  // shortest-arc lerp
  let delta = ((targetA - cur + Math.PI) % (Math.PI * 2)) - Math.PI;
  if (delta < -Math.PI) delta += Math.PI * 2;
  player.mesh.rotation.y = cur + delta * Math.min(1, dt * 12);
}

const FACING = { down: [0, 1], up: [0, -1], left: [-1, 0], right: [1, 0] };

/** Dodge — fast 1-tile dash with brief i-frames. Falls back to side-tiles
 *  if the facing tile is blocked. Returns true if a dodge actually started.
 *
 *  The dodge cancels any pending path so the player can break out of an
 *  auto-walked combat chase. `iframeT` blocks damage for ~0.18s (combat.js
 *  reads it). `isDodging` flags the step so footstep/anim modules can
 *  swap effects later.
 */
export const DODGE_STAMINA_COST = 20;

export function tryDodge(player, isBlocked) {
  if (player.dodgeCd > 0) return false;
  if (player.moving) return false;
  if (player.hp <= 0) return false;
  if (player.stamina < DODGE_STAMINA_COST) {
    player.staminaPulseT = 0.4;
    return false;
  }
  // Prefer current facing; if blocked, try perpendicular dirs.
  const order = [
    FACING[player.dir],
    FACING[player.dir === 'left' || player.dir === 'right' ? 'down' : 'right'],
    FACING[player.dir === 'left' || player.dir === 'right' ? 'up'   : 'left'],
  ];
  for (const [dx, dy] of order) {
    const nx = player.x + dx;
    const ny = player.y + dy;
    if (!isBlocked(nx, ny)) {
      if (dy === -1) player.dir = 'up';
      else if (dy === 1) player.dir = 'down';
      else if (dx === -1) player.dir = 'left';
      else if (dx === 1) player.dir = 'right';
      player.path = [];           // break any active auto-walk
      player.onPathDone = null;
      player.activeAction = null; // cancel any pending channeled gather
      player.targetX = nx;
      player.targetY = ny;
      player.moving = true;
      player.moveT = 0;
      player.moveDur = 0.10;      // ~3× faster than a walk-step
      player.iframeT = 0.18;
      player.dodgeCd = 0.6;
      player.isDodging = true;
      player.stamina = Math.max(0, player.stamina - DODGE_STAMINA_COST);
      // Drained the pool with this dodge → exhausted for ~3s.
      if (player.stamina <= 0) player.exhaustedT = Math.max(player.exhaustedT, 3.0);
      // Dust burst at the start tile — earthy tan, low + wide spread so
      // it reads as kicking up dust, not sparks.
      const dustPos = new THREE.Vector3(player.pos.x, player.pos.y + 0.10, player.pos.z);
      import('../scene/sparks.js').then(m => m.spawnHitSparks(dustPos, {
        count: 12, spread: 0.9, color: 0xc9b58c, size: 5, life: 0.5,
      }));
      // Quiet whoosh + a small camera nudge so the dodge has weight
      import('../core/sfx.js').then(m => m.sfx.footstep());
      return true;
    }
  }
  return false;
}

/** Try to start a step in (dx, dy). Returns true if started moving. */
export function startStep(player, dx, dy, isBlocked) {
  if (player.moving) return false;
  if (dx === 0 && dy === 0) return false;
  if (dy === -1) player.dir = 'up';
  else if (dy === 1) player.dir = 'down';
  else if (dx === -1) player.dir = 'left';
  else if (dx === 1) player.dir = 'right';
  const nx = player.x + dx;
  const ny = player.y + dy;
  if (isBlocked(nx, ny)) return false;
  player.targetX = nx;
  player.targetY = ny;
  player.moving = true;
  player.moveT = 0;
  // Pick step duration based on current running state.
  player.moveDur = player.running
    ? CONFIG.player.runMoveDuration
    : CONFIG.player.moveDuration;
  // Exhausted → 25% slower steps so the cost reads in feel, not just numbers.
  if (player.exhaustedT > 0) player.moveDur *= 1.25;
  // Surface-aware footstep tap. The world module exposes a global
  // surface-lookup (set in main.js) so we don't drag a world import
  // into player.js. Falls back to the default footstep if no lookup.
  const kind = (typeof window !== 'undefined' && window.__gj26_surfaceUnder)
    ? window.__gj26_surfaceUnder(player.x, player.y)
    : 'grass';
  import('../core/sfx.js').then(m => m.sfx.footstepOn(kind));
  return true;
}

/**
 * Begin walking along a path of {x,y} tiles. Cancels any prior path/interact.
 * `onDone` runs once player reaches the final tile.
 */
export function setPath(player, path, onDone = null) {
  player.path = path || [];
  player.onPathDone = onDone;
  if (player.path.length > 0) {
    player.clickMarker.x = player.path[player.path.length - 1].x;
    player.clickMarker.y = player.path[player.path.length - 1].y;
    player.clickMarker.visible = true;
  } else {
    player.clickMarker.visible = false;
    if (onDone) onDone();
  }
}

/** Pull next tile from the path, start step toward it. */
export function consumePathStep(player, isBlocked) {
  if (player.moving || !player.path || player.path.length === 0) return false;
  const next = player.path[0];
  const dx = Math.sign(next.x - player.x);
  const dy = Math.sign(next.y - player.y);
  if (dx === 0 && dy === 0) {
    // already there — pop and recurse
    player.path.shift();
    return consumePathStep(player, isBlocked);
  }
  if (!startStep(player, dx, dy, isBlocked)) {
    // path blocked mid-walk: cancel
    player.path = [];
    player.onPathDone = null;
    player.clickMarker.visible = false;
    return false;
  }
  player.path.shift();
  if (player.path.length === 0) player.clickMarker.visible = false;
  return true;
}

/** Called when current step finishes. Fires onPathDone if path empty. */
export function onStepFinish(player) {
  // Tile-entered hook — fires after every step (path or keyboard) so
  // main.js can apply trap damage / scope-aware footstep sfx without
  // duplicating step-end detection.
  if (player.onTileEnter) player.onTileEnter(player.x, player.y);
  if (player.path.length === 0 && player.onPathDone) {
    const cb = player.onPathDone;
    player.onPathDone = null;
    cb();
  }
}

