"""Quill v2 — tenth proof of the head-height anchor template.

Quill the Herbalist — soft-spoken brewer of healing draughts and refined
ink. Pots of hedgecap on her workbench, sprigs poked in her hat, mortar
in one hand and pestle in the other. Built fresh on the head-height
template at H=0.32, archetype='npc' — same proportions as Maud / Pell /
Onywyn but with a green / earthy palette and a *six-socket* prop set
(every defined socket in active use).

Aux parts via sockets:
  - Wide-brim herb-gatherer's hat + sprigs → socket_helmet_top
  - Loose dark hair (visible at shoulders)  → socket_chin (anchored under
                                              the hat-line, drops down
                                              both sides of the face)
  - Apron + herb-stuffed pockets            → socket_belt_front
  - Stone mortar                            → socket_hand_L
  - Wooden pestle                           → socket_hand_R
  - Bundle of dried herbs slung on back     → socket_back

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_npc_quill_v2.py

Output: models/npc_quill_v2.glb
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

# Quill palette — sage green tunic, leather tan apron, earthy browns + a
# few sprig accents (foxglove magenta, thyme purple).
SAGE_TUNIC    = (0.42, 0.50, 0.34)        # main tunic
SAGE_DARK     = (0.30, 0.38, 0.24)        # tunic trim / hem
APRON_TAN     = (0.62, 0.50, 0.34)        # leather apron
APRON_DARK    = (0.42, 0.32, 0.20)        # apron strap / pocket trim
STRAW_HAT     = (0.78, 0.68, 0.42)        # wide-brim hat
HAT_BAND      = (0.42, 0.32, 0.20)        # leather band
HAIR_DARK     = (0.28, 0.20, 0.14)        # dark hair under the hat
SKIN          = (0.92, 0.78, 0.62)
EYE_DARK      = (0.10, 0.06, 0.04)
TROUSER_BRN   = (0.32, 0.22, 0.16)
BOOT_BROWN    = (0.22, 0.16, 0.12)
MORTAR_STONE  = (0.55, 0.50, 0.45)        # grey-tan stone
PESTLE_WOOD   = (0.50, 0.36, 0.22)        # warm oak
HERB_GREEN    = (0.45, 0.55, 0.28)        # sprig + bundle leaves
HERB_BROWN    = (0.38, 0.30, 0.20)        # dried-herb tone
FOXGLOVE      = (0.62, 0.40, 0.65)        # bell-flower magenta
THYME_PURPLE  = (0.42, 0.30, 0.50)        # smaller spike-flower
TWINE         = (0.82, 0.68, 0.44)        # twine binding the bundle

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(2.0, -2.0, 1.0), cam_target=(0, 0, H * 1.5))

rig   = anchor_skeleton(H, ARCHETYPE)
biped = biped_pivots_only(rig)

# --- TORSO (subdivided into 4 sage panels with darker accents) ---
body_z = biped['Body'][2]
chest_z   = body_z + 0.45 * H
midriff_z = body_z + 0.05 * H
belt_z    = body_z - 0.30 * H
waist_z   = body_z - 0.55 * H
make_cube('Body_chest',   (0, 0, chest_z),
          (1.25 * H, 0.95 * H, 0.50 * H), SAGE_TUNIC)
make_cube('Body_midriff', (0, 0, midriff_z),
          (1.22 * H, 0.95 * H, 0.40 * H), SAGE_DARK)
make_cube('Body_belt',    (0, 0, belt_z),
          (1.30 * H, 1.00 * H, 0.18 * H), APRON_DARK)   # leather belt
make_cube('Body_waist',   (0, 0, waist_z),
          (1.20 * H, 0.95 * H, 0.30 * H), SAGE_TUNIC)
# Sage hem at the bottom of the tunic.
hem_z = (biped['Leg_L'][2] + biped['Body'][2]) * 0.5
make_cube('Body_hem', (0, 0, hem_z),
          (1.30 * H, 1.00 * H, 0.18 * H), SAGE_DARK)
# Tunic lacing — leather thong cross-stitched down the chest.
for i, dz in enumerate((0.20, 0.05, -0.10)):
    make_cube(f'Body_lace_{i}',
              (0, -0.50 * H, body_z + dz * H),
              (0.18 * H, 0.05 * H, 0.04 * H), APRON_DARK)
# Cream undershirt collar at neck.
make_cube('Body_collar',
          (0, -0.48 * H, body_z + 0.78 * H),
          (1.00 * H, 0.10 * H, 0.16 * H), STRAW_HAT)

# --- HEAD + FACE ---
make_cube('Head_skull', biped['Head'],
          (0.95 * H, 0.95 * H, 0.95 * H), SKIN)

# Soft jaw.
make_cube('Head_jaw',
          (0, -0.10 * H, biped['Head'][2] - 0.45 * H),
          (0.75 * H, 0.85 * H, 0.20 * H), SKIN)

# Ears.
for sx, name in ((-0.55, 'Head_ear_L'), (0.55, 'Head_ear_R')):
    make_cube(name, (sx * H, 0, biped['Head'][2]),
              (0.12 * H, 0.20 * H, 0.25 * H), SKIN)

# Soft nose.
make_cube('Head_nose',
          (0, -0.55 * H, biped['Head'][2] - 0.05 * H),
          (0.16 * H, 0.16 * H, 0.20 * H), SKIN)

# Brows — soft, dark.
for sx, name in ((-0.22, 'Head_brow_L'), (0.22, 'Head_brow_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] + 0.18 * H),
              (0.20 * H, 0.06 * H, 0.05 * H), HAIR_DARK)

# Soft, almond eyes.
eye_y = -0.51 * H
eye_z = biped['Head'][2] + 0.05 * H
for sx, name in ((-0.22, 'Head_eye_L'), (0.22, 'Head_eye_R')):
    make_cube(name, (sx * H, eye_y, eye_z),
              (0.13 * H, 0.04 * H, 0.10 * H), EYE_DARK)

# Subtle cheek warmth.
for sx, name in ((-0.32, 'Head_cheek_L'), (0.32, 'Head_cheek_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] - 0.12 * H),
              (0.14 * H, 0.04 * H, 0.10 * H), (0.94, 0.72, 0.62))

# Light smile — soft mouth.
make_cube('Head_mouth',
          (0, -0.51 * H, biped['Head'][2] - 0.25 * H),
          (0.22 * H, 0.04 * H, 0.05 * H), (0.50, 0.30, 0.25))

# Arms — sage tunic sleeves.
for side, name in ((-1, 'Arm_L'), (1, 'Arm_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.65 * H),
              (0.45 * H, 0.50 * H, 1.30 * H), SAGE_TUNIC)
    # Tan cuff at the wrist.
    make_cube(f'{name}_cuff',
              (pivot[0], pivot[1], pivot[2] - 1.30 * H),
              (0.50 * H, 0.55 * H, 0.16 * H), APRON_TAN)

# Legs + boots — sturdy dark trousers, leather field boots.
for side, name in ((-1, 'Leg_L'), (1, 'Leg_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.75 * H),
              (0.55 * H, 0.65 * H, 1.45 * H), TROUSER_BRN)
    make_cube(f'{name}_boot',
              (pivot[0], pivot[1] - 0.05 * H, pivot[2] - 1.50 * H),
              (0.62 * H, 0.85 * H, 0.30 * H), BOOT_BROWN)

# ---- rig + sockets ----------------------------------------------------
root, empties, mesh_objs = rig_biped(biped, 'Quill_v2_Root', biped_parent_for)
sockets = materialise_sockets(rig, empties)

# ---- aux parts pinned to sockets --------------------------------------

# Wide-brim straw hat. Crown + brim + leather band + 3 sprigs poked into
# the band so it reads as "herbalist's working hat", not "farmer".
attach_to_socket(
    make_cube('Aux_hat_brim',
              (0, 0, biped['Head'][2] + 0.42 * H),
              (1.60 * H, 1.40 * H, 0.10 * H), STRAW_HAT),
    sockets['socket_helmet_top'],
)
attach_to_socket(
    make_cube('Aux_hat_crown',
              (0, 0, biped['Head'][2] + 0.65 * H),
              (0.95 * H, 0.95 * H, 0.40 * H), STRAW_HAT),
    sockets['socket_helmet_top'],
)
# Leather band around the crown.
attach_to_socket(
    make_cube('Aux_hat_band',
              (0, 0, biped['Head'][2] + 0.50 * H),
              (1.00 * H, 1.00 * H, 0.10 * H), HAT_BAND),
    sockets['socket_helmet_top'],
)
# Sprigs poked through the band — green stem + a coloured flower head.
for i, (sx, sy, col) in enumerate((
    (-0.45, -0.45, FOXGLOVE),
    ( 0.10, -0.45, HERB_GREEN),
    ( 0.40, -0.40, THYME_PURPLE),
)):
    attach_to_socket(
        make_cube(f'Aux_sprig_stem_{i}',
                  (sx * H, sy * H, biped['Head'][2] + 0.55 * H),
                  (0.06 * H, 0.06 * H, 0.30 * H), HERB_GREEN),
        sockets['socket_helmet_top'],
    )
    attach_to_socket(
        make_cube(f'Aux_sprig_flower_{i}',
                  (sx * H, sy * H, biped['Head'][2] + 0.78 * H),
                  (0.12 * H, 0.12 * H, 0.14 * H), col),
        sockets['socket_helmet_top'],
    )

# Loose dark hair on the chin socket — drops behind the ears, visible at
# the jaw line. Two strands so the silhouette reads as "hair under hat",
# not "beard". (No moustache cubes.)
attach_to_socket(
    make_cube('Aux_hair_L',
              (-0.45 * H, -0.05 * H, biped['Head'][2] - 0.30 * H),
              (0.18 * H, 0.30 * H, 0.55 * H), HAIR_DARK),
    sockets['socket_chin'],
)
attach_to_socket(
    make_cube('Aux_hair_R',
              (0.45 * H, -0.05 * H, biped['Head'][2] - 0.30 * H),
              (0.18 * H, 0.30 * H, 0.55 * H), HAIR_DARK),
    sockets['socket_chin'],
)

# Apron — leather panel + neck strap + 2 stuffed pockets. Hangs from the
# belt-front socket the same way Pell's beads hang from his.
attach_to_socket(
    make_cube('Aux_apron_panel',
              (0, -0.55 * H, biped['Body'][2] - 0.05 * H),
              (1.20 * H, 0.10 * H, 1.30 * H), APRON_TAN),
    sockets['socket_belt_front'],
)
# Neck strap rising up to the shoulders.
attach_to_socket(
    make_cube('Aux_apron_strap',
              (0, -0.55 * H, biped['Body'][2] + 0.85 * H),
              (0.50 * H, 0.08 * H, 0.20 * H), APRON_DARK),
    sockets['socket_belt_front'],
)
# Two pockets, both with a sprig poking out.
for i, sx in enumerate((-0.30, 0.30)):
    attach_to_socket(
        make_cube(f'Aux_apron_pocket_{i}',
                  (sx * H, -0.58 * H, biped['Body'][2] - 0.20 * H),
                  (0.30 * H, 0.06 * H, 0.30 * H), APRON_DARK),
        sockets['socket_belt_front'],
    )
    attach_to_socket(
        make_cube(f'Aux_pocket_sprig_{i}',
                  (sx * H, -0.62 * H, biped['Body'][2] + 0.05 * H),
                  (0.10 * H, 0.06 * H, 0.25 * H), HERB_GREEN),
        sockets['socket_belt_front'],
    )

# Stone mortar in the left hand. socket_hand_L sits 1H below shoulder, so
# the mortar reads as "cradled in the palm".
mortar_x = biped['Arm_L'][0] + 0.10 * H
mortar_z = biped['Arm_L'][2] - 1.00 * H
attach_to_socket(
    make_cube('Aux_mortar_bowl',
              (mortar_x, -0.30 * H, mortar_z),
              (0.40 * H, 0.40 * H, 0.30 * H), MORTAR_STONE),
    sockets['socket_hand_L'],
)
# Crushed-herb interior at the top of the bowl.
attach_to_socket(
    make_cube('Aux_mortar_paste',
              (mortar_x, -0.30 * H, mortar_z + 0.16 * H),
              (0.30 * H, 0.30 * H, 0.06 * H), HERB_GREEN),
    sockets['socket_hand_L'],
)

# Wooden pestle in the right hand — short stout dowel, gripped with the
# fat end up. socket_hand_R sits 1H below shoulder.
pestle_x = biped['Arm_R'][0] - 0.05 * H
pestle_z = biped['Arm_R'][2] - 0.90 * H
attach_to_socket(
    make_cube('Aux_pestle_grip',
              (pestle_x, -0.30 * H, pestle_z),
              (0.10 * H, 0.10 * H, 0.40 * H), PESTLE_WOOD),
    sockets['socket_hand_R'],
)
# Fat end (head) of the pestle.
attach_to_socket(
    make_cube('Aux_pestle_head',
              (pestle_x, -0.30 * H, pestle_z + 0.25 * H),
              (0.18 * H, 0.18 * H, 0.20 * H), PESTLE_WOOD),
    sockets['socket_hand_R'],
)

# Herb bundle slung on the back — three stems bound with twine, leaves
# fanning at the top, tied at the bottom. socket_back sits behind the
# torso so the bundle moves with body rotation.
bundle_z = biped['Body'][2] + 0.10 * H
attach_to_socket(
    make_cube('Aux_bundle_stems',
              (0, 0.55 * H, bundle_z - 0.20 * H),
              (0.45 * H, 0.20 * H, 0.85 * H), HERB_BROWN),
    sockets['socket_back'],
)
# Twine binding near the bottom.
attach_to_socket(
    make_cube('Aux_bundle_twine',
              (0, 0.58 * H, bundle_z - 0.55 * H),
              (0.50 * H, 0.10 * H, 0.10 * H), TWINE),
    sockets['socket_back'],
)
# Fanned leaves at the top (3 layered cubes).
for i, (sx, sy, sz) in enumerate((
    (-0.18,  0.50,  0.30),
    ( 0.00,  0.50,  0.40),
    ( 0.20,  0.50,  0.30),
)):
    attach_to_socket(
        make_cube(f'Aux_bundle_leaves_{i}',
                  (sx * H, sy * H, bundle_z + sz * H),
                  (0.22 * H, 0.20 * H, 0.30 * H), HERB_GREEN),
        sockets['socket_back'],
    )
# A few magenta foxglove bells on the upper bundle for variety.
attach_to_socket(
    make_cube('Aux_bundle_flower',
              (0, 0.50 * H, bundle_z + 0.55 * H),
              (0.30 * H, 0.18 * H, 0.18 * H), FOXGLOVE),
    sockets['socket_back'],
)

# ---- finalise ---------------------------------------------------------
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
apply_bevel_remove_doubles(all_meshes)

out = os.path.abspath(os.path.dirname(__file__) + '/../models/npc_quill_v2.glb')
export_glb(root, out)
print(f"npc_quill_v2 — H={H}, archetype={ARCHETYPE}, total height "
      f"{3 * H:.3f}m, sockets={len(sockets)}")
