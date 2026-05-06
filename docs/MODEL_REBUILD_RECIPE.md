# Model rebuild recipe — synthesis from KB + project pipeline

A self-contained brief for iterating on the existing NPC + boss GLBs.
Distilled from the wiki at `/Users/bbroeking/projects/research/wiki/art/`
(silhouette / shape language / color & lighting / toon shading /
Blender→three.js pipeline) plus the project's accumulated bevel
recipe in `feedback_blender_bevel_pipeline.md`.

Companion: `docs/BOSS_SPEC.md` for boss-specific shape briefs.

---

## 1. Silhouette — the top-down readable marks (highest impact)

Top-down ARPG camera weights the silhouette OUTLINE and the head/shoulders.
Apply the **thumbnail test**: render the asset at 64×64 black-on-white
from the actual game camera angle. If you can't tell who the character
is from that one shape, redo.

**Concrete moves:**
1. **Exaggerate the head** — chunky cozy uses ~1:4 head:body ratio
   (head = 1/4 the total height). The face is the most legible mark.
2. **One distinct primary shape per character.** No two NPCs in the
   village share their primary shape. Eldra = column. Hod = block.
   Quill = inverted teardrop (frail, leaning). Etc.
3. **Crown the silhouette with one identifying mark** — Eldra's lantern,
   Hod's hammer, Sir Withering's falcon, the Hedgemother's thorn crown.
   This is the read-at-a-glance prop.
4. **Negative space matters.** Tuck the arms IN at idle so the silhouette
   reads as one column, not three. Spread arms only at attack telegraph.
5. **Top-down tilt:** game camera is ~45° pitch. Author the model so
   the head + crown-prop stay visible from that angle. Hoods that hide
   the face from above kill recognition.

## 2. Shape language — three primaries

| Shape | Reads as | Use for |
|---|---|---|
| **Circle** | warm, kind, harmless | Maud (cook), Eldra (lampwright), villagers |
| **Square / block** | stable, solid, trustworthy | Hod (smith), guards, stone-keep NPCs |
| **Triangle** | sharp, dangerous, fast | Goblins, archers, the Pale Hag, bosses |

Each character: pick **one primary** + **one secondary** as a counter-note.
Hod = square primary, circle secondary (round head, friendly under the
gruff). Eldra = circle primary, triangle accent (her lantern flame).

## 3. Primitives vs sculpt — when to use which

For chunky cozy / RuneScape-flavor at the project's style scale:

