"""Eldra v2 — concept-art-driven rebuild matching docs/concept-art/npc-eldra-lampwright.png.

Eldra the Lampwright is a stocky gnome-like elder, NOT a slim grandmother
(earlier interpretation). The concept shows a round, bearded, kindly old
soul carrying a gnarled hooked staff with hanging lanterns and a backpack
bundle of oil pots and herbs.

Built fresh on the head-height anchor template at H=0.34 (slightly
larger head than standard NPC, gnome-leaning silhouette), archetype='npc'.

The script is exhaustive — ~50 visible features from the concept art
become individual cubes. Heavy authoring trade-off; the result is a
silhouette that matches the concept rather than approximating it.

Aux parts via sockets (all six in active use):
  - Multi-tuft white hair         → socket_helmet_top
  - Big bushy beard + mustache    → socket_chin
  - Layered tabard / shawl front  → socket_belt_front
  - Leather hip satchel           → socket_belt_front
  - Backpack bundle (herbs+pots)  → socket_back
  - Hooked lantern staff          → socket_hand_R
  - (left hand free for animation)

Run headless:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python scripts/build_npc_eldra_v2.py

Output: models/npc_eldra_v2.glb
"""
import sys, os, math, random, colorsys
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__) + '/..'))

import bpy
from scripts._build_lib import (
    reset_scene, make_cube, make_cone, make_cylinder, make_sphere,
    rig_biped, biped_parent_for, apply_bevel_remove_doubles,
    apply_cast_modifier, export_glb,
)
from scripts._skin_lib import (
    add_mixamo_armature, bind_pieces_to_bones, add_walk_action,
    export_glb_skinned, eldra_mesh_to_bone,
)
from scripts.blender.template import (
    anchor_skeleton, biped_pivots_only,
    materialise_sockets, attach_to_socket,
    JOINT_PARENTS,
)

# ---- variant switch ---------------------------------------------------
# ELDRA_VARIANT env var picks one of the iteration prompts in
# docs/prompts/eldra_iterations.md:
#   '' (default)     — current best baseline (npc_eldra_v2.glb)
#   'a' (tapered)    — limbs taper from joint to extremity (stacked cubes)
#   'b' (asymmetric) — jittered hair, off-centre beard, head tilt
#   'c' (round_form) — selective subsurf=3 on head dome + lanterns + nose
#   'e' (primitives) — limbs as truncated cones, head as ovoid sphere,
#                      lantern bodies as octagonal cylinders, hand/foot
#                      as cylinders. Plus Cast modifier on shoulder + hip
#                      caps (0.4), torso panels (0.2), beard (0.5).
#   's' (skinned)    — variant E geometry + a real Mixamo-named armature
#                      replacing the empty rig. Per-piece rigid weights
#                      (each mesh's verts → 100% to one bone), simple
#                      sin-based walk action baked in. Skinned GLB export
#                      with embedded clip — drives via THREE.AnimationMixer
#                      instead of per-frame group rotation. Phase 1
#                      validation only; joints are still rigid (Phase 2
#                      adds blended weights for fluid bending).
# Each variant writes to models/npc_eldra_v2_<variant>.glb so they can
# be A/B'd in the codex Models tab.
VARIANT = (os.environ.get('ELDRA_VARIANT') or '').lower()
random.seed(42 if VARIANT == 'b' else 0)  # repeatable jitter for variant B

# ---- autoresearch knobs (drive iteration via env vars) ----------------
# These are layered ON TOP of the VARIANT mechanism — set ELDRA_VARIANT='s'
# to get the skinned base, then dial in form/cast/skip overrides for the
# specific experiment.
#   ELDRA_SKIP_GRASS=1     — drop the floaty Body_grass_*/Body_leaf_sprout
#                             cubes (they're ground decoration, not body).
#   ELDRA_FORM_MERGE=N     — body simplification level, 0..3:
#       0  = full panel detail (default)
#       1  = drop nano-detail (stitch / motif / weave / drawstring / buckle)
#       2  = above + drop tabard_low + shawl drapes, merge tabard mid into top
#       3  = above + tunic/shawl simplified to single forms, no inner tunic
#   ELDRA_BODY_CAST=F      — additional Cast factor (0.0..0.6) on torso
#                             panels (tunic_core, shawl_top, apron, skirt).
#                             Run alongside variant 's' or 'e'.
#   ELDRA_PALETTE=key      — color palette override:
#       'osrs' (default) | 'warm' (+10% saturation, warmer) | 'storybook'
#       (slightly desaturated, painterly) | 'high_contrast' (saturated cell)
#   ELDRA_OUT_NAME=str     — override output filename suffix (default: VARIANT).
SKIP_GRASS  = bool(int(os.environ.get('ELDRA_SKIP_GRASS', '0') or '0'))
FORM_MERGE  = int(os.environ.get('ELDRA_FORM_MERGE', '0') or '0')
BODY_CAST   = float(os.environ.get('ELDRA_BODY_CAST', '0') or '0')
PALETTE_KEY = (os.environ.get('ELDRA_PALETTE') or 'osrs').lower()
OUT_NAME    = os.environ.get('ELDRA_OUT_NAME') or ''

# ---- design knobs ------------------------------------------------------
H         = 0.34         # bigger head: gnome-like proportion
ARCHETYPE = 'npc'        # 3 heads tall

# ---- palette (matched to concept art) ---------------------------------
SKIN_PINK    = (0.96, 0.78, 0.66)         # warm peach
CHEEK_PINK   = (0.94, 0.62, 0.55)         # ruddy cheeks
EYE_DARK     = (0.20, 0.14, 0.10)         # squinted eye slits
NOSE_PINK    = (0.92, 0.70, 0.58)         # slightly redder than skin

HAIR_WHITE   = (0.94, 0.92, 0.88)         # wispy white hair
HAIR_SHADOW  = (0.78, 0.76, 0.72)         # underside of hair tufts
BEARD_WHITE  = (0.92, 0.90, 0.84)         # bushy beard

CREAM_TUNIC  = (0.92, 0.86, 0.72)         # central tunic panel
TUNIC_SEAM   = (0.78, 0.70, 0.55)         # darker seam stripes
TUNIC_VINE   = (0.55, 0.65, 0.32)         # embroidered leaf motif

NAVY_SHAWL   = (0.20, 0.28, 0.34)         # outer dark teal/navy shawl-vest
NAVY_DARK    = (0.12, 0.18, 0.24)         # shadow side of shawl
SAGE_TABARD  = (0.45, 0.55, 0.34)         # sage triangular front
SAGE_DARK    = (0.34, 0.42, 0.26)

LEATHER_BR   = (0.50, 0.32, 0.18)         # belt + apron wrap
LEATHER_TAN  = (0.62, 0.45, 0.28)         # satchel + lighter leather
LEATHER_DK   = (0.32, 0.20, 0.12)         # buckle + strap dark

