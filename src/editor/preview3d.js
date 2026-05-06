// 3D preview for the dungeon editor. Reuses the actual game render path
// (src/scene/dungeon.js's loadAuthoredLayout / loadScaffoldLayout +
// buildDungeonGroup) so what you see here is exactly what the game will
// render. Lazy-bootstraps three.js + the dungeon module on first toggle.

let THREE     = null;     // namespace import, populated lazily
let OrbitCtrl = null;
let dungeonMod = null;

let renderer = null;
let scene    = null;
let camera   = null;
let controls = null;
let group    = null;       // current dungeon group, swapped on each refresh
let resizeObserver = null;
let rafId    = null;       // active requestAnimationFrame token, null = not running

let _ready = false;        // first-toggle bootstrap done
let _bootstrapPromise = null;   // race-guard: concurrent toggles share one promise
let _lastState = null;          // most recent state for Refresh

function _bootstrap() {
  if (_ready) return Promise.resolve();
  if (_bootstrapPromise) return _bootstrapPromise;
  _bootstrapPromise = (async () => {
    const three = await import('three');
    const oc    = await import('three/addons/controls/OrbitControls.js');
    THREE     = three;
    OrbitCtrl = oc.OrbitControls;
    dungeonMod = await import('../scene/dungeon.js');
    _ready = true;
  })();
  return _bootstrapPromise;
}

/** Show the 3D preview, building it from the editor's current state. */
export async function show3DPreview(state) {
  await _bootstrap();
  _lastState = state;
  const overlay = document.getElementById('three-overlay');
  const canvas  = document.getElementById('three-canvas');
  overlay.style.display = '';
  _setError(null);

  if (!renderer) _initRenderer(canvas);
  _renderLayoutFromState(state);
  _startLoop();
}

/** Hide the 3D preview. Stops the rAF loop to free CPU; keeps the
 *  renderer + scene cached so reopening is instant. */
export function hide3DPreview() {
  const overlay = document.getElementById('three-overlay');
  if (overlay) overlay.style.display = 'none';
  _stopLoop();
}

/** Re-build the 3D preview from the most recent state without toggling.
 *  Triggered by the in-overlay Refresh button — useful for rerolling
 *  scaffold-mode procgen without losing your camera position. */
export function refresh3DPreview() {
  if (!_lastState || !renderer) return;
  _setError(null);
  _renderLayoutFromState(_lastState);
}

// ---- internals ---------------------------------------------------------

function _initRenderer(canvas) {
  renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
  renderer.setPixelRatio(window.devicePixelRatio || 1);
  renderer.shadowMap.enabled = false;
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x14110d);
  scene.fog = new THREE.Fog(0x14110d, 18, 50);

  const w = canvas.clientWidth || 800, h = canvas.clientHeight || 600;
  renderer.setSize(w, h, false);
  camera = new THREE.PerspectiveCamera(50, w / h, 0.05, 200);
  camera.position.set(0, 18, 22);
  camera.lookAt(0, 0, 0);

  controls = new OrbitCtrl(camera, canvas);
  controls.target.set(0, 0, 0);
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;
  controls.maxPolarAngle = Math.PI * 0.49;

  // Warm hemisphere + soft directional — broadly matches the in-game
  // dungeon ambience without depending on the per-scope torch lights.
  const hemi = new THREE.HemisphereLight(0xffd2a0, 0x2a1f18, 0.55);
  scene.add(hemi);
  const dir = new THREE.DirectionalLight(0xffe6c2, 0.65);
  dir.position.set(8, 14, 6);
  scene.add(dir);

  resizeObserver = new ResizeObserver(() => {
    const w = canvas.clientWidth, h = canvas.clientHeight;
    if (w > 0 && h > 0) {
      renderer.setSize(w, h, false);
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
    }
  });
  resizeObserver.observe(canvas);
}

