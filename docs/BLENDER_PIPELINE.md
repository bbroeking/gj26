# Blender → three.js asset pipeline

End-to-end: take a 2D concept image (e.g. Midjourney output) → 3D model in
Blender → rigged → exported as `.glb` → loaded in our game with `GLTFLoader`
+ `AnimationMixer`.

---

## 0. Once-off Blender setup

1. **Install Blender 4.x** (you said it's installed)
2. Enable add-ons (Edit → Preferences → Add-ons):
   - **Node Wrangler** (built-in) — speeds up shader work
   - **Import-Export: glTF 2.0 format** (built-in, on by default)
3. Set unit system to **Metric · 1.0 m** (Properties → Scene → Units). The
   game uses 1 unit = 1 tile = 1 m. If you model at the wrong scale,
   characters will be giants or ants.
4. Set **+Y up, -Z forward** is fine for Blender's internal axes — the
   glTF exporter handles the conversion to three.js's +Y up, +Z forward
   automatically.

---

## 1. Reference-image setup

For each character/prop you want to model:

1. Generate concept image (Midjourney prompts in this repo / your tool of
   choice). Aim for clean side / front / 3-quarter views — orthographic-style
   if possible.
2. In Blender:
   - `Add → Image → Reference` — drops a flat plane with the image
   - Alternatively, drag the file into the viewport directly
   - For multi-view: import 3 references (front, side, 3-quarter) and
     position them on perpendicular axes around the origin
   - Press `N` to open the side panel → adjust opacity to ~50% so you can
     see your model through it

Tip: a single 3-quarter image is usually enough for low-poly, stylized
work. Side + front views are needed when proportions matter (cf. AccuRig
expects neutral-pose front view).

---

## 2. Modeling — three approaches by skill level

### A. Easiest — primitives + edit
Best for low-poly stylized props (trees, hut, fence, fire pit).

```
Shift+A → Mesh → Cube
Tab (Edit Mode)
1 / 2 / 3 toggles vertex / edge / face select
E to extrude, S to scale, R to rotate, G to grab (move)
```

Workflow:
1. Add a cube/cylinder/cone matching the rough shape
2. Use `Bevel` (Ctrl+B) to round edges → matches our `RoundedBoxGeometry` look
3. Apply a basic Principled BSDF material (Properties → Material) with
   roughness ~0.85, metalness 0
4. Tab back to Object Mode
5. **Apply scale** before export: `Object → Apply → All Transforms`
   (this is critical; un-applied scale breaks animation in three.js)

### B. Medium — sculpting
Best for organic shapes (cow body, knight torso).

```
Add → Mesh → UV Sphere (or Cube + Subdivide)
Switch to Sculpt Mode (top-left dropdown)
Shift+drag to brush — Grab, Crease, Smooth are your three core brushes
```

Use sculpting to rough out, then **Decimate** modifier to drop polycount
to ~2-3k tris before export. The game runs fine up to ~10k tris per
character but lower is better.

### C. Hardest — full topology
Author each quad by hand. Skip unless you specifically need clean
deformation for animation (e.g. faces).

---

## 3. Materials — PBR, but keep it simple

Each mesh needs a **Principled BSDF** material:
- `Base Color` — a flat color, or a texture if you want detail
- `Roughness` — 0.7-0.95 for matte, 0.3-0.5 for shiny
- `Metallic` — 0 for cloth/wood, 0.7+ for armor/swords/gold

For our stylized look, **don't paint textures** — just use flat colors.
Multiple materials per object are fine; the glTF exporter splits them
into draw calls automatically.

For emissive (lantern glass, fire embers, eyes):
- Set `Emission` color
- Set `Emission Strength` to 1.5-3.0
- This will trigger our bloom pass in-game

---

## 4. Rigging — three options

### Option 1: Mixamo (humanoid only, easiest)
1. In Blender: `File → Export → glTF 2.0` — export your **un-rigged** model
2. Go to <https://www.mixamo.com> (free, Adobe account)
3. Click `Upload Character` → drop the .glb
4. Mixamo's auto-rigger: place 5 markers (chin, wrists, elbows, knees, groin)
5. Click `Find Animations` → browse 2,500 free motion-cap clips
6. For each animation you want, click → `Download` → choose `.fbx for Unity`
   - Settings: With Skin / Frames per second 30
7. Re-import the fbx files into Blender, copy the animation actions to
   your character, export as a single `.glb` with all animations bundled
   (`Animation` checkbox in the glTF exporter)

For this project we want at minimum: **Idle**, **Walk**, **Sword and Shield Slash**,
**Hit React Standing**, **Falling Back Death**.

### Option 2: AccuRig 2 (free, supports quadrupeds + birds + serpents)
The only free option for non-humanoid auto-rigging — use this for the cow
and goblin if you want them rigged with bones rather than animated procedurally.

1. Download AccuRig 2 from Reallusion
2. Import your model, follow the bone-placement wizard
3. Export to FBX or GLB
4. Optionally retarget animations from AccuRig's library

### Option 3: Manual rigging in Blender (most control, steepest)
Rigify add-on (built-in):
1. `Add → Armature → Human (Meta-Rig)` — drop a default skeleton
2. Edit Mode → align bones to your mesh
3. Generate the rig: armature properties → `Generate Rig`
4. Parent your mesh: select mesh, shift-select armature, `Ctrl+P → With Automatic Weights`
5. Pose mode → keyframe your animations on the action editor
6. Export with all actions

For our cow: 4 leg bones + spine + head + tail = ~10-bone rig is plenty.

---

## 5. Export — glTF settings

In Blender: `File → Export → glTF 2.0 (.glb / .gltf)`

Recommended settings:
```
Format:            glTF Binary (.glb)         ← single file, easiest
Include:
  Selected Objects:    only what you want
  Apply Modifiers:     ON
Transform:
  +Y Up:               ON
Geometry:
  Apply Modifiers:     ON
  UVs:                 ON
  Normals:             ON
  Tangents:            OFF unless you have normal maps
  Vertex Colors:       ON if you used them for variation
  Materials:           Export
  Compression:         Draco — only if your model is huge (>5 MB raw)
Animation:
  Animation:           ON
  Limit to Playback Range: OFF
  Always Sample Animations: ON
  NLA Strips:          ON if you used the NLA editor
Skinning:
  Bone Influences:     4 (default)
```

Save to `models/` in this repo.

---

## 6. Loading in three.js

Pattern is the same one used by `src/anim/skeletal.js` (the demo Soldier):

```js
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const loader = new GLTFLoader();
const gltf = await loader.loadAsync('models/knight.glb');
const root = gltf.scene;

// Match scale to game world units (Blender → game)
root.scale.setScalar(1.0);     // already 1m if you set units correctly

// Opt every mesh into shadows
root.traverse(o => {
  if (o.isMesh) {
    o.castShadow = true;
    o.receiveShadow = true;
  }
});

scene.add(root);

// Animation
const mixer = new THREE.AnimationMixer(root);
const clipsByName = Object.fromEntries(gltf.animations.map(c => [c.name, c]));
const idle   = mixer.clipAction(clipsByName['Idle']);
const walk   = mixer.clipAction(clipsByName['Walk']);
const attack = mixer.clipAction(clipsByName['Attack']);

idle.play();   walk.play();   attack.play();
walk.setEffectiveWeight(0);
attack.setEffectiveWeight(0);
attack.setLoop(THREE.LoopOnce, 1);
attack.clampWhenFinished = true;

// Per frame:
mixer.update(dt);
walk.setEffectiveWeight(player.moving ? 1 : 0);
idle.setEffectiveWeight(player.moving ? 0 : 1);

// Trigger an attack:
attack.reset().fadeIn(0.05).play();
```

---

## 7. Replace the procedural knight in our game

Drop a `knight.glb` into `models/` and edit `src/scene/characters.js`:

```js
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
const _knightCache = { gltf: null, promise: null };

export async function loadKnightGLTF(url = 'models/knight.glb') {
  if (_knightCache.gltf) return _knightCache.gltf;
  if (!_knightCache.promise) {
    const loader = new GLTFLoader();
    _knightCache.promise = loader.loadAsync(url).then(g => { _knightCache.gltf = g; return g; });
  }
  return _knightCache.promise;
}
```

Then in `src/game/player.js`:
```js
import { loadKnightGLTF } from '../scene/characters.js';
import * as THREE from 'three';

export async function createPlayerGLTF(spawnX, spawnY) {
  const gltf = await loadKnightGLTF();
  const mesh = THREE.SkeletonUtils.clone(gltf.scene); // separate instance
  // ... rest is same
  // mesh.name lookup ('lLeg', 'rLeg', etc.) — depends on your Mixamo bone names
  const mixer = new THREE.AnimationMixer(mesh);
  return { ..., gltf, mixer };
}
```

**Note**: Mixamo's bone names are different from our procedural mesh's
named children (`lLeg`, `rArm`, etc.). The procedural animation in
`src/anim/procedural.js` won't drive a Mixamo skeleton — you'd switch to
`AnimationMixer`-driven clips, which we already have a pattern for in
`src/anim/clips.js` and `src/anim/skeletal.js`.

---

## 8. Iteration tips

- **Polycount budget**: per character ~3-5k tris, total scene under ~200k tris for 60fps
- **Texture budget**: skip textures entirely for stylized; if you must, keep to one 1024×1024 atlas per character
- **Drag-and-drop a `.glb` into <https://gltf-viewer.donmccurdy.com>** to verify it before integrating — saves debugging
- **AccuRig works on weird models** that Mixamo rejects — use it as a fallback
- **Mixamo's body proportions** are humanoid-standard; your stylized character may need post-rig editing in Blender to match Mixamo's skeleton (e.g., scale arms longer)
- **Always apply transforms** before export (Object → Apply → All Transforms). Un-applied scale or rotation breaks animation playback in three.js.

---

## 9. Quick checklist before shipping a model

- [ ] Polycount < 5k tris (use Decimate modifier if over)
- [ ] All transforms applied
- [ ] Materials use Principled BSDF
- [ ] Naming: meshes have descriptive names (not "Cube.001")
- [ ] If rigged: armature pose is at rest, all keyframes on Action 1
- [ ] If multi-animation: each in its own NLA Strip
- [ ] Export GLB binary, not GLTF separate
- [ ] Test in <https://gltf-viewer.donmccurdy.com> first
- [ ] File under 500 KB ideally; under 2 MB max
