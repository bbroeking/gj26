"""Maud v2 — eighth proof of the head-height anchor template.

Maud Pennycress, the village matron. Silver-haired, sharp-tongued,
flour-dusted apron over a russet dress. Built fresh on the head-height
template at H=0.32, archetype='npc' — same proportions as Eldra/Pell,
but with a sturdier-cut shawl and a kitchen-themed prop set.

Aux parts via sockets:
  - Silver bun + side-strands → socket_helmet_top
  - Knit shawl + drape         → socket_chin       (wraps over shoulders)
  - Flour-dusted apron + tie   → socket_belt_front (front body coverage)
  - Wooden spoon               → socket_hand_R     (cooking implement)

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_npc_maud_v2.py

Output: models/npc_maud_v2.glb
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

# Maud palette — village matron warmth.
RUSSET_DRESS  = (0.55, 0.32, 0.22)        # main dress
RUSSET_DARK   = (0.42, 0.24, 0.18)        # dress trim / hem
APRON_CREAM   = (0.92, 0.86, 0.72)        # flour-dusted apron
FLOUR_DUST    = (0.96, 0.94, 0.88)        # patchy flour smudges
SHAWL_NAVY    = (0.30, 0.32, 0.42)        # knit shawl (slightly muted blue-grey)
SILVER_HAIR   = (0.82, 0.82, 0.80)
SKIN          = (0.92, 0.78, 0.65)
SPOON_OAK     = (0.55, 0.40, 0.22)
BOOT_BROWN    = (0.32, 0.22, 0.14)
EYE_DARK      = (0.10, 0.06, 0.04)
TIE_DARK      = (0.42, 0.30, 0.18)        # apron tie

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(2.0, -2.0, 1.0), cam_target=(0, 0, H * 1.5))

rig   = anchor_skeleton(H, ARCHETYPE)
biped = biped_pivots_only(rig)

# --- TORSO (subdivided into 4 vertical panels for visual interest) ---
# Bodice (upper chest) — slightly tighter, darker russet for shading.
body_z   = biped['Body'][2]
bodice_z = body_z + 0.45 * H        # upper chest
midriff_z= body_z + 0.05 * H        # mid torso (where apron tie sits)
waist_z  = body_z - 0.45 * H        # lower waist (where skirt joins)
make_cube('Body_bodice',  (0, 0, bodice_z),
          (1.40 * H, 1.05 * H, 0.55 * H), RUSSET_DARK)
make_cube('Body_midriff', (0, 0, midriff_z),
          (1.42 * H, 1.06 * H, 0.45 * H), RUSSET_DRESS)
make_cube('Body_waist',   (0, 0, waist_z),
          (1.45 * H, 1.08 * H, 0.30 * H), RUSSET_DARK)
# Lace-up panel (cream stripe down centre of bodice).
make_cube('Body_lacing',
          (0, -0.55 * H, bodice_z),
          (0.18 * H, 0.06 * H, 0.50 * H), APRON_CREAM)
# Three small dark crosshatch stitches over the lacing.
for i, dz in enumerate((0.18, 0.00, -0.18)):
    make_cube(f'Body_lace_stitch_{i}',
              (0, -0.58 * H, bodice_z + dz * H),
              (0.20 * H, 0.04 * H, 0.04 * H), TIE_DARK)
# Collar — thin band at the throat.
make_cube('Body_collar',
          (0, -0.50 * H, body_z + 0.78 * H),
          (1.10 * H, 0.10 * H, 0.16 * H), APRON_CREAM)

# Skirt — subdivided into 3 vertical panels (left / centre / right) so
# it reads as folded fabric rather than one block.
skirt_z = (biped['Leg_L'][2] + biped['Body'][2]) * 0.5
for i, sx in enumerate((-0.50, 0.00, 0.50)):
    col = RUSSET_DARK if i != 1 else RUSSET_DRESS
    width = 0.55 * H if i != 1 else 0.50 * H
    make_cube(f'Body_skirt_panel_{i}',
              (sx * H, 0, skirt_z - 0.20 * H),
              (width, 1.10 * H, 0.95 * H), col)
# Skirt hem — darker band at the bottom.
make_cube('Body_skirt_hem',
          (0, 0, skirt_z - 0.65 * H),
          (1.60 * H, 1.15 * H, 0.12 * H), TIE_DARK)

# --- HEAD + FACE (now with nose, ears, jaw, brows) ---
make_cube('Head_skull', biped['Head'],
          (1.0 * H, 0.95 * H, 0.95 * H), SKIN)

# Jaw / chin — small rectangle protruding below the skull, slightly
# narrower so it reads as "tucked under cheekbones".
make_cube('Head_jaw',
          (0, -0.10 * H, biped['Head'][2] - 0.45 * H),
          (0.75 * H, 0.85 * H, 0.20 * H), SKIN)

# Ears — small protrusions on each side.
for sx, name in ((-0.55, 'Head_ear_L'), (0.55, 'Head_ear_R')):
    make_cube(name, (sx * H, 0, biped['Head'][2]),
              (0.12 * H, 0.20 * H, 0.25 * H), SKIN)

# Nose — small forward protrusion at mid-face.
make_cube('Head_nose',
          (0, -0.55 * H, biped['Head'][2] - 0.05 * H),
          (0.16 * H, 0.16 * H, 0.20 * H), SKIN)

# Brows — thin dark bars above the eyes (silver-hair brows).
for sx, name in ((-0.22, 'Head_brow_L'), (0.22, 'Head_brow_R')):
    make_cube(name, (sx * H, -0.50 * H, biped['Head'][2] + 0.18 * H),
              (0.20 * H, 0.06 * H, 0.06 * H), SILVER_HAIR)

# Sharp eyes — slightly squinted for the "shrewd matron" read.
eye_y = -0.51 * H
eye_z = biped['Head'][2] + 0.05 * H
for sx, name in ((-0.22, 'Head_eye_L'), (0.22, 'Head_eye_R')):
    make_cube(name, (sx * H, eye_y, eye_z),
              (0.14 * H, 0.04 * H, 0.10 * H), EYE_DARK)

# Cheek apples — soft warm patches where the smile lines would be.
for sx, name in ((-0.32, 'Head_cheek_L'), (0.32, 'Head_cheek_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] - 0.12 * H),
              (0.16 * H, 0.04 * H, 0.12 * H), (0.94, 0.62, 0.55))

# Pursed mouth — narrow rectangle.
make_cube('Head_mouth',
          (0, -0.51 * H, biped['Head'][2] - 0.30 * H),
          (0.22 * H, 0.04 * H, 0.06 * H), (0.50, 0.30, 0.25))

# Smile-line creases (Maud's "shrewd but kind" cue).
for sx, name in ((-0.18, 'Head_smile_L'), (0.18, 'Head_smile_R')):
    make_cube(name, (sx * H, -0.51 * H, biped['Head'][2] - 0.22 * H),
              (0.06 * H, 0.04 * H, 0.06 * H), (0.50, 0.30, 0.25))

# Arms — russet dress sleeves.
for side, name in ((-1, 'Arm_L'), (1, 'Arm_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.65 * H),
              (0.50 * H, 0.55 * H, 1.30 * H), RUSSET_DRESS)
    # Cuff at the wrist — apron-cream sleeve roll.
    make_cube(f'{name}_cuff',
              (pivot[0], pivot[1], pivot[2] - 1.30 * H),
              (0.58 * H, 0.62 * H, 0.18 * H), APRON_CREAM)

# Legs (under skirt — mostly hidden) + sturdy brown boots.
for side, name in ((-1, 'Leg_L'), (1, 'Leg_R')):
    pivot = biped[name]
    make_cube(name,
              (pivot[0], pivot[1], pivot[2] - 0.75 * H),
              (0.55 * H, 0.65 * H, 1.45 * H), RUSSET_DARK)
    make_cube(f'{name}_boot',
              (pivot[0], pivot[1] - 0.05 * H, pivot[2] - 1.50 * H),
              (0.62 * H, 0.85 * H, 0.30 * H), BOOT_BROWN)

# ---- rig + sockets ----------------------------------------------------
root, empties, mesh_objs = rig_biped(biped, 'Maud_v2_Root', biped_parent_for)
sockets = materialise_sockets(rig, empties)

# ---- aux parts pinned to sockets --------------------------------------

# Silver bun on top of the head — single high knot + a couple of side-
# strands escaping at the temples.
attach_to_socket(
    make_cube('Aux_bun',
              (0, 0.20 * H, biped['Head'][2] + 0.55 * H),
              (0.85 * H, 0.85 * H, 0.55 * H), SILVER_HAIR),
    sockets['socket_helmet_top'],
)
# Side strands at temples.
attach_to_socket(
    make_cube('Aux_strand_L',
              (-0.45 * H, -0.05 * H, biped['Head'][2] + 0.20 * H),
              (0.18 * H, 0.20 * H, 0.45 * H), SILVER_HAIR),
    sockets['socket_helmet_top'],
)
attach_to_socket(
    make_cube('Aux_strand_R',
              (0.45 * H, -0.05 * H, biped['Head'][2] + 0.20 * H),
              (0.18 * H, 0.20 * H, 0.45 * H), SILVER_HAIR),
    sockets['socket_helmet_top'],
)

# Knit shawl — wraps over the shoulders + behind the neck. Two pieces
# for visual depth (top wrap + drape down each side).
attach_to_socket(
    make_cube('Aux_shawl_neck',
              (0, 0, biped['Head'][2] - 0.50 * H),
              (1.65 * H, 1.20 * H, 0.40 * H), SHAWL_NAVY),
    sockets['socket_chin'],
)
# Drape down the front-left side.
attach_to_socket(
    make_cube('Aux_shawl_drape_L',
              (-0.55 * H, -0.45 * H, biped['Head'][2] - 1.00 * H),
              (0.30 * H, 0.10 * H, 0.65 * H), SHAWL_NAVY),
    sockets['socket_chin'],
)
# Drape down the front-right side (slightly shorter — uneven for character).
attach_to_socket(
    make_cube('Aux_shawl_drape_R',
              (0.55 * H, -0.45 * H, biped['Head'][2] - 0.90 * H),
              (0.28 * H, 0.10 * H, 0.55 * H), SHAWL_NAVY),
    sockets['socket_chin'],
)

# Flour-dusted apron — main panel covering chest + belly. Tie at the
# top knots around the neck (visible just below the shawl).
attach_to_socket(
    make_cube('Aux_apron',
              (0, -0.55 * H, biped['Body'][2] + 0.10 * H),
              (1.30 * H, 0.10 * H, 1.45 * H), APRON_CREAM),
    sockets['socket_belt_front'],
)
# Tie at the apron neckline.
attach_to_socket(
    make_cube('Aux_apron_tie',
              (0, -0.55 * H, biped['Body'][2] + 0.85 * H),
              (0.65 * H, 0.08 * H, 0.16 * H), TIE_DARK),
    sockets['socket_belt_front'],
)
# Flour-dust patches on the apron (irregular, off-centre).
attach_to_socket(
    make_cube('Aux_flour_a',
              (-0.25 * H, -0.58 * H, biped['Body'][2] + 0.20 * H),
              (0.40 * H, 0.06 * H, 0.30 * H), FLOUR_DUST),
    sockets['socket_belt_front'],
)
attach_to_socket(
    make_cube('Aux_flour_b',
              (0.30 * H, -0.58 * H, biped['Body'][2] - 0.10 * H),
              (0.30 * H, 0.06 * H, 0.18 * H), FLOUR_DUST),
    sockets['socket_belt_front'],
)
# Apron belt-strap horizontal across the waist.
attach_to_socket(
    make_cube('Aux_apron_belt',
              (0, -0.58 * H, biped['Body'][2] - 0.40 * H),
              (1.45 * H, 0.08 * H, 0.18 * H), TIE_DARK),
    sockets['socket_belt_front'],
)

# Wooden spoon — held in right hand. Long handle + big oval bowl at the
# top. Pinned to socket_hand_R so the grip is the rotation pivot.
spoon_grip_x = biped['Arm_R'][0] + 0.15 * H
spoon_grip_z = biped['Arm_R'][2] - 1.00 * H
spoon_top_z  = biped['Arm_R'][2] + 0.20 * H
attach_to_socket(
    make_cube('Aux_spoon_handle',
              (spoon_grip_x, -0.20 * H, (spoon_grip_z + spoon_top_z) / 2),
              (0.10 * H, 0.10 * H, abs(spoon_top_z - spoon_grip_z)), SPOON_OAK),
    sockets['socket_hand_R'],
)
# Spoon bowl — rounded oval at the top.
attach_to_socket(
    make_cube('Aux_spoon_bowl',
              (spoon_grip_x, -0.20 * H, spoon_top_z + 0.15 * H),
              (0.30 * H, 0.20 * H, 0.30 * H), SPOON_OAK),
    sockets['socket_hand_R'],
)

# ---- finalise ---------------------------------------------------------
all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
# Maud is a hero NPC — village matron, recurring quest-giver. Build at
# level 3 (subsurf=3 + pre_subdivide=2) so she reads as the most polished
# member of the cast. Other NPCs use the level-2 default.
apply_bevel_remove_doubles(all_meshes, subsurf_level=3, pre_subdivide=2)

out = os.path.abspath(os.path.dirname(__file__) + '/../models/npc_maud_v2.glb')
export_glb(root, out)
print(f"npc_maud_v2 — H={H}, archetype={ARCHETYPE}, total height "
      f"{3 * H:.3f}m, sockets={len(sockets)}")
