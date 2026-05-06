// Shimmer drops — small floating orbs that occasionally drop from enemies.
// Two flavors:
//   - 'stamina' (green): refunds 30 stamina on walk-over
//   - 'hp'      (red):   refunds  5 HP      on walk-over
// Lifetime is finite so they don't accumulate in the world.
//
// Public API:
//   spawnStaminaShimmer(scene, worldPos)
//   spawnHPShimmer(scene, worldPos)
//   updateShimmers(dt, player)
//   clearShimmers()
import * as THREE from 'three';
import { spawnFloat } from '../core/floaters.js';

const _live = [];   // { mesh, mat, life, total, t, kind }
const STAMINA_REFUND = 30;
const HP_REFUND      = 5;
const PICKUP_RADIUS  = 0.6;
const LIFE_SECONDS   = 12;

const _GEOM = new THREE.SphereGeometry(0.10, 12, 8);

function _spawn(scene, worldPos, kind, color) {
  if (!scene) return null;
  const mat = new THREE.MeshBasicMaterial({
    color,
    transparent: true,
    opacity: 0.95,
    depthWrite: false,
  });
  const mesh = new THREE.Mesh(_GEOM, mat);
  mesh.position.set(worldPos.x, worldPos.y + 0.45, worldPos.z);
  mesh.renderOrder = 6;
  const glow = new THREE.PointLight(color, 0.8, 1.6);
  glow.position.copy(mesh.position);
  scene.add(mesh);
  scene.add(glow);
  _live.push({ mesh, mat, glow, life: LIFE_SECONDS, total: LIFE_SECONDS, t: 0, baseY: mesh.position.y, kind });
  return mesh;
}

export function spawnStaminaShimmer(scene, worldPos) {
  return _spawn(scene, worldPos, 'stamina', 0x9be05c);
}
export function spawnHPShimmer(scene, worldPos) {
  return _spawn(scene, worldPos, 'hp', 0xe85c5c);
}

export function updateShimmers(dt, player) {
  for (let i = _live.length - 1; i >= 0; i--) {
    const s = _live[i];
    s.life -= dt;
    s.t += dt;
    if (s.life <= 0) {
      _despawn(s);
      _live.splice(i, 1);
      continue;
    }
    // Idle bob + slow Y-spin so it reads as a magical pickup.
    s.mesh.position.y = s.baseY + Math.sin(s.t * 3) * 0.06;
    s.mesh.rotation.y = s.t * 1.2;
    if (s.glow) s.glow.position.y = s.mesh.position.y;
    // Fade alpha during last second so disappearance reads.
    s.mat.opacity = Math.min(0.95, s.life);
    // Pickup proximity check
    if (player) {
      const dx = s.mesh.position.x - player.pos.x;
      const dz = s.mesh.position.z - player.pos.z;
      if (dx*dx + dz*dz < PICKUP_RADIUS * PICKUP_RADIUS) {
        let consumed = false;
        if (s.kind === 'hp') {
          const before = player.hp ?? 0;
          const max = player.hpMax ?? 1;
          if (before < max) {
            player.hp = Math.min(max, before + HP_REFUND);
            const wp = new THREE.Vector3(player.pos.x, player.pos.y + 1.5, player.pos.z);
            spawnFloat(wp, `+${HP_REFUND} HP`, 'heal');
            consumed = true;
          }
        } else {
          // stamina (default)
          const before = player.stamina ?? 0;
          const max = player.staminaMax ?? 100;
          if (before < max) {
            player.stamina = Math.min(max, before + STAMINA_REFUND);
            const wp = new THREE.Vector3(player.pos.x, player.pos.y + 1.5, player.pos.z);
            spawnFloat(wp, `+${STAMINA_REFUND} STA`, 'heal');
            consumed = true;
          }
        }
        if (consumed) {
          import('../core/sfx.js').then(m => m.sfx.pickup());
          _despawn(s);
          _live.splice(i, 1);
        }
      }
    }
  }
}

function _despawn(s) {
  s.mesh.parent?.remove(s.mesh);
  s.mat.dispose();
  if (s.glow) s.glow.parent?.remove(s.glow);
}

export function clearShimmers() {
  for (const s of _live) _despawn(s);
  _live.length = 0;
}
