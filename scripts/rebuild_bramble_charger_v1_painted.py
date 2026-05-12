"""Rebuild Bramble Charger as `models/bramble_charger_v1.glb` — painted.

Filed against `docs/character-pipeline/bramble_charger.md`.

From `docs/concept-art/enemy-bramble-charger.png`:
  - Compact quadruped boar buried under DENSE green leaves
  - Pale cream snout pushing forward (silhouette anchor)
  - Two upturned cream tusks
  - Glowing amber/orange eyes
  - Wood plank armor strapped to flanks
  - Stubby split-hoof legs visible below the leaf skirt
  - Tail with leaf cluster at the tip

Quadruped rig identical to Burrow Boar (Body/Head/Tail/Leg_FL/FR/BL/BR).
~28 leaf cones cover the body surface with a `_ruffle_leaf_` name suffix
so the outline pass skips them — single unified silhouette traces the
leaf-mound + body + head + tusks + legs.

Run:
  /Applications/Blender.app/Contents/MacOS/Blender --background \\
      --python scripts/rebuild_bramble_charger_v1_painted.py
"""

import sys, os, math
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

import bpy
from _painted_build_lib import (
    make_material, add_box, add_soft_box, add_sphere, add_cylinder,
    add_cone, add_empty, wipe_by_prefix, export_glb,
)

PREFIXES = (
    'BrambleCharger', 'ChargerRoot', 'Charger',
    'Body', 'Head', 'Tail', 'Leg_',
    'Snout', 'Tusk_', 'Eye_', 'Ear_', 'Hoof_',
    'Leaf', 'Plank',
)
wipe_by_prefix(PREFIXES)

# ---------------------------------------------------------------------------
# Materials — colors from the description doc
# ---------------------------------------------------------------------------

MAT_HIDE       = make_material('Charger_Hide',      '#2a1f18', roughness=0.85)
MAT_LEAF_DARK  = make_material('Charger_LeafDark',  '#46582e', roughness=0.92)
MAT_LEAF_LIGHT = make_material('Charger_LeafLight', '#7e933e', roughness=0.92)
MAT_SNOUT      = make_material('Charger_Snout',     '#d8c49a', roughness=0.85)
MAT_TUSK       = make_material('Charger_Tusk',      '#efe0b6', roughness=0.55)
MAT_EYE        = make_material('Charger_Eye',       '#f0962a', roughness=0.30,
                                emissive_hex='#ffb54a', emission_strength=1.8)
MAT_PLANK      = make_material('Charger_Plank',     '#6e4d2e', roughness=0.85)
MAT_STRAP      = make_material('Charger_Strap',     '#3a2516', roughness=0.85)
MAT_HOOF       = make_material('Charger_Hoof',      '#2e2218', roughness=0.85)
MAT_LINE       = make_material('Charger_Line',      '#1a0e08', roughness=0.85)

# ---------------------------------------------------------------------------
# Quadruped rig — same layout as Burrow Boar.
# Charger is slightly more compact: ~1.10m long, ~0.50m wide, body z=0.40.
# ---------------------------------------------------------------------------

Z_BODY = 0.40
Z_LEG  = 0.36
Z_HEAD = 0.50

root      = add_empty('ChargerRoot', (0, 0, 0))
body_emp  = add_empty('Body',   (0,    0,    Z_BODY),  parent=root)
head_emp  = add_empty('Head',   (0.45, 0,    Z_HEAD),  parent=root)
tail_emp  = add_empty('Tail',   (-0.50, 0,   Z_BODY),  parent=root)
leg_fl    = add_empty('Leg_FL', (0.28, -0.18, Z_LEG),  parent=root)
leg_fr    = add_empty('Leg_FR', (0.28,  0.18, Z_LEG),  parent=root)
leg_bl    = add_empty('Leg_BL', (-0.28,-0.18, Z_LEG),  parent=root)
leg_br    = add_empty('Leg_BR', (-0.28, 0.18, Z_LEG),  parent=root)

# ---------------------------------------------------------------------------
# Body — dark hide barrel (mostly hidden under leaves, but provides the
# silhouette anchor that the unified outline traces).
# ---------------------------------------------------------------------------

add_soft_box('Body_Barrel', (0, 0, 0),     (0.95, 0.50, 0.36), MAT_HIDE, body_emp)
add_soft_box('Body_Belly',  (0, 0, -0.16), (0.85, 0.46, 0.10), MAT_HIDE, body_emp)

# ---- LEAVES — dense full-body coverage ----
# 28 leaf cones distributed across top/sides/shoulders/hips. Names use
# `_ruffle_leaf_` so the OUTLINE_SKIP_PATTERN excludes them from the
# silhouette merge (one outline traces the leaf-mound shape, not each
# individual leaf). Coverage rule per the description doc: NO leaves past
# the snout (+X) and NONE below z=-0.10. Alternating dark/light material
# every 3rd leaf for color break-up.

