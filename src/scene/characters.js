// Low-poly character factories — return a THREE.Group with a `dirObj`
// reference (for facing-direction rotation).
import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import * as BufferGeometryUtils from 'three/addons/utils/BufferGeometryUtils.js';
import { CONFIG } from '../data/config.js';

// ---------- TOON SHADER ----------
// Smooth-gradient cel shader. Was a 4-step nearest-filter LUT (hard bands,
// OSRS posterised feel). Switched 2026-05-03 to a 64-step linear-filter
// ramp because the v2 NPC subdivisions were producing geometric detail the
// hard banding was hiding — every smooth surface was reading as 4 flat
// patches. Linear filter blends between samples so curved geometry shows.
// Dark floor (110) preserved so saturated material colors don't wash white.
const _toonGradient = (() => {
  const N = 64;
  const colors = new Uint8Array(N * 4);
  for (let i = 0; i < N; i++) {
    // Smoothstep from 110 (shadow) to 255 (full-lit).
    const t = i / (N - 1);
    const v = Math.round(110 + (255 - 110) * t);
    colors[i * 4 + 0] = v;
    colors[i * 4 + 1] = v;
    colors[i * 4 + 2] = v;
    colors[i * 4 + 3] = 255;
  }
  const tex = new THREE.DataTexture(colors, N, 1, THREE.RGBAFormat);
  tex.minFilter = THREE.LinearFilter;
  tex.magFilter = THREE.LinearFilter;
  tex.generateMipmaps = false;
  tex.needsUpdate = true;
  return tex;
})();

// ---------- PER-INSTANCE VARIETY ----------
// Apply random scale and per-material tint shifts to a cloned GLB so each
// spawn looks slightly different. Materials must be cloned first (they are
// shared by default after Object3D.clone(true)) so tints don't bleed across
// instances. Caller passes which material *names* to tint.
export function varyInstance(inst, opts) {
  const {
    scaleJitter = 0,
    tintTargets = [],
    hueShift    = () => 0,
    satScale    = () => 1,
    lumOffset   = () => 0,
  } = opts;

  if (scaleJitter > 0) {
    const s = 1 + (Math.random() * 2 - 1) * scaleJitter;
    inst.scale.multiplyScalar(s);
  }

  if (!tintTargets.length) return;
  const targets = new Set(tintTargets);
  const hsl = {};
  const cloned = new WeakMap();   // share a clone across meshes that point at the same material

  inst.traverse(o => {
    if (!o.isMesh || !o.material) return;
    const orig = Array.isArray(o.material) ? o.material : [o.material];
    const replaced = orig.map(m => {
      if (!m || !targets.has(m.name)) return m;
      let next = cloned.get(m);
      if (!next) {
        next = m.clone();
        if (next.color) {
          next.color.getHSL(hsl);
          hsl.h = (hsl.h + hueShift() + 1) % 1;
          hsl.s = Math.max(0, Math.min(1, hsl.s * satScale()));
          hsl.l = Math.max(0, Math.min(1, hsl.l + lumOffset()));
          next.color.setHSL(hsl.h, hsl.s, hsl.l);
        }
        cloned.set(m, next);
      }
      return next;
    });
    o.material = Array.isArray(o.material) ? replaced : replaced[0];
  });
}

/** Tinyskies-style: MeshPhongMaterial + flatShading + shininess. Gives the
 *  soft-painterly chunky-low-poly feel without any toon banding. Each face
 *  gets one diffuse value (flatShading) plus a per-pixel specular highlight
 *  (shininess), which reads as "hand-painted volume" instead of "cel". Use
 *  on entities you want softer-volumetric than the toonified default — see
 *  loadCowGLB for a side-by-side spike.
 *
 *  Optional rim light: pass `{ rim: { color, intensity, power } }` to add a
 *  Fresnel rim emission via onBeforeCompile. Drives the bright silhouette
 *  edge tinyskies uses to lift assets off the background. */
export function phongifyMaterials(root, opts = {}) {
  const { shininess = 30, rim = null, flatShading = true } = opts;
  root.traverse(o => {
    if (!o.isMesh || !o.material) return;
    const orig = Array.isArray(o.material) ? o.material : [o.material];
    const replaced = orig.map(m => {
      if (m.isMeshPhongMaterial) return m;
      if (m.isMeshBasicMaterial) return m;          // unlit surfaces stay unlit
      const pm = new THREE.MeshPhongMaterial({
        color: m.color || new THREE.Color(0xffffff),
        map: m.map || null,
        side: m.side,
        transparent: m.transparent,
        opacity: m.opacity ?? 1,
        alphaTest: m.alphaTest ?? 0,
        vertexColors: m.vertexColors === true,
        flatShading,
        shininess,
      });
      if (m.emissive && (m.emissive.r > 0 || m.emissive.g > 0 || m.emissive.b > 0)) {
        pm.emissive = m.emissive.clone();
        if (m.emissiveMap) pm.emissiveMap = m.emissiveMap;
      }
      if (rim) addRimLight(pm, rim.color, rim.intensity, rim.power);
      return pm;
    });
    o.material = Array.isArray(o.material) ? replaced : replaced[0];
  });
}

/** Tinyskies-style Fresnel rim. Brightens the silhouette of an asset by
 *  adding `rim^power * intensity * color` to outgoingLight. Hooks into the
 *  built-in Phong shader via onBeforeCompile so we don't have to author a
 *  full ShaderMaterial.
 *
 *  Implementation note: we reference `normal` (the local vec3 set up by
 *  `<normal_fragment_begin>`) rather than `vNormal` (the varying), because
 *  three.js drops `vNormal` when `flatShading: true` and derives the face
 *  normal from screen-space derivatives. `normal` is correct for both
 *  flat and smooth shading. */
export function addRimLight(material, color = 0xffeebb, intensity = 0.25, power = 3.5) {
  const c = new THREE.Color(color);
  material.userData.rimLight = { color: c, intensity, power };
  material.onBeforeCompile = (shader) => {
    shader.uniforms.uRimColor     = { value: c };
    shader.uniforms.uRimIntensity = { value: intensity };
    shader.uniforms.uRimPower     = { value: power };
    shader.fragmentShader = shader.fragmentShader
      .replace('#include <common>',
        `#include <common>
        uniform vec3 uRimColor;
        uniform float uRimIntensity;
        uniform float uRimPower;`)
      .replace('#include <opaque_fragment>',
        `// Rim emission: bright at silhouette edges where the view ray
        // grazes the surface. The local vec3 named normal (set up by
        // normal_fragment_begin) works for both flatShading (derived
        // from dFdx/dFdy) and smooth (sampled from vNormal). The
        // vViewPosition varying is negated so normalize(it) points
        // toward the camera.
        float _rim = pow(1.0 - clamp(dot(normalize(normal), normalize(vViewPosition)), 0.0, 1.0), uRimPower);
        outgoingLight += uRimColor * (_rim * uRimIntensity);
        #include <opaque_fragment>`);
  };
  material.needsUpdate = true;
}

/** Default in-game shading. Historically this was MeshToonMaterial (4-band
 *  cel) — kept the export name so every loadXGLB callsite still works.
 *  After the tinyskies feel-check, the project's default is now flat-shaded
 *  Phong + soft specular + Fresnel rim, with a midpoint-subdivision pass
 *  that quadruples triangle count so flat facets read as smaller painterly
 *  brush-strokes instead of obvious blocks.
 *
 *  Per-entity tuning: pass an opts object to override defaults (or call
 *  phongifyMaterials directly + subdivideMeshes separately for finer
 *  control). subdivide=0 disables the geometry pass for dense assets that
 *  already have enough triangles. */
export function toonifyMaterials(root, opts = {}) {
  // Pipeline (Stardew/Death's-Door soft painterly):
  //   1. Subdivide (1 pass / 4× tris) so curved surfaces have enough
  //      density for normal-smoothing to read. Cheap.
  //   2. Smooth normals — mergeVertices welds duplicate verts, then
  //      toCreasedNormals leaves edges sharper than `creaseAngle`
  //      flat (cube edges stay crisp) but blends gentle curves.
  //   3. Phong + smooth shading + rim. Smoothed vertex normals carry
  //      the lighting so the surface reads continuous, not faceted.
  //
  // Was a 2-pass subdivide + flat-shaded approach (16× tris, blocky look).
  // Per playtest "we need it to be smoother": flat shading shows facets
  // no matter how dense the geometry, so we switched off flatShading and
  // used normal-smoothing instead — much cheaper, much smoother.
  const {
    subdivide = 1,
    smoothNormals = true,
    creaseAngle = Math.PI / 6,    // 30° — keeps cube edges sharp, blends curves
    shininess = 45,
    rim = null,
  } = opts;
  if (subdivide > 0) subdivideMeshes(root, subdivide);
  if (smoothNormals) smoothMeshNormals(root, creaseAngle);
  phongifyMaterials(root, {
    flatShading: false,
    shininess,
    rim: rim || { color: 0xffeebb, intensity: 0.38, power: 3.0 },
  });
}

/** Weld duplicate vertices and recompute normals as a *creased smooth*
 *  field — gentle surfaces blend, sharp edges (above creaseAngle) stay
 *  flat. Skips SkinnedMesh because vertex welding breaks skin weights. */
export function smoothMeshNormals(root, creaseAngle = Math.PI / 6) {
  root.traverse(o => {
    if (!o.isMesh || o.isSkinnedMesh) return;
    if (o.userData?.skipSmoothNormals) return;
    const g = o.geometry;
    if (!g?.attributes?.position) return;
    try {
      // Weld first so faces that *should* share a vertex actually do.
      // Then crease-aware normal recompute.
      const merged = BufferGeometryUtils.mergeVertices(g);
      BufferGeometryUtils.toCreasedNormals(merged, creaseAngle);
      o.geometry = merged;
    } catch (err) {
      // Geometry without indexable attributes (point clouds etc.) just
      // skip — leave the original alone.
      console.warn('[smoothNormals] skipped one mesh:', err.message);
    }
  });
}

/** Linear midpoint subdivision: each triangle → 4 smaller triangles, same
 *  surface shape. With flatShading: true, smaller facets read as smoother
 *  painterly gradients instead of chunky cubist blocks — same identity,
 *  more visual breath. Skips SkinnedMesh because rebuilding the geometry
 *  drops the skin weights. Indexed geometry is converted to non-indexed
 *  first so we can write triangles directly without de-duping midpoints
 *  (cheap; the visual cost of vertex duplication is zero for flat shading
 *  since we discard vertex normals anyway). */
export function subdivideMeshes(root, iterations = 1) {
  if (iterations <= 0) return;
  root.traverse(o => {
    if (!o.isMesh || o.isSkinnedMesh) return;
    if (o.userData?.skipSubdivide) return;
    let g = o.geometry;
    for (let i = 0; i < iterations; i++) g = subdivideTrianglesOnce(g);
    o.geometry = g;
  });
}

