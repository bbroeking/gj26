"""Rebuild Eldra the Lampwright as `models/npc_eldra_v3.glb`.

Proof-of-concept of the model recipe in docs/MODEL_REBUILD_RECIPE.md.
Runnable via:
  - mcp__blender__execute_blender_code (paste this whole file as the `code` arg)
  - or Blender Text Editor: open this file, click "Run Script"
  - or `blender --background --python scripts/rebuild_eldra.py` (CLI)

Authored to lock down the new pattern so we can crank out the rest of
the village + the bosses on the same template.

Eldra design summary:
  - Role: village lampwright. Carries a glowing lantern.
  - heightM: 1.55 (per src/data/npcs.js)
  - Primary shape: circle (warm, kind). Secondary: triangle accent (the flame).
  - Palette (6 hues):
      skin   = #f0d8b8   (cream)
      hair   = #d8d4c8   (gray-white)
      robe   = #c8b888   (muted ochre)
      belt   = #5a3a1a   (dark wood)
      lantern_metal = #b88440  (cool gold)
      lantern_flame = #ffd060  (warm gold + emissive — saturation peak)
  - Crown silhouette mark: lantern in right hand (the prop that names her).
  - Rig: Body / Head / Arm_L / Arm_R / Leg_L / Leg_R as empties; mesh
    sub-parts (hair, eyes, lantern, hand) parented to the right empty.
"""

import bpy
import math
import os

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def hex_rgb(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16) / 255.0,
            int(h[2:4], 16) / 255.0,
            int(h[4:6], 16) / 255.0)

def make_material(name, color_hex, roughness=0.85, emissive_hex=None, emission_strength=0.0):
    """Principled BSDF — survives glTF export. Optional emission for the
    saturation peak (lantern flame). Gets toonified on the engine side."""
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    if not bsdf:
        # Blender 4+ renames; try alternate.
        for n in mat.node_tree.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                bsdf = n; break
    bsdf.inputs['Base Color'].default_value = (*hex_rgb(color_hex), 1.0)
    bsdf.inputs['Roughness'].default_value = roughness
    if 'Metallic' in bsdf.inputs:
        bsdf.inputs['Metallic'].default_value = 0.0
    if emissive_hex and 'Emission Color' in bsdf.inputs:
        bsdf.inputs['Emission Color'].default_value = (*hex_rgb(emissive_hex), 1.0)
        bsdf.inputs['Emission Strength'].default_value = emission_strength
    elif emissive_hex and 'Emission' in bsdf.inputs:
        # Older Blender — single Emission slot expects RGBA.
        bsdf.inputs['Emission'].default_value = (*hex_rgb(emissive_hex), 1.0)
        if 'Emission Strength' in bsdf.inputs:
            bsdf.inputs['Emission Strength'].default_value = emission_strength
    return mat

def add_box(name, world_center, dims, mat, parent, bevel_width=0.020):
    """Add a single beveled box centered at `world_center` with `dims`
    in world units. Apply transforms, bevel, smooth-shade, then parent
    to `parent`. Returns the new mesh object."""
    cx, cy, cz = world_center
    sx, sy, sz = dims
    bpy.ops.mesh.primitive_cube_add(size=2, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    o.scale = (sx / 2, sy / 2, sz / 2)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    # Remove duplicate verts so bevel actually beveling, not no-oping.
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode='OBJECT')
    # Scale-aware bevel — 8% of smallest dim, capped.
    mod = o.modifiers.new('Bevel', 'BEVEL')
    mod.width = min(bevel_width, min(sx, sy, sz) * 0.08)
    mod.segments = 2
    mod.limit_method = 'ANGLE'
    mod.angle_limit = math.radians(30)
    bpy.ops.object.shade_smooth()
    # Parent — keep_transform writes the right parent_inverse because
    # we placed at world position above.
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    return o

def add_sphere(name, world_center, radius, mat, parent, segments=12, rings=8):
    cx, cy, cz = world_center
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, segments=segments,
                                          ring_count=rings, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.shade_smooth()
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    return o

def add_cylinder(name, world_center, radius, height, mat, parent, vertices=12):
    cx, cy, cz = world_center
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=height,
                                         vertices=vertices, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    return o

def add_empty(name, location, parent=None):
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=location)
    o = bpy.context.active_object
    o.name = name
    if parent is not None:
        bpy.ops.object.select_all(action='DESELECT')
        o.select_set(True)
        parent.select_set(True)
        bpy.context.view_layer.objects.active = parent
        bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    return o

