"""Build waypoint_cairn.glb — small ceremonial stone cairn with red ribbon."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, apply_bevel_remove_doubles, export_glb
import bpy

reset_scene(cam_loc=(1.5, -1.5, 0.8), cam_target=(0, 0, 0.3))

STONE = (0.55, 0.52, 0.48)
STONE_DARK = (0.42, 0.40, 0.36)
MOSS = (0.36, 0.50, 0.24)
RIBBON = (0.78, 0.20, 0.18)
MUSHROOM_CAP = (0.92, 0.88, 0.74)
ROSE = (0.72, 0.42, 0.50)

# Stacked stone cairn
make_cube('Cairn_base', (0, 0, 0.05), (0.45, 0.45, 0.10), STONE_DARK)
make_cube('Cairn_stone1', (-0.05, -0.03, 0.18), (0.30, 0.28, 0.16), STONE)
make_cube('Cairn_stone2', (0.05, 0.04, 0.34), (0.26, 0.24, 0.14), STONE_DARK)
make_cube('Cairn_stone3', (-0.02, -0.02, 0.46), (0.20, 0.18, 0.12), STONE)
# Top stone with rose sigil carved on it
make_cube('Cairn_top', (0, 0, 0.55), (0.16, 0.14, 0.06), STONE_DARK)
make_cube('Cairn_rose', (0, -0.07, 0.55), (0.06, 0.02, 0.06), ROSE)

# Red ribbon tied around middle
make_cube('Cairn_ribbon', (0, 0, 0.30), (0.32, 0.30, 0.04), RIBBON)
# Ribbon trail (one drop)
make_cube('Cairn_ribbon_trail', (0.16, 0.10, 0.20), (0.04, 0.02, 0.20), RIBBON)

# Mushrooms at base (3 small cream cubes with stem)
for i, (x, y) in enumerate([(-0.20, 0.18), (0.20, -0.18), (-0.16, -0.20)]):
    make_cube(f'Cairn_mush_stem_{i}', (x, y, 0.03), (0.04, 0.04, 0.06), (0.92, 0.88, 0.78))
    make_cube(f'Cairn_mush_cap_{i}', (x, y, 0.08), (0.08, 0.08, 0.05), MUSHROOM_CAP)

# Mossy patches between stones
make_cube('Cairn_moss_a', (-0.08, 0.10, 0.26), (0.06, 0.04, 0.04), MOSS)
make_cube('Cairn_moss_b', (0.10, -0.06, 0.40), (0.05, 0.04, 0.04), MOSS)

# Group all under root (no rig — static prop)
root = bpy.data.objects.new('Cairn_Root', None)
root.empty_display_type = 'PLAIN_AXES'
bpy.context.scene.collection.objects.link(root)
mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
for obj in mesh_objs:
    wm = obj.matrix_world.copy()
    obj.parent = root
    obj.matrix_parent_inverse = root.matrix_world.inverted()
    obj.matrix_world = wm

apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/waypoint_cairn.glb')
