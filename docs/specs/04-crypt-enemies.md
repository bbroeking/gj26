# 04 — Crypt enemy roster (5 niji 6 GLBs + spawn table)

> **Outcome**: 5 cleaned enemy GLBs in `models/` (skeleton, rat, ghost, hedge-sprite, crypt warden mini-boss), each registered in `dungeonSpawns.js` for the `'crypt'` scope so procgen rolls them into floors at the right depths.

## Why

Spec 02 wires crypt visuals but uses placeholder enemy rosters (goblin/ironGob/hedgewolf from existing pools). This spec replaces that with crypt-themed enemies. Combat already exists — these are art + registry adds, not new behaviors.

## Scope

**In:**
- Draft `docs/concept-art/enemies/PROMPTS.md` with the locked niji 6 stem (same recipe as the crypt tiles: `--niji 6 --stylize 400`, chunky cartoon proportions, primary palette, cream background, no PBR/realistic/etc).
- Generate 4 variants per enemy in Midjourney via the Chrome connector flow already used for the crypt tiles.
- Pick the best variant per enemy. Run through Meshy Image-to-3D with the appropriate rig (biped / quadruped / static).
- Run each Meshy output through `scripts/clean_ai_mesh.py --rig <biped|quadruped|static>` per the existing recipe.
- Drop cleaned GLBs at `models/enemy_<name>_v1.glb`.
- Per-frame rotation animators for walk + idle in `src/anim/<name>.js`, mirroring `src/anim/goblin.js` shape.
- Register each enemy in a new `src/data/enemies.js` (if it doesn't already exist) with `{ url, rig, hp, damage, speed, animator }`. Wire to the existing combat code by giving each the same property shape goblin/ironGob/etc use today.
- Add a `MOB_CRYPT` table to `dungeonSpawns.js` with tier 1–5 weighted pools:
  - **Tier 1:** mostly `skeleton`, some `rat`.
  - **Tier 2:** `skeleton`, `rat`, hint of `ghost`.
  - **Tier 3:** `skeleton` + `ghost` + `hedge_sprite`.
  - **Tier 4:** `hedge_sprite` heavy, `crypt_warden` in guard slot.
  - **Tier 5:** `crypt_warden`, `ghost`, `hedge_sprite`.

**Out:**
- New combat moves / attack types beyond walk-up-and-swing — same AI as existing goblin/etc. for v1.
- Special status effects (poison, root, etc.) — separate spec.
- Boss-tier behaviors — that's the Hedgemother spec.
- Forge cellar enemies — second-biome work.

## Files

| Path | Action |
|---|---|
| `docs/concept-art/enemies/PROMPTS.md` | new — 5 enemy prompts with niji 6 stem |
| `docs/concept-art/enemies/<name>-v[0-3].webp` | new — generated concept art |
| `models/enemy_skeleton_v1.glb` | new |
| `models/enemy_rat_v1.glb` | new |
| `models/enemy_ghost_v1.glb` | new |
| `models/enemy_hedge_sprite_v1.glb` | new |
| `models/enemy_crypt_warden_v1.glb` | new |
| `src/anim/skeleton.js` | new |
| `src/anim/rat.js` | new |
| `src/anim/ghost.js` | new |
| `src/anim/hedge_sprite.js` | new |
| `src/anim/crypt_warden.js` | new |
| `src/data/enemies.js` | new or modify — registry entry per enemy (or extend wherever existing enemy stat blocks live; check `src/game/` first) |
| `src/data/dungeonSpawns.js` | modify — add `MOB_CRYPT`, register in `SCOPE_MOB_TABLES['crypt']`, add `GUARD_CRYPT` mini-boss pool |

## Acceptance criteria

1. All 5 GLBs in `models/enemy_<name>_v1.glb`.
2. Each enemy renders in `rig_test.html` (swap `BODY_URL`) without errors; walk + idle play.
3. Registry compiles; spec 02's crypt dungeon now spawns these enemies instead of the placeholder roster.
4. Tier 1 crypt floor has mostly skeletons; tier 5 has mostly crypt-wardens.
5. Killing a crypt enemy yields existing combat XP (atk/str/def/hp via `CONFIG.combat.styles`) and rolls existing loot tables — no new combat logic needed.
6. Poly count under 5k tris per enemy (cleanup script enforces).
7. Style consistent with the crypt tile set — niji 6 cartoon, bright primary palette.

## Open decisions

- **Roster final.** Recommended: skeleton (humanoid melee), rat (quadruped fast/low-HP), ghost (floating, ranged or evasive), hedge-sprite (small caster — fits the Bramblewood world), crypt-warden (mini-boss biped). Notes record final.
- **Niji 6 prompt stem for enemies.**
  ```
  <subject>, cute exaggerated chunky cartoon proportions, super simple geometric shapes, plain pale cream background, one object only, three-quarter view --niji 6 --ar 3:4 --stylize 400 --no photoreal, realistic, PBR, gradient shading, watercolor, dark, gritty
  ```
- **Rig per enemy.** Skeleton/hedge-sprite/crypt-warden = biped. Rat = quadruped. Ghost = static (floating; per-frame Y bob in animator).
- **Stats** (recommended starting points, tune later):
  | Enemy | HP | Damage | Speed | Tier debut |
  |---|---|---|---|---|
  | skeleton | 18 | 4 | 2.0 | 1 |
  | rat | 8 | 2 | 3.0 | 1 |
  | ghost | 14 | 5 | 1.5 | 2 |
  | hedge_sprite | 22 | 6 | 1.8 | 3 |
  | crypt_warden | 60 | 10 | 1.7 | 4 (guard) |
- **Animation API.** Mirror `src/anim/goblin.js` — exported `animate<name>(t, root)` rotates named child Groups (Body / Head / Arm_L / Arm_R / Leg_L / Leg_R / Tail).
- **Where existing stat blocks live.** Check for an `ENEMIES` dict or similar before creating `src/data/enemies.js`. Notes record final location.
- **Ghost: ranged or melee?** Recommend melee with slightly longer reach for v1. Range/projectile = followup. Notes record.

## References

- Crypt prompts (style reference): [`docs/concept-art/dungeons/crypt/PROMPTS.md`](../concept-art/dungeons/crypt/PROMPTS.md)
- Meshy recipe: [`docs/character-pipeline/MESHY_OPERATIONS.md`](../character-pipeline/MESHY_OPERATIONS.md)
- Cleanup script: `scripts/clean_ai_mesh.py`
- Existing animator pattern: [`src/anim/goblin.js`](../../src/anim/goblin.js)
- Spawn table: [`src/data/dungeonSpawns.js`](../../src/data/dungeonSpawns.js)
- Existing enemy stat shape: search `hp:` and `damage:` in `src/data/` and `src/game/`

## Done check

- [ ] All 5 PNGs generated and chosen variant recorded.
- [ ] All 5 GLBs in `models/`.
- [ ] All 5 animators wired and previewed in `rig_test.html`.
- [ ] `MOB_CRYPT` + `GUARD_CRYPT` tables added; spawn-picker resolves correctly.
- [ ] Killing a crypt enemy yields combat XP and rolls loot (existing systems).
- [ ] PROMPTS.md committed with the niji 6 stem documented.
