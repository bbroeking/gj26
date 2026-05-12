"""Rebuild Maud Pennycress as `models/npc_maud_pennycress_v1.glb` — painted.

From `docs/concept-art/npc-maud-pennycress.png`:
  - Stocky dwarf-like cook with messy windswept silver-gray hair
  - Determined / slightly grumpy expression, big green eyes, thick brows
  - Cream apron with criss-cross laces over a forest-green tunic
  - Brown leather belt + small pouch + tiny lantern at hip
  - Holds a wooden rolling pin upright in her right hand
  - Brown boots, stocky proportions

Same v4 recipe as Eldra/Hod/Onywyn. Eyes/brows authored at x=0.221 from
the start (the buried-eye fix bakes in proactively).

Run:
  /Applications/Blender.app/Contents/MacOS/Blender --background \\
      --python scripts/rebuild_maud_pennycress_v1_painted.py
"""

import sys, os, math
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

import bpy
from _painted_build_lib import (
    make_material, add_box, add_soft_box, add_sphere, add_cylinder,
    add_cone, add_empty, wipe_by_prefix, export_glb,
)

PREFIXES = (
    'Maud', 'MaudRoot', 'Body', 'Head', 'Arm_', 'Leg_',
    'Hair', 'Eye_', 'Brow_', 'Nose', 'Mouth', 'Cheek',
    'Tunic', 'Apron', 'Belt', 'Pouch', 'Lantern', 'Sleeve_',
    'Cuff', 'Hand_', 'Skirt', 'Boot_', 'RollPin', 'Kettle',
    'Sash', 'Strap',
)
wipe_by_prefix(PREFIXES)

# ---------------------------------------------------------------------------
# Materials — pulled from concept art
# ---------------------------------------------------------------------------

MAT_SKIN     = make_material('Maud_Skin',     '#f0c498', roughness=0.78)
MAT_HAIR     = make_material('Maud_Hair',     '#a89878', roughness=0.92)  # silver-tan
MAT_EYE      = make_material('Maud_Eye',      '#3a5828', roughness=0.40)  # vivid green
MAT_TUNIC    = make_material('Maud_Tunic',    '#5a7838', roughness=0.85)  # forest green
MAT_APRON    = make_material('Maud_Apron',    '#dac8a0', roughness=0.85)  # cream apron
MAT_LEATHER  = make_material('Maud_Leather',  '#4a3018', roughness=0.85)  # belt / boots
MAT_BOOT     = make_material('Maud_Boot',     '#5a3820', roughness=0.82)
MAT_WOOD     = make_material('Maud_Wood',     '#b08858', roughness=0.85)  # rolling pin
MAT_KETTLE   = make_material('Maud_Kettle',   '#383838', roughness=0.55)
MAT_LINE     = make_material('Maud_Line',     '#1a0e08', roughness=0.85)

MAT_BROW = MAT_LINE
MAT_NOSE = MAT_SKIN

# ---------------------------------------------------------------------------
# Rig — same 6-empty layout. Maud is stocky like Hod (slightly shorter +
# wider torso) so we keep the same Z's but build wider primitives.
# ---------------------------------------------------------------------------

Z_HIP, Z_SHOULDER, Z_NECK = 0.55, 0.95, 1.00

root      = add_empty('MaudRoot', (0, 0, 0))
body_emp  = add_empty('Body',  (0,    0,    Z_HIP),     parent=root)
head_emp  = add_empty('Head',  (0,    0,    Z_NECK),    parent=root)
arm_l_emp = add_empty('Arm_L', (0,   -0.18, Z_SHOULDER), parent=root)
arm_r_emp = add_empty('Arm_R', (0,    0.18, Z_SHOULDER), parent=root)
leg_l_emp = add_empty('Leg_L', (0,   -0.10, Z_HIP),      parent=root)
leg_r_emp = add_empty('Leg_R', (0,    0.10, Z_HIP),      parent=root)

# ---------------------------------------------------------------------------
# Body — green tunic + cream apron over front + green skirt
# ---------------------------------------------------------------------------

# Green tunic torso (the under-layer)
add_soft_box('Tunic_Body', (0, 0, 0.78), (0.36, 0.32, 0.40), MAT_TUNIC, body_emp)
# Cream apron — over the front of the tunic, narrower than the tunic so
# the green peeks out at the sides.
add_soft_box('Apron_Body', (0.04, 0, 0.74), (0.32, 0.22, 0.42), MAT_APRON, body_emp)
# Apron criss-cross laces — two thin strips X-ed across the chest.
add_box('Apron_detail_lace_a', (0.06, 0, 0.96), (0.04, 0.16, 0.012), MAT_LEATHER, body_emp,
        bevel_width=0.002, rot=(0, 0, math.radians(20)))
add_box('Apron_detail_lace_b', (0.06, 0, 0.96), (0.04, 0.16, 0.012), MAT_LEATHER, body_emp,
        bevel_width=0.002, rot=(0, 0, math.radians(-20)))