function subdivideTrianglesOnce(geom) {
  const flat = geom.index ? geom.toNonIndexed() : geom;
  const pos = flat.attributes.position;
  const uv = flat.attributes.uv;
  const col = flat.attributes.color;
  const triCount = (pos.count / 3) | 0;
  const outPos = new Float32Array(triCount * 4 * 3 * 3);
  const outUv  = uv  ? new Float32Array(triCount * 4 * 3 * 2) : null;
  const outCol = col ? new Float32Array(triCount * 4 * 3 * 3) : null;
  let pi = 0, ui = 0, ci = 0;

  for (let i = 0; i < triCount; i++) {
    const a = i * 9;
    // corners
    const a0=pos.array[a+0], a1=pos.array[a+1], a2=pos.array[a+2];
    const b0=pos.array[a+3], b1=pos.array[a+4], b2=pos.array[a+5];
    const c0=pos.array[a+6], c1=pos.array[a+7], c2=pos.array[a+8];
    // midpoints
    const ab0=(a0+b0)*0.5, ab1=(a1+b1)*0.5, ab2=(a2+b2)*0.5;
    const bc0=(b0+c0)*0.5, bc1=(b1+c1)*0.5, bc2=(b2+c2)*0.5;
    const ca0=(c0+a0)*0.5, ca1=(c1+a1)*0.5, ca2=(c2+a2)*0.5;
    // 4 new triangles: A-AB-CA, B-BC-AB, C-CA-BC, AB-BC-CA
    const tri = (...v) => { for (const x of v) outPos[pi++] = x; };
    tri(a0,a1,a2, ab0,ab1,ab2, ca0,ca1,ca2);
    tri(b0,b1,b2, bc0,bc1,bc2, ab0,ab1,ab2);
    tri(c0,c1,c2, ca0,ca1,ca2, bc0,bc1,bc2);
    tri(ab0,ab1,ab2, bc0,bc1,bc2, ca0,ca1,ca2);

    if (uv) {
      const u = i * 6;
      const ax=uv.array[u+0], ay=uv.array[u+1];
      const bx=uv.array[u+2], by=uv.array[u+3];
      const cx=uv.array[u+4], cy=uv.array[u+5];
      const abx=(ax+bx)*0.5, aby=(ay+by)*0.5;
      const bcx=(bx+cx)*0.5, bcy=(by+cy)*0.5;
      const cax=(cx+ax)*0.5, cay=(cy+ay)*0.5;
      const tu = (...v) => { for (const x of v) outUv[ui++] = x; };
      tu(ax,ay, abx,aby, cax,cay);
      tu(bx,by, bcx,bcy, abx,aby);
      tu(cx,cy, cax,cay, bcx,bcy);
      tu(abx,aby, bcx,bcy, cax,cay);
    }
    if (col) {
      const k = i * 9;
      const ar=col.array[k+0], ag=col.array[k+1], ab=col.array[k+2];
      const br=col.array[k+3], bg=col.array[k+4], bb=col.array[k+5];
      const cr=col.array[k+6], cg=col.array[k+7], cb=col.array[k+8];
      const abr=(ar+br)*0.5, abg=(ag+bg)*0.5, abb=(ab+bb)*0.5;
      const bcr=(br+cr)*0.5, bcg=(bg+cg)*0.5, bcb=(bb+cb)*0.5;
      const car=(cr+ar)*0.5, cag=(cg+ag)*0.5, cab=(cb+ab)*0.5;
      const tc = (...v) => { for (const x of v) outCol[ci++] = x; };
      tc(ar,ag,ab, abr,abg,abb, car,cag,cab);
      tc(br,bg,bb, bcr,bcg,bcb, abr,abg,abb);
      tc(cr,cg,cb, car,cag,cab, bcr,bcg,bcb);
      tc(abr,abg,abb, bcr,bcg,bcb, car,cag,cab);
    }
  }
  const out = new THREE.BufferGeometry();
  out.setAttribute('position', new THREE.BufferAttribute(outPos, 3));
  if (outUv)  out.setAttribute('uv',    new THREE.BufferAttribute(outUv, 2));
  if (outCol) out.setAttribute('color', new THREE.BufferAttribute(outCol, 3));
  out.computeVertexNormals();   // overwritten by flatShading at draw, but safe
  return out;
}

/** Original 4-band cel-toon shader. Kept on a separate name so anything
 *  that explicitly wants the old look (codex viewer's "toon" radio uses
 *  its own `toonifyForViewer`, but a future variant might) can reach it. */
export function toonifyMaterialsCel(root) {
  root.traverse(o => {
    if (!o.isMesh || !o.material) return;
    const orig = Array.isArray(o.material) ? o.material : [o.material];
    const replaced = orig.map(m => {
      if (m.isMeshToonMaterial) return m;
      if (m.isMeshBasicMaterial) return m;
      const tm = new THREE.MeshToonMaterial({
        color: m.color || new THREE.Color(0xffffff),
        map: m.map || null,
        gradientMap: _toonGradient,
        side: m.side,
        transparent: m.transparent,
        opacity: m.opacity ?? 1,
        alphaTest: m.alphaTest ?? 0,
        vertexColors: m.vertexColors === true,
      });
      if (m.emissive && (m.emissive.r > 0 || m.emissive.g > 0 || m.emissive.b > 0)) {
        tm.emissive = m.emissive.clone();
        if (m.emissiveMap) tm.emissiveMap = m.emissiveMap;
      }
      return tm;
    });
    o.material = Array.isArray(o.material) ? replaced : replaced[0];
  });
}

// ---------- GLB asset cache ----------
// Loaded once and cloned per-spawn. If a load is in flight, callers await
// the same promise instead of triggering a second download.
const _glb = {
  cow: null, cowPromise: null,
  knight: null, knightPromise: null,
  goblin: null, goblinPromise: null,
  cook: null, cookPromise: null,
  oak: null, oakPromise: null,
  castle: null, castlePromise: null,
  forge: null, forgePromise: null,
  cottage: null, cottagePromise: null,
  well: null, wellPromise: null,
  bank: null, bankPromise: null,
  signpost: null, signpostPromise: null,
  chicken: null, chickenPromise: null,
  hare: null, harePromise: null,
  boar: null, boarPromise: null,
  hedgemother: null, hedgemotherPromise: null,
  equipment: new Map(),         // name → loaded scene
  equipmentPromises: new Map(), // name → in-flight promise
};

function _loadOnce(key, promiseKey, url, processScene) {
  if (_glb[key]) return Promise.resolve(_glb[key]);
  if (_glb[promiseKey]) return _glb[promiseKey];
  const loader = new GLTFLoader();
  _glb[promiseKey] = loader.loadAsync(url).then(g => {
    _glb[key] = g.scene;
    g.scene.traverse(o => {
      if (o.isMesh) { o.castShadow = true; o.receiveShadow = false; }
    });
    toonifyMaterials(g.scene);
    if (processScene) processScene(g.scene);
    return g.scene;
  }).catch(err => {
    console.warn(`${url} failed to load:`, err);
    _glb[promiseKey] = null;
    return null;
  });
  return _glb[promiseKey];
}

export function loadGoblinV2GLB(url = 'models/goblin_v2.glb') {
  return _loadOnce('goblin_v2', 'goblin_v2_promise', url);
}
export function loadGoblinGLB(url = 'models/goblin_v2.glb') {
  return _loadOnce('goblin', 'goblinPromise', url);
}
export function loadBrambleImpGLB(url = 'models/bramble_imp_v3.glb') {
  return _loadOnce('brambleImp', 'brambleImpPromise', url);
}
export function loadHedgewightGLB(url = 'models/hedgewight_v2.glb') {
  return _loadOnce('hedgewight', 'hedgewightPromise', url);
}
export function loadChartmakerStoneGLB(url = 'models/chartmaker_stone_v2.glb') {
  return _loadOnce('chartmakerStone', 'chartmakerStonePromise', url);
}
export function loadBurrowBoarGLB(url = 'models/burrow_boar_v2.glb') {
  return _loadOnce('burrowBoar', 'burrowBoarPromise', url);
}
export function loadWolfAlphaGLB(url = 'models/wolf_alpha_v2.glb') {
  return _loadOnce('wolfAlpha', 'wolfAlphaPromise', url);
}

export function loadSkitterlingGLB(url = 'models/skitterling.glb') {
  return _loadOnce('skitterling', 'skitterlingPromise', url);
}
export function loadMarshRatGLB(url = 'models/marsh_rat.glb') {
  return _loadOnce('marshRat', 'marshRatPromise', url);
}
export function loadIronGobGLB(url = 'models/iron_gob.glb') {
  return _loadOnce('ironGob', 'ironGobPromise', url);
}
export function loadTuskerSowGLB(url = 'models/tusker_sow.glb') {
  return _loadOnce('tuskerSow', 'tuskerSowPromise', url);
}
export function loadBrambleArcherGLB(url = 'models/bramble_archer.glb') {
  return _loadOnce('brambleArcher', 'brambleArcherPromise', url);
}
export function loadBrambleChargerGLB(url = 'models/bramble_charger.glb') {
  return _loadOnce('brambleCharger', 'brambleChargerPromise', url);
}
export function loadHodGLB(url = 'models/npc_hod.glb') {
  return _loadOnce('npcHod', 'npcHodPromise', url);
}
export function loadMaudGLB(url = 'models/npc_maud.glb') {
  return _loadOnce('npcMaud', 'npcMaudPromise', url);
}
export function loadQuillGLB(url = 'models/npc_quill.glb') {
  return _loadOnce('npcQuill', 'npcQuillPromise', url);
}
export function loadWitheringGLB(url = 'models/npc_withering.glb') {
  return _loadOnce('npcWithering', 'npcWitheringPromise', url);
}
export function loadEldraGLB(url = 'models/npc_eldra.glb') {
  return _loadOnce('npcEldra', 'npcEldraPromise', url);
}
export function loadCricketGLB(url = 'models/npc_cricket.glb') {
  return _loadOnce('npcCricket', 'npcCricketPromise', url);
}
export function loadPellGLB(url = 'models/npc_pell.glb') {
  return _loadOnce('npcPell', 'npcPellPromise', url);
}
export function loadOnywynGLB(url = 'models/npc_onywyn.glb') {
  return _loadOnce('npcOnywyn', 'npcOnywynPromise', url);
}
// build*Mesh functions are defined further down with their per-character
// animation config (cadence, lean, locked-arm). Keeping a single source
// of truth — the duplicate stubs that used to live here are gone.

