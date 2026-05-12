"""Rebuild Eldra the Lampwright as `models/npc_eldra_v3.glb`.

V3.2 — fixes from v3.1:
  - Floating head (added a neck cylinder + lowered head sphere so they overlap)
  - Hair: replaced smooth dome with 5 windswept spike tufts angled up+back
  - Added white chin beard tuft (concept clearly shows beard)
  - Staff: knobby (3 stacked cylinders w/ varying radius) + curved cane crook
  - Lanterns: round-bellied (sphere body + cone cap + ring base) instead of cubes
  - Herb sprig poking out of backpack (green leaf cluster)
  - Embroidered stripe on the vest (thin contrasting band)

Runnable via:
  - mcp__blender__execute_blender_code (paste this whole file)
  - or Blender Text Editor: open this file, click "Run Script"
  - or `blender --background --python scripts/rebuild_eldra.py` (CLI)

Eldra design — matched to concept-art/npc-eldra-lampwright.png:
  - Role: village lampwright. Carries a staff with two small lanterns + a herb backpack.
  - heightM 1.55 (engine normalizes via _scaleGLBToHeight at runtime).
  - Squat / chibi proportions — body short, head + voluminous hair add ~40% of height.
  - Primary shape: round (kindly). Saturation peak: lantern flames.
  - Palette (8 hues — at the cap):
      skin     = #f0c8a8   (peachy pink — concept's warm skin)
      hair     = #f4f0e8   (very pale white-cream, voluminous)
      undertunic = #e8d8b8 (cream, visible at shoulders)
      vest     = #a87a48   (ochre-brown, layered over the tunic)
      scarf    = #4a6878   (dark teal-blue, the patterned scarf)
      belt     = #5a3a1a   (dark wood-leather)
      trousers = #7a8a78   (olive-sage)
      backpack = #6a4a2a   (medium brown leather)
      staff    = #6a4a2a   (medium brown — same as backpack, shares mat)
      lantern_metal = #b88440  (cool gold)
      lantern_flame = #ffd060  (warm gold + emissive — saturation peak)
  - Crown silhouette mark: the staff with two hanging lanterns rising past her shoulder.
  - Rig: Body / Head / Arm_L / Arm_R / Leg_L / Leg_R as empties at the joint
    pivots; mesh sub-parts (hair, scarf, face details, lanterns, backpack)
    parented to the right empty so the procedural rotation moves them.
"""

import bpy
import math
import os

# ---------------------------------------------------------------------------
# Helpers — same recipe as v3, with the parent_inverse trap warning baked in.
# ---------------------------------------------------------------------------

def hex_rgb(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16) / 255.0,
            int(h[2:4], 16) / 255.0,
            int(h[4:6], 16) / 255.0)

def make_material(name, color_hex, roughness=0.85, emissive_hex=None, emission_strength=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    if not bsdf:
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
        bsdf.inputs['Emission'].default_value = (*hex_rgb(emissive_hex), 1.0)
        if 'Emission Strength' in bsdf.inputs:
            bsdf.inputs['Emission Strength'].default_value = emission_strength
    return mat

def add_box(name, world_center, dims, mat, parent, bevel_width=0.020, rot=(0,0,0)):
    cx, cy, cz = world_center
    sx, sy, sz = dims
    bpy.ops.mesh.primitive_cube_add(size=2, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    o.scale = (sx / 2, sy / 2, sz / 2)
    o.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    bpy.ops.object.mode_set(mode='OBJECT')
    mod = o.modifiers.new('Bevel', 'BEVEL')
    mod.width = min(bevel_width, min(sx, sy, sz) * 0.08)
    mod.segments = 2
    mod.limit_method = 'ANGLE'
    mod.angle_limit = math.radians(30)
    bpy.ops.object.shade_smooth()
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    return o

def add_sphere(name, world_center, radius, mat, parent, segments=12, rings=8, scale=(1,1,1)):
    cx, cy, cz = world_center
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, segments=segments,
                                          ring_count=rings, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    if scale != (1, 1, 1):
        o.scale = scale
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

def add_cylinder(name, world_center, radius, height, mat, parent, vertices=12, rot=(0,0,0)):
    cx, cy, cz = world_center
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=height,
                                         vertices=vertices, location=(cx, cy, cz))
    o = bpy.context.active_object
    o.name = name
    o.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    return o

def add_cone(name, world_center, radius_base, radius_tip, height, mat, parent,
             vertices=8, rot=(0, 0, 0)):
    """Cone primitive for hair strands / pointed tufts. Default orientation:
    base (wider, radius=radius_base) at top (+Z), tip (radius=radius_tip) at
    bottom (-Z) — natural for a strand hanging from a chin or scalp."""
    cx, cy, cz = world_center
    # radius1 is at -Z, radius2 is at +Z. We want tip at -Z (bottom), base at +Z (top).
    bpy.ops.mesh.primitive_cone_add(
        radius1=radius_tip, radius2=radius_base, depth=height,
        vertices=vertices, location=(cx, cy, cz),
    )
    o = bpy.context.active_object
    o.name = name
    o.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    return o

def add_empty(name, location, parent=None, rot=(0, 0, 0)):
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=location)
    o = bpy.context.active_object
    o.name = name
    o.rotation_euler = rot
    if parent is not None:
        bpy.ops.object.select_all(action='DESELECT')
        o.select_set(True)
        parent.select_set(True)
        bpy.context.view_layer.objects.active = parent
        bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    return o