# Apron tie at waist
add_box('Apron_detail_tie', (0.06, 0, 0.58), (0.04, 0.20, 0.04), MAT_LEATHER, body_emp,
        bevel_width=0.005)
# Belt under the apron
add_box('Belt', (0, 0, 0.55), (0.36, 0.30, 0.04), MAT_LEATHER, body_emp)
# Pouch at hip
add_box('Pouch_R', (0.04, 0.18, 0.50), (0.10, 0.06, 0.10), MAT_LEATHER, body_emp,
        bevel_width=0.005)
# Tiny lantern hanging beside pouch (silhouette feature from concept)
add_cylinder('Lantern_Body', (0.06, 0.20, 0.42), 0.04, 0.06, MAT_KETTLE, body_emp,
             vertices=6)
add_cylinder('Lantern_Cap',  (0.06, 0.20, 0.46), 0.035, 0.02, MAT_LEATHER, body_emp,
             vertices=6)
# Skirt — green, soft-flared (same as tunic)
add_soft_box('Skirt', (0, 0, 0.42), (0.34, 0.30, 0.16), MAT_TUNIC, body_emp)
# Neck cylinder
add_cylinder('Neck', (0, 0, 1.02), 0.08, 0.10, MAT_SKIN, body_emp, vertices=10)

# ---------------------------------------------------------------------------
# Legs — short stocky pants (under the skirt) + boots
# ---------------------------------------------------------------------------

add_cylinder('Pants_L', (0, -0.10, 0.30), 0.08, 0.40, MAT_TUNIC, leg_l_emp, vertices=10)
add_cylinder('Pants_R', (0,  0.10, 0.30), 0.08, 0.40, MAT_TUNIC, leg_r_emp, vertices=10)
add_soft_box('Boot_L', (0.04, -0.10, 0.07), (0.20, 0.12, 0.10), MAT_BOOT, leg_l_emp)
add_soft_box('Boot_R', (0.04,  0.10, 0.07), (0.20, 0.12, 0.10), MAT_BOOT, leg_r_emp)

# ---------------------------------------------------------------------------
# Head — face + WILD windswept silver-gray hair
# ---------------------------------------------------------------------------

# Head sphere (size between Eldra's 0.18 and Hod's 0.20 — Maud is chunky)
add_sphere('Head_Mesh', (0, 0, 1.16), 0.19, MAT_SKIN, head_emp,
           segments=14, rings=10, scale=(1.05, 1.05, 0.95))

# Hair — main wide windswept dome on top + a topknot/poof + multiple ruffle
# bumps for the wild messy texture.
add_sphere('Hair_Dome', (-0.04, 0, 1.30), 0.22, MAT_HAIR, head_emp,
           segments=14, rings=10, scale=(1.05, 1.10, 1.0))
# Top poof / messy bun pulled up at back
add_sphere('Hair_Poof', (-0.10, 0, 1.50), 0.10, MAT_HAIR, head_emp,
           segments=10, rings=8, scale=(1.0, 1.2, 1.4))
# Wild side wisps blowing outward — silhouette feature
add_sphere('Hair_Wisp_L', (-0.04, -0.22, 1.30), 0.09, MAT_HAIR, head_emp,
           segments=10, rings=8)
add_sphere('Hair_Wisp_R', (-0.04,  0.22, 1.30), 0.09, MAT_HAIR, head_emp,
           segments=10, rings=8)
