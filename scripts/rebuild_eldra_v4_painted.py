"""Rebuild Eldra as `models/npc_eldra_v4.glb` — painted-render-friendly geometry.

Why v4 vs v3:
  v3 was tuned for the old MeshPhong + smooth-normal pipeline, where
  internal detail reads as nuance. Switching to the painted-vertex-color +
  inverted-hull-outline pipeline (Wind Waker) inverts that — every primitive
  boundary becomes an ink line, so DETAIL = NOISE.

  v4 strips away the noise primitives that the concept art doesn't show as
  separate forms anyway:
    - beard: 11 cones → 1 fluffy ellipsoid + chin pad
    - brows: 6 boxes → 1 bushy tuft per side
    - vest: removed Cord, 3 Buttons, ChestPeek, 3 Scarf accents
    - hair: 5 spike cones + 6 fluff spheres → 1 dome + 3 large tufts
    - mustache: 2 cones removed (subtle in concept, noise here)
    - sandals: criss-cross straps → single ankle wrap
    - staff: rings + notches + grass blades removed (kept pole + crook + lanterns)

  Same material names as v3 (Eldra_Skin, _Hair, _Tunic, _Vest, _Scarf,
  _Trousers, _Leather, _Herb, _Lantern, _Flame) so the painted_materials.js
  palette dict applies unchanged. Same 6-empty rig (Body/Head/Arm_L/Arm_R/
  Leg_L/Leg_R) so animation transfers.

Run:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
      --python scripts/rebuild_eldra_v4_painted.py
"""

import bpy
import math
import os

# ---------------------------------------------------------------------------
# Helpers — copied from rebuild_eldra.py (same recipe).
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

def _add_primitive_finish(o, mat, parent):
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)

def add_soft_box(name, world_center, dims, mat, parent, rot=(0, 0, 0)):
    """Heavily-rounded box for clothing / body parts. Aggressive bevel (8%
    of the smallest dimension, 4 segments) + 1 level of subdivision-surface
    crease=0 so the corners round into a clay-figurine pillow shape rather
    than reading as a stiff cuboid. Result lands somewhere between a box
    and a scaled sphere — keeps the rectangular silhouette but loses every
    hard 90° edge. Used for Vest_Body, Vest_Skirt, Backpack: pieces that
    are large and dominate the body silhouette."""
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
    # Heavy bevel — 8% of smallest dim, 4 segments, all-edge limit (not
    # angle-limited) so every corner softens.
    bev = o.modifiers.new('Bevel', 'BEVEL')
    bev.width = min(sx, sy, sz) * 0.18
    bev.segments = 3
    bev.limit_method = 'NONE'
    # Subdivision surface — pushes flat faces toward sphere-likeness. 1
    # level keeps tri count manageable (multiplies by ~4×) while rounding
    # the silhouette substantially.
    sub = o.modifiers.new('Subsurf', 'SUBSURF')
    sub.levels = 1
    sub.render_levels = 1
    bpy.ops.object.shade_smooth()
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    parent.select_set(True)
    bpy.context.view_layer.objects.active = parent
    bpy.ops.object.parent_set(type='OBJECT', keep_transform=True)
    return o

def add_box(name, world_center, dims, mat, parent, bevel_width=0.020, rot=(0, 0, 0)):
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

def add_sphere(name, world_center, radius, mat, parent, segments=12, rings=8, scale=(1, 1, 1)):
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

def add_cylinder(name, world_center, radius, height, mat, parent, vertices=12, rot=(0, 0, 0)):
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
    cx, cy, cz = world_center
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
# Coordinate transform — same as rebuild_eldra.py: author face on +X, helpers
# remap to -Y at Blender world so engine walk anim works.
# ---------------------------------------------------------------------------

_orig_add_box      = add_box
_orig_add_sphere   = add_sphere
_orig_add_cylinder = add_cylinder
_orig_add_cone     = add_cone
_orig_add_empty    = add_empty

def _xform_pos(p):    return (p[1], -p[0], p[2])
def _xform_dims(d):   return (d[1], d[0], d[2])
def _xform_rot(r):    return (r[1], -r[0], r[2])
def _xform_scale(s):  return (s[1], s[0], s[2])

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
# 1. Wipe — idempotent rebuild (same prefixes as v3)
# ---------------------------------------------------------------------------