# ---------------------------------------------------------------------------
# Coordinate transform — author with face on +X for readability, but the
# engine wants the model facing -Y in Blender (= +Z three.js after Y-up,
# which is the convention `src/anim/knight.js` assumes for forward/back limb
# swing). We can't fix this with a root rotation: any rotation higher up
# in the rig propagates into each limb empty's local frame, so when the
# animator does Body.rotation.x it ends up rotating around the model's
# forward axis (lateral splay) instead of the lateral axis (forward swing).
# Wrapping the helpers here transforms every input position/dim/rotation as
# a -90° rotation around Z, so the AUTHORED-IN-CODE +X frame ends up at -Y
# in Blender world. After Y-up, the model lands facing +Z three.js with each
# limb empty at world identity — local X = world +X = lateral. Walk works.
_orig_add_box      = add_box
_orig_add_sphere   = add_sphere
_orig_add_cylinder = add_cylinder
_orig_add_cone     = add_cone
_orig_add_empty    = add_empty

def _xform_pos(p):
    x, y, z = p
    return (y, -x, z)

def _xform_dims(d):
    sx, sy, sz = d
    return (sy, sx, sz)

def _xform_rot(r):
    rx, ry, rz = r
    return (ry, -rx, rz)

def _xform_scale(s):
    sx, sy, sz = s
    return (sy, sx, sz)

def add_box(name, world_center, dims, mat, parent, bevel_width=0.020, rot=(0, 0, 0)):
    return _orig_add_box(name, _xform_pos(world_center), _xform_dims(dims), mat, parent,
                         bevel_width=bevel_width, rot=_xform_rot(rot))

def add_sphere(name, world_center, radius, mat, parent, segments=12, rings=8, scale=(1, 1, 1)):
    return _orig_add_sphere(name, _xform_pos(world_center), radius, mat, parent,
                             segments=segments, rings=rings, scale=_xform_scale(scale))

def add_cylinder(name, world_center, radius, height, mat, parent, vertices=12, rot=(0, 0, 0)):
    return _orig_add_cylinder(name, _xform_pos(world_center), radius, height, mat, parent,
                               vertices=vertices, rot=_xform_rot(rot))

def add_cone(name, world_center, radius_base, radius_tip, height, mat, parent,
             vertices=8, rot=(0, 0, 0)):
    return _orig_add_cone(name, _xform_pos(world_center), radius_base, radius_tip, height,
                          mat, parent, vertices=vertices, rot=_xform_rot(rot))

def add_empty(name, location, parent=None, rot=(0, 0, 0)):
    return _orig_add_empty(name, _xform_pos(location), parent=parent, rot=_xform_rot(rot))

# ---------------------------------------------------------------------------
# Ladder-3 helpers — Blender-native primitives that produce organic shapes
# instead of stacking spheres.
# ---------------------------------------------------------------------------

def add_metaball_blob(name, world_origin, balls, mat, parent,
                       resolution=0.04, threshold=0.6):
    """Build a single metaball OBJECT containing many ELEMENT spheres that
    merge into one organic blob. Ideal for hair tufts, beard, fur masses —
    anything where multiple sphere centers should melt together.

    Args
    ----
    world_origin : (x, y, z)  metaball object's anchor in the un-transformed
                              authoring frame (face on +X).
    balls : list of (local_pos, radius)  or  (local_pos, radius, scale_xyz)
            local_pos is RELATIVE to world_origin in the authoring frame.
    resolution : metaball voxel size; lower = finer surface (slower).
    threshold : iso-value for the merging surface; higher = tighter blobs.
    """
    mb_data = bpy.data.metaballs.new(name + "_meta")
    mb_data.resolution = resolution
    mb_data.threshold = threshold

    # Apply the same coord-transform to local positions/scales as our other
    # wrappers, so metaball authoring stays in the +X-facing source frame.
    for entry in balls:
        if len(entry) == 2:
            lp, r = entry; scale = (1, 1, 1)
        else:
            lp, r, scale = entry
        elem = mb_data.elements.new(type='BALL')
        elem.co = _xform_pos(lp)
        elem.radius = r
        sx, sy, sz = _xform_scale(scale)
        elem.size_x, elem.size_y, elem.size_z = sx, sy, sz

    mb_obj = bpy.data.objects.new(name + "_metaobj", mb_data)
    bpy.context.scene.collection.objects.link(mb_obj)
    mb_obj.location = _xform_pos(world_origin)

    # Convert metaballs to mesh for export. The convert operator returns a
    # MESH that replaces the metaball object in-place.
    bpy.ops.object.select_all(action='DESELECT')
    mb_obj.select_set(True)
    bpy.context.view_layer.objects.active = mb_obj
    bpy.ops.object.convert(target='MESH')
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()

    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    return o

# ---------------------------------------------------------------------------
# 1. Wipe — idempotent rebuild
# ---------------------------------------------------------------------------

PREFIXES = (
    'Eldra', 'Body', 'Head', 'Arm_', 'Leg_',
    'Hair', 'Eye_', 'Mouth', 'Nose', 'Brow', 'Cheek',
    'Tunic', 'Vest', 'Scarf', 'Belt', 'Pouch', 'Trousers', 'Foot',
    'Hand_', 'Sleeve_', 'Staff', 'Lantern', 'Backpack', 'Strap',
    'Robe',  # leftover names from the prior v3
)
for o in list(bpy.data.objects):
    if o.name.startswith(PREFIXES):
        bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes):
    if m.users == 0: bpy.data.meshes.remove(m)