# (auth_x, auth_y, auth_z, base_r, height, tilt_x_deg, tilt_y_deg, dark)
_leaves = [
    # Top spine ridge — 8 leaves running nose-to-tail
    ( 0.30,  0.00, 0.30, 0.060, 0.18,  -8,   5, True),
    ( 0.18, -0.04, 0.32, 0.055, 0.18,  -4, -10, True),
    ( 0.18,  0.04, 0.32, 0.050, 0.16,  -4,  10, False),
    ( 0.04, -0.06, 0.34, 0.060, 0.18,   0,  -8, True),
    ( 0.04,  0.06, 0.34, 0.060, 0.18,   0,   8, False),
    (-0.10,  0.00, 0.34, 0.055, 0.16,   2,   0, True),
    (-0.24, -0.04, 0.32, 0.050, 0.16,   8,  -8, False),
    (-0.24,  0.04, 0.32, 0.050, 0.16,   8,   8, True),
    # Shoulders — 4 leaves over each shoulder cluster
    ( 0.30, -0.18, 0.24, 0.060, 0.16, -10, -28, True),
    ( 0.30,  0.18, 0.24, 0.060, 0.16, -10,  28, False),
    ( 0.20, -0.22, 0.20, 0.045, 0.14,  -4, -38, False),
    ( 0.20,  0.22, 0.20, 0.045, 0.14,  -4,  38, True),
    # Mid-side flanks — leaves cascading down the sides between top and planks
    ( 0.06, -0.24, 0.16, 0.045, 0.14,   0, -45, True),
    ( 0.06,  0.24, 0.16, 0.045, 0.14,   0,  45, False),
    (-0.10, -0.24, 0.16, 0.040, 0.12,   4, -45, False),
    (-0.10,  0.24, 0.16, 0.040, 0.12,   4,  45, True),
    # Hips — 4 leaves over the hindquarters
    (-0.30, -0.16, 0.22, 0.050, 0.16,  10, -25, True),
    (-0.30,  0.16, 0.22, 0.050, 0.16,  10,  25, False),
    (-0.40, -0.04, 0.20, 0.045, 0.14,  16, -10, False),
    (-0.40,  0.04, 0.20, 0.045, 0.14,  16,  10, True),
    # Forehead/face — 4 small leaves crowning the head
    ( 0.42, -0.06, 0.36, 0.040, 0.10, -16, -12, True),
    ( 0.42,  0.06, 0.36, 0.040, 0.10, -16,  12, False),
    ( 0.48, -0.10, 0.32, 0.035, 0.10, -10, -22, False),
    ( 0.48,  0.10, 0.32, 0.035, 0.10, -10,  22, True),
    # Cheek leaves — small pair behind the snout, frames the face
    ( 0.50, -0.18, 0.18, 0.036, 0.10,   0, -36, True),
    ( 0.50,  0.18, 0.18, 0.036, 0.10,   0,  36, False),
    # Belly/chest — 2 leaves on the front-bottom (visible from front)
    ( 0.36, -0.10, 0.04, 0.034, 0.10,   8, -16, False),
    ( 0.36,  0.10, 0.04, 0.034, 0.10,   8,  16, True),
]

for idx, (lx, ly, lz, br, h, tilt_x, tilt_y, dark) in enumerate(_leaves):
    mat = MAT_LEAF_DARK if dark else MAT_LEAF_LIGHT
    name = f'Body_ruffle_leaf_{idx:02d}'
    # Forehead/face leaves parent to head_emp so they ride with head
    # animation. The helper places by world coords either way; parent is
    # only the rig anchor.
    parent = head_emp if lx > 0.40 else body_emp
    add_cone(name, (lx, ly, lz), br, 0.005, h, mat, parent,
             vertices=6, rot=(math.radians(tilt_x), math.radians(tilt_y), 0))

# ---- PLANK ARMOR — wood planks strapped to flanks (silhouette piece) ----
add_box('Plank_Armor_L', (0.05, -0.27, 0.05), (0.30, 0.04, 0.20), MAT_PLANK, body_emp)
add_box('Plank_Armor_R', (0.05,  0.27, 0.05), (0.30, 0.04, 0.20), MAT_PLANK, body_emp)
# Leather straps — `_detail_strap_` skips outline (surface decoration on the plank)
add_box('Plank_detail_strap_L', (0.05, -0.30, 0.10), (0.04, 0.06, 0.22), MAT_STRAP, body_emp,
        bevel_width=0.003)
add_box('Plank_detail_strap_R', (0.05,  0.30, 0.10), (0.04, 0.06, 0.22), MAT_STRAP, body_emp,
        bevel_width=0.003)

# ---------------------------------------------------------------------------
# Head — dark hide skull + cream snout + tusks + amber glowing eyes + ears
#
# IMPORTANT: helper positions are world coords (after _xform_pos), NOT
# relative to head_emp. Body extends in authoring x to ±0.475 (front edge
# at +0.475). Snout MUST protrude past x=0.475 to be visible.
# ---------------------------------------------------------------------------