PANT_TAN     = (0.55, 0.46, 0.32)         # rough-weave trousers
PANT_DK      = (0.42, 0.34, 0.22)         # vertical weave stripes
SANDAL_TAN   = (0.45, 0.32, 0.20)         # leather sandal sole
SANDAL_STRP  = (0.32, 0.22, 0.14)         # sandal toe straps

LANTERN_BR   = (0.52, 0.38, 0.18)         # brass / oxidized rim
LANTERN_GLOW = (0.98, 0.82, 0.40)         # warm yellow inside-glow
WOOD_KNARL   = (0.42, 0.30, 0.18)         # gnarled wood
LEAFVINE     = (0.38, 0.50, 0.26)         # green vine wrapped on staff

POT_OLIVE    = (0.42, 0.45, 0.30)         # oil pot olive-grey
POT_DK       = (0.28, 0.30, 0.20)         # pot base/foot
HERB_GREEN   = (0.45, 0.55, 0.28)         # herb sprigs
HERB_LEAF    = (0.55, 0.65, 0.35)         # lighter leaves

GRASS_GREEN  = (0.50, 0.62, 0.30)         # ground tufts

# ---- palette transforms ------------------------------------------------
# The 30 color constants above are the OSRS-saturated baseline. The wiki
# (`art/theory/color-and-lighting.md` §2) prescribes a 5-8 hue budget per
# asset and ONE saturation peak. ELDRA_PALETTE_MODE rewrites the constants
# in-place (after they're authored, before any make_cube call sees them):
#
#   'osrs'    — leave as-is (default).
#   'desat'   — multiply saturation by 0.6 on every color EXCEPT
#               LANTERN_GLOW. Tests "one saturation peak" by leaving the
#               warm yellow as the only fully-saturated swatch.
#   'reduced' — alias similar colors to a single anchor swatch (collapses
#               the 30 colors to 8). Tests the per-asset hue budget.
def _hsl_desat(rgb, factor):
    h, l, s = colorsys.rgb_to_hls(*rgb)
    return colorsys.hls_to_rgb(h, l, max(0.0, min(1.0, s * factor)))

if PALETTE_KEY == 'desat':
    _SAT_FACTOR = 0.55
    _PROTECTED = {'LANTERN_GLOW'}
    for _name in ['SKIN_PINK','CHEEK_PINK','EYE_DARK','NOSE_PINK','HAIR_WHITE',
                  'HAIR_SHADOW','BEARD_WHITE','CREAM_TUNIC','TUNIC_SEAM',
                  'TUNIC_VINE','NAVY_SHAWL','NAVY_DARK','SAGE_TABARD','SAGE_DARK',
                  'LEATHER_BR','LEATHER_TAN','LEATHER_DK','PANT_TAN','PANT_DK',
                  'SANDAL_TAN','SANDAL_STRP','LANTERN_BR','WOOD_KNARL','LEAFVINE',
                  'POT_OLIVE','POT_DK','HERB_GREEN','HERB_LEAF','GRASS_GREEN']:
        if _name in _PROTECTED:
            continue
        globals()[_name] = _hsl_desat(globals()[_name], _SAT_FACTOR)
elif PALETTE_KEY == 'reduced':
    # Collapse to 8 anchor swatches. Map every named color to one of:
    #   SKIN, HAIR, FABRIC_LIGHT, FABRIC_DARK, LEATHER, METAL, GLOW, GREEN.
    SKIN          = (0.96, 0.78, 0.66)        # was SKIN_PINK
    HAIR          = (0.92, 0.90, 0.84)        # was HAIR_WHITE / BEARD_WHITE
    FABRIC_LIGHT  = (0.92, 0.86, 0.72)        # was CREAM_TUNIC / TUNIC_SEAM
    FABRIC_DARK   = (0.20, 0.28, 0.34)        # was NAVY_SHAWL / NAVY_DARK
    LEATHER       = (0.50, 0.32, 0.18)        # was LEATHER_BR / SANDAL / PANT_DK
    METAL         = (0.52, 0.38, 0.18)        # was LANTERN_BR / POT_DK / WOOD_KNARL
    GLOW          = (0.98, 0.82, 0.40)        # was LANTERN_GLOW (THE saturation peak)
    GREEN         = (0.45, 0.55, 0.28)        # was SAGE_TABARD / HERB / LEAFVINE / GRASS
    # rebind every name to one of those anchors — same visual language,
    # smaller hue vocabulary
    SKIN_PINK = NOSE_PINK = SKIN
    CHEEK_PINK    = (0.94, 0.62, 0.55)        # one accent — cheek apples are the
                                              # only allowed warm-pink off-skin
    EYE_DARK      = (0.18, 0.12, 0.08)        # near-black for eye slits
    HAIR_WHITE = HAIR_SHADOW = BEARD_WHITE = HAIR
    CREAM_TUNIC = TUNIC_SEAM = FABRIC_LIGHT
    TUNIC_VINE = SAGE_TABARD = SAGE_DARK = LEAFVINE = HERB_GREEN = HERB_LEAF = GRASS_GREEN = GREEN
    NAVY_SHAWL = NAVY_DARK = FABRIC_DARK
    LEATHER_BR = LEATHER_TAN = LEATHER_DK = PANT_TAN = PANT_DK = SANDAL_TAN = SANDAL_STRP = LEATHER
    LANTERN_BR = WOOD_KNARL = POT_OLIVE = POT_DK = METAL
    LANTERN_GLOW  = GLOW

# ---- build -------------------------------------------------------------
reset_scene(cam_loc=(2.0, -2.0, 1.0), cam_target=(0, 0, H * 1.5))

rig   = anchor_skeleton(H, ARCHETYPE, segmented=True)
# biped_pivots_only returns just Body/Head/Arm_L/R/Leg_L/R. We extend with
# the secondary joints (Knee_L/R, Elbow_L/R) so rig_biped creates empties
# for them too. The chain parenting is handled via joint_parents.
biped = biped_pivots_only(rig)
biped['Knee_L']  = rig['Knee_L']
biped['Knee_R']  = rig['Knee_R']
biped['Elbow_L'] = rig['Elbow_L']
biped['Elbow_R'] = rig['Elbow_R']

body_z = biped['Body'][2]
head_z = biped['Head'][2]
hip_z  = biped['Leg_L'][2]

# ============================================================
# (A) BODY — stocky gnome silhouette, layered shawl + tunic
# ============================================================
# Inner cream tunic core (peeks through at chest centre).
make_cube('Body_tunic_core', biped['Body'],
          (1.20 * H, 0.95 * H, 1.45 * H), CREAM_TUNIC)

# Outer navy shawl-vest covering shoulders + upper torso.
make_cube('Body_shawl_top',
          (0, 0.05 * H, body_z + 0.55 * H),
          (1.55 * H, 1.10 * H, 0.45 * H), NAVY_SHAWL)
# Shawl wraps around mid-back.
make_cube('Body_shawl_back',
          (0, 0.30 * H, body_z + 0.20 * H),
          (1.40 * H, 0.30 * H, 0.65 * H), NAVY_DARK)