# ---------------------------------------------------------------------------
# 1. Wipe — idempotent rebuild
# ---------------------------------------------------------------------------

PREFIXES = ('Eldra', 'EldraPart', 'Body', 'Head', 'Arm_', 'Leg_', 'Hair',
            'Eye_', 'Mouth', 'Lantern', 'Belt', 'Robe', 'Hand_')
for o in list(bpy.data.objects):
    if o.name.startswith(PREFIXES):
        bpy.data.objects.remove(o, do_unlink=True)
# Strip orphan meshes / mats so re-runs don't bloat the .blend.
for m in list(bpy.data.meshes):
    if m.users == 0: bpy.data.meshes.remove(m)
for m in list(bpy.data.materials):
    if m.users == 0: bpy.data.materials.remove(m)

# ---------------------------------------------------------------------------
# 2. Materials
# ---------------------------------------------------------------------------

MAT_SKIN     = make_material('Eldra_Skin',     '#f0d8b8', roughness=0.78)
MAT_HAIR     = make_material('Eldra_Hair',     '#d8d4c8', roughness=0.92)
MAT_ROBE     = make_material('Eldra_Robe',     '#c8b888', roughness=0.88)
MAT_BELT     = make_material('Eldra_Belt',     '#5a3a1a', roughness=0.85)
MAT_BOOT     = make_material('Eldra_Boot',     '#3a281a', roughness=0.85)
MAT_LANTERN  = make_material('Eldra_Lantern',  '#b88440', roughness=0.40)
MAT_FLAME    = make_material('Eldra_Flame',    '#ffd060', roughness=0.30,
                              emissive_hex='#ffe09a', emission_strength=2.5)
MAT_EYE      = make_material('Eldra_Eye',      '#1a1410', roughness=0.40)

# ---------------------------------------------------------------------------
# 3. Empties — the engine-readable rig pivots, in world space
# ---------------------------------------------------------------------------
# Eldra is 1.55m tall. Approximate proportions (chunky cozy):
#   feet at z=0
#   knees at z=0.40
#   hip-center at z=0.78  (Body pivot)
#   shoulder at z=1.25  (Arm_* pivots)
#   neck-base at z=1.30 (Head pivot)
#   head crown at z=1.55

H_TOTAL    = 1.55
Z_HIP      = 0.78
Z_SHOULDER = 1.25
Z_NECK     = 1.30
Z_HEAD_TOP = 1.50

root      = add_empty('EldraRoot', (0, 0, 0))
body_emp  = add_empty('Body',   (0,     0,    Z_HIP),     parent=root)
head_emp  = add_empty('Head',   (0,     0,    Z_NECK),    parent=root)
arm_l_emp = add_empty('Arm_L',  (0,    -0.18, Z_SHOULDER), parent=root)
arm_r_emp = add_empty('Arm_R',  (0,     0.18, Z_SHOULDER), parent=root)
leg_l_emp = add_empty('Leg_L',  (0,    -0.10, Z_HIP),      parent=root)
leg_r_emp = add_empty('Leg_R',  (0,     0.10, Z_HIP),      parent=root)

# ---------------------------------------------------------------------------
# 4. Body — robe column (her primary silhouette is a tapered column)
# ---------------------------------------------------------------------------

# Robe lower (slightly wider at hem so silhouette tapers downward)
add_box('Robe_Lower', (0, 0, 0.40),  (0.36, 0.42, 0.78), MAT_ROBE, body_emp)
# Robe upper — narrower
add_box('Robe_Upper', (0, 0, 1.04),  (0.32, 0.36, 0.40), MAT_ROBE, body_emp)
# Belt — dark accent at waist; reads clearly from above
add_box('Belt',       (0, 0, 0.84),  (0.34, 0.38, 0.06), MAT_BELT, body_emp)

# ---------------------------------------------------------------------------
# 5. Head — circle primary; pale hair under hood-ish silhouette
# ---------------------------------------------------------------------------

