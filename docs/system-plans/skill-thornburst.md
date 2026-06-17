---
title: Thornburst
domain: Combat Skills
type: skill
status: partial
effort: M
tags: [wayfinder, plan]
---

# Thornburst

> Player-centered ring AoE (3.2 m, 1.4× DMG, 2 s Snare, 30 Focus, 8 s CD) — the panic/escape button — VFX is a minimal alpha-fade torus; the gap is the full Spec-34 5-beat treatment BrambleSnare received, plus upgrade hooks and a windup beat.

## Current state

`wyrd/scripts/skills/thornburst.gd:1–57` (tagged `B5-wave2`) is a functional but visually thin implementation. The skill correctly fires via `AoeQuery.query_circle` centered on the player at `RADIUS = 3.2` m, deals `DMG_MULT = 1.4×` damage to everything in range (`thornburst.gd:22–28`), applies `apply_status("snared", 2.0, 0, 0.5)` to every hit combatant (`thornburst.gd:29–31`), triggers a `−0.5` recoil (`thornburst.gd:32–33`), and plays `sfx.play("skill_snare")` (`thornburst.gd:34–36`). The Snare slow (`SNARE_SLOW = 0.5`) feeds into `combatant._slow_product()` (`combatant.gd:575–579`) which multiplies all active slow factors, so the numeric effect is live.

The VFX (`_ring_vfx`, `thornburst.gd:39–57`) is a single `TorusMesh` that scales out to `RADIUS / 0.6` over 0.28 s then alpha-fades — no ground disc, no thorn spikes, no anticipation beat, no player wind-up. This is the "Spec-31 placeholder" pattern, comparable to what `bramble_snare.gd` looked like before Spec-34 rebuilt it with the 5-beat AoE structure.

The skill has no Wayfinding-level gate (absent from `SKILL_REQS` in `game.gd:118`), is correctly registered in `SKILL_POOL` (`game.gd:114`), costs 30 Focus (`loadout_panel.gd:28`), and has a tooltip and icon (`loadout_panel.gd:17, 37`). The `skill_snare.mp3` SFX key exists (`sfx.gd:24`). Mastery upgrades (extending snare duration, adding a second slow tier, adding a thornwood pod scatter) are not implemented.

Status correction: the pre-filled guess of **complete** is wrong. The gameplay loop (damage + snare) works, but the VFX is a stub-level torus fade. Correct status: **partial**.

## Gaps — what needs fleshing out

1. **(Blocker for feel)** VFX is a bare torus fade. No ground disc, no thorn spikes, no 5-beat read. Panic button must read instantly — the torus only conveys range, not impact.
2. Player anticipation beat missing — no wind-up or cast pose before the burst fires. BrambleSnare has a `apply_recoil(−0.25)` + facing update at cast time; Thornburst's `−0.5` recoil fires *after* the AoE, feeling like a side-effect rather than a decision.
3. Snare VFX on the hit enemies is provided by `combatant.gd:682–698` (vine-wrap particles) — but Thornburst currently spawns the visual inline in the `_ring_vfx` burst; there is no per-enemy tether/bind the way BrambleSnare has (`bramble_snare.gd:462–520`). The panic read is "radius explosion" rather than "I bound every enemy near me."
4. No dedicated impact SFX distinct from `skill_snare` (shared with BrambleSnare). A heavier thud/burst would differentiate the close-range explosion feel from BrambleSnare's thrown-seed feel.
5. No upgrade path — snare duration, radius, or a secondary effect (e.g. brief bark-shield on self after cast) are unimplemented and unhookable; there are no constants parameterizing upgrades.
6. Thornburst has no Wayfinding-level unlock requirement despite being a deeper-utility skill (HeartwoodWard gates at 7, MercyShot at 9 — `game.gd:118`). Whether Thornburst should gate at e.g. level 5 is an open design question.

## Plan

### Phase 1 — 5-beat VFX rebuild (Spec-34 treatment)

Parallel to what `bramble_snare.gd` received. Thornburst is player-centered (no projectile flight, no landing reticle needed) so beats 1–2 collapse into a single anticipation flash.

