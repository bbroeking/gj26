---
title: Basic Shot
domain: Combat Skills
type: skill
status: complete
effort: M
tags: [wayfinder, plan]
---

# Basic Shot

> Slot-1 always-on bow shot is fully functional and juicy; the single most important next step is wiring the 4-variant colour-picker (`Arrow.variant_idx`) which is stubbed but never written by `player_controller.gd`.

## Current state

`basic_shot.gd` (all 27 lines) defines a `ProjectileSkill` subclass: `cost = 0.0`, `base_cd = 0.28`, `damage_mult = 1.0`, `skill_type = "basic"`, `sfx_key = "fire"`, `recoil_amount = -0.4`, `bow_pop_mult = 1.22` (`basic_shot.gd:8-18`). The `effective_cd` override reads `derived_stats.fire_cooldown` (`basic_shot.gd:22-26`), which is computed from the `fire_rate` affix (`player_controller.gd:1122-1123`) — deliberately separate from `cooldown_reduction` which only scales slots 2-4 (spec 30 split). Dispatch is dual-path: the F-key fire-buffer loop fires it on any frame `_fire_buffer > 0` and CD is clear (`player_controller.gd:617-626`); pressing 1 just re-arms `_fire_buffer` rather than firing immediately (`player_controller.gd:904-905`). `ProjectileSkill.fire()` handles origin, aim, recoil, bow-pop, and SFX (`projectile_skill.gd:28-60`).

VFX is fully realized in `arrow.gd`: four colour variants (gold/emerald/frost/violet) with a glowing `CapsuleMesh` + `GPUParticles3D` trail using textured billboard quads (`arrow.gd:78-177`, spec 34). Impact burst via `_explode()` (`arrow.gd:351-384`). SFX: `fire.mp3` exists and is pitch-jittered ±7% (`sfx.gd:86-93`); arrow impact plays `hit`/`crit` through `HitFeedback.play_hit` (`hit_feedback.gd:66-69`). The `capture_rig.gd` includes a `"basicshot"` entry (`capture_rig.gd:33`) so screenshot captures work. Perk effects on BasicShot: `steady_hands` (lv 5, +5% crit) and `heavy_draw` (lv 14, +25% crit_mult) apply via the shared `sums` dict (`player_controller.gd:1101-1108`); note `quick_nock` (lv 12, +10% CDR) does NOT affect BasicShot — it feeds `cooldown_reduction` which is the slots 2-4 path only.

**The variant-picker is unfinished:** `arrow.gd:8` says "player_controller writes Arrow.variant_idx on 1-4" and the static var is declared (`arrow.gd:96`), but there is no write of `ArrowScript.variant_idx` anywhere in `player_controller.gd` or the rest of the codebase.

## Gaps — what needs fleshing out

1. **Variant colour-picker unwired** (medium, no blocker): `ArrowScript.variant_idx` is never written. The 4-variant selector promised in spec 26/34 is dead. The `_try_skill` path already intercepts 1-4 — wiring it means branching on "is the current slot already 1?" to differentiate "re-select slot 1 → cycle variant" from "press 1 to arm shot."
2. **Charged-shot variant absent** (design gap, medium scope): no hold-F / charge mechanic exists anywhere. The scope note asks to plan it; see Phase 2 below.
3. **`quick_nock` perk wording vs. behaviour mismatch** (small, polish): tooltip says "skills come back a tenth sooner" but BasicShot's CD is `fire_cooldown` not `cooldown_reduction`, so lv-12 Wayfinders get no BasicShot speedup from `quick_nock`. Either the perk should also add a small `fire_rate` bonus or the tooltip should clarify "your special skills (slots 2-4)."
4. **No dedicated arrow-impact SFX key**: `fire.mp3` covers the bow-release; the arrow-hit sound comes from the shared `"hit"`/`"crit"` pool, which enemies also use for melee hits. A distinct `"arrow_impact"` key would separate the two reads (low-pri, one ElevenLabs call).
5. **Mastery path in tooltips**: `skill_bar.gd:53` reads "A quick arrow. No Focus cost — your bread and butter (also on F)." No mention of what scales it (`fire_rate` gear / perks). Consider a second tooltip line naming the scaling axis once the perk situation above is resolved.

## Plan

### Phase 1 — Wire the variant colour-picker
*(expansion/polish — the core skill is shipped)*

- In `player_controller.gd`, inside the `_try_skill(slot)` branch that handles `slot == 1`, add a cycle: if `_skill_cooldowns[1] > 0.0` (shot is on CD) treat a key-1 press as "cycle variant" instead of just re-arming the buffer. Cycle: `ArrowScript.variant_idx = (ArrowScript.variant_idx + 1) % ArrowScript.VARIANTS.size()`.
- Alternatively, expose the cycle on a dedicated keybind (e.g., `ui_cycle_variant`) so pressing 1 mid-cooldown doesn't ambiguously "do something different." Check with user.
- Update `skill_bar.gd` tooltip for BasicShot to surface "press 1 while reloading to cycle bolt colour (4 variants)" — or leave it as a hidden secret.
- **DoD:** pressing 1 four times cycles gold → emerald → frost → violet; newly spawned arrows match; survives a headless `test_wyrd_loop.gd` run (no regression in skill dispatch).
- **Effort:** S

### Phase 2 — Charged-shot variant (held-F mechanic)
*(new feature, design gap)*

No hold-F machinery exists. This phase plans and implements it.