PREFIXES = (
    'Eldra', 'Body', 'Head', 'Arm_', 'Leg_',
    'Hair', 'Eye_', 'Mouth', 'Nose', 'Brow', 'Cheek',
    'Tunic', 'Vest', 'Scarf', 'Belt', 'Pouch', 'Trousers', 'Foot',
    'Hand_', 'Sleeve_', 'Staff', 'Lantern', 'Backpack', 'Strap',
    'Beard', 'Mustache', 'Chin_', 'Sandal', 'Cuff', 'Neck',
    'Bedroll', 'Gourd', 'Robe',
)
for o in list(bpy.data.objects):
    if o.name.startswith(PREFIXES):
        bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes):
    if m.users == 0: bpy.data.meshes.remove(m)
for m in list(bpy.data.materials):
    if m.users == 0: bpy.data.materials.remove(m)

# ---------------------------------------------------------------------------
# 2. Materials — same names as v3 so the JS palette dict still works
# ---------------------------------------------------------------------------

MAT_SKIN     = make_material('Eldra_Skin',     '#f0c8a8', roughness=0.78)
MAT_HAIR     = make_material('Eldra_Hair',     '#f4f0e8', roughness=0.92)
MAT_TUNIC    = make_material('Eldra_Tunic',    '#e8d8b8', roughness=0.88)
MAT_VEST     = make_material('Eldra_Vest',     '#a87a48', roughness=0.85)
MAT_SCARF    = make_material('Eldra_Scarf',    '#4a6878', roughness=0.85)
MAT_TROUSERS = make_material('Eldra_Trousers', '#7a8a78', roughness=0.88)
MAT_LEATHER  = make_material('Eldra_Leather',  '#6a4a2a', roughness=0.85)
MAT_HERB     = make_material('Eldra_Herb',     '#5a7848', roughness=0.85)
MAT_LANTERN  = make_material('Eldra_Lantern',  '#b88440', roughness=0.40)
MAT_FLAME    = make_material('Eldra_Flame',    '#ffd060', roughness=0.30,
                              emissive_hex='#ffe09a', emission_strength=2.5)
MAT_EYE   = MAT_LEATHER
MAT_NOSE  = MAT_SKIN

# ---------------------------------------------------------------------------
# 3. Empties — same rig as v3
# ---------------------------------------------------------------------------

Z_HIP, Z_SHOULDER, Z_NECK, Z_HEAD_TOP = 0.55, 0.95, 1.00, 1.55

root      = add_empty('EldraRoot', (0, 0, 0))
body_emp  = add_empty('Body',  (0,     0,    Z_HIP),     parent=root)
head_emp  = add_empty('Head',  (0,     0,    Z_NECK),    parent=root)
arm_l_emp = add_empty('Arm_L', (0,    -0.18, Z_SHOULDER), parent=root)
arm_r_emp = add_empty('Arm_R', (0,     0.18, Z_SHOULDER), parent=root)
leg_l_emp = add_empty('Leg_L', (0,    -0.10, Z_HIP),      parent=root)
leg_r_emp = add_empty('Leg_R', (0,     0.10, Z_HIP),      parent=root)

# ---------------------------------------------------------------------------
# 4. Body — 1 tunic + 1 vest + 1 hem stripe + 1 belt + 1 scarf + 1 backpack
# ---------------------------------------------------------------------------

# Tunic_Body removed — was always invisible behind the wider vest, just
# adding a hidden mesh + an inverted-hull outline to render. The collar
# below is the only cream piece that needs to exist.
# Tiny tunic collar — small V-hint at the chest top. Narrower + lower than
# the first pass so it doesn't compete with the beard at the chin.
add_box('Tunic_Collar', (0.04, 0, 0.92), (0.10, 0.08, 0.04), MAT_TUNIC, body_emp,
        bevel_width=0.004)
# Neck cylinder bridges torso to head.
add_cylinder('Neck',   (0, 0, 1.02), 0.09, 0.14, MAT_SKIN, body_emp, vertices=10)
# Vest — soft-box (heavy bevel + subsurf) so it reads as soft cushion-like
# clothing instead of a stiff cuboid. Same dims as before.
add_soft_box('Vest_Body',   (0, 0, 0.72), (0.38, 0.32, 0.36), MAT_VEST,  body_emp)
# Hem stripe — only vest decoration we keep (matches concept).
add_box('Vest_Stripe', (0.18, 0, 0.58), (0.02, 0.30, 0.04), MAT_HERB, body_emp,
        bevel_width=0.005)