for m in list(bpy.data.materials):
    if m.users == 0: bpy.data.materials.remove(m)

# ---------------------------------------------------------------------------
# 2. Materials — 11 hues to match the concept's layered palette
# ---------------------------------------------------------------------------

# Locked palette — 10 hues per `docs/build-plans/eldra.md` § 2.
# `leather` is unified across belt + pouch + backpack + staff + sandal-wraps.
# `herb` is reused for backpack sprigs AND the vest hem stripe.
# Eyes use `leather` color (no separate eye material).
MAT_SKIN        = make_material('Eldra_Skin',        '#f0c8a8', roughness=0.78)
MAT_HAIR        = make_material('Eldra_Hair',        '#f4f0e8', roughness=0.92)
MAT_TUNIC       = make_material('Eldra_Tunic',       '#e8d8b8', roughness=0.88)
MAT_VEST        = make_material('Eldra_Vest',        '#a87a48', roughness=0.85)
MAT_SCARF       = make_material('Eldra_Scarf',       '#4a6878', roughness=0.85)
MAT_TROUSERS    = make_material('Eldra_Trousers',    '#7a8a78', roughness=0.88)
MAT_LEATHER     = make_material('Eldra_Leather',     '#6a4a2a', roughness=0.85)
MAT_HERB        = make_material('Eldra_Herb',        '#5a7848', roughness=0.85)
MAT_LANTERN     = make_material('Eldra_Lantern',     '#b88440', roughness=0.40)
MAT_FLAME       = make_material('Eldra_Flame',       '#ffd060', roughness=0.30,
                                emissive_hex='#ffe09a', emission_strength=2.5)
# Aliases for code that expected the older split-out materials
MAT_BELT    = MAT_LEATHER
MAT_PATTERN = MAT_HERB
MAT_EYE     = MAT_LEATHER  # eyes are dark-brown ovals, reusing leather
MAT_NOSE    = MAT_SKIN     # nose color = skin per plan (no separate hue)

# ---------------------------------------------------------------------------
# 3. Empties — joint pivots in WORLD space.
# ---------------------------------------------------------------------------
# Squat proportions per concept: total ~1.55u with head + hair occupying upper 35%.

Z_HIP      = 0.55     # body / hip pivot
Z_SHOULDER = 0.95     # arm pivots
Z_NECK     = 1.00     # head pivot (just below the head's underside)
Z_HEAD_TOP = 1.55

# Single-tier root: the helper wrappers up top remap our +X-facing source
# coordinates into -Y-facing Blender world (= +Z three.js after Y-up). No
# rotation tricks at the rig level — every limb empty stays at world
# identity, so its local X = world +X = lateral, and rotation.x in the walk
# animator becomes a real forward/back swing.
root      = add_empty('EldraRoot', (0, 0, 0))
body_emp  = add_empty('Body',   (0,     0,    Z_HIP),     parent=root)
head_emp  = add_empty('Head',   (0,     0,    Z_NECK),    parent=root)
arm_l_emp = add_empty('Arm_L',  (0,    -0.18, Z_SHOULDER), parent=root)
arm_r_emp = add_empty('Arm_R',  (0,     0.18, Z_SHOULDER), parent=root)
leg_l_emp = add_empty('Leg_L',  (0,    -0.10, Z_HIP),      parent=root)
leg_r_emp = add_empty('Leg_R',  (0,     0.10, Z_HIP),      parent=root)

# ---------------------------------------------------------------------------
# 4. Body — chunky barrel, layered tunic + vest + scarf + belt
# ---------------------------------------------------------------------------

# Cream undershirt (tunic) — visible at shoulders + a peek above the vest.
# Slimmed: (0.34, 0.28) was (0.40, 0.34) — torso now ~22% of height (was 26%).
add_box('Tunic_Body',  (0, 0, 0.78), (0.34, 0.28, 0.36), MAT_TUNIC, body_emp)

# Neck — short skin cylinder bridging tunic top to head bottom (fixes "floating head")
add_cylinder('Neck',   (0, 0, 1.02), 0.09, 0.14, MAT_SKIN, body_emp, vertices=10)

# Vest — ochre layer over the tunic. Slightly wider so it reads as an outer garment.
add_box('Vest_Body',   (0, 0, 0.72), (0.38, 0.32, 0.34), MAT_VEST,  body_emp)
# Vest embroidery stripe — sage-green band along the bottom hem of the vest
# (per concept art; was incorrectly at chest height in v3.x). Plan z=0.62.
add_box('Vest_Stripe', (0.18, 0, 0.62), (0.02, 0.30, 0.04), MAT_HERB, body_emp,
        bevel_width=0.005)
# Vest front cord — thin vertical brown braid down the center-front of the vest
add_box('Vest_Cord', (0.20, 0, 0.74), (0.02, 0.025, 0.20), MAT_LEATHER, body_emp,
        bevel_width=0.003)
# Vest chest highlight — small cream rectangle showing the tunic peek
# at the V-neck (concept shows a clear cream V above the scarf at the chest)
add_box('Vest_ChestPeek', (0.19, 0, 0.86), (0.02, 0.16, 0.04), MAT_TUNIC, body_emp,
        bevel_width=0.003)
