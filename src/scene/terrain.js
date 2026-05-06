// Heightmap noise — single source of truth so the rendered terrain and the
// per-frame entity y-lookups agree.
import * as THREE from 'three';

// Cheap deterministic value noise, bilinearly interpolated.
function hash(xi, zi) {
  const v = Math.sin(xi * 12.9898 + zi * 78.233) * 43758.5453;
  return v - Math.floor(v);
}

function smooth2(x, z) {
  const xi = Math.floor(x), zi = Math.floor(z);
  const xf = x - xi, zf = z - zi;
  // smoothstep on fractional part
  const sx = xf * xf * (3 - 2 * xf);
  const sz = zf * zf * (3 - 2 * zf);
  const a = hash(xi, zi);
  const b = hash(xi + 1, zi);
  const c = hash(xi, zi + 1);
  const d = hash(xi + 1, zi + 1);
  return THREE.MathUtils.lerp(
    THREE.MathUtils.lerp(a, b, sx),
    THREE.MathUtils.lerp(c, d, sx),
    sz
  );
}

/**
 * Height in world units at world-space (x, z).
 * Two octaves of value noise: large rolling hills + small bumps.
 */
export function terrainHeightAt(x, z) {
  const big   = (smooth2(x * 0.13, z * 0.13) - 0.5) * 0.55;
  const small = (smooth2(x * 0.42, z * 0.42) - 0.5) * 0.10;
  return big + small;
}

/** Per-vertex color noise factor (0.85..1.15) — deterministic per (x,z). */
export function colorNoise(x, z) {
  return 0.85 + smooth2(x * 1.7, z * 1.7) * 0.30;
}
