// Ground impact rings. Expanding circles on the floor that spawn when
// power swings / heavy abilities land. Adds physical weight to a hit
// without committing to a per-frame mesh animation rig.
//
// Public API:
//   setImpactScene(scene)
//   spawnImpactRing(worldPos, opts)
//   updateImpacts(dt)
import * as THREE from 'three';

let _scene = null;
const _live = [];   // { mesh, mat, life, total }

export function setImpactScene(scene) { _scene = scene; }

const _GEOM = new THREE.RingGeometry(0.48, 0.55, 28);

/** Spawn an expanding ring at (worldPos.x, 0.04, worldPos.z).
 *
 *   color    — hex (default warm gold)
 *   life     — total seconds (default 0.4)
 *   maxScale — final scale multiplier (default 3.0)
 *   yOffset  — height above ground (default 0.04)
 */
export function spawnImpactRing(worldPos, opts = {}) {
  if (!_scene) return null;
  const color = opts.color ?? 0xffd864;
  const life = opts.life ?? 0.4;
  const maxScale = opts.maxScale ?? 3.0;
  const yOffset = opts.yOffset ?? 0.04;
  const mat = new THREE.MeshBasicMaterial({
    color,
    transparent: true,
    opacity: 0.85,
    side: THREE.DoubleSide,
    depthWrite: false,
  });
  const mesh = new THREE.Mesh(_GEOM, mat);
  mesh.rotation.x = -Math.PI / 2;
  mesh.position.set(worldPos.x, yOffset, worldPos.z);
  mesh.scale.setScalar(0.4);
  mesh.renderOrder = 5;
  _scene.add(mesh);
  _live.push({ mesh, mat, life, total: life, maxScale });
  return mesh;
}

export function updateImpacts(dt) {
  for (let i = _live.length - 1; i >= 0; i--) {
    const r = _live[i];
    r.life -= dt;
    if (r.life <= 0) {
      r.mesh.parent?.remove(r.mesh);
      r.mat.dispose();
      _live.splice(i, 1);
      continue;
    }
    const u = 1 - (r.life / r.total);     // 0 → 1
    // Quick expand (ease-out cubic) + linear opacity fade.
    const ease = 1 - Math.pow(1 - u, 3);
    const scl = 0.4 + (r.maxScale - 0.4) * ease;
    r.mesh.scale.setScalar(scl);
    r.mat.opacity = 0.85 * (1 - u);
  }
}
