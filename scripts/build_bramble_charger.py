"""Build bramble_charger.glb — black-bristled boar mid-charge."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, rig_biped, apply_bevel_remove_doubles, export_glb, quad_parent_for

reset_scene(cam_loc=(2.6, -2.6, 1.4), cam_target=(0, 0, 0.6))

CHARCOAL = (0.10, 0.09, 0.08)
DARKER_CH = (0.05, 0.05, 0.05)
BRAMBLE_GREEN = (0.30, 0.42, 0.20)
DARK_GREEN = (0.18, 0.30, 0.12)
TUSK_IVORY = (0.92, 0.85, 0.65)
AMBER = (0.95, 0.62, 0.18)
MUD = (0.18, 0.13, 0.08)

# Big charging boar body (lower / more horizontal stance)
make_cube('Body_torso', (0, 0, 0.55), (0.55, 0.85, 0.45), CHARCOAL)
make_cube('Body_back_ridge', (0, 0, 0.85), (0.50, 0.80, 0.10), DARKER_CH)
# Bramble crown growing through shoulders/neck
make_cube('Body_bramble_a', (0, -0.20, 0.95), (0.30, 0.20, 0.20), BRAMBLE_GREEN)
make_cube('Body_bramble_b', (-0.18, 0, 0.92), (0.18, 0.20, 0.16), DARK_GREEN)
make_cube('Body_bramble_c', (0.18, 0, 0.92), (0.18, 0.20, 0.16), DARK_GREEN)
# Mossy green saddle along spine
make_cube('Body_saddle', (0, 0.10, 0.92), (0.40, 0.40, 0.06), BRAMBLE_GREEN)

# Head (forward, charge angle)
make_cube('Head_skull', (0, -0.55, 0.55), (0.36, 0.28, 0.30), CHARCOAL)
make_cube('Head_snout', (0, -0.75, 0.45), (0.20, 0.18, 0.22), DARKER_CH)
# Two pale tusks
make_cube('Head_tusk_L', (-0.14, -0.82, 0.55), (0.05, 0.06, 0.20), TUSK_IVORY)
make_cube('Head_tusk_R', ( 0.14, -0.82, 0.55), (0.05, 0.06, 0.20), TUSK_IVORY)
# Glowing amber eyes (narrowed)
make_cube('Head_eye_L', (-0.10, -0.68, 0.68), (0.05, 0.04, 0.03), AMBER, AMBER, 2.0)
make_cube('Head_eye_R', ( 0.10, -0.68, 0.68), (0.05, 0.04, 0.03), AMBER, AMBER, 2.0)
# Ears flat back
make_cube('Head_ear_L', (-0.16, -0.40, 0.78), (0.08, 0.08, 0.10), DARKER_CH)
make_cube('Head_ear_R', ( 0.16, -0.40, 0.78), (0.08, 0.08, 0.10), DARKER_CH)

# Tail (small, kicked back behind)
make_cube('Tail', (0, 0.55, 0.70), (0.04, 0.12, 0.10), DARKER_CH)

# Front legs braced (forward, lower)
make_cube('Leg_FL', (-0.20, -0.32, 0.18), (0.16, 0.16, 0.34), DARKER_CH)
make_cube('Leg_FR', ( 0.20, -0.32, 0.18), (0.16, 0.16, 0.34), DARKER_CH)
# Rear legs kicked back (raised, behind)
make_cube('Leg_BL', (-0.20,  0.45, 0.30), (0.16, 0.16, 0.34), DARKER_CH)
make_cube('Leg_BR', ( 0.20,  0.45, 0.30), (0.16, 0.16, 0.34), DARKER_CH)
# Hooves
make_cube('Leg_FL_hoof', (-0.20, -0.32, 0.04), (0.18, 0.18, 0.06), MUD)
make_cube('Leg_FR_hoof', ( 0.20, -0.32, 0.04), (0.18, 0.18, 0.06), MUD)
make_cube('Leg_BL_hoof', (-0.20,  0.45, 0.16), (0.18, 0.18, 0.06), MUD)
make_cube('Leg_BR_hoof', ( 0.20,  0.45, 0.16), (0.18, 0.18, 0.06), MUD)

# Mud spray particles (4 small clumps near front hooves)
for i, (x, y) in enumerate([(-0.30, -0.45), (-0.15, -0.50), (0.20, -0.48), (0.32, -0.40)]):
    make_cube(f'Body_mud_{i}', (x, y, 0.06), (0.06, 0.05, 0.05), MUD)

quad_pivots = {
    'Body':  (0, 0, 0.50),
    'Head':  (0, -0.45, 0.55),
    'Tail':  (0, 0.50, 0.65),
    'Leg_FL':(-0.20, -0.32, 0.36),
    'Leg_FR':( 0.20, -0.32, 0.36),
    'Leg_BL':(-0.20,  0.45, 0.50),
    'Leg_BR':( 0.20,  0.45, 0.50),
}
root, empties, mesh_objs = rig_biped(quad_pivots, 'BrambleCharger_Root', quad_parent_for)
apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/bramble_charger.glb')
