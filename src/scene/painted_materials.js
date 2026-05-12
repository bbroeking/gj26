// Painted-texture pipeline (Wind Waker / A Short Hike flavor).
//
// Bakes a 3-step lit/base/shadow ramp into per-vertex colors using each
// vertex's world-space normal vs a fixed light direction, then renders with
// MeshBasicMaterial { vertexColors: true, toneMapped: false }. Lighting is
// fixed in object space so the painterly read survives camera/scene changes.
//
// Why per-vertex vs per-pixel UV painting: the source primitives (boxes,
// spheres, cylinders, cones) all have default Blender UVs that don't share
// a coherent UV space, so a single canvas-painted texture can't drive
// shading consistently. Per-vertex sidesteps UVs entirely. Limitation: box
// faces only have ~6 unique normals, so each face gets one uniform color —
// the painted read carries on curved parts (head/hair/lanterns) but not on
// flat panels. Pair with the inverted-hull outline below to give every
// part a deliberate ink-line silhouette regardless of geometry.
//
// Tone mapping must be off on emitted materials. The renderer uses ACES
// filmic globally; without `toneMapped: false` the painted colors get
// crushed and re-saturated by the highlight roll-off.

import * as THREE from 'three';
import * as BufferGeometryUtils from 'three/addons/utils/BufferGeometryUtils.js';

// Top-front-right key light. Matches the lighting in concept art (sun from
// upper-left of frame, character facing camera).
const LIGHT_DIR = new THREE.Vector3(0.45, 1.0, 0.35).normalize();

// Cel thresholds, tuned 2026-05-06 against npc-eldra-lampwright.png:
//   hi=0.92  → only true upward-facing surfaces take the lit highlight
//             (prevents top-of-head bleach-out)
//   lo=0.18  → wide shadow band so under-faces and back-of-figure read dark
const NDOTL_HI = 0.92;
const NDOTL_LO = 0.18;

// Per-material palettes for Eldra. Lifted from the concept-art mid-tones
// rather than computed from the existing flat palette — concept tones are
// noticeably more saturated than the bevel/Phong palette since the latter
// expects the toon shader to brighten them.
const ELDRA_PALETTES = {
  Eldra_Skin:     { lit: '#f4caa4', base: '#eebd9a', shadow: '#9a7050' },
  Eldra_Hair:     { lit: '#ece4d0', base: '#dcd2bc', shadow: '#988868' },
  Eldra_Tunic:    { lit: '#d8c298', base: '#cab588', shadow: '#7a6648' },
  Eldra_Vest:     { lit: '#9a6c38', base: '#8a6030', shadow: '#3c2410' },
  Eldra_Scarf:    { lit: '#3a5868', base: '#324c5c', shadow: '#162028' },
  Eldra_Trousers: { lit: '#788c70', base: '#6c8064', shadow: '#34402c' },
  Eldra_Leather:  { lit: '#5c3c1c', base: '#503418', shadow: '#180c04' },
  Eldra_Herb:     { lit: '#506840', base: '#4c6438', shadow: '#1c2c14' },
  Eldra_Lantern:  { lit: '#a07030', base: '#946828', shadow: '#3c2410' },
  Eldra_Flame:    { unlit: '#ffe890' },
};

function bakeVertexColors(mesh, palette) {
  const geo = mesh.geometry;
  if (!geo.attributes.normal) geo.computeVertexNormals();

  const normalAttr = geo.attributes.normal;
  const count = normalAttr.count;

  const lit    = new THREE.Color(palette.lit);
  const base   = new THREE.Color(palette.base);
  const shadow = new THREE.Color(palette.shadow);

  const normalMatrix = new THREE.Matrix3().getNormalMatrix(mesh.matrixWorld);
  const tmp = new THREE.Vector3();

  const colors = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    tmp.fromBufferAttribute(normalAttr, i).applyMatrix3(normalMatrix).normalize();
    const ndotl = tmp.dot(LIGHT_DIR);

    let c;
    if (ndotl > NDOTL_HI)      c = lit;
    else if (ndotl > NDOTL_LO) c = base;
    else                       c = shadow;

    // Subtle per-vertex jitter (~±3%) so adjacent vertices break the
    // perfectly-uniform fill that pure stepped shading otherwise produces.
    const j = 0.97 + Math.random() * 0.06;

    colors[i * 3]     = c.r * j;
    colors[i * 3 + 1] = c.g * j;
    colors[i * 3 + 2] = c.b * j;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));
}

