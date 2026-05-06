"""Knight v6 — first model authored on the head-height anchor template.

What's different from prior knight versions:
  - Every joint position derived from H (head diameter), not hardcoded
    metric values. Tweak H or change archetype heads → whole rig
    rescales coherently.
  - Auxiliary parts (helmet plume, beard, sword, shield, cape) are
    parented to NAMED SOCKET EMPTIES (socket_helmet_top, socket_chin,
    socket_hand_R, socket_back). Their object origins are placed AT
    THE SOCKET, so glTF preserves the attachment as the rotation pivot
    — they don't fly off when src/anim/knight.js rotates the head/arm
    groups per-frame.
  - All transforms applied (rotation, scale) before parenting, per
    feedback_blender_bevel_pipeline.md.

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_knight_v6.py

Output: models/knight_v6.glb
"""
import sys, os, math
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__) + '/..'))

import bpy, mathutils
from scripts._build_lib import (
    reset_scene, make_cube, rig_biped, biped_parent_for,
    apply_bevel_remove_doubles, export_glb,
)
from scripts.blender.template import (
    anchor_skeleton, biped_pivots_only,
    materialise_sockets, attach_to_socket,
)

# ---- design knobs ------------------------------------------------------
H         = 0.32          # head diameter (meters) — single source of truth
ARCHETYPE = 'knight'      # 4 heads tall

# Knight palette — toon-style, tuned against existing scripts.
COL_SKIN   = (0.82, 0.66, 0.50)
COL_HAIR   = (0.30, 0.20, 0.12)
COL_BEARD  = (0.35, 0.25, 0.15)
COL_TUNIC  = (0.32, 0.36, 0.50)
COL_LEATHER= (0.45, 0.30, 0.20)
COL_BOOT   = (0.20, 0.15, 0.10)
COL_METAL  = (0.62, 0.62, 0.66)
COL_GOLD   = (0.85, 0.70, 0.30)
COL_CAPE   = (0.45, 0.18, 0.18)

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(2.4, -2.4, 1.2), cam_target=(0, 0, H * 2.0))

# 1) Pull the canonical rig from the template. Single source of truth for
#    every joint position; downstream sizes derive from H too.
rig = anchor_skeleton(H, ARCHETYPE)
biped = biped_pivots_only(rig)

# 2) Body — chunky torso. Width = 1.5H, depth = 0.9H, height = 1.5H.
#    Position = Body joint center.
make_cube('Body_torso', biped['Body'],
          (1.5 * H, 0.9 * H, 1.5 * H), COL_TUNIC)

# 3) Belt — at the waist (between leg-top and body-center).
belt_z = (biped['Leg_L'][2] + biped['Body'][2]) * 0.5
make_cube('Body_belt', (0, 0, belt_z),
          (1.55 * H, 0.95 * H, 0.20 * H), COL_LEATHER)

# 4) Head — single head-sized cube at the head joint.
make_cube('Head_skull', biped['Head'],
          (1.0 * H, 1.0 * H, 1.0 * H), COL_SKIN)

# 5) Eyes (front of face = -Y, slightly above center).
eye_y = -0.5 * H
eye_z = biped['Head'][2] + 0.08 * H
for sx, name in ((-0.22, 'Head_eye_L'), (0.22, 'Head_eye_R')):
    make_cube(name, (sx * H, eye_y, eye_z),
              (0.16 * H, 0.04 * H, 0.16 * H), (0.05, 0.05, 0.08))

# 6) Hair — caps the top of the skull.
make_cube('Head_hair', (0, 0, biped['Head'][2] + 0.42 * H),
          (1.05 * H, 1.05 * H, 0.30 * H), COL_HAIR)