# Shawl drape down the front sides — secondary panels, drop at merge >= 2.
if FORM_MERGE < 2:
    make_cube('Body_shawl_drape_L',
              (-0.55 * H, -0.45 * H, body_z + 0.10 * H),
              (0.30 * H, 0.10 * H, 0.70 * H), NAVY_SHAWL)
    make_cube('Body_shawl_drape_R',
              (0.55 * H, -0.45 * H, body_z + 0.10 * H),
              (0.30 * H, 0.10 * H, 0.70 * H), NAVY_SHAWL)

# Sage triangular tabard hanging from neck down chest. At FORM_MERGE >= 2
# the tabard collapses to a single taller top piece (mid + low merged in).
make_cube('Body_tabard_top',
          (0, -0.50 * H, body_z + 0.40 * H),
          (0.85 * H, 0.10 * H, 0.50 * H), SAGE_TABARD)
if FORM_MERGE < 2:
    make_cube('Body_tabard_mid',
              (0, -0.50 * H, body_z + 0.00 * H),
              (0.65 * H, 0.10 * H, 0.40 * H), SAGE_DARK)
    make_cube('Body_tabard_low',
              (0, -0.50 * H, body_z - 0.30 * H),
              (0.45 * H, 0.10 * H, 0.20 * H), SAGE_TABARD)
elif FORM_MERGE >= 2:
    # Single elongated tabard from chest to belt, replaces top + mid + low.
    make_cube('Body_tabard_merged',
              (0, -0.50 * H, body_z + 0.05 * H),
              (0.85 * H, 0.10 * H, 1.05 * H), SAGE_TABARD)

# Cream tunic centre-stripe — kept until FORM_MERGE >= 3 (not yet supported).
make_cube('Body_tunic_centre',
          (0, -0.49 * H, body_z + 0.10 * H),
          (0.16 * H, 0.06 * H, 0.95 * H), CREAM_TUNIC)
# Nano-detail (stitches, motif): drop at FORM_MERGE >= 1 — at chunky-character
# scale these are 4-pixel features that wash out anyway.
if FORM_MERGE < 1:
    for i, dz in enumerate((0.30, 0.05, -0.20)):
        make_cube(f'Body_stitch_{i}',
                  (0, -0.50 * H, body_z + dz * H),
                  (0.20 * H, 0.04 * H, 0.04 * H), TUNIC_SEAM)
    for i, (sx, sz) in enumerate(((-0.06, 0.18), (0.06, 0.05), (0, -0.10))):
        make_cube(f'Body_motif_{i}',
                  (sx * H, -0.50 * H, body_z + sz * H),
                  (0.08 * H, 0.04 * H, 0.06 * H), TUNIC_VINE)

# Brown leather waist wrap (overlay across the lower torso).
make_cube('Body_apron_wrap',
          (0, -0.40 * H, body_z - 0.55 * H),
          (1.25 * H, 0.95 * H, 0.30 * H), LEATHER_BR)
# Belt across the wrap.
make_cube('Body_belt',
          (0, -0.55 * H, body_z - 0.40 * H),
          (1.40 * H, 0.10 * H, 0.16 * H), LEATHER_DK)
# Buckle — small detail, drop at merge >= 1.
if FORM_MERGE < 1:
    make_cube('Body_belt_buckle',
              (0, -0.62 * H, body_z - 0.40 * H),
              (0.18 * H, 0.06 * H, 0.18 * H), LANTERN_BR)

# Lower body — short coat-skirt that flares at the hem.
skirt_z = (hip_z + body_z) * 0.5
make_cube('Body_skirt',
          (0, 0, skirt_z - 0.20 * H),
          (1.45 * H, 1.00 * H, 0.65 * H), CREAM_TUNIC)
# Hem trim — drop at merge >= 1.
if FORM_MERGE < 1:
    make_cube('Body_skirt_hem',
              (0, 0, skirt_z - 0.55 * H),
              (1.50 * H, 1.02 * H, 0.12 * H), TUNIC_SEAM)

# ============================================================
# (B) HEAD — round chubby face, closed eyes, big beard hidden via socket_chin
# ============================================================
# Variant E swaps the cube skull for a UV sphere squished slightly vertically
# (ovoid). Same overall dimensions as the cube so other head-mounted parts
# (eyes, nose, brows, hair sockets) keep their offsets.
if VARIANT in ('e', 's'):
    make_sphere('Head_skull', biped['Head'],
                (1.10 * H, 1.05 * H, 0.95 * H), SKIN_PINK,
                segments=16, rings=8)
else:
    make_cube('Head_skull', biped['Head'],
              (1.10 * H, 1.05 * H, 0.95 * H), SKIN_PINK)

# Round chubby jaw — wider than skull at the cheeks.
make_cube('Head_jaw',
          (0, -0.12 * H, head_z - 0.42 * H),
          (1.00 * H, 0.95 * H, 0.25 * H), SKIN_PINK)

# Bulbous round nose — large, central, slightly down-tilted.
make_cube('Head_nose_bridge',
          (0, -0.55 * H, head_z + 0.00 * H),
          (0.18 * H, 0.16 * H, 0.20 * H), SKIN_PINK)
make_cube('Head_nose_tip',
          (0, -0.62 * H, head_z - 0.10 * H),
          (0.24 * H, 0.18 * H, 0.16 * H), NOSE_PINK)

# Closed/squinted eye slits (small dark lines, not full eyeballs).
for sx, name in ((-0.22, 'Head_eye_L'), (0.22, 'Head_eye_R')):
    make_cube(name, (sx * H, -0.51 * H, head_z + 0.05 * H),
              (0.16 * H, 0.04 * H, 0.04 * H), EYE_DARK)

# Drooping bushy white eyebrows (wider than eyes, tilted slightly).
for sx, name in ((-0.22, 'Head_brow_L'), (0.22, 'Head_brow_R')):
    make_cube(name, (sx * H, -0.50 * H, head_z + 0.18 * H),
              (0.30 * H, 0.06 * H, 0.10 * H), HAIR_WHITE)

# Round ruddy cheek apples.
for sx, name in ((-0.40, 'Head_cheek_L'), (0.40, 'Head_cheek_R')):
    make_cube(name, (sx * H, -0.50 * H, head_z - 0.10 * H),
              (0.22 * H, 0.06 * H, 0.18 * H), CHEEK_PINK)

# Soft mouth (mostly hidden by mustache later — a small dark line here).
make_cube('Head_mouth',
          (0, -0.51 * H, head_z - 0.32 * H),
          (0.18 * H, 0.04 * H, 0.04 * H), (0.55, 0.32, 0.25))