# Head sphere — sits at the front-top of the body, partially overlapping
# so the head reads as fused with the leaf-mounded body.
add_sphere('Head_Mesh', (0.50, 0, 0.20), 0.16, MAT_HIDE, head_emp,
           segments=12, rings=10, scale=(1.0, 1.0, 0.9))

# Snout — cream forward push, protrudes well past the body's front edge.
# Lowered slightly so the snout sits below the head's center (concept
# shows the snout drooping forward + down from the leaf-shrouded skull).
add_soft_box('Snout', (0.65, 0, 0.10), (0.18, 0.20, 0.14), MAT_SNOUT, head_emp)

# Nostrils — small dark dots on the snout front
add_sphere('Snout_detail_nostril_L', (0.74, -0.05, 0.12), 0.014, MAT_LINE, head_emp,
           segments=6, rings=4)
add_sphere('Snout_detail_nostril_R', (0.74,  0.05, 0.12), 0.014, MAT_LINE, head_emp,
           segments=6, rings=4)

# Tusks — upturned cream cones at the corners of the snout
add_cone('Tusk_L', (0.69, -0.10, 0.10), radius_base=0.022, radius_tip=0.005,
         height=0.14, mat=MAT_TUSK, parent=head_emp, vertices=6,
         rot=(math.radians(-30), math.radians(20), 0))
add_cone('Tusk_R', (0.69,  0.10, 0.10), radius_base=0.022, radius_tip=0.005,
         height=0.14, mat=MAT_TUSK, parent=head_emp, vertices=6,
         rot=(math.radians(30), math.radians(20), 0))

# Glowing amber eyes — set high on the head, slightly back of the snout
add_sphere('Eye_L', (0.55, -0.12, 0.26), 0.025, MAT_EYE, head_emp,
           segments=8, rings=6)
add_sphere('Eye_R', (0.55,  0.12, 0.26), 0.025, MAT_EYE, head_emp,
           segments=8, rings=6)

# Ears — small cones (skip outline via `_detail`) on top of the head
add_cone('Ear_L_detail', (0.40, -0.16, 0.34), radius_base=0.05, radius_tip=0.005,
         height=0.08, mat=MAT_HIDE, parent=head_emp, vertices=6,
         rot=(math.radians(-30), 0, 0))
add_cone('Ear_R_detail', (0.40,  0.16, 0.34), radius_base=0.05, radius_tip=0.005,
         height=0.08, mat=MAT_HIDE, parent=head_emp, vertices=6,
         rot=(math.radians(30), 0, 0))

# ---------------------------------------------------------------------------
# Legs — short stubby cylinders + dark hooves
# ---------------------------------------------------------------------------

def build_leg(prefix, leg_emp):
    add_cylinder(f'{prefix}_Leg', (0, 0, -0.18), 0.06, 0.36, MAT_HIDE, leg_emp,
                 vertices=10)
    add_soft_box(f'{prefix}_Hoof', (0, 0, -0.40), (0.10, 0.10, 0.06), MAT_HOOF, leg_emp)

build_leg('FL', leg_fl)
build_leg('FR', leg_fr)
build_leg('BL', leg_bl)
build_leg('BR', leg_br)

# ---------------------------------------------------------------------------
# Tail — small base cone + 2 tip leaves
# ---------------------------------------------------------------------------

add_cone('Tail_Mesh', (0, 0, 0.04), radius_base=0.04, radius_tip=0.012,
         height=0.18, mat=MAT_HIDE, parent=tail_emp, vertices=8,
         rot=(0, math.radians(60), 0))
# Tail-tip leaves (skip outline)
add_cone('Tail_ruffle_leaf_a', (0, 0, 0.16), radius_base=0.05, radius_tip=0.005,
         height=0.10, mat=MAT_LEAF_DARK, parent=tail_emp, vertices=6,
         rot=(math.radians(20), math.radians(-10), 0))
add_cone('Tail_ruffle_leaf_b', (0, -0.04, 0.18), radius_base=0.04, radius_tip=0.005,
         height=0.10, mat=MAT_LEAF_LIGHT, parent=tail_emp, vertices=6,
         rot=(math.radians(15), math.radians(20), 0))

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

PROJECT_ROOT = os.environ.get('GJ26_PROJECT_ROOT',
                              os.path.abspath(os.path.dirname(__file__) + '/..'))
out_path = os.path.join(PROJECT_ROOT, 'models', 'bramble_charger_v1.glb')
export_glb(root, out_path)

mesh_count = sum(1 for o in bpy.data.objects if o.type == 'MESH'
                 and o.name.startswith(PREFIXES))
print(f"\n=== Exported {out_path} ({mesh_count} meshes) ===")
for name in ('Body', 'Head', 'Tail', 'Leg_FL', 'Leg_FR', 'Leg_BL', 'Leg_BR'):
    o = bpy.data.objects.get(name)
    if o:
        print(f"  {name} — {len(o.children)} direct children")
