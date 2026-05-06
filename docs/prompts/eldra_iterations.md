# Eldra v2 — iteration prompts

Saved 2026-05-04. Each variant pushes a different "less Roblox/Minecraft"
lever in isolation, so a side-by-side review tells us which **direction**
feels right before we polish.

Reference image: `docs/concept-art/npc-eldra-lampwright.png`
Base script:     `scripts/build_npc_eldra_v2.py`
Output dir:      `models/npc_eldra_v2_<letter>.glb`

To re-run a variant: `blender --background --python scripts/eldra_variants/build_eldra_<letter>_*.py`

Polycount budget per variant: ≤ 1.5M tris, ≤ 10MB GLB.
Animation contract: R15 segmented limbs, knee + elbow bend, no socket pop.

---

## Variant A — Tapered limbs

```
GOAL: iterate Eldra v2 — break the "limbs are uniform columns" feel.
REFERENCE: docs/concept-art/npc-eldra-lampwright.png
PIPELINE: scripts/build_npc_eldra_v2.py — make_cube + bevel + subsurf

WHAT "LESS BLOCKY" MEANS HERE:
1. Replace each limb segment (UpperArm, Forearm, Thigh, Shin) with 3
   stacked cubes that step down in width — wider at the joint pivot,
   narrower toward the extremity. Concept art shows tapered arms + legs.
2. Hands + feet should read smaller than wrists/ankles — anatomy cue.
3. Belt should taper into the hip; shoulders should taper into upper arm.

CONSTRAINTS:
- R15 rig: cap geometry stays on Body. Limbs only extend AWAY from torso.
- Keep all aux parts (lanterns, beard, satchel) unchanged.
- ≤ 1.5M tris.

GRADE:
- [ ] Profile silhouette no longer reads as a stack of identical-width
      blocks
- [ ] Outline at 60% scale matches the watercolor's tapered limbs
- [ ] Animation still plays (knee + elbow still bend correctly)
```

---

## Variant B — Asymmetry + handcrafted feel

```
GOAL: iterate Eldra v2 — kill the "perfectly symmetric robot" feel.
REFERENCE: docs/concept-art/npc-eldra-lampwright.png
PIPELINE: scripts/build_npc_eldra_v2.py

WHAT "LESS BLOCKY" MEANS HERE:
1. Hair tufts: 8 tufts → 8 with random ±0.04H position jitter and ±10°
   rotation each. No two the same.
2. Beard: instead of a single symmetric beard mass, split into 5 stacked
   layers of slightly different widths and one side ~0.05H lower than
   the other (off-centre tip).
3. Eyebrows: one slightly higher than the other (0.02H).
4. One lantern positioned higher on the staff than the other (already
   done somewhat, but accentuate by 0.10H).
5. Slight head tilt baked into Head_skull rotation (~5° around X).
6. Shoulders: one set 0.02H higher than the other.

CONSTRAINTS:
- R15 rig contract.
- Animation must still drive cleanly — only static-pose offsets, not
  baked rotations on the rig joints (those would conflict with the
  walk cycle).

GRADE:
- [ ] Mirror-test fails: flipping the model L-R yields a different
      silhouette
- [ ] Reads as "hand-painted" / "lived-in", not factory-stamped
- [ ] No floating bits — asymmetry doesn't break attachment
```

---

## Variant C — Round forms (head dome + hex lanterns)

```
GOAL: iterate Eldra v2 — break the "everything is a cube" feel by
replacing cuboidal silhouettes with rounded ones on the most-visible
parts (head, lanterns, staff knots).
REFERENCE: docs/concept-art/npc-eldra-lampwright.png

WHAT "LESS BLOCKY" MEANS HERE:
1. Head_skull: split into Head_dome (top half, scaled 1.0×0.95×0.55,
   subsurf level 3 only) + Head_jaw (already exists). Dome reads as
   round cap on top.
2. Lanterns: each lantern body becomes 2 cubes at 0° + 45° around Z
   (octagonal cross-section). Use subsurf level 3 on these specifically.
3. Staff knots: subsurf level 3 just on these — they currently read as
   square bumps; should read as bulbous/spherical knots.
4. Big nose: subsurf level 3 on the nose tip cube — it'll read as a
   round button instead of a square nub.
5. Hair tufts: subsurf level 3 on each tuft so they read as soft puffs.

CONSTRAINTS:
- Per-mesh subsurf override (apply_bevel_remove_doubles takes a list of
  high-detail object names).
- Polycount budget — selective level-3 means only ~10 cubes get the
  treatment, not all 126.

GRADE:
- [ ] Head silhouette in profile shows a curved skull, not a corner
- [ ] Lanterns read as octagonal/round, not square
- [ ] No noticeable polycount blow-up (tris ≤ 2× variant base)
```

---

## Variant D — Multi-shade gradient cloth

