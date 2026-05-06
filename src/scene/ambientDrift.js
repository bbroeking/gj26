// Ambient drifting particles — dandelion-seed wisps that float around
// the player. Pure atmosphere; cheap point cloud (one Points object,
// stable count, recycled positions). No gameplay impact.
//
// Public API:
//   setupAmbientDrift(scene, opts)
//   updateAmbientDrift(dt, player)
//   clearAmbientDrift()
import * as THREE from 'three';

let _points = null;
let _vels = null;        // Float32Array, 3 per particle
let _lives = null;       // Float32Array, 1 per particle
let _scene = null;
let _N = 0;
const _RANGE = 14;       // distance from player at which we recycle a particle
const _LIFE = 18;        // seconds before we recycle even mid-air

export function setupAmbientDrift(scene, opts = {}) {
  _scene = scene;
  _N = opts.count ?? 14;
  const geom = new THREE.BufferGeometry();
  const pos = new Float32Array(_N * 3);
  for (let i = 0; i < _N; i++) {
    pos[i*3 + 0] = (Math.random() - 0.5) * 30;
    pos[i*3 + 1] = 1.2 + Math.random() * 4.0;
    pos[i*3 + 2] = (Math.random() - 0.5) * 30;
  }
  geom.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  _vels = new Float32Array(_N * 3);
  _lives = new Float32Array(_N);
  for (let i = 0; i < _N; i++) {
    _vels[i*3 + 0] = 0.06 + Math.random() * 0.10;
    _vels[i*3 + 1] = (Math.random() - 0.5) * 0.05;
    _vels[i*3 + 2] = (Math.random() - 0.4) * 0.06;
    _lives[i] = Math.random() * _LIFE;
  }
  const mat = new THREE.PointsMaterial({
    color: 0xfff7d4,
    size: 4,
    sizeAttenuation: false,
    transparent: true,
    opacity: 0.7,
    depthWrite: false,
  });
  _points = new THREE.Points(geom, mat);
  _points.frustumCulled = false;
  scene.add(_points);
}

function _respawn(i, player) {
  const pos = _points.geometry.attributes.position.array;
  // Spawn upwind (negative X) of the player so wind drifts them across.
  const px = player ? player.pos.x : 0;
  const pz = player ? player.pos.z : 0;
  pos[i*3 + 0] = px + (Math.random() - 0.5) * 8 - _RANGE * 0.6;
  pos[i*3 + 1] = 1.2 + Math.random() * 3.5;
  pos[i*3 + 2] = pz + (Math.random() - 0.5) * 12;
  _vels[i*3 + 0] = 0.04 + Math.random() * 0.10;
  _vels[i*3 + 1] = (Math.random() - 0.5) * 0.05;
  _vels[i*3 + 2] = (Math.random() - 0.4) * 0.06;
  _lives[i] = _LIFE;
}

export function updateAmbientDrift(dt, player) {
  if (!_points) return;
  const pos = _points.geometry.attributes.position.array;
  for (let i = 0; i < _N; i++) {
    pos[i*3 + 0] += _vels[i*3 + 0] * dt * 60 * 0.05;
    // Vertical bob via sin so they shimmer; combine with vertical vel
    pos[i*3 + 1] += _vels[i*3 + 1] * dt * 60 * 0.05 + Math.sin((performance.now() + i * 137) * 0.0008) * 0.005;
    pos[i*3 + 2] += _vels[i*3 + 2] * dt * 60 * 0.05;
    _lives[i] -= dt;
    const dx = pos[i*3 + 0] - (player ? player.pos.x : 0);
    const dz = pos[i*3 + 2] - (player ? player.pos.z : 0);
    if (_lives[i] <= 0 || dx*dx + dz*dz > _RANGE * _RANGE) {
      _respawn(i, player);
    }
  }
  _points.geometry.attributes.position.needsUpdate = true;
}

export function clearAmbientDrift() {
  if (!_points) return;
  _points.parent?.remove(_points);
  _points.geometry.dispose();
  _points.material.dispose();
  _points = null;
  _vels = null;
  _lives = null;
  _scene = null;
}
