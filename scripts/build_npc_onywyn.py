"""Build npc_mother_onywyn.glb — herb-witch with raven and foxglove."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, rig_biped, apply_bevel_remove_doubles, export_glb, biped_parent_for, BIPED_PIVOTS

reset_scene()

FOREST_GREEN = (0.18, 0.30, 0.18)
DARK_GREEN = (0.10, 0.18, 0.10)
RAVEN = (0.05, 0.05, 0.05)
FOXGLOVE = (0.62, 0.40, 0.65)
DARK_LINEN = (0.28, 0.26, 0.22)
GLASS = (0.65, 0.78, 0.85)
HERB = (0.40, 0.50, 0.22)
WOOD = (0.32, 0.22, 0.14)
SKIN = (0.85, 0.72, 0.58)
GREY_HAIR = (0.65, 0.62, 0.55)

# Tall thin body
make_cube('Body_torso', (0, 0, 0.95), (0.36, 0.30, 0.55), DARK_LINEN)
# Hooded cloak (drapes long)
make_cube('Body_cloak', (0, 0.05, 0.85), (0.50, 0.40, 0.85), FOREST_GREEN)
make_cube('Body_cloak_lower', (0, 0.04, 0.30), (0.46, 0.38, 0.30), DARK_GREEN)
# Belt with herb jars
make_cube('Body_belt', (0, -0.16, 0.68), (0.46, 0.04, 0.06), WOOD)
# 3 small glass jars at belt
for i, x in enumerate([-0.18, 0, 0.18]):
    make_cube(f'Body_jar_{i}', (x, -0.20, 0.60), (0.06, 0.06, 0.10), GLASS)
    make_cube(f'Body_jar_herb_{i}', (x, -0.20, 0.62), (0.04, 0.04, 0.04), HERB)

# Head + hood
make_cube('Head_skull', (0, 0, 1.45), (0.30, 0.28, 0.30), SKIN)
make_cube('Head_hood_top', (0, 0.05, 1.65), (0.40, 0.32, 0.20), FOREST_GREEN)
make_cube('Head_hood_back', (0, 0.18, 1.50), (0.36, 0.16, 0.36), FOREST_GREEN)
# Grey hair (stragglers visible at temples)
make_cube('Head_hair_L', (-0.16, -0.05, 1.42), (0.06, 0.10, 0.20), GREY_HAIR)
make_cube('Head_hair_R', ( 0.16, -0.05, 1.42), (0.06, 0.10, 0.20), GREY_HAIR)
# Eyes (sharp)
make_cube('Head_eye_L', (-0.07, -0.15, 1.45), (0.04, 0.04, 0.03), (0.10, 0.18, 0.08))
make_cube('Head_eye_R', ( 0.07, -0.15, 1.45), (0.04, 0.04, 0.03), (0.10, 0.18, 0.08))
# Crow's-foot eye lines (subtle)
make_cube('Head_lines_L', (-0.12, -0.16, 1.42), (0.06, 0.02, 0.02), (0.65, 0.55, 0.42))
make_cube('Head_lines_R', ( 0.12, -0.16, 1.42), (0.06, 0.02, 0.02), (0.65, 0.55, 0.42))

# Raven on left shoulder
make_cube('Body_raven_body', (-0.28, 0, 1.42), (0.14, 0.16, 0.14), RAVEN)
make_cube('Body_raven_head', (-0.32, -0.10, 1.50), (0.10, 0.10, 0.08), RAVEN)
make_cube('Body_raven_beak', (-0.36, -0.12, 1.48), (0.04, 0.04, 0.04), (0.55, 0.42, 0.18))
make_cube('Body_raven_eye', (-0.32, -0.13, 1.52), (0.02, 0.02, 0.02), (0.85, 0.65, 0.20))

# Arms
make_cube('Arm_L', (-0.28, -0.05, 1.10), (0.14, 0.16, 0.45), FOREST_GREEN)
make_cube('Arm_R', ( 0.28, -0.05, 1.10), (0.14, 0.16, 0.45), FOREST_GREEN)
# Foxglove sprig in left hand
make_cube('Arm_L_stem', (-0.30, -0.20, 0.85), (0.02, 0.02, 0.18), HERB)
make_cube('Arm_L_flower_a', (-0.30, -0.22, 0.95), (0.06, 0.04, 0.06), FOXGLOVE)
make_cube('Arm_L_flower_b', (-0.32, -0.20, 0.92), (0.05, 0.04, 0.05), FOXGLOVE)

# Weathered staff in right hand
make_cube('Arm_R_staff', (0.40, -0.18, 1.20), (0.06, 0.06, 1.30), WOOD)

# Legs
make_cube('Leg_L', (-0.10, 0, 0.30), (0.18, 0.20, 0.55), DARK_LINEN)
make_cube('Leg_R', ( 0.10, 0, 0.30), (0.18, 0.20, 0.55), DARK_LINEN)
make_cube('Leg_L_boot', (-0.10, -0.02, 0.04), (0.20, 0.26, 0.13), WOOD)
make_cube('Leg_R_boot', ( 0.10, -0.02, 0.04), (0.20, 0.26, 0.13), WOOD)

root, empties, mesh_objs = rig_biped(BIPED_PIVOTS, 'Onywyn_Root', biped_parent_for)
apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/npc_onywyn.glb')
