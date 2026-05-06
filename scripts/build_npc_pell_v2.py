"""Pell v2 — sixth proof of the head-height anchor template.

Brother Pell of the cloister. Round-faced, cream-robed, ruddy cheeks,
small psalter held in his left hand. Built fresh on the head-height
template at H=0.32, archetype='npc' (3 heads tall) — same proportions
as Eldra but with a stockier torso and longer robe drape.

Aux parts via sockets:
  - Drooping hood       → socket_helmet_top  (covers crown + back of head)
  - White-gray beard    → socket_chin        (full chest-length)
  - Prayer beads        → socket_belt_front  (oak beads with cross)
  - Psalter (small book)→ socket_hand_L      (held against chest)

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_npc_pell_v2.py

Output: models/npc_pell_v2.glb
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
ARCHETYPE = 'npc'          # 3 heads tall

# Pell palette — preserved from v1.
CREAM_WOOL = (0.90, 0.85, 0.70)
DARK_BELT  = (0.32, 0.22, 0.14)
HOOD_DK    = (0.78, 0.72, 0.58)        # slightly darker than the robe
INDIGO     = (0.20, 0.22, 0.36)        # cassock trim
GOLD       = (0.86, 0.72, 0.30)
PARCHMENT  = (0.92, 0.86, 0.70)
PSALTER_DK = (0.45, 0.30, 0.20)
RUDDY      = (0.92, 0.65, 0.55)
SKIN       = (0.95, 0.78, 0.62)
BEARD_GRAY = (0.86, 0.84, 0.78)
SANDAL     = (0.32, 0.22, 0.14)

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(2.0, -2.0, 1.0), cam_target=(0, 0, H * 1.5))

rig   = anchor_skeleton(H, ARCHETYPE)
biped = biped_pivots_only(rig)

# --- TORSO (subdivided into 3 cassock panels with indigo seams) ---
body_z = biped['Body'][2]
chest_z   = body_z + 0.45 * H
midriff_z = body_z + 0.00 * H
waist_z   = body_z - 0.50 * H
make_cube('Body_chest',   (0, 0, chest_z),
          (1.55 * H, 1.10 * H, 0.50 * H), CREAM_WOOL)
make_cube('Body_midriff', (0, 0, midriff_z),
          (1.55 * H, 1.10 * H, 0.45 * H), (0.85, 0.78, 0.62))   # slightly darker cream
make_cube('Body_waist',   (0, 0, waist_z),
          (1.55 * H, 1.10 * H, 0.40 * H), CREAM_WOOL)
# Indigo trim band where the torso meets the legs.
trim_z = (biped['Leg_L'][2] + biped['Body'][2]) * 0.5 + 0.05 * H
make_cube('Body_trim', (0, -0.55 * H, trim_z),
          (1.55 * H, 0.10 * H, 0.16 * H), INDIGO)
# Indigo button-row down the centre of the cassock.
for i, dz in enumerate((0.45, 0.20, -0.05, -0.30)):
    make_cube(f'Body_button_{i}',
              (0, -0.56 * H, body_z + dz * H),
              (0.10 * H, 0.05 * H, 0.10 * H), INDIGO)
# Cream collar.
make_cube('Body_collar',
          (0, -0.50 * H, body_z + 0.78 * H),
          (1.10 * H, 0.10 * H, 0.16 * H), CREAM_WOOL)

# --- HEAD + FACE (round, jowly, friendly) ---
make_cube('Head_skull', biped['Head'],
          (1.05 * H, 1.0 * H, 0.95 * H), SKIN)

# Round jaw — slightly bigger than skull bottom for the "round-faced" read.
make_cube('Head_jaw',
          (0, -0.10 * H, biped['Head'][2] - 0.45 * H),
          (0.92 * H, 0.92 * H, 0.22 * H), SKIN)

# Ears.
for sx, name in ((-0.58, 'Head_ear_L'), (0.58, 'Head_ear_R')):
    make_cube(name, (sx * H, 0, biped['Head'][2]),
              (0.13 * H, 0.22 * H, 0.26 * H), SKIN)

# Soft round nose.
make_cube('Head_nose',
          (0, -0.55 * H, biped['Head'][2] - 0.05 * H),
          (0.22 * H, 0.18 * H, 0.22 * H), SKIN)

# Light brows.
for sx, name in ((-0.22, 'Head_brow_L'), (0.22, 'Head_brow_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] + 0.18 * H),
              (0.20 * H, 0.06 * H, 0.06 * H), BEARD_GRAY)

# Eyes (kindly + small).
eye_y = -0.51 * H
eye_z = biped['Head'][2] + 0.05 * H
for sx, name in ((-0.22, 'Head_eye_L'), (0.22, 'Head_eye_R')):
    make_cube(name, (sx * H, eye_y, eye_z),
              (0.12 * H, 0.04 * H, 0.10 * H), (0.10, 0.05, 0.04))

# Ruddy cheeks.
for sx, name in ((-0.40, 'Head_cheek_L'), (0.40, 'Head_cheek_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] - 0.08 * H),
              (0.18 * H, 0.04 * H, 0.14 * H), RUDDY)

# Gentle smile.
make_cube('Head_smile', (0, -0.51 * H, biped['Head'][2] - 0.20 * H),
          (0.28 * H, 0.04 * H, 0.06 * H), (0.50, 0.30, 0.25))

# Arms — robe-sleeved.
for side, name in ((-1, 'Arm_L'), (1, 'Arm_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.65 * H),
              (0.55 * H, 0.60 * H, 1.30 * H), CREAM_WOOL)

# Legs — under robe drape, dark sandals.
for side, name in ((-1, 'Leg_L'), (1, 'Leg_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.75 * H),
              (0.55 * H, 0.65 * H, 1.45 * H), CREAM_WOOL)
    make_cube(f'{name}_sandal',
              (pivot[0], pivot[1] - 0.05 * H, pivot[2] - 1.50 * H),
              (0.65 * H, 0.95 * H, 0.20 * H), SANDAL)

# ---- rig + sockets ----------------------------------------------------
root, empties, mesh_objs = rig_biped(biped, 'Pell_v2_Root', biped_parent_for)
sockets = materialise_sockets(rig, empties)

# ---- aux parts pinned to sockets --------------------------------------

# Hood — drapes over the crown and the back of the head. Slightly larger
# than the head so it reads as cloth, not skin. socket_helmet_top sits
# above the head; the hood mesh extends down + back to suggest drape.
attach_to_socket(
    make_cube('Aux_hood_top', (0, 0, biped['Head'][2] + 0.55 * H),
              (1.20 * H, 1.10 * H, 0.50 * H), HOOD_DK),
    sockets['socket_helmet_top'],
)
# Hood drape down the back of the head (slightly behind, lower than top).
attach_to_socket(
    make_cube('Aux_hood_back', (0, 0.45 * H, biped['Head'][2] + 0.20 * H),
              (1.10 * H, 0.18 * H, 0.85 * H), HOOD_DK),
    sockets['socket_helmet_top'],
)

# White-gray beard — full, chest-length under the chin.
attach_to_socket(
    make_cube('Aux_beard', (0, -0.40 * H, biped['Head'][2] - 0.55 * H),
              (0.85 * H, 0.40 * H, 0.55 * H), BEARD_GRAY),
    sockets['socket_chin'],
)
# Mustache strands.
attach_to_socket(
    make_cube('Aux_mustache_L', (-0.18 * H, -0.50 * H, biped['Head'][2] - 0.30 * H),
              (0.20 * H, 0.10 * H, 0.16 * H), BEARD_GRAY),
    sockets['socket_chin'],
)
attach_to_socket(
    make_cube('Aux_mustache_R', (0.18 * H, -0.50 * H, biped['Head'][2] - 0.30 * H),
              (0.20 * H, 0.10 * H, 0.16 * H), BEARD_GRAY),
    sockets['socket_chin'],
)

# Prayer beads — oak strand looped at the belt-front. Big single bead +
# small ones on a cord.
attach_to_socket(
    make_cube('Aux_beads_strand', (0, -0.55 * H, biped['Body'][2] - 0.10 * H),
              (0.40 * H, 0.10 * H, 0.85 * H), DARK_BELT),
    sockets['socket_belt_front'],
)
# Cross at the bottom.
attach_to_socket(
    make_cube('Aux_cross_v', (0, -0.58 * H, biped['Body'][2] - 0.55 * H),
              (0.10 * H, 0.06 * H, 0.30 * H), GOLD),
    sockets['socket_belt_front'],
)
attach_to_socket(
    make_cube('Aux_cross_h', (0, -0.58 * H, biped['Body'][2] - 0.50 * H),
              (0.22 * H, 0.06 * H, 0.10 * H), GOLD),
    sockets['socket_belt_front'],
)

# Psalter — small leather-bound book held against the chest in the left
# hand. socket_hand_L sits one head-length below Arm_L pivot, so we
# offset slightly forward + up to read as "hugged to chest".
psalter_x = biped['Arm_L'][0] + 0.10 * H
psalter_z = biped['Arm_L'][2] - 0.85 * H
attach_to_socket(
    make_cube('Aux_psalter', (psalter_x, -0.30 * H, psalter_z),
              (0.45 * H, 0.20 * H, 0.55 * H), PSALTER_DK),
    sockets['socket_hand_L'],
)
# Page-edge cream stripe.
attach_to_socket(
    make_cube('Aux_psalter_pages', (psalter_x + 0.20 * H, -0.30 * H, psalter_z),
              (0.05 * H, 0.18 * H, 0.50 * H), PARCHMENT),
    sockets['socket_hand_L'],
)
# Gold ornament on the cover.
attach_to_socket(
    make_cube('Aux_psalter_orn', (psalter_x, -0.40 * H, psalter_z),
              (0.18 * H, 0.04 * H, 0.18 * H), GOLD),
    sockets['socket_hand_L'],
)

# ---- finalise ---------------------------------------------------------
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
apply_bevel_remove_doubles(all_meshes)

out = os.path.abspath(os.path.dirname(__file__) + '/../models/npc_pell_v2.glb')
export_glb(root, out)
print(f"npc_pell_v2 — H={H}, archetype={ARCHETYPE}, total height "
      f"{3 * H:.3f}m, sockets={len(sockets)}")
