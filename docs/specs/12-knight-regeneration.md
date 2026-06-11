# 12 — Knight regeneration: Midjourney concept → Meshy

> **Outcome**: a fresh, clean knight character — concepted in Midjourney, regenerated through the Meshy pipeline (t-pose → remesh → rig → idle), landing as `models/knight_rigged_v1.glb`. A real rigged, animated knight asset, produced the same way the spec-11 crypt cast was.

## Why

The current knight (`models/knight_v4.glb`) is an older procedural-animation-style mesh — no skeletal rig, and it doesn't match the quality bar of the Meshy-rigged crypt cast. The user wants it regenerated from new concept art. This spec produces the asset; where it's consumed is open (the Godot player is now the Ranger — see spec 13 — so the regenerated knight is a clean asset for later use, e.g. a future character option or a three.js upgrade).

## Scope

**In:**

### A. Midjourney concept art
- Generate knight concept art via the Chrome connector + Midjourney, using the project's established niji-6 prompt stem (see `docs/concept-art/.../PROMPTS.md` patterns).
- The knight is a Bramblewood storybook adventurer — chunky low-poly-friendly silhouette, readable from a distance, cozy-fairytale not grimdark. T-pose-friendly framing (front-facing, arms out or relaxed).
- Generate variants; the user picks the best.
- Save the chosen PNG to `docs/concept-art/knight/knight-v<N>.png`.

### B. Meshy regeneration
- `meshy_image_to_3d` from the chosen concept, `ai_model="meshy-6"`, `pose_mode="t-pose"`.
- If the result exceeds 300K faces, `meshy_remesh` to ~50K.
- `meshy_rig` (humanoid — a knight rigs cleanly).
- `meshy_animate` with `action_id: 0` (idle).
- Download the `Animation_Idle_withSkin.glb` → `models/knight_rigged_v1.glb`.

### C. Verify
- Import into Godot; confirm an `AnimationPlayer` + idle clip via the `test_anim.gd` probe.
- The static `knight_v4.glb` stays untouched (three.js still uses it).

**Out (explicit non-goals):**
- Wiring the knight as the Godot player — the Godot player is the Ranger (spec 13).
- Walk / attack / death animations — idle only (matches spec 11).
- Touching the three.js game.
- A full character creator's worth of knight variants — one good knight.

## Files

| Path | Action |
|---|---|
| `docs/concept-art/knight/PROMPTS.md` | new — knight Midjourney prompt(s) |
| `docs/concept-art/knight/knight-v[0-3].png` | new — concept art |
| `models/knight_rigged_v1.glb` | new — Meshy rig+idle output |
| `models/knight_rigged_v1.glb.import` | new — Godot import sidecar |

## Acceptance criteria

1. Knight concept art generated in Midjourney; the chosen variant saved under `docs/concept-art/knight/`.
2. `models/knight_rigged_v1.glb` exists, imports into Godot with no errors.
3. The probe (`test_anim.gd` extended, or a one-off) shows the knight GLB has an `AnimationPlayer` with an idle clip.
4. `knight_v4.glb` and the three.js game are untouched.
5. Notes record the Meshy credit spend and any rig oddities.

## Open decisions

- **Cost.** Meshy 6: image-to-3d ≈ 29 + remesh ≈ 5 + rig 5 + idle 3 ≈ **~42 credits**. Confirm with the user before spending (Meshy Rule 1).
- **Midjourney model.** niji 6 (the project's established stem for characters) vs MJ v6. Recommend niji 6 for consistency with the crypt cast concepting. Notes record.
- **Filename.** `knight_rigged_v1.glb` vs `knight_v5.glb`. Recommend `knight_rigged_v1` — the `_rigged` suffix matches the spec-11 convention and distinguishes it from the static `knight_v*` series.

## References

- Spec 11 (the rig+animate pipeline this mirrors): `docs/specs/11-godot-animation.md` + notes
- Meshy recipes: `docs/character-pipeline/MESHY_OPERATIONS.md`
- Existing knight art: `models/knight_v2..v4.glb`
- Midjourney via Chrome connector — the established spec-04 concepting flow

## Done check

- [ ] Knight concept art in Midjourney, best variant chosen + saved
- [ ] Meshy image-to-3d (t-pose) → remesh → rig → idle
- [ ] `models/knight_rigged_v1.glb` imports clean in Godot
- [ ] Idle clip confirmed via probe
- [ ] `knight_v4.glb` + three.js untouched
- [ ] Credit spend recorded in notes
