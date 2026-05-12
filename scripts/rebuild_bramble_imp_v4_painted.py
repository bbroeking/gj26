"""Rebuild Bramble Imp as `models/bramble_imp_v4.glb` — painted-render-tuned.

Bramble Imp from `docs/concept-art/bramble-imp.png`:
  - Small chibi creature, head bigger than body
  - Green skin with lighter peach belly + ear interiors + nose
  - LARGE mossy/leafy hood that covers head + shoulders (silhouette feature)
  - Big pointed ears flaring outward
  - Big black eyes, small fang teeth, round dark nose
  - Brown fur collar at chest, cream bone-y belly panel
  - Stubby green arms with claws, stubby legs with claw feet
  - Holds a wooden spiked club (silhouette feature)

Same v4 recipe as Eldra/Hod:
  - Soft-box body / single-mass head + leafy hood for silhouette
  - _ruffle bumps on the moss for fluff variation
  - _line accents for mouth, brow strokes (no individual ink lines)
  - _detail for small studs/teeth

The unified-silhouette outline pass in painted_materials.js + codex.js
takes care of producing one ink line around the whole figure.

Run:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
      --python scripts/rebuild_bramble_imp_v4_painted.py
"""

import sys, os, math
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

import bpy
from _painted_build_lib import (
    make_material, add_box, add_soft_box, add_sphere, add_cylinder,
    add_cone, add_empty, wipe_by_prefix, export_glb,
)

# ---------------------------------------------------------------------------
# 1. Wipe — Imp-specific prefixes
# ---------------------------------------------------------------------------

PREFIXES = (
    'Imp', 'BrambleImp', 'BrambleImpRoot',
    'Body', 'Head', 'Arm_', 'Leg_',
    'Ear', 'Eye_', 'Mouth', 'Nose', 'Tooth_', 'Brow',
    'Hood', 'Moss', 'Fur', 'Collar',
    'Belly', 'Skirt', 'Tunic', 'Tail',
    'Hand_', 'Foot_', 'Claw_', 'Sleeve_', 'Trousers',
    'Club',
)
wipe_by_prefix(PREFIXES)

# ---------------------------------------------------------------------------
# 2. Materials — concept-derived hexes (paintifyAuto reads .color)
# ---------------------------------------------------------------------------

MAT_SKIN_GREEN = make_material('Imp_SkinGreen', '#5a7838', roughness=0.85)
MAT_SKIN_LIGHT = make_material('Imp_SkinLight', '#d49060', roughness=0.85)  # peachy ear interior + nose
MAT_MOSS       = make_material('Imp_Moss',      '#3a5028', roughness=0.92)  # dark green hood/leaf
MAT_MOSS_LIGHT = make_material('Imp_MossLight', '#688038', roughness=0.92)  # lighter leaf accents
MAT_BELLY      = make_material('Imp_Belly',     '#dcc8a0', roughness=0.85)  # cream bone-y belly
MAT_FUR        = make_material('Imp_Fur',       '#5c3818', roughness=0.95)  # brown collar
MAT_EYE        = make_material('Imp_Eye',       '#1c1610', roughness=0.40)  # near-black with slight warmth
MAT_TOOTH      = make_material('Imp_Tooth',     '#f0e8c8', roughness=0.55)
MAT_LINE       = make_material('Imp_Line',      '#1a0e08', roughness=0.85)  # ink-line accent (mouth, brow)
MAT_CLUB_WOOD  = make_material('Imp_ClubWood',  '#5a3818', roughness=0.85)
MAT_CLUB_SPIKE = make_material('Imp_ClubSpike', '#dcc8a0', roughness=0.55)

# ---------------------------------------------------------------------------
# 3. Empties — small chibi proportions
# ---------------------------------------------------------------------------

# Imp is ~0.6m tall, head occupies ~half the figure (chibi).
Z_HIP, Z_SHOULDER, Z_NECK = 0.20, 0.36, 0.40