// ----- Quest item GLBs -----
// Each maps to an item id in src/data/items.js. groundLoot.js consults
// these via _glb when spawning a drop and renders the GLB instead of
// the default colored box.
export function loadApprenticesHammerGLB(url = 'models/apprentices_hammer.glb') {
  return _loadOnce('item_apprentices_hammer', 'apprenticesHammerPromise', url);
}
export function loadHealingDraughtGLB(url = 'models/healing_draught.glb') {
  return _loadOnce('item_healing_draught', 'healingDraughtPromise', url);
}
export function loadFalconsWhistleGLB(url = 'models/falcons_whistle.glb') {
  return _loadOnce('item_falcons_whistle', 'falconsWhistlePromise', url);
}
export function loadBrambleResinGLB(url = 'models/bramble_resin.glb') {
  return _loadOnce('item_bramble_resin', 'brambleResinPromise', url);
}
export function loadWhickerharesFootGLB(url = 'models/whickerhares_foot.glb') {
  return _loadOnce('item_whickerhares_foot', 'whickerharesFootPromise', url);
}
export function loadThornCrownGLB(url = 'models/thorn_crown.glb') {
  return _loadOnce('item_thorn_crown', 'thornCrownPromise', url);
}
export function loadPantryStewGLB(url = 'models/pantry_stew.glb') {
  return _loadOnce('item_pantry_stew', 'pantryStewPromise', url);
}
export function loadHodsAnvilTokenGLB(url = 'models/hods_anvil_token.glb') {
  return _loadOnce('item_hods_anvil_token', 'hodsAnvilTokenPromise', url);
}
export function loadWitheredBrambleGLB(url = 'models/withered_bramble.glb') {
  return _loadOnce('witheredBramble', 'witheredBramblePromise', url);
}
export function loadPracticeDummyGLB(url = 'models/practice_dummy.glb') {
  return _loadOnce('practiceDummy', 'practiceDummyPromise', url);
}
export function loadMemorialLanternGLB(url = 'models/memorial_lantern.glb') {
  return _loadOnce('memorialLantern', 'memorialLanternPromise', url);
}
export function loadDryingRackGLB(url = 'models/drying_rack.glb') {
  return _loadOnce('dryingRack', 'dryingRackPromise', url);
}
export function loadFalconerPerchGLB(url = 'models/falconer_perch.glb') {
  return _loadOnce('falconerPerch', 'falconerPerchPromise', url);
}

export function buildPracticeDummyMesh() {
  if (!_glb.practiceDummy) return null;
  const g = new THREE.Group();
  const inst = _glb.practiceDummy.clone(true);
  inst.scale.setScalar(1.0);
  g.add(inst);
  return shadowizeAll(g);
}
export function buildMemorialLanternMesh() {
  if (!_glb.memorialLantern) return null;
  const g = new THREE.Group();
  const inst = _glb.memorialLantern.clone(true);
  inst.scale.setScalar(0.85);
  g.add(inst);
  return shadowizeAll(g);
}
export function buildDryingRackMesh() {
  if (!_glb.dryingRack) return null;
  const g = new THREE.Group();
  const inst = _glb.dryingRack.clone(true);
  inst.scale.setScalar(0.9);
  g.add(inst);
  return shadowizeAll(g);
}
export function buildFalconerPerchMesh() {
  if (!_glb.falconerPerch) return null;
  const g = new THREE.Group();
  const inst = _glb.falconerPerch.clone(true);
  inst.scale.setScalar(0.95);
  g.add(inst);
  return shadowizeAll(g);
}

/** Build a withered-bramble harvest node (drops bramble_resin). Returns
 *  the GLB if loaded, null otherwise so the caller can fall back to a
 *  procedural mesh. */
export function buildWitheredBrambleMesh() {
  if (!_glb.witheredBramble) return null;
  const g = new THREE.Group();
  const inst = _glb.witheredBramble.clone(true);
  inst.scale.setScalar(0.85);
  g.add(inst);
  return shadowizeAll(g);
}

/** Build a Group for a quest-item GLB by item id. Returns null if no
 *  GLB has been loaded for that id (caller falls back to the default
 *  ground-loot box). */
export function buildItemGLBMesh(itemId) {
  const key = 'item_' + itemId;
  const src = _glb[key];
  if (!src) return null;
  const g = new THREE.Group();
  const inst = src.clone(true);
  inst.scale.setScalar(0.6);
  g.add(inst);
  return shadowizeAll(g);
}

// Tier 3 inventory GLBs (weapons/shields/armor). The file slugs use a
// `weapon_*` / `shield_*` / `armor_*` prefix; the item ids in src/data/items.js
// don't. This helper bridges them so buildItemGLBMesh(itemId) finds the cached scene.
const _TIER3_ITEM_FILES = {
  brindle_sword: 'weapon_brindle_sword',
  brindle_axe: 'weapon_brindle_axe',
  brindle_dagger: 'weapon_brindle_dagger',
  brindle_pickaxe: 'weapon_brindle_pickaxe',
  bogiron_sword: 'weapon_bogiron_sword',
  bogiron_axe: 'weapon_bogiron_axe',
  bogiron_dagger: 'weapon_bogiron_dagger',
  bogiron_pickaxe: 'weapon_bogiron_pickaxe',
  cinderbloom_sword: 'weapon_cinderbloom_sword',
  cinderbloom_axe: 'weapon_cinderbloom_axe',
  cinderbloom_dagger: 'weapon_cinderbloom_dagger',
  cinderbloom_pickaxe: 'weapon_cinderbloom_pickaxe',
  wooden_shield: 'shield_wooden',
  bogiron_shield: 'shield_bogiron',
  cinderbloom_shield: 'shield_cinderbloom',
  leather_body: 'armor_leather',
  bogiron_cuirass: 'armor_bogiron_cuirass',
  cinderbloom_plate: 'armor_cinderbloom_plate',
  cinderbloom_helm: 'armor_cinderbloom_helm',
};

export function loadTier3ItemGLBs() {
  return Promise.all(
    Object.entries(_TIER3_ITEM_FILES).map(([itemId, fileSlug]) =>
      _loadOnce('item_' + itemId, 'item_' + itemId + '_promise', `models/${fileSlug}.glb`)
    )
  );
}
export function loadCookGLB(url = 'models/cook.glb') {
  return _loadOnce('cook', 'cookPromise', url);
}
export function loadOakGLB(url = 'models/oak.glb') {
  return _loadOnce('oak', 'oakPromise', url);
}
export function loadCastleGLB(url = 'models/castle.glb') {
  return _loadOnce('castle', 'castlePromise', url);
}
export function loadForgeGLB(url = 'models/forge_v2.glb') {
  return _loadOnce('forge', 'forgePromise', url);
}
export function loadCottageGLB(url = 'models/cottage_v3.glb') {
  return _loadOnce('cottage', 'cottagePromise', url);
}
export function loadWellGLB(url = 'models/well_v2.glb') {
  return _loadOnce('well', 'wellPromise', url);
}
export function loadBankGLB(url = 'models/bank_v2.glb') {
  return _loadOnce('bank', 'bankPromise', url);
}
export function loadSignpostGLB(url = 'models/signpost.glb') {
  return _loadOnce('signpost', 'signpostPromise', url);
}
export function loadChickenGLB(url = 'models/chicken_v2.glb') {
  return _loadOnce('chicken', 'chickenPromise', url);
}
export function loadHareGLB(url = 'models/hare_v2.glb') {
  return _loadOnce('hare', 'harePromise', url);
}
export function loadBoarGLB(url = 'models/boar_v2.glb') {
  return _loadOnce('boar', 'boarPromise', url);
}
export function loadHedgemotherGLB(url = 'models/hedgemother_v2.glb') {
  return _loadOnce('hedgemother', 'hedgemotherPromise', url);
}

export function buildHedgemotherMesh() {
  const g = new THREE.Group();
  if (_glb.hedgemother) {
    const inst = _glb.hedgemother.clone(true);
    inst.scale.setScalar(0.85);   // bigger than the player on purpose
    g.add(inst);
    const parts = {};
    inst.traverse(o => { if (['Body','Head','Tail','Leg_FL','Leg_FR','Leg_BL','Leg_BR'].includes(o.name)) parts[o.name] = o; });
    g.userData.parts = parts;
    g.userData.isGLBHedgemother = true;
  }
  return shadowizeAll(g);
}

const _BIPED_RIG_PARTS = ['Body','Head','Arm_L','Arm_R','Leg_L','Leg_R'];
const _QUAD_RIG_PARTS  = ['Body','Head','Tail','Leg_FL','Leg_FR','Leg_BL','Leg_BR'];

function _buildEnemyFromGLB(glbKey, { scale = 0.85, rig = 'biped' } = {}) {
  const src = _glb[glbKey];
  if (!src) return null;
  const g = new THREE.Group();
  const inst = src.clone(true);
  inst.scale.setScalar(scale);
  g.add(inst);
  const wanted = new Set(rig === 'quad' ? _QUAD_RIG_PARTS : _BIPED_RIG_PARTS);
  const parts = {};
  inst.traverse(o => { if (wanted.has(o.name)) parts[o.name] = o; });
  g.userData.parts = parts;
  g.userData.glbKey = glbKey;
  g.userData.rig = rig;
  return shadowizeAll(g);
}

export function buildSkitterlingMesh()    { return _buildEnemyFromGLB('skitterling',    { rig: 'biped' }); }
export function buildMarshRatMesh()       { return _buildEnemyFromGLB('marshRat',       { rig: 'quad'  }); }
export function buildIronGobMesh()        { return _buildEnemyFromGLB('ironGob',        { rig: 'biped' }); }
export function buildTuskerSowMesh()      { return _buildEnemyFromGLB('tuskerSow',      { rig: 'quad'  }); }
export function buildBrambleArcherMesh()  { return _buildEnemyFromGLB('brambleArcher',  { rig: 'biped' }); }
export function buildBrambleChargerMesh() { return _buildEnemyFromGLB('brambleCharger', { rig: 'quad'  }); }

/** Chartmaker site monolith. Returns the GLB if loaded, otherwise null
 *  so the caller can keep its procedural fallback up. */
export function buildChartmakerStoneMesh() {
  if (!_glb.chartmakerStone) return null;
  const g = new THREE.Group();
  const inst = _glb.chartmakerStone.clone(true);
  inst.scale.setScalar(0.85);
  g.add(inst);
  return shadowizeAll(g);
}

/** Burrow Boar — boss-tier boar with leaf mantle + glowing red eyes. */
export function buildBurrowBoarMesh() {
  const g = new THREE.Group();
  if (_glb.burrowBoar) {
    const inst = _glb.burrowBoar.clone(true);
    inst.scale.setScalar(0.85);     // boss-scale (player is ~0.55)
    g.add(inst);
    const parts = {};
    inst.traverse(o => { if (['Body','Head','Tail','Leg_FL','Leg_FR','Leg_BL','Leg_BR'].includes(o.name)) parts[o.name] = o; });
    g.userData.parts = parts;
    g.userData.isGLBBurrowBoar = true;
  }
  return shadowizeAll(g);
}

/** Generic NPC builder — picks a GLB key and returns a Group. Used by
 *  Hod, Maud, etc. Returns null if the GLB hasn't loaded yet so the caller
 *  can fall back to its existing placeholder mesh (e.g. cook.glb).
 *
 *  Stamps the rig parts onto `g.userData.parts` so animateGLBKnight can
 *  animate the NPC. Optional opts:
 *    - lockArm    'L'|'R'|'both' — that arm is holding an item, no swing
 *    - cadenceMul 0.7..1.2       — slower for elders, faster for teens
 *    - leanMul    0.5..2.0       — extra forward stoop for elder NPCs
 */
// Canonical adult-human height in world units. 1 unit ≈ 1m per project
// convention, but we render chunky-cozy at 1.0u (slightly under-scale
// vs realism) so rooms read at a comfortable top-down camera distance.
export const HUMAN_HEIGHT = 1.0;
const _bboxScratch = new THREE.Box3();

