# Implementation notes — 20-glb-textures

## Decisions
- **The textures were never the problem — `_tint` was.** A probe
  (`test_textures.gd`, since removed) walked every GLB's materials: the 4
  Meshy-rigged enemies (skeleton, ghost, hedge-sprite, Hedgemother) each
  carry a **2048² albedo texture, imported fine**. They rendered white only
  because `layout_loader._tint` slapped a flat-colour `material_override`
  over the textured material. Fix: stop tinting them.
- **Ranger + rat genuinely have no texture** — `albedo_texture = null`.
  The Ranger GLB's material is white albedo (1,1,1); the rat's is a baked
  tan colour. So they **keep their `_tint`** (the Ranger would render pure
  white otherwise) — this is spec criterion 4 (a model that can't be
  textured keeps its tint, recorded), not a failure.
- **Walls/floor untouched** — the spec-16 stylized stone reads fine; out of
  scope.

## Deviations
- _none_

## Tradeoffs
- The Meshy textures are subtle (the skeleton is bone-pale, the ghost
  pale-cyan) — not vivid. But they're the *real* textures and read as
  intentional (a bone skeleton *is* pale). Kept them over the flat tints.

## Surprises
- Diagnosis took minutes, not the full hour-cap — the probe answered it
  immediately. The spec-14 "white blob" rabbit-hole was, in hindsight,
  just the (later-added) `_tint` override masking working textures, plus
  flat ambient lighting.

## Followups
- The Ranger has no GLB texture — a real Ranger texture would need either
  authoring one or a Meshy retexture (declined this round).
- `meshy_retexture` on the enemies if the subtle textures want more punch
  (credits — not done).

## Status
COMPLETE, under the time cap. The 4 rigged enemies + the boss render their
real 2048² GLB textures (`_tint` removed); the untextured Ranger + rat keep
their tints by necessity. `test_combat.gd` 20/20; World boots clean.
