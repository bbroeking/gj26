"""Build all 12 Tier 3 weapons as drop-in 3D inventory items.
Brindle / Bogiron / Cinderbloom × Sword / Axe / Dagger / Pickaxe.
"""
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

# Palettes by tier
BRINDLE_BLADE = (0.78, 0.62, 0.34)
BRINDLE_DARK  = (0.58, 0.45, 0.22)
OAK           = (0.46, 0.32, 0.18)
CREAM_LEATHER = (0.86, 0.78, 0.62)
BRASS         = (0.78, 0.58, 0.18)

BOGIRON_BLADE = (0.42, 0.32, 0.22)
BOGIRON_DARK  = (0.30, 0.24, 0.18)
DARK_LEATHER  = (0.30, 0.20, 0.13)
COPPER        = (0.72, 0.42, 0.20)

CINDER_BLADE  = (0.20, 0.18, 0.20)
CINDER_DARK   = (0.10, 0.10, 0.10)
EMBER_PINK    = (0.95, 0.45, 0.55)
GOLD_TIER     = (0.86, 0.72, 0.30)
DEEP_RED      = (0.50, 0.18, 0.18)

# === BRINDLE ===
def brindle_sword():
    make_cube('Blade', (0, 0, 0.30), (0.06, 0.02, 0.50), BRINDLE_BLADE)
    make_cube('Crossguard', (0, 0, 0.04), (0.20, 0.04, 0.04), OAK)
    make_cube('Grip', (0, 0, -0.10), (0.04, 0.04, 0.20), CREAM_LEATHER)
    make_cube('Pommel', (0, 0, -0.22), (0.06, 0.06, 0.04), BRASS)
    # Leaf sigil
    make_cube('Leaf_sigil', (0, 0.05, -0.22), (0.03, 0.01, 0.03), (0.40, 0.55, 0.22))

def brindle_axe():
    make_cube('Head', (0.08, 0, 0.30), (0.18, 0.04, 0.18), BRINDLE_BLADE)
    make_cube('Head_dark', (-0.05, 0, 0.30), (0.06, 0.04, 0.16), BRINDLE_DARK)
    make_cube('Haft', (0, 0, 0.05), (0.05, 0.05, 0.50), OAK)
    make_cube('Grip_wrap', (0, 0, -0.10), (0.06, 0.06, 0.16), CREAM_LEATHER)
    make_cube('Butt_cap', (0, 0, -0.21), (0.05, 0.05, 0.04), BRASS)

def brindle_dagger():
    make_cube('Blade', (0, 0, 0.20), (0.04, 0.02, 0.30), BRINDLE_BLADE)
    make_cube('Crossguard', (0, 0, 0.04), (0.14, 0.04, 0.03), OAK)
    make_cube('Grip', (0, 0, -0.06), (0.03, 0.03, 0.14), CREAM_LEATHER)
    make_cube('Pommel', (0, 0, -0.15), (0.05, 0.05, 0.03), BRASS)

def brindle_pickaxe():
    make_cube('Pick_head', (0, 0, 0.30), (0.30, 0.05, 0.06), BRINDLE_BLADE)
    make_cube('Pick_point_L', (-0.18, 0, 0.32), (0.06, 0.04, 0.04), BRINDLE_DARK)
    make_cube('Haft', (0, 0, 0.05), (0.05, 0.05, 0.50), OAK)
    make_cube('Grip_wrap', (0, 0, -0.10), (0.06, 0.06, 0.16), CREAM_LEATHER)
    make_cube('Butt_cap', (0, 0, -0.21), (0.05, 0.05, 0.04), BRASS)

# === BOGIRON ===
def bogiron_sword():
    make_cube('Blade', (0, 0, 0.30), (0.06, 0.02, 0.50), BOGIRON_BLADE)
    make_cube('Crossguard', (0, 0, 0.04), (0.20, 0.04, 0.04), BOGIRON_DARK)
    make_cube('Grip', (0, 0, -0.10), (0.04, 0.04, 0.20), DARK_LEATHER)
    make_cube('Pommel', (0, 0, -0.22), (0.06, 0.06, 0.04), COPPER)

def bogiron_axe():
    make_cube('Head', (0.08, 0, 0.30), (0.18, 0.04, 0.18), BOGIRON_BLADE)
    make_cube('Head_moss', (0.08, 0, 0.30), (0.04, 0.05, 0.16), (0.30, 0.42, 0.20))
    make_cube('Haft', (0, 0, 0.05), (0.05, 0.05, 0.50), OAK)
    make_cube('Band_top', (0, 0, 0.20), (0.06, 0.06, 0.04), COPPER)
    make_cube('Band_bot', (0, 0, -0.10), (0.06, 0.06, 0.04), COPPER)
    make_cube('Grip_wrap', (0, 0, -0.04), (0.06, 0.06, 0.14), DARK_LEATHER)