/** Set inst.scale uniformly so its rendered bbox height equals targetH. */
function _scaleGLBToHeight(inst, targetH) {
  inst.scale.setScalar(1);
  inst.updateMatrixWorld(true);
  _bboxScratch.setFromObject(inst);
  const nativeH = _bboxScratch.max.y - _bboxScratch.min.y;
  if (nativeH > 0.01) inst.scale.setScalar(targetH / nativeH);
}

function _buildNpcGroup(glbKey, _legacyScale = 0.55, opts = {}) {
  const src = _glb[glbKey];
  if (!src) return null;
  const g = new THREE.Group();
  const inst = src.clone(true);
  // `_legacyScale` is ignored — kept for API compat with old callsites.
  // All humans normalize to HUMAN_HEIGHT × heightMul (default 1.0). Pass
  // opts.heightMul=1.1 for slightly taller imposing characters, 0.9 for
  // hunched/shorter folk. Don't reach for old absolute-scale numbers.
  const heightMul = opts.heightMul ?? 1.0;
  _scaleGLBToHeight(inst, HUMAN_HEIGHT * heightMul);
  g.add(inst);
  const parts = {};
  inst.traverse(o => {
    if (['Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R'].includes(o.name)) {
      parts[o.name] = o;
    }
  });
  g.userData.parts = parts;
  if (opts.lockArm)    g.userData.lockArm    = opts.lockArm;
  if (opts.cadenceMul) g.userData.cadenceMul = opts.cadenceMul;
  if (opts.leanMul)    g.userData.leanMul    = opts.leanMul;
  return shadowizeAll(g);
}

// Per-character animation config matched to whatever the NPC is holding +
// their age/gait. Keeps held-item arms from looking like they're swinging
// through the prop.
export function buildEldraMesh()    { return _buildNpcGroup('npcEldra',    0.55, { lockArm: 'R', cadenceMul: 0.7, leanMul: 1.6 }); }
export function buildCricketMesh()  { return _buildNpcGroup('npcCricket',  0.55, { lockArm: 'R', cadenceMul: 1.2 }); }
export function buildPellMesh()     { return _buildNpcGroup('npcPell',     0.55, { lockArm: 'L', cadenceMul: 0.85, leanMul: 1.2 }); }
export function buildOnywynMesh()   { return _buildNpcGroup('npcOnywyn',   0.55, { lockArm: 'R', cadenceMul: 0.7,  leanMul: 1.8 }); }
export function buildHodMesh()      { return _buildNpcGroup('npcHod',      0.55, { lockArm: 'R' }); }
export function buildMaudMesh()     { return _buildNpcGroup('npcMaud',     0.55, { lockArm: 'R', cadenceMul: 0.9, leanMul: 1.2 }); }
export function buildQuillMesh()    { return _buildNpcGroup('npcQuill',    0.55, { lockArm: 'both' }); }
export function buildWitheringMesh(){ return _buildNpcGroup('npcWithering',0.60, { lockArm: 'L', cadenceMul: 0.85, leanMul: 1.1, heightMul: 1.1 }); }

/** Wolf Alpha — boss-tier hedgewight variant with glowing blue eyes. */
export function buildWolfAlphaMesh() {
  const g = new THREE.Group();
  if (_glb.wolfAlpha) {
    const inst = _glb.wolfAlpha.clone(true);
    inst.scale.setScalar(0.78);
    g.add(inst);
    const parts = {};
    inst.traverse(o => { if (['Body','Head','Tail','Leg_FL','Leg_FR','Leg_BL','Leg_BR'].includes(o.name)) parts[o.name] = o; });
    g.userData.parts = parts;
    g.userData.isGLBWolfAlpha = true;
  }
  return shadowizeAll(g);
}

export function buildHedgewightMesh() {
  const g = new THREE.Group();
  if (_glb.hedgewight) {
    const inst = _glb.hedgewight.clone(true);
    inst.scale.setScalar(0.55);
    g.add(inst);
    const parts = {};
    inst.traverse(o => { if (['Body','Head','Tail','Leg_FL','Leg_FR','Leg_BL','Leg_BR'].includes(o.name)) parts[o.name] = o; });
    g.userData.parts = parts;
    g.userData.isGLBHedgewight = true;
    varyInstance(inst, {
      scaleJitter: 0.10,
      tintTargets: ['WolfDark', 'WolfLight'],
      hueShift: () => (Math.random() - 0.5) * 0.05,
      satScale: () => 0.80 + Math.random() * 0.30,
      lumOffset:() => (Math.random() - 0.5) * 0.06,
    });
    g.rotation.y = Math.random() * Math.PI * 2;
  }
  return shadowizeAll(g);
}

export function buildBoarMesh() {
  const g = new THREE.Group();
  if (_glb.boar) {
    const inst = _glb.boar.clone(true);
    inst.scale.setScalar(0.55);
    g.add(inst);
    const parts = {};
    inst.traverse(o => { if (['Body','Head','Tail','Leg_FL','Leg_FR','Leg_BL','Leg_BR'].includes(o.name)) parts[o.name] = o; });
    g.userData.parts = parts;
    g.userData.isGLBBoar = true;
    varyInstance(inst, {
      scaleJitter: 0.10,
      tintTargets: ['BoarDark', 'BoarMid', 'BoarLight'],
      hueShift: () => (Math.random() - 0.5) * 0.04,
      satScale: () => 0.85 + Math.random() * 0.30,
      lumOffset:() => (Math.random() - 0.5) * 0.06,
    });
    g.rotation.y = Math.random() * Math.PI * 2;
  }
  return shadowizeAll(g);
}

export function buildChickenMesh() {
  const g = new THREE.Group();
  if (_glb.chicken) {
    const inst = _glb.chicken.clone(true);
    inst.scale.setScalar(0.55);
    g.add(inst);
    const parts = {};
    inst.traverse(o => { if (['Body','Head','Wing_L','Wing_R','Leg_L','Leg_R','Tail'].includes(o.name)) parts[o.name] = o; });
    g.userData.parts = parts;
    g.userData.isGLBChicken = true;
    // each chicken slightly different in tint and scale
    varyInstance(inst, {
      scaleJitter: 0.10,
      tintTargets: ['ChickenWhite', 'ChickenShadow'],
      hueShift: () => (Math.random() - 0.5) * 0.04,
      satScale: () => 0.85 + Math.random() * 0.30,
      lumOffset:() => (Math.random() - 0.5) * 0.08,
    });
    g.rotation.y = Math.random() * Math.PI * 2;
  }
  return shadowizeAll(g);
}

export function buildHareMesh() {
  const g = new THREE.Group();
  if (_glb.hare) {
    const inst = _glb.hare.clone(true);
    inst.scale.setScalar(0.55);
    g.add(inst);
    const parts = {};
    inst.traverse(o => { if (['Body','Head','Ear_L','Ear_R','Tail','Leg_FL','Leg_FR','Leg_BL','Leg_BR'].includes(o.name)) parts[o.name] = o; });
    g.userData.parts = parts;
    g.userData.isGLBHare = true;
    varyInstance(inst, {
      scaleJitter: 0.12,
      tintTargets: ['HareTan', 'HareLight', 'HareShadow'],
      hueShift: () => (Math.random() - 0.5) * 0.08,
      satScale: () => 0.85 + Math.random() * 0.30,
      lumOffset:() => (Math.random() - 0.5) * 0.06,
    });
    g.rotation.y = Math.random() * Math.PI * 2;
  }
  return shadowizeAll(g);
}

export function loadCowGLB(url = 'models/cow.glb') {
  if (_glb.cow) return Promise.resolve(_glb.cow);
  if (_glb.cowPromise) return _glb.cowPromise;
  const loader = new GLTFLoader();
  _glb.cowPromise = loader.loadAsync(url).then(g => {
    _glb.cow = g.scene;
    g.scene.traverse(o => {
      if (o.isMesh) { o.castShadow = true; o.receiveShadow = false; }
    });
    toonifyMaterials(g.scene);
    return g.scene;
  }).catch(err => {
    console.warn('cow.glb failed to load, using procedural cow:', err);
    _glb.cowPromise = null;
    return null;
  });
  return _glb.cowPromise;
}

export function loadKnightBase(url = 'models/knight_base.glb') {
  if (_glb.knight) return Promise.resolve(_glb.knight);
  if (_glb.knightPromise) return _glb.knightPromise;
  const loader = new GLTFLoader();
  _glb.knightPromise = loader.loadAsync(url).then(g => {
    _glb.knight = g.scene;
    g.scene.traverse(o => {
      if (o.isMesh) { o.castShadow = true; o.receiveShadow = false; }
    });
    toonifyMaterials(g.scene);
    return g.scene;
  }).catch(err => {
    console.warn('knight_base.glb failed to load:', err);
    _glb.knightPromise = null;
    return null;
  });
  return _glb.knightPromise;
}

// ---- v2 archetypes — Knight / Druid / Wanderer ----
// Each archetype is a separate GLB with the standard humanoid hierarchy
// (Body / Head / Arm_L / Arm_R / Leg_L / Leg_R). The procedural rig
// drives the named groups, so animation is shared across archetypes.
// Archetype loaders — point at the latest checkpoint of each.
// knight_v5 / druid_v3 / wanderer_v3 are the current "best".
// Older versions stay on disk for codex comparison.
export function loadKnightV2GLB(url = 'models/knight_v5.glb') {
  return _loadOnce('knight_v5', 'knight_v5_promise', url);
}
export function loadDruidV2GLB(url = 'models/druid_v3.glb') {
  return _loadOnce('druid_v3', 'druid_v3_promise', url);
}
export function loadWandererV2GLB(url = 'models/wanderer_v3.glb') {
  return _loadOnce('wanderer_v3', 'wanderer_v3_promise', url);
}
export function loadKnightGoldGLB(url = 'models/knight_gold.glb') {
  return _loadOnce('knight_gold', 'knight_gold_promise', url);
}
export function loadDruidDarkGLB(url = 'models/druid_dark.glb') {
  return _loadOnce('druid_dark', 'druid_dark_promise', url);
}
export function loadWandererBardGLB(url = 'models/wanderer_bard.glb') {
  return _loadOnce('wanderer_bard', 'wanderer_bard_promise', url);
}
export function loadArcherGLB(url = 'models/archer.glb') {
  return _loadOnce('archer', 'archer_promise', url);
}

/** Load all v2 archetype GLBs in parallel — base + color variants. */
export function loadAllArchetypes() {
  return Promise.all([
    loadKnightV2GLB(), loadDruidV2GLB(), loadWandererV2GLB(),
    loadKnightGoldGLB(), loadDruidDarkGLB(), loadWandererBardGLB(),
    loadArcherGLB(),
  ]);
}

/** Build a player mesh for the given archetype. The new GLBs (knight_v3,
 *  druid_v2_redesign, wanderer_v1) are authored with the procedural-creature
 *  recipe: each rig empty (Body/Head/Arm_L/Arm_R/Leg_L/Leg_R) is at its
 *  correct world pivot, child meshes were placed at world positions before
 *  parenting (no parent_inverse trap), so animation rotating the empties
 *  drives the visual parts correctly. */