# Ruffle bumps — little spheres distributed over the dome for messy texture
add_sphere('Hair_ruffle_a', (0.06, -0.10, 1.42), 0.06, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_ruffle_b', (0.06,  0.10, 1.42), 0.06, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_ruffle_c', (-0.16, -0.06, 1.40), 0.05, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_ruffle_d', (-0.16,  0.06, 1.40), 0.05, MAT_HAIR, head_emp, segments=8, rings=6)
add_sphere('Hair_ruffle_e', (-0.04,  0.00, 1.50), 0.05, MAT_HAIR, head_emp, segments=8, rings=6)
# Forehead bangs — small fringe poking down between the brows and the dome
add_box('Hair_Bangs', (0.221, 0, 1.28), (0.04, 0.18, 0.05), MAT_HAIR, head_emp,
        bevel_width=0.005)
# Side strands flowing down past the cheeks
add_box('Hair_Side_L', (0.10, -0.20, 1.04), (0.06, 0.04, 0.18), MAT_HAIR, head_emp,
        bevel_width=0.005)
add_box('Hair_Side_R', (0.10,  0.20, 1.04), (0.06, 0.04, 0.18), MAT_HAIR, head_emp,
        bevel_width=0.005)

# Nose — small bulb in front of face
add_sphere('Nose', (0.20, 0, 1.13), 0.035, MAT_NOSE, head_emp, segments=8, rings=6)

# Eyes — bigger than Eldra/Hod's slashes, with a green tint to match the
# concept. Positioned forward (x=0.221) so they protrude past the head
# surface (radius 0.19).
add_sphere('Eye_L', (0.221, -0.07, 1.18), 0.024, MAT_EYE, head_emp,
           segments=8, rings=6)
add_sphere('Eye_R', (0.221,  0.07, 1.18), 0.024, MAT_EYE, head_emp,
           segments=8, rings=6)
# Tiny dark pupil dots
add_sphere('Eye_L_detail_pupil', (0.235, -0.07, 1.18), 0.010, MAT_LINE, head_emp,
           segments=6, rings=4)
add_sphere('Eye_R_detail_pupil', (0.235,  0.07, 1.18), 0.010, MAT_LINE, head_emp,
           segments=6, rings=4)

# Thick angled brows — Maud has a fierce expression. Outer ends sit higher
# than inner ends so the brows angle inward (concerned/grumpy look).
add_box('Brow_L', (0.221, -0.07, 1.24), (0.022, 0.060, 0.018), MAT_BROW, head_emp,
        bevel_width=0.003, rot=(0, 0, math.radians(-12)))
add_box('Brow_R', (0.221,  0.07, 1.24), (0.022, 0.060, 0.018), MAT_BROW, head_emp,
        bevel_width=0.003, rot=(0, 0, math.radians(12)))

# Small mouth line (slight frown — flat horizontal box)
add_box('Mouth_line', (0.221, 0, 1.06), (0.012, 0.040, 0.012), MAT_LINE, head_emp,
        bevel_width=0.002)

# ---------------------------------------------------------------------------
# Arms — green sleeves, cream cuffs, hands
# ---------------------------------------------------------------------------

add_soft_box('Sleeve_L', (0, -0.24, 0.80), (0.12, 0.12, 0.30), MAT_TUNIC, arm_l_emp)
add_box('Cuff_L', (0, -0.24, 0.65), (0.10, 0.10, 0.04), MAT_APRON, arm_l_emp)
add_sphere('Hand_L', (0, -0.24, 0.60), 0.05, MAT_SKIN, arm_l_emp, segments=10, rings=8)

add_soft_box('Sleeve_R', (0,  0.24, 0.80), (0.12, 0.12, 0.30), MAT_TUNIC, arm_r_emp)
add_box('Cuff_R', (0,  0.24, 0.65), (0.10, 0.10, 0.04), MAT_APRON, arm_r_emp)
add_sphere('Hand_R', (0,  0.24, 0.60), 0.05, MAT_SKIN, arm_r_emp, segments=10, rings=8)

# ---------------------------------------------------------------------------
# Rolling pin — held upright in the LEFT hand (concept shows it on her right
# from her POV, which is camera-left). The pin: thicker handle in the
# middle, thinner end caps.
# ---------------------------------------------------------------------------

# Vertical wooden cylinder running from hand level past head height
add_cylinder('RollPin_Body', (0.18, -0.26, 1.00), 0.040, 0.50, MAT_WOOD, arm_l_emp,
             vertices=10)
# Top end-cap (slightly fatter)
add_cylinder('RollPin_Cap_Top', (0.18, -0.26, 1.27), 0.045, 0.06, MAT_WOOD, arm_l_emp,
             vertices=10)
# Bottom end-cap
add_cylinder('RollPin_Cap_Bot', (0.18, -0.26, 0.73), 0.045, 0.06, MAT_WOOD, arm_l_emp,
             vertices=10)
# Top handle peg (the protruding thin handle)
add_cylinder('RollPin_Handle', (0.18, -0.26, 1.36), 0.018, 0.10, MAT_WOOD, arm_l_emp,
             vertices=8)

# ---------------------------------------------------------------------------
# Small kettle / tankard in the RIGHT hand (concept's small object on the
# right). Simple cylinder + handle hint.
# ---------------------------------------------------------------------------

add_cylinder('Kettle_Body', (0, 0.30, 0.60), 0.050, 0.10, MAT_KETTLE, arm_r_emp,
             vertices=10)
add_cylinder('Kettle_Spout', (0.06, 0.32, 0.62), 0.012, 0.06, MAT_KETTLE, arm_r_emp,
             vertices=6, rot=(0, math.radians(60), 0))

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

PROJECT_ROOT = os.environ.get('GJ26_PROJECT_ROOT',
                              os.path.abspath(os.path.dirname(__file__) + '/..'))
out_path = os.path.join(PROJECT_ROOT, 'models', 'npc_maud_pennycress_v1.glb')
export_glb(root, out_path)

mesh_count = sum(1 for o in bpy.data.objects if o.type == 'MESH'
                 and o.name.startswith(PREFIXES))
print(f"\n=== Exported {out_path} ({mesh_count} meshes) ===")
for name in ('Body', 'Head', 'Arm_L', 'Arm_R', 'Leg_L', 'Leg_R'):
    o = bpy.data.objects.get(name)
    if o:
        print(f"  {name} — {len(o.children)} direct children")