- **Primitives + bevel** — 90% of assets. Defaults to box + cylinder +
  sphere. Bevel modifier softens corners. Subdivision Surface 1 only
  if a part needs to read as pillow-soft (e.g. Quill's robe folds).
- **Sculpt** — only when the silhouette can't be hit with primitives
  (anatomy details, drapery folds, weathered surfaces). For chunky
  cozy that's a small minority of assets. If a primitive-blocked
  version passes the thumbnail test, ship it.
- **Geometry nodes** — set dressing only (rocks, fences, distributed
  trees). Not characters.

## 4. Palette discipline (single biggest amateur→pro gap)

1. **5–8 hues per asset, never more.** Author from a fixed swatch
   set per character. Eldra: 6 hues (skin / hair / robe / belt / lantern
   metal / lantern flame). More than 8 → muddy at game distance.
2. **One saturation peak per character.** Eldra's flame is the peak;
   everything else is ≤60% saturation. The eye locks onto the peak —
   it should be on the prop that defines the character.
3. **Warm light, cool shadow** (or inverse). Never grey-grey. Author
   highlights with a yellow-orange shift, shadows with a blue-violet
   shift — even on neutral materials.
4. **Implied light: upper-left, ~10–11 o'clock.** All hand-baked
   highlights match. The in-engine directional light matches.
5. **Shared world palette** — every asset pulls from the same 24–48
   swatch set. Lock it in `docs/ART_BIBLE.md` and lint against it.

## 5. Bevel + toon recipe for three.js export

The project is locked on Blender + procedural three.js animation
(rotation of named groups). No skinned bones. The recipe:

### Blender prep

```python
# Per mesh, before bevel:
bpy.ops.mesh.remove_doubles(threshold=0.0001)   # gltf-imported faces have split verts;
                                                 # bevel is a no-op without this
# Bevel modifier — scale-aware:
mod = obj.modifiers.new('Bevel', 'BEVEL')
mod.width = min(0.025, min(dim_x, dim_y, dim_z) * 0.08)   # 8% of smallest dim, capped
mod.segments = 2
mod.limit_method = 'ANGLE'
mod.angle_limit = math.radians(30)
# Apply transforms BEFORE bevel:
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
# Shade smooth:
bpy.ops.object.shade_smooth()
```

### Material recipe — Principled BSDF, no textures by default

```python
mat = bpy.data.materials.new('NPC_Robe')
mat.use_nodes = True
bsdf = mat.node_tree.nodes['Principled BSDF']
bsdf.inputs['Base Color'].default_value = (*hex_to_rgb('#e8d8b0'), 1.0)
bsdf.inputs['Roughness'].default_value = 0.85
bsdf.inputs['Metallic'].default_value = 0.0
# Emissive (optional — for glowing props like the lantern flame):
bsdf.inputs['Emission Color'].default_value = (*hex_to_rgb('#ffd060'), 1.0)
bsdf.inputs['Emission Strength'].default_value = 1.6
```

Critical: glTF DROPS materials that only have `diffuse_color`. Use
`use_nodes = True` + Principled BSDF for every material that should
survive export.

### GLB export — locked to project conventions

```python
bpy.ops.export_scene.gltf(
    filepath=out_path,
    export_format='GLB',
    use_selection=True,
    export_yup=True,                # Blender Z-up → glTF Y-up
    export_apply=True,              # bake transforms (we authored at world pos)
    export_normals=True,
    export_materials='EXPORT',
    export_animations=False,        # engine drives via procedural rotation
    export_skins=False,             # no skeletal rig
    export_image_format='AUTO',
)
```

### Runtime side (already in `src/scene/characters.js`)

- `_loadOnce(key, promiseKey, url)` caches the GLB.
- `toonifyMaterials(scene)` swaps every MeshStandardMaterial to
  MeshToonMaterial with a 4-step grayscale gradient (floor at 200/255
  so OSRS-saturated colors don't crush in shadow).
- `_scaleGLBToHeight(inst, target)` normalizes the rendered height —
  authored heightM (per `npcs.js`) drives final scale.
- `varyInstance(inst, opts)` clones materials + per-instance HSL tint
  so the herd doesn't look like clones.

## 6. Named-group rig (engine contract)

The procedural animation in `src/anim/knight.js`, `goblin.js`, `cow.js`,
`quadruped.js`, `bird.js` rotates named groups. Every character GLB
must expose:

- `Body` (root pivot at hip-center)
- `Head` (pivot at neck-base)
- `Arm_L`, `Arm_R` (pivot at shoulder)
- `Leg_L`, `Leg_R` (pivot at hip)

Quadrupeds add `Tail` and use `Leg_FL / Leg_FR / Leg_BL / Leg_BR` instead.

**Critical sub-part re-parenting:**
- Eyes, hair, hood, hat, brow accessories → child of `Head`
- Sleeve, hand prop (lantern, hammer, staff) → child of `Arm_L` or `Arm_R`
- Belt, drape, sash → child of `Body`
- Boots, shin gear → child of `Leg_L` or `Leg_R`

Without this re-parenting, the procedural rig rotates `Head` and the
hair stays behind. **Marionette-detached-parts is the #1 export bug.**

### The empty-pivot pattern (preferred for new builds)

Per `blender-stylized-game-assets`'s "procedural creature recipe":

- Each animatable joint is a `bpy.ops.object.empty_add(...)` at the
  joint's WORLD position (Head empty at neck-base in world space).
- Each visual mesh is a SEPARATE primitive at its own WORLD position,
  parented to the right empty.
- The runtime traverse picks up the empty by name and rotates it; all
  children mesh follow automatically.

The trap: place each mesh at world position BEFORE parenting. If you
build a mesh at `(0,0,0)` and parent later, Blender writes
`parent_inverse = -empty.world` to keep the mesh at origin, and
runtime rotation is canceled out by the inverse — head animates but
geometry stays put.

## 7. Common defects + fixes

| Defect | Cause | Fix |
|---|---|---|
| Hair / eyes detach from head during walk | Sub-parts not re-parented | Parent to `Head` empty in Blender |
| Bevel does nothing | Faces have split verts (gltf-imported) | `mesh.remove_doubles(threshold=0.0001)` first |
| Material drops on export | Only `diffuse_color` set | Use `use_nodes=True` + Principled BSDF |
| Character renders too dark | Toon gradient floor too low | Already handled in characters.js (200/255 floor) |
| All characters same height | Per-NPC scale not applied | `_scaleGLBToHeight(inst, heightM)` runs at build time |
| Tinting one cottage tints all | Materials shared after `clone(true)` | `varyInstance` clones materials before tint |
| Hooded character invisible from above | Hood occludes face from top-down camera | Author face partially exposed; or remove hood; or split hood mesh |
| Stretched geometry on big footprints | Cottage GLB scaled non-uniformly | Cap scale at 1.0; prefer multiple cottages over one stretched (already in `main.js` cottage placement) |

## 8. Iteration loop — keep it tight

1. Write/edit a focused Blender Python script — one targeted change per pass.
2. `mcp__blender__render_viewport_to_path` → returns a temp path.
3. Read the PNG. Compare to reference / previous render. Identify the largest gap.
4. Make ONE more change. Render. Repeat.

Don't stack 5 changes before rendering — when the result looks wrong
you won't know which change caused it.

## 9. The one rule that bites every time

**Place each mesh at its world position BEFORE parenting** — never at `(0,0,0)`-then-parent. The default `keep_transform=True` on `parent_set` writes the right inverse if the mesh is already in the right world position. If the mesh is at origin, the inverse cancels animation and the rig looks dead.

---

## Checklist — apply to every model rebuild

- [ ] Concept reference at hand (concept-art/<id>.png or sketch description)
- [ ] heightM and primary shape locked
- [ ] Palette: 5–8 hues authored, one saturation peak identified
- [ ] Empties placed for Body / Head / Arm_L / Arm_R / Leg_L / Leg_R at world joint positions
- [ ] Each mesh authored at WORLD position + parented to its empty
- [ ] Sub-parts (hair, eyes, hand-prop) re-parented to Head / Arm_*
- [ ] Materials use `use_nodes = True` with Principled BSDF
- [ ] Saturation peak material has Emission set (lantern flame, gem core, etc.)
- [ ] Per mesh: `remove_doubles` → Bevel modifier (scale-aware) → shade_smooth
- [ ] `transform_apply(rotation=True, scale=True, location=False)` before bevel
- [ ] Thumbnail test passed (render at 64×64, character readable)
- [ ] GLB exported with the locked settings
- [ ] In-game verify: `_scaleGLBToHeight` lands at expected stature
- [ ] In-game verify: walk animation drives Head + Arms + Legs without parts detaching