- Replace `_ring_vfx` with a `_burst_vfx(player)` that runs 4 beats:
  - **Beat 1 — Anticipation flash (0.08 s):** player mesh gets a brief emissive green pulse (reuse the `HitFeedback` flash pattern; just swap color to `Color(0.4, 1.0, 0.4)`). Signals "something is about to erupt."
  - **Beat 2 — Telegraph disc (0.12 s):** amber `CylinderMesh` disc (`top_radius = RADIUS`, `height = 0.05`) scales 0 → 1 at player feet with `TRANS_CUBIC / EASE_OUT` — matches the BrambleSnare telegraph pattern. Keeps the AoE dodgeable by nearby enemies (FFXIV rule; 120 ms is tight but Thornburst is the *panic* button, not a crowd-catcher, so a very short window is appropriate).
  - **Beat 3 — Snap + thorn burst (0.10 s):** disc color flips emerald; 8 `PrismMesh` thorn spikes spring up around the player at `RADIUS * 0.90` with `vine_grow.gdshader` (`growth` 0 → 1, reusing `assets/vfx/vine_grow.gdshader`). Scale BACK ease — identical to `bramble_snare._spawn_thorns`. A 2nd ring of 4 inner thorns at `RADIUS * 0.4` reads "erupted from the boots."
  - **Beat 4 — Wither (0.25 s):** disc alpha-out + thorns retract tip-to-base via `growth` 1 → 0, reusing `bramble_snare._wither_subtree` pattern verbatim.
- Move the AoE damage call to fire at Beat 3 onset (same tick as snap) — the visual and the damage land together.
- **Dedicated SFX:** add `"thornburst_impact": "res://audio/thornburst_impact.mp3"` key to `sfx.gd`. Generate the file with `tools/generate_audio.py` (heavy thud + rustle, distinct from the BrambleSnare seed-land sound). Call `sfx.play("thornburst_impact")` at Beat 3 onset; keep `sfx.play("skill_snare")` at cast time as the "drawing in" cue.
- **DoD:** the burst shows an amber disc (≥ 1 frame visible), snaps emerald, thorn spikes appear via vine-grow dissolve, all wither within 0.45 s total. Gate-green headless suites pass. Screenshot the snap frame via `WYRD_SHOT=1` in dungeon.
- **Effort: M**

### Phase 2 — Player cast anticipation beat

Currently `apply_recoil(-0.5)` fires after the AoE (`thornburst.gd:32`). The burst must read as a player-driven eruption.

- Add a 0.06 s pre-fire hold: delay the `AoeQuery` call and Beat 3 by 0.06 s. During that window, `apply_recoil(-0.5)` fires (existing) and a brief `scale_punch` on the player mesh (1.0 → 0.88 → 1.0 over 0.12 s, squash-in, ease out — the "coiling" anticipation from Plan.md Part A §1). This is the same pattern used for enemy wind-back in Phase 2 of Plan.md (SHIPPED).
- **DoD:** player visibly crouches/pulses 60 ms before thorns erupt; the punch reads on a screenshot. Gate green.
- **Effort: S**

### Phase 3 — Upgrade hooks + mastery integration

Thornburst is currently flat — the same skill at level 1 and level 17. Add parameterized upgrade constants and wire them to mastery perks.

- Expose `snare_duration_bonus: float = 0.0` and `radius_bonus: float = 0.0` as instance vars (set by mastery system). Effective snare = `SNARE_SEC + snare_duration_bonus`; effective radius = `RADIUS + radius_bonus`.
- Add a Wayfinding-level gate. Proposal: Thornburst unlocks at level 5 (sits between HuntersMark:4 and HeartwoodWard:7 — see Open Questions). Update `SKILL_REQS` in `game.gd:118`.
- Perk tier A (Wayfinding 5 — unlock): base stats (as shipped).
- Perk tier B (Wayfinding 8): `snare_duration_bonus = +1.0 s` (total 3 s). Wire via the mastery perk system (pattern in `game.gd:417`).
- Perk tier C (Wayfinding 11): `radius_bonus = +0.8 m` (total 4.0 m) — shifts from "panic grab nearby enemies" to "clear the whole room perimeter."
- Optional fourth perk: on successful hit of 2+ enemies, grant a 30-HP `HeartwoodWard`-style absorb for 3 s ("the thorns draw blood, the bark drinks it"). Wire via `player.apply_ward(30, 3.0)` conditional on hit count ≥ 2.
- **DoD:** `SKILL_REQS` contains Thornburst entry; `skill_unlocked("Thornburst")` returns false at lv 4, true at lv 5 (verify with `test_skills.gd` assertion). Perk tier B/C constants read from the instance var (headless test asserts `effective_radius` and `effective_snare`). Gate green.
- **Effort: M**

### Phase 4 — Polish pass (if status = expansion)

After Phases 1–3, the skill is feature-complete. Polish:

- Add a subtle screen micro-kick on burst snap (see Plan.md Part A §3 — shake-toggle aware, low intensity ≤ 0.3 u).
- Co-op: verify `AoeQuery.query_circle` runs host-only (Thornburst is player-centered, same model as enemy projectiles in Plan.md §3 — damage is host-authoritative, cosmetic beats run locally on caster).
- Add per-enemy vine-tether the moment the snare applies (`bramble_snare._spawn_tether` pattern) — optional, adds visual binding identity vs. BrambleSnare which already uses tethers. Differentiation angle: Thornburst tethers are shorter, more jagged spikes (it's an explosion, not a binding ritual). Guarded by `is_instance_valid` checks.
- **DoD:** play-test sign-off that burst reads as "eruption / panic" not "snare AoE clone." Shake toggle preserves readability.
- **Effort: S**

## Dependencies & links

- [[system-status-effects]] — `apply_status("snared", ...)` is the core mechanic; `Combatant._slow_product()` and the briarbound CC-immune window both affect whether Thornburst's snare lands.
- [[skill-bramble-snare]] — Phase 1 directly ports the Spec-34 5-beat VFX structure from BrambleSnare. `vine_grow.gdshader`, `_spawn_thorns`, `_wither_subtree`, and tether patterns are candidates for direct reuse.
- [[system-skills-hotbar]] — Thornburst lives on hotbar slots 2–4; the `_try_skill` dispatch and cooldown/Focus gate in `player_controller.gd:1403` owns the fire path.
- [[system-trades-progression]] — Phase 3 adds a Wayfinding-level gate. ADR 0012 (one trade) and ADR 0006 (level cap 17) define the ceiling; mastery perk tiers should stay within the level 5/8/11 band.
- [[skill-heartwood-ward]] — Optional Phase 3 perk (absorb on multi-hit) reuses `player.apply_ward()`; ward HP budget should not overshadow HeartwoodWard's dedicated 30 HP / 14 s CD role.
- [[system-combat-juice-vfx]] — Phase 1 VFX and Phase 4 micro-kick follow the same procedural juice patterns established in Plan.md Part A (SHIPPED). See Plan.md Part A §1 (animation tactics) and §3 (cross-cutting rules).
- [[system-combatant-ai]] — Thornburst is the player's only instant-AoE; AI pathing into melee range is what makes it relevant. Any AI range-closing buff makes Thornburst more valuable.
- [[system-elites]] — Briarbound elite is CC-immune after first root/snare (`combatant.gd:492–495`). Thornburst's snare is subject to this window; the Phase 3 upgrade (longer duration) doesn't help if briarbound blocks the first landing.

Plan.md Part A (combat-feel SHIPPED) — the animation tactics in §1 (anticipation → action → follow-through, squash/stretch, BACK ease) are the vocabulary Phase 1 and Phase 2 draw from directly. Phase 4's co-op ruling follows Part A §3's host-authoritative model. Do not replicate Plan.md phases here.

Plan.md Part B (loop-feel PLANNED) — no overlap; Thornburst is pure combat. The `feel.gd` tunables proposed in Phase B0 could absorb Thornburst's new timing constants; wait for B0 to land before extracting them.

## Verification

**Phase 1:**
```
cd /Users/bbroeking/projects/gj26/wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
```
Then `WYRD_SHOT=1 godot --path .` in dungeon, fire Thornburst, confirm screenshot shows amber disc → emerald snap with visible thorn spikes.

**Phase 2:** screenshot at snap frame shows player mesh scale visibly compressed (< 1.0) 1 frame before thorn eruption. Gate green after.

**Phase 3:** add to `test_skills.gd`:
- assert `Game.skill_unlocked("Thornburst")` is false at Wayfinding lv 4.
- assert `Game.skill_unlocked("Thornburst")` is true at Wayfinding lv 5.
- assert a `Thornburst` instance with `radius_bonus = 0.8` has effective radius 4.0.
Gate green across all four suites.

**Phase 4:** play-test sign-off from user (motion/feel — same criterion as Plan.md Phase 2/3). Co-op: host fires Thornburst, guest observes thorn VFX locally; damage resolves only on host.

## Open questions

1. **Level gate for Thornburst** — currently ungated (no entry in `SKILL_REQS`). Proposed: gate at Wayfinding 5, sitting between HuntersMark (4) and HeartwoodWard (7). Or keep it open if it is meant as a beginner panic option. Decision gates Phase 3.
2. **Per-enemy vine tethers in Phase 4** — BrambleSnare's tethers are its signature "binding" identity. If Thornburst also sprouts tethers, it risks blurring the two skills' reads. Preferred differentiation: Thornburst is an eruption (no tethers, just spikes), BrambleSnare is a binding (tethers + thornwood pods). Confirm before Phase 4.
3. **Thornburst-specific impact SFX** — shares `skill_snare.mp3` with BrambleSnare today. A distinct audio identity (heavy thud vs. seed-land rustle) is proposed for Phase 1. Requires one `generate_audio.py` run; confirm budget.