function paintMesh(mesh, palette) {
  const orig = Array.isArray(mesh.material) ? mesh.material[0] : mesh.material;

  if (palette.unlit) {
    mesh.material = new THREE.MeshBasicMaterial({
      color: new THREE.Color(palette.unlit),
      side: orig.side,
      transparent: orig.transparent,
      opacity: orig.opacity ?? 1,
      toneMapped: false,
    });
    return;
  }

  bakeVertexColors(mesh, palette);
  mesh.material = new THREE.MeshBasicMaterial({
    vertexColors: true,
    side: orig.side,
    transparent: orig.transparent,
    opacity: orig.opacity ?? 1,
    toneMapped: false,
  });
}

/** Apply painted-texture-flat materials to every mesh in `root` whose
 *  material name is keyed in `palettes`. Meshes with unmapped materials
 *  are left untouched so partial palettes still render. */
export function paintifyByMaterialName(root, palettes) {
  root.updateMatrixWorld(true);
  root.traverse(o => {
    if (!o.isMesh || !o.material) return;
    const mat = Array.isArray(o.material) ? o.material[0] : o.material;
    const palette = palettes[mat?.name];
    if (!palette) return;
    paintMesh(o, palette);
  });
}

export function paintifyEldra(root) {
  paintifyByMaterialName(root, ELDRA_PALETTES);
}

/** Apply painted-texture-flat shading to any model by deriving the lit/
 *  base/shadow palette from each material's existing `color`. No name
 *  lookup, so this works on the codex viewer for arbitrary GLBs. The
 *  derived ramp keeps base = original color and pushes lit/shadow on a
 *  warm/cool axis around it. */
export function paintifyAuto(root, opts = {}) {
  const { litMul = 1.08, shadowMul = 0.45 } = opts;
  root.updateMatrixWorld(true);
  const _base = new THREE.Color();
  const _lit = new THREE.Color();
  const _shadow = new THREE.Color();
  root.traverse(o => {
    if (!o.isMesh || !o.material) return;
    if (o.userData?.isOutlineHull) return;
    const orig = Array.isArray(o.material) ? o.material[0] : o.material;
    if (!orig) return;
    // Emissive surfaces (lantern flames etc.) stay unlit as-is — preserve
    // their bright color, no shading split.
    const isEmissive = orig.emissive && (orig.emissive.r > 0.1 || orig.emissive.g > 0.1 || orig.emissive.b > 0.1);
    if (isEmissive) {
      const baseCol = (orig.emissive && (orig.emissive.r + orig.emissive.g + orig.emissive.b) > 0.3)
        ? orig.emissive
        : (orig.color || new THREE.Color(0xffffff));
      paintMesh(o, { unlit: '#' + baseCol.getHexString() });
      return;
    }
    if (!orig.color) return;
    _base.copy(orig.color);
    _lit.copy(_base).multiplyScalar(litMul);
    // Slight warm shift on lit, slight cool shift on shadow
    _lit.r = Math.min(1, _lit.r * 1.03);
    _shadow.copy(_base).multiplyScalar(shadowMul);
    _shadow.b = Math.min(1, _shadow.b * 1.05);
    paintMesh(o, {
      lit:    '#' + _lit.getHexString(),
      base:   '#' + _base.getHexString(),
      shadow: '#' + _shadow.getHexString(),
    });
  });
}

// ----- Inverted-hull outline -----
// Renders a thin black silhouette around every painted mesh by adding a
// child mesh that uses the same geometry, pushes each vertex along its
// normal in object space, and renders back-faces only in solid color.
// Classic toon-game technique (Wind Waker, Dragon Quest XI). Object-space
// thickness so the outline scales with the model — looks correct after
// _scaleGLBToHeight without per-instance tuning.

const _outlineVS = `
  uniform float uThickness;
  void main() {
    vec3 pushed = position + normalize(normal) * uThickness;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pushed, 1.0);
  }
`;
const _outlineFS = `
  uniform vec3 uColor;
  void main() {
    gl_FragColor = vec4(uColor, 1.0);
  }
`;

function makeOutlineMaterial(color, thickness) {
  return new THREE.ShaderMaterial({
    vertexShader: _outlineVS,
    fragmentShader: _outlineFS,
    uniforms: {
      uThickness: { value: thickness },
      uColor: { value: new THREE.Color(color) },
    },
    side: THREE.BackSide,
    toneMapped: false,
  });
}