# Head ovoid — sit it ON the robe upper (top of robe at z=1.24, head bottom at robe top + tiny overlap).
# Squashed sphere reads as a kindly oval from above.
add_sphere('Head_Mesh', (0, 0, 1.36), 0.13, MAT_SKIN, head_emp)
# Hair tuft — gray-white cap. Slight overhang toward back to read at top-down.
add_box('Hair_Cap',  (0, 0, 1.43),       (0.24, 0.26, 0.10), MAT_HAIR, head_emp)
add_box('Hair_Back', (-0.04, 0, 1.34),   (0.18, 0.24, 0.18), MAT_HAIR, head_emp)
# Eyes — pushed FORWARD onto the front face of the head (avoid the
# parent_inverse trap; eyes must be at world position, not (0,0,0)).
EYE_X = 0.10   # front face of head + 0.005u for visible offset
add_sphere('Eye_L', (EYE_X,  -0.05, 1.36), 0.018, MAT_EYE, head_emp, segments=8, rings=6)
add_sphere('Eye_R', (EYE_X,   0.05, 1.36), 0.018, MAT_EYE, head_emp, segments=8, rings=6)

# ---------------------------------------------------------------------------
# 6. Arms — short sleeves, straight at idle (hands hanging)
# ---------------------------------------------------------------------------
# Arms positioned OUTSIDE the robe (robe edge at y=±0.18 — arms must be at y=±0.28+ to peek).
# Arm_L: empty hand
add_box('Arm_L_Sleeve', (0, -0.28, 1.07),  (0.10, 0.10, 0.36), MAT_ROBE, arm_l_emp)
add_sphere('Hand_L',    (0, -0.28, 0.83), 0.055, MAT_SKIN, arm_l_emp, segments=10, rings=8)

# Arm_R: holds the lantern. Lantern hangs forward + outward so it reads from any angle.
add_box('Arm_R_Sleeve', (0,  0.28, 1.09),  (0.10, 0.10, 0.32), MAT_ROBE, arm_r_emp)
add_sphere('Hand_R',    (0,  0.28, 0.89), 0.055, MAT_SKIN, arm_r_emp, segments=10, rings=8)
# Lantern body — cool gold metal cylinder
add_cylinder('Lantern_Body',  (0.10, 0.32, 0.74), 0.07, 0.18, MAT_LANTERN, arm_r_emp, vertices=12)
# Lantern flame — warm gold sphere + emissive (the saturation peak).
add_sphere('Lantern_Flame',   (0.10, 0.32, 0.83), 0.055, MAT_FLAME, arm_r_emp, segments=10, rings=8)
# Lantern handle — small loop on top, parented to arm so it follows.
add_box('Lantern_Handle',     (0.10, 0.32, 0.91), (0.04, 0.12, 0.04), MAT_LANTERN, arm_r_emp)

# ---------------------------------------------------------------------------
# 7. Legs — short, hidden by robe but pivot present so walk-bob reads
# ---------------------------------------------------------------------------
# Robe covers most of leg; we only need the boot peeking out so the
# walk animation has a visible foot to swing.
add_box('Leg_L_Boot', (0, -0.10, 0.06), (0.12, 0.14, 0.12), MAT_BOOT, leg_l_emp)
add_box('Leg_R_Boot', (0,  0.10, 0.06), (0.12, 0.14, 0.12), MAT_BOOT, leg_r_emp)

# ---------------------------------------------------------------------------
# 8. Export
# ---------------------------------------------------------------------------

bpy.ops.object.select_all(action='DESELECT')
# Select root + every child (recursive). glTF exporter follows the hierarchy.
def select_subtree(obj):
    obj.select_set(True)
    for c in obj.children:
        select_subtree(c)
select_subtree(root)
bpy.context.view_layer.objects.active = root

# Project root resolution — fall back to user home if PROJECT_ROOT env unset.
PROJECT_ROOT = os.environ.get('GJ26_PROJECT_ROOT', '/Users/bbroeking/projects/gj26')
out_path = os.path.join(PROJECT_ROOT, 'models', 'npc_eldra_v3.glb')

bpy.ops.export_scene.gltf(
    filepath=out_path,
    export_format='GLB',
    use_selection=True,
    export_yup=True,            # Blender Z-up → glTF Y-up
    export_apply=True,          # bake transforms — meshes were authored at world pos
    export_normals=True,
    export_materials='EXPORT',
    export_animations=False,    # engine drives via procedural rotation
    export_skins=False,         # no skeletal rig
    export_image_format='AUTO',
)

print(f"\n=== Exported {out_path} ===")
print("Switch the engine to use it:")
print("  src/scene/characters.js → loadEldraGLB() default url='models/npc_eldra_v3.glb'")
print()
print("Named groups exported (engine reads these):")
for name in ('Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R'):
    o = bpy.data.objects.get(name)
    if o:
        print(f"  {name} — {len(o.children)} direct children")
