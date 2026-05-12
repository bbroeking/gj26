# MODEL_DESCRIPTION_TEMPLATE.md

A character description must exist as a markdown file under
`docs/character-pipeline/<name>.md` BEFORE any Blender script is written.
The point: pin proportions, palette, parts, rig, surface approach, and the
outline strategy on paper so we stop re-iterating after a v1 lands and
notice the head is the wrong size / a beard reads as confetti / the
silhouette merges with the next NPC over.

This file is the canonical template. Copy it, rename, fill in every
section. The filled example at the bottom (Wren the Tinker) shows the
expected level of detail.

Cross-references:
- `docs/ASSET_PIPELINE.md` — concept → model → game end-to-end workflow.
- `docs/BLENDER_PIPELINE.md` — Blender-side recipe (Principled BSDF,
  remove_doubles, scale-aware bevel, GLB export flags).
- `scripts/_painted_build_lib.py` — primitive helpers
  (`add_box`, `add_soft_box`, `add_sphere`, `add_cylinder`, `add_cone`,
  `add_empty`). Authoring frame = face on +X, lateral on ±Y, up on +Z.
- `src/scene/painted_materials.js` — `_ruffle` / `_detail` / `_line`
  suffix convention for outline-skip parts.
- `CLAUDE.md` — project-wide conventions (1 tile = 1m, world coords,
  procedural empty rig vs skeletal animation).

---

## Sections (required)

### 1. Identity
- **Name (display)**: storybook name as shown in-game.
- **Role**: NPC / enemy / boss / ambient creature.
- **One-line description**: silhouette-first, e.g. "Stocky old goat-herd
  with a windswept hair pile, cinch-belted leather vest, and a tall
  hooked staff bearing two paper lanterns."
- **Source concept art path**: `docs/concepts/<file>.png` (required —
  if no concept exists yet, generate one before continuing; we do NOT
  build to a vibe).

### 2. Proportions
- **Total height (m)**: 1 unit = 1m world. Adult human ≈ 1.55–1.70m.
- **Head : body ratio**: e.g. 1:5.5 (realistic) → 1:3 (chibi).
- **Build**: chibi / stocky / slim / hulking. Note any silhouette anchor
  (e.g. "rounded barrel torso, narrow shoulders, no neck visible").
- **Authoring origin**: feet at z=0, centerline at x=0,y=0. Face on +X.

### 3. Palette
6–10 named hex colors with explicit Material slot names. Use the
`<Character>_<Slot>` convention so `painted_materials.js` palette
detection still works. Roughness defaults to 0.85 unless noted.

| Material name      | Hex       | Where it's used              | Notes |
|--------------------|-----------|------------------------------|-------|
| `<Char>_Skin`      | `#xxxxxx` | face, hands, feet            | rough 0.78 |
| `<Char>_Hair`      | `#xxxxxx` | hair, beard, brows           | rough 0.92 |
| `<Char>_Tunic`     | `#xxxxxx` | undershirt, collar           |       |
| ...                |           |                              |       |