root      = add_empty('BrambleImpRoot', (0, 0, 0))
body_emp  = add_empty('Body',  (0,     0,    Z_HIP),     parent=root)
head_emp  = add_empty('Head',  (0,     0,    Z_NECK),    parent=root)
arm_l_emp = add_empty('Arm_L', (0,    -0.13, Z_SHOULDER), parent=root)
arm_r_emp = add_empty('Arm_R', (0,     0.13, Z_SHOULDER), parent=root)
leg_l_emp = add_empty('Leg_L', (0,    -0.07, Z_HIP),      parent=root)
leg_r_emp = add_empty('Leg_R', (0,     0.07, Z_HIP),      parent=root)

# ---------------------------------------------------------------------------
# 4. Body — soft_box torso + cream belly panel + brown fur collar
# ---------------------------------------------------------------------------

# Torso — small soft_box. Slightly tapered.
add_soft_box('Body_Torso', (0, 0, 0.24), (0.18, 0.18, 0.20), MAT_SKIN_GREEN, body_emp)

# Belly panel — cream/bone rectangle on the front, suggesting bone-armor.
add_soft_box('Belly_Panel', (0.10, 0, 0.22), (0.04, 0.14, 0.16), MAT_BELLY, body_emp)

# Fur collar — brown ring around the neck base. Cylinder rotated to wrap.
add_cylinder('Fur_Collar', (0, 0, 0.36), 0.13, 0.04, MAT_FUR, body_emp,
             vertices=14)

# Skirt — cream wrap at the hip, suggesting bone tabs.
add_soft_box('Skirt', (0, 0, 0.16), (0.20, 0.20, 0.06), MAT_BELLY, body_emp)

# ---------------------------------------------------------------------------
# 5. Head — big sphere + huge mossy hood + ears + face features
# ---------------------------------------------------------------------------

# Head — big sphere, dominant feature (chibi).
add_sphere('Head_Mesh', (0, 0, 0.48), 0.18, MAT_SKIN_GREEN, head_emp,
           segments=14, rings=10, scale=(1.0, 1.0, 0.95))

# ---- MOSSY HOOD — defining silhouette feature ----
# Big leafy mass covering the top + back of the head. Single sphere mass
# carries the silhouette; ruffle bumps add foliage variation.
add_sphere('Hood_Mass', (-0.04, 0, 0.62), 0.18, MAT_MOSS, head_emp,
           segments=14, rings=10, scale=(1.1, 1.2, 0.9))

# Hood ruffles — leaf clumps protruding from the main hood mass. Mix of
# darker (MAT_MOSS) and lighter (MAT_MOSS_LIGHT) for foliage variation.
add_sphere('Hood_ruffle_top',     (-0.04, 0,    0.72), 0.06, MAT_MOSS_LIGHT, head_emp, segments=8, rings=6)
add_sphere('Hood_ruffle_front',   (0.05,  0,    0.66), 0.06, MAT_MOSS,       head_emp, segments=8, rings=6)
add_sphere('Hood_ruffle_back_L',  (-0.16,-0.10, 0.62), 0.05, MAT_MOSS,       head_emp, segments=8, rings=6)
add_sphere('Hood_ruffle_back_R',  (-0.16, 0.10, 0.62), 0.05, MAT_MOSS,       head_emp, segments=8, rings=6)
add_sphere('Hood_ruffle_side_L',  (-0.04,-0.18, 0.55), 0.05, MAT_MOSS_LIGHT, head_emp, segments=8, rings=6)
add_sphere('Hood_ruffle_side_R',  (-0.04, 0.18, 0.55), 0.05, MAT_MOSS_LIGHT, head_emp, segments=8, rings=6)

# ---- EARS — large pointed cones flaring outward ----
# Outer green skin shell + lighter peach interior to suggest the inner ear.
add_cone('Ear_L', (0.04, -0.20, 0.50), radius_base=0.06, radius_tip=0.02,
         height=0.14, mat=MAT_SKIN_GREEN, parent=head_emp, vertices=8,
         rot=(math.radians(-90), 0, math.radians(20)))