def bogiron_dagger():
    make_cube('Blade', (0, 0, 0.18), (0.05, 0.02, 0.26), BOGIRON_BLADE)
    make_cube('Crossguard', (0, 0, 0.04), (0.14, 0.04, 0.03), OAK)
    make_cube('Grip', (0, 0, -0.06), (0.03, 0.03, 0.14), DARK_LEATHER)
    make_cube('Pommel', (0, 0, -0.15), (0.05, 0.05, 0.03), COPPER)

def bogiron_pickaxe():
    make_cube('Pick_head', (0, 0, 0.30), (0.32, 0.06, 0.07), BOGIRON_BLADE)
    make_cube('Pick_moss', (0, 0, 0.30), (0.04, 0.04, 0.05), (0.30, 0.42, 0.20))
    make_cube('Haft', (0, 0, 0.05), (0.05, 0.05, 0.50), OAK)
    make_cube('Band_top', (0, 0, 0.20), (0.06, 0.06, 0.04), COPPER)
    make_cube('Band_bot', (0, 0, -0.10), (0.06, 0.06, 0.04), COPPER)
    make_cube('Grip_wrap', (0, 0, -0.04), (0.06, 0.06, 0.14), DARK_LEATHER)

# === CINDERBLOOM ===
def cinder_sword():
    make_cube('Blade', (0, 0, 0.30), (0.06, 0.02, 0.50), CINDER_BLADE)
    # Glowing pink ember-line in fuller
    make_cube('Ember_line', (0, 0, 0.30), (0.015, 0.025, 0.46), EMBER_PINK, EMBER_PINK, 2.0)
    make_cube('Crossguard', (0, 0, 0.04), (0.22, 0.04, 0.04), CINDER_DARK)
    make_cube('Grip', (0, 0, -0.10), (0.04, 0.04, 0.20), DEEP_RED)
    make_cube('Pommel', (0, 0, -0.22), (0.06, 0.06, 0.06), GOLD_TIER)

def cinder_axe():
    make_cube('Head', (0.08, 0, 0.30), (0.20, 0.04, 0.20), CINDER_BLADE)
    make_cube('Ember_edge', (0.16, 0, 0.30), (0.04, 0.05, 0.18), EMBER_PINK, EMBER_PINK, 2.0)
    make_cube('Haft', (0, 0, 0.05), (0.05, 0.05, 0.50), CINDER_DARK)
    make_cube('Gold_band', (0, 0, -0.04), (0.06, 0.06, 0.05), GOLD_TIER)
    make_cube('Grip_wrap', (0, 0, -0.12), (0.06, 0.06, 0.12), DEEP_RED)

def cinder_dagger():
    make_cube('Blade', (0, 0, 0.18), (0.05, 0.02, 0.26), CINDER_BLADE)
    make_cube('Ember_edge', (0.025, 0, 0.18), (0.01, 0.02, 0.24), EMBER_PINK, EMBER_PINK, 2.0)
    make_cube('Crossguard', (0, 0, 0.04), (0.14, 0.04, 0.03), CINDER_DARK)
    make_cube('Grip', (0, 0, -0.06), (0.03, 0.03, 0.14), DEEP_RED)
    make_cube('Pommel', (0, 0, -0.15), (0.05, 0.05, 0.04), GOLD_TIER)

def cinder_pickaxe():
    make_cube('Pick_head', (0, 0, 0.30), (0.32, 0.06, 0.07), CINDER_BLADE)
    make_cube('Ember_top', (0.16, 0, 0.30), (0.04, 0.04, 0.04), EMBER_PINK, EMBER_PINK, 2.0)
    make_cube('Ember_bot', (-0.16, 0, 0.30), (0.04, 0.04, 0.04), EMBER_PINK, EMBER_PINK, 2.0)
    make_cube('Haft', (0, 0, 0.05), (0.05, 0.05, 0.50), CINDER_DARK)
    make_cube('Gold_band', (0, 0, -0.04), (0.06, 0.06, 0.05), GOLD_TIER)
    make_cube('Grip_wrap', (0, 0, -0.12), (0.06, 0.06, 0.12), DEEP_RED)

# Run all 12
for slug, fn in [
    ('weapon_brindle_sword', brindle_sword),
    ('weapon_brindle_axe', brindle_axe),
    ('weapon_brindle_dagger', brindle_dagger),
    ('weapon_brindle_pickaxe', brindle_pickaxe),
    ('weapon_bogiron_sword', bogiron_sword),
    ('weapon_bogiron_axe', bogiron_axe),
    ('weapon_bogiron_dagger', bogiron_dagger),
    ('weapon_bogiron_pickaxe', bogiron_pickaxe),
    ('weapon_cinderbloom_sword', cinder_sword),
    ('weapon_cinderbloom_axe', cinder_axe),
    ('weapon_cinderbloom_dagger', cinder_dagger),
    ('weapon_cinderbloom_pickaxe', cinder_pickaxe),
]:
    build_one(slug, fn)

print("All 12 weapons exported.")