### 4. Parts table
Every primitive that will be authored. One row per call site. Authoring
positions are in the +X-forward authoring frame (helpers remap to
Blender's -Y). Skip-outline column drives the `_ruffle` / `_detail` /
`_line` suffix in the mesh name.

| Mesh name        | Primitive | Pos (x, y, z)     | Dimensions / radius        | Material        | Skip outline? |
|------------------|-----------|-------------------|----------------------------|-----------------|---------------|
| `Head_Mesh`      | sphere    | (0, 0, 1.40)      | r=0.18, scale (1.05,1,0.95)| `<Char>_Skin`   | N             |
| `Beard_Mass`     | sphere    | (0.26, 0, 1.10)   | r=0.11, scale (0.7,1.2,1.7)| `<Char>_Hair`   | N             |
| `Beard_ruffle_a` | sphere    | (0.31,-0.06, 1.20)| r=0.035                    | `<Char>_Hair`   | Y             |
| ...              |           |                   |                            |                 |               |

### 5. Rig
- **Layout**: biped (`Body / Head / Arm_L / Arm_R / Leg_L / Leg_R`) OR
  quadruped (`Body / Head / Tail / Leg_FL / Leg_FR / Leg_BL / Leg_BR`).
- **Joint heights** (z, in m): Z_HIP, Z_SHOULDER, Z_NECK, Z_HEAD_TOP.
- **Sub-mesh parenting**: every primitive parents to one of the empties
  above (no orphans). Special accessories (staff, basket, prop) parent
  to the dominant arm empty so they swing with the limb.
- **No skeletal animation**: GLB exports with
  `export_animations=False, export_skins=False`. Per-frame rotation of
  named groups is driven by `src/anim/*.js`.

### 6. Surface texture approach
Pick exactly one per textured surface (face, body, prop). The recent
Eldra A/B/C/D variant pass settled the trade-offs:

- **strand-cones**: many small cones authored as discrete strands.
  Reads as noise under inverted-hull outline (every cone gets its own
  ink line). AVOID for fur/beard/grass at NPC distance. OK for hero
  props seen close-up.
- **displaced-mass**: one main ellipsoid + ruffle bumps with
  `_ruffle` suffix to skip outline. The current beard/hair recipe.
  Reads as cel-banded volume with one clean silhouette.
- **painted-stripes**: vertex-color or texture stripes on a single
  primitive. Used for stripes/spots on cows, scales on snake-like
  enemies. Cheap, no extra geometry.
- **none**: bare painted material. Most clothing, walls, weapons.

### 7. Outline strategy
The painted pipeline runs an inverted-hull outline pass. Suffix
conventions (enforced by `src/scene/painted_materials.js`):
- `_ruffle`  → small surface bumps, skip outline (no ink line).
- `_detail`  → small accessories that overlap a parent shape, skip
  outline if their ink line would fight the parent's silhouette.
- `_line`    → a thin sliver authored explicitly to be a drawn line
  (eyebrow, mouth seam). Skip outline on the mesh itself; it IS the
  line.

List every part that should skip outline, and why. If your character
has zero outline-skip parts, that's a smell — most characters need at
least the eye/brow/mouth row.

### 8. Validation checklist
Before declaring v1 done, verify each of the following. If any item
fails, iterate before merging.

1. **Reads at NPC distance** — render at the in-game camera distance
   (~6m, 30° tilt). Silhouette identifies the character without any
   facial detail.
2. **Silhouette is unique among existing cast** — A/B against current
   NPCs (Eldra, Hod, Cricket, etc.). If two characters share a
   silhouette, change height, build, or signature prop.
3. **Eyes / brows / nose protrude past head surface** — raycast from
   camera direction; every facial feature mesh boundary must lie OUTSIDE
   the head sphere. (Buried features cause "no face" reads at distance.)
4. **No sub-mesh is parented to root** — every mesh parents to one of
   the 6 (or 7) rig empties. Orphans don't animate.
5. **Materials use Principled BSDF** — confirm via
   `bpy.data.materials[<name>].node_tree.nodes['Principled BSDF']`.
   `diffuse_color`-only materials drop on glTF export.
6. **Outline-skip suffixes applied** — every part listed in §7 has the
   correct suffix in its mesh name.
7. **GLB size sanity** — 30KB–150KB. >300KB usually means a stray
   high-poly mesh; check subsurf levels and sphere segment counts.

---

## Filled example: Wren the Tinker

A worked example showing the level of detail this template expects.
Wren is a hypothetical wandering tinker NPC for Bramblewood — not
canon, just a stand-in.

### 1. Identity
- **Name**: Wren the Tinker
- **Role**: NPC (vendor)
- **One-line description**: Slim, twitchy young woman in a patched
  oilcloth coat that hangs to mid-thigh, with a wide leather belt
  bristling with tin tools and a single crooked pair of brass goggles
  pushed up on a frizz of copper hair.
- **Source concept art path**: `docs/concepts/wren_tinker_v1.png`

### 2. Proportions
- **Total height**: 1.62 m
- **Head : body ratio**: 1:4.5 (slightly chibi, between Eldra's 1:4
  and a realistic 1:6).
- **Build**: slim. Narrow shoulders, neutral hips, knees and elbows
  read as visible joints (cylinders pinch slightly).
- **Authoring origin**: feet at z=0, centerline x=0/y=0, face on +X.

### 3. Palette

| Material name     | Hex       | Where it's used                 | Notes |
|-------------------|-----------|---------------------------------|-------|
| `Wren_Skin`       | `#e8c098` | face, hands, neck               | rough 0.78 |
| `Wren_Hair`       | `#c87838` | hair mass, brows                | rough 0.92 |
| `Wren_Coat`       | `#5a4a3a` | oilcloth coat body, sleeves     | rough 0.88 |
| `Wren_CoatPatch`  | `#7a5a48` | shoulder + elbow patches        | rough 0.88 |
| `Wren_Shirt`      | `#d8c8a8` | undershirt collar peek          | rough 0.85 |
| `Wren_Trousers`   | `#3a4858` | leg cylinders                   | rough 0.88 |
| `Wren_Leather`    | `#4a2a18` | belt, boots, pouch straps       | rough 0.85 |
| `Wren_Brass`      | `#c89038` | goggles, tool fittings          | rough 0.40 |
| `Wren_Tin`        | `#a8a8b0` | wrench, pliers, hammer head     | rough 0.45 |
| `Wren_Eye`        | `#2a1a10` | eye slashes                     | rough 0.85 |

### 4. Parts table (abridged — head, torso, one arm, one leg)

Joint heights: Z_HIP=0.85, Z_SHOULDER=1.20, Z_NECK=1.30, Z_HEAD_TOP=1.62.

| Mesh name           | Primitive | Pos (x, y, z)       | Dimensions / radius           | Material         | Skip outline? |
|---------------------|-----------|---------------------|-------------------------------|------------------|---------------|
| `Head_Mesh`         | sphere    | (0, 0, 1.42)        | r=0.16, scale (1.0,1.0,1.05)  | `Wren_Skin`      | N             |
| `Nose`              | sphere    | (0.14, 0, 1.40)     | r=0.025                       | `Wren_Skin`      | N             |
| `Eye_L`             | box       | (0.16,-0.05, 1.44)  | (0.018, 0.028, 0.010)         | `Wren_Eye`       | Y (`_line`)   |
| `Eye_R`             | box       | (0.16, 0.05, 1.44)  | (0.018, 0.028, 0.010)         | `Wren_Eye`       | Y (`_line`)   |
| `Brow_L_line`       | box       | (0.155,-0.05, 1.49) | (0.025, 0.045, 0.010)         | `Wren_Hair`      | Y (`_line`)   |
| `Brow_R_line`       | box       | (0.155, 0.05, 1.49) | (0.025, 0.045, 0.010)         | `Wren_Hair`      | Y (`_line`)   |
| `Hair_Dome`         | sphere    | (-0.02, 0, 1.55)    | r=0.18, scale (1.1,1.1,1.05)  | `Wren_Hair`      | N             |
| `Hair_ruffle_top`   | sphere    | (0.02, 0, 1.66)     | r=0.055                       | `Wren_Hair`      | Y (`_ruffle`) |
| `Hair_ruffle_R`     | sphere    | (-0.02, 0.16, 1.55) | r=0.045                       | `Wren_Hair`      | Y (`_ruffle`) |
| `Hair_ruffle_L`     | sphere    | (-0.02,-0.16, 1.55) | r=0.045                       | `Wren_Hair`      | Y (`_ruffle`) |
| `Goggles_Strap`     | box       | (0, 0, 1.58)        | (0.04, 0.34, 0.035)           | `Wren_Leather`   | N             |
| `Goggle_L_detail`   | cylinder  | (0.03,-0.10, 1.58)  | r=0.045, h=0.035 (rot Y=90°)  | `Wren_Brass`     | Y (`_detail`) |
| `Goggle_R_detail`   | cylinder  | (0.03, 0.10, 1.58)  | r=0.045, h=0.035 (rot Y=90°)  | `Wren_Brass`     | Y (`_detail`) |
| `Neck`              | cylinder  | (0, 0, 1.30)        | r=0.06, h=0.10                | `Wren_Skin`      | N             |
| `Coat_Body`         | soft_box  | (0, 0, 1.05)        | (0.30, 0.26, 0.42)            | `Wren_Coat`      | N             |
| `Coat_Skirt`        | soft_box  | (0, 0, 0.78)        | (0.30, 0.26, 0.20)            | `Wren_Coat`      | N             |
| `Coat_Patch_L`      | box       | (0.04,-0.16, 1.18)  | (0.06, 0.10, 0.10)            | `Wren_CoatPatch` | N             |
| `Belt`              | box       | (0, 0, 0.86)        | (0.30, 0.26, 0.05)            | `Wren_Leather`   | N             |
| `Pouch_R`           | box       | (0.05, 0.16, 0.82)  | (0.10, 0.06, 0.10)            | `Wren_Leather`   | N             |
| `Wrench_detail`     | box       | (0.07,-0.18, 0.86)  | (0.04, 0.02, 0.18)            | `Wren_Tin`       | Y (`_detail`) |
| `Sleeve_R`          | soft_box  | (0,    0.22, 1.05)  | (0.10, 0.10, 0.32)            | `Wren_Coat`      | N             |
| `Cuff_R`            | box       | (0,    0.22, 0.86)  | (0.09, 0.09, 0.04)            | `Wren_Shirt`     | N             |
| `Hand_R`            | sphere    | (0,    0.22, 0.81)  | r=0.05                        | `Wren_Skin`      | N             |
| `Trousers_R`        | cylinder  | (0,    0.10, 0.50)  | r=0.07, h=0.70                | `Wren_Trousers`  | N             |
| `Boot_R`            | box       | (0.02, 0.10, 0.07)  | (0.13, 0.10, 0.10)            | `Wren_Leather`   | N             |

(Mirror across ±y for the L side.)

### 5. Rig
- **Layout**: biped — `Body / Head / Arm_L / Arm_R / Leg_L / Leg_R`.
- **Joint heights**: Z_HIP=0.85, Z_SHOULDER=1.20, Z_NECK=1.30,
  Z_HEAD_TOP=1.62.
- **Sub-mesh parenting**: head + facial detail → `Head`. coat / belt /
  pouch → `Body`. sleeves / cuffs / hands → `Arm_L`/`Arm_R`. trousers /
  boots → `Leg_L`/`Leg_R`. Wrench parents to `Body` (it sits in the
  belt, not the hand).
- **No skeletal animation** — exported with
  `export_animations=False, export_skins=False`.

### 6. Surface texture approach
- **Hair (head)**: displaced-mass — 1 dome + 3 `_ruffle` bumps. The
  copper color is loud enough that strand-cones would shred the
  silhouette.
- **Coat patches**: painted-stripes — handled as separate small boxes
  with the `Wren_CoatPatch` material. Two patches, no more (silhouette
  budget).
- **Tools at belt**: detail primitives with `_detail` suffix to skip
  outline. They're small enough that an ink line would just look like
  noise on the belt.
- **Goggles**: detail cylinders with `_detail` suffix — the brass
  rims are thin and an outline pass collapses them visually.

### 7. Outline strategy
Skip outline on:
- `Eye_L`, `Eye_R` (`_line`) — eyes ARE the line.
- `Brow_L_line`, `Brow_R_line` (`_line`) — same reason.
- `Hair_ruffle_top`, `Hair_ruffle_L`, `Hair_ruffle_R` (`_ruffle`) —
  bumps on the dome, outline would fragment the dome's silhouette.
- `Goggle_L_detail`, `Goggle_R_detail` (`_detail`) — small brass rim
  on top of the strap; outline would double-line them.
- `Wrench_detail` (`_detail`) — overlaps the belt; outline would draw
  a redundant box around it.

### 8. Validation checklist (Wren-specific notes)
1. **Reads at NPC distance** — at 6m the goggles + frizz silhouette
   should still distinguish her from Eldra (windswept old man) and
   Cricket (small chittery thing).
2. **Silhouette uniqueness** — current cast has no slim-with-prop-on-
   forehead silhouette. Confirmed.
3. **Eye/brow protrusion** — eyes at x=0.16, head sphere radius 0.16
   centered at x=0; eye boundary at x=0.169 → just OUTSIDE head
   surface. Brows at x=0.155 + 0.0125 = 0.168, also outside. OK.
4. **No orphan parts** — wrench has been moved off the floor and into
   `Body`'s parent list.
5. **Principled BSDF** — confirmed via export inspection.
6. **Outline-skip suffixes** — 9 parts flagged in §7 carry the right
   suffix.
7. **GLB size** — projected ~70–90KB at this primitive count.