add_cone('Ear_R', (0.04,  0.20, 0.50), radius_base=0.06, radius_tip=0.02,
         height=0.14, mat=MAT_SKIN_GREEN, parent=head_emp, vertices=8,
         rot=(math.radians(90),  0, math.radians(-20)))
# Inner-ear peach cones (smaller, slightly inset).
add_cone('Ear_L_detail_inner', (0.06, -0.18, 0.50), radius_base=0.04, radius_tip=0.015,
         height=0.10, mat=MAT_SKIN_LIGHT, parent=head_emp, vertices=6,
         rot=(math.radians(-90), 0, math.radians(20)))
add_cone('Ear_R_detail_inner', (0.06,  0.18, 0.50), radius_base=0.04, radius_tip=0.015,
         height=0.10, mat=MAT_SKIN_LIGHT, parent=head_emp, vertices=6,
         rot=(math.radians(90),  0, math.radians(-20)))

# ---- FACE — eyes, nose, mouth, fangs ----
# Big black eyes.
add_sphere('Eye_L', (0.16, -0.07, 0.48), 0.03, MAT_EYE, head_emp,
           segments=8, rings=6, scale=(0.7, 1.0, 1.1))
add_sphere('Eye_R', (0.16,  0.07, 0.48), 0.03, MAT_EYE, head_emp,
           segments=8, rings=6, scale=(0.7, 1.0, 1.1))
# Tiny eye highlight dots — _detail so no outline.
add_sphere('Eye_L_detail_glint', (0.18, -0.06, 0.49), 0.008, MAT_BELLY, head_emp,
           segments=6, rings=4)
add_sphere('Eye_R_detail_glint', (0.18,  0.06, 0.49), 0.008, MAT_BELLY, head_emp,
           segments=6, rings=4)

# Round peach nose.
add_sphere('Nose', (0.18, 0, 0.42), 0.025, MAT_SKIN_LIGHT, head_emp,
           segments=8, rings=6)

# Mouth line — thin dark sliver. Named _line so the outline pass skips it
# (it IS our mouth ink line; we don't want it re-outlined).
add_box('Mouth_line', (0.175, 0, 0.36), (0.005, 0.05, 0.008), MAT_LINE, head_emp,
        bevel_width=0.001)
# Two small fangs — _detail (skip outline, read as cream nubs).
add_box('Tooth_detail_L', (0.176, -0.012, 0.345), (0.006, 0.010, 0.012), MAT_TOOTH, head_emp,
        bevel_width=0.001)
add_box('Tooth_detail_R', (0.176,  0.012, 0.345), (0.006, 0.010, 0.012), MAT_TOOTH, head_emp,
        bevel_width=0.001)

# Brow stroke lines — _line accents over the eyes for an angry look.
add_box('Brow_line_L', (0.166, -0.07, 0.515), (0.004, 0.040, 0.006), MAT_LINE, head_emp,
        bevel_width=0.001, rot=(0, 0, math.radians(-15)))
add_box('Brow_line_R', (0.166,  0.07, 0.515), (0.004, 0.040, 0.006), MAT_LINE, head_emp,
        bevel_width=0.001, rot=(0, 0, math.radians(15)))

# ---------------------------------------------------------------------------
# 6. Arms — stubby green sleeves + small claw hands
# ---------------------------------------------------------------------------

add_soft_box('Sleeve_L', (0, -0.16, 0.30), (0.08, 0.08, 0.16), MAT_SKIN_GREEN, arm_l_emp)
add_sphere('Hand_L',     (0, -0.16, 0.20), 0.05, MAT_SKIN_GREEN, arm_l_emp,
           segments=10, rings=8, scale=(1.0, 1.0, 0.9))
