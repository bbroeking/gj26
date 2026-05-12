"""Rebuild Hod the Tenter as `models/npc_hod_v3.glb` — painted-render-tuned.

Hod from `docs/concept-art/npc-hod-tenter.png`:
  - Stocky bald smith with a BIG bushy gray-cream beard
  - Green headband around the bald scalp
  - Slightly pointed ears
  - Heavy leather body armor with metal-scale shoulder pauldrons
  - Brown leather apron over a green tunic skirt
  - Green sash at waist
  - Brown leather boots, stocky proportions

Recipe is the same as Eldra v4: simple primitives + soft_box for clothing,
single-mass beard, no fragmented sub-decorations. Replaces the existing
v2 build (70 meshes / 484K tris) with a painted-friendly geometry budget
of ~30-40 meshes.

Reuses material names that align with paintifyAuto's auto-derive (each
material's color drives the painted lit/base/shadow ramp).

Run:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
      --python scripts/rebuild_hod_v3_painted.py
"""

import sys, os, math
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

import bpy
from _painted_build_lib import (
    make_material, add_box, add_soft_box, add_sphere, add_cylinder,
    add_cone, add_empty, wipe_by_prefix, export_glb,
)

# ---------------------------------------------------------------------------
# 1. Wipe — idempotent rebuild. Use Hod_-specific prefixes only so we don't
#    nuke any other objects sitting in the scene.
# ---------------------------------------------------------------------------

PREFIXES = (
    'Hod', 'HodRoot', 'Body', 'Head', 'Arm_', 'Leg_',
    'Beard', 'Headband', 'Ear', 'Brow', 'Eye_', 'Nose', 'Chin_',
    'Tunic', 'Vest', 'Apron', 'Sash', 'Belt', 'Pouch', 'Pauldron',
    'Sleeve_', 'Cuff', 'Hand_', 'Boot_', 'Trousers',
    'Hammer',
)
wipe_by_prefix(PREFIXES)

# ---------------------------------------------------------------------------
# 2. Materials — colors lifted from npc-hod-tenter.png concept art
# ---------------------------------------------------------------------------

MAT_SKIN     = make_material('Hod_Skin',     '#d8a878', roughness=0.78)
MAT_BEARD    = make_material('Hod_Beard',    '#e0d8c4', roughness=0.92)
MAT_BROW     = make_material('Hod_Brow',     '#988868', roughness=0.92)
MAT_HEADBAND = make_material('Hod_Headband', '#6c8848', roughness=0.85)
MAT_TUNIC    = make_material('Hod_Tunic',    '#5a7838', roughness=0.85)  # green tunic visible at sleeves + skirt
MAT_VEST     = make_material('Hod_Vest',     '#3c2818', roughness=0.85)  # dark leather vest
MAT_APRON    = make_material('Hod_Apron',    '#583820', roughness=0.85)  # brown leather apron
MAT_SASH     = make_material('Hod_Sash',     '#7c9050', roughness=0.85)  # green sash at waist
MAT_LEATHER  = make_material('Hod_Leather',  '#4a3018', roughness=0.85)  # belt / pouches / boots
MAT_PAULDRON = make_material('Hod_Pauldron', '#a89880', roughness=0.55)  # weathered metal-pewter shoulders
MAT_HAMMER_M = make_material('Hod_HammerMetal', '#7a7268', roughness=0.40)
MAT_HAMMER_W = make_material('Hod_HammerWood',  '#5a3c20', roughness=0.85)
MAT_EYE      = MAT_LEATHER

# ---------------------------------------------------------------------------
# 3. Empties — same 6-empty rig as Eldra v4
# ---------------------------------------------------------------------------

# Hod is stockier than Eldra: shorter legs, more barrel torso. Slightly
# lower shoulders, slightly higher hips.
Z_HIP, Z_SHOULDER, Z_NECK, Z_HEAD_TOP = 0.55, 0.95, 1.00, 1.55

root      = add_empty('HodRoot', (0, 0, 0))
body_emp  = add_empty('Body',  (0,     0,    Z_HIP),     parent=root)
head_emp  = add_empty('Head',  (0,     0,    Z_NECK),    parent=root)
arm_l_emp = add_empty('Arm_L', (0,    -0.20, Z_SHOULDER), parent=root)
arm_r_emp = add_empty('Arm_R', (0,     0.20, Z_SHOULDER), parent=root)
leg_l_emp = add_empty('Leg_L', (0,    -0.10, Z_HIP),      parent=root)
leg_r_emp = add_empty('Leg_R', (0,     0.10, Z_HIP),      parent=root)

# ---------------------------------------------------------------------------
# 4. Body — barrel-chest soft_box vest + leather apron + green sash + belt
# ---------------------------------------------------------------------------

