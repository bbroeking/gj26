// Crypt-scope GLB cache + per-cell factories.
//
// Mirrors the `_loadOnce` pattern from characters.js (one cached scene per
// URL, returned via clone()). Wall orientation is resolved at place-time
// from a 4-bit cardinal-neighbor bitmask.
//
// Lifecycle: buildCryptDungeon() in dungeon.js fires the loads and either
// places clones immediately (cache warm) or queues them via the promise
// path. Either way the floor/wall/decor placement is synchronous from
// dungeon.js's POV — un-loaded slots show empty until the promise lands.

import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { toonifyMaterials } from './characters.js';
import {
  CRYPT_DECOR_MODELS, CRYPT_WALL_MODELS, CRYPT_CHEST_MODEL,
  CRYPT_FLOOR_TEXTURE, CRYPT_WEB_TEXTURE, CRYPT_FLICKER_KINDS,
} from '../data/dungeonTilesCrypt.js';

const _cache = {
  scenes: new Map(),     // url → THREE.Group (loaded scene template, cloned per instance)
  promises: new Map(),   // url → Promise (in-flight load)
  floorTex: null,
  floorPromise: null,
  webTex: null,
  webPromise: null,
};

/** Load + cache a GLB by URL. Returns Promise<THREE.Group>. Subsequent
 *  calls return the cached scene. Clones MUST be made by the caller —
 *  the cached scene is the template. */
function _loadCryptGLB(url) {
  if (_cache.scenes.has(url)) return Promise.resolve(_cache.scenes.get(url));
  if (_cache.promises.has(url)) return _cache.promises.get(url);
  const loader = new GLTFLoader();
  const p = loader.loadAsync(url).then(g => {
    g.scene.traverse(o => {
      if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; }
    });
    toonifyMaterials(g.scene);
    _cache.scenes.set(url, g.scene);
    return g.scene;
  }).catch(err => {
    console.warn('[crypt] failed to load', url, err);
    _cache.promises.delete(url);
    return null;
  });
  _cache.promises.set(url, p);
  return p;
}

/** Load the tileable floor texture once. */
function _loadFloorTexture() {
  if (_cache.floorTex) return Promise.resolve(_cache.floorTex);
  if (_cache.floorPromise) return _cache.floorPromise;
  const loader = new THREE.TextureLoader();
  _cache.floorPromise = loader.loadAsync(CRYPT_FLOOR_TEXTURE).then(tex => {
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(1, 1);
    tex.minFilter = THREE.LinearMipMapLinearFilter;
    tex.magFilter = THREE.LinearFilter;
    _cache.floorTex = tex;
    return tex;
  }).catch(err => {
    console.warn('[crypt] floor texture failed:', err);
    return null;
  });
  return _cache.floorPromise;
}

/** Web billboard texture. */
function _loadWebTexture() {
  if (_cache.webTex) return Promise.resolve(_cache.webTex);
  if (_cache.webPromise) return _cache.webPromise;
  const loader = new THREE.TextureLoader();
  _cache.webPromise = loader.loadAsync(CRYPT_WEB_TEXTURE).then(tex => {
    tex.colorSpace = THREE.SRGBColorSpace;
    _cache.webTex = tex;
    return tex;
  }).catch(err => {
    console.warn('[crypt] web texture failed:', err);
    return null;
  });
  return _cache.webPromise;
}

/** Pre-warm the loaders for every crypt asset the layout might place. */
export function preloadCryptAssets() {
  const urls = new Set();
  for (const k in CRYPT_DECOR_MODELS) urls.add(CRYPT_DECOR_MODELS[k].url);
  for (const k in CRYPT_WALL_MODELS) urls.add(CRYPT_WALL_MODELS[k].url);
  urls.add(CRYPT_CHEST_MODEL.url);
  for (const u of urls) _loadCryptGLB(u);
  _loadFloorTexture();
  _loadWebTexture();
}

/** Clone a cached GLB scene + register a `_pendingFill` hook on the
 *  returned wrapper so the dungeon.js code can place an empty Group
 *  synchronously and have it filled in when the load resolves. */
function _instantiateOrDefer(url, wrap) {
  const ready = _cache.scenes.get(url);
  if (ready) {
    wrap.add(ready.clone(true));
    return;
  }
  _loadCryptGLB(url).then(scene => {
    if (scene && wrap.parent) wrap.add(scene.clone(true));
  });
}