function _renderLayoutFromState(state) {
  // Quick sanity — if the canvas has no floor tiles, the 3D will just be
  // a solid wall block. Catch it early with a user-readable message.
  const floorCount = _countFloor(state.grid);
  if (floorCount === 0) {
    _setError('No floor tiles painted yet. Use F to paint floor, then 3D preview again.');
    if (group) { scene.remove(group); _disposeGroup(group); group = null; }
    return;
  }

  let layout;
  try {
    const json = _toJsonShape(state);
    const affixes = state.affixIds.map(id => ({ id, good: true, resolvedId: id }));
    layout = state.mode === 'scaffold'
      ? dungeonMod.loadScaffoldLayout(json, state.tier || 1, affixes)
      : dungeonMod.loadAuthoredLayout(json, affixes);
  } catch (e) {
    _setError('Layout build failed: ' + (e.message || e));
    return;
  }

  // Scaffold mode silently falls through to authored when <2 rooms detected
  // — surface that so the user knows why they aren't seeing corridors.
  if (state.mode === 'scaffold' && layout.authoredName && !layout.authoredName.includes('scaffold')) {
    _setError('Need at least 2 separate floor regions for scaffold mode. Showing as authored.');
  }

  if (group) {
    scene.remove(group);
    _disposeGroup(group);
  }
  group = dungeonMod.buildDungeonGroup(layout, []);
  const gw = layout.grid[0].length, gh = layout.grid.length;
  group.position.set(-gw / 2, 0, -gh / 2);
  scene.add(group);

  // Frame camera relative to map size, but only on first render —
  // preserve user-controlled angle on Refresh.
  if (!_camHasFrame) {
    const radius = Math.max(gw, gh) * 0.7;
    camera.position.set(radius, radius * 0.85, radius);
    controls.target.set(0, 0, 0);
    controls.update();
    _camHasFrame = true;
  }
}
let _camHasFrame = false;

function _countFloor(grid) {
  let n = 0;
  for (const row of grid) for (const c of row) if (c === 'floor') n++;
  return n;
}

function _startLoop() {
  if (rafId !== null) return;
  const loop = () => {
    if (rafId === null) return;
    controls && controls.update();
    if (renderer && scene && camera) renderer.render(scene, camera);
    rafId = requestAnimationFrame(loop);
  };
  rafId = requestAnimationFrame(loop);
}

function _stopLoop() {
  if (rafId !== null) {
    cancelAnimationFrame(rafId);
    rafId = null;
  }
}

function _setError(msg) {
  const el = document.getElementById('three-error');
  if (!el) return;
  if (msg) {
    el.textContent = msg;
    el.style.display = '';
  } else {
    el.style.display = 'none';
  }
}

function _disposeGroup(g) {
  g.traverse(o => {
    if (o.geometry) o.geometry.dispose?.();
    if (o.material) {
      const mats = Array.isArray(o.material) ? o.material : [o.material];
      for (const m of mats) m.dispose?.();
    }
  });
}

// Editor state → loader-shape JSON. Same fields toJson() in editor.js
// produces, but kept local so the preview module doesn't depend on
// editor.js's export surface.
function _toJsonShape(s) {
  return {
    name: s.name,
    scope: s.scope,
    mode: s.mode,
    procgenPadding: s.procgenPadding,
    useBrushes: s.useBrushes,
    brushes: s.useBrushes
      ? Object.values(_readBrushes()).map(rec => rec.brush).filter(b => b && Array.isArray(b.grid))
      : null,
    size: { w: s.w, h: s.h },
    grid: s.grid,
    entry: s.entry,
    exit: s.exit,
    chestTile: s.chestTile,
    decor: s.decor,
    spawns: s.spawns,
    staircases: s.staircases,
    roomTags: s.roomTags,
    bossKind: s.bossKind || null,
    procgen: {
      tier: s.tier,
      runeEffect: s.runeEffect || null,
      seed: s.seed || null,
      affixIds: s.affixIds.slice(),
    },
  };
}

function _readBrushes() {
  try {
    const raw = localStorage.getItem('gj26.dungeon_brushes');
    if (!raw) return {};
    const o = JSON.parse(raw);
    return o && typeof o === 'object' ? o : {};
  } catch (_) { return {}; }
}
