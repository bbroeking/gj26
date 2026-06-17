---
title: Bramble Snare
domain: Combat Skills
type: skill
status: partial
effort: M
tags: [wayfinder, plan]
---

# Bramble Snare

> Fully-implemented AoE root with a rich 5-beat VFX stack — the missing pieces are the WINDUP cast animation (explicitly deferred at line 11), the thornwood pod pickup economy (visual-only), and any upgrade/synergy path.

## Current state

`wyrd/scripts/skills/bramble_snare.gd` is 551 lines and fully implements the core mechanic and VFX pipeline. `fire()` (line 74) lobs a seed projectile on a parabolic arc (`_animate_seed_arc`, line 222) from the bow to the landing point while simultaneously snapping a ground reticle ring at cast time (`_spawn_landing_reticle`, line 108). On landing, `_on_seed_land` (line 253) calls `_spawn_snare_visuals` and applies the root via `AoeQuery.query_circle` + `enemy.apply_root(SNARE_DURATION)` after the telegraph fairness window. All 5 VFX beats are present: telegraph fill (amber disc, CUBIC ease-out, 0.30s), thorn snap (vine_grow dissolve shader, `vine_grow.gdshader`, 0.10s), body pulse (4 Hz emission loop, 2.0s), wither (growth shader reversed, parallel disc alpha-out, 0.30s). Per-enemy thorn-rope tethers (`_spawn_tether`, line 462) use the same dissolve shader. Beat 1 (WINDUP / player cast animation) is explicitly deferred: `#   1. WINDUP — player anim, deferred (needs anim rig)` (line 11). Thornwood pods (`_spawn_thornwood_pods`, line 367) are purely cosmetic `MeshInstance3D` nodes with an idle bob — there is no `Area3D`, no pickup collision, and no "thornwood" item in `wyrd/data/items.gd` or `wyrd/data/gather.gd`. All required assets exist: `assets/vfx/vine_grow.gdshader`, `assets/vfx/soft_circle.png`, `assets/vfx/reticle_ring.png`, `assets/ui/icons/skill_snare.png`, `audio/skill_snare.mp3`.

## Gaps — what needs fleshing out

- **WINDUP beat missing (deferred):** Beat 1 is a no-op. The cast reads as instant. A `SkeletonModifier3D` draw-extend pose (mirroring `bow_draw_modifier.gd`) or a brief full-body wind-up before the seed launches would complete the spec-34 5-beat promise. This is the highest-value gap. Not a hard blocker for gameplay, but conspicuous next to `bow_draw_modifier.gd`.
- **Thornwood pod collection is decorative only:** The comment at line 36 promises pods "the player can walk through to collect thornwood" but there is no pickup `Area3D`, no `add_to_satchel` call, and no `thornwood` item anywhere in the data layer. The "cultivation that leaves a small economy on the field" identity is currently just visual flavour.
- **No upgrade or mastery path:** The KB deep-design doc (`kb/wiki/design/Skills and Loadout — Deep Design.md`) puts named cross-skill synergies and per-skill mastery knobs explicitly in HORIZON. BrambleSnare has no configurable upgrade path (extended duration, wider radius, snare-on-impact damage, re-root window, or mark synergy).
- **Control synergies not exploited:** The root cleanly sets up [[skill-rain-of-thorns]] (root then volley) and [[skill-hunters-mark]] (mark a rooted target for +30% burst), but there is no in-game affordance (tooltip combo hint, stat amplification, or tether-on-marked VFX variant) that teaches or rewards the combo.
- **Boss Poise interaction undefined:** The KB notes (`Skills and Loadout — Deep Design.md` line ~107) that bosses are root-immune, so BrambleSnare does nothing to a boss unless the Poise/stagger mechanic is in place. A Poise landing from a rooted elite should clear the root visually to avoid confusing feedback — currently undefined.
- **Windup SFX gap:** `sfx.play("skill_snare")` fires at cast time (line 100), not at the seed landing. The "plant and bind" audio should be at snap (Beat 3), not at cast. A short bow-cast sound at cast time + a distinct snare-crack at snap would be cleaner.

## Plan

### Phase 1 — WINDUP cast animation (complete the 5-beat spec)

The seed launches instantly. Add a brief anticipation pose before the seed flight begins.

