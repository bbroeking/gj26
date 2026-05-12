"""Rebuild Burrow Boar as `models/burrow_boar_v3.glb` — painted-render-tuned.

From `docs/concept-art/burrow-boar.png`:
  - Big tan/cream boar body
  - Dark green mossy ridge running along the back (silhouette feature)
  - White curving tusks
  - Red glowing eyes (angry)
  - Brown leather barding/saddle armor on the back
  - Darker brown legs and hooves
  - Small curly tail

First quadruped using the v4 recipe — uses the standard Body / Head /
Tail / Leg_FL / Leg_FR / Leg_BL / Leg_BR rig that the engine's
animateQuadruped expects (see characters.js + main.js).

Run:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
      --python scripts/rebuild_burrow_boar_v3_painted.py
"""

import sys, os, math
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

import bpy
from _painted_build_lib import (
    make_material, add_box, add_soft_box, add_sphere, add_cylinder,
    add_cone, add_empty, wipe_by_prefix, export_glb,
)

PREFIXES = (
    'BurrowBoar', 'BoarRoot', 'Boar',
    'Body', 'Head', 'Tail', 'Leg_',
    'Snout', 'Tusk_', 'Eye_', 'Ear_', 'Hoof_', 'Mane',
    'Saddle', 'Strap', 'Moss',
)
wipe_by_prefix(PREFIXES)

MAT_HIDE      = make_material('Boar_Hide',     '#c8a878', roughness=0.85)  # tan body
MAT_BELLY     = make_material('Boar_Belly',    '#dcb888', roughness=0.85)  # lighter belly
MAT_LEG       = make_material('Boar_Leg',      '#5c3818', roughness=0.85)  # dark brown legs
MAT_HOOF      = make_material('Boar_Hoof',     '#1c1208', roughness=0.85)  # near-black hooves
MAT_MOSS      = make_material('Boar_Moss',     '#3a5028', roughness=0.92)  # dark green ridge
MAT_MOSS_LT   = make_material('Boar_MossLight','#688038', roughness=0.92)
MAT_TUSK      = make_material('Boar_Tusk',     '#f0e8c8', roughness=0.55)
MAT_SNOUT     = make_material('Boar_Snout',    '#8c6048', roughness=0.85)  # darker pink/brown snout
MAT_EYE       = make_material('Boar_Eye',      '#c83020', roughness=0.30,
                              emissive_hex='#dc4030', emission_strength=1.5)  # red glow
MAT_LEATHER   = make_material('Boar_Leather',  '#4a3018', roughness=0.85)
MAT_LINE      = make_material('Boar_Line',     '#1a0e08', roughness=0.85)

# ---------------------------------------------------------------------------
# Quadruped rig — Body, Head, Tail, four legs (FL/FR/BL/BR)
# ---------------------------------------------------------------------------
# Authoring frame: face on +X. Boar is ~0.7m tall at shoulders, ~1.2m long.
# Body center at (0, 0, 0.45). Head out front and slightly up.
Z_BODY = 0.45
Z_LEG  = 0.40
Z_HEAD = 0.50

root      = add_empty('BoarRoot', (0, 0, 0))
body_emp  = add_empty('Body',   (0,    0,    Z_BODY),  parent=root)
head_emp  = add_empty('Head',   (0.45, 0,    Z_HEAD),  parent=root)
tail_emp  = add_empty('Tail',   (-0.5, 0,    Z_BODY),  parent=root)
leg_fl    = add_empty('Leg_FL', (0.30, -0.18, Z_LEG),  parent=root)
leg_fr    = add_empty('Leg_FR', (0.30,  0.18, Z_LEG),  parent=root)
leg_bl    = add_empty('Leg_BL', (-0.30,-0.18, Z_LEG),  parent=root)
leg_br    = add_empty('Leg_BR', (-0.30, 0.18, Z_LEG),  parent=root)

