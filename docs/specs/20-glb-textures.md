# 20 — Real GLB textures

> **Outcome**: enemies, the boss, and the Ranger render with their actual GLB textures instead of flat stylized tints — the crypt looks made, not placeholder.

## Why

Specs 14/16 applied flat per-model colour tints because the Meshy GLB textures read as white blobs in Godot, and chasing the cause was a rabbit hole that wasn't worth blocking combat on. The Meshy enemies *do* ship textures (`enemy_*_rigged_texture_0.png` sit next to the GLBs). For the shareable demo it's worth one focused, time-boxed pass to get the real textures rendering.

## Scope

**In:**
- **Diagnose** why textured Meshy GLBs render white/untextured in Godot — the import settings, the material's albedo-texture slot, or whether the GLB references the texture at all. Inspect one rigged GLB's imported material.
- **Fix it** so the GLBs render their baked textures: correct the import (re-import with the right material flags), or wire the `_texture_0.png` onto the material's albedo at load.
- **Remove the flat-tint override** in `layout_loader._tint` / `player_controller._tint` once textures render — or keep `_tint` as a *fallback* only.
- Walls + floor — keep the spec-16 stylized stone (it reads fine), or give them a simple texture; walls are not the focus.
- **Time-box the diagnosis** — see Open decisions.

**Out:**
- Authoring new textures.
- Re-texturing via Meshy (`meshy_retexture` — a separate credit cost; only if the grill approves).
- The wall-GLB geometry swap (spec 16 out-of-scope).
- PBR / normal / roughness maps beyond what the GLBs already carry.

## Files

| Path | Action |
|---|---|
| `godot/models/*.glb.import` | modify — corrected import settings |
| `godot/scripts/layout_loader.gd` | modify — drop/relegate `_tint` |
| `godot/scripts/player_controller.gd` | modify — drop/relegate `_tint` |
| `docs/GODOT_PIPELINE.md` | modify — record the texture-import fix |

## Acceptance criteria

1. At least the rigged enemies + the Ranger render their real textures (not flat tint, not white).
2. No white-blob characters in a play session.
3. Combat evals still pass; boots clean.
4. If a model genuinely can't be textured cleanly in the time box, it keeps its tint and that's recorded — not a silent regression.

## Open decisions

- **Time box — DECIDED (grill): a hard 1-hour cap** on the diagnosis. If real textures aren't working by then, keep the tints, document why, move on. The flat tints are a legitimate final look, not a failure.
- **Root-cause hypotheses to check, in order**: (1) the GLB's material albedo-texture slot didn't import; (2) Godot's GLB importer needs "embed"/material flags toggled; (3) the texture is a separate file the GLB references by a path that didn't resolve. 
- **Meshy retexture** — if the baked textures are genuinely unusable, `meshy_retexture` (~10 credits/model) is an option — but only with explicit user approval (Meshy Rule 1); default is *don't*.
- **Walls/floor** — recommend leaving the spec-16 stylized stone; it already reads well.

## References

- Spec 14 notes — the white-blob discovery, why tints were chosen
- Spec 16 notes — `_tint` per-model colours
- `models/enemy_*_rigged_texture_0.png` — the baked textures
- `layout_loader._tint`, `player_controller._tint`

## Done check

- [ ] Diagnosed why GLB textures read white (within the time box)
- [ ] Rigged enemies + Ranger render real textures
- [ ] `_tint` removed or demoted to fallback
- [ ] Evals pass; boots clean
- [ ] Any model that kept its tint is documented