# ============================================================
# (C) ARMS + LEGS + SANDALS
# ============================================================
# --- SHOULDER + HIP CAPS (R15 rule: cap geometry lives on the TORSO, not
# the rotating limb, so the silhouette doesn't pop the moment a limb
# swings. The Body_* prefix routes them to the Body empty.) ---
for prefix in ('L', 'R'):
    arm_pivot = biped[f'Arm_{prefix}']
    leg_pivot = biped[f'Leg_{prefix}']
    # Shoulder cap — sits at the shoulder pivot, parented to Body.
    make_cube(f'Body_shoulder_{prefix}',
              (arm_pivot[0], arm_pivot[1], arm_pivot[2] + 0.05 * H),
              (0.65 * H, 0.62 * H, 0.22 * H), NAVY_SHAWL)
    # Hip cap — sits at the hip pivot, parented to Body.
    make_cube(f'Body_hip_{prefix}',
              (leg_pivot[0], leg_pivot[1], leg_pivot[2] + 0.05 * H),
              (0.70 * H, 0.72 * H, 0.20 * H), PANT_TAN)

# --- ARMS (segmented limb: upper arm + elbow + forearm + hand stub).
# Limb meshes only extend AWAY from the torso — their TOP face sits at
# the shoulder pivot so a rotation swings them down without exposing a
# gap above. Variant 'a' replaces each segment with 3 tapering stacked
# cubes (wide near joint, narrow toward extremity).
for side, prefix in ((-1, 'L'), (1, 'R')):
    arm_pivot   = biped[f'Arm_{prefix}']
    elbow_pivot = biped[f'Elbow_{prefix}']
    upper_h = arm_pivot[2] - elbow_pivot[2]
    wrist_z = elbow_pivot[2] - 0.45 * H
    forearm_h = elbow_pivot[2] - wrist_z
    if VARIANT == 'a':
        # Tapered upper arm — 3 cubes stepping from 0.60H wide at shoulder
        # down to 0.42H at elbow. Stack their centres along the arm axis.
        for k, (top_frac, bot_frac, w_top, w_bot) in enumerate((
            (1.00, 0.66, 0.60, 0.55),
            (0.66, 0.33, 0.55, 0.48),
            (0.33, 0.00, 0.48, 0.42),
        )):
            seg_top_z = arm_pivot[2] - upper_h * (1 - top_frac)
            seg_bot_z = arm_pivot[2] - upper_h * (1 - bot_frac)
            make_cube(f'UpperArm_{prefix}_t{k}',
                      (arm_pivot[0], arm_pivot[1], (seg_top_z + seg_bot_z) / 2),
                      ((w_top + w_bot) * 0.5 * H,
                       (w_top + w_bot) * 0.5 * H,
                       seg_top_z - seg_bot_z), CREAM_TUNIC)
        # Tapered forearm — 0.42H at elbow → 0.32H at wrist.
        for k, (top_frac, bot_frac, w_top, w_bot) in enumerate((
            (1.00, 0.50, 0.42, 0.37),
            (0.50, 0.00, 0.37, 0.32),
        )):
            seg_top_z = elbow_pivot[2] - forearm_h * (1 - top_frac)
            seg_bot_z = elbow_pivot[2] - forearm_h * (1 - bot_frac)
            make_cube(f'Forearm_{prefix}_t{k}',
                      (arm_pivot[0], arm_pivot[1], (seg_top_z + seg_bot_z) / 2),
                      ((w_top + w_bot) * 0.5 * H,
                       (w_top + w_bot) * 0.5 * H,
                       seg_top_z - seg_bot_z), CREAM_TUNIC)
    elif VARIANT in ('e', 's'):
        # Single truncated cone per limb segment — true taper, smooth
        # cross-section (12 verts), no stacked-cube stair-step. Top radius
        # at the joint, bottom radius narrower at the next joint down.
        upper_z = (arm_pivot[2] + elbow_pivot[2]) / 2
        make_cone(f'UpperArm_{prefix}_sleeve',
                  (arm_pivot[0], arm_pivot[1], upper_z),
                  top_r=0.30 * H, bot_r=0.24 * H,
                  height=upper_h, color=CREAM_TUNIC)
        forearm_z = (elbow_pivot[2] + wrist_z) / 2
        make_cone(f'Forearm_{prefix}_sleeve',
                  (arm_pivot[0], arm_pivot[1], forearm_z),
                  top_r=0.21 * H, bot_r=0.16 * H,
                  height=forearm_h, color=CREAM_TUNIC)
    else:
        upper_z = (arm_pivot[2] + elbow_pivot[2]) / 2
        make_cube(f'UpperArm_{prefix}_sleeve',
                  (arm_pivot[0], arm_pivot[1], upper_z),
                  (0.55 * H, 0.55 * H, upper_h), CREAM_TUNIC)
        forearm_z = (elbow_pivot[2] + wrist_z) / 2
        make_cube(f'Forearm_{prefix}_sleeve',
                  (arm_pivot[0], arm_pivot[1], forearm_z),
                  (0.50 * H, 0.50 * H, forearm_h), CREAM_TUNIC)
    # Wrist cuff — leather strap. Smaller in tapered variants.
    cuff_w = 0.45 if VARIANT in ('a', 'e', 's') else 0.55
    make_cube(f'Forearm_{prefix}_cuff',
              (arm_pivot[0], arm_pivot[1], wrist_z + 0.04 * H),
              (cuff_w * H, cuff_w * H, 0.12 * H), LEATHER_BR)
    # Hand stub — smaller in tapered variants (narrower wrist). Variant E
    # uses a 12-side cylinder so the wrist meets the cuff with a round
    # silhouette instead of a square one.
    hand_w = 0.32 if VARIANT in ('a', 'e', 's') else 0.42
    if VARIANT in ('e', 's'):
        make_cylinder(f'Hand_{prefix}_stub',
                      (arm_pivot[0], arm_pivot[1], wrist_z - 0.10 * H),
                      (hand_w * H, hand_w * H, 0.18 * H), SKIN_PINK,
                      verts=12)
    else:
        make_cube(f'Hand_{prefix}_stub',
                  (arm_pivot[0], arm_pivot[1], wrist_z - 0.10 * H),
                  (hand_w * H, hand_w * H, 0.18 * H), SKIN_PINK)