# ---------------------------------------------------------------------------
# Body — soft-box barrel + lighter belly
# ---------------------------------------------------------------------------
add_soft_box('Body_Barrel', (0, 0, 0), (1.00, 0.50, 0.40), MAT_HIDE, body_emp)
# Belly panel — lighter underside.
add_soft_box('Body_Belly', (0, 0, -0.16), (0.90, 0.46, 0.10), MAT_BELLY, body_emp)

# Mossy ridge along the back — single big mass + leaf-shaped petals.
add_soft_box('Mane_Ridge', (0, 0, 0.25), (0.80, 0.18, 0.12), MAT_MOSS, body_emp)
# Mane leaves — tapered cones growing from the spine ridge.
# Each tuple: (x, y, z_base, height, base_r, tip_r, tilt_x_deg, tilt_y_deg, mat)
# Y > 0 tilts the leaf to the +Y side (right); X tilt leans it forward/back.
mane_leaves = [
    # Crown row — center spine, fan outward in alternating directions.
    (0.34,  0.00, 0.31, 0.13, 0.055, 0.005,  -8,   0,  MAT_MOSS),
    (0.26, -0.04, 0.31, 0.12, 0.050, 0.005,   6, -18,  MAT_MOSS_LT),
    (0.18,  0.04, 0.31, 0.14, 0.060, 0.005,  -4,  20,  MAT_MOSS),
    (0.10, -0.05, 0.31, 0.13, 0.055, 0.005,   8, -22,  MAT_MOSS_LT),
    (0.02,  0.05, 0.31, 0.14, 0.060, 0.005,  -6,  24,  MAT_MOSS),
    (-0.06, -0.04, 0.31, 0.12, 0.050, 0.005,  4, -18,  MAT_MOSS_LT),
    (-0.14,  0.04, 0.31, 0.13, 0.055, 0.005, -8,  20,  MAT_MOSS),
    (-0.22, -0.03, 0.31, 0.11, 0.045, 0.005,  6, -14,  MAT_MOSS_LT),
    (-0.30,  0.00, 0.31, 0.10, 0.045, 0.005, -4,   0,  MAT_MOSS),
    # Side leaves — flank the ridge, angle further outward.
    (0.22, -0.10, 0.27, 0.11, 0.045, 0.005,  10, -38,  MAT_MOSS_LT),
    (0.22,  0.10, 0.27, 0.11, 0.045, 0.005, -10,  38,  MAT_MOSS),
    (0.04, -0.10, 0.27, 0.12, 0.050, 0.005,   6, -42,  MAT_MOSS),
    (0.04,  0.10, 0.27, 0.12, 0.050, 0.005,  -6,  42,  MAT_MOSS_LT),
    (-0.18, -0.09, 0.27, 0.10, 0.040, 0.005,  4, -36,  MAT_MOSS_LT),
    (-0.18,  0.09, 0.27, 0.10, 0.040, 0.005, -4,  36,  MAT_MOSS),
]
for i, (x, y, z, h, rb, rt, rx_deg, ry_deg, mat) in enumerate(mane_leaves):
    # Place leaf so its base sits at z and tip extends upward + tilted.
    # add_cone places the cone centered on world_center; we want base near z,
    # so offset center by half-height along the cone's local up before tilt.
    add_cone(f'Mane_ruffle_leaf_{i}', (x, y, z + h * 0.45),
             radius_base=rb, radius_tip=rt, height=h,
             mat=mat, parent=body_emp, vertices=6,
             rot=(math.radians(rx_deg), math.radians(ry_deg), 0))

# Saddle/barding — leather strap across the back behind the mane.
add_soft_box('Saddle', (-0.28, 0, 0.22), (0.30, 0.42, 0.06), MAT_LEATHER, body_emp)
# Saddle strap — thin band wrapping the body.
add_box('Strap_detail', (-0.22, 0, 0), (0.04, 0.50, 0.42), MAT_LEATHER, body_emp,
        bevel_width=0.003)