```
GOAL: iterate Eldra v2 — make every fabric panel read as cloth-with-
folds instead of "painted plastic".
REFERENCE: docs/concept-art/npc-eldra-lampwright.png

WHAT "LESS BLOCKY" MEANS HERE:
1. Every garment region (cream tunic, navy shawl, sage tabard, leather
   wrap, trousers, beard) becomes 3 stacked cubes: top-shadow + main +
   bottom-highlight. Each shade ±10% luminance from the base.
2. Add a few "fold" cubes (small, slightly darker, slightly indented)
   crossing each panel diagonally — implies cloth crease.
3. Boots / sandals get a darker scuff cube on the toe.
4. Beard: 3 horizontal layers with progressive darkening top→bottom.

CONSTRAINTS:
- Don't change silhouette — only colour zoning.
- Adds ~20 cubes total. Stay under 150 meshes.

GRADE:
- [ ] Each fabric region shows 2-3 visible shade bands instead of one
      flat colour
- [ ] Outline silhouette unchanged from current Eldra
- [ ] Fabric "weight" reads — light catches highlights, shadows pool
      at folds
```

---

## Variant E — Geometry-level smoothing (cylinders + sphere head + cast)

Picked after grading: variant A (tapered limbs) was the right direction.
Variant E pushes that direction by replacing the stacked-cube approximation
with **real cylindrical primitives** (which taper smoothly between top and
bottom radii) and a **UV-sphere head**, then applies a global Cast modifier
to round any remaining cube-derived silhouettes. Same R15 rig contract.

```
GOAL: iterate Eldra v2 — push past stacked-cube tapering (variant A) by
swapping the cube primitive for cylinders (limbs), spheres (head), and
adding a Cast modifier on the largest remaining cube panels. Final
silhouette should read as "soft sculpted figure", not "blocks beveled".

REFERENCE: docs/concept-art/npc-eldra-lampwright.png
PIPELINE: scripts/build_npc_eldra_v2.py + new helpers in _build_lib:
  - make_cylinder(name, loc, dims, color, vertices=12,
                  radius_top=None, radius_bot=None)
  - make_sphere(name, loc, dims, color, segments=16, rings=8)
  - apply_cast_modifier(obj, factor=0.5, target='SPHERE')

WHAT "LESS BLOCKY" MEANS HERE:
1. ALL limb segments (UpperArm × 2, Forearm × 2, Thigh × 2, Shin × 2)
   become 12-vertex cylinders with TOP radius wider than BOTTOM radius.
   Native tapering — no stacked cubes. Cylinder ends already round.
2. Head_skull becomes a UV sphere (16 seg × 8 rings) squished vertically
   to ~0.95H tall, ~1.05H wide. Slight ovoid for "stocky gnome".
3. Lantern bodies become 8-sided cylinders (rotate 0° + 22.5° around Z
   for octagonal cross-section) with brass top + bottom caps.
4. Shoulder + hip caps (already on Body) get Cast modifier factor=0.4
   pulling them toward sphere — they become rounded shoulder bumps
   instead of square pads.
5. Torso panels (chest / midriff / waist / shawl) keep cube primitive
   (cloth folds well in flat panels) but get Cast factor=0.2 to soften
   the corners just slightly.
6. Hand stub and foot sandal go cylinder too — narrow tubes at wrist,
   flat oblong cylinders at feet.
7. Beard mass: 5-cube stack stays cube but each cube gets Cast factor=0.5
   so beard reads as soft puffy rather than blocky brick.

CONSTRAINTS:
- R15 rig contract: cap geometry on Body, limbs only extend AWAY.
- Polycount: cylinders @ 12 verts × 8 rings = ~200 tris each; sphere head
  @ 16×8 = ~256 tris. Should stay under 1.5M tris total with subsurf=2.
- File size: target ≤ 25MB (currently variant A is 21MB, this should
  stay close).
- Animation: cylinders have a single mesh — verify rotation pivots
  end up at the geometric top end (bevel/origin set).
- Held-item sockets stay at the END of the chain (Hand parent).

GRADE:
- [ ] Profile silhouette has no visible cube-corners on limbs or head
- [ ] Limbs taper smoothly (no stair-stepping like variant A had)
- [ ] Head reads as round/ovoid in profile, not square
- [ ] Lanterns read as round-ish (octagonal at minimum), not boxes
- [ ] Tris ≤ 1.5M, GLB ≤ 25MB
- [ ] Walk animation still plays — knee bend, elbow bend, all the same
- [ ] Concept-overlay alignment in codex matches or beats variant A

NEXT STEP IF YES: propagate the pattern to the other 7 NPCs.
NEXT STEP IF NO: identify which grading line failed and re-prompt with
  smaller scope — e.g. "limb cylinders only, leave head as cube" if the
  sphere head looks weird.
```

## How to combine after review

After grading the 4 variants, the **winning recipe** is whatever combination
of A/B/C/D scored highest on its grading criteria. Combined-pass authoring
takes the same time as one variant since each direction is orthogonal — they
edit different parts of the script.