# --- LEGS (segmented limb: thigh + knee + shin + foot). Same R15 rule —
# the hip cap is on Body (above), the thigh's TOP sits AT the hip pivot. ---
for side, prefix in ((-1, 'L'), (1, 'R')):
    leg_pivot  = biped[f'Leg_{prefix}']
    knee_pivot = biped[f'Knee_{prefix}']
    thigh_h = leg_pivot[2] - knee_pivot[2]
    ankle_top = 0.10
    shin_h    = knee_pivot[2] - ankle_top
    if VARIANT == 'a':
        # Tapered thigh — 0.78H at hip → 0.55H at knee, 3 stacked cubes.
        for k, (top_frac, bot_frac, w_top, w_bot) in enumerate((
            (1.00, 0.66, 0.78, 0.70),
            (0.66, 0.33, 0.70, 0.62),
            (0.33, 0.00, 0.62, 0.55),
        )):
            seg_top_z = leg_pivot[2] - thigh_h * (1 - top_frac)
            seg_bot_z = leg_pivot[2] - thigh_h * (1 - bot_frac)
            make_cube(f'Thigh_{prefix}_t{k}',
                      (leg_pivot[0], leg_pivot[1], (seg_top_z + seg_bot_z) / 2),
                      ((w_top + w_bot) * 0.5 * H,
                       (w_top + w_bot) * 0.5 * H * 1.08,
                       seg_top_z - seg_bot_z), PANT_TAN)
        # Tapered shin — 0.55H at knee → 0.42H at ankle, 2 stacked cubes.
        for k, (top_frac, bot_frac, w_top, w_bot) in enumerate((
            (1.00, 0.50, 0.55, 0.48),
            (0.50, 0.00, 0.48, 0.42),
        )):
            seg_top_z = knee_pivot[2] - shin_h * (1 - top_frac)
            seg_bot_z = knee_pivot[2] - shin_h * (1 - bot_frac)
            make_cube(f'Shin_{prefix}_t{k}',
                      (leg_pivot[0], leg_pivot[1], (seg_top_z + seg_bot_z) / 2),
                      ((w_top + w_bot) * 0.5 * H,
                       (w_top + w_bot) * 0.5 * H * 1.08,
                       seg_top_z - seg_bot_z), PANT_TAN)
    elif VARIANT in ('e', 's'):
        # Single cone per leg segment. Skip the 3-stripe weave detail —
        # flat cubes pinned to a curved cone surface read as floating
        # decals; the silhouette gain is worth losing the texture cue.
        thigh_z = (leg_pivot[2] + knee_pivot[2]) / 2
        make_cone(f'Thigh_{prefix}',
                  (leg_pivot[0], leg_pivot[1], thigh_z),
                  top_r=0.39 * H, bot_r=0.28 * H,
                  height=thigh_h, color=PANT_TAN)
        shin_z = (knee_pivot[2] + ankle_top) / 2
        make_cone(f'Shin_{prefix}',
                  (leg_pivot[0], leg_pivot[1], shin_z),
                  top_r=0.275 * H, bot_r=0.21 * H,
                  height=shin_h, color=PANT_TAN)
    else:
        thigh_z = (leg_pivot[2] + knee_pivot[2]) / 2
        make_cube(f'Thigh_{prefix}',
                  (leg_pivot[0], leg_pivot[1], thigh_z),
                  (0.60 * H, 0.65 * H, thigh_h), PANT_TAN)
        # Vertical weave stripes on thigh (3 darker lines).
        for j, sx_off in enumerate((-0.18, 0, 0.18)):
            make_cube(f'Thigh_{prefix}_weave_{j}',
                      (leg_pivot[0] + sx_off * H, leg_pivot[1] - 0.32 * H, thigh_z),
                      (0.06 * H, 0.04 * H, thigh_h * 0.85), PANT_DK)
        shin_z    = (knee_pivot[2] + ankle_top) / 2
        make_cube(f'Shin_{prefix}',
                  (leg_pivot[0], leg_pivot[1], shin_z),
                  (0.55 * H, 0.60 * H, shin_h), PANT_TAN)
    # Cuff band at bottom of shin.
    make_cube(f'Shin_{prefix}_cuff',
              (leg_pivot[0], leg_pivot[1], ankle_top + 0.04 * H),
              (0.60 * H, 0.65 * H, 0.10 * H), PANT_DK)
    # Sandal sole — wide flat tan leather. Variant E uses an oval cylinder
    # (12 sides, dx != dy) so the foot reads round in plan view rather
    # than as a brick.
    if VARIANT in ('e', 's'):
        make_cylinder(f'Foot_{prefix}_sandal',
                      (leg_pivot[0], leg_pivot[1] - 0.10 * H, 0.05),
                      (0.65 * H, 0.95 * H, 0.10), SANDAL_TAN, verts=12)
    else:
        make_cube(f'Foot_{prefix}_sandal',
                  (leg_pivot[0], leg_pivot[1] - 0.10 * H, 0.05),
                  (0.65 * H, 0.95 * H, 0.10), SANDAL_TAN)
    # Toe strap.
    make_cube(f'Foot_{prefix}_toestrap',
              (leg_pivot[0], leg_pivot[1] - 0.30 * H, 0.10),
              (0.55 * H, 0.10 * H, 0.06), SANDAL_STRP)
    # Heel strap.
    make_cube(f'Foot_{prefix}_heelstrap',
              (leg_pivot[0], leg_pivot[1] + 0.20 * H, 0.10),
              (0.50 * H, 0.10 * H, 0.06), SANDAL_STRP)

# ---- rig + sockets ----------------------------------------------------
root, empties, mesh_objs = rig_biped(biped, 'Eldra_v2_Root',
                                     biped_parent_for, JOINT_PARENTS)
sockets = materialise_sockets(rig, empties)
# Re-parent the hand sockets onto the elbow joints so the elbow bend
# carries the held items along (without this, the staff would tear off
# the hand the moment the elbow flexes).
for hand_sock, elbow_name in (('socket_hand_L', 'Elbow_L'),
                              ('socket_hand_R', 'Elbow_R')):
    sock = sockets[hand_sock]; eb = empties[elbow_name]
    wm = sock.matrix_world.copy()
    sock.parent = eb
    sock.matrix_parent_inverse = eb.matrix_world.inverted()
    sock.matrix_world = wm

# ============================================================
# (D) HAIR — multiple wispy tufts (NOT a smooth bun)
# ============================================================
# Top crown tuft.
attach_to_socket(
    make_cube('Aux_hair_crown',
              (0, 0.05 * H, head_z + 0.55 * H),
              (0.85 * H, 0.85 * H, 0.32 * H), HAIR_WHITE),
    sockets['socket_helmet_top'],
)
# Five individual spike-tufts radiating out + up from crown.
hair_spikes = (
    (-0.30, 0.10, 0.78), (0.30, 0.10, 0.78),                    # left + right top spikes
    (0.00, -0.20, 0.85),                                          # forward top
    (-0.45, -0.10, 0.55), (0.45, -0.10, 0.55),                    # side temples
    (-0.20, 0.40, 0.62), (0.20, 0.40, 0.62),                      # back top
)
for i, (sx, sy, sz) in enumerate(hair_spikes):
    # Variant B jitters each tuft so the head reads as hand-painted, not
    # mirror-symmetric. Position ±0.04H, height ±0.10H, width ±25%.
    if VARIANT == 'b':
        jx = (random.random() - 0.5) * 0.08
        jy = (random.random() - 0.5) * 0.08
        jz = (random.random() - 0.5) * 0.20
        jw = 1.0 + (random.random() - 0.5) * 0.50
    else:
        jx = jy = jz = 0; jw = 1.0
    attach_to_socket(
        make_cube(f'Aux_hair_tuft_{i}',
                  ((sx + jx) * H, (sy + jy) * H, head_z + (sz + jz) * H),
                  (0.18 * H * jw, 0.18 * H * jw, 0.30 * H * jw), HAIR_WHITE),
        sockets['socket_helmet_top'],
    )
# Subtle shadow band along the back-bottom of the crown (kerchief-line cue).
attach_to_socket(
    make_cube('Aux_hair_band',
              (0, 0.45 * H, head_z + 0.30 * H),
              (0.95 * H, 0.20 * H, 0.18 * H), HAIR_SHADOW),
    sockets['socket_helmet_top'],
)

