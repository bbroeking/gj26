---
type: pipeline
tags: [blender, modeling, glb, toon-shading, rigging]
status: draft
updated: 2026-06-13
sources: ["docs/BLENDER_PIPELINE.md", "docs/MODEL_REBUILD_RECIPE.md", "docs/ASSET_PIPELINE.md", "docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md"]
---

# Blender Pipeline

The Blender workflow for producing low-poly stylized GLBs for Wayfinder: primitives + scale-aware bevel + Principled BSDF materials → named-group empty rig → GLB export.

## One-time setup

1. Enable **Node Wrangler** and **Import-Export: glTF 2.0** add-ons (built-in).
2. Set units to **Metric · 1.0 m** (Properties → Scene → Units). 1 unit = 1 tile = 1 m.
3. Blender's +Y up / -Z forward: the glTF exporter auto-converts to glTF/three.js convention.
4. Install Blender 4.x. The MCP Blender tools assume Blender is running with the MCP add-on enabled.

## Modeling approach

**Primitives + bevel** covers 90% of assets. Sculpting is reserved for organic shapes that primitives can't hit; Geometry Nodes are set-dressing only (rocks, fences), never characters.

The **thumbnail test** drives design: render at 64×64 black-on-white from the actual game camera angle (~45° pitch). If the character isn't identifiable from the silhouette alone, redesign.

**Shape language** (from `docs/MODEL_REBUILD_RECIPE.md`):
- Circle → warm/kind (villagers, cook)
- Square/block → solid/trustworthy (smith, guards)
- Triangle → sharp/dangerous (enemies, bosses)

Each character gets one primary + one secondary shape as a counter-note.

## The bevel + toon recipe

Validated recipe from `feedback_blender_bevel_pipeline` project memory (OSRS-style, Principled BSDF + scale-aware bevel + toon shading):

```python
# 1. Weld split verts first — GLB-imported faces have split verts; bevel is a no-op without this
bpy.ops.mesh.remove_doubles(threshold=0.0001)

# 2. Apply transforms BEFORE bevel (wrong order breaks animation)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

# 3. Bevel modifier — scale-aware
mod = obj.modifiers.new('Bevel', 'BEVEL')
mod.width = min(0.025, min(dim_x, dim_y, dim_z) * 0.08)   # 8% of smallest dim, capped
mod.segments = 2
mod.limit_method = 'ANGLE'
mod.angle_limit = math.radians(30)

# 4. Shade smooth
bpy.ops.object.shade_smooth()
```

## Material recipe

**Principled BSDF only** — glTF silently drops materials that only have `diffuse_color` set:

```python
mat = bpy.data.materials.new('NPC_Robe')
mat.use_nodes = True
bsdf = mat.node_tree.nodes['Principled BSDF']
bsdf.inputs['Base Color'].default_value = (*hex_to_rgb('#e8d8b0'), 1.0)
bsdf.inputs['Roughness'].default_value = 0.85   # 0.7–0.95 for matte
bsdf.inputs['Metallic'].default_value = 0.0
# Emissive for glowing props (lantern flame, gem):
bsdf.inputs['Emission Color'].default_value = (*hex_to_rgb('#ffd060'), 1.0)
bsdf.inputs['Emission Strength'].default_value = 1.6
```

**Palette discipline** (from `docs/MODEL_REBUILD_RECIPE.md`): 5–8 hues per asset, never more. One saturation peak per character — the prop that defines the character. Warm highlights / cool shadows, implied light at ~10–11 o'clock.

## Named-group empty rig (engine contract)

The procedural animation runtime rotates named empty objects. Every character GLB must expose these named empties:

**Biped** (`Body / Head / Arm_L / Arm_R / Leg_L / Leg_R`): player, NPCs, humanoid enemies.

**Quadruped** (`Body / Head / Tail / Leg_FL / Leg_FR / Leg_BL / Leg_BR`): cow, boar, wolf, hedgemother.

**Bird** (`Body / Head / Wing_L / Wing_R / Leg_L / Leg_R / Tail`): chickens, falcons.

**Static**: props and decoration — no rig empties required.

Each empty's origin sits at the **pivot of motion** (Arm_L origin at shoulder, Leg_FL origin at hip joint). Sub-parts must be re-parented to the correct empty:
- Eyes, hair, hat → child of `Head`
- Hand props (lantern, hammer) → child of `Arm_L` or `Arm_R`
- Belt, drape → child of `Body`
- Boots, shin gear → child of `Leg_L` or `Leg_R`

Missing re-parenting causes the #1 export bug: marionette-detached parts where `Head` rotates but hair stays behind.

## The two-tier root for GLB orientation

From `feedback_glb_orientation_two_tier_root` project memory: the engine walk animator needs limb local X = world +X. Use a **Root + RigPivot** two-empty hierarchy; set rotations **last** (after all mesh parenting is done). This is required for skeletal Meshy rigs going into Godot's `AnimationPlayer`.

## The parent_inverse trap

**Author each mesh at its TRUE world position BEFORE parenting** — never at `(0,0,0)` then parent. If a mesh is built at origin and parented to an empty, Blender writes `parent_inverse = -empty.world` which cancels runtime rotation. The rig animates, geometry stays put.

## GLB export — locked settings

```python
bpy.ops.export_scene.gltf(
    filepath=out_path,
    export_format='GLB',
    use_selection=True,
    export_yup=True,          # Blender Z-up → glTF Y-up
    export_apply=True,        # bake transforms (authored at world pos)
    export_normals=True,
    export_materials='EXPORT',
    export_animations=False,  # engine drives via procedural rotation
    export_skins=False,       # no skeletal rig for manually modeled assets
    export_image_format='AUTO',
)
```

Save to `models/<slug>.glb`. GLB size target: 30–150 KB. >300 KB usually means a stray high-poly mesh.

## Outline strategy (painted pipeline)

Suffix conventions enforced by `src/scene/painted_materials.js`:
- `_ruffle` → small surface bumps, skip outline (prevents silhouette fragmentation)
- `_detail` → small accessories overlapping a parent shape, skip outline
- `_line` → a thin sliver that IS a drawn line (eyebrow, mouth seam) — skip outline on the mesh, it is the line

Most characters need at least the eye/brow/mouth row in the outline-skip list.

## Pre-ship checklist

- [ ] Thumbnail test passed (64×64, character readable)
- [ ] 5–8 hues in palette, one saturation peak identified
- [ ] Empties placed for all rig joints at world joint positions
- [ ] Each mesh authored at WORLD position + parented to its empty
- [ ] Sub-parts (hair, eyes, hand props) re-parented to Head / Arm_*
- [ ] `use_nodes=True` + Principled BSDF on every material
- [ ] `remove_doubles` → bevel modifier → shade_smooth per mesh
- [ ] `transform_apply(rotation=True, scale=True)` before bevel
- [ ] GLB exported with locked settings; size 30–150 KB
- [ ] Validated in https://gltf-viewer.donmccurdy.com before integrating

## See also

- [[Asset Pipeline]] — where Blender fits in the Midjourney → Meshy → Blender → game flow
- [[Animation Pipeline]] — procedural vs. skinned animation; what the rig empties drive
- [[Art Bible]] — the visual style target these models must match
- [[Godot Pipeline]] — how the GLBs are imported and used in-engine

## Sources

- `docs/BLENDER_PIPELINE.md`
- `docs/MODEL_REBUILD_RECIPE.md`
- `docs/ASSET_PIPELINE.md`
- `docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md`
