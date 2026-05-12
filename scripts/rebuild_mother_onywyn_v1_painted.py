"""Rebuild Mother Onywyn as `models/npc_mother_onywyn_v1.glb` — painted.

From `docs/concept-art/npc-mother-onywyn.png`:
  - Chibi young woman, hooded forest-green cloak
  - Long black hair flowing out from under the hood
  - Big dark anime-style eyes, pale skin
  - Layered tunic: dark teal body + cream embroidered side panels
  - Cross-body sash, leather pouches at belt
  - Black skinny pants tucked into dark brown boots
  - Walking staff in left hand with a crow perched on top

First female NPC in the cast. First v4 build with: hood mass, long hair,
companion creature on prop. Eyes/brows authored at x=0.221 from start
(Eldra/Hod fix bakes in proactively).

Run:
  /Applications/Blender.app/Contents/MacOS/Blender --background \\
      --python scripts/rebuild_mother_onywyn_v1_painted.py
"""

import sys, os, math
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

import bpy
from _painted_build_lib import (
    make_material, add_box, add_soft_box, add_sphere, add_cylinder,
    add_cone, add_empty, wipe_by_prefix, export_glb,
)

PREFIXES = (
    'Onywyn', 'OnywynRoot', 'Body', 'Head', 'Arm_', 'Leg_',
    'Hair', 'Hood', 'Eye_', 'Brow_', 'Nose', 'Mouth', 'Cheek',
    'Tunic', 'Vest', 'Sash', 'Belt', 'Pouch', 'Cloak', 'Cuff',
    'Sleeve_', 'Hand_', 'Pants_', 'Boot_',
    'Staff', 'Crow',
)
wipe_by_prefix(PREFIXES)

# ---------------------------------------------------------------------------
# Materials — colors from the concept art
# ---------------------------------------------------------------------------

MAT_SKIN     = make_material('Onywyn_Skin',     '#f0d4b8', roughness=0.78)
MAT_HAIR     = make_material('Onywyn_Hair',     '#1a1418', roughness=0.92)
MAT_HOOD     = make_material('Onywyn_Hood',     '#2c4838', roughness=0.88)  # forest green
MAT_TUNIC    = make_material('Onywyn_Tunic',    '#3a5050', roughness=0.85)  # dark teal
MAT_PANEL    = make_material('Onywyn_Panel',    '#d4c098', roughness=0.85)  # cream embroidered side
MAT_SASH     = make_material('Onywyn_Sash',     '#3a4838', roughness=0.85)
MAT_LEATHER  = make_material('Onywyn_Leather',  '#4a3018', roughness=0.85)
MAT_PANTS    = make_material('Onywyn_Pants',    '#2a2628', roughness=0.85)
MAT_BOOT     = make_material('Onywyn_Boot',     '#5a3820', roughness=0.82)
MAT_STAFF    = make_material('Onywyn_Staff',    '#7a5838', roughness=0.85)
MAT_CROW     = make_material('Onywyn_Crow',     '#1c1820', roughness=0.88)
MAT_CROW_LT  = make_material('Onywyn_CrowLt',   '#3c3030', roughness=0.85)
MAT_BEAK     = make_material('Onywyn_Beak',     '#2a2828', roughness=0.65)
MAT_LINE     = make_material('Onywyn_Line',     '#1a0e08', roughness=0.85)

MAT_EYE = MAT_LINE
MAT_BROW = MAT_LINE

# ---------------------------------------------------------------------------
# Rig — same 6-empty layout as Hod/Eldra so engine walk anim transfers.
# ---------------------------------------------------------------------------

Z_HIP, Z_SHOULDER, Z_NECK = 0.55, 0.95, 1.00

root      = add_empty('OnywynRoot', (0, 0, 0))
body_emp  = add_empty('Body',  (0,    0,    Z_HIP),     parent=root)
head_emp  = add_empty('Head',  (0,    0,    Z_NECK),    parent=root)
arm_l_emp = add_empty('Arm_L', (0,   -0.16, Z_SHOULDER), parent=root)
arm_r_emp = add_empty('Arm_R', (0,    0.16, Z_SHOULDER), parent=root)
leg_l_emp = add_empty('Leg_L', (0,   -0.08, Z_HIP),      parent=root)
leg_r_emp = add_empty('Leg_R', (0,    0.08, Z_HIP),      parent=root)

# ---------------------------------------------------------------------------
# Body — slim chibi torso (narrower than Hod)
# ---------------------------------------------------------------------------

# Tunic body — dark teal vest
add_soft_box('Tunic_Body',  (0, 0, 0.74), (0.30, 0.26, 0.34), MAT_TUNIC, body_emp)
# Cream embroidered side panels — slim vertical strips on either side of the
# tunic, peeking out from under the hood
add_box('Tunic_Panel_L', (0.05, -0.14, 0.66), (0.18, 0.04, 0.22), MAT_PANEL, body_emp)
add_box('Tunic_Panel_R', (0.05,  0.14, 0.66), (0.18, 0.04, 0.22), MAT_PANEL, body_emp)
# Cross-body sash — diagonal scarf on the chest
add_box('Sash', (0.06, -0.04, 0.92), (0.12, 0.20, 0.06), MAT_SASH, body_emp,
        bevel_width=0.005, rot=(0, 0, math.radians(15)))