# ---------------------------------------------------------------------------
# Head — broad skull + snout + tusks + eyes + ears
# ---------------------------------------------------------------------------
# Main head mass.
add_sphere('Head_Mesh', (0, 0, 0), 0.18, MAT_HIDE, head_emp,
           segments=14, rings=10, scale=(1.2, 1.0, 0.9))
# Snout (forward-projecting box).
add_soft_box('Snout', (0.16, 0, -0.04), (0.18, 0.18, 0.14), MAT_SNOUT, head_emp)
# Nostrils — _detail dots.
add_sphere('Snout_detail_nostril_L', (0.25, -0.04, -0.02), 0.012, MAT_LINE, head_emp,
           segments=6, rings=4)
add_sphere('Snout_detail_nostril_R', (0.25,  0.04, -0.02), 0.012, MAT_LINE, head_emp,
           segments=6, rings=4)

# Tusks — curving cones pointing up + outward from the snout.
add_cone('Tusk_L', (0.20, -0.10, 0.02), radius_base=0.025, radius_tip=0.005,
         height=0.12, mat=MAT_TUSK, parent=head_emp, vertices=6,
         rot=(math.radians(-30), math.radians(20), 0))
add_cone('Tusk_R', (0.20,  0.10, 0.02), radius_base=0.025, radius_tip=0.005,
         height=0.12, mat=MAT_TUSK, parent=head_emp, vertices=6,
         rot=(math.radians(30), math.radians(20), 0))

# Red glowing eyes.
add_sphere('Eye_L', (0.10, -0.10, 0.08), 0.020, MAT_EYE, head_emp,
           segments=8, rings=6)
add_sphere('Eye_R', (0.10,  0.10, 0.08), 0.020, MAT_EYE, head_emp,
           segments=8, rings=6)

# Ears — flat triangular flaps on top of head, _detail.
add_cone('Ear_L_detail', (-0.04, -0.16, 0.16), radius_base=0.05, radius_tip=0.005,
         height=0.10, mat=MAT_HIDE, parent=head_emp, vertices=6,
         rot=(math.radians(-30), 0, 0))
add_cone('Ear_R_detail', (-0.04,  0.16, 0.16), radius_base=0.05, radius_tip=0.005,
         height=0.10, mat=MAT_HIDE, parent=head_emp, vertices=6,
         rot=(math.radians(30), 0, 0))

# ---------------------------------------------------------------------------
# Legs — short cylinders + dark hooves
# ---------------------------------------------------------------------------
def build_leg(prefix, leg_emp):
    add_cylinder(f'{prefix}_Leg', (0, 0, -0.20), 0.06, 0.40, MAT_LEG, leg_emp,
                 vertices=10)
    add_soft_box(f'{prefix}_Hoof', (0, 0, -0.42), (0.10, 0.10, 0.06), MAT_HOOF, leg_emp)

build_leg('FL', leg_fl)
build_leg('FR', leg_fr)
build_leg('BL', leg_bl)
build_leg('BR', leg_br)

# ---------------------------------------------------------------------------
# Tail — small curly cone hanging from rear
# ---------------------------------------------------------------------------
add_cone('Tail_Mesh', (0, 0, 0.04), radius_base=0.04, radius_tip=0.012,
         height=0.16, mat=MAT_HIDE, parent=tail_emp, vertices=8,
         rot=(0, math.radians(60), 0))

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------
PROJECT_ROOT = os.environ.get('GJ26_PROJECT_ROOT',
                              os.path.abspath(os.path.dirname(__file__) + '/..'))
out_path = os.path.join(PROJECT_ROOT, 'models', 'burrow_boar_v3.glb')
export_glb(root, out_path)

mesh_count = sum(1 for o in bpy.data.objects if o.type == 'MESH'
                 and o.name.startswith(PREFIXES))
print(f"\n=== Exported {out_path} ({mesh_count} meshes) ===")
for name in ('Body', 'Head', 'Tail', 'Leg_FL', 'Leg_FR', 'Leg_BL', 'Leg_BR'):
    o = bpy.data.objects.get(name)
    if o:
        print(f"  {name} — {len(o.children)} direct children")
