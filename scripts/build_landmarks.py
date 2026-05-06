"""Build forge_interior.glb + herbalist_interior.glb — diorama cutaways."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from _build_lib import reset_scene, make_cube, apply_bevel_remove_doubles, export_glb
import bpy

def build_one(slug, build_fn):
    reset_scene(cam_loc=(4, -4, 2.5), cam_target=(0, 0, 1.0))
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

# Shared palette
WOOD = (0.46, 0.32, 0.18)
DARK_WOOD = (0.28, 0.18, 0.12)
STONE = (0.55, 0.52, 0.48)
DARK_STONE = (0.38, 0.36, 0.34)
BRICK_RED = (0.55, 0.30, 0.22)
SOOT = (0.10, 0.08, 0.08)
HEARTH_ORANGE = (0.95, 0.55, 0.25)
EMBER_GLOW = (0.98, 0.78, 0.30)
IRON = (0.32, 0.34, 0.38)
COPPER = (0.72, 0.42, 0.20)
LEATHER = (0.45, 0.30, 0.18)
CREAM = (0.92, 0.86, 0.72)
HERB_GREEN = (0.36, 0.50, 0.24)
DRY_HERB = (0.55, 0.45, 0.22)
GLASS_BLUE = (0.45, 0.62, 0.75)
RUG_CREAM = (0.85, 0.78, 0.62)
CAT_GREY = (0.55, 0.50, 0.45)

def forge_interior():
    # Floor
    make_cube('Floor', (0, 0, 0), (3.0, 3.0, 0.06), STONE)
    # Back wall (cutaway — we show 2 walls L + back)
    make_cube('Wall_L', (-1.45, 0, 1.0), (0.10, 3.0, 2.0), STONE)
    make_cube('Wall_back', (0, 1.45, 1.0), (3.0, 0.10, 2.0), STONE)
    # Brick hearth (back wall, large)
    make_cube('Hearth_brick', (0.5, 1.40, 0.7), (1.4, 0.20, 1.4), BRICK_RED)
    make_cube('Hearth_opening', (0.5, 1.30, 0.5), (0.9, 0.15, 0.7), SOOT)
    make_cube('Hearth_glow', (0.5, 1.20, 0.4), (0.7, 0.05, 0.3), HEARTH_ORANGE, HEARTH_ORANGE, 3.0)
    # Chimney
    make_cube('Chimney', (0.5, 1.40, 1.8), (0.6, 0.20, 0.4), DARK_STONE)
    # Anvil center
    make_cube('Anvil_base', (-0.3, 0.2, 0.18), (0.30, 0.40, 0.20), DARK_WOOD)
    make_cube('Anvil_top', (-0.3, 0.2, 0.40), (0.50, 0.20, 0.10), IRON)
    make_cube('Anvil_horn', (-0.55, 0.2, 0.42), (0.20, 0.10, 0.08), IRON)
    # Glowing iron bar on anvil
    make_cube('Iron_bar', (-0.3, 0.2, 0.50), (0.20, 0.04, 0.04), HEARTH_ORANGE, EMBER_GLOW, 2.5)
    # Leather bellows beside hearth
    make_cube('Bellows_a', (1.10, 0.95, 0.45), (0.30, 0.30, 0.30), LEATHER)
    make_cube('Bellows_pipe', (0.85, 1.10, 0.55), (0.30, 0.06, 0.06), DARK_WOOD)
    # Tool rack on left wall
    make_cube('Tool_rack', (-1.30, -0.4, 1.20), (0.04, 0.50, 0.40), DARK_WOOD)
    # Tongs
    make_cube('Tongs', (-1.20, -0.4, 1.30), (0.06, 0.04, 0.30), IRON)
    # Hammer
    make_cube('Hammer_head', (-1.25, -0.6, 1.25), (0.10, 0.04, 0.06), IRON)
    make_cube('Hammer_haft', (-1.25, -0.6, 1.10), (0.04, 0.04, 0.20), WOOD)
    # File
    make_cube('File', (-1.25, -0.2, 1.20), (0.04, 0.04, 0.30), IRON)
    # Water trough at floor
    make_cube('Trough', (1.1, -0.3, 0.20), (0.50, 0.40, 0.20), DARK_WOOD)
    make_cube('Trough_water', (1.1, -0.3, 0.30), (0.46, 0.36, 0.04), GLASS_BLUE)
    # Cluttered shelf of nails/rivets (back-right)
    make_cube('Shelf', (1.10, 1.30, 1.20), (0.50, 0.15, 0.05), WOOD)
    for i in range(4):
        make_cube(f'Rivet_{i}', (0.95 + i*0.10, 1.30, 1.27), (0.04, 0.04, 0.04), IRON)
    # Sparks rising from hearth (4 small bright cubes)
    for i, (x, z) in enumerate([(0.30, 0.80), (0.50, 1.05), (0.70, 0.95), (0.40, 1.20)]):
        make_cube(f'Spark_{i}', (x, 1.10, z), (0.03, 0.03, 0.03), EMBER_GLOW, EMBER_GLOW, 4.0)

def herbalist_interior():
    # Floor + cream rug
    make_cube('Floor', (0, 0, 0), (3.0, 3.0, 0.06), DARK_WOOD)
    make_cube('Rug', (0, 0, 0.04), (1.6, 1.4, 0.02), RUG_CREAM)
    # Back wall + side
    make_cube('Wall_L', (-1.45, 0, 1.0), (0.10, 3.0, 2.0), CREAM)
    make_cube('Wall_back', (0, 1.45, 1.0), (3.0, 0.10, 2.0), CREAM)
    # Sloped beam ceiling (a few exposed beams)
    for i, x in enumerate([-0.8, 0, 0.8]):
        make_cube(f'Beam_{i}', (x, 0.5, 1.95), (0.10, 2.0, 0.10), DARK_WOOD)
    # Herb bundles hanging from beams
    for i, (x, y) in enumerate([(-0.7, 0.3), (-0.1, 0.6), (0.5, 0.4), (0.9, 0.7), (-0.5, 0.9), (0.3, 1.0)]):
        make_cube(f'Bundle_{i}', (x, y, 1.65), (0.10, 0.06, 0.20), DRY_HERB)
        make_cube(f'Bundle_str_{i}', (x, y, 1.78), (0.04, 0.04, 0.10), CREAM)
    # Stone hearth (left wall, smaller than forge)
    make_cube('Hearth', (-1.30, 0.5, 0.6), (0.20, 0.50, 1.0), STONE)
    make_cube('Hearth_op', (-1.20, 0.5, 0.5), (0.10, 0.30, 0.40), SOOT)
    make_cube('Hearth_fire', (-1.20, 0.5, 0.4), (0.06, 0.20, 0.20), HEARTH_ORANGE, HEARTH_ORANGE, 2.5)
    # Simmering pot
    make_cube('Pot', (-1.15, 0.5, 0.65), (0.10, 0.20, 0.16), IRON)
    make_cube('Pot_steam', (-1.10, 0.5, 0.85), (0.06, 0.10, 0.06), CREAM)
    # Alchemy bench (back-right wall)
    make_cube('Bench', (0.70, 1.20, 0.65), (1.20, 0.40, 0.10), WOOD)
    make_cube('Bench_leg_L', (0.20, 1.20, 0.30), (0.05, 0.05, 0.55), DARK_WOOD)
    make_cube('Bench_leg_R', (1.20, 1.20, 0.30), (0.05, 0.05, 0.55), DARK_WOOD)
    # Mortars + bottles cluttered on bench
    make_cube('Mortar', (0.30, 1.20, 0.78), (0.12, 0.12, 0.10), STONE)
    make_cube('Pestle', (0.30, 1.20, 0.86), (0.04, 0.04, 0.10), DARK_STONE)
    make_cube('Bottle_a', (0.55, 1.20, 0.80), (0.06, 0.06, 0.18), GLASS_BLUE)
    make_cube('Bottle_b', (0.75, 1.20, 0.80), (0.06, 0.06, 0.18), HERB_GREEN)
    make_cube('Bottle_c', (0.95, 1.20, 0.80), (0.06, 0.06, 0.18), DRY_HERB)
    # Stack of books with cat on top
    make_cube('Books_a', (-0.50, 0.30, 0.10), (0.30, 0.20, 0.08), LEATHER)
    make_cube('Books_b', (-0.50, 0.30, 0.18), (0.30, 0.22, 0.08), DARK_WOOD)
    make_cube('Books_c', (-0.50, 0.30, 0.26), (0.28, 0.20, 0.08), CREAM)
    # Sleeping cat on books (curled up)
    make_cube('Cat_body', (-0.50, 0.30, 0.36), (0.24, 0.18, 0.08), CAT_GREY)
    make_cube('Cat_head', (-0.40, 0.20, 0.42), (0.10, 0.10, 0.08), CAT_GREY)
    make_cube('Cat_ear_L', (-0.45, 0.18, 0.49), (0.04, 0.04, 0.04), CAT_GREY)
    make_cube('Cat_ear_R', (-0.36, 0.18, 0.49), (0.04, 0.04, 0.04), CAT_GREY)
    make_cube('Cat_tail', (-0.62, 0.40, 0.40), (0.04, 0.16, 0.04), CAT_GREY)

build_one('forge_interior', forge_interior)
build_one('herbalist_interior', herbalist_interior)

print("Both landmark interiors exported.")