# Vest — dark leather body armor. Wider than Eldra's (Hod is barrel-chested).
add_soft_box('Vest_Body', (0, 0, 0.74), (0.42, 0.36, 0.40), MAT_VEST, body_emp)
# Neck cylinder.
add_cylinder('Neck', (0, 0, 1.02), 0.10, 0.14, MAT_SKIN, body_emp, vertices=10)

# Apron — brown leather rectangle hanging from chest down past belt.
add_soft_box('Apron', (0.20, 0, 0.65), (0.04, 0.30, 0.50), MAT_APRON, body_emp)

# Apron stitching/seam details — 2 horizontal seams + 1 vertical center
# stitch. Named *_detail_* so the outline pass skips them; the painted
# shading just darkens the surface around them, reading as stitched leather.
add_box('Apron_detail_seam_top', (0.225, 0, 0.78), (0.005, 0.28, 0.012),
        MAT_LEATHER, body_emp, bevel_width=0.002)
add_box('Apron_detail_seam_bot', (0.225, 0, 0.48), (0.005, 0.28, 0.012),
        MAT_LEATHER, body_emp, bevel_width=0.002)
add_box('Apron_detail_seam_mid', (0.225, 0, 0.65), (0.005, 0.012, 0.30),
        MAT_LEATHER, body_emp, bevel_width=0.002)

# Apron metal scale plates — 2 small flattened squares on the chest panel.
# Marked _detail so they don't get individual ink lines (they read as
# raised studs on the apron, not separate parts).
add_box('Apron_detail_plate_a', (0.225, -0.08, 0.86), (0.02, 0.07, 0.08),
        MAT_PAULDRON, body_emp, bevel_width=0.005)
add_box('Apron_detail_plate_b', (0.225,  0.08, 0.86), (0.02, 0.07, 0.08),
        MAT_PAULDRON, body_emp, bevel_width=0.005)

# Belt — leather strip at waist.
add_box('Belt', (0, 0, 0.55), (0.40, 0.34, 0.04), MAT_LEATHER, body_emp,
        bevel_width=0.008)
# Sash — green wrap around waist (concept shows it tied off at front).
add_soft_box('Sash', (0, 0, 0.50), (0.42, 0.36, 0.10), MAT_SASH, body_emp)

# Pouches — 2 small pouches hanging from belt.
add_soft_box('Pouch_R', (0.06, 0.18, 0.45), (0.10, 0.06, 0.10), MAT_LEATHER, body_emp)
add_soft_box('Pouch_L', (0.06, -0.16, 0.46), (0.08, 0.05, 0.08), MAT_LEATHER, body_emp)

# Tunic skirt — green skirt visible below the apron between vest skirt and trousers.
add_soft_box('Tunic_Skirt', (0, 0, 0.40), (0.38, 0.32, 0.14), MAT_TUNIC, body_emp)

# ---------------------------------------------------------------------------
# 5. Pauldrons — defining silhouette feature
# ---------------------------------------------------------------------------

# Hod's shoulder armor — flattened spheres for the main pauldron volume,
# plus 3 small _detail scale-bumps per side that read as overlapping plate
# scales. The bumps share the pauldron material so painted shading colors
# them the same; only the cel banding from each bump's own normal field
# differentiates them visually. No outlines on the bumps.
add_sphere('Pauldron_L', (0, -0.22, 0.99), 0.10, MAT_PAULDRON, arm_l_emp,
           segments=12, rings=8, scale=(1.2, 1.0, 0.6))
add_sphere('Pauldron_L_detail_a', (0, -0.28, 1.02), 0.040, MAT_PAULDRON, arm_l_emp,
           segments=8, rings=6, scale=(0.8, 1.0, 0.5))
add_sphere('Pauldron_L_detail_b', (0, -0.20, 1.04), 0.040, MAT_PAULDRON, arm_l_emp,
           segments=8, rings=6, scale=(0.8, 1.0, 0.5))
add_sphere('Pauldron_L_detail_c', (0, -0.12, 1.02), 0.040, MAT_PAULDRON, arm_l_emp,
           segments=8, rings=6, scale=(0.8, 1.0, 0.5))

add_sphere('Pauldron_R', (0,  0.22, 0.99), 0.10, MAT_PAULDRON, arm_r_emp,
           segments=12, rings=8, scale=(1.2, 1.0, 0.6))
add_sphere('Pauldron_R_detail_a', (0,  0.28, 1.02), 0.040, MAT_PAULDRON, arm_r_emp,
           segments=8, rings=6, scale=(0.8, 1.0, 0.5))
add_sphere('Pauldron_R_detail_b', (0,  0.20, 1.04), 0.040, MAT_PAULDRON, arm_r_emp,
           segments=8, rings=6, scale=(0.8, 1.0, 0.5))
