// ARPG-style attack telegraphs. Draws a flat translucent shape on the
// world floor for a short window so the player has a chance to read the
// incoming hit and dodge / step out.
//
// Public API:
//   setTelegraphScene(scene)
//   spawnTileTelegraph(x, y, durationSec, opts)
//   updateTelegraphs(dt)
//   TELEGRAPH_COLORS — unified color vocabulary across all enemies
import * as THREE from 'three';

let _scene = null;
const _live = [];   // { mesh, mat, life, total }

/** Telegraph color vocabulary — see AI research notes (Sekiro/FFXIV/Hades).
 *  One color per category across the whole game so the player learns the
 *  language once instead of per-enemy.
 *    NORMAL      — single-tile melee tell (white-cream)
 *    AOE         — area attack, dodgeable (yellow-amber)
 *    PARRY_ONLY  — unblockable hit, must Riposte to negate (red)
 *    BOSS        — boss/unique attack (purple)
 */
export const TELEGRAPH_COLORS = {
  NORMAL:     0xeeddc8,
  AOE:        0xffd864,
  PARRY_ONLY: 0xc63030,
  BOSS:       0x8a3e8e,
  PULL:       0xa4b04a,   // warm vine-amber for Hedgemother's bramble pull
};

export function setTelegraphScene(scene) { _scene = scene; }

const _PLANE = new THREE.PlaneGeometry(0.95, 0.95);

/**
 * Drop a tile-flash at world tile (x, y) for `durationSec` seconds.
 * Fades in fast then out smoothly so it reads as "this is about to hit".
 *
 *   color   — hex (default normal-melee cream)
 *   y       — world Y to render at (default 0.02 — just above floor)
 */
export function spawnTileTelegraph(x, y, durationSec = 0.35, opts = {}) {
  if (!_scene) return null;
  const color = opts.color ?? TELEGRAPH_COLORS.NORMAL;
  const yWorld = opts.y ?? 0.02;
  const mat = new THREE.MeshBasicMaterial({
    color,
    transparent: true,
    opacity: 0,
    depthWrite: false,
    side: THREE.DoubleSide,
  });
  const mesh = new THREE.Mesh(_PLANE, mat);
  mesh.rotation.x = -Math.PI / 2;
  mesh.position.set(x + 0.5, yWorld, y + 0.5);
  mesh.renderOrder = 5;        // sit on top of terrain
  _scene.add(mesh);
  _live.push({ mesh, mat, life: durationSec, total: durationSec });
  return mesh;
}

export function updateTelegraphs(dt) {
  for (let i = _live.length - 1; i >= 0; i--) {
    const t = _live[i];
    t.life -= dt;
    if (t.life <= 0) {
      t.mesh.parent?.remove(t.mesh);
      t.mat.dispose();
      _live.splice(i, 1);
      continue;
    }
    const u = t.life / t.total;            // 1 → 0
    // Quick fade-in (last 80% of life) then steady — and pulse subtly.
    const inU = Math.min(1, (1 - u) / 0.18);
    const pulse = 0.55 + Math.abs(Math.sin((t.total - t.life) * 14)) * 0.25;
    t.mat.opacity = pulse * inU;
  }
}

/** Telegraph a line of tiles between (x1,y1) and (x2,y2). Both endpoints
 *  inclusive. Used by the charger archetype to paint its dash path so the
 *  player can sidestep out of the lane. */
export function spawnLineTelegraph(x1, y1, x2, y2, durationSec = 0.7, opts = {}) {
  const meshes = [];
  const dx = Math.sign(x2 - x1);
  const dy = Math.sign(y2 - y1);
  let x = x1, y = y1;
  // Walk the line — covers both axis-aligned (charger) and diagonal cases.
  while (true) {
    const m = spawnTileTelegraph(x, y, durationSec, opts);
    if (m) meshes.push(m);
    if (x === x2 && y === y2) break;
    if (x !== x2) x += dx;
    if (y !== y2) y += dy;
    if (meshes.length > 12) break;   // safety cap
  }
  return meshes;
}

/** Telegraph an N×N area centered on (cx, cy). Returns the array of
 *  meshes so callers can override material if they want to. */
export function spawnAreaTelegraph(cx, cy, radius, durationSec = 0.55, opts = {}) {
  const meshes = [];
  for (let dy = -radius; dy <= radius; dy++) {
    for (let dx = -radius; dx <= radius; dx++) {
      const m = spawnTileTelegraph(cx + dx, cy + dy, durationSec, opts);
      if (m) meshes.push(m);
    }
  }
  return meshes;
}

/** For when leaving a dungeon / death — clear all live telegraphs. */
export function clearTelegraphs() {
  for (const t of _live) {
    t.mesh.parent?.remove(t.mesh);
    t.mat.dispose();
  }
  _live.length = 0;
}