# Vest buttons — three small dark spheres down the front
add_sphere('Vest_Button_a', (0.21, 0, 0.80), 0.012, MAT_LEATHER, body_emp, segments=8, rings=6)
add_sphere('Vest_Button_b', (0.21, 0, 0.74), 0.012, MAT_LEATHER, body_emp, segments=8, rings=6)
add_sphere('Vest_Button_c', (0.21, 0, 0.68), 0.012, MAT_LEATHER, body_emp, segments=8, rings=6)
# Vest skirt extension — flares slightly down toward hips
add_box('Vest_Skirt',  (0, 0, 0.55), (0.36, 0.30, 0.10), MAT_VEST,  body_emp)

# Scarf — wraps around the neck. Slimmed alongside the torso.
add_box('Scarf_Front', (0.04, 0,    1.00), (0.26, 0.26, 0.12), MAT_SCARF, body_emp)
add_box('Scarf_Tail',  (-0.04, 0.08, 0.92), (0.04, 0.08, 0.18), MAT_SCARF, body_emp)
# Scarf pattern accents — small lighter-teal accent boxes form the cross/
# lozenge pattern visible in concept. Use MAT_TUNIC (cream) for contrast.
add_box('Scarf_Accent_a', (0.18, -0.10, 1.02), (0.02, 0.025, 0.025), MAT_TUNIC, body_emp,
        bevel_width=0.003)
add_box('Scarf_Accent_b', (0.18,  0.10, 1.02), (0.02, 0.025, 0.025), MAT_TUNIC, body_emp,
        bevel_width=0.003)
add_box('Scarf_Accent_c', (0.18, 0,    0.96), (0.02, 0.025, 0.025), MAT_TUNIC, body_emp,
        bevel_width=0.003)

# Belt — dark line at waist
add_box('Belt',        (0, 0, 0.55), (0.36, 0.30, 0.04), MAT_BELT, body_emp)
# Belt pouch — small bag hanging at the side
add_box('Pouch_R',     (0.05, 0.18, 0.50), (0.10, 0.06, 0.08), MAT_LEATHER, body_emp)

# Backpack on the back — visible as a brown lump behind her shoulders.
add_box('Backpack',     (-0.20, 0, 0.78), (0.10, 0.26, 0.36), MAT_LEATHER, body_emp)
# Two straps over the shoulders
add_box('Strap_L', (0, -0.08, 0.92), (0.30, 0.04, 0.04), MAT_LEATHER, body_emp)
add_box('Strap_R', (0,  0.08, 0.92), (0.30, 0.04, 0.04), MAT_LEATHER, body_emp)

# Herb sprig poking out of the backpack — green leaf cluster (the lampwright's foraged herbs).
add_sphere('Backpack_Herb_a', (-0.20, -0.06, 1.04), 0.05, MAT_HERB, body_emp,
           segments=8, rings=6, scale=(1.0, 1.0, 1.4))
add_sphere('Backpack_Herb_b', (-0.20,  0.06, 1.06), 0.05, MAT_HERB, body_emp,
           segments=8, rings=6, scale=(1.0, 1.0, 1.6))
add_sphere('Backpack_Herb_c', (-0.20,  0,    1.10), 0.04, MAT_HERB, body_emp,
           segments=8, rings=6, scale=(1.0, 1.0, 1.8))

# Side gourd — small leather-pouch bulb hanging off the left side of the
# backpack. Concept shows a round dangling thing — small enough to not
# dominate but distinct enough to read as "she carries lots of things."
add_sphere('Gourd_Side', (-0.18, -0.18, 0.78), 0.05, MAT_LEATHER, body_emp,
           segments=10, rings=8, scale=(1.0, 1.0, 1.3))

# Bedroll — horizontal cylinder on top of the backpack (rolled-up cloth /
# scroll). Concept shows a pale cream tube tied across the top of the pack.
add_cylinder('Bedroll', (-0.20, 0, 1.00), 0.045, 0.30, MAT_TUNIC, body_emp,
             vertices=8, rot=(math.radians(90), 0, 0))
# Bedroll end-caps in leather color (suggesting tied ends)
add_cylinder('Bedroll_Cap_L', (-0.20, -0.16, 1.00), 0.046, 0.025, MAT_LEATHER, body_emp,
             vertices=8, rot=(math.radians(90), 0, 0))
add_cylinder('Bedroll_Cap_R', (-0.20,  0.16, 1.00), 0.046, 0.025, MAT_LEATHER, body_emp,
             vertices=8, rot=(math.radians(90), 0, 0))

# ---------------------------------------------------------------------------
# 5. Legs — visible trousers (concept clearly shows them) + bare feet
# ---------------------------------------------------------------------------

# Trousers cylinder — narrower than hip, for each leg.
add_cylinder('Trousers_L', (0, -0.10, 0.30), 0.08, 0.50, MAT_TROUSERS, leg_l_emp, vertices=10)
add_cylinder('Trousers_R', (0,  0.10, 0.30), 0.08, 0.50, MAT_TROUSERS, leg_r_emp, vertices=10)
# Sandal criss-cross straps — concept shows distinctive criss-crossing
# leather straps at the ankle, not a flat band. Build with a thin base
# wrap + 2 diagonal crossing straps over the foot.
def build_sandal(side_y, leg_emp, side_label):
    # Ankle base wrap (thin band at the very bottom of trousers)
    add_box(f'Sandal_AnkleBand_{side_label}', (0, side_y, 0.10),
            (0.10, 0.10, 0.025), MAT_LEATHER, leg_emp, bevel_width=0.005)
    # Two diagonal crossing straps across the top of the foot — each is a
    # thin elongated box rotated to cross the other.
    add_box(f'Sandal_Strap_A_{side_label}', (0.04, side_y, 0.07),
            (0.16, 0.020, 0.020), MAT_LEATHER, leg_emp, bevel_width=0.003,
            rot=(math.radians(20), math.radians(-15), 0))
    add_box(f'Sandal_Strap_B_{side_label}', (0.04, side_y, 0.07),
            (0.16, 0.020, 0.020), MAT_LEATHER, leg_emp, bevel_width=0.003,
            rot=(math.radians(-20), math.radians(-15), 0))