# ============================================================
# (E) BEARD — big bushy white, covering chin + chest
# ============================================================
# Main beard mass — wide and full.
attach_to_socket(
    make_cube('Aux_beard_main',
              (0, -0.40 * H, head_z - 0.55 * H),
              (1.05 * H, 0.40 * H, 0.65 * H), BEARD_WHITE),
    sockets['socket_chin'],
)
# Lower beard — narrower extension down to chest.
attach_to_socket(
    make_cube('Aux_beard_lower',
              (0, -0.45 * H, head_z - 1.05 * H),
              (0.75 * H, 0.30 * H, 0.45 * H), BEARD_WHITE),
    sockets['socket_chin'],
)
# Beard tip (narrowest at the bottom).
attach_to_socket(
    make_cube('Aux_beard_tip',
              (0, -0.50 * H, head_z - 1.42 * H),
              (0.40 * H, 0.20 * H, 0.20 * H), BEARD_WHITE),
    sockets['socket_chin'],
)
# Mustache — left + right curls under the nose.
attach_to_socket(
    make_cube('Aux_mustache_L',
              (-0.18 * H, -0.55 * H, head_z - 0.30 * H),
              (0.24 * H, 0.10 * H, 0.16 * H), BEARD_WHITE),
    sockets['socket_chin'],
)
attach_to_socket(
    make_cube('Aux_mustache_R',
              (0.18 * H, -0.55 * H, head_z - 0.30 * H),
              (0.24 * H, 0.10 * H, 0.16 * H), BEARD_WHITE),
    sockets['socket_chin'],
)
# Mustache outer drooping curls.
attach_to_socket(
    make_cube('Aux_mustache_curl_L',
              (-0.32 * H, -0.55 * H, head_z - 0.45 * H),
              (0.16 * H, 0.10 * H, 0.18 * H), BEARD_WHITE),
    sockets['socket_chin'],
)
attach_to_socket(
    make_cube('Aux_mustache_curl_R',
              (0.32 * H, -0.55 * H, head_z - 0.45 * H),
              (0.16 * H, 0.10 * H, 0.18 * H), BEARD_WHITE),
    sockets['socket_chin'],
)

# ============================================================
# (F) HIP SATCHEL — leather pouch hanging from the front-right belt
# ============================================================
attach_to_socket(
    make_cube('Aux_satchel_body',
              (0.45 * H, -0.65 * H, body_z - 0.55 * H),
              (0.40 * H, 0.30 * H, 0.45 * H), LEATHER_TAN),
    sockets['socket_belt_front'],
)
# Satchel flap.
attach_to_socket(
    make_cube('Aux_satchel_flap',
              (0.45 * H, -0.68 * H, body_z - 0.40 * H),
              (0.40 * H, 0.06 * H, 0.18 * H), LEATHER_BR),
    sockets['socket_belt_front'],
)
# Satchel strap up to belt.
attach_to_socket(
    make_cube('Aux_satchel_strap',
              (0.45 * H, -0.65 * H, body_z - 0.30 * H),
              (0.10 * H, 0.06 * H, 0.18 * H), LEATHER_DK),
    sockets['socket_belt_front'],
)
# Drawstring detail.
attach_to_socket(
    make_cube('Aux_satchel_drawstring',
              (0.45 * H, -0.70 * H, body_z - 0.55 * H),
              (0.06 * H, 0.04 * H, 0.20 * H), LEATHER_DK),
    sockets['socket_belt_front'],
)

# ============================================================
# (G) BACK BUNDLE — herb sprigs + oil pots over the left shoulder
# ============================================================
# Strap going across the body.
attach_to_socket(
    make_cube('Aux_strap_back',
              (0, 0.40 * H, body_z + 0.30 * H),
              (1.10 * H, 0.10 * H, 0.10 * H), LEATHER_DK),
    sockets['socket_back'],
)
# Lower oil pot — bulbous olive-grey body.
attach_to_socket(
    make_cube('Aux_pot_body',
              (-0.45 * H, 0.50 * H, body_z + 0.10 * H),
              (0.40 * H, 0.40 * H, 0.45 * H), POT_OLIVE),
    sockets['socket_back'],
)
# Pot foot/base (darker).
attach_to_socket(
    make_cube('Aux_pot_foot',
              (-0.45 * H, 0.50 * H, body_z - 0.20 * H),
              (0.36 * H, 0.36 * H, 0.10 * H), POT_DK),
    sockets['socket_back'],
)
# Pot glow — warm yellow at the bottom (hint of a candle inside).
attach_to_socket(
    make_cube('Aux_pot_glow',
              (-0.45 * H, 0.50 * H, body_z - 0.10 * H),
              (0.30 * H, 0.30 * H, 0.10 * H), LANTERN_GLOW),
    sockets['socket_back'],
)
# Upper smaller oil pot.
attach_to_socket(
    make_cube('Aux_pot2_body',
              (-0.30 * H, 0.55 * H, body_z + 0.55 * H),
              (0.30 * H, 0.30 * H, 0.32 * H), POT_OLIVE),
    sockets['socket_back'],
)
attach_to_socket(
    make_cube('Aux_pot2_foot',
              (-0.30 * H, 0.55 * H, body_z + 0.40 * H),
              (0.26 * H, 0.26 * H, 0.08 * H), POT_DK),
    sockets['socket_back'],
)

# Herb sprig cluster — leafy greens sticking up over the shoulder.
herb_positions = (
    (-0.55, 0.50, 0.85, 0.20),
    (-0.40, 0.55, 0.95, 0.22),
    (-0.20, 0.50, 0.88, 0.18),
    (-0.05, 0.55, 0.78, 0.16),
)
for i, (sx, sy, sz, w) in enumerate(herb_positions):
    # Stem.
    attach_to_socket(
        make_cube(f'Aux_herb_stem_{i}',
                  (sx * H, sy * H, body_z + (sz - 0.20) * H),
                  (0.05 * H, 0.05 * H, 0.40 * H), HERB_GREEN),
        sockets['socket_back'],
    )
    # Leaves at top.
    attach_to_socket(
        make_cube(f'Aux_herb_leaf_{i}',
                  (sx * H, sy * H, body_z + sz * H),
                  (w * H, w * H, 0.18 * H), HERB_LEAF),
        sockets['socket_back'],
    )

# ============================================================
# (H) HOOKED LANTERN STAFF — gnarled, with curve at top + 2 lanterns
# ============================================================
staff_x   = biped['Arm_R'][0] + 0.20 * H
staff_low = biped['Arm_R'][2] - 1.30 * H        # bottom of staff at floor
staff_top = biped['Arm_R'][2] + 1.30 * H        # top of staff above head

