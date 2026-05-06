"""Onywyn v2 — seventh proof of the head-height anchor template.

Mother Onywyn — the briar-witch. Ancient, hunched, talks to her raven,
brews bitter draughts. Built fresh on the head-height template at
H=0.32, archetype='npc'. Stoop is achieved via a forward Y-offset on
the torso (same trick as Eldra v2).

Aux parts via sockets — first model to use socket_back for a creature
companion (raven perches between the shoulder blades):
  - White-wisp hair        → socket_helmet_top
  - Foxglove sprigs        → socket_hand_L      (held in left hand)
  - Mortar + pestle / herb jars → socket_belt_front
  - Raven (Hen)            → socket_back        (perches with head turned)
  - Walking staff          → socket_hand_R

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_npc_onywyn_v2.py

Output: models/npc_onywyn_v2.glb
"""
import sys, os
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__) + '/..'))

import bpy
from scripts._build_lib import (
    reset_scene, make_cube, rig_biped, biped_parent_for,
    apply_bevel_remove_doubles, export_glb,
)
from scripts.blender.template import (
    anchor_skeleton, biped_pivots_only,
    materialise_sockets, attach_to_socket,
)

# ---- design knobs ------------------------------------------------------
H         = 0.32
ARCHETYPE = 'npc'

# Onywyn palette — preserved from v1.
DARK_LINEN   = (0.28, 0.26, 0.22)
FOREST_GREEN = (0.18, 0.30, 0.18)
DARK_GREEN   = (0.10, 0.18, 0.10)
PURPLE_SHAWL = (0.32, 0.22, 0.40)        # deep purple top-shawl
RAVEN        = (0.05, 0.05, 0.05)
RAVEN_BEAK   = (0.55, 0.42, 0.18)
RAVEN_EYE    = (0.85, 0.65, 0.20)
FOXGLOVE     = (0.62, 0.40, 0.65)
HERB         = (0.40, 0.50, 0.22)
GLASS        = (0.65, 0.78, 0.85)
WOOD         = (0.32, 0.22, 0.14)
SKIN         = (0.85, 0.72, 0.58)
GREY_HAIR    = (0.65, 0.62, 0.55)
EYE_DARK     = (0.10, 0.18, 0.08)
LINE_TAN     = (0.65, 0.55, 0.42)

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(2.0, -2.0, 1.0), cam_target=(0, 0, H * 1.5))

rig   = anchor_skeleton(H, ARCHETYPE)
biped = biped_pivots_only(rig)

# --- TORSO (subdivided: shawl top, cloak chest, cloak mid, cloak waist) ---
body_z = biped['Body'][2]
make_cube('Body_torso',
          (0, -0.18 * H, body_z),
          (1.20 * H, 0.95 * H, 1.20 * H), DARK_LINEN)
# Cloak — three vertical stacked panels for fold lines.
make_cube('Body_cloak_upper',
          (0, 0.05 * H, body_z + 0.30 * H),
          (1.55 * H, 1.20 * H, 0.50 * H), FOREST_GREEN)
make_cube('Body_cloak_mid',
          (0, 0.05 * H, body_z - 0.20 * H),
          (1.55 * H, 1.20 * H, 0.50 * H), (0.14, 0.24, 0.14))   # darker
make_cube('Body_cloak_lower',
          (0, 0.05 * H, body_z - 0.65 * H),
          (1.55 * H, 1.20 * H, 0.40 * H), FOREST_GREEN)
# Lower cloak hem in darker green.
hem_z = (biped['Leg_L'][2] + biped['Body'][2]) * 0.5 - 0.20 * H
make_cube('Body_cloak_hem',
          (0, 0.04 * H, hem_z),
          (1.55 * H, 1.20 * H, 0.30 * H), DARK_GREEN)
# Purple shawl across the upper torso — Onywyn's signature.
make_cube('Body_shawl',
          (0, -0.10 * H, body_z + 0.55 * H),
          (1.65 * H, 1.10 * H, 0.40 * H), PURPLE_SHAWL)
# Shawl tassels — darker drips of fringe.
for i, sx in enumerate((-0.55, -0.20, 0.20, 0.55)):
    make_cube(f'Body_shawl_tassel_{i}',
              (sx * H, -0.55 * H, body_z + 0.30 * H),
              (0.10 * H, 0.06 * H, 0.18 * H), (0.20, 0.14, 0.28))