build_sandal(-0.10, leg_l_emp, 'L')
build_sandal( 0.10, leg_r_emp, 'R')
# Bare feet — small skin-colored boxes extending forward from below the wraps
add_box('Foot_L', (0.02, -0.10, 0.04), (0.14, 0.10, 0.06), MAT_SKIN, leg_l_emp)
add_box('Foot_R', (0.02,  0.10, 0.04), (0.14, 0.10, 0.06), MAT_SKIN, leg_r_emp)

# ---------------------------------------------------------------------------
# 6. Head — round, peachy, with peaceful eyes + nose + hair tuft
# ---------------------------------------------------------------------------

# Head: round oval, slightly wider than tall (kindly read).
# Lowered to z=1.12 (was 1.18) so the head bottom (z=0.96) overlaps the neck/scarf.
add_sphere('Head_Mesh', (0, 0, 1.12), 0.16, MAT_SKIN, head_emp,
           segments=14, rings=10, scale=(1.05, 1.0, 0.95))

# Nose — bulbous, on the front face.
add_sphere('Nose', (0.16, 0, 1.10), 0.04, MAT_NOSE, head_emp, segments=8, rings=6)

# Eyes — on the front face, small and warm. Concept's eyes are nearly closed
# (peaceful), so use small flat ovals rather than circles.
EYE_X = 0.155
EYE_Z = 1.14
add_sphere('Eye_L', (EYE_X, -0.06, EYE_Z), 0.018, MAT_EYE, head_emp,
           segments=8, rings=6, scale=(1.0, 1.0, 0.5))
add_sphere('Eye_R', (EYE_X,  0.06, EYE_Z), 0.018, MAT_EYE, head_emp,
           segments=8, rings=6, scale=(1.0, 1.0, 0.5))

# Bushier eyebrows — 3 small angular tufts per side instead of one flat
# box, so the brow reads as actual hair, not a sticker. Concept shows
# prominent fluffy eyebrows.
def bushy_brow(name_prefix, side_y):
    add_box(f'{name_prefix}_a', (0.15, side_y - 0.02, 1.20),
            (0.03, 0.025, 0.025), MAT_HAIR, head_emp,
            bevel_width=0.005, rot=(0, math.radians(15), 0))
    add_box(f'{name_prefix}_b', (0.155, side_y, 1.21),
            (0.035, 0.030, 0.025), MAT_HAIR, head_emp,
            bevel_width=0.005, rot=(0, math.radians(10), 0))
    add_box(f'{name_prefix}_c', (0.15, side_y + 0.02, 1.20),
            (0.03, 0.025, 0.025), MAT_HAIR, head_emp,
            bevel_width=0.005, rot=(0, math.radians(15), 0))

bushy_brow('Brow_L', -0.06)
bushy_brow('Brow_R',  0.06)

# ---- Fluffy grandfather beard — single metaball blob ----
# 7 element spheres at chin / jaw-sides / tip / cheek-tufts merge into one
# organic mass via metaball iso-surface. Reads as a fluffy chunk instead of
# a stack of distinct spheres. Origin at chin front; all element positions
# are relative to that origin.
# ---- Beard built from visible cone strands (low-poly convention) ----
# A chunky old-man beard reads as a SET of distinct hair tufts you can
# count, not a smooth blob. Construction:
#   Chin_Pad        — flat patch where strands attach
#   Beard_Strand_C  — center strand, longest, with a slight forward droop
#   Beard_Strand_L  — left strand, slightly shorter, angled out + down
#   Beard_Strand_R  — right strand, mirror of L
#   Beard_Side_L/R  — short jaw-line tufts (side-burns)
#   Mustache_L/R    — two angled cones flaring out from below the nose
# Each cone is wider at the base, pointy at the tip — gives the
# tapered-strand silhouette that makes low-poly beards readable.

# Chin pad — anchors the strands so they read as attached, not floating.
add_box('Chin_Pad', (0.18, 0, 1.02), (0.05, 0.14, 0.04), MAT_HAIR, head_emp,
        bevel_width=0.008)

# Center strand — pulled forward at the base (x=0.20) and tilted significantly
# forward (Y+28°) so the tip ends up at x≈0.24, clearly in front of the
# vest surface (x_max=0.19). Without this tilt the beard cones clip through
# the chest geometry.
add_cone('Beard_Strand_C', (0.20, 0,    0.94), radius_base=0.045, radius_tip=0.005,
         height=0.14, mat=MAT_HAIR, parent=head_emp,
         vertices=8, rot=(0, math.radians(28), 0))

# Left + right strands — same forward tilt, plus outward splay
add_cone('Beard_Strand_L', (0.18, -0.06, 0.95), radius_base=0.035, radius_tip=0.005,
         height=0.12, mat=MAT_HAIR, parent=head_emp,
         vertices=8, rot=(math.radians(-12), math.radians(28), 0))
