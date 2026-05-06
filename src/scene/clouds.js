// Lightweight cloud layer — fuzzy white sprites high above the playable
// area. They drift slowly on the wind and wrap around the map.
import * as THREE from 'three';

function makeCloudTexture() {
  const c = document.createElement('canvas');
  c.width = c.height = 128;
  const cx = c.getContext('2d');
  // 4-blob fluffy cloud: a big center + 3 offset puffs
  const blobs = [[64, 64, 36, 1.0], [44, 70, 22, 0.9], [82, 70, 24, 0.9], [60, 50, 18, 0.85]];
  for (const [x, y, r, a] of blobs) {
    const g = cx.createRadialGradient(x, y, 1, x, y, r);
    g.addColorStop(0, `rgba(255,255,255,${a})`);
    g.addColorStop(0.6, `rgba(255,255,255,${a * 0.55})`);
    g.addColorStop(1, 'rgba(255,255,255,0)');
    cx.fillStyle = g;
    cx.beginPath();
    cx.arc(x, y, r, 0, Math.PI * 2);
    cx.fill();
  }
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

let _texCache = null;

/**
 * Spawn `count` clouds in a horizontal band above the world. Returns a
 * `{ group, update(dt) }` — call update() each frame for drift.
 */
export function spawnClouds(scene, world, count = 18) {
  if (!_texCache) _texCache = makeCloudTexture();
  const group = new THREE.Group();
  scene.add(group);
  const minY = 22, maxY = 30;
  const cols = world.tileGrid[0].length;     // map cols
  const rows = world.tileGrid.length;        // map rows
  const margin = 30;                          // spawn slightly off-map
  const wMin = -margin, wMax = cols + margin;
  const hMin = -margin, hMax = rows + margin;
  const clouds = [];
  for (let i = 0; i < count; i++) {
    const mat = new THREE.SpriteMaterial({
      map: _texCache,
      color: 0xe8eef4,             // slight blue tint so they don't read as pure white
      transparent: true,
      opacity: 0.5 + Math.random() * 0.2,
      depthWrite: false,
      fog: false,
    });
    const s = new THREE.Sprite(mat);
    const sx = 7 + Math.random() * 9;
    const sy = sx * (0.4 + Math.random() * 0.2);
    s.scale.set(sx, sy, 1);
    s.position.set(
      wMin + Math.random() * (wMax - wMin),
      minY + Math.random() * (maxY - minY),
      hMin + Math.random() * (hMax - hMin),
    );
    group.add(s);
    clouds.push({
      sprite: s,
      driftX: 0.4 + Math.random() * 0.5,    // units / sec
      driftZ: (Math.random() - 0.3) * 0.2,
    });
  }
  return {
    group,
    update(dt) {
      for (const c of clouds) {
        c.sprite.position.x += c.driftX * dt;
        c.sprite.position.z += c.driftZ * dt;
        // wrap
        if (c.sprite.position.x > wMax) c.sprite.position.x = wMin;
        if (c.sprite.position.x < wMin) c.sprite.position.x = wMax;
        if (c.sprite.position.z > hMax) c.sprite.position.z = hMin;
        if (c.sprite.position.z < hMin) c.sprite.position.z = hMax;
      }
    },
  };
}
