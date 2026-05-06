"""Bramble Imp v4 — fourth template proof, validating the SHORT end of the
height spectrum (archetype='imp', 2.5 heads tall).

The imp is the player's most-encountered foe: small thorn-fae, scampers,
hits with a bramble-claw. Visual signature is twigs sprouting from the
crown of its head + green glowing eyes. The point of building it on the
template is to confirm that:

  - Chibi proportions (~40% of body height = head) emerge naturally
    when archetype='imp' is selected.
  - Sockets scale correctly at small H — a twig at socket_helmet_top
    sits properly on the crown, not floating in the air.

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_bramble_imp_v4.py

Output: models/bramble_imp_v4.glb
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
ARCHETYPE = 'imp'        # 2.5 heads tall — chibi enemy

# Bramble-imp palette — bramble-mossy creature, glowing eyes.
SKIN_MOSS   = (0.32, 0.42, 0.22)        # dark mossy green
TUNIC_THORN = (0.28, 0.20, 0.14)        # thorny brown
EYE_GLOW    = (0.45, 1.00, 0.55)        # bright glowing green
EYE_EMIT    = (0.30, 0.90, 0.40)
TWIG_BARK   = (0.18, 0.12, 0.08)        # dark woodbark brown
CLAW_HORN   = (0.12, 0.08, 0.05)        # blackened thorn
TOOTH_PALE  = (0.85, 0.82, 0.74)        # pale yellow

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(1.6, -1.6, 0.8), cam_target=(0, 0, H * 1.0))

rig   = anchor_skeleton(H, ARCHETYPE)
biped = biped_pivots_only(rig)

# Torso — chunky little body. Wider than knight (1.4H vs 1.5H) but
# shorter (1.2H total height since the imp is squat).
make_cube('Body_torso', biped['Body'],
          (1.40 * H, 0.85 * H, 1.20 * H), TUNIC_THORN)

# A small bramble-shoulders cap — looks like the body grows briars.
make_cube('Body_shoulders',
          (0, 0, biped['Body'][2] + 0.50 * H),
          (1.55 * H, 0.95 * H, 0.30 * H), SKIN_MOSS)

# Head — full 1.0H cube. At 2.5H total this naturally reads as a big
# chibi head, ~40% of total body height.
make_cube('Head_skull', biped['Head'],
          (1.0 * H, 0.95 * H, 1.0 * H), SKIN_MOSS)

# Glowing green eyes — emissive so they read in shadow. Slightly forward
# and just above center.
eye_y = -0.50 * H
eye_z = biped['Head'][2] + 0.10 * H
for sx, name in ((-0.22, 'Head_eye_L'), (0.22, 'Head_eye_R')):
    make_cube(name, (sx * H, eye_y, eye_z),
              (0.20 * H, 0.05 * H, 0.20 * H),
              EYE_GLOW, EYE_EMIT, 2.0)

# Tooth row — small pale teeth visible below the eyes (gives the imp a
# grin without needing a full mouth model).
make_cube('Head_teeth',
          (0, -0.50 * H, biped['Head'][2] - 0.18 * H),
          (0.48 * H, 0.04 * H, 0.10 * H), TOOTH_PALE)

# Arms — stubby, 1.0H length (vs knight's 1.4H).
for side, name in ((-1, 'Arm_L'), (1, 'Arm_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.50 * H),
              (0.40 * H, 0.40 * H, 1.00 * H), SKIN_MOSS)

# Legs — short, mossy.
for side, name in ((-1, 'Leg_L'), (1, 'Leg_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.50 * H),
              (0.45 * H, 0.50 * H, 1.00 * H), SKIN_MOSS)
    # Bramble-foot (small claw block at the bottom).
    make_cube(f'{name}_foot',
              (pivot[0], pivot[1] - 0.05 * H, pivot[2] - 1.05 * H),
              (0.50 * H, 0.65 * H, 0.20 * H), CLAW_HORN)

# ---- rig + sockets ----------------------------------------------------
root, empties, mesh_objs = rig_biped(biped, 'BrambleImp_v4_Root', biped_parent_for)
sockets = materialise_sockets(rig, empties)

# ---- aux parts pinned to sockets --------------------------------------

# Crown of twigs — three thorny shoots sprouting from the top of the head,
# all parented to socket_helmet_top so when Head rotates per-frame, the
# twigs go with the skull (no floating crown). Each twig has a slight
# X / Y offset to read as a cluster.
TWIG_OFFSETS = [
    (-0.18, 0.05, 0.50),    # left, slightly back
    ( 0.05, -0.10, 0.55),   # center-right, slightly forward
    ( 0.20, 0.10, 0.45),    # right
]
for i, (dx, dy, dz) in enumerate(TWIG_OFFSETS):
    attach_to_socket(
        make_cube(f'Aux_twig_{i}',
                  (dx * H, dy * H, biped['Head'][2] + dz * H),
                  (0.10 * H, 0.10 * H, 0.55 * H), TWIG_BARK),
        sockets['socket_helmet_top'],
    )

# Bramble claw on the right hand — chunky talon-block, pinned at
# socket_hand_R so the grip is the rotation pivot when the arm swings.
claw_grip_x = biped['Arm_R'][0]
claw_grip_z = biped['Arm_R'][2] - 0.95 * H
attach_to_socket(
    make_cube('Aux_claw_root',
              (claw_grip_x, -0.10 * H, claw_grip_z),
              (0.45 * H, 0.45 * H, 0.30 * H), CLAW_HORN),
    sockets['socket_hand_R'],
)
# Three sprout-talons radiating out from the claw root.
TALON_OFFSETS = [
    ( 0.00, -0.30,  0.00),
    (-0.20, -0.20, -0.10),
    ( 0.20, -0.20, -0.10),
]
for i, (dx, dy, dz) in enumerate(TALON_OFFSETS):
    attach_to_socket(
        make_cube(f'Aux_talon_{i}',
                  (claw_grip_x + dx * H, dy * H, claw_grip_z + dz * H),
                  (0.10 * H, 0.10 * H, 0.40 * H), CLAW_HORN),
        sockets['socket_hand_R'],
    )

# A small bramble-belt at belt-front for visual mass — the imp's "thorn
# girdle" hinted at in lore. Skipping a back socket since imps don't carry
# anything on their backs.
attach_to_socket(
    make_cube('Aux_thorn_belt',
              (0, -0.45 * H, biped['Body'][2] - 0.35 * H),
              (1.30 * H, 0.10 * H, 0.20 * H), TWIG_BARK),
    sockets['socket_belt_front'],
)

# ---- finalise ---------------------------------------------------------
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
apply_bevel_remove_doubles(all_meshes)

out = os.path.abspath(os.path.dirname(__file__) + '/../models/bramble_imp_v4.glb')
export_glb(root, out)
print(f"bramble_imp_v4 — H={H}, archetype={ARCHETYPE}, total height "
      f"{2.5 * H:.3f}m, sockets={len(sockets)}")