export function buildArchetypeMesh(archetype, loadout = []) {
  // Pick GLB based on archetype name. Bard and unknown fall back to knight.
  const glbKey = ({
    Knight:      'knight_v5',
    SunKnight:   'knight_gold',
    Druid:       'druid_v3',
    NightDruid:  'druid_dark',
    Archer:      'archer',
    Bard:        'wanderer_bard',
  })[archetype] || 'knight_v5';
  const src = _glb[glbKey];
  if (!src) {
    // GLB still loading or missing — fall back to the working classic knight
    const g = buildKnightMesh(loadout);
    if (g) g.userData.archetype = archetype || 'Knight';
    return g;
  }
  const g = new THREE.Group();
  const inst = src.clone(true);
  // Normalize to canonical human height so the player matches the
  // village NPCs regardless of which archetype GLB is loaded.
  _scaleGLBToHeight(inst, HUMAN_HEIGHT);
  g.add(inst);
  // Find named rig parts so the procedural animation can drive them.
  const wantedParts = new Set(['Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R']);
  const parts = {};
  inst.traverse(o => {
    if (wantedParts.has(o.name)) parts[o.name] = o;
  });
  g.userData.parts = parts;
  g.userData.isGLBKnight = true;     // existing animation pipeline reads this flag
  g.userData.archetype = archetype || 'Knight';
  return shadowizeAll(g);
}

export function loadEquipment(name, url = `models/equipment/${name}.glb`) {
  if (_glb.equipment.has(name)) return Promise.resolve(_glb.equipment.get(name));
  if (_glb.equipmentPromises.has(name)) return _glb.equipmentPromises.get(name);
  const loader = new GLTFLoader();
  const p = loader.loadAsync(url).then(g => {
    _glb.equipment.set(name, g.scene);
    g.scene.traverse(o => {
      if (o.isMesh) { o.castShadow = true; o.receiveShadow = false; }
    });
    toonifyMaterials(g.scene);
    return g.scene;
  }).catch(err => {
    console.warn(`equipment ${name}.glb failed to load:`, err);
    _glb.equipmentPromises.delete(name);
    return null;
  });
  _glb.equipmentPromises.set(name, p);
  return p;
}

// Map from equipment GLB name → slot anchor it attaches to on the base.
export const EQUIPMENT_SLOT = {
  helmet_centurion:  'head',
  breastplate_olive: 'chest',
  pauldrons_gold:    'chest',
  belt_leather:      'hip',
  tunic_skirt_cream: 'hip',
  boots_brown:       'root',
  sword_short:       'hand_R',
  shield_laurel:     'hand_L',
  cape_red:          'back',
};

/** Parent equipmentScene's clone under the matching slot empty.
 *  Returns the cloned instance (so callers can swap later). */
export function equip(knightGroup, slotName, equipmentScene) {
  const slots = knightGroup.userData?.slots;
  if (!slots) return null;
  const slot = slots[`slot_${slotName}`];
  if (!slot) {
    console.warn(`equip: slot_${slotName} not found on knight`);
    return null;
  }
  const inst = equipmentScene.clone(true);
  // Each equipment GLB is exported with the object position at its slot
  // anchor's world coords (so the meshes line up during preview). We zero
  // the cloned root before parenting so it sits exactly on the anchor.
  inst.position.set(0, 0, 0);
  inst.traverse(o => {
    if (o.isMesh) { o.castShadow = true; o.receiveShadow = false; }
  });
  slot.add(inst);
  return inst;
}

/** Build a knight Group from the loaded GLB and a list of equipment names. */
export function buildKnightMesh(loadout = []) {
  if (!_glb.knight) return null;     // caller must preload

  const g = new THREE.Group();
  const inst = _glb.knight.clone(true);
  // Player normalizes to canonical human height — no more being smaller
  // than every NPC because of an old hand-tuned 0.42 scale.
  _scaleGLBToHeight(inst, HUMAN_HEIGHT);
  g.add(inst);

  // Find named rig parts + slot anchors
  const wantedParts = new Set(['Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R']);
  const parts = {};
  const slots = {};
  inst.traverse(o => {
    if (wantedParts.has(o.name)) parts[o.name] = o;
    if (o.name && o.name.startsWith('slot_')) slots[o.name] = o;
  });
  g.userData.parts = parts;
  g.userData.slots = slots;
  g.userData.isGLBKnight = true;

  for (const name of loadout) {
    const eqScene = _glb.equipment.get(name);
    if (!eqScene) continue;
    equip(g, EQUIPMENT_SLOT[name] || 'root', eqScene);
  }
  return shadowizeAll(g);
}

// ---------- GEOMETRY HELPERS ----------
// RoundedBox keeps the silhouette of a box but adds a chamfered edge so
// nothing reads as 100% Lego. Cheap (a handful of extra triangles).
function rbox(w, h, d, radius = 0.05, segments = 2) {
  return new RoundedBoxGeometry(w, h, d, segments, Math.min(radius, w/2 - 0.01, h/2 - 0.01, d/2 - 0.01));
}
// Smooth capsule for limbs/arms — radius + length, plenty of segments.
function caps(radius, length) {
  return new THREE.CapsuleGeometry(radius, length, 4, 8);
}
// Smooth-shaded material variant for organic body parts.
function smat(color, opts = {}) {
  // strip PBR-only props that MeshToonMaterial doesn't accept
  const { roughness, metalness, flatShading, ...rest } = opts;
  return new THREE.MeshToonMaterial({
    color, gradientMap: _toonGradient,
    ...rest,
  });
}

const C = CONFIG.colors;

function mat(color, opts = {}) {
  const { roughness, metalness, flatShading, ...rest } = opts;
  return new THREE.MeshToonMaterial({
    color, gradientMap: _toonGradient,
    ...rest,
  });
}

/** Recursively opt every mesh in the group into shadows. */
function shadowizeAll(group, { castShadow = true, receiveShadow = false } = {}) {
  group.traverse(o => {
    if (o.isMesh) {
      o.castShadow = castShadow;
      o.receiveShadow = receiveShadow;
    }
  });
  return group;
}

// ---------- PLAYER (red plumed knight) ----------
// Capsule limbs + rounded-box torso/head — keeps the chunky proportions but
// rounds the silhouette so it doesn't read as Lego. Named children let
// animation code address parts directly.
export function buildPlayerMesh() {
  const g = new THREE.Group();

  // legs — capsule from hip to ankle; pivot at hip so rotation.x swings.
  function leg(side) {
    const pivot = new THREE.Group();
    pivot.position.set(0.12 * side, 0.42, 0);
    const seg = new THREE.Mesh(caps(0.09, 0.22), smat(C.pants));
    seg.position.set(0, -0.21, 0);
    pivot.add(seg);
    return pivot;
  }
  const lLeg = leg(-1); lLeg.name = 'lLeg'; g.add(lLeg);
  const rLeg = leg(+1); rLeg.name = 'rLeg'; g.add(rLeg);

  // body — rounded tunic with subtle chamfer
  const body = new THREE.Mesh(rbox(0.5, 0.45, 0.32, 0.08), smat(C.tunic));
  body.position.set(0, 0.65, 0);
  body.name = 'body';
  g.add(body);

  // cape — pivoted at the shoulders, hangs down behind the body. The
  // animation system rotates it via .rotation.x so it drags during walks.
  const cape = new THREE.Group();
  cape.position.set(0, 0.92, -0.16);    // shoulder pivot, slightly behind
  const capeMesh = new THREE.Mesh(
    new THREE.PlaneGeometry(0.5, 0.65, 1, 3),
    new THREE.MeshStandardMaterial({
      color: 0x6c1f1f,
      roughness: 0.9,
      side: THREE.DoubleSide,
      flatShading: false,
    })
  );
  capeMesh.position.set(0, -0.32, 0);   // hangs from pivot
  cape.add(capeMesh);
  cape.name = 'cape';
  g.add(cape);

  // arms — capsule, pivot at shoulder
  function arm(side) {
    const pivot = new THREE.Group();
    pivot.position.set(0.27 * side, 0.85, 0);
    const seg = new THREE.Mesh(caps(0.07, 0.22), smat(C.tunic));
    seg.position.set(0, -0.21, 0);
    pivot.add(seg);
    const hand = new THREE.Mesh(
      new THREE.SphereGeometry(0.075, 8, 6),
      smat(C.skin));
    hand.position.set(0, -0.4, 0);
    pivot.add(hand);
    return pivot;
  }
  const lArm = arm(-1); lArm.name = 'lArm'; g.add(lArm);
  const rArm = arm(+1); rArm.name = 'rArm'; g.add(rArm);

  // pauldrons — gray armor caps over each shoulder, slight metallic sheen
  function pauldron(side) {
    const m = new THREE.Mesh(
      new THREE.SphereGeometry(0.13, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2),
      smat(0x88888a, { metalness: 0.5, roughness: 0.5 })
    );
    m.position.set(0.27 * side, 0.86, 0);
    m.scale.set(1.0, 0.7, 1.0);
    return m;
  }
  g.add(pauldron(-1));
  g.add(pauldron(+1));

  // gold belt — thin rounded slab
  const belt = new THREE.Mesh(
    rbox(0.54, 0.07, 0.34, 0.025),
    smat(0xd4af37, { metalness: 0.7, roughness: 0.35 }));
  belt.position.set(0, 0.4, 0);
  belt.name = 'belt';
  g.add(belt);

  // head — sphere'd cube for friendliness
  const head = new THREE.Mesh(rbox(0.32, 0.32, 0.32, 0.08), smat(C.skin));
  head.position.set(0, 1.04, 0);
  head.name = 'head';
  g.add(head);

  // face — eye dots + mouth crescent on the front of the head
  const eyeMat = new THREE.MeshBasicMaterial({ color: 0x1a1a1a });
  const lEye = new THREE.Mesh(new THREE.SphereGeometry(0.022, 8, 6), eyeMat);
  lEye.position.set(-0.07, 0, 0.165);
  head.add(lEye);
  const rEye = new THREE.Mesh(new THREE.SphereGeometry(0.022, 8, 6), eyeMat);
  rEye.position.set(0.07, 0, 0.165);
  head.add(rEye);
  // mouth — slim flat box, slightly forward
  const mouth = new THREE.Mesh(
    new THREE.BoxGeometry(0.08, 0.012, 0.005),
    new THREE.MeshBasicMaterial({ color: 0x4a2418 })
  );
  mouth.position.set(0, -0.07, 0.166);
  head.add(mouth);

  // helmet — rounded lid + slim brim
  const helmet = new THREE.Mesh(rbox(0.36, 0.14, 0.36, 0.06), smat(C.helmet));
  helmet.position.set(0, 1.27, 0);
  helmet.name = 'helmet';
  g.add(helmet);
  const brim = new THREE.Mesh(
    new THREE.CylinderGeometry(0.22, 0.22, 0.04, 16),
    smat(0x6e6e76));
  brim.position.set(0, 1.19, 0);
  brim.name = 'brim';
  g.add(brim);

  // red plume on top — slightly taller, smooth cone
  const plume = new THREE.Mesh(
    new THREE.ConeGeometry(0.08, 0.26, 8),
    smat(C.plume));
  plume.position.set(0, 1.5, 0);
  plume.name = 'plume';
  g.add(plume);

  // sword (held in right hand). Pivot at hilt so .rotation.z swings the blade.
  const sword = new THREE.Group();
  const blade = new THREE.Mesh(
    rbox(0.045, 0.42, 0.04, 0.012),
    smat(0xd4d4dc, { metalness: 0.8, roughness: 0.32 }));
  blade.position.set(0, 0.21, 0);
  const guard = new THREE.Mesh(
    rbox(0.18, 0.045, 0.05, 0.018),
    smat(0xd4af37, { metalness: 0.6, roughness: 0.4 }));
  const grip = new THREE.Mesh(
    new THREE.CylinderGeometry(0.022, 0.022, 0.1, 8),
    smat(0x5a3a1a));
  grip.position.set(0, -0.07, 0);
  sword.add(blade, guard, grip);
  sword.position.set(0.28, 0.55, 0);
  sword.rotation.z = 0.1;
  sword.name = 'sword';
  g.add(sword);

  return shadowizeAll(g);
}

