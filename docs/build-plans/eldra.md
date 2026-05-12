---
character: eldra
character_role: village lampwright (elderly grandfather figure)
date: 2026-05-06
version: 1
concept_art: docs/concept-art/npc-eldra-lampwright.png
heightM: 1.55
primary_shape: circle
secondary_shape: triangle
saturation_peak: lantern_flame
rig: 6-empty biped (no optional secondary joints in v1)
authored_via: concept-to-blender-plan skill
---

# Eldra — Build Plan

Village lampwright. Elderly chibi old-man — substantial white beard and hair, layered earth-tone clothes, brown leather backpack with herbs, and the silhouette-defining staff with two hanging lanterns. This plan is the build contract: every coordinate / dimension / material / shading mode is locked here, and the Blender script translates it mechanically.

---

## 1. Overall proportions

Squat chibi proportions — body is ~3.5 heads tall (chibi convention is 3-4). Head + hair alone occupy the top 30% of the figure; legs + feet about 35%; the torso/shoulders sit in the middle 35%. Standing pose, very still — both feet planted, weight even, staff held vertical in the right hand.

| name | value | notes |
|---|---|---|
| heightM | 1.55 | total height including hair tufts |
| head_fraction | 0.32 | head height ÷ total ≈ 1/3 (chibi) |
| shoulder_z | 0.95 | top of torso, shoulder pivot |
| hip_z | 0.55 | belt level, hip pivot |
| knee_z | 0.30 | mid-leg |
| ankle_z | 0.06 | foot top |
| neck_z | 1.00 | base of head |
| head_center_z | 1.12 | sphere center |
| head_top_z | 1.28 | top of head sphere |
| hair_top_z | 1.45 | tallest hair tuft |
| shoulder_width | 0.36 | lateral distance Arm_L↔Arm_R pivots (y-axis) |
| torso_width | 0.32 | front-back depth of vest at chest |
| hip_width | 0.20 | lateral distance Leg_L↔Leg_R pivots |
| limb_to_body_ratio | 0.5 | short stubby legs/arms (chibi) |
| primary_shape | circle | round head + cushion-soft body (kindly) |
| secondary_shape | triangle | staff + crook + lanterns rising past shoulder |

Authoring frame: face on +X, lateral on ±Y, up on +Z. Helper wrapper handles the +X→-Y conversion at export per `feedback_glb_orientation_two_tier_root.md`.

---

## 2. Palette

Locked palette — 10 hues. One saturation peak (`lantern_flame`) on the character-defining prop. Everything else ≤55% saturation. Slightly over the 5-8 ideal because the concept layers many earth tones; consolidations have already removed `nose`, `eye`, separate sandal/belt/staff/backpack browns (all unified to `leather`).

| role | hex | description | use |
|---|---|---|---|
| skin | `#f0c8a8` | peachy warm | head, hands, feet, neck |
| hair | `#f4f0e8` | off-white silver | hair, beard, eyebrows, mustache |
| tunic | `#e8d8b8` | cream | undershirt visible at neckline + sleeve cuff |
| vest | `#a87a48` | ochre / burnt orange | outer vest layer |
| scarf | `#4a6878` | dark teal | scarf around neck |
| trousers | `#7a8a78` | olive sage | knee-length pants |
| leather | `#6a4a2a` | medium leather brown | belt, pouch, backpack, sandal-wraps, staff wood |
| herb | `#5a7848` | sage green | backpack herb sprig + vest decorative stripe |
| lantern_body | `#b88440` | warm brass | lantern body, cap, base |
| **lantern_flame** | **`#ffd060`** | **warm gold + EMISSIVE 2.5** | **flame inside each lantern (saturation peak)** |