# Main vertical staff shaft.
attach_to_socket(
    make_cube('Aux_staff_shaft',
              (staff_x, -0.20 * H, (staff_low + staff_top) / 2),
              (0.14 * H, 0.14 * H, abs(staff_top - staff_low)), WOOD_KNARL),
    sockets['socket_hand_R'],
)
# Gnarled bumps along the staff.
for i, dz in enumerate((-0.80, -0.30, 0.30, 0.85)):
    attach_to_socket(
        make_cube(f'Aux_staff_knot_{i}',
                  (staff_x, -0.20 * H, biped['Arm_R'][2] + dz * H),
                  (0.20 * H, 0.20 * H, 0.10 * H), WOOD_KNARL),
        sockets['socket_hand_R'],
    )
# Hook at top — three short cubes forming the curve.
attach_to_socket(
    make_cube('Aux_staff_hook_a',
              (staff_x, -0.20 * H, staff_top),
              (0.16 * H, 0.16 * H, 0.18 * H), WOOD_KNARL),
    sockets['socket_hand_R'],
)
attach_to_socket(
    make_cube('Aux_staff_hook_b',
              (staff_x - 0.15 * H, -0.20 * H, staff_top + 0.10 * H),
              (0.30 * H, 0.16 * H, 0.16 * H), WOOD_KNARL),
    sockets['socket_hand_R'],
)
attach_to_socket(
    make_cube('Aux_staff_hook_c',
              (staff_x - 0.30 * H, -0.20 * H, staff_top + 0.00 * H),
              (0.16 * H, 0.16 * H, 0.30 * H), WOOD_KNARL),
    sockets['socket_hand_R'],
)
# Green vine wrapped on upper staff (3 leaves).
for i, (dz, sx_off) in enumerate(((0.70, 0.05), (0.45, -0.05), (1.10, 0.10))):
    attach_to_socket(
        make_cube(f'Aux_staff_vine_{i}',
                  (staff_x + sx_off * H, -0.30 * H, biped['Arm_R'][2] + dz * H),
                  (0.18 * H, 0.10 * H, 0.16 * H), LEAFVINE),
        sockets['socket_hand_R'],
    )

# Variant E swaps the lantern bodies (caps, glow, mid-band) to 8-side
# cylinders so they read as octagonal cans rather than little cubes. The
# hanging loops and wire ribs stay as thin cubes — at their scale the
# silhouette difference is invisible and they survive subsurf cleanly.
def _lantern_body(name, loc, dims, color):
    if VARIANT in ('e', 's'):
        return make_cylinder(name, loc, dims, color, verts=8)
    return make_cube(name, loc, dims, color)

# Upper lantern (smaller). Hangs from the hook.
ul_x = staff_x - 0.35 * H
ul_z = biped['Arm_R'][2] + 0.95 * H
# Lantern hanging-loop.
attach_to_socket(
    make_cube('Aux_lant1_loop',
              (ul_x, -0.20 * H, ul_z + 0.18 * H),
              (0.06 * H, 0.06 * H, 0.10 * H), LANTERN_BR),
    sockets['socket_hand_R'],
)
# Brass top cap.
attach_to_socket(
    _lantern_body('Aux_lant1_top',
                  (ul_x, -0.20 * H, ul_z + 0.10 * H),
                  (0.20 * H, 0.20 * H, 0.06 * H), LANTERN_BR),
    sockets['socket_hand_R'],
)
# Glow body.
attach_to_socket(
    _lantern_body('Aux_lant1_glow',
                  (ul_x, -0.20 * H, ul_z),
                  (0.18 * H, 0.18 * H, 0.18 * H), LANTERN_GLOW),
    sockets['socket_hand_R'],
)
# Wire ribs (4 thin bars).
for i, (dx, dy) in enumerate(((-0.10, 0), (0.10, 0), (0, -0.10), (0, 0.10))):
    attach_to_socket(
        make_cube(f'Aux_lant1_rib_{i}',
                  (ul_x + dx * H, -0.20 * H + dy * H, ul_z),
                  (0.03 * H, 0.03 * H, 0.20 * H), LANTERN_BR),
        sockets['socket_hand_R'],
    )
# Brass bottom cap.
attach_to_socket(
    _lantern_body('Aux_lant1_bot',
                  (ul_x, -0.20 * H, ul_z - 0.10 * H),
                  (0.20 * H, 0.20 * H, 0.05 * H), LANTERN_BR),
    sockets['socket_hand_R'],
)

# Lower lantern (larger). Hangs further down the staff.
ll_x = staff_x - 0.05 * H
ll_z = biped['Arm_R'][2] + 0.10 * H
attach_to_socket(
    make_cube('Aux_lant2_loop',
              (ll_x, -0.20 * H, ll_z + 0.30 * H),
              (0.06 * H, 0.06 * H, 0.10 * H), LANTERN_BR),
    sockets['socket_hand_R'],
)
attach_to_socket(
    _lantern_body('Aux_lant2_top',
                  (ll_x, -0.20 * H, ll_z + 0.20 * H),
                  (0.28 * H, 0.28 * H, 0.08 * H), LANTERN_BR),
    sockets['socket_hand_R'],
)
attach_to_socket(
    _lantern_body('Aux_lant2_glow',
                  (ll_x, -0.20 * H, ll_z),
                  (0.26 * H, 0.26 * H, 0.30 * H), LANTERN_GLOW),
    sockets['socket_hand_R'],
)
# Wire ribs (4 thin bars + 2 horizontal mid-bands).
for i, (dx, dy) in enumerate(((-0.14, 0), (0.14, 0), (0, -0.14), (0, 0.14))):
    attach_to_socket(
        make_cube(f'Aux_lant2_rib_{i}',
                  (ll_x + dx * H, -0.20 * H + dy * H, ll_z),
                  (0.03 * H, 0.03 * H, 0.32 * H), LANTERN_BR),
        sockets['socket_hand_R'],
    )
# Mid-band (around middle of lantern).
attach_to_socket(
    _lantern_body('Aux_lant2_band',
                  (ll_x, -0.20 * H, ll_z + 0.00 * H),
                  (0.30 * H, 0.30 * H, 0.04 * H), LANTERN_BR),
    sockets['socket_hand_R'],
)
attach_to_socket(
    _lantern_body('Aux_lant2_bot',
                  (ll_x, -0.20 * H, ll_z - 0.18 * H),
                  (0.28 * H, 0.28 * H, 0.06 * H), LANTERN_BR),
    sockets['socket_hand_R'],
)

# ============================================================
# (I) GROUND DETAIL — small grass tufts at her feet (cosmetic)
# ============================================================
# These are at world space, parented to root via biped_parent_for fallback.
# Note: they won't follow walking animation perfectly — but they read as
# "she's standing in her garden" in the codex viewer. Skip via env var
# ELDRA_SKIP_GRASS=1 for skinned/walking variants where they look like
# floating dirt-clumps left behind during the walk cycle.
if not SKIP_GRASS:
    make_cube('Body_grass_L',
              (-0.55 * H, -0.20 * H, 0.04),
              (0.18 * H, 0.16 * H, 0.10), GRASS_GREEN)
    make_cube('Body_grass_R',
              (0.55 * H, 0.10 * H, 0.04),
              (0.14 * H, 0.14 * H, 0.08), GRASS_GREEN)
    make_cube('Body_leaf_sprout',
              (-0.40 * H, -0.05 * H, 0.06),
              (0.10 * H, 0.10 * H, 0.16), HERB_LEAF)