// ---------- COW ----------
export function buildCowMesh() {
  // Prefer the Blender-authored GLB if it has been preloaded; clone so each
  // cow has its own transforms. Falls through to the procedural build if the
  // asset isn't ready (or failed to load).
  if (_glb.cow) {
    const g = new THREE.Group();
    const inst = _glb.cow.clone(true);
    inst.scale.setScalar(0.55);
    g.add(inst);
    const parts = {};
    const wanted = new Set(['Body', 'Head', 'Leg_FL', 'Leg_FR', 'Leg_BL', 'Leg_BR', 'Tail']);
    inst.traverse(o => { if (wanted.has(o.name)) parts[o.name] = o; });
    g.userData.parts = parts;
    g.userData.isGLBCow = true;

    // Per-instance variety so the herd doesn't read as identical clones.
    // Cows: ±10% scale, slight body-tint shift, randomized facing.
    varyInstance(inst, {
      scaleJitter: 0.10,
      tintTargets: ['CowWhite', 'CowBlack'],
      hueShift:    () => (Math.random() - 0.5) * 0.04,
      satScale:    () => 0.85 + Math.random() * 0.30,
      lumOffset:   () => (Math.random() - 0.5) * 0.06,
    });
    g.rotation.y = Math.random() * Math.PI * 2;

    return shadowizeAll(g);
  }

  const g = new THREE.Group();

  // body — rounded barrel
  const body = new THREE.Mesh(rbox(0.85, 0.5, 0.45, 0.18), smat(C.cow_white));
  body.position.set(0, 0.55, 0);
  g.add(body);

  // black spots — flatter rounded slabs that hug the body
  for (const [x, y, z] of [[-0.25, 0.7, 0.22], [0.18, 0.55, 0.23], [-0.15, 0.38, 0.23], [0.3, 0.7, -0.22]]) {
    const spot = new THREE.Mesh(
      rbox(0.2, 0.18, 0.03, 0.06),
      smat(C.cow_spot));
    spot.position.set(x, y, z);
    g.add(spot);
  }

  // head — rounded
  const head = new THREE.Mesh(rbox(0.3, 0.3, 0.3, 0.08), smat(C.cow_white));
  head.position.set(0.5, 0.55, 0);
  g.add(head);

  // snout — soft pink
  const snout = new THREE.Mesh(rbox(0.14, 0.16, 0.16, 0.05), smat(0xf0a8b0));
  snout.position.set(0.6, 0.5, 0);
  g.add(snout);

  // horns — smooth cones
  for (const z of [-0.15, 0.15]) {
    const horn = new THREE.Mesh(
      new THREE.ConeGeometry(0.04, 0.12, 8),
      smat(0xd0c8a0));
    horn.position.set(0.5, 0.78, z);
    g.add(horn);
  }

  // legs — smooth cylinders
  for (const [x, z] of [[-0.3, -0.18], [-0.3, 0.18], [0.3, -0.18], [0.3, 0.18]]) {
    const leg = new THREE.Mesh(
      new THREE.CylinderGeometry(0.05, 0.06, 0.3, 8),
      smat(C.cow_white));
    leg.position.set(x, 0.15, z);
    g.add(leg);
  }

  return shadowizeAll(g);
}

// ---------- GOBLIN / BRAMBLE-IMP ----------
// Bramble-imp is the Bramblewood rename of "goblin". Engine identifier stays
// `kind: 'goblin'` so animation rigs + spawn factories don't churn; the visible
// mesh and label flip to bramble-imp once the GLB has loaded.
export function buildGoblinMesh() {
  // Prefer the new procedural goblin_v2 (clean rig, no floats) → fall back to
  // bramble-imp GLB → legacy goblin → procedural. We keep all paths so the
  // game stays playable while assets load.
  const useV2 = !!_glb.goblin_v2;
  const src = _glb.goblin_v2 || _glb.brambleImp || _glb.goblin;
  if (src) {
    const g = new THREE.Group();
    const inst = src.clone(true);
    inst.scale.setScalar(useV2 ? 0.85 : 0.55);   // v2 was authored to game-scale already
    g.add(inst);
    const parts = {};
    const wanted = new Set(['Body','Head','Arm_L','Arm_R','Leg_L','Leg_R','Club']);
    inst.traverse(o => { if (wanted.has(o.name)) parts[o.name] = o; });
    g.userData.parts = parts;
    g.userData.isGLBGoblin = true;

    // Per-instance variety: ±15% scale, big skin-hue shift so some goblins
    // look mossier and others sickly-yellow. Cloth tint also wobbles.
    varyInstance(inst, {
      scaleJitter: 0.15,
      tintTargets: ['Skin', 'SkinDark', 'SkinLight'],
      hueShift:    () => (Math.random() - 0.5) * 0.10,
      satScale:    () => 0.80 + Math.random() * 0.40,
      lumOffset:   () => (Math.random() - 0.5) * 0.08,
    });
    varyInstance(inst, {
      scaleJitter: 0,    // already applied above; only tint here
      tintTargets: ['Cloth', 'Tunic', 'TunicDark'],
      hueShift:    () => (Math.random() - 0.5) * 0.04,
      satScale:    () => 0.90 + Math.random() * 0.20,
      lumOffset:   () => (Math.random() - 0.5) * 0.04,
    });

    return shadowizeAll(g);
  }

  const g = new THREE.Group();

  // body — rounded green tunic
  const body = new THREE.Mesh(rbox(0.4, 0.4, 0.3, 0.1), smat(0x4ab07c));
  body.position.set(0, 0.55, 0);
  g.add(body);

  // green legs — capsules
  const lLeg = new THREE.Mesh(caps(0.07, 0.16), smat(0x2c6e4d));
  lLeg.position.set(-0.1, 0.18, 0); g.add(lLeg);
  const rLeg = new THREE.Mesh(caps(0.07, 0.16), smat(0x2c6e4d));
  rLeg.position.set(0.1, 0.18, 0); g.add(rLeg);

  // green head — rounded with a subtle squash
  const head = new THREE.Mesh(rbox(0.32, 0.3, 0.3, 0.1), smat(0x4ab07c));
  head.position.set(0, 0.96, 0);
  g.add(head);

  // pointed ears — smooth cones
  for (const x of [-0.2, 0.2]) {
    const ear = new THREE.Mesh(
      new THREE.ConeGeometry(0.05, 0.16, 8),
      smat(0x4ab07c));
    ear.position.set(x, 1.04, 0);
    ear.rotation.z = x < 0 ? Math.PI / 3.5 : -Math.PI / 3.5;
    g.add(ear);
  }

  // glowing yellow eyes — small spheres for friendlier read
  for (const x of [-0.06, 0.06]) {
    const eye = new THREE.Mesh(
      new THREE.SphereGeometry(0.025, 8, 6),
      new THREE.MeshBasicMaterial({ color: 0xffd84a }));
    eye.position.set(x, 0.99, 0.16);
    g.add(eye);
  }

  // crude wooden club — slimmer rounded shaft
  const club = new THREE.Mesh(
    new THREE.CylinderGeometry(0.035, 0.05, 0.32, 8),
    smat(0x6b431f));
  club.position.set(0.26, 0.55, 0.05);
  club.rotation.z = -0.3;
  g.add(club);

  return shadowizeAll(g);
}

// ---------- COOK NPC ----------
export function buildCookMesh() {
  // Maud Pennycress is the cook in Bramblewood; prefer her dedicated GLB
  // when loaded, then fall back to the legacy generic cook GLB, then
  // procedural so the village always has someone at the hearth.
  const src = _glb.npcMaud || _glb.cook;
  if (src) {
    const g = new THREE.Group();
    const inst = src.clone(true);
    _scaleGLBToHeight(inst, HUMAN_HEIGHT);
    g.add(inst);
    g.userData.isGLBCook = true;
    return shadowizeAll(g);
  }
  const g = new THREE.Group();

  // body (white robe)
  const body = new THREE.Mesh(
    new THREE.CylinderGeometry(0.32, 0.36, 0.7, 8),
    mat(C.cook_white));
  body.position.set(0, 0.55, 0);
  g.add(body);

  // red apron stripe
  const apron = new THREE.Mesh(
    new THREE.BoxGeometry(0.5, 0.18, 0.5),
    mat(C.cook_apron));
  apron.position.set(0, 0.5, 0);
  g.add(apron);

  // head — rounded
  const head = new THREE.Mesh(rbox(0.3, 0.3, 0.3, 0.08), smat(C.cook_skin));
  head.position.set(0, 1.05, 0);
  g.add(head);

  // tall white chef hat (stacked cylinders)
  const hat1 = new THREE.Mesh(
    new THREE.CylinderGeometry(0.2, 0.2, 0.18, 8),
    mat(C.cook_white));
  hat1.position.set(0, 1.32, 0);
  g.add(hat1);
  const hat2 = new THREE.Mesh(
    new THREE.SphereGeometry(0.25, 8, 6),
    mat(C.cook_white));
  hat2.position.set(0, 1.55, 0);
  g.add(hat2);

  return shadowizeAll(g);
}

// ---------- TREES — three variants picked by srand ----------
export function buildOakMesh() {
  if (_glb.oak) {
    const g = new THREE.Group();
    const inst = _glb.oak.clone(true);
    inst.scale.setScalar(0.85);    // tree GLB is sized to ~2u tall; scale to fit world
    g.add(inst);
    return shadowizeAll(g);
  }
  const g = new THREE.Group();
  const trunk = new THREE.Mesh(
    new THREE.CylinderGeometry(0.16, 0.2, 0.9, 7),
    mat(0x6b431f, { roughness: 0.95 }));
  trunk.position.set(0, 0.45, 0);
  g.add(trunk);
  const c1 = new THREE.Mesh(
    new THREE.SphereGeometry(0.7, 8, 6),
    mat(0x4a8a3a, { flatShading: true, roughness: 1.0 }));
  c1.position.set(0, 1.3, 0);
  g.add(c1);
  const c2 = new THREE.Mesh(
    new THREE.SphereGeometry(0.5, 8, 6),
    mat(0x6ba03d, { flatShading: true, roughness: 1.0 }));
  c2.position.set(0.2, 1.6, -0.1);
  g.add(c2);
  const c3 = new THREE.Mesh(
    new THREE.SphereGeometry(0.45, 8, 6),
    mat(0x3a8a3a, { flatShading: true, roughness: 1.0 }));
  c3.position.set(-0.25, 1.5, 0.15);
  g.add(c3);
  return shadowizeAll(g);
}

