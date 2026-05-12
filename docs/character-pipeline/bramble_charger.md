# Bramble Charger — model description (v1)

Filed against `docs/character-pipeline/MODEL_DESCRIPTION_TEMPLATE.md`.
Concept art: `docs/concept-art/enemy-bramble-charger.png`.

## 1. Identity
- **Name (display)**: Bramble Charger
- **Role**: enemy (smaller, faster bramble-grown boar; charges in groups)
- **One-line description**: Compact quadruped boar buried under dense layered green leaves with a pale cream snout pushing forward, two upturned cream tusks, glowing amber eyes, and wooden plank armor strapped to its flanks.
- **Source**: `docs/concept-art/enemy-bramble-charger.png`

## 2. Proportions
- **Length (nose to tail-base)**: ~1.10m
- **Body width**: ~0.50m
- **Total height (top of leaf crest)**: ~0.85m
- **Build**: compact quadruped, lower-slung than Burrow Boar (more aggressive read at the same scale). Charge-pose silhouette: head low, hindquarters slightly higher.
- **Authoring origin**: tail at -X, snout at +X, paws on z=0. Helpers remap to Blender world.

## 3. Palette
| Material name           | Hex       | Where it's used              | Notes |
|-------------------------|-----------|------------------------------|-------|
| `Charger_Hide`          | `#2A1F18` | underbody, body barrel       | dark hide peeking under leaves |
| `Charger_LeafDark`      | `#46582E` | most leaves                  | rough 0.92 |
| `Charger_LeafLight`     | `#7E933E` | accent leaves (every 3rd)    | rough 0.92 |
| `Charger_Snout`         | `#D8C49A` | snout, lips                  | cream — silhouette anchor |
| `Charger_Tusk`          | `#EFE0B6` | two upturned tusks           | rough 0.55 |
| `Charger_Eye`           | `#F0962A` | both eyes                    | emissive `#FFB54A`, strength 1.8 |
| `Charger_Plank`         | `#6E4D2E` | flank armor planks           | rough 0.85 |
| `Charger_Strap`         | `#3A2516` | leather straps holding planks| rough 0.85 |
| `Charger_Hoof`          | `#2E2218` | hoof caps                    | rough 0.85 |
| `Charger_Line`          | `#1A0E08` | nostrils, mouth line         | rough 0.85 |

## 4. Parts table (high-level)
Detailed cone/leaf positions live in the build script — listing only structural primitives and notable accent groups here.

| Mesh name              | Primitive | Pos (x, y, z)        | Dimensions / radius           | Material              | Skip outline? |
|------------------------|-----------|----------------------|-------------------------------|------------------------|---------------|
| **Body cluster**       |           |                      |                               |                       |               |
| `Body_Barrel`          | soft_box  | (0, 0, 0)            | (0.95, 0.50, 0.36)            | `Charger_Hide`        | N             |
| `Body_Belly`           | soft_box  | (0, 0, -0.16)        | (0.85, 0.46, 0.10)            | `Charger_Hide`        | N             |
| `Plank_Armor_L`        | box       | (0.05, -0.27, 0.05)  | (0.30, 0.04, 0.20)            | `Charger_Plank`       | N             |
| `Plank_Armor_R`        | box       | (0.05,  0.27, 0.05)  | (0.30, 0.04, 0.20)            | `Charger_Plank`       | N             |
| `Plank_detail_strap_L` | box       | (0.05, -0.30, 0.10)  | (0.04, 0.06, 0.22)            | `Charger_Strap`       | Y (`_detail_`)|
| `Plank_detail_strap_R` | box       | (0.05,  0.30, 0.10)  | (0.04, 0.06, 0.22)            | `Charger_Strap`       | Y (`_detail_`)|
| **Leaves** (~28 leaf cones) |        |                      | base 0.040–0.080, tip 0.005, h 0.10–0.20 | `Charger_LeafDark` / `Charger_LeafLight` (alternating) | Y (`_ruffle_leaf_*`) |
| **Head cluster**       |           |                      |                               |                       |               |
| `Head_Mesh`            | sphere    | (0.55, 0, 0.10)      | r=0.16, scale (1.0,1.0,0.9)   | `Charger_Hide`        | N             |
| `Snout`                | soft_box  | (0.72, 0, 0.04)      | (0.18, 0.20, 0.14)            | `Charger_Snout`       | N             |
| `Snout_detail_nostril_L` | sphere  | (0.81, -0.05, 0.06)  | r=0.014                       | `Charger_Line`        | Y             |
| `Snout_detail_nostril_R` | sphere  | (0.81,  0.05, 0.06)  | r=0.014                       | `Charger_Line`        | Y             |
| `Tusk_L`               | cone      | (0.76, -0.10, 0.04)  | base 0.022, tip 0.005, h 0.12 | `Charger_Tusk`        | N             |
| `Tusk_R`               | cone      | (0.76,  0.10, 0.04)  | base 0.022, tip 0.005, h 0.12 | `Charger_Tusk`        | N             |
| `Eye_L`                | sphere    | (0.62, -0.12, 0.18)  | r=0.022                       | `Charger_Eye`         | N             |
| `Eye_R`                | sphere    | (0.62,  0.12, 0.18)  | r=0.022                       | `Charger_Eye`         | N             |
| `Ear_L_detail`         | cone      | (0.42, -0.16, 0.26)  | base 0.05, tip 0.005, h 0.08  | `Charger_Hide`        | Y             |
| `Ear_R_detail`         | cone      | (0.42,  0.16, 0.26)  | base 0.05, tip 0.005, h 0.08  | `Charger_Hide`        | Y             |
| **Legs** (×4)          |           |                      |                               |                       |               |
| `<Leg>_Leg`            | cylinder  | (0, 0, -0.18)        | r=0.06, h=0.36                | `Charger_Hide`        | N             |
| `<Leg>_Hoof`           | soft_box  | (0, 0, -0.40)        | (0.10, 0.10, 0.06)            | `Charger_Hoof`        | N             |
| **Tail**               |           |                      |                               |                       |               |
| `Tail_Mesh`            | cone      | (0, 0, 0)            | base 0.04, tip 0.012, h 0.18  | `Charger_Hide`        | N             |
| `Tail_ruffle_leaf_a`   | cone      | (0, 0, 0.16)         | base 0.05, tip 0.005, h 0.10  | `Charger_LeafDark`    | Y             |
| `Tail_ruffle_leaf_b`   | cone      | (0, -0.04, 0.18)     | base 0.04, tip 0.005, h 0.10  | `Charger_LeafLight`   | Y             |