add_cone('Beard_Strand_R', (0.18,  0.06, 0.95), radius_base=0.035, radius_tip=0.005,
         height=0.12, mat=MAT_HAIR, parent=head_emp,
         vertices=8, rot=(math.radians(12), math.radians(28), 0))

# Side-burn tufts — small jaw-line cones connecting beard to where hair meets cheek
add_cone('Beard_Side_L', (0.10, -0.13, 1.00), radius_base=0.030, radius_tip=0.008,
         height=0.10, mat=MAT_HAIR, parent=head_emp,
         vertices=6, rot=(math.radians(-20), 0, 0))
add_cone('Beard_Side_R', (0.10,  0.13, 1.00), radius_base=0.030, radius_tip=0.008,
         height=0.10, mat=MAT_HAIR, parent=head_emp,
         vertices=6, rot=(math.radians(20), 0, 0))

# Forked bottom — two small cones at the bottom give the beard a split-tip
# look. Pushed forward (x=0.24) so they sit clearly in front of the chest.
add_cone('Beard_Fork_L', (0.24, -0.025, 0.86), radius_base=0.018, radius_tip=0.003,
         height=0.07, mat=MAT_HAIR, parent=head_emp,
         vertices=6, rot=(math.radians(-15), math.radians(30), 0))
add_cone('Beard_Fork_R', (0.24,  0.025, 0.86), radius_base=0.018, radius_tip=0.003,
         height=0.07, mat=MAT_HAIR, parent=head_emp,
         vertices=6, rot=(math.radians(15), math.radians(30), 0))

# Mustache — two cones flaring out from below the nose. Base near the nose,
# tip flaring laterally and slightly down (handlebar suggestion).
add_cone('Mustache_L', (0.22, -0.05, 1.07), radius_base=0.025, radius_tip=0.004,
         height=0.08, mat=MAT_HAIR, parent=head_emp,
         vertices=6, rot=(math.radians(75), 0, math.radians(-15)))
add_cone('Mustache_R', (0.22,  0.05, 1.07), radius_base=0.025, radius_tip=0.004,
         height=0.08, mat=MAT_HAIR, parent=head_emp,
         vertices=6, rot=(math.radians(-75), 0, math.radians(15)))

# ---- Beard density additions — intermediate strands ----
# Adds 4 shorter strands woven between the existing 5 to make the beard
# read as a denser fluffy mass instead of a sparse cluster. All forward-
# tilted Y+28° so they sit in front of the chest, not inside it.
add_cone('Beard_Inter_a', (0.19, -0.03, 0.94), radius_base=0.022, radius_tip=0.004,
         height=0.09, mat=MAT_HAIR, parent=head_emp, vertices=6,
         rot=(0, math.radians(28), 0))
add_cone('Beard_Inter_b', (0.19,  0.03, 0.94), radius_base=0.022, radius_tip=0.004,
         height=0.09, mat=MAT_HAIR, parent=head_emp, vertices=6,
         rot=(0, math.radians(28), 0))
add_cone('Beard_Inter_c', (0.17, -0.09, 0.96), radius_base=0.020, radius_tip=0.004,
         height=0.08, mat=MAT_HAIR, parent=head_emp, vertices=6,
         rot=(math.radians(-15), math.radians(25), 0))
add_cone('Beard_Inter_d', (0.17,  0.09, 0.96), radius_base=0.020, radius_tip=0.004,
         height=0.08, mat=MAT_HAIR, parent=head_emp, vertices=6,
         rot=(math.radians(15), math.radians(25), 0))

# ---- Voluminous WINDSWEPT hair — 4-vertex pyramidal cones ----
# Per `low-poly-character-modeling.SKILL.md § Hair`: in low-poly stylized
# (Wind Waker / RuneScape / chibi-cozy), hair reads as DISCRETE angular
# tufts, NOT a smooth dome. 4-vertex cones (vertices=4) give pyramidal
# shapes — flat-shaded for the angular cel-shaded look. Each tuft is a
# pointed strand leaning up-and-back from the scalp.

# Back-of-head dome — fills the rear silhouette so we don't see scalp.
# Sphere is intentional here; this is the underlying mass, not a tuft.
add_sphere('Hair_Back_Dome', (-0.10, 0, 1.22), 0.18, MAT_HAIR, head_emp,
           segments=12, rings=10, scale=(1.0, 1.2, 1.0))

# Five pyramidal spike tufts — each is a 4-vert cone with base at the
# scalp, pointy tip leaning up-and-back. Rotation Y bends the cone toward
# -X (the back of the head); rotation X spreads it left/right.
def hair_pyramid(name, world_pos, base_r, height, lean_back_deg, lean_side_deg=0):
    add_cone(name, world_pos,
             radius_base=base_r, radius_tip=0.005, height=height,
             mat=MAT_HAIR, parent=head_emp,
             vertices=4,                                # pyramidal, not round
             rot=(math.radians(lean_side_deg), math.radians(lean_back_deg), 0))

hair_pyramid('Hair_Tuft_top',     (-0.04, 0,    1.42), 0.10, 0.16, 35)
hair_pyramid('Hair_Tuft_top_L',   (-0.06, -0.10, 1.40), 0.08, 0.14, 40, -10)
hair_pyramid('Hair_Tuft_top_R',   (-0.06,  0.10, 1.40), 0.08, 0.14, 40,  10)
hair_pyramid('Hair_Tuft_back_L',  (-0.16, -0.14, 1.32), 0.06, 0.12, 55, -15)
hair_pyramid('Hair_Tuft_back_R',  (-0.16,  0.14, 1.32), 0.06, 0.12, 55,  15)

