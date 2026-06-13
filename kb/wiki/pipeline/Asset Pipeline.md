---
type: pipeline
tags: [asset-pipeline, meshy, ai-mesh, midjourney, glb, clean-ai-mesh]
status: draft
updated: 2026-06-13
sources: ["docs/ASSET_PIPELINE.md", "docs/character-pipeline/AI_WORKFLOW.md", "docs/character-pipeline/MESHY_OPERATIONS.md", "docs/GODOT_PIPELINE.md"]
---

# Asset Pipeline

The end-to-end flow for getting a new character, enemy, or prop from concept art into the game: Midjourney → Meshy AI Image-to-3D → `clean_ai_mesh.py` → Blender socket pass → `models/` → engine.

## Two entry paths

**Concept-art-driven** (full quality): the standard path when a design exists.

**Dummy-procedural** (no concept yet): clone the closest existing silhouette (e.g. `boar_v2.glb` for a quadruped boss), apply a color tint via `varyInstance`, suffix the slug `_dummy`. Replace when concept art lands.

Dummies must still pass the floater audit (no floating parts). Add a note in `docs/concept-art/INDEX.md` under "Dummy models awaiting concept art".

## Phase 0 — decide what to build

Write down: **slug** (snake_case), **kind** (player / enemy / NPC / prop), **rig type** (biped / quadruped / static), **behavior** (melee / ranged / kiter / boss), **why it earns its slot**. If you can't answer the last question, don't build it.

## Phase 1 — concept art (Midjourney)

1. Open `docs/concept-art-prompts-next.md` and append using the **locked style stem** (the stem is non-negotiable — it keeps tone consistent).
2. Generate ~4 variations. Pick the favorite, save to `docs/concept-art/<slug>.png`. Save the runner-up to `docs/art-refs/<slug>_v2.png`.
3. Append one line to `docs/concept-art/INDEX.md`.

Never change the locked stem mid-batch. Start a new batch file if the style needs to shift.

## Phase 2A — Meshy AI Image-to-3D

Meshy turns concept art into a textured 3D GLB. Total cost: ~35 credits/character (~10 base + ~25 refine).

