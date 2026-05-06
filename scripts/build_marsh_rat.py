"""Build marsh_rat.glb — wet-furred bog rat."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, rig_biped, apply_bevel_remove_doubles, export_glb, quad_parent_for, QUAD_PIVOTS

reset_scene(cam_loc=(2.2, -2.2, 1.0), cam_target=(0, 0, 0.4))

SLATE  = (0.32, 0.34, 0.38)
ALGAE  = (0.32, 0.42, 0.20)
PINK_TAIL = (0.78, 0.55, 0.55)
ORANGE_TOOTH = (0.86, 0.55, 0.20)
DARK = (0.18, 0.16, 0.12)
PAW_BROWN = (0.32, 0.22, 0.16)

# Body — chunky low quadruped
make_cube('Body_torso', (0, 0.05, 0.45), (0.34, 0.50, 0.28), SLATE)
make_cube('Body_algae', (0, 0.05, 0.59), (0.30, 0.46, 0.04), ALGAE)
make_cube('Body_underbelly', (0, 0.10, 0.34), (0.26, 0.40, 0.04), (0.42, 0.38, 0.30))

# Head (forward)
make_cube('Head_skull', (0, -0.40, 0.48), (0.22, 0.20, 0.20), SLATE)
make_cube('Head_snout', (0, -0.55, 0.42), (0.10, 0.14, 0.10), (0.55, 0.42, 0.32))
make_cube('Head_eye_L', (-0.06, -0.50, 0.52), (0.04, 0.04, 0.04), (0.04, 0.04, 0.04))
make_cube('Head_eye_R', ( 0.06, -0.50, 0.52), (0.04, 0.04, 0.04), (0.04, 0.04, 0.04))
make_cube('Head_tooth', (0, -0.62, 0.38), (0.05, 0.04, 0.06), ORANGE_TOOTH)
# Torn ear (one side)
make_cube('Head_ear_L', (-0.10, -0.42, 0.62), (0.06, 0.04, 0.10), (0.55, 0.42, 0.32))
# Whiskers (hint via thin cubes)
make_cube('Head_whiskers', (0, -0.62, 0.46), (0.18, 0.04, 0.02), (0.92, 0.86, 0.72))

# Tail (long, pink scaled)
make_cube('Tail', (0, 0.55, 0.42), (0.05, 0.40, 0.05), PINK_TAIL)

# Legs (4 short paws)
make_cube('Leg_FL', (-0.14, -0.30, 0.20), (0.10, 0.10, 0.20), DARK)
make_cube('Leg_FR', ( 0.14, -0.30, 0.20), (0.10, 0.10, 0.20), DARK)
make_cube('Leg_BL', (-0.14,  0.35, 0.20), (0.10, 0.10, 0.20), DARK)
make_cube('Leg_BR', ( 0.14,  0.35, 0.20), (0.10, 0.10, 0.20), DARK)
make_cube('Leg_FL_paw', (-0.14, -0.30, 0.06), (0.12, 0.14, 0.06), PAW_BROWN)
make_cube('Leg_FR_paw', ( 0.14, -0.30, 0.06), (0.12, 0.14, 0.06), PAW_BROWN)
make_cube('Leg_BL_paw', (-0.14,  0.35, 0.06), (0.12, 0.14, 0.06), PAW_BROWN)
make_cube('Leg_BR_paw', ( 0.14,  0.35, 0.06), (0.12, 0.14, 0.06), PAW_BROWN)

quad_pivots = {
    'Body':  (0, 0, 0.40),
    'Head':  (0, -0.40, 0.48),
    'Tail':  (0, 0.30, 0.42),
    'Leg_FL':(-0.14, -0.30, 0.30),
    'Leg_FR':( 0.14, -0.30, 0.30),
    'Leg_BL':(-0.14,  0.35, 0.30),
    'Leg_BR':( 0.14,  0.35, 0.30),
}

root, empties, mesh_objs = rig_biped(quad_pivots, 'MarshRat_Root', quad_parent_for)
apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/marsh_rat.glb')
