"""Rebuild Cricket the Letter-Carrier as `models/npc_cricket_v3.glb`.

From `docs/concept-art/npc-cricket-letter-carrier.png`:
  - Young chibi adventurer, ~1.0m tall (smaller than Eldra)
  - Big curly red-orange hair (silhouette feature)
  - Pale freckled face
  - Dark teal scarf wrapped around neck
  - Green tunic with leather belt
  - Brown leather mail satchel on hip with letters poking out
  - Walking stick in right hand
  - Brown leather boots
  - Tiny bird (Pibbet) on left shoulder

Same v4 recipe as the others. Tests humanoid + companion accessory in one
build. The bird is built as a small set of meshes parented to Arm_L so it
rides on the left shoulder.

Run:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
      --python scripts/rebuild_cricket_v3_painted.py
"""

import sys, os, math
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

import bpy
from _painted_build_lib import (
    make_material, add_box, add_soft_box, add_sphere, add_cylinder,
    add_cone, add_empty, wipe_by_prefix, export_glb,
)

PREFIXES = (
    'Cricket', 'CricketRoot',
    'Body', 'Head', 'Arm_', 'Leg_',
    'Hair', 'Eye_', 'Mouth', 'Nose', 'Brow', 'Freckle',
    'Tunic', 'Vest', 'Scarf', 'Belt', 'Pouch', 'Strap',
    'Sleeve_', 'Cuff', 'Hand_', 'Boot_', 'Trousers',
    'Stick', 'Letter',
    'Bird', 'Pibbet', 'Wing', 'Beak', 'Tail',
)
wipe_by_prefix(PREFIXES)

MAT_SKIN     = make_material('Cricket_Skin',    '#f4d4b0', roughness=0.78)
MAT_HAIR     = make_material('Cricket_Hair',    '#c45828', roughness=0.92)
MAT_FRECKLE  = make_material('Cricket_Freckle', '#a05030', roughness=0.85)
MAT_SCARF    = make_material('Cricket_Scarf',   '#3a5868', roughness=0.85)
MAT_TUNIC    = make_material('Cricket_Tunic',   '#3c5430', roughness=0.85)
MAT_LEATHER  = make_material('Cricket_Leather', '#4a3018', roughness=0.85)
MAT_POUCH    = make_material('Cricket_Pouch',   '#7c4828', roughness=0.85)
MAT_LETTER   = make_material('Cricket_Letter',  '#e8dcc0', roughness=0.85)
MAT_STICK    = make_material('Cricket_Stick',   '#5a3818', roughness=0.85)
MAT_BIRD     = make_material('Cricket_Bird',    '#7c5028', roughness=0.85)
MAT_BIRD_BLY = make_material('Cricket_BirdBelly', '#dcb888', roughness=0.85)
MAT_BEAK     = make_material('Cricket_Beak',    '#3c2410', roughness=0.85)
MAT_LINE     = make_material('Cricket_Line',    '#1a0e08', roughness=0.85)
MAT_EYE      = MAT_LINE
MAT_TROUSERS = make_material('Cricket_Trousers', '#3c3020', roughness=0.85)

# Cricket is shorter than Eldra — heightMul scaling at engine handles
# absolute size, here we author at our standard ~1.5m frame and let the
# scaling normalize.
Z_HIP, Z_SHOULDER, Z_NECK = 0.55, 0.95, 1.00

root      = add_empty('CricketRoot', (0, 0, 0))
body_emp  = add_empty('Body',  (0,     0,    Z_HIP),     parent=root)
head_emp  = add_empty('Head',  (0,     0,    Z_NECK),    parent=root)
arm_l_emp = add_empty('Arm_L', (0,    -0.18, Z_SHOULDER), parent=root)
arm_r_emp = add_empty('Arm_R', (0,     0.18, Z_SHOULDER), parent=root)
leg_l_emp = add_empty('Leg_L', (0,    -0.10, Z_HIP),      parent=root)
leg_r_emp = add_empty('Leg_R', (0,     0.10, Z_HIP),      parent=root)

# ---- BODY ----
add_soft_box('Tunic_Body', (0, 0, 0.74), (0.34, 0.30, 0.36), MAT_TUNIC, body_emp)
add_cylinder('Neck',       (0, 0, 1.02), 0.09, 0.14, MAT_SKIN, body_emp, vertices=10)