# --- HEAD + FACE ---
make_cube('Head_skull',
          (0, -0.05 * H, biped['Head'][2]),
          (0.95 * H, 0.95 * H, 0.95 * H), SKIN)

# Gaunt jaw — pointed.
make_cube('Head_jaw',
          (0, -0.15 * H, biped['Head'][2] - 0.45 * H),
          (0.70 * H, 0.80 * H, 0.20 * H), SKIN)

# Ears.
for sx, name in ((-0.55, 'Head_ear_L'), (0.55, 'Head_ear_R')):
    make_cube(name, (sx * H, 0, biped['Head'][2]),
              (0.12 * H, 0.20 * H, 0.25 * H), SKIN)

# Hooked nose.
make_cube('Head_nose',
          (0, -0.58 * H, biped['Head'][2] - 0.05 * H),
          (0.14 * H, 0.20 * H, 0.22 * H), SKIN)

# Sharp brows — narrow, expressive.
for sx, name in ((-0.22, 'Head_brow_L'), (0.22, 'Head_brow_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] + 0.18 * H),
              (0.22 * H, 0.06 * H, 0.06 * H), GREY_HAIR)

# Sharp eyes — small + glittery green.
eye_y = -0.56 * H
eye_z = biped['Head'][2] + 0.05 * H
for sx, name in ((-0.22, 'Head_eye_L'), (0.22, 'Head_eye_R')):
    make_cube(name, (sx * H, eye_y, eye_z),
              (0.12 * H, 0.04 * H, 0.06 * H), EYE_DARK)

# Crow's-foot lines at temple — readability cue for "ancient".
for sx, name in ((-0.40, 'Head_lines_L'), (0.40, 'Head_lines_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] + 0.05 * H),
              (0.18 * H, 0.04 * H, 0.06 * H), LINE_TAN)

# Thin mouth — pursed.
make_cube('Head_mouth',
          (0, -0.51 * H, biped['Head'][2] - 0.28 * H),
          (0.18 * H, 0.04 * H, 0.04 * H), (0.40, 0.22, 0.18))

# Arms — forest-green sleeves.
for side, name in ((-1, 'Arm_L'), (1, 'Arm_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.65 * H),
              (0.45 * H, 0.50 * H, 1.30 * H), FOREST_GREEN)

# Legs (under cloak — mostly hidden) + dark wood-soled boots.
for side, name in ((-1, 'Leg_L'), (1, 'Leg_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.75 * H),
              (0.55 * H, 0.65 * H, 1.45 * H), DARK_LINEN)
    make_cube(f'{name}_boot',
              (pivot[0], pivot[1] - 0.05 * H, pivot[2] - 1.50 * H),
              (0.62 * H, 0.85 * H, 0.30 * H), WOOD)

# ---- rig + sockets ----------------------------------------------------
root, empties, mesh_objs = rig_biped(biped, 'Onywyn_v2_Root', biped_parent_for)
sockets = materialise_sockets(rig, empties)

# ---- aux parts pinned to sockets --------------------------------------

# White-wisp hair under a hood — straggly grey strands at the temples
# plus a fold of cloth on the crown.
attach_to_socket(
    make_cube('Aux_hood_top', (0, 0.05 * H, biped['Head'][2] + 0.55 * H),
              (1.20 * H, 1.05 * H, 0.40 * H), FOREST_GREEN),
    sockets['socket_helmet_top'],
)
attach_to_socket(
    make_cube('Aux_hair_L', (-0.45 * H, -0.10 * H, biped['Head'][2] + 0.10 * H),
              (0.20 * H, 0.30 * H, 0.55 * H), GREY_HAIR),
    sockets['socket_helmet_top'],
)
attach_to_socket(
    make_cube('Aux_hair_R', (0.45 * H, -0.10 * H, biped['Head'][2] + 0.10 * H),
              (0.20 * H, 0.30 * H, 0.55 * H), GREY_HAIR),
    sockets['socket_helmet_top'],
)

# Foxglove sprig — held in the left hand. Stem + 3 magenta bell flowers
# at varying heights so it reads as a wildflower bunch, not a single block.
fox_x = biped['Arm_L'][0] - 0.10 * H
fox_z = biped['Arm_L'][2] - 0.85 * H
attach_to_socket(
    make_cube('Aux_foxglove_stem', (fox_x, -0.30 * H, fox_z + 0.10 * H),
              (0.06 * H, 0.06 * H, 0.55 * H), HERB),
    sockets['socket_hand_L'],
)
for i, dz in enumerate([0.20, 0.40, 0.55]):
    attach_to_socket(
        make_cube(f'Aux_foxglove_bell_{i}',
                  (fox_x + (i - 1) * 0.05 * H, -0.40 * H, fox_z + dz),
                  (0.20 * H, 0.15 * H, 0.18 * H), FOXGLOVE),
        sockets['socket_hand_L'],
    )

# Belt + herb jars — three glass vials with green herb inside, hung at
# the belt-front. socket_belt_front is forward of centre, so the jars
# read as "tied to the front of her belt" not "buried in cloak".
attach_to_socket(
    make_cube('Aux_belt', (0, -0.55 * H, biped['Body'][2] - 0.45 * H),
              (1.40 * H, 0.10 * H, 0.18 * H), WOOD),
    sockets['socket_belt_front'],
)
for i, sx in enumerate((-0.55, 0, 0.55)):
    attach_to_socket(
        make_cube(f'Aux_jar_{i}',
                  (sx * H, -0.62 * H, biped['Body'][2] - 0.55 * H),
                  (0.20 * H, 0.20 * H, 0.30 * H), GLASS),
        sockets['socket_belt_front'],
    )
    attach_to_socket(
        make_cube(f'Aux_jar_herb_{i}',
                  (sx * H, -0.62 * H, biped['Body'][2] - 0.50 * H),
                  (0.14 * H, 0.14 * H, 0.18 * H), HERB),
        sockets['socket_belt_front'],
    )

# Mortar + pestle slung at the side. Stone bowl + wooden grinder
# protruding upward.
attach_to_socket(
    make_cube('Aux_mortar', (-0.70 * H, -0.45 * H, biped['Body'][2] - 0.30 * H),
              (0.30 * H, 0.30 * H, 0.20 * H), (0.55, 0.50, 0.45)),
    sockets['socket_belt_front'],
)
attach_to_socket(
    make_cube('Aux_pestle', (-0.70 * H, -0.45 * H, biped['Body'][2] - 0.10 * H),
              (0.06 * H, 0.06 * H, 0.30 * H), WOOD),
    sockets['socket_belt_front'],
)

# Raven companion (Hen) — perches on the back, between the shoulder
# blades. socket_back sits behind the body, so the raven body + head +
# beak + eye all rotate together when the body moves. Head turned to
# face left, looking sideways at the player.
raven_z = biped['Body'][2] + 0.55 * H
attach_to_socket(
    make_cube('Aux_raven_body', (0, 0.55 * H, raven_z),
              (0.45 * H, 0.50 * H, 0.45 * H), RAVEN),
    sockets['socket_back'],
)
attach_to_socket(
    make_cube('Aux_raven_head', (-0.20 * H, 0.45 * H, raven_z + 0.30 * H),
              (0.30 * H, 0.30 * H, 0.30 * H), RAVEN),
    sockets['socket_back'],
)
attach_to_socket(
    make_cube('Aux_raven_beak', (-0.40 * H, 0.45 * H, raven_z + 0.30 * H),
              (0.16 * H, 0.10 * H, 0.10 * H), RAVEN_BEAK),
    sockets['socket_back'],
)
attach_to_socket(
    make_cube('Aux_raven_eye', (-0.18 * H, 0.32 * H, raven_z + 0.35 * H),
              (0.06 * H, 0.06 * H, 0.06 * H), RAVEN_EYE),
    sockets['socket_back'],
)

# Weathered walking staff — gnarled wood in the right hand.
staff_grip_x = biped['Arm_R'][0] + 0.20 * H
staff_grip_z = biped['Arm_R'][2] - 1.00 * H
staff_top_z  = biped['Arm_R'][2] + 1.10 * H
attach_to_socket(
    make_cube('Aux_staff',
              (staff_grip_x, -0.20 * H, (staff_grip_z + staff_top_z) / 2),
              (0.18 * H, 0.18 * H, abs(staff_top_z - staff_grip_z)), WOOD),
    sockets['socket_hand_R'],
)

# ---- finalise ---------------------------------------------------------
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
apply_bevel_remove_doubles(all_meshes)

out = os.path.abspath(os.path.dirname(__file__) + '/../models/npc_onywyn_v2.glb')
export_glb(root, out)
print(f"npc_onywyn_v2 — H={H}, archetype={ARCHETYPE}, total height "
      f"{3 * H:.3f}m, sockets={len(sockets)}")