# Vest skirt — soft-box so the hip flare reads organically.
add_soft_box('Vest_Skirt',  (0, 0, 0.50), (0.36, 0.30, 0.10), MAT_VEST, body_emp)
# Scarf — single front block + one tail.
add_box('Scarf_Front', (0.04, 0,    1.00), (0.26, 0.26, 0.12), MAT_SCARF, body_emp)
add_box('Scarf_Tail',  (-0.04, 0.08, 0.92), (0.04, 0.08, 0.18), MAT_SCARF, body_emp)
# Belt.
add_box('Belt',        (0, 0, 0.55), (0.36, 0.30, 0.04), MAT_LEATHER, body_emp)
# Pouch — single side pouch (silhouette feature in concept).
add_box('Pouch_R',     (0.05, 0.18, 0.50), (0.10, 0.06, 0.08), MAT_LEATHER, body_emp)

# Backpack — soft-box (rounded leather pouch shape, not a cuboid).
add_soft_box('Backpack', (-0.20, 0, 0.78), (0.10, 0.26, 0.36), MAT_LEATHER, body_emp)
add_box('Strap_L', (0, -0.08, 0.92), (0.30, 0.04, 0.04), MAT_LEATHER, body_emp)
add_box('Strap_R', (0,  0.08, 0.92), (0.30, 0.04, 0.04), MAT_LEATHER, body_emp)
# Herb sprigs poking out of backpack — keep as silhouette feature.
add_sphere('Backpack_Herb', (-0.20, 0, 1.06), 0.08, MAT_HERB, body_emp,
           segments=8, rings=6, scale=(0.8, 1.4, 1.5))
# Side gourd — small leather sphere.
add_sphere('Gourd_Side', (-0.18, -0.18, 0.78), 0.05, MAT_LEATHER, body_emp,
           segments=10, rings=8, scale=(1.0, 1.0, 1.3))
# Bedroll — silhouette feature on top of backpack.
add_cylinder('Bedroll', (-0.20, 0, 1.00), 0.045, 0.30, MAT_TUNIC, body_emp,
             vertices=8, rot=(math.radians(90), 0, 0))

# ---------------------------------------------------------------------------
# 5. Legs — single trouser cylinder + simple foot per side
# ---------------------------------------------------------------------------

add_cylinder('Trousers_L', (0, -0.10, 0.30), 0.08, 0.50, MAT_TROUSERS, leg_l_emp, vertices=10)
add_cylinder('Trousers_R', (0,  0.10, 0.30), 0.08, 0.50, MAT_TROUSERS, leg_r_emp, vertices=10)
# Single ankle wrap (no criss-cross detail).
add_box('Sandal_L', (0, -0.10, 0.07), (0.12, 0.10, 0.03), MAT_LEATHER, leg_l_emp,
        bevel_width=0.005)
add_box('Sandal_R', (0,  0.10, 0.07), (0.12, 0.10, 0.03), MAT_LEATHER, leg_r_emp,
        bevel_width=0.005)
# Bare feet.
add_box('Foot_L', (0.02, -0.10, 0.04), (0.14, 0.10, 0.06), MAT_SKIN, leg_l_emp)
add_box('Foot_R', (0.02,  0.10, 0.04), (0.14, 0.10, 0.06), MAT_SKIN, leg_r_emp)

# ---------------------------------------------------------------------------
# 6. Head — single hair mass + single beard + single brow per side
# ---------------------------------------------------------------------------

# Head sphere — round, kindly. Bigger than v3 (radius 0.18 vs 0.16) so the
# head:body ratio reads more chibi, matching the concept proportions.
add_sphere('Head_Mesh', (0, 0, 1.14), 0.18, MAT_SKIN, head_emp,
           segments=14, rings=10, scale=(1.05, 1.0, 0.95))

# Nose — bulbous.
add_sphere('Nose', (0.16, 0, 1.10), 0.04, MAT_NOSE, head_emp, segments=8, rings=6)

# Eyes — small dark slashes (boxes, not spheres — flatter, more cel-art).
# Pushed forward (x 0.156 → 0.201) so they protrude past the head surface
# instead of being buried 0.024m inside it.
add_box('Eye_L', (0.201, -0.06, 1.14), (0.020, 0.030, 0.012), MAT_EYE, head_emp,
        bevel_width=0.003)
add_box('Eye_R', (0.201,  0.06, 1.14), (0.020, 0.030, 0.012), MAT_EYE, head_emp,
        bevel_width=0.003)

# Brows — ONE bushy tuft per side (single small box per side, not 3).
# Material: MAT_LEATHER (dark brown, same as eyes) — was MAT_HAIR (white)
# which was invisible on the white face. Position pushed forward (x 0.155
# → 0.175) so they sit on/just in front of the face surface.
add_box('Brow_L', (0.175, -0.06, 1.20), (0.030, 0.060, 0.030), MAT_LEATHER, head_emp,
        bevel_width=0.008, rot=(0, math.radians(10), 0))