# Scarf — wraps the neck.
add_soft_box('Scarf_Front', (0.04, 0,    1.00), (0.26, 0.26, 0.12), MAT_SCARF, body_emp)
add_box('Scarf_Tail',       (-0.04, -0.12, 0.86), (0.04, 0.06, 0.20), MAT_SCARF, body_emp)

# Belt + cross-strap (mail satchel strap diagonal across chest).
add_box('Belt', (0, 0, 0.55), (0.36, 0.30, 0.04), MAT_LEATHER, body_emp,
        bevel_width=0.008)
add_box('Strap', (0.18, 0, 0.78), (0.02, 0.04, 0.30), MAT_LEATHER, body_emp,
        bevel_width=0.003, rot=(math.radians(-15), 0, 0))

# Mail satchel on right hip — leather pouch with letters poking out.
add_soft_box('Pouch_R', (0.04, 0.20, 0.50), (0.14, 0.10, 0.16), MAT_POUCH, body_emp)
# Letters — _detail (no individual outlines).
add_box('Letter_detail_a', (0.10, 0.20, 0.58), (0.02, 0.06, 0.04), MAT_LETTER, body_emp,
        bevel_width=0.002, rot=(0, 0, math.radians(8)))
add_box('Letter_detail_b', (0.10, 0.22, 0.59), (0.02, 0.05, 0.05), MAT_LETTER, body_emp,
        bevel_width=0.002, rot=(0, 0, math.radians(-5)))

# ---- LEGS ----
add_cylinder('Trousers_L', (0, -0.10, 0.30), 0.08, 0.50, MAT_TROUSERS, leg_l_emp, vertices=10)
add_cylinder('Trousers_R', (0,  0.10, 0.30), 0.08, 0.50, MAT_TROUSERS, leg_r_emp, vertices=10)
add_soft_box('Boot_L', (0.04, -0.10, 0.06), (0.18, 0.12, 0.10), MAT_LEATHER, leg_l_emp)
add_soft_box('Boot_R', (0.04,  0.10, 0.06), (0.18, 0.12, 0.10), MAT_LEATHER, leg_r_emp)

# ---- HEAD ----
add_sphere('Head_Mesh', (0, 0, 1.14), 0.17, MAT_SKIN, head_emp,
           segments=14, rings=10, scale=(1.05, 1.0, 0.95))

# Eyes — small dark slashes.
add_box('Eye_L', (0.16, -0.06, 1.16), (0.018, 0.026, 0.012), MAT_EYE, head_emp,
        bevel_width=0.003)
add_box('Eye_R', (0.16,  0.06, 1.16), (0.018, 0.026, 0.012), MAT_EYE, head_emp,
        bevel_width=0.003)

# Mouth and brows as _line accents.
add_box('Mouth_line', (0.166, 0, 1.07), (0.004, 0.030, 0.006), MAT_LINE, head_emp,
        bevel_width=0.001)
add_box('Brow_line_L', (0.156, -0.06, 1.20), (0.004, 0.034, 0.006), MAT_LINE, head_emp,
        bevel_width=0.001, rot=(0, 0, math.radians(-10)))
add_box('Brow_line_R', (0.156,  0.06, 1.20), (0.004, 0.034, 0.006), MAT_LINE, head_emp,
        bevel_width=0.001, rot=(0, 0, math.radians(10)))

# Freckle dots — _detail to skip outlines.
for i, (y, z) in enumerate([(-0.04, 1.10), (0, 1.09), (0.04, 1.10), (-0.06, 1.13), (0.06, 1.13)]):
    add_sphere(f'Freckle_detail_{i}', (0.165, y, z), 0.005, MAT_FRECKLE, head_emp,
               segments=6, rings=4)

# Round nose.
add_sphere('Nose', (0.17, 0, 1.12), 0.025, MAT_SKIN, head_emp, segments=8, rings=6)

# ---- HAIR — big curly mass + lots of ruffle bumps for the curls ----
add_sphere('Hair_Dome', (-0.04, 0, 1.30), 0.20, MAT_HAIR, head_emp,
           segments=14, rings=10, scale=(1.15, 1.10, 1.05))

