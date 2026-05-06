"""Build npc_brother_pell.glb — round-faced monk in cream wool robe."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, rig_biped, apply_bevel_remove_doubles, export_glb, biped_parent_for, BIPED_PIVOTS

reset_scene()

CREAM_WOOL = (0.90, 0.85, 0.70)
DARK_BELT = (0.32, 0.22, 0.14)
GOLD = (0.86, 0.72, 0.30)
PARCHMENT = (0.92, 0.86, 0.70)
RUDDY = (0.92, 0.65, 0.55)
SKIN = (0.95, 0.78, 0.62)
HAIR = (0.55, 0.40, 0.25)
IRON = (0.42, 0.42, 0.46)

# Short round body
make_cube('Body_torso', (0, 0, 0.85), (0.50, 0.42, 0.55), CREAM_WOOL)
# Robe lower (longer drape)
make_cube('Body_robe', (0, 0, 0.30), (0.52, 0.44, 0.40), CREAM_WOOL)
# Dark belt
make_cube('Body_belt', (0, -0.18, 0.62), (0.50, 0.06, 0.10), DARK_BELT)

# Head (round face)
make_cube('Head_skull', (0, 0, 1.35), (0.34, 0.32, 0.30), SKIN)
# Tonsured hair (ring around bald spot — simplified to a band)
make_cube('Head_hair_band', (0, 0.10, 1.43), (0.36, 0.06, 0.06), HAIR)
make_cube('Head_hair_l', (-0.18, 0, 1.42), (0.04, 0.10, 0.10), HAIR)
make_cube('Head_hair_r', ( 0.18, 0, 1.42), (0.04, 0.10, 0.10), HAIR)
# Gentle smile (simplified — small darker rect on face)
make_cube('Head_smile', (0, -0.16, 1.28), (0.10, 0.02, 0.03), (0.50, 0.30, 0.25))
# Eyes
make_cube('Head_eye_L', (-0.07, -0.16, 1.36), (0.04, 0.04, 0.04), (0.10, 0.05, 0.04))
make_cube('Head_eye_R', ( 0.07, -0.16, 1.36), (0.04, 0.04, 0.04), (0.10, 0.05, 0.04))
# Ruddy cheeks
make_cube('Head_cheek_L', (-0.13, -0.16, 1.30), (0.06, 0.02, 0.04), RUDDY)
make_cube('Head_cheek_R', ( 0.13, -0.16, 1.30), (0.06, 0.02, 0.04), RUDDY)

# Iron key on cord around neck
make_cube('Body_cord', (0, -0.21, 1.20), (0.04, 0.02, 0.10), DARK_BELT)
make_cube('Body_key', (0, -0.22, 1.10), (0.06, 0.02, 0.10), IRON)

# Arms
make_cube('Arm_L', (-0.30, -0.05, 1.05), (0.18, 0.20, 0.45), CREAM_WOOL)
make_cube('Arm_R', ( 0.30, -0.05, 1.05), (0.18, 0.20, 0.45), CREAM_WOOL)

# Hands holding parchment (right hand prominent)
make_cube('Arm_R_parchment', (0.30, -0.20, 0.78), (0.20, 0.06, 0.20), PARCHMENT)
# Gold ornament on parchment
make_cube('Arm_R_gold_orn', (0.30, -0.23, 0.78), (0.10, 0.02, 0.10), GOLD)

# Legs (under robe, mostly hidden — simple)
make_cube('Leg_L', (-0.11, 0, 0.20), (0.20, 0.22, 0.40), CREAM_WOOL)
make_cube('Leg_R', ( 0.11, 0, 0.20), (0.20, 0.22, 0.40), CREAM_WOOL)
# Sandals
make_cube('Leg_L_sandal', (-0.11, -0.02, 0.04), (0.22, 0.30, 0.06), DARK_BELT)
make_cube('Leg_R_sandal', ( 0.11, -0.02, 0.04), (0.22, 0.30, 0.06), DARK_BELT)

root, empties, mesh_objs = rig_biped(BIPED_PIVOTS, 'BrotherPell_Root', biped_parent_for)
apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/npc_pell.glb')
