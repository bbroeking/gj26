"""Build 3 shields + 4 armor (cuirass + helm) as drop-in 3D inventory meshes."""
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

OAK = (0.46, 0.32, 0.18)
IRON = (0.32, 0.34, 0.38)
BRASS = (0.78, 0.58, 0.18)
CREAM_LEATHER = (0.86, 0.78, 0.62)
DARK_OAK = (0.30, 0.22, 0.16)
BOGIRON = (0.42, 0.32, 0.22)
COPPER = (0.72, 0.42, 0.20)
MOSS_GREEN = (0.30, 0.42, 0.22)
CINDER_DARK = (0.18, 0.16, 0.18)
EMBER_PINK = (0.95, 0.45, 0.55)
GOLD = (0.86, 0.72, 0.30)
DEEP_RED = (0.50, 0.18, 0.18)
TAN_LEATHER = (0.55, 0.40, 0.25)
LINEN = (0.92, 0.86, 0.74)
VERDIGRIS = (0.40, 0.55, 0.42)

# === SHIELDS ===
def wooden_shield():
    # Round buckler with iron bands
    make_cube('Disk', (0, 0, 0), (0.40, 0.05, 0.40), OAK)
    # Iron rim bands
    make_cube('Rim_top', (0, -0.03, 0.20), (0.40, 0.04, 0.04), IRON)
    make_cube('Rim_bot', (0, -0.03, -0.20), (0.40, 0.04, 0.04), IRON)
    # Central iron boss (sun-hammer)
    make_cube('Boss', (0, -0.04, 0), (0.12, 0.04, 0.12), IRON)
    # Rivets (4 brass)
    for i, (x, z) in enumerate([(-0.16, 0.16), (0.16, 0.16), (-0.16, -0.16), (0.16, -0.16)]):
        make_cube(f'Rivet_{i}', (x, -0.04, z), (0.03, 0.02, 0.03), BRASS)

def bogiron_shield():
    # Heater shape — wider top, tapering bottom
    make_cube('Face_top', (0, -0.02, 0.15), (0.36, 0.06, 0.20), BOGIRON)
    make_cube('Face_bot', (0, -0.02, -0.10), (0.28, 0.06, 0.20), BOGIRON)
    make_cube('Back', (0, 0.04, 0), (0.32, 0.04, 0.40), DARK_OAK)
    # Iron rim
    make_cube('Rim_L', (-0.18, -0.02, 0.05), (0.04, 0.06, 0.40), IRON)
    make_cube('Rim_R', ( 0.18, -0.02, 0.05), (0.04, 0.06, 0.40), IRON)
    # Mossy bramble crest in center
    make_cube('Crest', (0, -0.06, 0), (0.10, 0.04, 0.14), MOSS_GREEN)
    # Copper studs on edges
    for i, (x, z) in enumerate([(-0.16, 0.16), (0.16, 0.16), (-0.16, -0.16), (0.16, -0.16)]):
        make_cube(f'Stud_{i}', (x, -0.05, z), (0.03, 0.02, 0.03), COPPER)

def cinderbloom_shield():
    # Kite-shape (tall pointed bottom)
    make_cube('Face_top', (0, -0.02, 0.15), (0.32, 0.06, 0.20), CINDER_DARK)
    make_cube('Face_mid', (0, -0.02, -0.05), (0.28, 0.06, 0.18), CINDER_DARK)
    make_cube('Face_point', (0, -0.02, -0.22), (0.18, 0.06, 0.10), CINDER_DARK)
    # Diagonal ember line
    make_cube('Ember_line', (0, -0.06, 0), (0.04, 0.04, 0.40), EMBER_PINK, EMBER_PINK, 2.0)
    # Gold trim border
    make_cube('Trim_L', (-0.16, -0.04, 0.05), (0.03, 0.04, 0.36), GOLD)
    make_cube('Trim_R', ( 0.16, -0.04, 0.05), (0.03, 0.04, 0.36), GOLD)
    # Central blackened-rose flower
    make_cube('Rose', (0, -0.07, 0), (0.10, 0.03, 0.10), CINDER_DARK)
    # Gold rivet studs at corners
    for i, (x, z) in enumerate([(-0.14, 0.18), (0.14, 0.18), (-0.10, -0.18), (0.10, -0.18)]):
        make_cube(f'Stud_{i}', (x, -0.06, z), (0.03, 0.02, 0.03), GOLD)

# === ARMOR ===
def leather_body():
    # Boiled-leather cuirass
    make_cube('Front', (0, -0.10, 0.05), (0.36, 0.06, 0.40), TAN_LEATHER)
    make_cube('Back', (0, 0.10, 0.05), (0.36, 0.06, 0.40), DARK_OAK)
    # Cream linen at neck + sleeves visible at top
    make_cube('Linen_neck', (0, 0, 0.25), (0.20, 0.10, 0.04), LINEN)
    # Dark leather straps + brass buckles
    make_cube('Strap_L', (-0.18, -0.10, 0), (0.04, 0.04, 0.40), DARK_OAK)
    make_cube('Strap_R', ( 0.18, -0.10, 0), (0.04, 0.04, 0.40), DARK_OAK)
    make_cube('Buckle_L', (-0.18, -0.13, 0), (0.05, 0.02, 0.05), BRASS)
    make_cube('Buckle_R', ( 0.18, -0.13, 0), (0.05, 0.02, 0.05), BRASS)
    # Padded shoulders
    make_cube('Shoulder_L', (-0.20, 0, 0.18), (0.10, 0.16, 0.06), TAN_LEATHER)
    make_cube('Shoulder_R', ( 0.20, 0, 0.18), (0.10, 0.16, 0.06), TAN_LEATHER)