# Skirt — short flare under the tunic
add_soft_box('Tunic_Skirt', (0, 0, 0.46), (0.30, 0.28, 0.10), MAT_TUNIC, body_emp)
# Belt
add_box('Belt', (0, 0, 0.56), (0.32, 0.28, 0.04), MAT_LEATHER, body_emp)
# Two small pouches at hip
add_box('Pouch_L', (0.04, -0.16, 0.50), (0.08, 0.06, 0.07), MAT_LEATHER, body_emp)
add_box('Pouch_R', (0.04,  0.16, 0.50), (0.08, 0.06, 0.07), MAT_LEATHER, body_emp)
# Neck cylinder
add_cylinder('Neck', (0, 0, 1.02), 0.07, 0.10, MAT_SKIN, body_emp, vertices=10)

# Cloak back — drapes from shoulders down past the skirt. Soft-box for
# weighty fabric look. Sits behind the body.
add_soft_box('Cloak_Back', (-0.14, 0, 0.66), (0.10, 0.36, 0.50), MAT_HOOD, body_emp)

# ---------------------------------------------------------------------------
# Legs — skinny pants + boots
# ---------------------------------------------------------------------------

add_cylinder('Pants_L', (0, -0.08, 0.30), 0.06, 0.50, MAT_PANTS, leg_l_emp, vertices=10)
add_cylinder('Pants_R', (0,  0.08, 0.30), 0.06, 0.50, MAT_PANTS, leg_r_emp, vertices=10)
add_soft_box('Boot_L', (0.04, -0.08, 0.07), (0.16, 0.10, 0.10), MAT_BOOT, leg_l_emp)
add_soft_box('Boot_R', (0.04,  0.08, 0.07), (0.16, 0.10, 0.10), MAT_BOOT, leg_r_emp)

# ---------------------------------------------------------------------------
# Head — pale chibi face + long black hair + green hood
# ---------------------------------------------------------------------------

# Face sphere — slightly smaller than Hod (radius 0.18) for chibi proportions
add_sphere('Head_Mesh', (0, 0, 1.16), 0.18, MAT_SKIN, head_emp,
           segments=14, rings=10, scale=(1.0, 1.0, 1.05))

# Long black hair — main mass behind the head, drapes down past shoulders.
# Uses soft_box for a fabric-like sweep silhouette.
add_soft_box('Hair_Back', (-0.06, 0, 1.05), (0.12, 0.36, 0.50), MAT_HAIR, head_emp)
# Hair side strands — peek out from under the hood, in front of the ears
add_soft_box('Hair_Side_L', (0.10, -0.18, 1.05), (0.10, 0.06, 0.36), MAT_HAIR, head_emp)
add_soft_box('Hair_Side_R', (0.10,  0.18, 1.05), (0.10, 0.06, 0.36), MAT_HAIR, head_emp)
# Forehead bangs — short fringe peeking from under the hood. Slim band
# right under the hood opening, above the brows.
add_box('Hair_Bangs', (0.221, 0, 1.25), (0.04, 0.22, 0.04), MAT_HAIR, head_emp,
        bevel_width=0.005)

# Hood — large green dome covering the top of the head, opens forward to
# show the face. Authored as a sphere centered slightly back from face,
# scaled forward less so the face shows.
add_sphere('Hood_Top', (-0.04, 0, 1.34), 0.22, MAT_HOOD, head_emp,
           segments=14, rings=10, scale=(1.05, 1.10, 1.05))
# Hood point — tapered ridge at the very top (soft cone)
add_cone('Hood_Point', (-0.10, 0, 1.52), radius_base=0.12, radius_tip=0.04,
         height=0.10, mat=MAT_HOOD, parent=head_emp, vertices=8,
         rot=(0, math.radians(-20), 0))
# Hood collar — thick ring around the neck
add_cylinder('Hood_Collar', (-0.04, 0, 1.04), 0.18, 0.08, MAT_HOOD, head_emp,
             vertices=14)

# Eyes — big anime-style. Authored at x=0.221 from the start (past head
# surface at x=0.18 + tweak for the bigger relative size).
# Use small dark spheres (more anime than the Eldra/Hod slash-boxes).
add_sphere('Eye_L', (0.181, -0.06, 1.15), 0.025, MAT_EYE, head_emp,
           segments=8, rings=6)
add_sphere('Eye_R', (0.181,  0.06, 1.15), 0.025, MAT_EYE, head_emp,
           segments=8, rings=6)

# Subtle dark brows — pushed forward and lowered slightly so they sit
# between the bangs (z=1.25) and the eyes (z=1.15) without overlapping.
add_box('Brow_L', (0.221, -0.06, 1.20), (0.018, 0.040, 0.010), MAT_BROW, head_emp,
        bevel_width=0.002)
