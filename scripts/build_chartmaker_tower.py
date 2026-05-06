"""Build chartmaker_tower.glb — three-story round stone tower w/ telescope."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, apply_bevel_remove_doubles, export_glb
import bpy

reset_scene(cam_loc=(5, -5, 4), cam_target=(0, 0, 2.0))

STONE = (0.62, 0.58, 0.50)
STONE_DARK = (0.48, 0.45, 0.40)
COPPER_PATINA = (0.32, 0.55, 0.50)
BRASS = (0.78, 0.58, 0.18)
CREAM = (0.92, 0.86, 0.72)
RED = (0.72, 0.18, 0.16)
IVY_GREEN = (0.30, 0.45, 0.22)
WOOD_DARK = (0.32, 0.22, 0.16)
GLOW = (0.95, 0.78, 0.40)

# Tower shaft (3 stories, slightly taller than wide for proportion)
make_cube('Tower_base', (0, 0, 0.6), (1.4, 1.4, 1.2), STONE)
make_cube('Tower_mid', (0, 0, 1.8), (1.3, 1.3, 1.2), STONE_DARK)
make_cube('Tower_top', (0, 0, 3.0), (1.2, 1.2, 1.2), STONE)

# Window slits (3 per story, just darker spots)
for z in [0.7, 1.9, 3.1]:
    make_cube(f'Tower_win_{int(z*10)}', (0, -0.71, z), (0.20, 0.04, 0.30), GLOW, GLOW, 1.0)

# Door (front)
make_cube('Tower_door', (0, -0.71, 0.30), (0.42, 0.06, 0.60), WOOD_DARK)
make_cube('Tower_door_handle', (0.10, -0.74, 0.30), (0.04, 0.04, 0.04), BRASS)

# Hexagonal observation deck on top (slightly wider than top story)
make_cube('Tower_deck', (0, 0, 3.75), (1.5, 1.5, 0.20), STONE_DARK)
make_cube('Tower_rail_N', (0, -0.70, 3.95), (1.4, 0.06, 0.16), STONE)
make_cube('Tower_rail_S', (0, 0.70, 3.95), (1.4, 0.06, 0.16), STONE)
make_cube('Tower_rail_E', (0.70, 0, 3.95), (0.06, 1.4, 0.16), STONE)
make_cube('Tower_rail_W', (-0.70, 0, 3.95), (0.06, 1.4, 0.16), STONE)

# Brass telescope on the deck rail
make_cube('Tower_scope_body', (0.50, -0.55, 4.10), (0.10, 0.30, 0.10), BRASS)
make_cube('Tower_scope_eyepiece', (0.50, -0.42, 4.10), (0.06, 0.06, 0.06), BRASS)
make_cube('Tower_scope_stand', (0.50, -0.55, 4.00), (0.06, 0.06, 0.10), STONE_DARK)

# Copper-domed roof in patinated green
make_cube('Tower_roof_a', (0, 0, 4.30), (1.2, 1.2, 0.30), COPPER_PATINA)
make_cube('Tower_roof_b', (0, 0, 4.55), (0.8, 0.8, 0.30), COPPER_PATINA)
make_cube('Tower_roof_c', (0, 0, 4.78), (0.4, 0.4, 0.20), COPPER_PATINA)
make_cube('Tower_roof_spire', (0, 0, 5.00), (0.10, 0.10, 0.30), COPPER_PATINA)

# Weathervane in shape of leaping fish
make_cube('Tower_weather_pole', (0, 0, 5.25), (0.04, 0.04, 0.20), BRASS)
make_cube('Tower_fish', (0, 0, 5.45), (0.30, 0.06, 0.16), BRASS)
make_cube('Tower_fish_tail', (-0.18, 0, 5.50), (0.08, 0.04, 0.10), BRASS)

# Cream + red pennants (4 from deck rail)
for i, (x, y) in enumerate([(-0.50, -0.65), (0.20, -0.65), (-0.40, 0.65), (0.45, 0.65)]):
    color = CREAM if i % 2 == 0 else RED
    make_cube(f'Tower_pennant_{i}', (x, y, 4.05), (0.06, 0.06, 0.20), color)

# Ivy creeping up one side (the west side)
for i, z in enumerate([0.8, 1.4, 2.2, 2.8]):
    make_cube(f'Tower_ivy_{i}', (-0.71, 0.10, z), (0.04, 0.10, 0.30), IVY_GREEN)

# Cobble path leading to door (3 stones)
for i, y in enumerate([-1.2, -1.6, -2.0]):
    make_cube(f'Tower_path_{i}', (0, y, 0.04), (0.40, 0.30, 0.06), STONE)
    make_cube(f'Tower_path_b_{i}', (-0.20, y, 0.04), (0.16, 0.20, 0.06), STONE_DARK)

# Group under root
root = bpy.data.objects.new('ChartmakerTower_Root', None)
root.empty_display_type = 'PLAIN_AXES'
bpy.context.scene.collection.objects.link(root)
mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
for obj in mesh_objs:
    wm = obj.matrix_world.copy()
    obj.parent = root
    obj.matrix_parent_inverse = root.matrix_world.inverted()
    obj.matrix_world = wm

apply_bevel_remove_doubles(mesh_objs)
export_glb(root, '/Users/bbroeking/projects/gj26/models/chartmaker_tower.glb')
