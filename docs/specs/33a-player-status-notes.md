# Implementation notes — 33a-player-status

## Decisions
- **`_apply_tick_damage` on the player skips `take_damage` entirely** (same pattern as Combatant's `_apply_tick_damage`). Bypasses i-frames, crit roll, knockback, hitstop, SFX — DoT ticks are passive drains, not impacts.
- **Status suffix joins with `" · "` (middle dot)** like the spec said. Stable order = dict insertion order (no sort).
- **`_status_suffix` prefixes with `" — "`** so it composes cleanly with the existing `"HP %d / %d"` format string. Empty suffix preserves the old shape exactly.
- **Player movement integration**: instead of multiplying `spd` by `_status_slow_product()` directly, gated through an explicit `if has_status("root"): spd = 0.0` check first. Root immobilizes (not just clamped to 0.25); the slow product handles everything else.
- **`_hud.set_hp(hp, hp_max, _status_suffix())` fires every physics frame**, not just on state changes. set_hp is cheap (label.text + ColorRect offset); no need for change-detection.

## Deviations
- **Did NOT update every existing `_hud.set_hp(hp, hp_max)` call site** (5 of them around the codebase). The per-frame set_hp call from `_physics_process` overwrites the suffix-less call within one frame — single-frame staleness is acceptable for v1. Tighter would be to make `_update_hud_hp()` a single helper that all call sites share; tracked as a followup.
- **`apply_status` return type left untyped** (not `-> StatusEffect`). Combatant's return-type strictness already bit us during the spec 32d Interactable migration; matching the loose pattern avoids the same parse-error gotcha.

## Tradeoffs
- **Port (not extract).** Combatant.apply_status is 30+ lines, and ~95% of it is identical to what the player needs. Could have factored into a `StatusBearer` mixin — but Combatant's status code is entangled with `_meshes` / `_flash_mat` / `_apply_tick_damage`, and the player doesn't share those internals. Extraction would have required threading abstractions through. v1 ports; an extract spec can land if a third caller (boss-side player-style statuses, breakable obj statuses) appears.
- **No status particles on the player.** Combatant gets a feet-ring / above-head particle for each kind via `_make_status_particle`. Player skipped — the HP-bar text suffix carries the read. The visual layer would also need the player's `_meshes` cache + the `apply_flash` plumbing, which is a follow-up.
- **Sunlit damage delta**: pre-33a +3 immediate burst; post-33a 6 over 3s. Net more total damage but spread out — player can disengage to interrupt. Documented in spec; playtest will judge.

## Surprises
- **The `_tick_statuses(delta)` call slots in cleanly** at the top of `_physics_process` right after the combat-timer + skill-cooldown decrement. No state ordering issues. The `_hud.set_hp` refresh I put a few lines later is a one-frame lag from a status applying but works as long as the player runs `_physics_process` (i.e. not dead).
- **`_apply_tick_damage` calling `_die()` on lethal damage** flagged a subtle thing: `_die` on the player is a long animation + respawn sequence. If a burn tick kills the player, the existing death pipeline runs end-to-end. Tested incidentally — `test_player_status.gd P1` starts player at 30 HP and burns for 6, lands at 24. Never crosses 0.
- **`StatusEffectScript` was already used by `combatant.gd`**; just adding a parallel preload in `player_controller.gd` works without conflicts. RefCounted scripts cache across consts cleanly.

## Followups
- **Refactor the 5 `_hud.set_hp(hp, hp_max)` call sites** into a single `_update_hud_hp()` helper that always passes the suffix. Removes the 1-frame staleness. ~10 lines of refactor.
- **Player status particles** — when polish-pass time comes, add a small particle above the player mesh per active status (mirror of Combatant's `_make_status_particle`). Requires caching the player's `_mesh` references and exposing them.
- **Player `apply_flash` method** — would unlock spec 32c's `HitFeedback.tick_pulse` on the player too. Currently the player has its own hit-flash via `_hud.flash()` (a UI flash, not a mesh flash); adding a mesh flash would require new infrastructure on player_controller.
- **Sunlit damage tuning** — playtest the 6-over-3s burn vs 3-immediate trade. If feels weak, bump the burn dpt or duration in `combatant._trigger_burn_pulse`.
- **Bleed-on-crit for enemies-hitting-the-player** is still gated to "enemy" group. If we ever want enemy crits to bleed the player, flip the gate in `combatant.take_damage`. Spec keeps the asymmetry.

## Status
COMPLETE — `test_player_status.gd` 4/4 + every existing harness still green. **Full tally: 90/90 evals across 12 harnesses.** Sunlit elite now applies real Burn DoT to the player (visible in HP bar as "HP X/30 — burning").