add_box('Brow_R', (0.221,  0.06, 1.20), (0.018, 0.040, 0.010), MAT_BROW, head_emp,
        bevel_width=0.002)

# Tiny mouth line — also pushed forward and slightly bigger to read at
# NPC distance.
add_box('Mouth_line', (0.221, 0, 1.07), (0.012, 0.040, 0.014), MAT_LINE, head_emp,
        bevel_width=0.002)

# ---------------------------------------------------------------------------
# Arms — sleeves + hands
# ---------------------------------------------------------------------------

add_soft_box('Sleeve_L', (0, -0.20, 0.80), (0.10, 0.10, 0.30), MAT_TUNIC, arm_l_emp)
add_box('Cuff_L', (0, -0.20, 0.65), (0.09, 0.09, 0.04), MAT_PANEL, arm_l_emp)
add_sphere('Hand_L', (0, -0.20, 0.60), 0.045, MAT_SKIN, arm_l_emp, segments=10, rings=8)

add_soft_box('Sleeve_R', (0,  0.20, 0.80), (0.10, 0.10, 0.30), MAT_TUNIC, arm_r_emp)
add_box('Cuff_R', (0,  0.20, 0.65), (0.09, 0.09, 0.04), MAT_PANEL, arm_r_emp)
add_sphere('Hand_R', (0,  0.20, 0.60), 0.045, MAT_SKIN, arm_r_emp, segments=10, rings=8)

# ---------------------------------------------------------------------------
# Staff — held in LEFT hand (vs Eldra's right-hand staff)
# ---------------------------------------------------------------------------

# Pole runs from hand-grip up past head height. Hand at z=0.60, top at ~1.6.
add_cylinder('Staff_Pole', (0.18, -0.22, 1.00), 0.025, 1.40, MAT_STAFF, arm_l_emp, vertices=10)
# Knot/wrap near the top where the crow perches
add_cylinder('Staff_Knot', (0.18, -0.22, 1.55), 0.04, 0.06, MAT_STAFF, arm_l_emp, vertices=10)

# ---------------------------------------------------------------------------
# Crow — perched atop the staff
# ---------------------------------------------------------------------------

# Body (egg shape — sphere with vertical scale). Larger so it reads at
# game distance where the crow is up high above the staff.
add_sphere('Crow_Body', (0.18, -0.22, 1.66), 0.10, MAT_CROW, arm_l_emp,
           segments=10, rings=8, scale=(1.0, 1.0, 1.2))
# Head (smaller sphere ahead of body)
add_sphere('Crow_Head', (0.26, -0.22, 1.74), 0.05, MAT_CROW, arm_l_emp,
           segments=10, rings=8)
# Beak (small forward-pointing cone)
add_cone('Crow_Beak', (0.32, -0.22, 1.74), radius_base=0.022, radius_tip=0.005,
         height=0.05, mat=MAT_BEAK, parent=arm_l_emp, vertices=6,
         rot=(0, math.radians(90), 0))
# Eye (tiny dot)
add_sphere('Crow_Eye_detail', (0.27, -0.18, 1.76), 0.008, MAT_LINE, arm_l_emp,
           segments=6, rings=4)
# Tail (small triangular flap)
add_box('Crow_Tail', (0.10, -0.22, 1.68), (0.06, 0.04, 0.04), MAT_CROW, arm_l_emp,
        bevel_width=0.005, rot=(0, math.radians(-15), 0))
# Wings (folded flat against body)
add_box('Crow_Wing_L', (0.16, -0.28, 1.66), (0.08, 0.025, 0.10), MAT_CROW_LT, arm_l_emp,
        bevel_width=0.005)
add_box('Crow_Wing_R', (0.16, -0.16, 1.66), (0.08, 0.025, 0.10), MAT_CROW_LT, arm_l_emp,
        bevel_width=0.005)
# Feet — tiny clawed cylinders gripping the staff knot
add_cylinder('Crow_Foot_L', (0.18, -0.24, 1.59), 0.008, 0.04, MAT_BEAK, arm_l_emp,
             vertices=6)
add_cylinder('Crow_Foot_R', (0.18, -0.20, 1.59), 0.008, 0.04, MAT_BEAK, arm_l_emp,
             vertices=6)

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

PROJECT_ROOT = os.environ.get('GJ26_PROJECT_ROOT',
                              os.path.abspath(os.path.dirname(__file__) + '/..'))
out_path = os.path.join(PROJECT_ROOT, 'models', 'npc_mother_onywyn_v1.glb')
export_glb(root, out_path)

mesh_count = sum(1 for o in bpy.data.objects if o.type == 'MESH'
                 and o.name.startswith(PREFIXES))
print(f"\n=== Exported {out_path} ({mesh_count} meshes) ===")
for name in ('Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R'):
    o = bpy.data.objects.get(name)
    if o:
        print(f"  {name} — {len(o.children)} direct children")