# Curl ruffles — many overlapping spheres distributed over the dome to
# read as voluminous curly hair. Mix of two sizes for variation.
curl_positions = [
    (0.04, -0.10, 1.42, 0.060),
    (0.04,  0.10, 1.42, 0.060),
    (0.00, -0.16, 1.36, 0.055),
    (0.00,  0.16, 1.36, 0.055),
    (-0.06, -0.18, 1.30, 0.050),
    (-0.06,  0.18, 1.30, 0.050),
    (-0.14, -0.10, 1.34, 0.055),
    (-0.14,  0.10, 1.34, 0.055),
    (-0.04,  0,    1.50, 0.060),
    (-0.18,  0,    1.40, 0.050),
    (0.06,  0,    1.46, 0.050),
]
for i, (x, y, z, r) in enumerate(curl_positions):
    add_sphere(f'Hair_ruffle_curl_{i}', (x, y, z), r, MAT_HAIR, head_emp, segments=8, rings=6)

# ---- ARMS ----
add_soft_box('Sleeve_L', (0, -0.22, 0.80), (0.10, 0.10, 0.30), MAT_TUNIC, arm_l_emp)
add_box('Cuff_L', (0, -0.22, 0.65), (0.09, 0.09, 0.04), MAT_LEATHER, arm_l_emp,
        bevel_width=0.005)
add_sphere('Hand_L', (0, -0.22, 0.60), 0.05, MAT_SKIN, arm_l_emp, segments=10, rings=8)

add_soft_box('Sleeve_R', (0,  0.22, 0.80), (0.10, 0.10, 0.30), MAT_TUNIC, arm_r_emp)
add_box('Cuff_R', (0,  0.22, 0.65), (0.09, 0.09, 0.04), MAT_LEATHER, arm_r_emp,
        bevel_width=0.005)
add_sphere('Hand_R', (0,  0.22, 0.60), 0.05, MAT_SKIN, arm_r_emp, segments=10, rings=8)

# ---- WALKING STICK held in right hand ----
add_cylinder('Stick_Haft', (0.16, 0.27, 0.85), 0.022, 1.40, MAT_STICK, arm_r_emp,
             vertices=10)

# ---- PIBBET — tiny bird on left shoulder ----
# Parented to Arm_L so it rides on the shoulder. All meshes are small —
# main body gets the silhouette outline, wing + beak are _detail.
add_sphere('Bird_Body', (0.04, -0.30, 1.04), 0.045, MAT_BIRD, arm_l_emp,
           segments=10, rings=8, scale=(1.0, 1.1, 0.9))
add_sphere('Bird_Head', (0.08, -0.32, 1.10), 0.030, MAT_BIRD, arm_l_emp,
           segments=10, rings=8)
add_sphere('Bird_detail_belly', (0.06, -0.30, 1.02), 0.035, MAT_BIRD_BLY, arm_l_emp,
           segments=8, rings=6, scale=(1.0, 0.6, 0.8))
add_box('Bird_Beak_detail', (0.115, -0.32, 1.10), (0.020, 0.008, 0.008), MAT_BEAK, arm_l_emp,
        bevel_width=0.002)
add_box('Bird_Eye_detail', (0.10, -0.34, 1.115), (0.005, 0.005, 0.005), MAT_EYE, arm_l_emp,
        bevel_width=0.001)
add_box('Bird_Wing_detail', (0.02, -0.32, 1.05), (0.04, 0.012, 0.025), MAT_BIRD, arm_l_emp,
        bevel_width=0.002, rot=(0, math.radians(-10), 0))

# ---- EXPORT ----
PROJECT_ROOT = os.environ.get('GJ26_PROJECT_ROOT',
                              os.path.abspath(os.path.dirname(__file__) + '/..'))
out_path = os.path.join(PROJECT_ROOT, 'models', 'npc_cricket_v3.glb')
export_glb(root, out_path)

mesh_count = sum(1 for o in bpy.data.objects if o.type == 'MESH'
                 and o.name.startswith(PREFIXES))
print(f"\n=== Exported {out_path} ({mesh_count} meshes) ===")
for name in ('Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R'):
    o = bpy.data.objects.get(name)
    if o:
        print(f"  {name} — {len(o.children)} direct children")
