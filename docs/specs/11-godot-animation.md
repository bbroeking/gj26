# 11 — Godot animation: rig + animate the cast via Meshy

> **Outcome**: the crypt cast stops standing in T-pose. The five character GLBs (skeleton, rat, ghost, hedge-sprite, hedgemother) are auto-rigged and given idle + walk animations through the Meshy API, re-exported as animated GLBs, and Godot plays them via `AnimationPlayer` — enemies idle in place, the player plays walk while moving and idle when still.

## Why

The Godot models export from `clean_ai_mesh.py` as static meshes — no skeleton, no clips — so every enemy and the boss stands frozen. The three.js game solves this with per-frame procedural rotation animators (`src/anim/*.js`). For the Godot evaluation we use the path the user asked for: Meshy's auto-rig + animation, which produces real skeletal clips Godot's `AnimationPlayer` plays natively. This also exercises the newly-added Meshy MCP end-to-end.

## Scope

**In:**

### A. Meshy MCP gate (do this first)
- Confirm `mcp__meshy__*` tools are available. They require `MESHY_API_KEY` in the environment and a Claude Code restart (the key was wired into `.mcp.json` in a prior session).
- If the tools are **not** available: stop, tell the user to set `MESHY_API_KEY` and restart, and do not proceed with the Meshy path. Record the block in notes. (See Open decisions for the fallback.)

### B. Rig + animate the five characters via Meshy
For each of `enemy_skeleton_v1`, `enemy_rat_v1`, `enemy_ghost_v1`, `enemy_hedge_sprite_v1`, `hedgemother_v2`:
- Submit the GLB to Meshy **auto-rig**.
- Apply **idle** and **walk** animations (Meshy's animation library / text-driven).
- Download the rigged + animated GLB to `models/<name>_rigged.glb` (new file — the static `_v1` GLBs stay untouched so the three.js side is unaffected).
- The rat is a quadruped; ghost has no legs — accept whatever Meshy's auto-rig produces and note oddities rather than fighting them.

### C. Godot playback
- `layout_loader.gd` loads the `_rigged.glb` variants for enemies + boss when they exist (fall back to the static `_v1` GLB if a rig failed).
- Each instantiated character: find its `AnimationPlayer`, play `idle` looped.
- Player: when `_rigged` player art exists it plays `walk` while moving and `idle` when still; if there is no player GLB (the player is a capsule today) this is a no-op — note it.
- A small `scripts/anim_driver.gd` helper: given a character node + a "moving" bool, pick and crossfade idle/walk. Keeps the logic in one place.

### D. Symlink / pipeline note
- `models/` is symlinked into `godot/models`, so the new `_rigged.glb` files appear in Godot automatically; commit the `.import` sidecars.
- Update `docs/character-pipeline/MESHY_OPERATIONS.md` and `docs/GODOT_PIPELINE.md` with the rig+animate-via-API step.

**Out (explicit non-goals):**
- Attack / hit-react / death animations — idle + walk only.
- Animation blend trees, root motion, IK.
- Re-rigging for the three.js side — three.js keeps its procedural animators; this spec only adds `_rigged.glb` variants.
- Replacing `clean_ai_mesh.py` — the static pipeline stays for non-animated props.
- Facial animation, cloth sim.
- Animating decor props.

## Files

| Path | Action |
|---|---|
| `models/enemy_skeleton_v1_rigged.glb` etc. (×5) | new — Meshy rig+animate outputs |
| `models/*_rigged.glb.import` | new — Godot import sidecars (commit) |
| `godot/scripts/anim_driver.gd` | new — idle/walk selection + crossfade helper |
| `godot/scripts/layout_loader.gd` | modify — prefer `_rigged.glb`, start `idle` on spawn |
| `godot/scripts/player_controller.gd` | modify — drive walk/idle if player art exists |
| `docs/character-pipeline/MESHY_OPERATIONS.md` | modify — rig+animate API step |
| `docs/GODOT_PIPELINE.md` | modify — animation section |

## Acceptance criteria

1. `mcp__meshy__*` tools are confirmed available before any Meshy work (or the spec stops with a clear message).
2. All five characters have a `models/<name>_rigged.glb` with at least an `idle` and a `walk` clip — or, for any that Meshy could not rig, a notes entry explaining which and why.
3. Opening `World.tscn`: enemies and the boss visibly animate (idle) instead of standing in T-pose.
4. The animated GLBs import into Godot with no errors; `.import` sidecars committed.
5. If a rig failed for a given character, `layout_loader.gd` falls back to its static `_v1` GLB and the scene still loads.
6. The static `_v1` GLBs are untouched — the three.js game is unaffected (verify it still boots).
7. `MESHY_OPERATIONS.md` and `GODOT_PIPELINE.md` document the rig+animate step.

## Open decisions

- **Fallback if the Meshy MCP is unavailable.** Two options: (a) hard-stop and wait for the user to set the key; (b) port the three.js procedural rotation animators to GDScript `_process` as an interim. Recommend (a) — the user explicitly asked for the Meshy route, and procedural GDScript would be throwaway once Meshy lands. Notes record which happened.
- **Meshy credit cost.** Auto-rig + animation costs credits per model (×5). Treat it like the earlier Meshy runs — proceed within the existing working budget; if a job needs an unusually large spend, surface it first.
- **Idle clip naming.** Meshy may name clips differently per model. `anim_driver.gd` should match case-insensitively / by substring (`"idle"`, `"walk"`) rather than assuming exact names. Notes record what Meshy actually produced.
- **Ghost rig.** The ghost has no legs — Meshy auto-rig may produce something strange. Accept it; if the result is unusable, fall back to the static GLB + a simple GDScript bob (the spec 04 three.js ghost animator did exactly this). Notes record.
- **Player art.** The player is still a capsule. If there is no player character GLB, the player stays a capsule and the walk/idle hook in `player_controller.gd` is dormant until one exists. Note it; don't block the spec on it.

## References

- Meshy MCP: `@meshy-ai/meshy-mcp-server` (in `.mcp.json`) — auto-rig + animation tools
- `docs/character-pipeline/MESHY_OPERATIONS.md` — existing Meshy recipes
- `models/` — the five static character GLBs from specs 04/05
- Three.js procedural animators for reference: `src/anim/*.js`
- Godot docs — `AnimationPlayer`, glTF animation import

## Done check

- [ ] Meshy MCP availability confirmed (or spec stopped with a message)
- [ ] 5 characters auto-rigged + idle/walk applied via Meshy
- [ ] `_rigged.glb` files in `models/`, `.import` sidecars committed
- [ ] `anim_driver.gd` idle/walk helper
- [ ] `layout_loader.gd` prefers `_rigged.glb`, starts idle, falls back cleanly
- [ ] Enemies + boss visibly animate in `World.tscn`
- [ ] Static `_v1` GLBs untouched; three.js still boots
- [ ] Meshy + Godot docs updated