**Eyes:** use `leather` (#6a4a2a) for the dark eye-line — no separate eye material. Dark enough to read against skin without breaking the palette.

---

## 3. Silhouette mark + character-defining prop

**Primary silhouette feature:** voluminous white hair + beard cluster framing the round peachy face. Reads from a 64×64 thumbnail as "kindly old man" via the soft circular mass of head + hair + beard.

**Character-defining prop:** the wooden staff held in his right hand, rising past his shoulder, with a forward-curving crook at the top and TWO round lanterns hanging beneath. The lantern flames are the saturation peak — at gameplay distance the eye locks onto the warm glow first.

**Why these specifically:** without the staff he's just an old grandfather; with it he's *immediately* readable as "the lampwright." The hair + beard mass tells you he's elderly; the lantern tells you his profession. Both must read at thumbnail.

---

## 4. Parts list

Organized by parent rig group, in build order (anchor → decorative within each group). Composites (`STAFF`, `BEARD`, `HAIR`, `LANTERN`, `BACKPACK`) defined once, instantiated where needed.

### Body (parent: rig group `Body` at z=0.55)

```
Tunic_Body
  primitive  : box
  world_pos  : (0, 0, 0.78)
  dims       : (0.34, 0.28, 0.36)
  material   : tunic
  shading    : smooth
  notes      : cream undershirt; visible peek at neck + sleeve cuffs

Neck
  primitive  : cylinder
  world_pos  : (0, 0, 1.02)
  radius     : 0.09
  height     : 0.14
  material   : skin
  shading    : smooth
  notes      : bridges tunic top to head bottom — fixes "floating head"

Vest_Body
  primitive  : box
  world_pos  : (0, 0, 0.72)
  dims       : (0.38, 0.32, 0.34)
  material   : vest
  shading    : smooth
  notes      : ochre layer over tunic — slightly wider so it reads as outer

Vest_Stripe
  primitive  : box
  world_pos  : (0.16, 0, 0.62)
  dims       : (0.04, 0.30, 0.04)
  material   : herb (decorative green)
  shading    : flat
  notes      : embroidered band along the bottom hem of the vest

Vest_Skirt
  primitive  : box
  world_pos  : (0, 0, 0.55)
  dims       : (0.36, 0.30, 0.10)
  material   : vest
  shading    : smooth
  notes      : flares slightly toward hip; sits over the belt area

Scarf_Front
  primitive  : box
  world_pos  : (0.04, 0, 1.00)
  dims       : (0.26, 0.26, 0.12)
  material   : scarf
  shading    : smooth
  notes      : wraps the neck cylinder; overlaps Neck by ~0.02u to hide seam

Scarf_Tail
  primitive  : box
  world_pos  : (-0.04, 0.08, 0.92)
  dims       : (0.04, 0.08, 0.18)
  material   : scarf
  shading    : smooth
  notes      : fabric end hanging down on the right side

Belt
  primitive  : box
  world_pos  : (0, 0, 0.55)
  dims       : (0.36, 0.30, 0.04)
  material   : leather
  shading    : smooth
  notes      : dark band at waist

Pouch_R
  primitive  : box
  world_pos  : (0.05, 0.18, 0.50)
  dims       : (0.10, 0.06, 0.08)
  material   : leather
  shading    : smooth
  notes      : small bag hanging from belt on the right side

[BACKPACK composite — see composite recipes below]
```

### Head (parent: rig group `Head` at z=1.00)

```
Head_Mesh
  primitive  : sphere
  world_pos  : (0, 0, 1.12)
  radius     : 0.16
  scale      : (1.05, 1.0, 0.95)
  material   : skin
  shading    : smooth
  notes      : slightly wider than tall (kindly read)

Nose
  primitive  : sphere
  world_pos  : (0.16, 0, 1.10)
  radius     : 0.04
  material   : skin
  shading    : smooth
  notes      : bulbous, on the front face — character read for "old man"

Eye_L / Eye_R
  primitive  : sphere
  world_pos  : (0.155, ±0.06, 1.14)
  radius     : 0.018
  scale      : (1.0, 1.0, 0.5)
  material   : leather (dark eye-line)
  shading    : smooth
  notes      : peaceful, near-closed; flat ovals not full circles

Brow_L / Brow_R
  primitive  : box
  world_pos  : (0.15, ±0.06, 1.20)
  dims       : (0.04, 0.04, 0.02)
  material   : hair
  shading    : flat
  notes      : bushy white tufts above each eye

[BEARD composite — see composite recipes below]
[HAIR composite — see composite recipes below]
```

### Arm_L (parent: rig group `Arm_L` at y=-0.18, z=0.95) — empty hand

```
Sleeve_L
  primitive  : box
  world_pos  : (0, -0.24, 0.80)
  dims       : (0.12, 0.12, 0.30)
  material   : vest
  shading    : smooth

Cuff_L
  primitive  : box
  world_pos  : (0, -0.24, 0.65)
  dims       : (0.10, 0.10, 0.04)
  material   : tunic
  shading    : flat
  notes      : cream peek at sleeve hem

Hand_L
  primitive  : sphere
  world_pos  : (0, -0.24, 0.60)
  radius     : 0.055
  material   : skin
  shading    : smooth
  notes      : mitten-style; no fingers
```

### Arm_R (parent: rig group `Arm_R` at y=+0.18, z=0.95) — holds staff

```
Sleeve_R
  primitive  : box
  world_pos  : (0, 0.24, 0.80)
  dims       : (0.12, 0.12, 0.30)
  material   : vest
  shading    : smooth

Cuff_R
  primitive  : box
  world_pos  : (0, 0.24, 0.65)
  dims       : (0.10, 0.10, 0.04)
  material   : tunic
  shading    : flat

Hand_R
  primitive  : sphere
  world_pos  : (0, 0.24, 0.60)
  radius     : 0.055
  material   : skin
  shading    : smooth
  notes      : grips staff at this z-level

[STAFF composite — see composite recipes below]
[LANTERN_1 + LANTERN_2 composites — see composite recipes below]
```

### Leg_L (parent: rig group `Leg_L` at y=-0.10, z=0.55)

```
Trousers_L
  primitive  : cylinder
  world_pos  : (0, -0.10, 0.30)
  radius     : 0.08
  height     : 0.50
  vertices   : 10
  material   : trousers
  shading    : smooth

Sandal_Wrap_L
  primitive  : box
  world_pos  : (0, -0.10, 0.10)
  dims       : (0.10, 0.10, 0.04)
  material   : leather
  shading    : flat
  notes      : ankle wrap; sits at the bottom of the trouser cylinder

Foot_L
  primitive  : box
  world_pos  : (0.02, -0.10, 0.04)
  dims       : (0.14, 0.10, 0.06)
  material   : skin
  shading    : smooth
  notes      : bare-ish foot extending forward
```

### Leg_R (parent: rig group `Leg_R` at y=+0.10, z=0.55)

Mirror of Leg_L with y=+0.10. Same dims/materials/shading.

---

### Composite recipes (define once, instantiate where needed)

#### `BEARD` composite — substantial dwarf-wizard chin beard

Per `low-poly-character-modeling.SKILL.md § Beard`. Anchored at world `(face_x, 0, chin_z)` where `face_x ≈ 0.16` and `chin_z ≈ 1.00` for Eldra. All sub-parts material=`hair`, shading=`flat`.

```
Chin_Pad        box      (0.18, 0,    1.02)   dims (0.05, 0.14, 0.04)
Beard_Strand_C  cone     (0.18, 0,    0.92)   base_r=0.045 tip_r=0.005 h=0.16   rot Y +8°
Beard_Strand_L  cone     (0.16, -0.06, 0.94)  base_r=0.035 tip_r=0.005 h=0.13   rot X-12° Y+8°
Beard_Strand_R  cone     (0.16,  0.06, 0.94)  base_r=0.035 tip_r=0.005 h=0.13   rot X+12° Y+8°
Beard_Side_L    cone     (0.10, -0.13, 1.00)  base_r=0.030 tip_r=0.008 h=0.10   rot X-20°
Beard_Side_R    cone     (0.10,  0.13, 1.00)  base_r=0.030 tip_r=0.008 h=0.10   rot X+20°
Beard_Fork_L    cone     (0.18, -0.025, 0.82) base_r=0.018 tip_r=0.003 h=0.07   rot X-15°
Beard_Fork_R    cone     (0.18,  0.025, 0.82) base_r=0.018 tip_r=0.003 h=0.07   rot X+15°
Mustache_L      cone     (0.22, -0.05, 1.07)  base_r=0.025 tip_r=0.004 h=0.08   rot X+75° Z-15°
Mustache_R      cone     (0.22,  0.05, 1.07)  base_r=0.025 tip_r=0.004 h=0.08   rot X-75° Z+15°
```

10 sub-parts. Visible strand structure with forked tip + flared mustache.

#### `HAIR` composite — voluminous windswept tufts (up + back)

Anchored at world `(scalp_x, 0, scalp_z)` where `scalp_x ≈ -0.05` (back of head) and `scalp_z ≈ 1.30`. All material=`hair`, shading=`flat`.

```
Hair_Tuft_top      cone(4-vert)  (-0.04, 0,     1.42)  base_r=0.10 tip_r=0.005 h=0.16  rot Y+35°
Hair_Tuft_top_L    cone(4-vert)  (-0.06, -0.10, 1.40)  base_r=0.08 tip_r=0.005 h=0.14  rot X-10° Y+40°
Hair_Tuft_top_R    cone(4-vert)  (-0.06,  0.10, 1.40)  base_r=0.08 tip_r=0.005 h=0.14  rot X+10° Y+40°
Hair_Tuft_back_L   cone(4-vert)  (-0.16, -0.14, 1.32)  base_r=0.06 tip_r=0.005 h=0.12  rot X-15° Y+55°
Hair_Tuft_back_R   cone(4-vert)  (-0.16,  0.14, 1.32)  base_r=0.06 tip_r=0.005 h=0.12  rot X+15° Y+55°
Hair_Wisp_L        sphere        (0.04, -0.18,  1.20)  radius=0.06
Hair_Wisp_R        sphere        (0.04,  0.18,  1.20)  radius=0.06
Hair_Back_Dome     sphere        (-0.10, 0,     1.22)  radius=0.18  scale (1.0, 1.2, 1.0)
```

8 sub-parts. 4-vertex pyramidal cones (per `low-poly-character-modeling § Hair`) for angular Wind-Waker-flavor flat-shaded hair.

#### `STAFF` composite — knobby branch with crook (parented to Arm_R)

Anchored relative to Arm_R hand grip at `(0.16, 0.27, 0.85)`. All material=`leather`, shading=`smooth` (the bevel softens the cylinders).

```
Staff_Pole_lo   cylinder  (0.16, 0.27, 0.32)  r=0.030 h=0.55  vertices=10
Staff_Knot_a    cylinder  (0.16, 0.27, 0.62)  r=0.040 h=0.06  vertices=10
Staff_Pole_mid  cylinder  (0.16, 0.27, 0.95)  r=0.028 h=0.60  vertices=10
Staff_Knot_b    cylinder  (0.16, 0.27, 1.27)  r=0.038 h=0.06  vertices=10
Staff_Pole_hi   cylinder  (0.16, 0.27, 1.45)  r=0.025 h=0.30  vertices=10
Staff_Crook_a   cylinder  (0.22, 0.27, 1.62)  r=0.024 h=0.16  vertices=8   rot Y+60°
Staff_Crook_b   cylinder  (0.32, 0.27, 1.58)  r=0.024 h=0.14  vertices=8   rot Y+90°
Staff_Crook_c   cylinder  (0.40, 0.27, 1.50)  r=0.022 h=0.14  vertices=8   rot Y+120°
```

8 sub-parts. Knots create the gnarled wood read; the crook curves outward (+X = forward) so lanterns dangle clear of the body.

#### `LANTERN` composite — round-bellied lantern with hanging chain (instantiated 2×)

Each lantern = 5 sub-parts. Anchor `(L_x, L_y, L_z)` per instance.

```
Lantern_Hang   cylinder  (L_x, L_y, L_z + 0.18)   r=0.008 h=0.12  vertices=6  material: leather
Lantern_Cap    cylinder  (L_x, L_y, L_z + 0.10)   r=0.055 h=0.04  vertices=10 material: lantern_body
Lantern_Body   sphere    (L_x, L_y, L_z)          radius=0.060   scale (1.0, 1.0, 1.1)  material: lantern_body
Lantern_Flame  sphere    (L_x, L_y, L_z + 0.02)   radius=0.038   material: lantern_flame  shading: smooth (emissive)
Lantern_Base   cylinder  (L_x, L_y, L_z - 0.07)   r=0.040 h=0.020 vertices=10 material: lantern_body
```

**Instance 1 (`LANTERN_1`):** hangs from Crook_b apex. Anchor `(0.32, 0.27, 1.32)`.
**Instance 2 (`LANTERN_2`):** hangs from Crook_c tip, lower + further forward. Anchor `(0.40, 0.27, 1.18)`.

#### `BACKPACK` composite — leather pack with green herbs (parented to Body)

```
Backpack_Body     box     (-0.20, 0,    0.78)  dims (0.10, 0.26, 0.36)  material: leather  shading: smooth
Strap_L           box     (0,   -0.08,  0.92)  dims (0.30, 0.04, 0.04)  material: leather
Strap_R           box     (0,    0.08,  0.92)  dims (0.30, 0.04, 0.04)  material: leather
Backpack_Herb_a   sphere  (-0.20, -0.06, 1.04) radius=0.05  scale (1.0, 1.0, 1.4)  material: herb
Backpack_Herb_b   sphere  (-0.20,  0.06, 1.06) radius=0.05  scale (1.0, 1.0, 1.6)  material: herb
Backpack_Herb_c   sphere  (-0.20,  0,    1.10) radius=0.04  scale (1.0, 1.0, 1.8)  material: herb
Gourd_Side        sphere  (-0.18, -0.18, 0.78) radius=0.05  scale (1.0, 1.0, 1.3)  material: leather  notes: small gourd hanging on left of pack
```

7 sub-parts.

---

## 5. Animation contract

```yaml
rig_groups: [Body, Head, Arm_L, Arm_R, Leg_L, Leg_R]
optional_joints: []  # no Knee/Elbow/Foot in v1; consider for v2 polish

hand_props:
  Arm_R: STAFF + LANTERN_1 + LANTERN_2  # parented under Arm_R so they swing/swing-lock together
  Arm_L: null

locked_arms: R          # Arm_R holds staff — does not swing during walk

per_character_overrides:
  cadenceMul: 0.7       # slow elder walk
  leanMul: 1.6          # stooped forward lean (animator multiplies leanBase by this)

facing: +Z (three.js)   # via the +X-source → -Y-Blender wrapper, no root rotation needed
```

The codex `NPC_ANIM_CONFIG` block should match this — already wired for `npc_eldra` per `codex.js:1209`.

---

## 6. Concept ↔ model alignment check

```
[x] Voluminous windswept hair (up + back)         — HAIR composite (8 parts)
[x] Substantial chin beard with forked tip        — BEARD composite (10 parts)
[x] Bushy white eyebrows                          — Brow_L + Brow_R
[x] Bulbous nose                                  — Nose
[x] Closed peaceful eyes                          — Eye_L + Eye_R (flat ovals, leather color)
[x] Layered cream tunic + ochre vest              — Tunic_Body + Vest_Body + Vest_Skirt
[x] Decorative green stripe on vest hem           — Vest_Stripe (herb material)
[x] Patterned teal scarf with hanging end         — Scarf_Front + Scarf_Tail
[x] Wooden staff with knots + crook               — STAFF composite (8 parts)
[x] Two round-bellied hanging lanterns            — LANTERN_1 + LANTERN_2 (5 parts each)
[x] Brown leather backpack                        — BACKPACK composite (7 parts)
[x] Green herb sprig poking from backpack         — Backpack_Herb_a/b/c
[x] Small gourd on side of backpack               — Gourd_Side
[x] Brown belt + side pouch                       — Belt + Pouch_R
[x] Olive-sage trousers                           — Trousers_L + Trousers_R
[x] Brown sandal/foot wraps                       — Sandal_Wrap_L/R
[x] Bare-ish feet extending forward               — Foot_L + Foot_R

[ ] Visible vest buttons (~3-4 small dark dots)   — DEFERRED (too small to read at gameplay distance; consider material noise instead)
[ ] Embroidered scarf cross-pattern               — DEFERRED (use 2-tone scarf material with secondary darker color in v2)
[ ] Right-wrist bracelet/wrap                     — DEFERRED (low visual weight; not load-bearing for character read)
[ ] Vest cord-tassel detail at hem                — DEFERRED (covered by vest_stripe at silhouette level)
```

All silhouette-critical elements captured. Deferred items are surface decoration that can be added to a v2 polish pass via material color variation rather than new geometry.

---

## Total geometry estimate

- Standalone parts: ~22
- Composite parts: BEARD 10 + HAIR 8 + STAFF 8 + LANTERN ×2=10 + BACKPACK 7 = 43
- **Total parts: ~65**
- **Estimated tris (chunky-cozy with bevel): 4500-6000** — within hero NPC budget per `low-poly-character-modeling` (1500-3000 for regular, 6000+ acceptable for hero)

## v1.1 detail additions (2026-05-06)

User accepted bumping poly count to better match concept-art surface detail. 11 detail upgrades, ~+780 tris. New target: **~6200 tris**.

| addition | replaces / adds | parts | poly cost |
|---|---|---|---|
| **Hexagonal lanterns w/ window panes** | sphere bodies | 6-vert cylinder body + 4 vertical bar primitives per lantern × 2 | +240 |
| **Bedroll on backpack** | new | horizontal cylinder on top of backpack with two-tone caps | +50 |
| **Grass tuft at staff base** | new | 4-5 thin green pyramid cones at z≈0.05 around staff bottom | +40 |
| **Sandal criss-cross straps** | flat wrap box | 3 thin diagonal boxes crossing the foot per leg × 2 | +120 |
| **Hair fluff** | new | 4-6 small spheres tucked between the pyramidal tufts | +80 |
| **Vest front cord + hem highlight** | new | thin vertical box down vest front + cream highlight at chest peek | +40 |
| **Beard density** | beard composite extends | +3-4 intermediate strands between existing | +60 |
| **Staff knot rings + notches** | extends staff composite | +4 thin disc-rings + 2 small carved notches | +50 |
| **Scarf pattern accents** | new | 3 small lighter-teal accent boxes on scarf | +30 |
| **Vest buttons** | new | 3 small dark spheres down the vest front | +30 |
| **Bushier eyebrows** | single box per side | 2-3 small angular tufts per side | +30 |

Total: **+780 tris** (5436 → ~6216).

## Build dependencies

This plan assumes the existing helper layer in `scripts/rebuild_eldra.py`:
- `add_box`, `add_sphere`, `add_cylinder`, `add_cone`, `add_empty`, `add_metaball_blob` (helpers wrapped with the +X→-Y coordinate transform)
- Material factory with the 10 hex colors above (locked at script top)
- Single-tier root with rig empties parented directly (no RigPivot — that approach was abandoned per `feedback_glb_orientation_two_tier_root.md`)

The existing script is ~80% aligned with this plan — what changes from the current state:
1. **Beard:** drop the metaball blob, use the cone-strand cluster from §4 BEARD
2. **Hair:** replace the dome+box-tufts with 4-vertex pyramidal cones from §4 HAIR
3. **Add:** Sandal_Wrap_L/R, Gourd_Side, Vest_Stripe positioning fixed (was floating)
4. **Materials:** consolidate `leather` (was 2 separate browns), drop `Eldra_Pattern` (use `herb` instead)
