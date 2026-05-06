"""Cricket v2 — fifth proof of the head-height anchor template.

Cricket the Letter-Carrier, age 16, orphan with russet hair and his
companion bird Pibbet. Built fresh on the head-height template at H=0.30
(slightly shorter than the adult NPCs at 0.32) so his silhouette reads
as "young/lean" against Hod and Maud.

Aux parts via sockets:
  - Walking staff       → socket_hand_R   (oak shaft, grip is pivot)
  - Letter satchel      → socket_back     (crossbody bag with letters)
  - Pibbet (bird)       → socket_helmet_top (perched up top — visible)
  - Scarf               → socket_chin     (knit scarf around neck)

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_npc_cricket_v2.py

Output: models/npc_cricket_v2.glb
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
H         = 0.30           # smaller than adult NPCs (0.32) — teenage build
ARCHETYPE = 'npc'          # 3 heads tall

# Cricket palette — preserved from v1.
MOSS_GREEN  = (0.36, 0.46, 0.24)
OAK_BROWN   = (0.42, 0.30, 0.18)
STRAW_HAIR  = (0.78, 0.65, 0.40)
MUD         = (0.30, 0.22, 0.16)
SKIN        = (0.95, 0.80, 0.65)
CREAM       = (0.90, 0.84, 0.72)
DARK        = (0.20, 0.16, 0.12)
SCARF_RUST  = (0.62, 0.32, 0.22)
PIBBET_DRK  = (0.18, 0.13, 0.08)
PIBBET_BEAK = (0.85, 0.62, 0.20)

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(1.8, -1.8, 1.0), cam_target=(0, 0, H * 1.5))

rig   = anchor_skeleton(H, ARCHETYPE)
biped = biped_pivots_only(rig)

# --- TORSO (subdivided into 4 panels: chest / midriff / belt / waist) ---
body_z = biped['Body'][2]
chest_z   = body_z + 0.45 * H
midriff_z = body_z + 0.05 * H
belt_z    = body_z - 0.30 * H
waist_z   = body_z - 0.55 * H
make_cube('Body_chest',   (0, 0, chest_z),
          (1.20 * H, 0.95 * H, 0.50 * H), MOSS_GREEN)
make_cube('Body_midriff', (0, 0, midriff_z),
          (1.18 * H, 0.95 * H, 0.40 * H), (0.42, 0.52, 0.28))   # darker moss
make_cube('Body_belt',    (0, 0, belt_z),
          (1.25 * H, 1.00 * H, 0.18 * H), OAK_BROWN)
make_cube('Body_waist',   (0, 0, waist_z),
          (1.16 * H, 0.95 * H, 0.30 * H), MOSS_GREEN)
# Tunic lacing — leather thong cross-stitched down the chest.
for i, dz in enumerate((0.20, 0.05, -0.10, -0.25)):
    make_cube(f'Body_lace_{i}',
              (0, -0.50 * H, body_z + dz * H),
              (0.20 * H, 0.05 * H, 0.04 * H), OAK_BROWN)
# Collar — light cream undershirt peeking at neck.
make_cube('Body_collar',
          (0, -0.48 * H, body_z + 0.78 * H),
          (0.95 * H, 0.10 * H, 0.16 * H), CREAM)

# --- HEAD + FACE ---
make_cube('Head_skull', biped['Head'],
          (1.0 * H, 0.95 * H, 0.95 * H), SKIN)

# Boyish jaw — narrower than Hod's.
make_cube('Head_jaw',
          (0, -0.10 * H, biped['Head'][2] - 0.45 * H),
          (0.78 * H, 0.85 * H, 0.20 * H), SKIN)

# Ears.
for sx, name in ((-0.55, 'Head_ear_L'), (0.55, 'Head_ear_R')):
    make_cube(name, (sx * H, 0, biped['Head'][2]),
              (0.12 * H, 0.20 * H, 0.25 * H), SKIN)

# Small nose.
make_cube('Head_nose',
          (0, -0.55 * H, biped['Head'][2] - 0.05 * H),
          (0.14 * H, 0.16 * H, 0.18 * H), SKIN)

# Light brows.
for sx, name in ((-0.22, 'Head_brow_L'), (0.22, 'Head_brow_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] + 0.18 * H),
              (0.20 * H, 0.06 * H, 0.05 * H), STRAW_HAIR)

# Eyes — bright, slightly forward.
eye_y = -0.51 * H
eye_z = biped['Head'][2] + 0.05 * H
for sx, name in ((-0.22, 'Head_eye_L'), (0.22, 'Head_eye_R')):
    make_cube(name, (sx * H, eye_y, eye_z),
              (0.14 * H, 0.04 * H, 0.10 * H), (0.08, 0.05, 0.04))

# Freckles across the nose bridge.
for sx, name in ((-0.25, 'Head_freckle_L'), (0.25, 'Head_freckle_R')):
    make_cube(name, (sx * H, -0.56 * H, biped['Head'][2] - 0.10 * H),
              (0.10 * H, 0.04 * H, 0.05 * H), (0.78, 0.55, 0.35))

# Mouth — small grin.
make_cube('Head_mouth',
          (0, -0.51 * H, biped['Head'][2] - 0.28 * H),
          (0.20 * H, 0.04 * H, 0.04 * H), (0.50, 0.30, 0.25))

# Tousled bangs in front of the forehead.
make_cube('Head_bangs', (0, -0.45 * H, biped['Head'][2] + 0.30 * H),
          (0.95 * H, 0.20 * H, 0.32 * H), STRAW_HAIR)

# Arms — thin, moss-green sleeves.
for side, name in ((-1, 'Arm_L'), (1, 'Arm_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.65 * H),
              (0.40 * H, 0.45 * H, 1.30 * H), MOSS_GREEN)

# Legs — thin dark trousers + muddy boots.
for side, name in ((-1, 'Leg_L'), (1, 'Leg_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.75 * H),
              (0.50 * H, 0.55 * H, 1.45 * H), DARK)
    make_cube(f'{name}_boot',
              (pivot[0], pivot[1] - 0.05 * H, pivot[2] - 1.50 * H),
              (0.58 * H, 0.78 * H, 0.30 * H), MUD)

# ---- rig + sockets ----------------------------------------------------
root, empties, mesh_objs = rig_biped(biped, 'Cricket_v2_Root', biped_parent_for)
sockets = materialise_sockets(rig, empties)

# ---- aux parts pinned to sockets --------------------------------------

# Russet-curl hair tied with twine — sits on top of the skull and
# rotates with the Head group when animation fires.
attach_to_socket(
    make_cube('Aux_hair', (0, 0.10 * H, biped['Head'][2] + 0.50 * H),
              (1.10 * H, 1.00 * H, 0.55 * H), STRAW_HAIR),
    sockets['socket_helmet_top'],
)

# Pibbet — Cricket's pet bird, perched on the crown. Tiny dark body +
# a bright orange beak so it reads at glance as a wee creature, not
# just "another hat block".
attach_to_socket(
    make_cube('Aux_pibbet_body', (0, 0.20 * H, biped['Head'][2] + 1.05 * H),
              (0.34 * H, 0.45 * H, 0.34 * H), PIBBET_DRK),
    sockets['socket_helmet_top'],
)
attach_to_socket(
    make_cube('Aux_pibbet_head', (0, 0.05 * H, biped['Head'][2] + 1.20 * H),
              (0.24 * H, 0.26 * H, 0.22 * H), PIBBET_DRK),
    sockets['socket_helmet_top'],
)
attach_to_socket(
    make_cube('Aux_pibbet_beak', (0, -0.18 * H, biped['Head'][2] + 1.18 * H),
              (0.10 * H, 0.18 * H, 0.08 * H), PIBBET_BEAK),
    sockets['socket_helmet_top'],
)
# Tiny eye glint on Pibbet so the bird actually reads as alive.
attach_to_socket(
    make_cube('Aux_pibbet_eye', (0.08 * H, -0.10 * H, biped['Head'][2] + 1.22 * H),
              (0.05 * H, 0.04 * H, 0.05 * H), (0.95, 0.85, 0.30)),
    sockets['socket_helmet_top'],
)

# Knit scarf — wraps under the chin. socket_chin sits below jaw, so the
# scarf will rotate with the head when Cricket nods/looks around.
attach_to_socket(
    make_cube('Aux_scarf', (0, -0.30 * H, biped['Head'][2] - 0.55 * H),
              (1.10 * H, 0.65 * H, 0.30 * H), SCARF_RUST),
    sockets['socket_chin'],
)
# Trailing scarf end on the chest.
attach_to_socket(
    make_cube('Aux_scarf_tail', (-0.40 * H, -0.25 * H, biped['Head'][2] - 1.00 * H),
              (0.30 * H, 0.10 * H, 0.55 * H), SCARF_RUST),
    sockets['socket_chin'],
)

# Leather letter satchel — crossbody bag on the back. socket_back sits
# behind the torso so the bag stays put even when Cricket leans forward.
attach_to_socket(
    make_cube('Aux_satchel', (0, 0.55 * H, biped['Body'][2] - 0.05 * H),
              (1.00 * H, 0.40 * H, 0.95 * H), OAK_BROWN),
    sockets['socket_back'],
)
# Letters peeking out the top.
attach_to_socket(
    make_cube('Aux_letter_a', (-0.20 * H, 0.55 * H, biped['Body'][2] + 0.40 * H),
              (0.32 * H, 0.12 * H, 0.20 * H), CREAM),
    sockets['socket_back'],
)
attach_to_socket(
    make_cube('Aux_letter_b', (0.10 * H, 0.55 * H, biped['Body'][2] + 0.45 * H),
              (0.28 * H, 0.12 * H, 0.18 * H), CREAM),
    sockets['socket_back'],
)
# Crossbody strap from satchel up over the shoulder.
attach_to_socket(
    make_cube('Aux_strap', (0, 0.20 * H, biped['Body'][2] + 0.60 * H),
              (1.05 * H, 0.10 * H, 0.16 * H), OAK_BROWN),
    sockets['socket_back'],
)

# Walking staff — tall oak shaft in the right hand. Pinned at
# socket_hand_R so the grip is the rotation pivot.
staff_grip_x = biped['Arm_R'][0] + 0.20 * H
staff_grip_z = biped['Arm_R'][2] - 1.05 * H
staff_top_z  = biped['Arm_R'][2] + 1.20 * H
attach_to_socket(
    make_cube('Aux_staff',
              (staff_grip_x, -0.20 * H, (staff_grip_z + staff_top_z) / 2),
              (0.16 * H, 0.16 * H, abs(staff_top_z - staff_grip_z)), OAK_BROWN),
    sockets['socket_hand_R'],
)

# ---- finalise ---------------------------------------------------------
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
apply_bevel_remove_doubles(all_meshes)

out = os.path.abspath(os.path.dirname(__file__) + '/../models/npc_cricket_v2.glb')
export_glb(root, out)
print(f"npc_cricket_v2 — H={H}, archetype={ARCHETYPE}, total height "
      f"{3 * H:.3f}m, sockets={len(sockets)}")