def bogiron_cuirass():
    # Hand-forged plate breastplate
    make_cube('Front', (0, -0.10, 0.05), (0.40, 0.05, 0.45), BOGIRON)
    make_cube('Back', (0, 0.10, 0.05), (0.36, 0.05, 0.45), BOGIRON)
    # Verdigris on seams
    make_cube('Seam_L', (-0.20, 0, 0), (0.02, 0.20, 0.40), VERDIGRIS)
    make_cube('Seam_R', ( 0.20, 0, 0), (0.02, 0.20, 0.40), VERDIGRIS)
    # Riveted shoulder straps
    make_cube('Strap_L', (-0.20, -0.05, 0.22), (0.10, 0.10, 0.06), DARK_OAK)
    make_cube('Strap_R', ( 0.20, -0.05, 0.22), (0.10, 0.10, 0.06), DARK_OAK)
    # Copper buckles
    make_cube('Buckle_L', (-0.20, -0.13, 0.22), (0.05, 0.02, 0.04), COPPER)
    make_cube('Buckle_R', ( 0.20, -0.13, 0.22), (0.05, 0.02, 0.04), COPPER)
    # Hammered moss-bramble crest at chest
    make_cube('Crest', (0, -0.13, 0.10), (0.10, 0.02, 0.10), MOSS_GREEN)

def cinderbloom_plate():
    # Dark steel plate with pink ember rose-vine
    make_cube('Front', (0, -0.10, 0.05), (0.42, 0.05, 0.45), CINDER_DARK)
    make_cube('Back', (0, 0.10, 0.05), (0.36, 0.05, 0.45), CINDER_DARK)
    # Glowing ember-vein engravings (vertical slashes)
    make_cube('Vein_C', (0, -0.13, 0.05), (0.02, 0.02, 0.40), EMBER_PINK, EMBER_PINK, 2.0)
    make_cube('Vein_L', (-0.10, -0.13, 0.05), (0.02, 0.02, 0.30), EMBER_PINK, EMBER_PINK, 2.0)
    make_cube('Vein_R', ( 0.10, -0.13, 0.05), (0.02, 0.02, 0.30), EMBER_PINK, EMBER_PINK, 2.0)
    # Gold trim collar + cuffs
    make_cube('Collar', (0, -0.13, 0.27), (0.32, 0.02, 0.04), GOLD)
    # Deep red leather straps
    make_cube('Strap_L', (-0.21, -0.05, 0.22), (0.06, 0.10, 0.06), DEEP_RED)
    make_cube('Strap_R', ( 0.21, -0.05, 0.22), (0.06, 0.10, 0.06), DEEP_RED)
    # Gold buckles
    make_cube('Buckle_L', (-0.21, -0.13, 0.22), (0.04, 0.02, 0.04), GOLD)
    make_cube('Buckle_R', ( 0.21, -0.13, 0.22), (0.04, 0.02, 0.04), GOLD)

def cinderbloom_helm():
    # Close helm with sweeping gold flame crest
    make_cube('Skull', (0, 0, 0.08), (0.30, 0.30, 0.28), CINDER_DARK)
    # Brow line ember
    make_cube('Brow', (0, -0.13, 0.18), (0.26, 0.02, 0.02), EMBER_PINK, EMBER_PINK, 2.0)
    # Visor slit
    make_cube('Visor', (0, -0.16, 0.10), (0.18, 0.02, 0.04), (0.04, 0.04, 0.04))
    # Cheek guards w/ gold trim
    make_cube('Cheek_L', (-0.14, -0.10, 0.02), (0.04, 0.04, 0.10), GOLD)
    make_cube('Cheek_R', ( 0.14, -0.10, 0.02), (0.04, 0.04, 0.10), GOLD)
    # Sweeping gold flame crest on top
    make_cube('Crest_a', (0, 0.04, 0.30), (0.06, 0.16, 0.10), GOLD)
    make_cube('Crest_b', (0, 0.10, 0.36), (0.04, 0.10, 0.08), GOLD)
    make_cube('Crest_c', (0, 0.16, 0.40), (0.04, 0.06, 0.06), GOLD)
    # Deep red inner padding visible at neck
    make_cube('Padding', (0, 0.05, -0.10), (0.20, 0.18, 0.06), DEEP_RED)

# Run all 7
for slug, fn in [
    ('shield_wooden', wooden_shield),
    ('shield_bogiron', bogiron_shield),
    ('shield_cinderbloom', cinderbloom_shield),
    ('armor_leather', leather_body),
    ('armor_bogiron_cuirass', bogiron_cuirass),
    ('armor_cinderbloom_plate', cinderbloom_plate),
    ('armor_cinderbloom_helm', cinderbloom_helm),
]:
    build_one(slug, fn)

print("All 7 shields + armor exported.")
