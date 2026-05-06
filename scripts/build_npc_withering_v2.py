"""Withering v2 — ninth proof of the head-height anchor template.

Sir Withering of Trelliswick — retired knight, eccentric, builder of the
folly tower, teacher of Falconry. Dignified but worn. Has a falcon named
Linnet perched on his left arm. Built fresh on the head-height template
at H=0.34 (parallel to Hod — both are notable taller-than-average village
figures), archetype='npc'.

This is the second model to put a creature companion on the rig (after
Onywyn's raven on socket_back). Linnet rides socket_hand_L so the falcon
turns with the arm when Withering gestures or animates a fly-off.

Aux parts via sockets:
  - Steel coronet (modest circlet)  → socket_helmet_top
  - Long grey beard                  → socket_chin
  - Heavy falconer's gauntlet        → socket_hand_L (forearm)
  - Linnet (falcon, perched)         → socket_hand_L (rides on the glove)
  - Dress sabre on hip               → socket_belt_front
  - Cape mantle                      → socket_back

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_npc_withering_v2.py

Output: models/npc_withering_v2.glb
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
H         = 0.34         # slightly larger — Withering is tall and gaunt
ARCHETYPE = 'npc'        # 3 heads tall

# Withering palette — retired-knight dignity, military-burgundy + steel.
BURGUNDY      = (0.42, 0.18, 0.18)        # main coat colour
BURGUNDY_DARK = (0.30, 0.12, 0.12)        # coat trim / hem
GOLD_TRIM     = (0.78, 0.62, 0.28)        # frogging / coronet
STEEL         = (0.62, 0.64, 0.68)        # coronet, sabre blade
STEEL_DARK    = (0.34, 0.36, 0.40)        # gauntlet plates
LEATHER_BR    = (0.30, 0.20, 0.12)        # gauntlet base + sabre grip
SKIN          = (0.86, 0.72, 0.58)        # weathered tan
HAIR_GREY     = (0.72, 0.70, 0.66)        # silvering
BEARD_GREY    = (0.78, 0.76, 0.72)        # full grey beard
EYE_DARK      = (0.10, 0.08, 0.06)
BOOT_DARK     = (0.18, 0.14, 0.10)
CAPE_BURG     = (0.32, 0.14, 0.14)        # darker than the coat
LINE_TAN      = (0.55, 0.45, 0.35)        # weathering lines

# Linnet — russet-and-cream falcon, dark wing tips.
FALCON_BREAST = (0.92, 0.84, 0.68)        # cream chest
FALCON_BODY   = (0.55, 0.32, 0.20)        # russet back/wings
FALCON_TIP    = (0.18, 0.12, 0.10)        # dark wing tips + crown
FALCON_BEAK   = (0.85, 0.62, 0.20)        # yellow-orange beak
FALCON_EYE    = (0.10, 0.08, 0.06)        # dark glittering eye

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(2.2, -2.2, 1.1), cam_target=(0, 0, H * 1.6))

rig   = anchor_skeleton(H, ARCHETYPE)
biped = biped_pivots_only(rig)

# --- TORSO (military coat: shoulders, lapels, buttons, belt, skirt) ---
body_z = biped['Body'][2]
chest_z   = body_z + 0.45 * H
midriff_z = body_z + 0.00 * H
belt_z    = body_z - 0.40 * H
waist_z   = body_z - 0.65 * H
make_cube('Body_chest',   (0, 0, chest_z),
          (1.35 * H, 1.00 * H, 0.50 * H), BURGUNDY)
make_cube('Body_midriff', (0, 0, midriff_z),
          (1.30 * H, 0.98 * H, 0.45 * H), BURGUNDY_DARK)
make_cube('Body_belt',    (0, 0, belt_z),
          (1.40 * H, 1.04 * H, 0.18 * H), LEATHER_BR)
make_cube('Body_skirt',   (0, 0, waist_z),
          (1.40 * H, 1.05 * H, 0.30 * H), BURGUNDY)
# Lapels — gold-trimmed V at the chest.
for sx, name in ((-0.30, 'Body_lapel_L'), (0.30, 'Body_lapel_R')):
    make_cube(name, (sx * H, -0.55 * H, chest_z),
              (0.22 * H, 0.10 * H, 0.55 * H), GOLD_TRIM)
# Gold frogging / button line — 5 individual gold buttons down the chest.
for i, dz in enumerate((0.55, 0.30, 0.05, -0.20, -0.45)):
    make_cube(f'Body_button_{i}',
              (0, -0.56 * H, body_z + dz * H),
              (0.10 * H, 0.05 * H, 0.10 * H), GOLD_TRIM)
# Cassock-style trim band where the coat meets the legs.
trim_z = (biped['Leg_L'][2] + biped['Body'][2]) * 0.5 + 0.05 * H
make_cube('Body_trim', (0, 0, trim_z),
          (1.42 * H, 1.05 * H, 0.16 * H), BURGUNDY_DARK)
# Cream collar at the throat.
make_cube('Body_collar',
          (0, -0.50 * H, body_z + 0.85 * H),
          (1.10 * H, 0.10 * H, 0.16 * H), (0.92, 0.86, 0.72))

# --- HEAD + FACE (gaunt, dignified, hawkish) ---
make_cube('Head_skull', biped['Head'],
          (1.0 * H, 0.95 * H, 0.95 * H), SKIN)

# Strong jaw.
make_cube('Head_jaw',
          (0, -0.10 * H, biped['Head'][2] - 0.45 * H),
          (0.82 * H, 0.85 * H, 0.22 * H), SKIN)

# Ears.
for sx, name in ((-0.55, 'Head_ear_L'), (0.55, 'Head_ear_R')):
    make_cube(name, (sx * H, 0, biped['Head'][2]),
              (0.12 * H, 0.22 * H, 0.28 * H), SKIN)

# Aquiline nose — tall, prominent.
make_cube('Head_nose',
          (0, -0.56 * H, biped['Head'][2] - 0.05 * H),
          (0.16 * H, 0.20 * H, 0.26 * H), SKIN)

# Stern brows — heavy grey.
for sx, name in ((-0.22, 'Head_brow_L'), (0.22, 'Head_brow_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] + 0.18 * H),
              (0.24 * H, 0.06 * H, 0.08 * H), HAIR_GREY)

# Sharp eyes — narrow, slightly hawkish.
eye_y = -0.51 * H
eye_z = biped['Head'][2] + 0.05 * H
for sx, name in ((-0.22, 'Head_eye_L'), (0.22, 'Head_eye_R')):
    make_cube(name, (sx * H, eye_y, eye_z),
              (0.14 * H, 0.04 * H, 0.06 * H), EYE_DARK)

# Crow's-foot wrinkles at the temples — mark of age.
for sx, name in ((-0.40, 'Head_lines_L'), (0.40, 'Head_lines_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] + 0.05 * H),
              (0.18 * H, 0.04 * H, 0.06 * H), LINE_TAN)

# Mouth — firm, slight downturn.
make_cube('Head_mouth',
          (0, -0.51 * H, biped['Head'][2] - 0.30 * H),
          (0.24 * H, 0.04 * H, 0.04 * H), (0.40, 0.22, 0.18))

# Greying-back temple hair — visible at the sides under the coronet.
for sx, name in ((-0.45, 'Head_temple_L'), (0.45, 'Head_temple_R')):
    make_cube(name, (sx * H, 0, biped['Head'][2] + 0.20 * H),
              (0.20 * H, 0.50 * H, 0.45 * H), HAIR_GREY)

# Arms — burgundy coat sleeves with gold cuffs.
for side, name in ((-1, 'Arm_L'), (1, 'Arm_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.65 * H),
              (0.50 * H, 0.55 * H, 1.30 * H), BURGUNDY)
    # Gold cuff at the wrist.
    make_cube(f'{name}_cuff',
              (pivot[0], pivot[1], pivot[2] - 1.30 * H),
              (0.55 * H, 0.60 * H, 0.16 * H), GOLD_TRIM)

# Legs — dark trousers + tall riding boots.
for side, name in ((-1, 'Leg_L'), (1, 'Leg_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.75 * H),
              (0.55 * H, 0.65 * H, 1.45 * H), BURGUNDY_DARK)
    make_cube(f'{name}_boot',
              (pivot[0], pivot[1] - 0.05 * H, pivot[2] - 1.50 * H),
              (0.62 * H, 0.95 * H, 0.55 * H), BOOT_DARK)

# ---- rig + sockets ----------------------------------------------------
root, empties, mesh_objs = rig_biped(biped, 'Withering_v2_Root', biped_parent_for)
sockets = materialise_sockets(rig, empties)

# ---- aux parts pinned to sockets --------------------------------------

# Steel coronet — a thin circlet, not a full helm. Withering is retired;
# the band signals "knight" without "still on duty".
attach_to_socket(
    make_cube('Aux_coronet_band', (0, 0, biped['Head'][2] + 0.45 * H),
              (1.10 * H, 1.05 * H, 0.18 * H), STEEL),
    sockets['socket_helmet_top'],
)
# Gold inlay on the coronet front.
attach_to_socket(
    make_cube('Aux_coronet_jewel',
              (0, -0.50 * H, biped['Head'][2] + 0.45 * H),
              (0.30 * H, 0.10 * H, 0.20 * H), GOLD_TRIM),
    sockets['socket_helmet_top'],
)

# Long grey beard — full chest-length, slightly forked at the bottom.
attach_to_socket(
    make_cube('Aux_beard_main',
              (0, -0.40 * H, biped['Head'][2] - 0.55 * H),
              (0.85 * H, 0.40 * H, 0.65 * H), BEARD_GREY),
    sockets['socket_chin'],
)
# Beard-fork tail.
attach_to_socket(
    make_cube('Aux_beard_fork',
              (0, -0.45 * H, biped['Head'][2] - 1.00 * H),
              (0.50 * H, 0.30 * H, 0.40 * H), BEARD_GREY),
    sockets['socket_chin'],
)
# Mustache strands.
attach_to_socket(
    make_cube('Aux_mustache_L',
              (-0.20 * H, -0.50 * H, biped['Head'][2] - 0.30 * H),
              (0.22 * H, 0.10 * H, 0.16 * H), BEARD_GREY),
    sockets['socket_chin'],
)
attach_to_socket(
    make_cube('Aux_mustache_R',
              (0.20 * H, -0.50 * H, biped['Head'][2] - 0.30 * H),
              (0.22 * H, 0.10 * H, 0.16 * H), BEARD_GREY),
    sockets['socket_chin'],
)

# Heavy falconer's gauntlet on the left forearm. Larger than the regular
# coat-sleeve cuff — read as "thick leather + steel plates strapped on".
gauntlet_x = biped['Arm_L'][0]
gauntlet_z = biped['Arm_L'][2] - 1.15 * H
attach_to_socket(
    make_cube('Aux_gauntlet_leather',
              (gauntlet_x, -0.10 * H, gauntlet_z),
              (0.70 * H, 0.75 * H, 0.55 * H), LEATHER_BR),
    sockets['socket_hand_L'],
)
# Steel plate on the back of the gauntlet.
attach_to_socket(
    make_cube('Aux_gauntlet_plate',
              (gauntlet_x, 0.20 * H, gauntlet_z + 0.10 * H),
              (0.55 * H, 0.18 * H, 0.40 * H), STEEL_DARK),
    sockets['socket_hand_L'],
)

# Linnet the falcon — perched on the gauntlet. Body + head + cream breast
# + russet wings + dark wing-tips + yellow beak + dark eye. All on
# socket_hand_L so she rides the gauntlet through any animation.
falcon_z = gauntlet_z + 0.70 * H        # perched on top of the gauntlet
falcon_x = gauntlet_x
attach_to_socket(
    make_cube('Aux_falcon_body',
              (falcon_x, -0.10 * H, falcon_z),
              (0.40 * H, 0.55 * H, 0.55 * H), FALCON_BODY),
    sockets['socket_hand_L'],
)
# Cream breast at the front.
attach_to_socket(
    make_cube('Aux_falcon_breast',
              (falcon_x, -0.30 * H, falcon_z),
              (0.38 * H, 0.18 * H, 0.45 * H), FALCON_BREAST),
    sockets['socket_hand_L'],
)
# Folded wings — slightly behind body, dark tips at trailing edge.
attach_to_socket(
    make_cube('Aux_falcon_wing_L',
              (falcon_x - 0.18 * H, -0.05 * H, falcon_z),
              (0.10 * H, 0.50 * H, 0.40 * H), FALCON_BODY),
    sockets['socket_hand_L'],
)
attach_to_socket(
    make_cube('Aux_falcon_wing_R',
              (falcon_x + 0.18 * H, -0.05 * H, falcon_z),
              (0.10 * H, 0.50 * H, 0.40 * H), FALCON_BODY),
    sockets['socket_hand_L'],
)
# Wing tips (dark) at the trailing edge.
attach_to_socket(
    make_cube('Aux_falcon_wing_tip_L',
              (falcon_x - 0.20 * H, 0.20 * H, falcon_z - 0.15 * H),
              (0.12 * H, 0.22 * H, 0.18 * H), FALCON_TIP),
    sockets['socket_hand_L'],
)
attach_to_socket(
    make_cube('Aux_falcon_wing_tip_R',
              (falcon_x + 0.20 * H, 0.20 * H, falcon_z - 0.15 * H),
              (0.12 * H, 0.22 * H, 0.18 * H), FALCON_TIP),
    sockets['socket_hand_L'],
)
# Head — dark crown, slightly forward + above body.
attach_to_socket(
    make_cube('Aux_falcon_head',
              (falcon_x, -0.30 * H, falcon_z + 0.40 * H),
              (0.28 * H, 0.30 * H, 0.30 * H), FALCON_BODY),
    sockets['socket_hand_L'],
)
# Dark crown / cap on the head.
attach_to_socket(
    make_cube('Aux_falcon_cap',
              (falcon_x, -0.30 * H, falcon_z + 0.55 * H),
              (0.26 * H, 0.28 * H, 0.10 * H), FALCON_TIP),
    sockets['socket_hand_L'],
)
# Yellow hooked beak.
attach_to_socket(
    make_cube('Aux_falcon_beak',
              (falcon_x, -0.50 * H, falcon_z + 0.36 * H),
              (0.10 * H, 0.16 * H, 0.10 * H), FALCON_BEAK),
    sockets['socket_hand_L'],
)
# Eye glint.
attach_to_socket(
    make_cube('Aux_falcon_eye',
              (falcon_x + 0.10 * H, -0.40 * H, falcon_z + 0.42 * H),
              (0.06 * H, 0.06 * H, 0.06 * H), FALCON_EYE),
    sockets['socket_hand_L'],
)

# Dress sabre on the right hip — properly worn, pommel just above the
# belt + scabbard hanging down past the thigh. socket_belt_front is at
# body z, shifted forward; the sabre hangs from there following the same
# "drop down from belt" pattern as Pell's prayer beads.
sabre_x  = 0.70 * H                          # right hip
sabre_y  = -0.55 * H                         # in front of body plane
belt_z   = biped['Body'][2] - 0.10 * H       # waist line
guard_z  = belt_z                            # crossguard sits at the belt
grip_z   = belt_z + 0.20 * H                 # grip rises above crossguard
pommel_z = belt_z + 0.40 * H                 # pommel caps the grip
blade_low_z  = biped['Body'][2] - 1.10 * H   # mid-thigh
blade_top_z  = belt_z - 0.05 * H             # just under the crossguard
# Scabbard + blade together — single dark column.
attach_to_socket(
    make_cube('Aux_sabre_scabbard',
              (sabre_x, sabre_y, (blade_top_z + blade_low_z) / 2),
              (0.10 * H, 0.12 * H, abs(blade_top_z - blade_low_z)), LEATHER_BR),
    sockets['socket_belt_front'],
)
# Steel chape at the bottom of the scabbard.
attach_to_socket(
    make_cube('Aux_sabre_chape',
              (sabre_x, sabre_y, blade_low_z),
              (0.12 * H, 0.14 * H, 0.10 * H), STEEL),
    sockets['socket_belt_front'],
)
# Brass crossguard at the belt.
attach_to_socket(
    make_cube('Aux_sabre_guard',
              (sabre_x, sabre_y, guard_z),
              (0.30 * H, 0.16 * H, 0.10 * H), GOLD_TRIM),
    sockets['socket_belt_front'],
)
# Leather grip rising above the crossguard.
attach_to_socket(
    make_cube('Aux_sabre_grip',
              (sabre_x, sabre_y, grip_z),
              (0.10 * H, 0.10 * H, 0.25 * H), LEATHER_BR),
    sockets['socket_belt_front'],
)
# Pommel caps the grip.
attach_to_socket(
    make_cube('Aux_sabre_pommel',
              (sabre_x, sabre_y, pommel_z),
              (0.16 * H, 0.16 * H, 0.12 * H), GOLD_TRIM),
    sockets['socket_belt_front'],
)

# Cape mantle — cape fastened at the shoulders, draped down the back.
# socket_back sits behind the body, so the cape rotates with the torso.
attach_to_socket(
    make_cube('Aux_mantle',
              (0, 0.55 * H, biped['Body'][2] + 0.50 * H),
              (1.50 * H, 0.18 * H, 0.45 * H), CAPE_BURG),
    sockets['socket_back'],
)
# Cape body — wider, longer, drops to the knees.
cape_z = (biped['Leg_L'][2] + biped['Body'][2]) * 0.5
attach_to_socket(
    make_cube('Aux_cape_body',
              (0, 0.50 * H, cape_z),
              (1.60 * H, 0.20 * H, 1.40 * H), CAPE_BURG),
    sockets['socket_back'],
)
# Gold clasps at the shoulders.
attach_to_socket(
    make_cube('Aux_clasp_L',
              (-0.55 * H, 0.50 * H, biped['Body'][2] + 0.65 * H),
              (0.18 * H, 0.14 * H, 0.18 * H), GOLD_TRIM),
    sockets['socket_back'],
)
attach_to_socket(
    make_cube('Aux_clasp_R',
              (0.55 * H, 0.50 * H, biped['Body'][2] + 0.65 * H),
              (0.18 * H, 0.14 * H, 0.18 * H), GOLD_TRIM),
    sockets['socket_back'],
)

# ---- finalise ---------------------------------------------------------
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
# Withering is a hero NPC — retired knight, falconry teacher, distinctive
# silhouette with the perched falcon. Build at level 3 (subsurf=3 +
# pre_subdivide=2) for highest detail; other NPCs use the level-2 default.
apply_bevel_remove_doubles(all_meshes, subsurf_level=3, pre_subdivide=2)

out = os.path.abspath(os.path.dirname(__file__) + '/../models/npc_withering_v2.glb')
export_glb(root, out)
print(f"npc_withering_v2 — H={H}, archetype={ARCHETYPE}, total height "
      f"{3 * H:.3f}m, sockets={len(sockets)}")
