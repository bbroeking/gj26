// Lightweight smoke system — THREE.Points emitting from a 3D position,
// rising + fading. Reused per-source.
import * as THREE from 'three';

export function makeSmoke(origin, count = 40) {
  const geo = new THREE.BufferGeometry();
  const positions = new Float32Array(count * 3);
  const lifeArr = new Float32Array(count);
  const seed = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    positions[i * 3]     = origin.x + (Math.random() - 0.5) * 0.2;
    positions[i * 3 + 1] = origin.y + Math.random() * 0.5;
    positions[i * 3 + 2] = origin.z + (Math.random() - 0.5) * 0.2;
    lifeArr[i] = Math.random();
    seed[i] = Math.random();
  }
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geo.setAttribute('life', new THREE.BufferAttribute(lifeArr, 1));
  geo.setAttribute('seed', new THREE.BufferAttribute(seed, 1));

  const mat = new THREE.PointsMaterial({
    color: 0xddd5cc,
    size: 0.45,
    transparent: true,
    opacity: 0.5,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
  });
  const points = new THREE.Points(geo, mat);
  points.userData.origin = origin.clone();
  points.userData.count = count;
  return points;
}

export function updateSmoke(points, dt) {
  if (!points) return;
  const pos = points.geometry.attributes.position.array;
  const life = points.geometry.attributes.life.array;
  const seed = points.geometry.attributes.seed.array;
  const o = points.userData.origin;
  const n = points.userData.count;
  for (let i = 0; i < n; i++) {
    life[i] += dt * (0.4 + seed[i] * 0.4);
    if (life[i] >= 1) {
      // respawn near origin
      life[i] = 0;
      pos[i * 3]     = o.x + (Math.random() - 0.5) * 0.15;
      pos[i * 3 + 1] = o.y;
      pos[i * 3 + 2] = o.z + (Math.random() - 0.5) * 0.15;
    } else {
      pos[i * 3 + 1] += dt * (0.5 + seed[i] * 0.5);
      pos[i * 3]     += dt * Math.sin(life[i] * 6 + seed[i] * 10) * 0.06;
      pos[i * 3 + 2] += dt * Math.cos(life[i] * 6 + seed[i] * 10) * 0.06;
    }
  }
  points.geometry.attributes.position.needsUpdate = true;
  points.geometry.attributes.life.needsUpdate = true;
}