# ---- finalise ---------------------------------------------------------
# The grass cubes (when authored — see SKIP_GRASS) don't have a parent-for
# hit so they'd be dropped. Re-parent them to the body so they ride along.
if not SKIP_GRASS:
    for grass_name in ('Body_grass_L', 'Body_grass_R', 'Body_leaf_sprout'):
        if grass_name in bpy.data.objects:
            obj = bpy.data.objects[grass_name]
            if not obj.parent and 'Body' in empties:
                wm = obj.matrix_world.copy()
                obj.parent = empties['Body']
                obj.matrix_parent_inverse = empties['Body'].matrix_world.inverted()
                obj.matrix_world = wm

all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']

if VARIANT in ('e', 's'):
    # Cast modifier on rounded-form pieces — pulls vertices toward a
    # sphere so cube panels bow outward and corners pull inward without
    # replacing the primitive. Stack order matters: Cast is added BEFORE
    # apply_bevel_remove_doubles so it sits ABOVE Bevel + Subsurf in the
    # stack and runs first at evaluation time. Tuned factors:
    #   shoulder/hip caps 0.4 — visibly soft "ball joint" silhouette
    #   beard cubes       0.5 — reads as puffy cloud, not blocky brick
    # NOTE: an earlier iteration also included the torso panels at 0.2,
    # but the sphere-pull on wide flat panels (shawl_top, apron_wrap)
    # bowed them into ellipsoids that broke the tabard/belt layering on
    # top. Dropped — the soft-form gain wasn't worth the layering loss.
    cast_factors = {
        'Body_shoulder_L': 0.4, 'Body_shoulder_R': 0.4,
        'Body_hip_L':      0.4, 'Body_hip_R':      0.4,
        'Aux_beard_main':  0.5, 'Aux_beard_lower': 0.5, 'Aux_beard_tip': 0.5,
    }
    # Autoresearch knob: ELDRA_BODY_CAST adds Cast modifier to the wide flat
    # torso panels so they bow into rounder forms instead of stacking. Use
    # CUBOID target (rounds corners only, doesn't bow flat faces) to avoid
    # the ellipsoid distortion that SPHERE caused on the original variant E.
    if BODY_CAST > 0:
        for n in ('Body_tunic_core', 'Body_shawl_top', 'Body_shawl_back',
                  'Body_apron_wrap', 'Body_skirt'):
            cast_factors.setdefault(n, BODY_CAST)
    for obj_name, factor in cast_factors.items():
        if obj_name in bpy.data.objects:
            target = 'CUBOID' if obj_name.startswith('Body_') and obj_name not in (
                'Body_shoulder_L', 'Body_shoulder_R', 'Body_hip_L', 'Body_hip_R'
            ) else 'SPHERE'
            apply_cast_modifier(bpy.data.objects[obj_name],
                                factor=factor, target=target)

if VARIANT == 'c':
    # Variant C bumps subsurf to level 3 on a curated set of round-form
    # candidates (head dome, lanterns, hair tufts, nose), and keeps the
    # rest at level 2. The result reads as "round forms attached to a
    # blockier body" — softens the most-visible silhouette pieces
    # without the polycount blowup of subsurf=3 across all 126 meshes.
    round_form_names = {
        'Head_skull', 'Head_nose_bridge', 'Head_nose_tip',
        'Aux_lant1_glow', 'Aux_lant1_top', 'Aux_lant1_bot',
        'Aux_lant2_glow', 'Aux_lant2_top', 'Aux_lant2_bot', 'Aux_lant2_band',
    }
    # Hair tufts + beard get the smooth treatment too.
    round_form_names.update(o.name for o in all_meshes
                            if o.name.startswith('Aux_hair_tuft_')
                            or o.name.startswith('Aux_beard'))
    high_detail = [o for o in all_meshes if o.name in round_form_names]
    rest        = [o for o in all_meshes if o.name not in round_form_names]
    apply_bevel_remove_doubles(rest, subsurf_level=2, pre_subdivide=1)
    apply_bevel_remove_doubles(high_detail, subsurf_level=3, pre_subdivide=2)
elif VARIANT in ('e', 's'):
    # The head sphere is already round; running it through the standard
    # pipeline (pre_subdivide + bevel) triggers the angle-limited bevel
    # on the UV sphere's shallow ring-edges, producing visible diagonal
    # banding around the poles. Split it out: subsurf=2 only, no bevel,
    # no pre_subdivide.
    head_sphere = [o for o in all_meshes if o.name == 'Head_skull']
    rest        = [o for o in all_meshes if o.name != 'Head_skull']
    apply_bevel_remove_doubles(rest)
    apply_bevel_remove_doubles(head_sphere, pre_subdivide=0,
                               bevel=False, subsurf_level=2)
else:
    apply_bevel_remove_doubles(all_meshes)

# Output filename — base, per-variant suffix for A/B/C/E/S, or autoresearch
# override via ELDRA_OUT_NAME=run_id (writes to models/npc_eldra_v2_<run_id>.glb).
if OUT_NAME:
    out_suffix = f'_{OUT_NAME}'
else:
    out_suffix = f'_{VARIANT}' if VARIANT else ''
out = os.path.abspath(os.path.dirname(__file__) +
                      f'/../models/npc_eldra_v2{out_suffix}.glb')

if VARIANT == 's':
    # ============================================================
    # SKINNED post-process — replace the empty-rig with a real
    # Mixamo-named Blender Armature, bind every authored mesh piece
    # to its matching bone via vertex groups (rigid weights, factor
    # 1.0 per piece), and bake a simple sin-based walk into the
    # armature's pose-bone keyframes. Then export with skins +
    # animations enabled. Phase 1 validation only — fluid joints
    # (Phase 2) require joining pieces and weight-painting near-
    # joint vertex blends.
    # ============================================================
    armature = add_mixamo_armature(biped, H, root_name='Eldra_v2_Armature')
    bound = bind_pieces_to_bones(all_meshes, armature, eldra_mesh_to_bone)
    walk_action = add_walk_action(armature, frames=24, fps=24, name='Walk')
    export_glb_skinned(armature, out)
    print(f"npc_eldra_v2{out_suffix} — SKINNED, H={H}, archetype={ARCHETYPE}, "
          f"bones={len(armature.data.bones)}, bound_meshes={bound}, "
          f"action='{walk_action.name}' ({int(walk_action.frame_range[1])}f), "
          f"total height {3 * H:.3f}m")
else:
    export_glb(root, out)
    print(f"npc_eldra_v2{out_suffix} — H={H}, archetype={ARCHETYPE}, "
          f"variant={VARIANT or 'main'}, total height {3 * H:.3f}m, "
          f"sockets={len(sockets)}, meshes={len(all_meshes)}")