- In `fire()`, drive `bow_draw_modifier.gd`'s `draw_amount` (or a new `CastPoseModifier`) to a raised-arm-with-seed-in-hand pose for `SEED_FLIGHT_SEC * 0.4` (roughly 160ms), then release at seed launch.
- Alternatively: the whole-body "cock back" squash used in `creature_anim.gd` (wind-back, scale-Y down 0.92) on `player._mesh` for the same 160ms before the seed spawns.
- Do NOT add a lock window — the player can still move during the wind-up; only the arm/mesh pose is affected. Matches the `bow_draw_modifier.gd` pattern (additive, legs keep cycling).
- **DoD:** a screenshot via `WYRD_SHOT=1` at 80ms post-cast shows a visible arm/body anticipation before the seed arc begins; `test_skills.gd` stays green; no Focus or cooldown accounting changes.
- **Effort: S.** Clone `bow_draw_modifier.gd`'s `draw_amount` tween; no new files required.

### Phase 2 — Audio timing fix + distinct snare-crack SFX

- Move `sfx.play("skill_snare")` from `fire()` (line 100) to `_on_seed_land()` at Beat 3 (the thorn-snap callback in `_spawn_snare_visuals`, line 293).
- Add a lighter "seed-throw" SFX at cast time in `fire()` (generate via `tools/generate_audio.py`, add key `"skill_snare_throw"` to `sfx.gd`).
- Register `"skill_snare_throw"` in `sfx.gd`'s path map. Add `pitch_scale = randf_range(0.95, 1.05)` to both calls (Part A §3 audio rule — same pipeline as see Plan.md Part A §3).
- **DoD:** a sound fires at cast (throw) and a distinct crack fires at Beat 3 (snap); the two SFX keys are in `sfx.gd`; gate green.
- **Effort: S.** One new audio file + two-line code change.

### Phase 3 — Thornwood pod pickup economy

The "cultivation that leaves an economy on the field" comment (line 36) is the spell's identity hook. Wire up the collection side.

- Add a `thornwood_pod` item entry to `wyrd/data/items.gd` (kind: `material`, rarity: `common`, display name: "Thornwood Pod").
- Wrap each pod `MeshInstance3D` in an `Area3D + CollisionShape3D (SphereShape3D, r 0.30)` before adding to the holder. Set `collision_layer` to the pickup layer, `monitoring = false`, `monitorable = true`.
- In `player_controller.gd`'s `_on_pickup_entered` (line 1195), detect nodes named `"ThornwoodPod_Area"` and call `Game.add_to_satchel("thornwood_pod", 1)` + `queue_free` the pod (same pattern as ground pickups in spec 27b).
- The pod `Area3D` must be **parented to the holder** so it withers and queue_frees with the disc — no leaks.
- **DoD:** walking through a snare deposits ≥1 thornwood_pod into the satchel (visible Pack count increase); the pod visual disappears on collection; pods that are not collected queue_free on wither. Logic test: fire snare, step through all pods, assert `game.satchel["thornwood_pod"] == THORNWOOD_POD_COUNT`. Gate green.
- **Effort: M.** New item data entry + Area3D wiring + player pickup handler extension.

### Phase 4 — Control synergy affordances (polish / expansion)

These are expansion beats; nothing here is a blocker.

- **Tooltip combo hints:** extend `skill_bar.gd` (line 56) description for BrambleSnare to mention the root + [[skill-rain-of-thorns]] / [[skill-hunters-mark]] combo. No code change required — just a string update.
- **Mark-on-root variant VFX (optional):** if the player fires [[skill-hunters-mark]] on a rooted enemy, swap the tether color from `Color(0.20, 0.55, 0.18)` (green) to `Color(1.00, 0.82, 0.30)` (gold, matching `MARKED_MULT` indicator color in `combatant.gd` line 94) so the combo reads visually without any new mechanic.
- **Boss Poise window:** when a snared elite gains root-immunity (briarbound, `combatant.gd` line 495), emit a brief "shrug-off" flash on the disc (`disc_mat.emission` pulse to white then decay) so the player sees the immunity land. Prevents silent "skill did nothing" confusion.
- **DoD:** the three tooltip hints are in game; the mark-on-root tether variant is screenshot-verified; the briarbound shrug VFX fires and is captured via `WYRD_DEV_BOSS` or `WYRD_GALLERY_ATTACK`. Gate green.
- **Effort: S–M.** Tooltip = trivial; tether color = 2 lines; shrug flash = ~10 lines in `_spawn_tether`.

## Dependencies & links

