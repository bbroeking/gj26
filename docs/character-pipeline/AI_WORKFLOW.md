# AI Character Workflow

End-to-end pipeline for getting a Bramblewood character from a concept-art
image to a walking NPC in the game, using Meshy.ai for 3D generation and
the gj26 cleanup/slicing scripts for engine integration.

Reference: `MODEL_DESCRIPTION_TEMPLATE.md`, `UI_MOCK_WORKFLOW.md`.

---

## Total cost per character

- **Active work**: ~10 min (mostly Stage 5 game integration)
- **Wall clock**: ~15 min (Stage 1 has waiting)
- **Meshy credits**: ~10 base + ~25 refine = **35 credits/character** (~$0.10 at Pro tier)

---

## Stages

### Stage 1: Generate via Meshy (~5 min)

1. Sign in to [meshy.ai](https://meshy.ai).
2. Pick **Image to 3D** (not Text to 3D — the concept art has too much
   visual detail to capture in a prompt).
3. Upload the concept image from `docs/concept-art/<name>.png`.
4. Settings:
   - **Art style**: `Stylized` — gives cartoon-friendly topology.
   - **AI model**: newest Meshy stylized preset.
   - **Symmetry**: `Auto` for humanoid bipeds, `Off` for quadrupeds.
   - **Topology**: `Tri` (or `Quad` if quality preset supports it).
   - **Texture**: `Yes, with PBR` — we'll strip but useful to have.
   - **Polygon count**: ~10,000 if the slider exists.
5. Generate. Inspect the preview. Regenerate (different seed) if the
   first pass has melted face / extra limbs / wrong proportions —
   second/third attempts often hit.
6. Refine to high quality if the base is good (costs more credits).
7. **Download as `.glb`** to `~/Downloads/` (any filename — note it).

### Stage 2: Clean + slice + rig (~30 sec)

Run the cleanup script via headless Blender:

```bash
python3 scripts/clean_ai_mesh.py \
    --input ~/Downloads/Meshy_AI_Foo.glb \
    --name foo_ai_v1 \
    --rig biped \
    --tris 30000
```

Flags:
- `--input` — path to the raw Meshy GLB.
- `--name` — internal name. Will produce `models/<name>.glb` and use
  `<Name>_<Slot>` for material naming so `paintifyAuto` picks up colors.
- `--rig` — `biped` (6 parts: Head/Body/Arm_L/Arm_R/Leg_L/Leg_R),
  `quadruped` (7 parts: Head/Body/Tail/Leg_FL/FR/BL/BR), or `static`
  (Body+Head, no slicing).
- `--tris` — decimation target. 30,000 is good for hero NPCs; 10,000-15,000
  fine for ambient mobs.
- `--rotate-z` — degrees to rotate around Z to align face if Meshy chose
  a different forward axis than expected (-Y is our convention).
- `--head-cut-ratio` / `--legs-cut-ratio` — Z-plane positions for biped
  slicing as fractions of total height (defaults 0.72 / 0.45 work for
  most chibi humanoids).
- `--arm-cut-ratio` — X-plane position for arm cuts as a fraction of
  half-width (default 0.30).

What it does internally:
1. Imports → applies transforms → optional rotation
2. Centers laterally + grounds at z=0
3. Decimates to target tri count + shade smooth
4. Slices into rig parts (biped: 6, quadruped: 7, static: 1)
5. Caps cut openings with `use_fill=True`
6. Renames material to `<Name>_Body` for paintifyAuto compatibility
7. Wraps each piece in a named empty (Body/Head/Arm_L/etc.)
8. Exports to `models/<name>.glb` with our standard GLB flags

### Stage 3: Register in codex (~10 sec)

```bash
python3 scripts/register_ai_character.py foo_ai_v1
```

This:
- Inserts the GLB filename into the "AI-generated (Meshy)" group in
  `codex.js` MODEL_GROUPS.
- Bumps the cache-buster query string in `codex.html`.

### Stage 4: Verify in codex (~30 sec)

Open `http://127.0.0.1:8765/codex.html?cb=<today>` (the registration
script prints the right URL).

Click the new model. Toggle **painted (Wind Waker)** + **ink outline**.

The codex info card should read:
```
foo_ai_v1.glb
N meshes · N materials · T tris
rig parts: Arm_L, Arm_R, Body, Head, Leg_L, Leg_R   ← all 6 present!
▶ animated · walking biped (procedural empty rig)
```

If you see `static (no rig)` instead, the slicing didn't produce all 6
named empties. Re-run `clean_ai_mesh.py` with tweaked cut ratios.

### Stage 5: In-game integration (~5 min)

This is the manual part. For each character:

**5a. Add loader in `src/scene/characters.js`:**

```js
export function loadFooGLB(url = 'models/foo_ai_v1.glb') {
  if (_glb.foo) return Promise.resolve(_glb.foo);
  if (_glb.fooPromise) return _glb.fooPromise;
  const loader = new GLTFLoader();
  _glb.fooPromise = loader.loadAsync(url).then(g => {
    _glb.foo = g.scene;
    g.scene.traverse(o => {
      if (o.isMesh) { o.castShadow = true; o.receiveShadow = false; }
    });
    paintifyAuto(g.scene);
    addUnifiedSilhouetteOutline(g.scene);
    return g.scene;
  }).catch(err => {
    console.warn(`${url} failed to load:`, err);
    _glb.fooPromise = null;
    return null;
  });
  return _glb.fooPromise;
}
```

**5b. Add builder in `src/scene/characters.js`:**

```js
export function buildFooMesh() {
  return _buildNpcGroup('foo', 0.55, { lockArm: 'L', cadenceMul: 1.0 });
}
```

The `lockArm` / `cadenceMul` / `leanMul` opts tune the procedural walk
for this character. See existing NPCs for examples.

**5c. In `src/main.js`, add imports:**

Add `loadFooGLB, buildFooMesh` to the long `from './scene/characters.js'`
import line. **Add `?v=<bump>` to the import URL** to bust the ES module
cache, e.g. `from './scene/characters.js?v=20260510-foo'`.

**5d. Add to startup loaders (around line ~350):**

```js
loadFooGLB(),
```

inside the `Promise.all([...])` block.

**5e. Add to `NEW_NPCS` spawn list (around line ~2265):**

```js
{ kind: 'npc_foo', build: buildFooMesh,
  dx:  3.0, dz: -3.5, rotY: -Math.PI / 4,
  speaker: 'Foo the Whatever',
  lines: ['Line one.', 'Line two.'] },
```

`dx, dz` are offsets from `world.spawn`. `rotY` is facing.

**5f. (Optional) Force walk-in-place** so the NPC animates even when
the player is far away:

```js
let _validationFoo = null;
const fooNpc = NEW_NPCS.find(n => n.kind === 'npc_foo');
if (fooNpc?.mesh) {
  _validationFoo = { mesh: fooNpc.mesh, fakeEntity: { moving: true, running: false } };
}
```

And in the game loop:

```js
if (_validationFoo) animateGLBKnight(_validationFoo.mesh, _validationFoo.fakeEntity, dt);
```

**5g. Bump `index.html` cache-buster** for `main.js`:

```html
<script type="module" src="src/main.js?v=20260510-foo"></script>
```

### Stage 6: Live test (~1 min)

```bash
python3 -m http.server 8765
```

Open `http://127.0.0.1:8765/index.html?cb=foo`. NPC should be visible
at its spawn position, walking in place (if 5f was added) or standing
idle (otherwise).

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Codex says `static (no rig)` | Slicing didn't produce all 6 named empties | Re-run clean_ai_mesh.py with adjusted `--head-cut-ratio` / `--legs-cut-ratio` |
| Character faces wrong way in-game | Meshy chose a different forward axis | Use `--rotate-z 90` (or 180, -90) in clean_ai_mesh.py |
| Character is upside-down or sideways | Meshy used Y-up instead of Z-up in source | Edit clean_ai_mesh.py to rotate around X by 90° before grounding |
| Mesh looks lumpy / faceted | Too aggressive decimation | Increase `--tris` to 30000+ |
| Painted shading looks washed-out | `paintifyAuto` palette derived from neutral grey | Set base color on the material before paintify; or use the script's `bsdf.inputs['Base Color']` line |
| In-game NPC missing | ES module cache | Bump cache-buster on every `import` line in main.js, not just the script tag in index.html |
| Console: "module does not provide export named X" | Stale characters.js | Add `?v=<bump>` to the import URL inside main.js |

---

## Quick-start: add a new character end-to-end

```bash
# 1. Generate in Meshy (browser, ~5 min) — save to ~/Downloads/Foo.glb

# 2. Process
python3 scripts/clean_ai_mesh.py \
    --input ~/Downloads/Foo.glb \
    --name npc_foo_ai_v1 \
    --rig biped

# 3. Register
python3 scripts/register_ai_character.py npc_foo_ai_v1

# 4. Verify in codex (browser)
python3 -m http.server 8765 &
open http://127.0.0.1:8765/codex.html

# 5. Manually edit src/scene/characters.js + src/main.js per Stage 5 above

# 6. Test in-game (browser)
open http://127.0.0.1:8765/index.html
```
