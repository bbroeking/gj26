"""Build bramble_archer.glb — perched thorn-fae with shortbow."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, rig_biped, apply_bevel_remove_doubles, export_glb

reset_scene(cam_loc=(2.0, -2.0, 1.1), cam_target=(0, 0, 0.6))

FEATHER_BROWN = (0.42, 0.32, 0.20)
DARK_THORN = (0.20, 0.16, 0.12)
THORN_GREEN = (0.28, 0.32, 0.16)
GLASS_BLACK = (0.04, 0.04, 0.04)
VINE_WOOD = (0.42, 0.30, 0.18)
LEAF_FLETCH = (0.32, 0.45, 0.20)
TALON = (0.18, 0.14, 0.10)

# Crow-like body
make_cube('Body_torso', (0, 0, 0.78), (0.26, 0.24, 0.30), FEATHER_BROWN)
# Feathered cloak
make_cube('Body_cloak', (0, 0.06, 0.75), (0.36, 0.30, 0.36), FEATHER_BROWN)
# Cloak hem (thorn fringe)
make_cube('Body_cloak_fringe', (0, 0.05, 0.55), (0.30, 0.26, 0.04), DARK_THORN)

# Head: hood-mask of woven thorns
make_cube('Head_skull', (0, -0.05, 1.05), (0.20, 0.18, 0.18), DARK_THORN)
make_cube('Head_hood', (0, 0, 1.10), (0.26, 0.22, 0.22), DARK_THORN)
# Glassy black eyes (only thing visible from mask)
make_cube('Head_eye_L', (-0.05, -0.13, 1.05), (0.04, 0.04, 0.04), GLASS_BLACK)
make_cube('Head_eye_R', ( 0.05, -0.13, 1.05), (0.04, 0.04, 0.04), GLASS_BLACK)
# Beak hint
make_cube('Head_beak', (0, -0.16, 1.00), (0.04, 0.04, 0.06), TALON)

# Wings (instead of arms — bird-style biped) — actually crow-like fae has arms holding bow
make_cube('Arm_L', (-0.18, -0.04, 0.85), (0.10, 0.12, 0.30), FEATHER_BROWN)
make_cube('Arm_R', ( 0.18, -0.04, 0.85), (0.10, 0.12, 0.30), FEATHER_BROWN)

# Legs (short with talons gripping branch)
make_cube('Leg_L', (-0.08, 0, 0.45), (0.08, 0.10, 0.25), DARK_THORN)
make_cube('Leg_R', ( 0.08, 0, 0.45), (0.08, 0.10, 0.25), DARK_THORN)
# Talons gripping
make_cube('Leg_L_talon', (-0.08, -0.04, 0.30), (0.10, 0.14, 0.06), TALON)
make_cube('Leg_R_talon', ( 0.08, -0.04, 0.30), (0.10, 0.14, 0.06), TALON)

# Thorny perch branch
make_cube('Body_branch', (0, 0, 0.20), (0.50, 0.10, 0.10), VINE_WOOD)
make_cube('Body_branch_thorn1', (-0.20, 0, 0.28), (0.04, 0.04, 0.06), DARK_THORN)
make_cube('Body_branch_thorn2', ( 0.20, 0, 0.28), (0.04, 0.04, 0.06), DARK_THORN)

# Drawn shortbow (twisted vine, in left hand)
make_cube('Arm_L_bow_grip', (-0.30, -0.18, 0.85), (0.04, 0.04, 0.10), VINE_WOOD)
make_cube('Arm_L_bow_top', (-0.32, -0.16, 1.05), (0.03, 0.03, 0.30), VINE_WOOD)
make_cube('Arm_L_bow_bot', (-0.28, -0.16, 0.65), (0.03, 0.03, 0.30), VINE_WOOD)
# Bowstring (drawn back)
make_cube('Arm_L_bowstring', (-0.20, -0.20, 0.85), (0.02, 0.02, 0.55), (0.92, 0.86, 0.72))
# Nocked arrow with leaf-fletch
make_cube('Arm_L_arrow', (-0.10, -0.20, 0.85), (0.02, 0.02, 0.30), VINE_WOOD)
make_cube('Arm_L_arrow_fletch', (0.05, -0.20, 0.85), (0.06, 0.04, 0.08), LEAF_FLETCH)

# Quiver on back with green arrows
make_cube('Body_quiver', (0.13, 0.16, 0.95), (0.10, 0.10, 0.30), DARK_THORN)
make_cube('Body_quiver_arrow_a', (0.10, 0.16, 1.18), (0.02, 0.02, 0.20), VINE_WOOD)
make_cube('Body_quiver_arrow_b', (0.16, 0.16, 1.18), (0.02, 0.02, 0.20), VINE_WOOD)
make_cube('Body_quiver_fletch', (0.13, 0.16, 1.30), (0.06, 0.04, 0.08), LEAF_FLETCH)

biped_pivots = {
    'Body':  (0, 0, 0.55),
    'Head':  (0, 0, 0.95),
    'Arm_L': (-0.16, 0, 0.95),
    'Arm_R': ( 0.16, 0, 0.95),
    'Leg_L': (-0.08, 0, 0.55),
    'Leg_R': ( 0.08, 0, 0.55),
}
def parent_for(name):
    if name.startswith('Body_'): return 'Body'
    if name.startswith('Head_'): return 'Head'
    if name == 'Arm_L' or name.startswith('Arm_L_'): return 'Arm_L'
    if name == 'Arm_R' or name.startswith('Arm_R_'): return 'Arm_R'
    if name == 'Leg_L' or name.startswith('Leg_L_'): return 'Leg_L'
    if name == 'Leg_R' or name.startswith('Leg_R_'): return 'Leg_R'
    return None

root, empties, mesh_objs = rig_biped(biped_pivots, 'BrambleArcher_Root', parent_for)
apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/bramble_archer.glb')