/** Mesh-name suffixes that opt OUT of the inverted-hull outline pass.
 *  Convention for surface-variation pieces (fluff bumps, fabric seams,
 *  scale plates, line accents) — they convey detail but shouldn't get
 *  their own ink line, which would re-fragment the silhouette and defeat
 *  the soft-mass read. Build scripts name detail meshes accordingly:
 *    _ruffle  — bumpy fluff (hair, beard, fur)
 *    _detail  — hard surface variation (seams, studs, scales)
 *    _line    — sketched line accents (mouth, belt edge, brow stroke) */
const OUTLINE_SKIP_PATTERN = /(?:_ruffle|_detail|_line)\b|_ruffle_|_detail_|_line_/i;

/** Add an inverted-hull outline sibling under every Mesh in `root`.
 *  Skips meshes named with `_ruffle` / `_detail` so surface-variation bumps
 *  can be added without fragmenting the silhouette. `color` defaults to a
 *  very-dark warm brown that reads as ink-line on the painted palette.
 *  `thickness` is in object-space units; tuned for ~1m chibi NPCs.
 *
 *  Most callsites should prefer `addUnifiedSilhouetteOutline` below — this
 *  per-mesh variant produces N ink lines for N parts, which fragments the
 *  silhouette. Kept for cases where per-mesh outlines are intentional. */
export function addInvertedHullOutline(root, opts = {}) {
  const { color = 0x1a0e08, thickness = 0.012 } = opts;
  const mat = makeOutlineMaterial(color, thickness);
  const meshes = [];
  root.traverse(o => {
    if (!o.isMesh || o.userData.isOutlineHull) return;
    if (OUTLINE_SKIP_PATTERN.test(o.name)) return;
    meshes.push(o);
  });
  for (const m of meshes) {
    if (!m.geometry?.attributes?.normal) m.geometry?.computeVertexNormals();
    const outline = new THREE.Mesh(m.geometry, mat);
    outline.userData.isOutlineHull = true;
    outline.castShadow = false;
    outline.receiveShadow = false;
    outline.renderOrder = (m.renderOrder || 0) + 1;
    m.add(outline);
  }
}

/** Single ink line around the union of all non-detail meshes.
 *
 *  Why this beats per-mesh outlines: a character built from many primitives
 *  produces N visible ink lines (one per primitive) under the per-mesh
 *  approach. That re-fragments the silhouette and undoes the soft-mass
 *  read that the painted-flat pipeline aims for. This pass merges every
 *  non-`_detail`/`_ruffle` mesh's geometry (with its local transform
 *  baked in) into one BufferGeometry, then renders that as a single
 *  inverted-hull. Result: one continuous ink line traces the character's
 *  outer silhouette; everything inside is communicated by painted color
 *  zones + interior detail meshes (no outlines).
 *
 *  Implementation note: each contributing geometry is cloned, transformed
 *  into the root's local frame, and stripped down to a position+normal
 *  attribute set so mergeGeometries doesn't reject mismatched attribute
 *  layouts. Indexed/non-indexed mismatch is also normalized. */
export function addUnifiedSilhouetteOutline(root, opts = {}) {
  const { color = 0x1a0e08, thickness = 0.012 } = opts;

  root.updateMatrixWorld(true);
  const rootInv = new THREE.Matrix4().copy(root.matrixWorld).invert();
  const localToRoot = new THREE.Matrix4();

  const geos = [];
  root.traverse(o => {
    if (!o.isMesh || o.userData.isOutlineHull) return;
    if (OUTLINE_SKIP_PATTERN.test(o.name)) return;
    if (!o.geometry?.attributes?.position) return;

    let g = o.geometry.clone();
    if (!g.attributes.normal) g.computeVertexNormals();
    // Strip every attribute except position+normal; mergeGeometries
    // requires identical attribute sets across inputs.
    for (const k of Object.keys(g.attributes)) {
      if (k !== 'position' && k !== 'normal') g.deleteAttribute(k);
    }
    // Normalize to non-indexed so all inputs match.
    if (g.index) g = g.toNonIndexed();
    // Bake mesh's local-to-root transform into vertex positions.
    localToRoot.copy(o.matrixWorld).premultiply(rootInv);
    g.applyMatrix4(localToRoot);
    geos.push(g);
  });

  if (geos.length === 0) return;

  const merged = BufferGeometryUtils.mergeGeometries(geos, false);
  if (!merged) return;

  const mat = makeOutlineMaterial(color, thickness);
  const outline = new THREE.Mesh(merged, mat);
  outline.userData.isOutlineHull = true;
  outline.castShadow = false;
  outline.receiveShadow = false;
  outline.renderOrder = 1;
  root.add(outline);
  return outline;
}