/** Build a single floor tile mesh. Either uses the cached texture or
 *  paints a fallback grey toon material until the texture lands. */
export function buildCryptFloorTile() {
  const geom = new THREE.PlaneGeometry(1, 1);
  geom.rotateX(-Math.PI / 2);
  const mat = new THREE.MeshToonMaterial({
    color: _cache.floorTex ? 0xffffff : 0x5a5045,
    map: _cache.floorTex,
  });
  const mesh = new THREE.Mesh(geom, mat);
  mesh.receiveShadow = true;
  // Promote material from grey-fallback to textured once the load completes.
  if (!_cache.floorTex) {
    _loadFloorTexture().then(tex => {
      if (tex) {
        mat.color.set(0xffffff);
        mat.map = tex;
        mat.needsUpdate = true;
      }
    });
  }
  return mesh;
}

/** Pick wall variant + Y-rotation from a 4-bit cardinal-neighbor bitmask.
 *  Bits, in this order: 1=N(y-1), 2=E(x+1), 4=S(y+1), 8=W(x-1).
 *  A bit is SET when that neighbor is a floor tile (i.e. the wall faces
 *  it). Returns { kind, ry } where ry is the Y rotation in radians.
 *
 *  The base GLB orientations (per Meshy v0/v1/v3 picks) are:
 *    straight     — faces NORTH (+Z negative). Long axis along E-W.
 *    cornerOuter  — convex corner; default faces NE (N+E exposed).
 *    cornerInner  — concave corner; default faces NE inside, NW+SE behind.
 *
 *  Empirical fallbacks: if a 3-floor case appears, treat as outer-corner
 *  with the wall-side pointing into the single closed neighbor. */
export function cryptWallVariant(neighborsBitmask) {
  const n = (neighborsBitmask >> 0) & 1;
  const e = (neighborsBitmask >> 1) & 1;
  const s = (neighborsBitmask >> 2) & 1;
  const w = (neighborsBitmask >> 3) & 1;
  const count = n + e + s + w;

  // 0 or 4 floor neighbors: not visible from anywhere meaningful; use
  // straight as a default. (4-floor case is an isolated pillar that
  // probably shouldn't exist in well-formed layouts.)
  if (count === 0 || count === 4) return { kind: 'straight', ry: 0 };

  // 1 floor neighbor: straight wall, back to the floor.
  if (count === 1) {
    if (n) return { kind: 'straight', ry: 0 };              // faces north (+Z-)
    if (e) return { kind: 'straight', ry: -Math.PI / 2 };   // faces east
    if (s) return { kind: 'straight', ry: Math.PI };        // faces south
    if (w) return { kind: 'straight', ry: Math.PI / 2 };    // faces west
  }

  // 2 floor neighbors.
  if (count === 2) {
    // Opposite — wall is between two corridors. Use straight; rotate so
    // the long axis lines up with the corridor opening.
    if (n && s) return { kind: 'straight', ry: 0 };
    if (e && w) return { kind: 'straight', ry: Math.PI / 2 };
    // Adjacent — convex outer corner. Rotate by 90° to match which pair.
    if (n && e) return { kind: 'cornerOuter', ry: 0 };               // default NE
    if (e && s) return { kind: 'cornerOuter', ry: -Math.PI / 2 };    // SE
    if (s && w) return { kind: 'cornerOuter', ry: Math.PI };         // SW
    if (w && n) return { kind: 'cornerOuter', ry: Math.PI / 2 };     // NW
  }

  // 3 floor neighbors: one closed side. Use inner-corner (concave) and
  // rotate so the closed direction points "inward".
  if (count === 3) {
    if (!n) return { kind: 'cornerInner', ry: Math.PI };       // closed N → faces S
    if (!e) return { kind: 'cornerInner', ry: Math.PI / 2 };   // closed E → faces W
    if (!s) return { kind: 'cornerInner', ry: 0 };             // closed S → faces N
    if (!w) return { kind: 'cornerInner', ry: -Math.PI / 2 };  // closed W → faces E
  }

  return { kind: 'straight', ry: 0 };
}

/** Build a single wall tile from a bitmask of floor neighbors. Returns
 *  a Group whose contents come in via the GLB-load promise. */
export function buildCryptWallTile(neighborsBitmask) {
  const { kind, ry } = cryptWallVariant(neighborsBitmask);
  const url = CRYPT_WALL_MODELS[kind].url;
  const wrap = new THREE.Group();
  wrap.rotation.y = ry;
  wrap.userData.wallVariant = kind;
  _instantiateOrDefer(url, wrap);
  return wrap;
}