# Side wisps — small spheres in front of the ears, below the spike tufts.
add_sphere('Hair_Wisp_L', (0.04, -0.18, 1.20), 0.06, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_Wisp_R', (0.04,  0.18, 1.20), 0.06, MAT_HAIR, head_emp, segments=8, rings=6)

# Hair fluff — small intermediate spheres tucked between the angular tufts
# so the silhouette doesn't read as overly geometric. Soft cushion of fluff
# around the angular spikes.
add_sphere('Hair_Fluff_a', (-0.08, 0,    1.36), 0.05, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_Fluff_b', (-0.08, -0.08, 1.34), 0.045, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_Fluff_c', (-0.08,  0.08, 1.34), 0.045, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_Fluff_d', (-0.13, 0,    1.30), 0.06, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_Fluff_e', (0.00, -0.14, 1.36), 0.04, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_Fluff_f', (0.00,  0.14, 1.36), 0.04, MAT_HAIR, head_emp, segments=8, rings=6)

# ---------------------------------------------------------------------------
# 7. Arms — stocky sleeves + small skin hands
# ---------------------------------------------------------------------------
# Vest sleeves are slightly puffy. Sleeves end above wrist; cream tunic peeks below.

# Arms moved in to match the slimmer torso (was y=±0.28).
# Sleeve y=±0.24 sits ~0.06 outside the new vest edge (0.19) — natural hang.
# LEFT ARM — empty hand (resting near belt)
add_box('Sleeve_L',  (0, -0.24, 0.80), (0.12, 0.12, 0.30), MAT_VEST, arm_l_emp)
add_box('Cuff_L',    (0, -0.24, 0.65), (0.10, 0.10, 0.04), MAT_TUNIC, arm_l_emp)
add_sphere('Hand_L', (0, -0.24, 0.60), 0.055, MAT_SKIN, arm_l_emp, segments=10, rings=8)

# RIGHT ARM — gripping the staff. Pose: hand near body, staff just outside.
add_box('Sleeve_R',  (0, 0.24, 0.80), (0.12, 0.12, 0.30), MAT_VEST, arm_r_emp)
add_box('Cuff_R',    (0, 0.24, 0.65), (0.10, 0.10, 0.04), MAT_TUNIC, arm_r_emp)
add_sphere('Hand_R', (0, 0.24, 0.60), 0.055, MAT_SKIN, arm_r_emp, segments=10, rings=8)

# ---- The STAFF — Eldra's silhouette mark ----
# Knobby tree-branch staff held by Arm_R. Three stacked cylinders of
# varying radius give it the gnarled-wood read; a short curved crook at the
# top holds the lanterns. x=0.16 (forward), y=0.30 (right side).

# Knobby pole — three segments stacked vertically, slightly varying radius.
add_cylinder('Staff_Pole_lo',  (0.16, 0.27, 0.32), 0.030, 0.55, MAT_LEATHER, arm_r_emp, vertices=10)
add_cylinder('Staff_Knot_a',   (0.16, 0.27, 0.62), 0.040, 0.06, MAT_LEATHER, arm_r_emp, vertices=10)
add_cylinder('Staff_Pole_mid', (0.16, 0.27, 0.95), 0.028, 0.60, MAT_LEATHER, arm_r_emp, vertices=10)
add_cylinder('Staff_Knot_b',   (0.16, 0.27, 1.27), 0.038, 0.06, MAT_LEATHER, arm_r_emp, vertices=10)
add_cylinder('Staff_Pole_hi',  (0.16, 0.27, 1.45), 0.025, 0.30, MAT_LEATHER, arm_r_emp, vertices=10)
# Additional thin disc rings between segments — suggest carved bands /
# extra knots that catch the eye and break up the smooth cylinders.
add_cylinder('Staff_Ring_a', (0.16, 0.27, 0.45), 0.034, 0.018, MAT_LEATHER, arm_r_emp, vertices=10)
add_cylinder('Staff_Ring_b', (0.16, 0.27, 0.78), 0.032, 0.018, MAT_LEATHER, arm_r_emp, vertices=10)
add_cylinder('Staff_Ring_c', (0.16, 0.27, 1.10), 0.032, 0.018, MAT_LEATHER, arm_r_emp, vertices=10)
add_cylinder('Staff_Ring_d', (0.16, 0.27, 1.40), 0.029, 0.018, MAT_LEATHER, arm_r_emp, vertices=10)
# Two small carved-notch boxes — break the cylinder uniformity
add_box('Staff_Notch_a', (0.18, 0.27, 0.52), (0.012, 0.012, 0.04), MAT_LEATHER, arm_r_emp,
        bevel_width=0.002)
add_box('Staff_Notch_b', (0.18, 0.27, 1.18), (0.012, 0.012, 0.04), MAT_LEATHER, arm_r_emp,
        bevel_width=0.002)

# Cane crook — three short angled cylinders forming a curve at the top.
# Curves OUTWARD/FORWARD from the staff top (increasing x) then down — so
# lanterns dangle beyond the silhouette, away from the body.
# Pole top is at (x=0.16, y=0.30, z=1.60).
add_cylinder('Staff_Crook_a', (0.22, 0.27, 1.62), 0.024, 0.16, MAT_LEATHER, arm_r_emp,
             vertices=8, rot=(0, math.radians(60), 0))
add_cylinder('Staff_Crook_b', (0.32, 0.27, 1.58), 0.024, 0.14, MAT_LEATHER, arm_r_emp,
             vertices=8, rot=(0, math.radians(90), 0))
add_cylinder('Staff_Crook_c', (0.40, 0.27, 1.50), 0.022, 0.14, MAT_LEATHER, arm_r_emp,
             vertices=8, rot=(0, math.radians(120), 0))

# ---- Hexagonal lanterns with visible window-pane bars ----
# Per build plan v1.1: replace round-bellied spheres with HEXAGONAL bodies
# (6-vert cylinders) and add 4 thin vertical "pane bars" around each so the
# lantern reads as a real lit cage, not a solid orb. Concept art shows
# distinct hexagonal/octagonal lantern panes.
LANTERN_Y = 0.27

def build_lantern(prefix, world_x, world_z, body_r=0.060, body_h=0.11,
                   cap_r=0.055, base_r=0.040, hang_h=0.10, flame_r=0.038,
                   pane_count=4):
    # Hang chain (thin cord/rod from crook to lantern cap)
    add_cylinder(f'{prefix}_Hang', (world_x, LANTERN_Y, world_z + body_h/2 + 0.10),
                 0.008, hang_h, MAT_LEATHER, arm_r_emp, vertices=6)
    # Cap — small flat hexagonal disc on top
    add_cylinder(f'{prefix}_Cap',  (world_x, LANTERN_Y, world_z + body_h/2 + 0.025),
                 cap_r, 0.04, MAT_LANTERN, arm_r_emp, vertices=6)
    # Body — HEXAGONAL cage cylinder (6 vertices = clear hexagonal silhouette)
    add_cylinder(f'{prefix}_Body', (world_x, LANTERN_Y, world_z),
                 body_r, body_h, MAT_LANTERN, arm_r_emp, vertices=6)
    # Pane bars — thin vertical posts around the body, slightly outside the
    # cylinder radius so they read as a cage frame separating the panes.
    for i in range(pane_count):
        angle = 2 * math.pi * i / pane_count
        bar_x = world_x + (body_r + 0.005) * math.cos(angle)
        bar_y = LANTERN_Y + (body_r + 0.005) * math.sin(angle)
        add_box(f'{prefix}_Pane_{i}', (bar_x, bar_y, world_z),
                (0.012, 0.012, body_h + 0.005), MAT_LEATHER, arm_r_emp,
                bevel_width=0.002)
    # Flame — emissive sphere inside the cage
    add_sphere(f'{prefix}_Flame', (world_x, LANTERN_Y, world_z + 0.01),
               flame_r, MAT_FLAME, arm_r_emp, segments=10, rings=8)
    # Base — thicker hexagonal disc at the bottom
    add_cylinder(f'{prefix}_Base', (world_x, LANTERN_Y, world_z - body_h/2 - 0.015),
                 base_r, 0.025, MAT_LANTERN, arm_r_emp, vertices=6)

# Lantern 1 — hangs from Crook_b apex
build_lantern('Lantern_1', 0.32, 1.32, body_r=0.060, body_h=0.12,
              cap_r=0.055, base_r=0.045, hang_h=0.10)

# Lantern 2 — hangs lower and further forward, from Crook_c tip; slightly smaller
build_lantern('Lantern_2', 0.40, 1.18, body_r=0.055, body_h=0.11,
              cap_r=0.050, base_r=0.040, hang_h=0.16, flame_r=0.034)

# Grass tuft at the staff base — small green pyramidal cones around the
# staff bottom (concept shows a clump of grass at the foot of the staff).
# Parented to Arm_R so it follows the staff if/when the arm pose changes
# (acceptable since the staff bottom rests near the ground in idle).
def grass_blade(name, x, y, z, h):
    add_cone(name, (x, y, z), radius_base=0.010, radius_tip=0.003,
             height=h, mat=MAT_HERB, parent=arm_r_emp, vertices=4)

grass_blade('Grass_Blade_a', 0.16, 0.27, 0.06, 0.10)
grass_blade('Grass_Blade_b', 0.18, 0.30, 0.05, 0.08)
grass_blade('Grass_Blade_c', 0.14, 0.24, 0.05, 0.09)
grass_blade('Grass_Blade_d', 0.20, 0.27, 0.06, 0.07)
grass_blade('Grass_Blade_e', 0.16, 0.30, 0.04, 0.06)

# Orientation handled at the helper-wrapper layer — no rotations needed here.

# ---------------------------------------------------------------------------
# 9. Export
# ---------------------------------------------------------------------------

bpy.ops.object.select_all(action='DESELECT')
def select_subtree(obj):
    obj.select_set(True)
    for c in obj.children:
        select_subtree(c)
select_subtree(root)
bpy.context.view_layer.objects.active = root

PROJECT_ROOT = os.environ.get('GJ26_PROJECT_ROOT', '/Users/bbroeking/projects/gj26')
out_path = os.path.join(PROJECT_ROOT, 'models', 'npc_eldra_v3.glb')

bpy.ops.export_scene.gltf(
    filepath=out_path,
    export_format='GLB',
    use_selection=True,
    export_yup=True,
    export_apply=True,
    export_normals=True,
    export_materials='EXPORT',
    export_animations=False,
    export_skins=False,
    export_image_format='AUTO',
)

print(f"\n=== Exported {out_path} ===")
for name in ('Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R'):
    o = bpy.data.objects.get(name)
    if o:
        print(f"  {name} — {len(o.children)} direct children")