export function buildPineMesh() {
  const g = new THREE.Group();
  const trunk = new THREE.Mesh(
    new THREE.CylinderGeometry(0.1, 0.13, 1.2, 6),
    mat(0x4a2c14, { roughness: 0.95 }));
  trunk.position.set(0, 0.6, 0);
  g.add(trunk);
  // stacked decreasing cones
  for (let i = 0; i < 4; i++) {
    const r = 0.65 - i * 0.13;
    const h = 0.55;
    const cone = new THREE.Mesh(
      new THREE.ConeGeometry(r, h, 7),
      mat(0x2c5a2a, { roughness: 1.0 }));
    cone.position.set(0, 0.95 + i * 0.32, 0);
    g.add(cone);
  }
  return shadowizeAll(g);
}

export function buildDeadTreeMesh() {
  const g = new THREE.Group();
  const trunk = new THREE.Mesh(
    new THREE.CylinderGeometry(0.1, 0.14, 1.0, 6),
    mat(0x6b5040, { roughness: 1.0 }));
  trunk.position.set(0, 0.5, 0);
  g.add(trunk);
  // a couple of bare branches
  const b1 = new THREE.Mesh(
    new THREE.CylinderGeometry(0.04, 0.06, 0.5, 5),
    mat(0x6b5040));
  b1.rotation.z = -0.7;
  b1.position.set(0.18, 1.0, 0);
  g.add(b1);
  const b2 = new THREE.Mesh(
    new THREE.CylinderGeometry(0.04, 0.06, 0.45, 5),
    mat(0x6b5040));
  b2.rotation.z = 0.6;
  b2.position.set(-0.16, 0.95, 0);
  g.add(b2);
  return shadowizeAll(g);
}

// Backwards-compat alias used by world.js (will be replaced by variant picker).
export function buildTreeMesh() { return buildOakMesh(); }

/**
 * Procedural low-poly falcon — small companion bird.
 * Named children Wing_L, Wing_R, Body, Head, Tail so the per-frame animator
 * can flap the wings. Total ~80 polys.
 */
export function buildFalconMesh() {
  const grp = new THREE.Group();
  const bodyMat = mat(0x6b4a2c, { roughness: 0.9, flatShading: true });
  const bellyMat = mat(0xcdb89a, { roughness: 0.9, flatShading: true });
  const beakMat = mat(0xf2cc55, { roughness: 0.7, flatShading: true });
  const eyeMat = mat(0x101010, { roughness: 0.6, flatShading: true });

  // Body — squashed ico
  const body = new THREE.Mesh(new THREE.IcosahedronGeometry(0.10, 0), bodyMat);
  body.scale.set(1.2, 0.85, 1.6);
  body.name = 'Body';
  grp.add(body);

  // Belly — lighter underside cube
  const belly = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.06, 0.18), bellyMat);
  belly.position.y = -0.04;
  grp.add(belly);

  // Head — slightly forward + up
  const head = new THREE.Mesh(new THREE.IcosahedronGeometry(0.07, 0), bodyMat);
  head.position.set(0, 0.06, -0.12);
  head.name = 'Head';
  grp.add(head);

  // Beak — small yellow cube tapering forward
  const beak = new THREE.Mesh(new THREE.BoxGeometry(0.025, 0.025, 0.06), beakMat);
  beak.position.set(0, 0.04, -0.20);
  grp.add(beak);

  // 2 eyes
  for (const x of [-0.025, 0.025]) {
    const e = new THREE.Mesh(new THREE.BoxGeometry(0.018, 0.018, 0.018), eyeMat);
    e.position.set(x, 0.075, -0.165);
    grp.add(e);
  }

  // Wings — wide flat planes pivoted at shoulder. Named for animation.
  for (const side of [-1, 1]) {
    const wingGeo = new THREE.PlaneGeometry(0.28, 0.16);
    wingGeo.translate(side * 0.14, 0, 0);  // shoulder at origin, wing extends out
    const wing = new THREE.Mesh(wingGeo, bodyMat);
    wing.material = bodyMat.clone();
    wing.material.side = THREE.DoubleSide;
    wing.name = side < 0 ? 'Wing_L' : 'Wing_R';
    wing.rotation.x = Math.PI / 2;  // make horizontal
    wing.position.y = 0.02;
    grp.add(wing);
  }

  // Tail — small angled cube extending backward
  const tail = new THREE.Mesh(new THREE.BoxGeometry(0.10, 0.02, 0.10), bodyMat);
  tail.position.set(0, 0, 0.14);
  tail.name = 'Tail';
  grp.add(tail);

  // Tag for the per-frame animator
  grp.userData = {
    isFalcon: true,
    parts: { Body: body, Head: head, Tail: tail,
             Wing_L: grp.getObjectByName('Wing_L'),
             Wing_R: grp.getObjectByName('Wing_R') },
    flapPhase: 0,
  };

  return shadowizeAll(grp);
}

// ---------- DECORATIONS ----------
export function buildRockCluster() {
  const g = new THREE.Group();
  const sizes = [0.35, 0.28, 0.22];
  const positions = [[0, 0, 0], [0.35, 0, -0.1], [-0.2, 0, 0.25]];
  for (let i = 0; i < 3; i++) {
    const r = sizes[i];
    const rock = new THREE.Mesh(
      new THREE.DodecahedronGeometry(r, 0),
      mat(0x88847e, { roughness: 0.95 }));
    rock.position.set(positions[i][0], r * 0.5, positions[i][2]);
    rock.rotation.set(Math.random(), Math.random(), Math.random());
    g.add(rock);
  }
  return shadowizeAll(g);
}

export function buildBush() {
  // Three overlapping smooth-shaded spheres of varying greens.
  const g = new THREE.Group();
  const greens = [0x3a7a2a, 0x4a8a3a, 0x6ba03d];
  const offsets = [[0, 0, 0], [0.18, 0.06, -0.05], [-0.14, 0.04, 0.12]];
  const sizes = [0.28, 0.22, 0.20];
  for (let i = 0; i < 3; i++) {
    const m = new THREE.Mesh(
      new THREE.SphereGeometry(sizes[i], 7, 5),
      smat(greens[i], { roughness: 1.0 })
    );
    m.position.set(offsets[i][0], sizes[i] * 0.9 + offsets[i][1], offsets[i][2]);
    g.add(m);
  }
  return shadowizeAll(g);
}

export function buildMushroom() {
  const g = new THREE.Group();
  const stem = new THREE.Mesh(
    new THREE.CylinderGeometry(0.05, 0.06, 0.18, 6),
    mat(0xeee4c8, { roughness: 0.9 }));
  stem.position.y = 0.09;
  g.add(stem);
  const cap = new THREE.Mesh(
    new THREE.SphereGeometry(0.13, 8, 5, 0, Math.PI * 2, 0, Math.PI / 2),
    mat(0xc0392b, { roughness: 0.9 }));
  cap.position.y = 0.18;
  g.add(cap);
  // white spots
  for (let i = 0; i < 3; i++) {
    const a = (i / 3) * Math.PI * 2;
    const dot = new THREE.Mesh(
      new THREE.SphereGeometry(0.025, 4, 3),
      mat(0xffffff));
    dot.position.set(Math.cos(a) * 0.07, 0.22, Math.sin(a) * 0.07);
    g.add(dot);
  }
  return shadowizeAll(g);
}

// ---------- FLOWERS (placed via InstancedMesh, see world.js) ----------
// Returns { stemGeo, headGeo, stemMat, headMat } for caller to build instances.
export function makeFlowerAssets() {
  const stemGeo = new THREE.CylinderGeometry(0.012, 0.012, 0.16, 4);
  stemGeo.translate(0, 0.08, 0);
  const stemMat = new THREE.MeshStandardMaterial({
    color: 0x4a7a2f, roughness: 1.0,
  });
  const headGeo = new THREE.SphereGeometry(0.05, 8, 6);
  headGeo.translate(0, 0.18, 0);
  const headMatRed    = new THREE.MeshStandardMaterial({ color: 0xc63030, roughness: 0.85 });
  const headMatYellow = new THREE.MeshStandardMaterial({ color: 0xf2c64a, roughness: 0.85 });
  const headMatPink   = new THREE.MeshStandardMaterial({ color: 0xe07ac0, roughness: 0.85 });
  return { stemGeo, headGeo, stemMat, headMatRed, headMatYellow, headMatPink };
}

// ---------- FENCE — single segment (post + 2 rails) ----------
export function buildFenceSegment() {
  const g = new THREE.Group();
  const post = new THREE.Mesh(
    new THREE.CylinderGeometry(0.045, 0.05, 0.55, 6),
    smat(0x6b431f, { roughness: 0.95 })
  );
  post.position.y = 0.275;
  g.add(post);
  // 2 rails extending +x; world.js will orient/duplicate
  for (const yy of [0.18, 0.42]) {
    const rail = new THREE.Mesh(
      new THREE.BoxGeometry(0.95, 0.05, 0.05),
      smat(0x8a5a2a, { roughness: 0.9 })
    );
    rail.position.set(0.5, yy, 0);   // rail extends rightward, post at 0
    g.add(rail);
  }
  return shadowizeAll(g);
}

// ---------- LILY PAD ----------
export function buildLilyPad() {
  const g = new THREE.Group();
  const pad = new THREE.Mesh(
    new THREE.CircleGeometry(0.32, 12),
    smat(0x3a8a4a, { roughness: 0.85, side: THREE.DoubleSide })
  );
  pad.rotation.x = -Math.PI / 2;
  pad.position.y = 0.04;
  g.add(pad);
  // tiny pink flower on some pads (caller decides whether to add)
  const flower = new THREE.Mesh(
    new THREE.SphereGeometry(0.06, 8, 6),
    smat(0xe07ac0, { roughness: 0.8 })
  );
  flower.position.set(0.05, 0.1, 0);
  flower.name = 'flower';
  g.add(flower);
  return g;
}

// ---------- LANTERN — emissive box on a hanging bracket ----------
export function buildLantern() {
  const g = new THREE.Group();
  const post = new THREE.Mesh(
    new THREE.CylinderGeometry(0.04, 0.04, 1.4, 6),
    smat(0x4a2c14, { roughness: 0.95 })
  );
  post.position.y = 0.7;
  g.add(post);
  // arm extending out
  const arm = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.025, 0.3, 4),
    smat(0x4a2c14, { roughness: 0.95 })
  );
  arm.rotation.z = Math.PI / 2;
  arm.position.set(0.18, 1.3, 0);
  g.add(arm);
  // bracket
  const bracket = new THREE.Mesh(
    new THREE.BoxGeometry(0.04, 0.04, 0.04),
    smat(0x222222));
  bracket.position.set(0.32, 1.3, 0);
  g.add(bracket);
  // glass body — emissive yellow
  const glass = new THREE.Mesh(
    new THREE.BoxGeometry(0.16, 0.18, 0.16),
    new THREE.MeshStandardMaterial({
      color: 0xfff4a8,
      emissive: 0xffd84a,
      emissiveIntensity: 1.4,
      roughness: 0.4,
      transparent: true,
      opacity: 0.9,
    })
  );
  glass.position.set(0.32, 1.18, 0);
  glass.name = 'lanternGlass';
  g.add(glass);
  // tiny cap on top
  const cap = new THREE.Mesh(
    new THREE.ConeGeometry(0.1, 0.06, 4),
    smat(0x222222));
  cap.position.set(0.32, 1.32, 0);
  g.add(cap);
  return shadowizeAll(g);
}

