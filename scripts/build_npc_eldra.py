"""Build npc_eldra_lampwright.glb — stooped elderly woman with lantern-pole."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, rig_biped, apply_bevel_remove_doubles, export_glb, biped_parent_for, BIPED_PIVOTS

reset_scene()

CREAM_SHAWL = (0.86, 0.82, 0.72)
LANTERN_GLOW = (0.95, 0.65, 0.30)
WHITE_HAIR = (0.92, 0.90, 0.86)
PATCH_GREEN = (0.42, 0.50, 0.32)
SKIN = (0.90, 0.78, 0.65)
LEATHER = (0.32, 0.22, 0.16)
WOOD = (0.42, 0.30, 0.18)

# Stooped torso (slightly forward-leaning)
make_cube('Body_torso', (0, -0.05, 0.92), (0.42, 0.30, 0.50), CREAM_SHAWL)
make_cube('Body_shawl', (0, 0, 0.95), (0.50, 0.36, 0.30), CREAM_SHAWL)
# Patch-green mended shoulder
make_cube('Body_patch', (-0.18, -0.10, 1.05), (0.10, 0.06, 0.10), PATCH_GREEN)
# Canvas skirt
make_cube('Body_skirt', (0, 0, 0.40), (0.46, 0.34, 0.30), CREAM_SHAWL)
# Belt with wick pouch
make_cube('Body_belt', (0, -0.15, 0.65), (0.46, 0.06, 0.06), LEATHER)
make_cube('Body_pouch', (0.20, -0.18, 0.55), (0.10, 0.08, 0.10), LEATHER)

# Head
make_cube('Head_skull', (0, 0, 1.40), (0.32, 0.30, 0.30), SKIN)
# White hair tied with twine (loose bun + straggles)
make_cube('Head_hair', (0, 0.05, 1.55), (0.34, 0.30, 0.18), WHITE_HAIR)
# Eyes (kindly squint = smaller)
make_cube('Head_eye_L', (-0.07, -0.16, 1.42), (0.04, 0.04, 0.02), (0.10, 0.05, 0.04))
make_cube('Head_eye_R', ( 0.07, -0.16, 1.42), (0.04, 0.04, 0.02), (0.10, 0.05, 0.04))

# Arms
make_cube('Arm_L', (-0.30, -0.05, 1.05), (0.16, 0.18, 0.45), CREAM_SHAWL)
make_cube('Arm_R', ( 0.30, -0.05, 1.05), (0.16, 0.18, 0.45), CREAM_SHAWL)

# Legs (mended canvas trousers under skirt edge)
make_cube('Leg_L', (-0.11, 0, 0.30), (0.20, 0.22, 0.50), (0.62, 0.55, 0.42))
make_cube('Leg_R', ( 0.11, 0, 0.30), (0.20, 0.22, 0.50), (0.62, 0.55, 0.42))
# Sturdy clogs
make_cube('Leg_L_clog', (-0.11, -0.02, 0.04), (0.22, 0.30, 0.13), WOOD)
make_cube('Leg_R_clog', ( 0.11, -0.02, 0.04), (0.22, 0.30, 0.13), WOOD)

# Lantern pole over right shoulder (long oak with 3 lanterns)
make_cube('Arm_R_pole', (0.40, -0.10, 1.40), (0.05, 0.05, 1.10), WOOD)
# Three lanterns (orange glow)
for i, z in enumerate([1.00, 1.40, 1.80]):
    make_cube(f'Arm_R_lantern_{i}', (0.42, -0.20, z), (0.10, 0.10, 0.14), LANTERN_GLOW, LANTERN_GLOW, 1.5)

root, empties, mesh_objs = rig_biped(BIPED_PIVOTS, 'Eldra_Root', biped_parent_for)
apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/npc_eldra.glb')
