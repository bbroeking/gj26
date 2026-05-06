"""Build 4 cartography inventory items: blank chart, surveyor pole, compass, master chart."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, apply_bevel_remove_doubles, export_glb
import bpy

def build_one(slug, build_fn):
    reset_scene(cam_loc=(1.0, -1.0, 0.5), cam_target=(0, 0, 0.0))
    build_fn()
    root = bpy.data.objects.new(f'{slug}_Root', None)
    root.empty_display_type = 'PLAIN_AXES'
    bpy.context.scene.collection.objects.link(root)
    mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
    for obj in mesh_objs:
        wm = obj.matrix_world.copy()
        obj.parent = root
        obj.matrix_parent_inverse = root.matrix_world.inverted()
        obj.matrix_world = wm
    apply_bevel_remove_doubles(mesh_objs)
    export_glb(root, f'/Users/bbroeking/projects/gj26/models/{slug}.glb')

PARCHMENT = (0.92, 0.86, 0.70)
PARCHMENT_DARK = (0.78, 0.68, 0.50)
WOOD = (0.45, 0.32, 0.18)
IRON_DARK = (0.32, 0.30, 0.30)
BRASS = (0.78, 0.58, 0.18)
INK_BLUE = (0.18, 0.30, 0.55)
RED_WAX = (0.72, 0.18, 0.16)
CREAM = (0.92, 0.88, 0.74)
LEATHER_TAN = (0.62, 0.46, 0.30)
GOLD_LEAF = (0.86, 0.72, 0.30)

def chart_blank():
    # Folded parchment on wooden plank, two iron weights
    make_cube('Plank', (0, 0, 0.02), (0.40, 0.30, 0.04), WOOD)
    make_cube('Parchment', (0, 0, 0.06), (0.34, 0.24, 0.02), PARCHMENT)
    make_cube('Parch_edge_a', (0.13, 0, 0.07), (0.06, 0.22, 0.01), PARCHMENT_DARK)
    make_cube('Weight_L', (-0.16, -0.12, 0.10), (0.05, 0.05, 0.06), IRON_DARK)
    make_cube('Weight_R', (0.16, -0.12, 0.10), (0.05, 0.05, 0.06), IRON_DARK)

def surveyor_pole():
    # Tall striped wooden stake with brass plumb-bob
    # Bands alternating cream + red along the pole
    for i in range(8):
        z = 0.05 + i * 0.10
        c = CREAM if i % 2 == 0 else RED_WAX
        make_cube(f'Pole_band_{i}', (0, 0, z), (0.06, 0.06, 0.10), c)
    # Plumb-bob hanging from a leather strap
    make_cube('Plumb_strap', (0.02, -0.06, 0.78), (0.02, 0.06, 0.10), LEATHER_TAN)
    make_cube('Plumb_bob', (0.02, -0.10, 0.66), (0.06, 0.06, 0.10), BRASS)
    # Mud at base
    make_cube('Pole_mud', (0, 0, 0.02), (0.10, 0.10, 0.02), (0.30, 0.20, 0.14))

def cartographer_compass():
    # Open brass compass on a leather travel-map
    make_cube('Map', (0, 0, 0.02), (0.40, 0.30, 0.02), PARCHMENT_DARK)
    # Compass body
    make_cube('Compass_base', (-0.08, -0.04, 0.06), (0.16, 0.16, 0.04), BRASS)
    make_cube('Compass_lid', (-0.08, -0.04, 0.10), (0.16, 0.04, 0.10), BRASS)
    # Quill
    make_cube('Quill_shaft', (0.10, 0.05, 0.06), (0.02, 0.20, 0.01), CREAM)
    make_cube('Quill_feather', (0.10, 0.18, 0.07), (0.04, 0.10, 0.04), CREAM)
    # Inkpot
    make_cube('Inkpot', (0.13, -0.10, 0.06), (0.08, 0.08, 0.08), INK_BLUE)
    # Candle stub
    make_cube('Candle', (-0.18, 0.10, 0.06), (0.04, 0.04, 0.08), CREAM)
    make_cube('Candle_flame', (-0.18, 0.10, 0.13), (0.03, 0.03, 0.04), (0.95, 0.78, 0.30))

def master_chart():
    # Large unfurled vellum map with 4 corner ornaments + central wax seal
    make_cube('Vellum', (0, 0, 0.02), (0.50, 0.40, 0.02), CREAM)
    # Inked details: river (blue stripe) + hill (brown bump)
    make_cube('River', (-0.05, 0.08, 0.04), (0.30, 0.04, 0.01), INK_BLUE)
    make_cube('Hill', (0.10, -0.10, 0.04), (0.10, 0.06, 0.02), (0.50, 0.40, 0.30))
    # Corner ornaments (gold leaf)
    for i, (x, y) in enumerate([(-0.22, 0.17), (0.22, 0.17), (-0.22, -0.17), (0.22, -0.17)]):
        make_cube(f'Orn_{i}', (x, y, 0.03), (0.06, 0.06, 0.02), GOLD_LEAF)
    # Wax seal in center
    make_cube('Seal', (0, 0, 0.04), (0.08, 0.08, 0.02), RED_WAX)
    # Roller dowels at each end
    make_cube('Roller_L', (-0.27, 0, 0.03), (0.04, 0.36, 0.04), WOOD)
    make_cube('Roller_R', (0.27, 0, 0.03), (0.04, 0.36, 0.04), WOOD)

# Build all 4
build_one('chart_blank', chart_blank)
build_one('surveyor_pole', surveyor_pole)
build_one('cartographer_compass', cartographer_compass)
build_one('master_chart', master_chart)

print("All 4 cartography items exported.")