/** Build a single decor prop by kind. Returns null for unknown kinds so
 *  callers can fall back to the legacy procedural switch. */
export function buildCryptDecor(kind) {
  // Web — billboard plane with alpha (Meshy failed on the actual mesh,
  // per spec 01 followup).
  if (kind === 'web') {
    const wrap = new THREE.Group();
    wrap.userData.decorKind = kind;
    const geom = new THREE.PlaneGeometry(0.95, 0.95);
    const mat = new THREE.MeshBasicMaterial({
      color: 0xffffff, transparent: true, alphaTest: 0.1, opacity: 0.65,
      depthWrite: false, side: THREE.DoubleSide,
      map: _cache.webTex,
    });
    const mesh = new THREE.Mesh(geom, mat);
    // Tilt slightly so it reads as hanging in a corner, not a floor decal.
    mesh.position.y = 0.65;
    mesh.rotation.x = -Math.PI / 12;
    wrap.add(mesh);
    if (!_cache.webTex) {
      _loadWebTexture().then(tex => { if (tex) { mat.map = tex; mat.needsUpdate = true; } });
    }
    return wrap;
  }

  const def = CRYPT_DECOR_MODELS[kind];
  if (!def) return null;
  const wrap = new THREE.Group();
  wrap.position.y = def.y || 0;
  if (def.scale && def.scale !== 1) wrap.scale.setScalar(def.scale);
  wrap.userData.decorKind = kind;
  _instantiateOrDefer(def.url, wrap);

  // Brazier + torch get a flickering warm point-light parented to the prop.
  if (CRYPT_FLICKER_KINDS.has(kind)) {
    const light = new THREE.PointLight(0xff8030, 2.5, 7, 2);
    light.position.set(0, kind === 'torch_wall' ? 1.2 : 0.8, 0);
    // Stash flicker config so the dungeon group's per-frame tick (added
    // in buildDungeonGroup for crypt scopes) can vary the intensity.
    light.userData.flickerBase = 2.5;
    light.userData.flickerAmp = 0.6;
    light.userData.flickerPhase = Math.random() * Math.PI * 2;
    wrap.add(light);
  }
  return wrap;
}

/** Build the crypt chest override. Same call-site as the procedural
 *  chest in buildDungeonGroup; just swaps the mesh. */
export function buildCryptChest() {
  const wrap = new THREE.Group();
  wrap.position.y = CRYPT_CHEST_MODEL.y || 0;
  if (CRYPT_CHEST_MODEL.scale && CRYPT_CHEST_MODEL.scale !== 1) {
    wrap.scale.setScalar(CRYPT_CHEST_MODEL.scale);
  }
  // Gold glow above — keeps the player-eye affordance from the procedural
  // chest so the player can spot the loot at a distance.
  const glow = new THREE.PointLight(0xffcc66, 1.0, 6);
  glow.position.y = 1.2;
  wrap.add(glow);
  _instantiateOrDefer(CRYPT_CHEST_MODEL.url, wrap);
  return wrap;
}

/** Register the dungeon group for per-frame flicker updates. The animate
 *  loop in main.js doesn't traverse for tick callbacks, so we self-manage
 *  with requestAnimationFrame; cancel hook attached to the group so
 *  exitDungeon can stop us. */
export function attachCryptFlicker(group) {
  let raf = 0;
  const start = performance.now();
  const tick = () => {
    if (!group.parent) return; // group removed from scene → stop
    const t = (performance.now() - start) / 1000;
    group.traverse(o => {
      if (o.isLight && o.userData.flickerBase !== undefined) {
        const base = o.userData.flickerBase;
        const amp = o.userData.flickerAmp || 0.5;
        const phase = o.userData.flickerPhase || 0;
        // Mix slow sin + short random jitter for a fire-like wobble.
        const sin = Math.sin(t * 7 + phase) * 0.5;
        const noise = (Math.random() - 0.5) * 0.6;
        o.intensity = Math.max(0.4, base + amp * sin + amp * 0.4 * noise);
      }
    });
    raf = requestAnimationFrame(tick);
  };
  raf = requestAnimationFrame(tick);
  group.userData.flickerStop = () => { if (raf) cancelAnimationFrame(raf); raf = 0; };
}
