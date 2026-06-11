# 05 — Hedgemother boss GLB + floor-10 fight

> **Outcome**: walking onto floor 10 of the crypt arc spawns Hedgemother (real GLB, not procedural), the door visually seals, she cycles three attack phases by HP gates, beating her unlocks the gold exit + drops a tier-5 reward chest, returning to town with the `crypt_cleared` flag set.

## Why

A `bossKind: 'hedgemother'` factory already exists in main.js (procedural mesh). `docs/BOSS_SPEC.md` already specs her cinematic identity. Spec 03 gates floor 10 on her defeat. This spec gives her a real model + the three-phase fight that makes the floor feel like a punctuation mark, not a regular room.

## Scope

**In:**
- Niji 6 concept art for Hedgemother in `docs/concept-art/bosses/PROMPTS.md`, following the BOSS_SPEC.md description (giant moss-witch with vine arms, hedge-cap face).
- Generate variants, pick best, Meshy Image-to-3D, `clean_ai_mesh.py --rig biped --tris 8000` (bigger silhouette = more polys).
- `models/boss_hedgemother_v1.glb` lands in repo.
- Per-frame rotation animator `src/anim/hedgemother.js` with idle, walk, and 3 attack telegraphs (vine-sweep, root-stomp, summon).
- Replace the procedural-mesh path in main.js's `bossKind === 'hedgemother'` factory with a GLB load (use the same `_loadOnce` cache pattern as crypt assets).
- Boss HP bar overlay (DOM): full-width thin bar at top of canvas, only visible while a boss is alive in the current room.
- Three phases keyed by HP%:
  - **Phase 1 (100–60%)** — `thorn_sweep`: 180° arc swipe in front of her every ~4s. Telegraph: ring of ground decals 1s before hit.
  - **Phase 2 (60–30%)** — adds `root_stomp`: ground-target circles appear under the player; standing in one for 1s applies rooted state (existing `player.rootedT` flag works — duration 2s).
  - **Phase 3 (30–0%)** — adds `summon`: every ~8s, spawn 2 hedge-sprites (uses spec 04's enemy).
- On Hedgemother death: room "unseals" (the wall/door blocker fades), the gold exit becomes interactive, a special reward chest spawns at her death position with a tier-5 loot roll, player gets a "Crypt cleared" log line, `player.flags.cryptCleared = true`.
- Re-entry: a cleared crypt is replayable (per Hades-style decision in Q2). Fresh `baseSeed` each entry. The flag is set-once-and-stays for narrative purposes (NPCs can react later).

**Out:**
- Other bosses (Pale Hag, Chartmaker's Echo) — separate specs.
- Permanent unlock rewards (skills, perks) — separate progression spec.
- Multi-stage boss room geometry changes — for v1 the room is a static layout.
- Reskinning the existing `burrow_boar` / `wolf_alpha` bosses to GLBs — same pattern, but out of scope.

## Files

| Path | Action |
|---|---|
| `docs/concept-art/bosses/PROMPTS.md` | new — niji 6 stem for bosses, Hedgemother first |
| `docs/concept-art/bosses/hedgemother-v[0-3].webp` | new — concept art |
| `models/boss_hedgemother_v1.glb` | new |
| `src/anim/hedgemother.js` | new — per-frame rig animator + telegraph poses |
| `src/data/bossAttacks.js` | new — attack patterns table for Hedgemother |
| `src/game/bosses.js` | new or extend — phase machine, HP gates, attack dispatcher |
| `src/scene/dungeon.js` | modify — boss-room "seal" decoration when `bossKind` is set and boss alive |
| `src/ui/bossHp.js` | new — boss HP overlay |
| `src/main.js` | modify — replace procedural Hedgemother in the `bossKind` factory with GLB load + bind to phase machine |

## Acceptance criteria

1. Reach floor 10 of a crypt arc → enter the boss room → Hedgemother appears as a real GLB (no procedural box-rig).
2. Door/entry visually seals (a wall mesh blocks the doorway, or the entry tile flips to wall in the layout — pick one, document).
3. Boss HP bar appears at top of canvas.
4. Phase 1 attack (`thorn_sweep`) telegraphs and fires on schedule; player can dodge.
5. At 60% HP, `root_stomp` starts triggering.
6. At 30% HP, hedge-sprites start summoning.
7. Killing Hedgemother → seal lifts, gold exit interactive, tier-5 chest at her death position.
8. Returning to town → `player.flags.cryptCleared === true`.
9. Re-entering the crypt rolls a fresh arc; the flag persists for narrative use but doesn't change the run.

## Open decisions

- **Sealing visual.** Two options: (a) place a wall mesh blocking the doorway tile on enter, remove on death; (b) animate the existing `archway` GLB closing (rotation). Recommend (a) for v1, simpler. Notes record.
- **HP value.** Recommend `playerMaxDamage * 30` so the fight is ~30 successful hits at peak. Tune after first playtest.
- **Attack timings**: 4s `thorn_sweep`, 5s `root_stomp` cooldown, 8s `summon` cooldown. Notes record final values.
- **Telegraph duration.** 1s for ground-circle telegraphs. Notes confirm — too short = unfair, too long = boring.
- **Rooted state.** `player.rootedT` already exists in `CONFIG.combat`. Recommend reuse for `root_stomp` effect. Notes confirm.
- **Hedge-sprite cap during summon.** Recommend max 4 sprites alive at once (so summon doesn't infinitely add).
- **Damage values.** Phase 1: 8 per sweep hit. Phase 2 root: no damage, only immobilizes. Phase 3 summon damage handled by sprite stats.
- **Reward chest contents.** Recommend: tier-5 from `generateDungeonLoot` + one unique drop (`hedgemother_thorn_crown` or similar named item — needs to exist in `ITEMS` registry; new item entry recommended).
- **Music/sfx ramp.** Out of scope here; flag for followup.

## References

- Existing boss spec: [`docs/BOSS_SPEC.md`](../BOSS_SPEC.md)
- Existing boss code: search `bossKind` in [`src/main.js`](../../src/main.js)
- Combat tunables: [`src/data/config.js`](../../src/data/config.js)
- Loot generator: `generateDungeonLoot` in [`src/scene/dungeon.js`](../../src/scene/dungeon.js)
- Hedgemother lore: [`docs/WORLD_BIBLE.md`](../WORLD_BIBLE.md)
- Spec 03 gates floor 10 on her defeat: [`03-multi-floor-descent.md`](./03-multi-floor-descent.md)

## Done check

- [ ] Hedgemother concept art generated and chosen.
- [ ] GLB cleaned, in `models/`.
- [ ] Animator wired with idle / walk / 3 telegraph poses.
- [ ] Procedural mesh path replaced.
- [ ] Boss HP overlay renders.
- [ ] 3 phases trigger at correct HP gates.
- [ ] Seal-on-enter / unseal-on-death works.
- [ ] Reward chest spawns on victory with tier-5 roll + named drop.
- [ ] `cryptCleared` flag set in town.
- [ ] Re-entry rolls a fresh arc.
