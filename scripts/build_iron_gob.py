"""Build iron_gob.glb — armored goblin variant."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, rig_biped, apply_bevel_remove_doubles, export_glb, biped_parent_for, BIPED_PIVOTS

reset_scene()

OLIVE_SKIN = (0.42, 0.50, 0.30)
IRON       = (0.32, 0.34, 0.38)
DARK_IRON  = (0.20, 0.22, 0.26)
SOOT       = (0.12, 0.10, 0.10)
EMBER_RED  = (0.65, 0.18, 0.10)
LEATHER    = (0.36, 0.26, 0.18)
BRASS      = (0.78, 0.58, 0.18)

# Body — chunky goblin, heavier than normal
make_cube('Body_torso', (0, 0, 0.85), (0.50, 0.40, 0.55), OLIVE_SKIN)
# Riveted breastplate
make_cube('Body_plate', (0, -0.18, 0.95), (0.48, 0.10, 0.48), IRON)
make_cube('Body_plate_dark', (0, -0.16, 0.85), (0.42, 0.06, 0.20), DARK_IRON)
# Asymmetric pauldron (right shoulder only)
make_cube('Body_pauldron_R', (0.30, 0, 1.20), (0.20, 0.20, 0.18), IRON)
# Belt
make_cube('Body_belt', (0, -0.18, 0.65), (0.50, 0.05, 0.10), LEATHER)

# Head + helm
make_cube('Head_skull', (0, 0, 1.40), (0.34, 0.32, 0.30), OLIVE_SKIN)
make_cube('Head_helmet', (0, 0, 1.50), (0.40, 0.38, 0.36), IRON)
# Single horn-spike on helmet
make_cube('Head_horn', (0, 0, 1.78), (0.06, 0.06, 0.18), DARK_IRON)
# Dim ember-red eye glow (peering from helm shadow)
make_cube('Head_eye_L', (-0.08, -0.18, 1.40), (0.04, 0.04, 0.04), EMBER_RED, EMBER_RED, 1.5)
make_cube('Head_eye_R', ( 0.08, -0.18, 1.40), (0.04, 0.04, 0.04), EMBER_RED, EMBER_RED, 1.5)

# Arms
make_cube('Arm_L', (-0.32, -0.05, 1.05), (0.20, 0.20, 0.50), OLIVE_SKIN)
make_cube('Arm_R', ( 0.32, -0.05, 1.05), (0.20, 0.20, 0.50), OLIVE_SKIN)
# Bandage wraps on gauntlets
make_cube('Arm_L_wrap', (-0.32, -0.10, 0.78), (0.22, 0.18, 0.16), (0.68, 0.62, 0.50))
make_cube('Arm_R_wrap', ( 0.32, -0.10, 0.78), (0.22, 0.18, 0.16), (0.68, 0.62, 0.50))

# Legs
make_cube('Leg_L', (-0.13, 0, 0.30), (0.22, 0.24, 0.55), DARK_IRON)
make_cube('Leg_R', ( 0.13, 0, 0.30), (0.22, 0.24, 0.55), DARK_IRON)
# Mismatched leather boots
make_cube('Leg_L_boot', (-0.13, -0.02, 0.04), (0.24, 0.30, 0.13), LEATHER)
make_cube('Leg_R_boot', ( 0.13, -0.02, 0.04), (0.24, 0.30, 0.13), (0.32, 0.20, 0.14))  # one slightly darker = mismatched

# Two-handed forge hammer resting on right shoulder
make_cube('Arm_R_hammer_haft', (0.36, 0.10, 1.20), (0.06, 0.06, 0.55), LEATHER)
make_cube('Arm_R_hammer_head', (0.36, 0.10, 1.55), (0.20, 0.18, 0.18), IRON)

root, empties, mesh_objs = rig_biped(BIPED_PIVOTS, 'IronGob_Root', biped_parent_for)
apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/iron_gob.glb')
