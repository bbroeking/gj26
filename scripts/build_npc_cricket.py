"""Build npc_cricket.glb — letter-carrier teen, mossy-green tunic, satchel."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, rig_biped, apply_bevel_remove_doubles, export_glb, biped_parent_for, BIPED_PIVOTS

reset_scene()

MOSS_GREEN = (0.36, 0.46, 0.24)
OAK_BROWN = (0.42, 0.30, 0.18)
STRAW_HAIR = (0.78, 0.65, 0.40)
MUD = (0.30, 0.22, 0.16)
SKIN = (0.95, 0.80, 0.65)
CREAM = (0.90, 0.84, 0.72)
DARK = (0.20, 0.16, 0.12)

# Thin teenage body
make_cube('Body_torso', (0, 0, 0.95), (0.36, 0.28, 0.55), MOSS_GREEN)
# Tunic belt
make_cube('Body_belt', (0, -0.15, 0.72), (0.36, 0.04, 0.06), OAK_BROWN)

# Head
make_cube('Head_skull', (0, 0, 1.45), (0.30, 0.28, 0.28), SKIN)
# Windblown straw hair
make_cube('Head_hair', (0, 0.10, 1.60), (0.34, 0.20, 0.20), STRAW_HAIR)
# Bangs (tousled)
make_cube('Head_bangs', (0, -0.13, 1.55), (0.28, 0.06, 0.10), STRAW_HAIR)
# Eyes
make_cube('Head_eye_L', (-0.07, -0.15, 1.45), (0.04, 0.04, 0.04), (0.08, 0.05, 0.04))
make_cube('Head_eye_R', ( 0.07, -0.15, 1.45), (0.04, 0.04, 0.04), (0.08, 0.05, 0.04))
# Freckles
make_cube('Head_freckle_L', (-0.08, -0.16, 1.40), (0.04, 0.02, 0.02), (0.78, 0.55, 0.35))
make_cube('Head_freckle_R', ( 0.08, -0.16, 1.40), (0.04, 0.02, 0.02), (0.78, 0.55, 0.35))
# Cricket on shoulder (tiny — small cube)
make_cube('Head_cricket', (0.18, -0.05, 1.30), (0.04, 0.06, 0.04), DARK)

# Arms (thin)
make_cube('Arm_L', (-0.26, -0.05, 1.10), (0.12, 0.14, 0.50), MOSS_GREEN)
make_cube('Arm_R', ( 0.26, -0.05, 1.10), (0.12, 0.14, 0.50), MOSS_GREEN)

# Legs (thin)
make_cube('Leg_L', (-0.10, 0, 0.32), (0.16, 0.18, 0.55), DARK)
make_cube('Leg_R', ( 0.10, 0, 0.32), (0.16, 0.18, 0.55), DARK)
# Muddy boots
make_cube('Leg_L_boot', (-0.10, -0.02, 0.04), (0.18, 0.24, 0.13), MUD)
make_cube('Leg_R_boot', ( 0.10, -0.02, 0.04), (0.18, 0.24, 0.13), MUD)

# Tall walking staff (right hand)
make_cube('Arm_R_staff', (0.40, -0.18, 1.25), (0.05, 0.05, 1.40), OAK_BROWN)

# Leather satchel of letters (crossbody)
make_cube('Body_satchel', (-0.20, 0.20, 0.78), (0.20, 0.14, 0.18), OAK_BROWN)
# Letters peeking out (cream)
make_cube('Body_letter_a', (-0.22, 0.20, 0.92), (0.10, 0.04, 0.06), CREAM)
make_cube('Body_letter_b', (-0.18, 0.20, 0.94), (0.08, 0.04, 0.06), CREAM)
# Strap
make_cube('Body_strap', (0, 0.06, 1.20), (0.30, 0.04, 0.05), OAK_BROWN)

root, empties, mesh_objs = rig_biped(BIPED_PIVOTS, 'Cricket_Root', biped_parent_for)
apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/npc_cricket.glb')