// ---------- HUT ROOF ----------
/** A pitched stone-tile roof. Pass cols × rows footprint; centered on (0,0,0). */
export function buildHutRoof(footprintW, footprintH) {
  const g = new THREE.Group();
  const w = footprintW + 0.3;
  const d = footprintH + 0.3;
  const baseY = 1.25;
  const peakY = 2.05;
  // four-sided pyramid roof
  const half = w / 2, halfD = d / 2;
  const verts = new Float32Array([
    -half, baseY, -halfD,
     half, baseY, -halfD,
     half, baseY,  halfD,
    -half, baseY,  halfD,
        0, peakY,      0,
  ]);
  const idx = [
    0, 1, 4,    // front
    1, 2, 4,    // right
    2, 3, 4,    // back
    3, 0, 4,    // left
  ];
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(verts, 3));
  geo.setIndex(idx);
  geo.computeVertexNormals();
  const roof = new THREE.Mesh(
    geo,
    mat(0x6b3a2a, { roughness: 0.92, metalness: 0, side: THREE.DoubleSide })
  );
  g.add(roof);
  // small cap stone
  const cap = new THREE.Mesh(
    new THREE.BoxGeometry(0.12, 0.12, 0.12),
    mat(0x444446, { roughness: 0.8 }));
  cap.position.y = peakY - 0.06;
  g.add(cap);
  return shadowizeAll(g);
}

// ---------- FIRE ----------
export function buildFireMesh() {
  const g = new THREE.Group();
  // stone ring
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * Math.PI * 2;
    const stone = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.12, 0.18),
      mat(0x6b6e74));
    stone.position.set(Math.cos(a) * 0.32, 0.06, Math.sin(a) * 0.32);
    stone.rotation.y = -a;
    g.add(stone);
  }
  // logs (crossed)
  const log1 = new THREE.Mesh(
    new THREE.CylinderGeometry(0.05, 0.05, 0.5, 6),
    mat(0x6b431f));
  log1.rotation.z = Math.PI / 2;
  log1.position.set(0, 0.13, 0);
  g.add(log1);
  const log2 = log1.clone();
  log2.rotation.z = 0;
  log2.rotation.x = Math.PI / 2;
  log2.position.set(0, 0.13, 0);
  g.add(log2);
  // flame cones — MeshBasicMaterial so they bloom strongly through post-FX
  const flames = new THREE.Group();
  const flame1 = new THREE.Mesh(
    new THREE.ConeGeometry(0.22, 0.5, 6),
    new THREE.MeshBasicMaterial({ color: C.fire_low, transparent: true, opacity: 0.95 }));
  flame1.position.set(0, 0.45, 0);
  flames.add(flame1);
  const flame2 = new THREE.Mesh(
    new THREE.ConeGeometry(0.14, 0.36, 5),
    new THREE.MeshBasicMaterial({ color: C.fire_high, transparent: true, opacity: 1.0 }));
  flame2.position.set(0, 0.6, 0);
  flames.add(flame2);
  const flame3 = new THREE.Mesh(
    new THREE.ConeGeometry(0.08, 0.18, 5),
    new THREE.MeshBasicMaterial({ color: 0xfff8c8, transparent: true, opacity: 1.0 }));
  flame3.position.set(0, 0.72, 0);
  flames.add(flame3);
  flames.userData.isFlames = true;
  g.add(flames);
  g.userData.flames = flames;
  // stones + logs cast/receive shadows; flames don't (transparent, emissive)
  g.traverse(o => {
    if (!o.isMesh) return;
    const isFlame = flames.children.includes(o);
    o.castShadow = !isFlame;
    o.receiveShadow = !isFlame;
  });
  return g;
}

// ---------- HUT (stone walls + wood floor) ----------
export function buildHutMesh(footprint) {
  // footprint: { rows: [...], cols: [...] } passed by world; built as boxes
  // to keep this generic.
  // Simpler: callers place wall and floor tiles individually using these:
  return null;
}

export function buildStoneWallTile() {
  // Subtle bevel — softens corners but tiles still pack flush.
  const m = new THREE.Mesh(
    rbox(1, 1.2, 1, 0.06),
    new THREE.MeshStandardMaterial({
      color: C.stone, flatShading: false,
      roughness: 0.9, metalness: 0,
    })
  );
  m.position.y = 0.6;
  m.castShadow = true;
  m.receiveShadow = true;
  // Tag for the camera-occlusion fader in main.js loop.
  m.userData.occlude = true;
  return m;
}

export function buildWoodFloorTile() {
  const m = new THREE.Mesh(
    new THREE.BoxGeometry(1, 0.06, 1),
    new THREE.MeshStandardMaterial({
      color: C.wood, flatShading: false, roughness: 0.85, metalness: 0,
    })
  );
  m.position.y = 0.03;
  m.receiveShadow = true;
  return m;
}

export function buildPathTile() {
  const m = new THREE.Mesh(
    new THREE.PlaneGeometry(1, 1),
    mat(C.path));
  m.rotation.x = -Math.PI / 2;
  m.position.y = 0.01;
  return m;
}

/** Camera-facing health bar for an enemy. Set userData.fill.scale.x ratio,
 *  call lookAt(camera) each frame so it always faces. */
/** Small flat arrow decal that hovers on the ground behind an enemy,
 *  pointing AWAY from the enemy's facing. Visualizes the back tile so
 *  Backstab positioning is readable. Returns a Group ready to be added
 *  as a child of the enemy mesh — it will rotate with the parent. */
export function buildBacksideArrow() {
  const g = new THREE.Group();
  const mat = new THREE.MeshBasicMaterial({
    color: 0xffaa44, transparent: true, opacity: 0.55,
    side: THREE.DoubleSide, depthWrite: false,
  });
  // Triangle pointing backward (-Z in local space — the enemy "front"
  // is +Z at rotation 0). Build a custom geometry — three vertices.
  const geom = new THREE.BufferGeometry();
  const vs = new Float32Array([
     0.0, 0.0,  -0.40,    // tip (back)
     0.18, 0.0, -0.10,    // back-right base
    -0.18, 0.0, -0.10,    // back-left base
  ]);
  geom.setAttribute('position', new THREE.BufferAttribute(vs, 3));
  geom.computeVertexNormals();
  const arrow = new THREE.Mesh(geom, mat);
  arrow.position.y = 0.02;
  g.add(arrow);
  return g;
}

export function buildEnemyHealthBar() {
  const g = new THREE.Group();
  const w = 0.7, h = 0.09;
  const bg = new THREE.Mesh(
    new THREE.PlaneGeometry(w, h),
    new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.7 })
  );
  g.add(bg);
  const fillMat = new THREE.MeshBasicMaterial({ color: 0x4ab07c });
  const fill = new THREE.Mesh(new THREE.PlaneGeometry(w - 0.06, h - 0.04), fillMat);
  fill.position.z = 0.001;
  // anchor scale.x at left edge so it shrinks rightward → leftward
  fill.geometry.translate((w - 0.06) / 2, 0, 0);
  fill.position.x = -(w - 0.06) / 2;
  g.add(fill);
  // Bleed status badge — small red dot on the right side of the bar.
  // Toggled visible via mesh.userData.fillMat parent's `bleedDot` ref.
  const dotMat = new THREE.MeshBasicMaterial({ color: 0xc63030, transparent: true, opacity: 0 });
  const bleedDot = new THREE.Mesh(new THREE.CircleGeometry(0.05, 12), dotMat);
  bleedDot.position.set(w / 2 + 0.08, 0, 0.002);
  g.add(bleedDot);
  g.userData.fill = fill;
  g.userData.fillMat = fillMat;
  g.userData.bleedDot = bleedDot;
  g.userData.bleedDotMat = dotMat;
  g.visible = false;          // hidden until damaged
  return g;
}

/** Click-target ring — flat emissive disc that pulses and rotates. */
export function buildClickMarker() {
  const g = new THREE.Group();
  // outer glowing ring
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(0.32, 0.42, 24),
    new THREE.MeshBasicMaterial({
      color: 0xffd84a, transparent: true, opacity: 0.85,
      side: THREE.DoubleSide,
    })
  );
  ring.rotation.x = -Math.PI / 2;
  g.add(ring);
  // inner thinner ring
  const ring2 = new THREE.Mesh(
    new THREE.RingGeometry(0.18, 0.22, 24),
    new THREE.MeshBasicMaterial({
      color: 0xfff8c8, transparent: true, opacity: 0.6,
      side: THREE.DoubleSide,
    })
  );
  ring2.rotation.x = -Math.PI / 2;
  g.add(ring2);
  g.visible = false;
  return g;
}

export function buildSandTile() {
  const m = new THREE.Mesh(
    new THREE.PlaneGeometry(1, 1),
    mat(C.sand));
  m.rotation.x = -Math.PI / 2;
  m.position.y = 0.01;
  return m;
}

// Shared water material with animated vertex waves. Created lazily so all
// tiles share the same shader (one uniform updated per frame).
let _waterMat = null;
export function getWaterMaterial() {
  if (_waterMat) return _waterMat;
  const m = new THREE.MeshStandardMaterial({
    color: 0x3a6cb8,
    roughness: 0.35, metalness: 0.1,
    transparent: true, opacity: 0.9,
    flatShading: true,
  });
  m.onBeforeCompile = (shader) => {
    shader.uniforms.uTime = { value: 0 };
    shader.vertexShader = 'uniform float uTime;\nvarying vec3 vWaveWorld;\n' + shader.vertexShader;
    shader.vertexShader = shader.vertexShader.replace(
      '#include <begin_vertex>',
      `#include <begin_vertex>
       vec3 wp = (modelMatrix * vec4(transformed, 1.0)).xyz;
       float wave = sin(wp.x * 1.4 + uTime * 1.2) * 0.06
                  + cos(wp.z * 1.7 + uTime * 0.9) * 0.06;
       transformed.y += wave;
       vWaveWorld = wp;`
    );
    m.userData.shader = shader;
  };
  _waterMat = m;
  return m;
}

export function buildWaterTile() {
  // 4×4 segment plane to give the wave shader something to displace
  const m = new THREE.Mesh(
    new THREE.PlaneGeometry(1, 1, 4, 4),
    getWaterMaterial()
  );
  m.rotation.x = -Math.PI / 2;
  m.position.y = 0.02;  // slightly above ground so waves don't z-fight with grass
  m.receiveShadow = true;
  return m;
}