# 7) Arms — boxy, length 1.4H from shoulder.
for side, name in ((-1, 'Arm_L'), (1, 'Arm_R')):
    pivot = biped[name]
    # Arm extends DOWN from the pivot; mesh center is one head-length below.
    arm_center = (pivot[0], pivot[1], pivot[2] - 0.7 * H)
    make_cube(name, arm_center, (0.45 * H, 0.45 * H, 1.4 * H), COL_TUNIC)
    # Glove / hand at the bottom.
    make_cube(f'{name}_hand',
              (pivot[0], pivot[1], pivot[2] - 1.40 * H),
              (0.55 * H, 0.55 * H, 0.30 * H), COL_LEATHER)

# 8) Legs — length 1.5H from hip.
for side, name in ((-1, 'Leg_L'), (1, 'Leg_R')):
    pivot = biped[name]
    leg_center = (pivot[0], pivot[1], pivot[2] - 0.75 * H)
    make_cube(name, leg_center, (0.50 * H, 0.50 * H, 1.5 * H), COL_TUNIC)
    # Boot.
    make_cube(f'{name}_boot',
              (pivot[0], pivot[1], pivot[2] - 1.55 * H),
              (0.60 * H, 0.70 * H, 0.30 * H), COL_BOOT)

# 9) Rig — empties + parent meshes by name prefix. Uses ONLY the 6 biped
#    pivots; sockets handled below so they parent to their pivot.
root, empties, mesh_objs = rig_biped(biped, 'Knight_v6_Root', biped_parent_for)

# 10) Materialise socket empties — one per SOCKET_OFFSETS entry, parented
#     to its corresponding rig pivot so per-frame animation rotations
#     carry attached props with the joint.
sockets = materialise_sockets(rig, empties)

# 11) Auxiliary parts — each authored at its design world position, then
#     pinned to a named socket. Origin moves to the socket so glTF
#     preserves the rotation pivot, eliminating "floating beard" drift.
attach_to_socket(
    make_cube('Aux_helmet', (0, 0, biped['Head'][2] + 0.40 * H),
              (1.10 * H, 1.10 * H, 0.55 * H), COL_METAL),
    sockets['socket_helmet_top'],
)
attach_to_socket(
    make_cube('Aux_plume', (0, 0, biped['Head'][2] + 0.85 * H),
              (0.16 * H, 0.30 * H, 0.50 * H), COL_GOLD),
    sockets['socket_helmet_top'],
)
attach_to_socket(
    make_cube('Aux_beard', (0, -0.40 * H, biped['Head'][2] - 0.55 * H),
              (0.50 * H, 0.20 * H, 0.50 * H), COL_BEARD),
    sockets['socket_chin'],
)
sword_pommel_z = biped['Arm_R'][2] - 1.10 * H
attach_to_socket(
    make_cube('Aux_sword_blade',
              (biped['Arm_R'][0] + 0.05 * H, 0, sword_pommel_z - 0.55 * H),
              (0.10 * H, 0.10 * H, 1.10 * H), COL_METAL),
    sockets['socket_hand_R'],
)
attach_to_socket(
    make_cube('Aux_shield',
              (biped['Arm_L'][0] - 0.20 * H, -0.45 * H,
               biped['Arm_L'][2] - 0.70 * H),
              (0.15 * H, 0.95 * H, 1.10 * H), COL_CAPE),
    sockets['socket_hand_L'],
)
attach_to_socket(
    make_cube('Aux_cape', (0, 0.50 * H, biped['Body'][2] - 0.20 * H),
              (1.20 * H, 0.10 * H, 1.40 * H), COL_CAPE),
    sockets['socket_back'],
)

# 12) Bevel + remove_doubles on every mesh (toon pipeline).
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
apply_bevel_remove_doubles(all_meshes)

# 13) Export.
out = os.path.abspath(os.path.dirname(__file__) + '/../models/knight_v6.glb')
export_glb(root, out)
print(f"knight_v6 — H={H}, archetype={ARCHETYPE}, total height "
      f"{4 * H:.3f}m, sockets={len(socket_empties)}")