1. Sign in to [meshy.ai](https://meshy.ai) → **Image to 3D** (not Text to 3D — concept art has too much detail).
2. Upload `docs/concept-art/<slug>.png`.
3. Settings: Art style = **Stylized**, Symmetry = **Auto** (bipeds) / **Off** (quadrupeds), Topology = Tri, Texture = Yes with PBR, ~10,000 polygons.
4. Generate. Regenerate with a different seed if the first pass has melted face / extra limbs. Second/third seeds often hit.
5. Refine to high quality if the base is good.
6. Download `.glb` to `~/Downloads/`.

**Hard-won Meshy facts** (from `docs/character-pipeline/MESHY_OPERATIONS.md`):
- Meshy auto-rig **only works on Meshy-native t-pose generations** — it cannot pose-estimate the `clean_ai_mesh.py` low-poly outputs.
- Meshy 6 generates dense meshes (300K–1.4M faces). The rig API caps at 300K — run `meshy_remesh` first if rigging is needed.
- **Rigging is humanoid-only.** Quadrupeds (the crypt rat) fail pose estimation and stay static.
- `meshy_rig` includes walk + run clips free (5 credits). `meshy_animate` adds custom clips (3 credits, `action_id: 0` = Idle).
- Always download the `Animation_<Name>_withSkin.glb` (the "with skin" / "Character" variant) — the "Merged Animations" sidecar is degenerate (empty skeleton, no mesh).
- Meshy's animation export strips textures. Texture **after** rigging, not before (Recipe A in `MESHY_OPERATIONS.md`).
- Clip names come through in `gltf.animations[].name` — keep them sensible so `find('draw')` / `find('walk')` in the game loader picks them up.

## Phase 2B — `clean_ai_mesh.py`

Cleanup script (runs in headless Blender) that welds, decimates, normalizes, slices into named rig parts, and exports:

```bash
python3 scripts/clean_ai_mesh.py \
    --input ~/Downloads/Meshy_AI_Foo.glb \
    --name foo_ai_v1 \
    --rig biped \          # biped | quadruped | static
    --tris 30000           # 30k for hero NPCs; 10–15k for ambient mobs
```

Key flags: `--rotate-z <deg>` (fix forward-axis mismatch), `--head-cut-ratio` / `--legs-cut-ratio` / `--arm-cut-ratio` (Z/X-plane slice positions as fractions of total height/half-width).

What it does internally: import → apply transforms → optional rotation → center + ground → decimate + shade smooth → slice into parts → cap cut openings → rename materials to `<Name>_Body` for `paintifyAuto` → wrap in named empties → export to `models/<name>.glb`.

Output lands at `models/<name>_v1.glb`. For rigged/animated variants: `models/<name>_rigged.glb`.

## Phase 2C — Blender socket pass (props)

For props that attach to character sockets (bow, quiver, sword), follow **Recipe C** from `docs/character-pipeline/MESHY_OPERATIONS.md`:
1. Meshy → Image to 3D with Stylized art style.
2. Run `clean_ai_mesh.py` with `--rig static` and appropriate `--tris` (3k for arrows, 6k for bows/swords, 10k for cloaks).
3. Save to `models/prop_<name>_v1.glb`.
4. Add socket empties in Blender (`PROP_ATTACHMENT.md` details the socket naming convention).

## Phase 3 — wire into the game (three.js prototype)

For each new GLB in the three.js codebase:

1. **Loader** in `src/scene/characters.js` via `_loadOnce('xxx', 'xxxPromise', url)`.
2. **Builder** in `src/scene/characters.js`: traverses the GLB for named rig empties, sets `userData.parts`, calls `shadowizeAll`.
3. **Spawn factory** in `src/game/enemies.js` with the standard enemy schema.
4. **Animation routing** in `src/main.js` — add the `isGLBXxx` flag check.
5. **Dungeon spawn table** in `src/data/dungeonSpawns.js` — add weighted entry.
6. **Dev console** in `src/ui/devConsole.js` — add to `ENEMY_KINDS`.
7. **Codex** in `codex.js` — add `ENEMIES` entry with scope, drops, one-liner.

## Phase 3 — Godot import

GLBs in `models/` are automatically visible to Godot via the symlink (`wyrd/models -> ../models`). When the editor opens with a new GLB present, it auto-imports and creates a `models/<name>_v1.glb.import` sidecar. **Commit the sidecar.** Reference the model as `res://models/<name>_v1.glb`.

`layout_loader.gd` prefers `<name>_rigged.glb` when it exists and falls back to the static `_v1` GLB.

## Phase 4 — validate before merging

- [ ] No floating parts
- [ ] Named rig empties have origins at the pivot of motion
- [ ] Walk animation drives limbs without parts detaching
- [ ] Dev console can spawn it; fight works without errors
- [ ] Codex page shows correct stats and drops
- [ ] Unique mechanic telegraphed readably

## Codex verification step (AI workflow)

After running `clean_ai_mesh.py`, register and verify:

```bash
python3 scripts/register_ai_character.py foo_ai_v1
# Open codex.html — info card must show:
# rig parts: Arm_L, Arm_R, Body, Head, Leg_L, Leg_R  ← all 6 present
# ▶ animated · walking biped (procedural empty rig)
```

If codex shows `static (no rig)`, re-run `clean_ai_mesh.py` with tweaked cut ratios.

## Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `static (no rig)` in codex | Slicing didn't produce all 6 named empties | Adjust `--head-cut-ratio` / `--legs-cut-ratio` |
| Character faces wrong way in-game | Meshy chose a different forward axis | `--rotate-z 90` (or 180, -90) |
| Meshy auto-rig fails | Feeding a `clean_ai_mesh.py` low-poly GLB | Must use a Meshy-native t-pose generation |
| Textured GLB loses rig on texture pass | Meshy's texturing stripped the skeleton | Extract diffuse from textured GLB, assign to rigged GLB's material in Blender |

## See also

- [[Blender Pipeline]] — detailed Blender recipe for manually modeled assets
- [[Art Bible]] — the style stem all concept art must follow
- [[Animation Pipeline]] — what happens to the GLB animations after export
- [[Godot Pipeline]] — how GLBs are imported and used in-engine
- [[Enemies]] — the enemy cast that drives most model requests
- [[Items and Gear]] — prop models for equipment

## Sources

- `docs/ASSET_PIPELINE.md`
- `docs/character-pipeline/AI_WORKFLOW.md`
- `docs/character-pipeline/MESHY_OPERATIONS.md`
- `docs/GODOT_PIPELINE.md` (dual-engine asset model, spec 07)
