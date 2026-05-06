// Tiny particle bursts for combat hits. Each burst is a short-lived
// THREE.Points cloud — small, GPU-cheap, no textures.
//
// Public API:
//   spawnHitSparks(scene, worldPos, opts)   — call on a hit/miss/crit
//   updateSparks(dt)                        — call every frame
import * as THREE from 'three';

const _bursts = [];   // { points, life, maxLife, vels, baseOpacity }

let _scene = null;
export function setSparkScene(scene) { _scene = scene; }

const _GEOM_CACHE = new Map();   // count → BufferGeometry template

function geomFor(count) {
  let g = _GEOM_CACHE.get(count);
  if (g) return g.clone();
  g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(new Float32Array(count * 3), 3));
  _GEOM_CACHE.set(count, g);
  return g.clone();
}

/**
 * Spawn a small spark burst at `worldPos`.
 *   color   — hex (default warm gold for hits, blue-grey for miss)
 *   count   — number of points (default 8)
 *   spread  — initial speed magnitude (default 1.6)
 *   life    — total seconds before fade (default 0.32)
 *   size    — point size in px (default 5)
 */
export function spawnHitSparks(sceneOrPos, posMaybe, optsMaybe) {
  // Support both forms:
  //   spawnHitSparks(scene, worldPos, opts)   — explicit scene
  //   spawnHitSparks(worldPos, opts)          — uses scene set via setSparkScene
  let scene, worldPos, opts;
  if (sceneOrPos && sceneOrPos.isScene) {
    scene = sceneOrPos; worldPos = posMaybe; opts = optsMaybe ?? {};
  } else {
    scene = _scene; worldPos = sceneOrPos; opts = posMaybe ?? {};
  }
  if (!scene || !worldPos) return;
  return _spawn(scene, worldPos, opts);
}

function _spawn(scene, worldPos, opts) {
  const count   = opts.count ?? 8;
  const spread  = opts.spread ?? 1.6;
  const life    = opts.life ?? 0.32;
  const size    = opts.size ?? 5;
  const color   = opts.color ?? 0xf6c64a;

  const geom = geomFor(count);
  const pos  = geom.attributes.position.array;
  const vels = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    pos[i*3 + 0] = worldPos.x;
    pos[i*3 + 1] = worldPos.y;
    pos[i*3 + 2] = worldPos.z;
    // Random hemisphere bias upward (sparks tend to fly up + away)
    const a = Math.random() * Math.PI * 2;
    const r = (0.4 + Math.random() * 0.6) * spread;
    vels[i*3 + 0] = Math.cos(a) * r;
    vels[i*3 + 1] = (0.6 + Math.random() * 0.9) * spread;
    vels[i*3 + 2] = Math.sin(a) * r;
  }
  const mat = new THREE.PointsMaterial({
    color,
    size,
    sizeAttenuation: false,
    transparent: true,
    opacity: 1,
    depthWrite: false,
  });
  const points = new THREE.Points(geom, mat);
  points.frustumCulled = false;
  scene.add(points);
  _bursts.push({ points, life, maxLife: life, vels });
}

const _G = 7.0;

export function updateSparks(dt) {
  for (let i = _bursts.length - 1; i >= 0; i--) {
    const b = _bursts[i];
    b.life -= dt;
    if (b.life <= 0) {
      b.points.parent?.remove(b.points);
      b.points.geometry.dispose();
      b.points.material.dispose();
      _bursts.splice(i, 1);
      continue;
    }
    const pos = b.points.geometry.attributes.position.array;
    const v = b.vels;
    for (let j = 0; j < v.length; j += 3) {
      // gravity on Y, drag on XZ
      v[j+1] -= _G * dt;
      v[j+0] *= 0.94;
      v[j+2] *= 0.94;
      pos[j+0] += v[j+0] * dt;
      pos[j+1] += v[j+1] * dt;
      pos[j+2] += v[j+2] * dt;
    }
    b.points.geometry.attributes.position.needsUpdate = true;
    b.points.material.opacity = Math.max(0, b.life / b.maxLife);
  }
}