add_box('Brow_R', (0.175,  0.06, 1.20), (0.030, 0.060, 0.030), MAT_LEATHER, head_emp,
        bevel_width=0.008, rot=(0, math.radians(10), 0))

# ---- BEARD — main mass + ruffle bumps for fluff texture ----
# Main ellipsoid carries the silhouette outline. Ruffle spheres (suffix
# `_ruffle_*`) skip the outline pass via the convention in
# src/scene/painted_materials.js + codex.js, so they add visible cel-banded
# fluff on the surface without fragmenting the silhouette into separate
# strands.
add_sphere('Beard_Mass', (0.26, 0, 0.85), 0.11, MAT_HAIR, head_emp,
           segments=14, rings=10, scale=(0.7, 1.2, 1.7))
# Chin pad — small anchor bridging chin to beard mass.
add_box('Chin_Pad', (0.20, 0, 1.04), (0.05, 0.13, 0.04), MAT_HAIR, head_emp,
        bevel_width=0.008)

# Beard strands — 8 tapered cones flowing down from the chin instead of
# polka-dot sphere ruffles (variant C from the A/B/C/D exploration). Each
# cone is a single hair strand: thicker base near the chin, tip near the
# bottom. `_ruffle_strand_` in the name keeps the outline pass skipping
# them so they don't fragment the silhouette.
#
# rot=(180°, 0, 0) flips the cone so its tip points down (-Z) instead of
# the default +Z; the helper's _xform_rot remaps to Blender Y-axis.
_BEARD_STRAND_DOWN = (math.radians(180), 0, 0)
_beard_strands = [
    # (name, auth_x, auth_y, center_z, height, base_r, tip_r)
    ('Beard_ruffle_strand_a', 0.31, -0.06, 0.815, 0.30, 0.030, 0.008),
    ('Beard_ruffle_strand_b', 0.33, -0.04, 0.795, 0.32, 0.025, 0.006),
    ('Beard_ruffle_strand_c', 0.33,  0.04, 0.795, 0.32, 0.025, 0.006),
    ('Beard_ruffle_strand_d', 0.31,  0.06, 0.815, 0.30, 0.030, 0.008),
    ('Beard_ruffle_strand_e', 0.35,  0.00, 0.760, 0.34, 0.024, 0.006),
    ('Beard_ruffle_strand_f', 0.33, -0.04, 0.710, 0.30, 0.020, 0.006),
    ('Beard_ruffle_strand_g', 0.33,  0.04, 0.710, 0.30, 0.020, 0.006),
    ('Beard_ruffle_strand_h', 0.37,  0.00, 0.650, 0.28, 0.020, 0.005),
]
for _nm, _x, _y, _cz, _h, _br, _tr in _beard_strands:
    add_cone(_nm, (_x, _y, _cz), _br, _tr, _h, MAT_HAIR, head_emp,
             vertices=6, rot=_BEARD_STRAND_DOWN)

# ---- HAIR — main dome + ruffle bumps for windswept volume + side wisps ----
# Drop the previous accent-cone-on-dome combo — the cone still read as a
# discrete spike from oblique angles. Now: dome carries silhouette, 5
# ruffle bumps add windswept volumetric variation without ink lines.

# Main hair dome — wraps the whole top of the head.
add_sphere('Hair_Dome', (-0.04, 0, 1.30), 0.20, MAT_HAIR, head_emp,
           segments=14, rings=10, scale=(1.1, 1.1, 1.0))

# Hair ruffles — distributed across the dome top + front + back to convey
# the concept's windswept volumetric mass. Top-front cluster pushes the
# silhouette up like a pompadour; back-top adds height; side bumps fill
# the lateral profile.
add_sphere('Hair_ruffle_top',     (0.00, 0,    1.46), 0.060, MAT_HAIR, head_emp, segments=8, rings=6)
# Front-side ruffles pushed forward (x 0.04 → 0.14) so they protrude past
# the dome's front instead of being buried inside it.
add_sphere('Hair_ruffle_front_L', (0.14, -0.08, 1.42), 0.050, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_ruffle_front_R', (0.14,  0.08, 1.42), 0.050, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_ruffle_back',    (-0.16, 0,   1.40), 0.055, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_ruffle_side_L',  (-0.06, -0.18, 1.30), 0.045, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_ruffle_side_R',  (-0.06,  0.18, 1.30), 0.045, MAT_HAIR, head_emp, segments=8, rings=6)