- [[system-skills-hotbar]] — owns the 4-slot hotbar dispatch, `_try_skill`, cooldown accounting, and the Huntcraft gate that controls which skills are available; any BrambleSnare upgrade path must go through the gate logic here.
- [[system-status-effects]] — `apply_root` delegates to `apply_status("root", ...)` in `combatant.gd`; the root/snared/briarbound immunity logic lives here.
- [[system-combat-juice-vfx]] — the vine_grow dissolve shader and 5-beat cookbook pattern are the shared VFX vocabulary; Phase 1 WINDUP reuses the same procedural animation primitives (squash, back-out, tween) documented there.
- [[system-animation]] — Beat 1 WINDUP requires a `SkeletonModifier3D` integration; this system owns the `bow_draw_modifier.gd` pattern Phase 1 clones.
- [[skill-rain-of-thorns]] — BrambleSnare's natural combo partner: root the pack, then drop Rain for a free-damage window. Phase 4 tooltip hints both ends of the combo.
- [[skill-hunters-mark]] — mark a rooted target for the +30% burst window (`MARKED_MULT`, `combatant.gd` line 104). Phase 4 tether color variant makes this read visually.
- [[skill-thornburst]] — sibling AoE control skill (boots-radius snare); both skills share the `skill_snare` audio key and the emerald palette, so a tonal split (thornburst = panic, snare = placement) should be visible in sound + VFX without the two reads competing.
- [[system-items-affixes]] — Phase 3 thornwood pod requires a new item in `items.gd`; the item's rarity and any gear-affix interaction (e.g., "Thorn Yield" affix increases pod count) is governed here.
- [[system-combatant-ai]] — briarbound elite modifier and root interrupt of ghost ranged cast (Plan.md Phase 3 note) both touch combatant root state; Phase 4 shrug-off VFX piggybacks on the existing `apply_status` immunity check.
- **Plan.md Part A §4 Phases 1–5 (SHIPPED):** the animation toolkit (squash, BACK tween, overshoot, two-layer transform split) is the shared vocabulary Phase 1 WINDUP reuses — read §1 before implementing. Phase 3 enemy ranged note covers the root-interrupts-ghost-cast behavior that BrambleSnare already satisfies.
- **Plan.md Part B / Phase B0 (`feel.gd`):** when `feel.gd` is created, BrambleSnare's timing constants (`TELEGRAPH_FILL_SEC`, `THORN_SNAP_SEC`, `WITHER_SEC`, `SEED_FLIGHT_SEC`) should migrate there so a playtest is one-file-fast. Do not do this migration until B0 ships.

## Verification

- **Phase 1 (WINDUP):** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` (gate green); `WYRD_SHOT=1` screenshot confirms visible arm/body anticipation in-world.
- **Phase 2 (Audio):** `test_skills.gd` gate green; manual playtest confirms two distinct SFX fire at cast and at snap respectively.
- **Phase 3 (Thornwood pods):** add a case to `test_wyrd_loop.gd` (or `test_skills.gd`) that fires a BrambleSnare in-scene, waits a frame, walks the player over pods, and asserts `game.satchel["thornwood_pod"] == THORNWOOD_POD_COUNT`; all four suites stay green (`WYRD_NO_SAVE=1`).
- **Phase 4 (Synergies/polish):** screenshot of the gold tether variant via `WYRD_GALLERY_ATTACK=1`; briarbound shrug-off captured with `WYRD_DEV_BOSS=` pointing at a briarbound elite; tooltip text spot-checked in-game via `WYRD_UI_SHOT`.

## Open questions

- Should thornwood pods persist after the wither (leaving collectibles on the floor) or always queue_free with the disc holder? The current comment says "Player walks through them (or they remain after wither)" but the `_wither` recursion (line 528) would destroy them with the holder. Decide before Phase 3: if they persist, pods need to be reparented from the holder to the scene root at wither time.
- At what Huntcraft level (if any) should pod count or snare duration be upgraded? The KB's HORIZON note defers named synergies and mastery knobs — confirm whether Phase 4 upgrade path is in or out of the demo scope before building.
- Should BrambleSnare deal impact damage at snap (like [[skill-rain-of-thorns]] does with `DMG_MULT 1.8`)? Currently it deals 0 damage; it is purely control. The design notes (`kb/wiki/design/Skills and Loadout — Deep Design.md`, answer column: `space(root)`) suggest pure CC is intentional — but confirm before Phase 4 polish.
