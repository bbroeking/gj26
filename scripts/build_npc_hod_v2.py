"""Hod v2 — third proof of the head-height anchor template.

Hod Tenter, the village smith. Barrel-chested, gray-streaked beard,
soot-streaked apron, heavy boots, hammer in his right hand. Built fresh
on the template (no prior build_npc_hod.py existed, only the GLB).

Three sockets in active use — strongest template stress test so far:
  - Hammer (head + haft) → socket_hand_R   (grip is the rotation pivot)
  - Smithing apron        → socket_belt_front (front of torso)
  - Full beard            → socket_chin   (under the jaw, follows head)

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_npc_hod_v2.py

Output: models/npc_hod_v2.glb
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
H         = 0.34         # slightly larger head — Hod is barrel-chested
ARCHETYPE = 'npc'        # 3 heads tall

# Hod palette — warmer skin, smith dark tones, gray-streaked beard.
SKIN          = (0.82, 0.65, 0.48)       # warm tan, weathered
TUNIC_DARK    = (0.25, 0.20, 0.16)       # under-apron dark brown
APRON_LEATHER = (0.36, 0.24, 0.14)       # base apron color
APRON_SOOT    = (0.18, 0.13, 0.10)       # soot streak (darker)
HAIR_DARK     = (0.22, 0.16, 0.12)
BEARD_GRAY    = (0.55, 0.50, 0.46)       # gray-streaked
EYE_DARK      = (0.10, 0.06, 0.04)
BOOT_BLACK    = (0.10, 0.08, 0.07)
HAMMER_METAL  = (0.45, 0.45, 0.48)       # dull pewter
HAMMER_WOOD   = (0.40, 0.28, 0.16)       # haft

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(2.2, -2.2, 1.1), cam_target=(0, 0, H * 1.6))

rig   = anchor_skeleton(H, ARCHETYPE)
biped = biped_pivots_only(rig)

# --- TORSO (subdivided into 4 panels: chest / midriff / belt / waist) ---
body_z   = biped['Body'][2]
chest_z  = body_z + 0.45 * H
midriff_z= body_z + 0.05 * H
belt_z   = body_z - 0.30 * H
waist_z  = body_z - 0.55 * H
make_cube('Body_chest',   (0, 0, chest_z),
          (1.55 * H, 1.05 * H, 0.50 * H), TUNIC_DARK)
make_cube('Body_midriff', (0, 0, midriff_z),
          (1.50 * H, 1.05 * H, 0.40 * H), APRON_LEATHER)   # leather apron upper
make_cube('Body_belt',    (0, 0, belt_z),
          (1.55 * H, 1.10 * H, 0.18 * H), APRON_SOOT)      # dark leather belt
make_cube('Body_waist',   (0, 0, waist_z),
          (1.50 * H, 1.05 * H, 0.30 * H), TUNIC_DARK)
# Shoulders — bulkier broader top to read as smith musculature.
make_cube('Body_shoulders',
          (0, 0, body_z + 0.78 * H),
          (1.85 * H, 1.15 * H, 0.30 * H), TUNIC_DARK)
# Soot streaks down the apron front (small darker patches).
for i, (sx, sz) in enumerate(((-0.30, 0.10), (0.20, -0.10), (-0.10, -0.25))):
    make_cube(f'Body_soot_{i}',
              (sx * H, -0.55 * H, body_z + sz * H),
              (0.20 * H, 0.06 * H, 0.20 * H), APRON_SOOT)
# Collar — narrow band at the throat.
make_cube('Body_collar',
          (0, -0.50 * H, body_z + 1.00 * H),
          (1.10 * H, 0.10 * H, 0.16 * H), APRON_LEATHER)

# --- HEAD + FACE (jaw, ears, nose, brows, smith's heavy features) ---
make_cube('Head_skull', biped['Head'],
          (1.05 * H, 0.95 * H, 0.95 * H), SKIN)

# Heavy jaw — Hod's defining feature.
make_cube('Head_jaw',
          (0, -0.10 * H, biped['Head'][2] - 0.45 * H),
          (0.92 * H, 0.85 * H, 0.22 * H), SKIN)

# Ears.
for sx, name in ((-0.58, 'Head_ear_L'), (0.58, 'Head_ear_R')):
    make_cube(name, (sx * H, 0, biped['Head'][2]),
              (0.14 * H, 0.22 * H, 0.28 * H), SKIN)

# Broad nose — slightly bigger to fit the smith.
make_cube('Head_nose',
          (0, -0.55 * H, biped['Head'][2] - 0.05 * H),
          (0.20 * H, 0.18 * H, 0.22 * H), SKIN)

# Heavy dark brows — distinctive.
for sx, name in ((-0.22, 'Head_brow_L'), (0.22, 'Head_brow_R')):
    make_cube(name, (sx * H, -0.50 * H, biped['Head'][2] + 0.18 * H),
              (0.26 * H, 0.08 * H, 0.10 * H), HAIR_DARK)

# Hair on top — short, dark, capped over the skull.
make_cube('Head_hair',
          (0, 0.10 * H, biped['Head'][2] + 0.42 * H),
          (1.10 * H, 1.00 * H, 0.30 * H), HAIR_DARK)

# Eyes — squinting smith look (small + slightly low).
eye_y = -0.51 * H
eye_z = biped['Head'][2] + 0.05 * H
for sx, name in ((-0.22, 'Head_eye_L'), (0.22, 'Head_eye_R')):
    make_cube(name, (sx * H, eye_y, eye_z),
              (0.16 * H, 0.04 * H, 0.06 * H), EYE_DARK)

# Mouth — slight grimace line.
make_cube('Head_mouth',
          (0, -0.51 * H, biped['Head'][2] - 0.28 * H),
          (0.30 * H, 0.04 * H, 0.05 * H), (0.40, 0.22, 0.16))

# Arms — thicker than NPC-default to fit the smith silhouette.
for side, name in ((-1, 'Arm_L'), (1, 'Arm_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.65 * H),
              (0.55 * H, 0.55 * H, 1.30 * H), TUNIC_DARK)
    # Glove (rolled-up sleeve cuff) at the wrist.
    make_cube(f'{name}_cuff',
              (pivot[0], pivot[1], pivot[2] - 1.30 * H),
              (0.62 * H, 0.62 * H, 0.18 * H), APRON_LEATHER)

# Legs — solid, in dark trousers.
TROUSER = (0.30, 0.24, 0.18)
for side, name in ((-1, 'Leg_L'), (1, 'Leg_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.75 * H),
              (0.55 * H, 0.65 * H, 1.45 * H), TROUSER)
    # Heavy boots — wider + taller than Eldra's clogs.
    make_cube(f'{name}_boot',
              (pivot[0], pivot[1] - 0.05 * H, pivot[2] - 1.50 * H),
              (0.68 * H, 0.95 * H, 0.40 * H), BOOT_BLACK)

# ---- rig + sockets ----------------------------------------------------
root, empties, mesh_objs = rig_biped(biped, 'Hod_v2_Root', biped_parent_for)
sockets = materialise_sockets(rig, empties)

# ---- aux parts pinned to sockets --------------------------------------

# Smithing apron — main panel covering the chest + belly. Soot-streaked
# variant produced by overlaying a darker rectangle on top.
attach_to_socket(
    make_cube('Aux_apron',
              (0, -0.55 * H, biped['Body'][2] + 0.15 * H),
              (1.40 * H, 0.10 * H, 1.55 * H), APRON_LEATHER),
    sockets['socket_belt_front'],
)
# Soot streak — diagonal-ish darker patch in the apron's mid-section.
attach_to_socket(
    make_cube('Aux_apron_soot',
              (0.20 * H, -0.58 * H, biped['Body'][2] + 0.10 * H),
              (0.55 * H, 0.06 * H, 0.85 * H), APRON_SOOT),
    sockets['socket_belt_front'],
)
# Apron strap loop — sits at the base of the neck, between chin (below
# head center) and body-top. Tuned at +0.55H so it never overlaps the
# head regardless of H.
attach_to_socket(
    make_cube('Aux_apron_strap',
              (0, -0.55 * H, biped['Body'][2] + 0.55 * H),
              (0.80 * H, 0.08 * H, 0.18 * H), APRON_LEATHER),
    sockets['socket_belt_front'],
)

# Full beard — bushy block under the chin. Gray-streaked color reads as
# "older smith" rather than the dark-only HAIR.
attach_to_socket(
    make_cube('Aux_beard',
              (0, -0.45 * H, biped['Head'][2] - 0.55 * H),
              (0.95 * H, 0.45 * H, 0.65 * H), BEARD_GRAY),
    sockets['socket_chin'],
)
# Gray streak through the beard — a slightly lighter band off-center.
attach_to_socket(
    make_cube('Aux_beard_streak',
              (-0.20 * H, -0.50 * H, biped['Head'][2] - 0.50 * H),
              (0.18 * H, 0.10 * H, 0.55 * H), (0.78, 0.74, 0.70)),
    sockets['socket_chin'],
)

# Hammer — head + haft, both pinned to socket_hand_R so the grip is the
# rotation pivot when the arm swings. Head at the top of the haft.
hammer_grip_x = biped['Arm_R'][0] + 0.15 * H
hammer_grip_z = biped['Arm_R'][2] - 1.05 * H
hammer_top_z  = hammer_grip_z + 1.40 * H

# Haft — long wooden shaft from grip up to where the head sits.
attach_to_socket(
    make_cube('Aux_hammer_haft',
              (hammer_grip_x, -0.10 * H, (hammer_grip_z + hammer_top_z) / 2),
              (0.16 * H, 0.16 * H, abs(hammer_top_z - hammer_grip_z)), HAMMER_WOOD),
    sockets['socket_hand_R'],
)
# Head — chunky perpendicular metal block at the top of the haft.
attach_to_socket(
    make_cube('Aux_hammer_head',
              (hammer_grip_x, -0.10 * H, hammer_top_z + 0.05 * H),
              (0.65 * H, 0.30 * H, 0.40 * H), HAMMER_METAL),
    sockets['socket_hand_R'],
)

# ---- finalise ---------------------------------------------------------
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
apply_bevel_remove_doubles(all_meshes)

out = os.path.abspath(os.path.dirname(__file__) + '/../models/npc_hod_v2.glb')
export_glb(root, out)
print(f"npc_hod_v2 — H={H}, archetype={ARCHETYPE}, total height "
      f"{3 * H:.3f}m, sockets={len(sockets)}")
