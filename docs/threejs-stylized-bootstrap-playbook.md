# three.js Stylized Game Bootstrap Playbook

How to start a three.js browser game that looks good *and* runs at 60fps on a mid-range laptop. Biased toward toon / cozy / low-poly aesthetics (gj26 mold).

---

## 1. Stack — what to pick (and what to skip)

| Concern | Pick | Why |
|---|---|---|
| Bundler | **Vite** | Zero-config, instant HMR, ES modules native |
| Language | **Vanilla JS** (TS optional) | One less yak; add types only if the project survives jam |
| Framework | **Vanilla three.js**, not R3F | R3F is great but adds React + reconciler overhead; vanilla is faster to learn and ship for a small game |
| Helpers | **three.js examples/jsm** (OrbitControls, GLTFLoader, EffectComposer) | Already maintained inside the repo |
| Physics | **Skip** for jam (use simple AABB collisions). Add Rapier or cannon-es post-jam |
| Audio | **Howler.js** (12kb, simple) or `<audio>` | three.js Audio is fine but Howler is easier |
| State | **Plain modules + classes** | A game state singleton is fine. Don't reach for Redux. |
| GLB models | **Embed textures** (`export_image_format=AUTO`) | Self-contained, simple. Migrate to KTX2 if total >50MB |

When R3F *is* worth it: when the team already knows React, when the game has lots of UI overlays, or when the post-jam plan is a SaaS-grade product with many scenes.

---

## 2. Minimum viable bootstrap

```bash
npm create vite@latest mygame -- --template vanilla
cd mygame
npm i three
npm run dev
```

Replace `main.js`:

```js
import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

// renderer
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
document.body.appendChild(renderer.domElement);

// scene + camera
const scene = new THREE.Scene();
scene.background = new THREE.Color('#bcd');
scene.fog = new THREE.Fog('#bcd', 30, 80);
const camera = new THREE.PerspectiveCamera(45, innerWidth/innerHeight, 0.1, 200);
camera.position.set(8, 8, 8);
new OrbitControls(camera, renderer.domElement);

// lights — see §4
const sun = new THREE.DirectionalLight('#fff5e0', 2.5);
sun.position.set(8, 12, 6);
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
sun.shadow.camera.left = -20; sun.shadow.camera.right = 20;
sun.shadow.camera.top = 20; sun.shadow.camera.bottom = -20;
sun.shadow.bias = -0.0005;
scene.add(sun);
scene.add(new THREE.HemisphereLight('#cfeaff', '#3a4a2a', 0.6));

// ground
const ground = new THREE.Mesh(
  new THREE.PlaneGeometry(80, 80),
  new THREE.MeshToonMaterial({ color: '#6a9a4a' })
);
ground.rotation.x = -Math.PI / 2;
ground.receiveShadow = true;
scene.add(ground);

// load a glb
const loader = new GLTFLoader();
loader.load('/models/character.glb', (gltf) => {
  gltf.scene.traverse(o => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
  scene.add(gltf.scene);
});

// loop
const clock = new THREE.Clock();
function tick() {
  const dt = clock.getDelta();
  renderer.render(scene, camera);
  requestAnimationFrame(tick);
}
tick();

// resize
addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});
```

That's a full working stylized scene in ~50 lines.

---

## 3. The toon look — three approaches

### A. `MeshToonMaterial` (easiest, ~5 min setup)

```js
const gradient = new THREE.DataTexture(
  new Uint8Array([80, 80, 80, 255,  170, 170, 170, 255,  255, 255, 255, 255]),
  3, 1, THREE.RGBAFormat
);
gradient.minFilter = THREE.NearestFilter;
gradient.magFilter = THREE.NearestFilter;
gradient.needsUpdate = true;

const mat = new THREE.MeshToonMaterial({
  color: 0xa86a3a,
  gradientMap: gradient,
});
```

Three discrete light steps → instant cel look. Works with shadows, fog, env maps.

### B. Painted textures + `MeshBasicMaterial` (RuneScape 3 / mobile look)

The texture *is* the lighting. No live shading. Cheapest perf, painted-by-hand vibe matches `ART_BIBLE.md` exactly.

```js
const tex = new THREE.TextureLoader().load('/textures/grass_painted.png');
tex.colorSpace = THREE.SRGBColorSpace;
const mat = new THREE.MeshBasicMaterial({ map: tex });
```

Pair with **vertex AO** baked in Blender for fake shadowing. This is the recommended path for gj26 — fits the art bible's "no PBR-metallic" rule.

### C. Custom shader (full control)

For when you need rim light, custom outline width per object, or fancy post effects. Use `ShaderMaterial` + `THREE.UniformsLib.lights`. High effort, only do if A and B aren't enough.

---

## 4. Lighting — the cheap stylized formula

Three lights, no HDR needed:

```js
const sun       = new THREE.DirectionalLight('#fff5e0', 2.5); // warm key, casts shadow
const sky       = new THREE.HemisphereLight('#cfeaff', '#3a4a2a', 0.6); // cool fill
const rim       = new THREE.DirectionalLight('#ffd5b0', 0.4); // optional warm rim
```