add_sphere('Pauldron_R_detail_c', (0,  0.12, 1.02), 0.040, MAT_PAULDRON, arm_r_emp,
           segments=8, rings=6, scale=(0.8, 1.0, 0.5))

# ---------------------------------------------------------------------------
# 6. Legs — short, stocky cylinders + chunky leather boots
# ---------------------------------------------------------------------------

# Stocky leg trousers — slightly shorter and thicker than Eldra's.
add_cylinder('Trousers_L', (0, -0.10, 0.30), 0.10, 0.45, MAT_TUNIC, leg_l_emp, vertices=10)
add_cylinder('Trousers_R', (0,  0.10, 0.30), 0.10, 0.45, MAT_TUNIC, leg_r_emp, vertices=10)

# Boots — chunky leather, larger than Eldra's bare feet.
add_soft_box('Boot_L', (0.04, -0.10, 0.07), (0.20, 0.14, 0.10), MAT_LEATHER, leg_l_emp)
add_soft_box('Boot_R', (0.04,  0.10, 0.07), (0.20, 0.14, 0.10), MAT_LEATHER, leg_r_emp)

# ---------------------------------------------------------------------------
# 7. Head — bald, headband, pointed ears, big beard
# ---------------------------------------------------------------------------

# Head — bigger than Eldra's (radius 0.20) since Hod is stockier.
add_sphere('Head_Mesh', (0, 0, 1.16), 0.20, MAT_SKIN, head_emp,
           segments=14, rings=10, scale=(1.05, 1.0, 0.95))

# Headband — thin green band wrapping around the head above the brows.
add_cylinder('Headband', (0, 0, 1.22), 0.21, 0.05, MAT_HEADBAND, head_emp,
             vertices=14, rot=(0, 0, 0))

# Pointed ears — slightly elf-like cones angling outward from the sides
# of the head. Subtle but defining for the silhouette.
add_cone('Ear_L', (0, -0.20, 1.18), radius_base=0.04, radius_tip=0.01,
         height=0.08, mat=MAT_SKIN, parent=head_emp, vertices=6,
         rot=(math.radians(-90), math.radians(0), math.radians(20)))
add_cone('Ear_R', (0,  0.20, 1.18), radius_base=0.04, radius_tip=0.01,
         height=0.08, mat=MAT_SKIN, parent=head_emp, vertices=6,
         rot=(math.radians(90), math.radians(0), math.radians(-20)))

# Nose — bulbous, on the front of the face.
add_sphere('Nose', (0.18, 0, 1.10), 0.045, MAT_SKIN, head_emp, segments=8, rings=6)

# Eyes — small dark slashes (boxes flatter than spheres for cel-art read).
# Pushed forward (x 0.176 → 0.221) so they protrude past the head sphere's
# front (radius 0.20) instead of being buried inside it.
add_box('Eye_L', (0.221, -0.07, 1.16), (0.020, 0.030, 0.012), MAT_EYE, head_emp,
        bevel_width=0.003)
add_box('Eye_R', (0.221,  0.07, 1.16), (0.020, 0.030, 0.012), MAT_EYE, head_emp,
        bevel_width=0.003)

# Bushy gray-brown brows — single tuft per side.
# Position pushed forward (x 0.175 → 0.221) so they sit on the face surface
# rather than embedded behind it.
add_box('Brow_L', (0.221, -0.07, 1.20), (0.030, 0.060, 0.025), MAT_BROW, head_emp,
        bevel_width=0.008, rot=(0, math.radians(8), 0))
add_box('Brow_R', (0.221,  0.07, 1.20), (0.030, 0.060, 0.025), MAT_BROW, head_emp,
        bevel_width=0.008, rot=(0, math.radians(8), 0))

# ---- BEARD — single big mass + ruffle bumps for fluff texture ----
# The main mass carries the silhouette outline. Ruffle bumps (small
# overlapping spheres named *_ruffle_*) add surface variation that the
# painted vertex-color shading can pick up as cel-banded fluff, but the
# outline pass skips them — keeps the silhouette clean.
add_sphere('Beard_Mass', (0.28, 0, 0.86), 0.14, MAT_BEARD, head_emp,
           segments=14, rings=10, scale=(0.6, 1.3, 1.7))
# Chin pad bridges chin to beard mass.
add_box('Chin_Pad', (0.22, 0, 1.04), (0.05, 0.16, 0.05), MAT_BEARD, head_emp,
        bevel_width=0.008)