Design intent (to confirm with user before coding):
- Hold F ≥ 0.5 s → arrow spawns with `damage_mult ≈ 2.5`, narrower spread, slower `base_cd` (≈ 0.60 s effective). Visually: `_bow_draw_t` held at `BOW_DRAW_TIME` while charging, extra glow ring drawn on the crosshair or HUD ring. SFX: reuse `charge.mp3` (already in `audio/`) as the hold ramp; release fires the existing `fire.mp3`.
- Implementation outline:
  - Add `_charge_t := 0.0` and `const CHARGE_THRESHOLD := 0.50` to `player_controller.gd`.
  - In `_physics_process`, if `Input.is_action_pressed("fire")` accumulate `_charge_t`; on release check if `_charge_t >= CHARGE_THRESHOLD` — if so, call a new `_fire_charged()` that instantiates a modified `BasicShotScript` with `damage_mult = 2.5` and `skill_type = "power"` visual but fires from slot 1.
  - Cancel if `_charge_t > 0` and player rolls or opens inventory.
  - `capture_rig.gd`: add a `"chargedshot"` entry (slug, kind `"skill"`, slot `1`) with a longer `POST_FIRE_FRAMES` constant.
- **DoD:** holding F ≥ 0.5 s fires a heavier-looking arrow dealing ≥2× damage with a distinct visual; tapping F still fires a standard BasicShot at the normal 0.28 s CD; headless `test_wyrd_loop.gd` passes; `test_wyrd_dungeon_scene.gd` passes; play-test confirms charged shot doesn't break the F-spam feel for tap-fire.
- **Effort:** M

### Phase 3 — Perk wording + `quick_nock` fix
*(polish, small)*

- Decision: does `quick_nock` (lv 12) add `fire_rate` as well as `cooldown_reduction`? If yes: add `_add_stat(sums, "fire_rate", 0.08)` in the `quick_nock` branch (`player_controller.gd:1106`). If no: update the perk `"desc"` in `game.gd:441` to say "Your special skills (slots 2-4) come back a tenth sooner."
- Update `skill_bar.gd` BasicShot tooltip to mention the `fire_rate` axis once the above is resolved.
- **DoD:** perk wording and behaviour agree; `test_wyrd_loop.gd` perk-active assertions still pass.
- **Effort:** S

### Phase 4 — Dedicated arrow-impact SFX (optional, low-pri)
*(polish; one ElevenLabs credit)*

- Add `"arrow_impact": "res://audio/arrow_impact.mp3"` to `sfx.gd:PATHS`.
- In `HitFeedback.play_hit`, pass an optional `sfx_override: String = ""` parameter; callers from arrow impact pass `"arrow_impact"`. Existing hit-flash-from-melee keeps `"hit"`.
- Generate `arrow_impact.mp3` via `tools/generate_audio.py`.
- **DoD:** arrow hits play a distinct thwock; melee hits still play the old hit; no pitch-jitter regression (`sfx.gd:92` pool path unchanged).
- **Effort:** S

## Dependencies & links

- [[system-skills-hotbar]] — BasicShot is the permanent slot-1 anchor; the hotbar grey-out and CDR-split design live here. Phase 1's variant-cycle UX must respect the hotbar's "slot 1 always locked" visual rule.
- [[system-player-controller]] — `_try_skill`, `_fire_buffer`, `BOW_DRAW_TIME`, `apply_recoil`, `effective_cd` dispatch all live here; Phase 2 adds `_charge_t` to this file.
- [[skill-power-shot]] — PowerShot owns the `"power"` visual (ember-red, 2.5× scale, AoE burst, `POWERSHOT_VARIANT`); the charged-shot variant in Phase 2 borrows the same visual identity — coordinate so they stay distinguishable (different entry point means different hotbar slot, but the bolt looks similar).
- [[system-combat-juice-vfx]] — bolt VFX variants, `_explode`, `_spawn_power_aoe_burst`, and the `HitFeedback` tier system live here; Phase 4's dedicated impact SFX plugs into `HitFeedback.play_hit`.
- [[system-trades-progression]] — the perk ladder (`steady_hands` / `heavy_draw` / `quick_nock`) is defined in `game.gd`; Phase 3 touches perk wording and effect.
- [[system-audio-music]] — `sfx.gd` pool + pitch-jitter pattern; Phase 4 adds one new key following the established pattern.
- Plan.md Part A (Phases 1-5) — combat feel is **SHIPPED**. The bow-draw recoil animation (P4: `BOW_DRAW_TIME`, `BowDrawModifier`, `apply_recoil`) and the juice layer (P5: bow-pop, hitstop, screen-shake via `HitFeedback`) already underpin BasicShot — do not re-plan those. Phase 2 here reuses those same animation hooks.

## Verification

- **Phase 1 (variant cycle):** `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` — confirm no skill-dispatch regression. Manual: launch game, press 1 three times, confirm bolt colour cycles.
- **Phase 2 (charged shot):** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` + `test_wyrd_dungeon_scene.gd` both green. Manual play-test: tap-fire feels unchanged at normal cadence; hold 0.5 s fires heavy shot with correct visual + damage (use combat dummy).
- **Phase 3 (perk wording):** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` — the `perk_active` assertions at `test_wyrd_loop.gd:298-305` must stay green. Inspect `derived_stats.fire_cooldown` at lv 12 to confirm the change (or non-change) matches intent.
- **Phase 4 (SFX):** manual playtest with audio on; confirm arrow hits and melee hits sound distinct.

## Open questions

1. **Variant-cycle UX:** should pressing 1 mid-cooldown cycle the variant (dev-mode flavour), or should there be a dedicated keybind to avoid accidental re-arms? (Phase 1 decision.)
2. **Charged-shot scope:** is Phase 2 a planned feature or cut? The scope note asks to "plan the charged-shot variant" but it is not mentioned in any spec/ADR. Needs sign-off before implementation.
3. **`quick_nock` + BasicShot:** should lv-12 Wayfinders feel their bow speed improve (add `fire_rate` component) or is the current CDR-only behaviour intentional? (Phase 3 decision.)