- **Key from upper-left** (matches ART_BIBLE: "soft warm key light from upper left").
- **Hemi fill** does what Ambient + ground bounce does, in one light.
- **Cast shadows from key only.** Multiple shadow casters tank perf.
- **Tighten the shadow camera.** A 20×20 frustum at 2048² is sharp enough; 50×50 is mush.

### Want HDR for reflections / metal bits?

```js
import { RGBELoader } from 'three/examples/jsm/loaders/RGBELoader.js';
new RGBELoader().load('/env/sunset_2k.hdr', (tex) => {
  tex.mapping = THREE.EquirectangularReflectionMapping;
  scene.environment = tex; // affects PBR materials only
});
```

For toon games you usually skip this. HDR doesn't cast shadows; you still need the directional light.

### Tone mapping

`ACESFilmicToneMapping` is the safe default. For a flatter painterly look, `THREE.NoToneMapping` and tune colors directly in textures.

---

## 5. Outlines — the toon bonus

### A. Inverted-hull (per-mesh, cheap, controllable)

Duplicate the mesh, flip normals, scale slightly larger, render with black `MeshBasicMaterial` and `side: THREE.BackSide`. Old-school. Works. One extra draw call per outlined object.

### B. Post-process Sobel edge (full-screen, free per object)

Use `pmndrs/postprocessing` library (cleaner than three's built-in EffectComposer):

```bash
npm i postprocessing
```

```js
import { EffectComposer, RenderPass, EffectPass, OutlineEffect } from 'postprocessing';

const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const outline = new OutlineEffect(scene, camera, {
  edgeStrength: 3, visibleEdgeColor: 0x000000, hiddenEdgeColor: 0x000000,
});
composer.addPass(new EffectPass(camera, outline));

// in tick():
composer.render();
```

For gj26's "no hard cel-shade black outlines" rule (per ART_BIBLE §8), **skip outlines**. Painted textures + cel toon material gets you there.

---

## 6. Performance — the rules of 60fps

The single most useful number: **draw calls**. Target **<150** for a casual browser game.

Check it:

```js
console.log(renderer.info.render);  // { calls, triangles, points, lines, frame }
```

### Top-N optimizations, in priority order

| # | Lever | Win |
|---|---|---|
| 1 | **Merge static geometry** (BufferGeometryUtils.mergeGeometries) | 20 trees = 1 draw call |
| 2 | **InstancedMesh** for repeated dynamic meshes (rocks, grass, mobs) | 100 → 1 draw call |
| 3 | **Frustum culling on by default** — don't disable it | Auto-skips offscreen |
| 4 | **Texture atlasing** | Fewer materials, fewer state changes |
| 5 | **Limit shadow casters** to the hero + maybe big props | Shadow pass is expensive |
| 6 | **Cap pixel ratio to 2** | `setPixelRatio(Math.min(devicePixelRatio, 2))` |
| 7 | **Disable antialiasing on mobile** | Drop SMAA in post instead |
| 8 | **Don't `clone()` materials** | Share one material across instances |
| 9 | **Use `Mesh.matrixAutoUpdate = false`** for static objects + `updateMatrix()` once | Saves per-frame matrix math |
| 10 | **LODs** for distant objects | `THREE.LOD` swaps to lower poly past N units |

### Profiling

- **Spector.js** browser extension — see every draw call, every state change.
- **`renderer.info`** — fastest sanity check.
- **Stats.js** — fps + ms + heap, drop-in widget.

---

## 7. GLTF — loading and managing models

```js
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/examples/jsm/loaders/DRACOLoader.js';
import { KTX2Loader } from 'three/examples/jsm/loaders/KTX2Loader.js';

const draco = new DRACOLoader().setDecoderPath('https://www.gstatic.com/draco/v1/decoders/');
const ktx2 = new KTX2Loader().setTranscoderPath('https://unpkg.com/three@0.160.0/examples/jsm/libs/basis/').detectSupport(renderer);

const loader = new GLTFLoader().setDRACOLoader(draco).setKTX2Loader(ktx2);
loader.load('/models/cottage.glb', (gltf) => scene.add(gltf.scene));
```

### Cloning rules

- `gltf.scene` is a `Group` you should add **once**.
- For multiple instances of the same model, use `SkeletonUtils.clone(gltf.scene)` (preserves rigs).
- For purely static (no skinning), `clone(true)` is fine.
- Share materials when possible — extract them after first load:

```js
const sharedMat = gltf.scene.getObjectByName('Body').material;
```

### Animation

```js
const mixer = new THREE.AnimationMixer(gltf.scene);
const clip = THREE.AnimationClip.findByName(gltf.animations, 'walk_loop');
const action = mixer.clipAction(clip);
action.play();

// in tick():
mixer.update(dt);
```

For multiple clips per character, store actions in a map and crossfade with `action.crossFadeTo(other, 0.2)`.

---

## 8. Project layout (vanilla three.js game)

```
src/
├── main.js                 # entrypoint
├── core/
│   ├── renderer.js         # WebGLRenderer + composer setup
│   ├── camera.js           # camera + controls
│   ├── input.js            # keyboard + mouse + touch
│   └── loop.js             # tick(), dt, fixed-step option
├── scene/
│   ├── world.js            # ground, sky, fog
│   ├── lights.js           # sun + hemi
│   ├── characters.js       # GLTFLoader factory + clone(true)
│   └── decorations.js      # InstancedMesh placement
├── game/
│   ├── player.js           # player state + controller
│   ├── inventory.js
│   ├── skills.js
│   ├── combat.js
│   └── npcs.js
├── anim/
│   └── clips.js            # mixer helpers, crossfade, named clips
├── data/
│   ├── config.js           # tunable constants
│   ├── items.js            # item definitions
│   └── npcs.js             # NPC schedules + dialog
└── ui/
    └── hud.js              # XP bars, hearts, time-of-day
```

(This matches gj26/v3 layout — keep it.)

---

## 9. Common pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| Textures look washed-out / glow | Color space wrong | `tex.colorSpace = THREE.SRGBColorSpace` on every diffuse texture |
| Shadows are blocky | Shadow map too small or frustum too big | 2048² + tight frustum; check `sun.shadow.camera.*` bounds |
| Shadow acne / Z-fighting | No bias | `sun.shadow.bias = -0.0005` |
| FPS drops with many of same mesh | One draw call each | Switch to `InstancedMesh` |
| Loading hitch when a new mob spawns | GLB parsed on first spawn | Pre-load all GLBs at boot, then clone |
| Animations shake | Mixer not using delta | `mixer.update(dt)`, not `(time)` |
| Black flash at startup | `gltf.scene` added before texture loaded | Add to scene inside load callback, not after |
| Mobile chokes | Pixel ratio = 3 + AA + shadows | Cap pixel ratio at 1.5 on mobile, drop AA, fewer shadow casters |
| Memory grows over hours | Geometries / textures not disposed when unloading scene | `geometry.dispose()`, `material.dispose()`, `texture.dispose()` |

---

## 10. Stylized polish — fast wins

- **Vertex colors for fake AO.** Bake AO in Blender to vertex colors, use `vertexColors: true` on material. Free shading without textures.
- **Soft fog matching sky color.** Fog hides the world's edge AND adds painterly depth.
  ```js
  scene.fog = new THREE.Fog(scene.background, 30, 80);
  ```
- **Slight camera tilt** (3/4 iso) sells the storybook feel. `camera.position.set(8, 8, 8); camera.lookAt(0,0,0);`
- **Subtle bobbing on float-able props** (NPCs idle, item pickups) — drives the eye to interactives.
- **One particle layer:** dust motes in light shafts, drifting cloud shadows on ground. `THREE.Points` with a soft sprite.
- **Music ducking on combat.** `Howler` makes this two lines.

---

## 11. References

**Toon shading**
- [Maya — Custom Toon Shader in three.js](https://www.maya-ndljk.com/blog/threejs-basic-toon-shader)
- [sbcode.net — MeshToonMaterial Tutorial](https://sbcode.net/threejs/meshtoonmaterial/)
- [Offscreen Canvas — Cel/Toon Shading](https://offscreencanvas.com/issues/cel-toon-shading/)

**Post-processing & outlines**
- [pmndrs/postprocessing on GitHub](https://github.com/pmndrs/postprocessing)
- [Codrops — Sketchy Pencil Effect with three.js](https://tympanus.net/codrops/2022/11/29/sketchy-pencil-effect-with-three-js-post-processing/)
- [Maxime Heckel — Moebius-style Post-Processing](https://blog.maximeheckel.com/posts/moebius-style-post-processing/)
- [OmarShehata/webgl-outlines](https://github.com/OmarShehata/webgl-outlines)
- [Three.js forum — Full outlines as post-process](https://discourse.threejs.org/t/how-to-render-full-outlines-as-a-post-process-tutorial/22674)

**Performance**
- [utsubo — 100 three.js Tips That Actually Improve Performance (2026)](https://www.utsubo.com/blog/threejs-best-practices-100-tips)
- [VR Me Up — InstancedMesh Performance](https://vrmeup.com/devlog/devlog_10_threejs_instancedmesh_performance_optimizations.html)
- [Casey Primozic — Depth-Based Fragment Culling](https://cprimozic.net/blog/depth-based-fragment-culling-webgl/)
- [MoldStud — Overdraw in three.js](https://moldstud.com/articles/p-essential-tips-and-tricks-for-addressing-overdraw-issues-in-threejs-rendering)

**Lighting / HDR**
- [PixelCapture — HDR Lighting in three.js](https://pixel-capture.com/tutorials/hdr-lighting-threejs-article)
- [Red Stapler — Realistic Light and Shadow Tutorial](https://redstapler.co/threejs-realistic-light-shadow-tutorial/)
- [three.js examples — HDR environment mapping](https://threejs.org/examples/webgl_materials_envmaps_hdr.html)

**Bootstrap templates** (only if you decide to migrate to R3F post-jam)
- [benjaminmiles/react-three-vite](https://github.com/benjaminmiles/react-three-vite)
- [renoiser/r3f-vite-starter (TS + GLSL)](https://github.com/renoiser/r3f-vite-starter)