# Hand claws — three tiny cones poking forward from the hand. _detail so
# they don't get outlines (they read as small claw points on the hand mass).
add_cone('Hand_L_detail_claw_a', (0.04, -0.18, 0.18), radius_base=0.012, radius_tip=0.003,
         height=0.025, mat=MAT_TOOTH, parent=arm_l_emp, vertices=6,
         rot=(0, math.radians(70), 0))
add_cone('Hand_L_detail_claw_b', (0.04, -0.16, 0.18), radius_base=0.012, radius_tip=0.003,
         height=0.025, mat=MAT_TOOTH, parent=arm_l_emp, vertices=6,
         rot=(0, math.radians(70), 0))
add_cone('Hand_L_detail_claw_c', (0.04, -0.14, 0.18), radius_base=0.012, radius_tip=0.003,
         height=0.025, mat=MAT_TOOTH, parent=arm_l_emp, vertices=6,
         rot=(0, math.radians(70), 0))

add_soft_box('Sleeve_R', (0,  0.16, 0.30), (0.08, 0.08, 0.16), MAT_SKIN_GREEN, arm_r_emp)
add_sphere('Hand_R',     (0,  0.16, 0.20), 0.05, MAT_SKIN_GREEN, arm_r_emp,
           segments=10, rings=8, scale=(1.0, 1.0, 0.9))

# ---------------------------------------------------------------------------
# 7. Legs — short cylinders + claw feet
# ---------------------------------------------------------------------------

add_cylinder('Trousers_L', (0, -0.07, 0.10), 0.06, 0.18, MAT_SKIN_GREEN, leg_l_emp, vertices=10)
add_cylinder('Trousers_R', (0,  0.07, 0.10), 0.06, 0.18, MAT_SKIN_GREEN, leg_r_emp, vertices=10)

add_soft_box('Foot_L', (0.04, -0.07, 0.02), (0.10, 0.08, 0.04), MAT_SKIN_GREEN, leg_l_emp)
add_soft_box('Foot_R', (0.04,  0.07, 0.02), (0.10, 0.08, 0.04), MAT_SKIN_GREEN, leg_r_emp)

# Foot claws — cream cones pointing forward, _detail so no outlines.
for side, leg_emp in [('L', leg_l_emp), ('R', leg_r_emp)]:
    side_y = -0.07 if side == 'L' else 0.07
    for i, dy in enumerate((-0.025, 0, 0.025)):
        add_cone(f'Foot_{side}_detail_claw_{i}', (0.10, side_y + dy, 0.015),
                 radius_base=0.010, radius_tip=0.003, height=0.025,
                 mat=MAT_TOOTH, parent=leg_emp, vertices=6,
                 rot=(0, math.radians(75), 0))

# ---------------------------------------------------------------------------
# 8. Club — held in right hand, silhouette feature
# ---------------------------------------------------------------------------

# Wood handle — long cylinder.
add_cylinder('Club_Haft', (0.12, 0.20, 0.30), 0.020, 0.40, MAT_CLUB_WOOD, arm_r_emp,
             vertices=8)
# Bone spike at the top — cone pointing up.
add_cone('Club_Spike', (0.12, 0.20, 0.55),
         radius_base=0.040, radius_tip=0.005, height=0.10,
         mat=MAT_CLUB_SPIKE, parent=arm_r_emp, vertices=6)

# ---------------------------------------------------------------------------
# 9. Export
# ---------------------------------------------------------------------------

PROJECT_ROOT = os.environ.get('GJ26_PROJECT_ROOT',
                              os.path.abspath(os.path.dirname(__file__) + '/..'))
out_path = os.path.join(PROJECT_ROOT, 'models', 'bramble_imp_v4.glb')
export_glb(root, out_path)

mesh_count = sum(1 for o in bpy.data.objects if o.type == 'MESH'
                 and o.name.startswith(PREFIXES))
print(f"\n=== Exported {out_path} ({mesh_count} meshes) ===")
for name in ('Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R'):
    o = bpy.data.objects.get(name)
    if o:
        print(f"  {name} — {len(o.children)} direct children")