# Side wisps — small spheres in front of the ears (frames the face).
add_sphere('Hair_Wisp_L', (0.04, -0.18, 1.18), 0.07, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_Wisp_R', (0.04,  0.18, 1.18), 0.07, MAT_HAIR, head_emp, segments=8, rings=6)

# ---------------------------------------------------------------------------
# 7. Arms — sleeve + cuff + hand per side (no extra detail)
# ---------------------------------------------------------------------------

add_soft_box('Sleeve_L', (0, -0.24, 0.80), (0.12, 0.12, 0.30), MAT_VEST, arm_l_emp)
add_box('Cuff_L',    (0, -0.24, 0.65), (0.10, 0.10, 0.04), MAT_TUNIC, arm_l_emp)
add_sphere('Hand_L', (0, -0.24, 0.60), 0.055, MAT_SKIN, arm_l_emp, segments=10, rings=8)

add_soft_box('Sleeve_R', (0,  0.24, 0.80), (0.12, 0.12, 0.30), MAT_VEST, arm_r_emp)
add_box('Cuff_R',    (0,  0.24, 0.65), (0.10, 0.10, 0.04), MAT_TUNIC, arm_r_emp)
add_sphere('Hand_R', (0,  0.24, 0.60), 0.055, MAT_SKIN, arm_r_emp, segments=10, rings=8)

# ---------------------------------------------------------------------------
# 8. Staff — simple pole (no rings/notches/grass) + crook + 2 lanterns
# ---------------------------------------------------------------------------

# Single pole cylinder for the whole shaft (vs v3's 5 segments + 4 rings + 2 notches).
add_cylinder('Staff_Pole', (0.16, 0.27, 0.85), 0.030, 1.50, MAT_LEATHER, arm_r_emp, vertices=10)

# Crook — 3 short angled cylinders that curve outward at the top.
add_cylinder('Staff_Crook_a', (0.22, 0.27, 1.62), 0.024, 0.16, MAT_LEATHER, arm_r_emp,
             vertices=8, rot=(0, math.radians(60), 0))
add_cylinder('Staff_Crook_b', (0.32, 0.27, 1.58), 0.024, 0.14, MAT_LEATHER, arm_r_emp,
             vertices=8, rot=(0, math.radians(90), 0))
add_cylinder('Staff_Crook_c', (0.40, 0.27, 1.50), 0.022, 0.14, MAT_LEATHER, arm_r_emp,
             vertices=8, rot=(0, math.radians(120), 0))

# Lanterns — hexagonal cylinders + flames. Drop the pane bars (visual noise).
LANTERN_Y = 0.27

def build_lantern(prefix, world_x, world_z, body_r=0.060, body_h=0.11,
                   cap_r=0.055, base_r=0.040, hang_h=0.10, flame_r=0.038):
    add_cylinder(f'{prefix}_Hang', (world_x, LANTERN_Y, world_z + body_h/2 + 0.10),
                 0.008, hang_h, MAT_LEATHER, arm_r_emp, vertices=6)
    add_cylinder(f'{prefix}_Cap',  (world_x, LANTERN_Y, world_z + body_h/2 + 0.025),
                 cap_r, 0.04, MAT_LANTERN, arm_r_emp, vertices=6)
    add_cylinder(f'{prefix}_Body', (world_x, LANTERN_Y, world_z),
                 body_r, body_h, MAT_LANTERN, arm_r_emp, vertices=6)
    add_sphere(f'{prefix}_Flame', (world_x, LANTERN_Y, world_z + 0.01),
               flame_r, MAT_FLAME, arm_r_emp, segments=10, rings=8)
    add_cylinder(f'{prefix}_Base', (world_x, LANTERN_Y, world_z - body_h/2 - 0.015),
                 base_r, 0.025, MAT_LANTERN, arm_r_emp, vertices=6)

build_lantern('Lantern_1', 0.32, 1.32)
build_lantern('Lantern_2', 0.40, 1.18, body_r=0.055, body_h=0.11,
              cap_r=0.050, base_r=0.040, hang_h=0.16, flame_r=0.034)

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
out_path = os.path.join(PROJECT_ROOT, 'models', 'npc_eldra_v4.glb')

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

# Mesh count summary — confirm we hit our simplification target.
mesh_count = sum(1 for o in bpy.data.objects if o.type == 'MESH'
                 and o.name.startswith(PREFIXES))
print(f"\n=== Exported {out_path} ({mesh_count} meshes) ===")
for name in ('Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R'):
    o = bpy.data.objects.get(name)
    if o:
        print(f"  {name} — {len(o.children)} direct children")