# Beard strands — 10 tapered cones flowing down from the chin (variant C
# from the A/B/C/D exploration). Hod's beard is bushier than Eldra's so
# we use slightly thicker bases + a wider spread. `_ruffle_strand_` in
# the name keeps the outline pass skipping them.
#
# rot=(180°, 0, 0) flips the cone tip from +Z to -Z (helper's _xform_rot
# remaps to Blender Y-axis).
_BEARD_STRAND_DOWN = (math.radians(180), 0, 0)
_beard_strands = [
    # (name, auth_x, auth_y, center_z, height, base_r, tip_r)
    ('Beard_ruffle_strand_a', 0.32, -0.10, 0.80, 0.30, 0.040, 0.010),
    ('Beard_ruffle_strand_b', 0.34, -0.05, 0.78, 0.36, 0.038, 0.008),
    ('Beard_ruffle_strand_c', 0.36,  0.00, 0.76, 0.40, 0.040, 0.008),
    ('Beard_ruffle_strand_d', 0.34,  0.05, 0.78, 0.36, 0.038, 0.008),
    ('Beard_ruffle_strand_e', 0.32,  0.10, 0.80, 0.30, 0.040, 0.010),
    ('Beard_ruffle_strand_f', 0.34, -0.07, 0.65, 0.30, 0.030, 0.008),
    ('Beard_ruffle_strand_g', 0.34,  0.00, 0.62, 0.34, 0.030, 0.008),
    ('Beard_ruffle_strand_h', 0.34,  0.07, 0.65, 0.30, 0.030, 0.008),
    ('Beard_ruffle_strand_i', 0.36,  0.00, 0.50, 0.26, 0.024, 0.005),
    ('Beard_ruffle_strand_j', 0.30, -0.03, 0.55, 0.22, 0.020, 0.005),
]
for _nm, _x, _y, _cz, _h, _br, _tr in _beard_strands:
    add_cone(_nm, (_x, _y, _cz), _br, _tr, _h, MAT_BEARD, head_emp,
             vertices=6, rot=_BEARD_STRAND_DOWN)

# Mustache — small bumps under nose, named as ruffle so they read as
# fluffy mustache hair without their own ink lines.
add_sphere('Mustache_ruffle_L', (0.23, -0.05, 1.07), 0.030, MAT_BEARD, head_emp, segments=8, rings=6)
add_sphere('Mustache_ruffle_R', (0.23,  0.05, 1.07), 0.030, MAT_BEARD, head_emp, segments=8, rings=6)

# ---------------------------------------------------------------------------
# 8. Arms — sleeves + cuffs + hands (same recipe as Eldra)
# ---------------------------------------------------------------------------

add_soft_box('Sleeve_L', (0, -0.27, 0.80), (0.14, 0.14, 0.30), MAT_TUNIC, arm_l_emp)
add_box('Cuff_L', (0, -0.27, 0.65), (0.12, 0.12, 0.04), MAT_LEATHER, arm_l_emp,
        bevel_width=0.008)
add_sphere('Hand_L', (0, -0.27, 0.60), 0.06, MAT_SKIN, arm_l_emp, segments=10, rings=8)

add_soft_box('Sleeve_R', (0,  0.27, 0.80), (0.14, 0.14, 0.30), MAT_TUNIC, arm_r_emp)
add_box('Cuff_R', (0,  0.27, 0.65), (0.12, 0.12, 0.04), MAT_LEATHER, arm_r_emp,
        bevel_width=0.008)
add_sphere('Hand_R', (0,  0.27, 0.60), 0.06, MAT_SKIN, arm_r_emp, segments=10, rings=8)

# ---------------------------------------------------------------------------
# 9. Hammer — held in right hand, silhouette feature for the smith identity
# ---------------------------------------------------------------------------

# Wooden haft (long brown cylinder).
add_cylinder('Hammer_Haft', (0.16, 0.30, 0.50), 0.025, 0.46, MAT_HAMMER_W, arm_r_emp,
             vertices=8, rot=(0, math.radians(0), 0))
# Pewter head — chunky cylinder at the top of the haft.
add_cylinder('Hammer_Head', (0.16, 0.30, 0.78), 0.06, 0.10, MAT_HAMMER_M, arm_r_emp,
             vertices=8, rot=(0, math.radians(90), 0))

# ---------------------------------------------------------------------------
# 10. Export
# ---------------------------------------------------------------------------

PROJECT_ROOT = os.environ.get('GJ26_PROJECT_ROOT',
                              os.path.abspath(os.path.dirname(__file__) + '/..'))
out_path = os.path.join(PROJECT_ROOT, 'models', 'npc_hod_v3.glb')
export_glb(root, out_path)

mesh_count = sum(1 for o in bpy.data.objects if o.type == 'MESH'
                 and o.name.startswith(PREFIXES))
print(f"\n=== Exported {out_path} ({mesh_count} meshes) ===")
for name in ('Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R'):
    o = bpy.data.objects.get(name)
    if o:
        print(f"  {name} — {len(o.children)} direct children")