## 5. Rig
- **Layout**: quadruped — `Body / Head / Tail / Leg_FL / Leg_FR / Leg_BL / Leg_BR`
- **Body center z**: 0.40 (above ground; legs hang below to z=0)
- **Head center z**: 0.50 (slightly higher than body, but lower than Burrow Boar — charge-pose head-low cue is set by the empty's static position in v1; the engine's quadruped animator handles the dynamic walk)
- **Sub-mesh parenting**: every leaf cone parents to `body_emp` so it sways together when the body rocks during animation. Head leaves parent to `head_emp`.

## 6. Surface texture approach
- **Leaves** (dominant signature): ~28 small flat cones distributed across the body surface. Alternating `Charger_LeafDark` / `Charger_LeafLight` for color break. Names use `_ruffle_leaf_<n>` so the outline pass skips them — a single unified silhouette traces the whole leaf-mound shape rather than outlining each leaf individually.
- **Coverage rule**: leaves must cluster densely on top/sides but **leave a clear cream snout protruding +X** and **leave the legs visible from the knees down**. If any leaf would clip past the snout's bbox or below z=-0.10, drop or move it. (Lesson from the survey: easiest way to fail this character is to bury the snout.)
- **Plank armor**: solid boxes with `_detail_strap_*` leather straps overlaid. Planks ARE part of the silhouette (no skip).
- **Tusks**: silhouette-critical. Outlined.
- **Eyes**: emissive amber for "bramble-grown" magical glow. No outline skip — the dot reads as a bright eye against the dark hide.

## 7. Outline strategy
- All leaves carry `_ruffle_leaf_` in the name → skip-pattern matches → outline merge ignores them. Result: one silhouette outline traces the body+leaf-mound + head + planks + tusks + legs as a unified shape.
- Nostrils (`_detail_nostril_`) and ears (`_detail`) skip too — they're surface accents, not silhouette pieces.
- Mouth line on the snout (TBD if needed) would use `_line` if added.

## 8. Validation checklist
1. Snout (cream) reads as the FRONT of the character at NPC distance — not buried under leaves
2. Two tusks visible from any 3/4 angle
3. Amber eyes visible (bright spots) against the dark hide
4. Leaf coverage is uniform — no bald spots on top/sides
5. Plank armor pieces visible on both flanks (silhouette break-up)
6. Leg hooves visible — character isn't a leaf-blob with no legs
7. Total mesh count under 60 (current quadruped reference: Burrow Boar has 31)
8. Painted shading + unified outline working in codex viewer
