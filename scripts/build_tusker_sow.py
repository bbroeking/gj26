"""Build tusker_sow.glb — massive matriarch boar with leaf-mantle."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, rig_biped, apply_bevel_remove_doubles, export_glb, quad_parent_for

reset_scene(cam_loc=(2.6, -2.6, 1.4), cam_target=(0, 0, 0.6))

DARK_BROWN = (0.28, 0.20, 0.14)
DARKER     = (0.18, 0.13, 0.10)
TUSK       = (0.92, 0.85, 0.65)
LEAF_GREEN = (0.30, 0.42, 0.20)
MUD_CHARCOAL = (0.18, 0.16, 0.12)
EYE = (0.04, 0.04, 0.04)

# Big boar body
make_cube('Body_torso', (0, 0, 0.65), (0.65, 0.95, 0.55), DARK_BROWN)
# Bristly back ridge
make_cube('Body_ridge', (0, 0, 0.95), (0.55, 0.85, 0.10), DARKER)
# Leaf-mantle along back
make_cube('Body_mantle_a', (-0.10, -0.15, 1.00), (0.30, 0.30, 0.10), LEAF_GREEN)
make_cube('Body_mantle_b', (0.05, 0.20, 1.00), (0.30, 0.35, 0.10), LEAF_GREEN)
# Wet reeds
make_cube('Body_reed', (0.14, 0.25, 1.05), (0.04, 0.20, 0.18), (0.62, 0.55, 0.30))
# Mud-caked belly
make_cube('Body_belly', (0, 0, 0.30), (0.55, 0.85, 0.18), MUD_CHARCOAL)

# Head (forward)
make_cube('Head_skull', (0, -0.65, 0.65), (0.40, 0.30, 0.34), DARK_BROWN)
make_cube('Head_snout', (0, -0.85, 0.55), (0.22, 0.20, 0.22), DARKER)
# Two huge tusks per side (4 total)
make_cube('Head_tusk_FL', (-0.16, -0.92, 0.62), (0.05, 0.06, 0.18), TUSK)
make_cube('Head_tusk_FR', ( 0.16, -0.92, 0.62), (0.05, 0.06, 0.18), TUSK)
make_cube('Head_tusk_BL', (-0.10, -0.95, 0.55), (0.04, 0.04, 0.12), TUSK)
make_cube('Head_tusk_BR', ( 0.10, -0.95, 0.55), (0.04, 0.04, 0.12), TUSK)
make_cube('Head_eye_L', (-0.10, -0.78, 0.78), (0.04, 0.04, 0.04), EYE)
make_cube('Head_eye_R', ( 0.10, -0.78, 0.78), (0.04, 0.04, 0.04), EYE)
# Ears
make_cube('Head_ear_L', (-0.18, -0.50, 0.82), (0.10, 0.08, 0.14), DARKER)
make_cube('Head_ear_R', ( 0.18, -0.50, 0.82), (0.10, 0.08, 0.14), DARKER)

# Tail (small)
make_cube('Tail', (0, 0.50, 0.85), (0.04, 0.10, 0.12), DARKER)

# Legs (4 stout legs planted)
make_cube('Leg_FL', (-0.22, -0.35, 0.20), (0.16, 0.16, 0.40), DARKER)
make_cube('Leg_FR', ( 0.22, -0.35, 0.20), (0.16, 0.16, 0.40), DARKER)
make_cube('Leg_BL', (-0.22,  0.45, 0.20), (0.16, 0.16, 0.40), DARKER)
make_cube('Leg_BR', ( 0.22,  0.45, 0.20), (0.16, 0.16, 0.40), DARKER)
# Hooves
make_cube('Leg_FL_hoof', (-0.22, -0.35, 0.04), (0.18, 0.18, 0.06), MUD_CHARCOAL)
make_cube('Leg_FR_hoof', ( 0.22, -0.35, 0.04), (0.18, 0.18, 0.06), MUD_CHARCOAL)
make_cube('Leg_BL_hoof', (-0.22,  0.45, 0.04), (0.18, 0.18, 0.06), MUD_CHARCOAL)
make_cube('Leg_BR_hoof', ( 0.22,  0.45, 0.04), (0.18, 0.18, 0.06), MUD_CHARCOAL)

quad_pivots = {
    'Body':  (0, 0, 0.55),
    'Head':  (0, -0.55, 0.65),
    'Tail':  (0, 0.50, 0.75),
    'Leg_FL':(-0.22, -0.35, 0.40),
    'Leg_FR':( 0.22, -0.35, 0.40),
    'Leg_BL':(-0.22,  0.45, 0.40),
    'Leg_BR':( 0.22,  0.45, 0.40),
}
root, empties, mesh_objs = rig_biped(quad_pivots, 'TuskerSow_Root', quad_parent_for)
apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/tusker_sow.glb')
