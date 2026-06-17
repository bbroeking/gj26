---
title: Status Effects
domain: Player & Abilities
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Status Effects

> Five ailments (burn / bleed / snared / root / marked) are fully wired on enemies and the player; the gaps are player-facing readout fidelity, multiplayer sync of player statuses, a cleanse path, and a headless suite gap for player immunity edge-cases.

## Current state

`status_effect.gd` (lines 1–19) is a pure-data `RefCounted`: `kind`, `time_left`, `tick_interval`, `next_tick`, `damage_per_tick`, `slow_factor`, and a `visual: Node3D` owned by the combatant. No logic lives here.

`combatant.gd` owns the full enemy-side pipeline (lines 81–574):
- `_statuses: Dictionary` keyed by kind string (line 86).
- `STATUS_COLOR` and `APPLY_TEXT` palettes for all five kinds (lines 89–102).
- `apply_status` (line 487) implements highest-wins + refresh-duration stacking (D3 model): max `time_left`, max `damage_per_tick`, min `slow_factor`. Returns null on death.
- `_tick_statuses` (line 549) ticks one interval per frame (single-tick, no catch-up), calls `_apply_tick_damage` → `HitFeedback.tick_pulse` for coloured mesh pulses (line 567).
- `_slow_product` (line 575) multiplies all `slow_factor`s, clamped to 0.25× minimum.
- Visuals: root gets an emerald disc (`_make_root_disc` line 605); burn/bleed/snared each get a distinct-silhouette `GPUParticles3D` (rise / fall / orbit respectively, lines 627–733).
- Apply-text floats on first application via `_spawn_apply_text` (line 737).
- `_clear_all_statuses` (line 753) frees all visuals on death.

`boss.gd` overrides `apply_status` (line 69): root and snared are fully blocked (`IMMUNE_KINDS = ["root","snared"]`, line 66); burn and bleed land at 0.5× duration (`REDUCED_DURATION`, line 67). The boss bar tag reads " — Unyielding" so the player learns why the snare bounced.

`player_controller.gd` mirrors the enemy framework (spec 33a, lines 1507–1601):
- Same `apply_status` / `has_status` / `get_status` / `_tick_statuses` / `_apply_tick_damage` / `_status_slow_product` (lines 1521–1587).
- `_status_suffix()` (line 1591) renders active statuses as a storybook suffix on the HP orb ("burning · snared"). `STATUS_WORD` (line 1514) covers burn / bleed / snared / root — **`marked` is absent**, but marked is currently only applied to enemies (not the player) so the omission is harmless for v1.
- Player-side status tick does **not** fire a coloured mesh pulse or a UI icon — only the HP-bar text suffix.
- No `_clear_all_statuses` on player death (statuses simply expire with the scene).

`skill_effect.gd` (lines 1–54) is a data container + static factories (`burn`, `snared`, `bleed`, `marked`) that duck-type onto any node with `apply_status`. Arrow.gd carries an `effects: Array` and calls `e.apply()` on impact.

Skills that apply statuses: `power_shot.gd` → burn (3s / 0.5s / 1dpt); `multi_shot.gd` (via arrow effects) → snared (1.5s, slow 0.5); `rain_of_thorns.gd` → bleed (2s / 0.5s / 1dpt); `hunters_mark.gd` → marked (8s); `bramble_snare.gd` → root (2s) via `apply_root` alias (line 543 combatant.gd).

Two headless test suites cover the system:
- `test_statuses.gd` — T1–T7: burn ticks, arrow dispatch, boss immunity, stacking rules, AoE query.
- `test_player_status.gd` — P1–P4: player burn/bleed/snared/Sunlit-elite end-to-end.

Neither suite is in the four-suite gate (`test_wyrd_loop`, `test_wyrd_dungeon_scene`, `test_wyrd_transitions`, `test_skills`). They run separately.

## Gaps — what needs fleshing out

1. **Player-side visual feedback is text-only** (HP suffix) — no coloured mesh tint pulse, no status icon row, no per-status icon with a countdown pip. Enemy combatants get both a particle system and a tick-pulse flash; the player gets neither. A burning player looks identical to a healthy one.
2. **`marked` missing from `player_controller.STATUS_WORD`** (line 1514) — benign today (only enemies get marked), but breaks the suffix if any future enemy ever marks the player. Two-line fix.
3. **No cleanse path** — `_quaff` heals HP or applies a buff draught; no consumable removes an active status. The crafting data has `quickroot_tonic` (line 100 of `crafting.gd`) but it is wired as a buff draught, not a cleanse. If enemy DoT sources multiply (deeper dens, new elite modifiers), there is no defensive answer.
4. **Multiplayer status sync gap** — player statuses (`player_controller._statuses`) are local-only. In co-op, a Sunlit elite's `_trigger_burn_pulse` calls `_player.apply_status` on the host's local player only; guest players near the same elite are never burned. The enemy's own status sync rides the `net_apply_state` HP snapshot (combatant line 245), which is correct for enemies but player statuses need the same treatment.
5. **`test_statuses.gd` / `test_player_status.gd` are outside the gate** — a regression in the status framework would not be caught by the four-suite CI gate. The suite design is good; it just needs to be added to the standard run order (or promoted into `test_wyrd_loop.gd`).
6. **Boss "Unyielding" tag is hard-coded in `boss.gd`** (commented at line 65) but not actually rendered in `boss_bar.gd` yet — needs verification.
7. **No stacking-mode documentation for new statuses** — adding a sixth status kind requires touching `STATUS_COLOR`, `APPLY_TEXT`, `_make_status_particle`, `STATUS_WORD`, `SkillEffect` factories, and the two test suites. There is no single registration point.

## Plan

### Phase 1 — Player visual parity + `marked` fix (polish)
The player already has the tick loop and the HP-bar suffix. Close the gap so a burning/bleeding player is as readable as a burning enemy.

- **`marked` in STATUS_WORD** (`player_controller.gd` line 1514): add `"marked": "marked"`. One line — do this first.
- **Tick-pulse on player**: in `player_controller._apply_tick_damage` (line 1572) call `HitFeedback.tick_pulse(self, kind)` mirroring combatant line 567. Requires `self` to have `_meshes` + `apply_flash` — player already has both.
- **Status icon strip on the HUD**: add a small horizontal row of coloured pips (one per active status) above the HP orb in `player_hud.gd`. Reuse `STATUS_COLOR` palette from `combatant.gd` (extract to a shared autoload const or duplicate into `player_controller.gd`). Each pip is a filled circle in the status colour with a clockwise-drain arc showing `time_left / duration` — drawn in `_draw` on a `Control` node (no textures, no white-rect risk). Pips appear/vanish as statuses start/end.
- **DoD:** taking Burn from a Sunlit elite: (a) player mesh pulses orange on each tick, (b) an orange pip appears above the HP orb and drains over the burn duration, (c) the suffix still reads "burning". Verified by extending `test_player_status.gd` with a P5 assertion (tick-pulse called, pip count = 1 after apply).
- **Effort: S**

### Phase 2 — Cleanse path (consumable hooks)
Give the player a defensive answer to stacking DoTs at deeper den depths.

- Add a `cleanse_status(kind: String)` method on `player_controller.gd` that calls `_statuses.erase(kind)` and frees any visual (player statuses currently have no visuals — so it is just the dict erase).
- Wire `quickroot_tonic` consumption to call `cleanse_status("root")` + `cleanse_status("snared")` (thematic: a root-clearing herb). This hooks into `game.quaff_buff_draught()` → the consume path already exists.
- Extend `SkillEffect` with a `cleanse` static factory (no `status_kind` — clears a nominated kind on the target) so future skill-based cleanse effects are data-driven.
- **DoD:** consuming a `quickroot_tonic` while rooted removes the root status and its tick immediately; `test_player_status.gd` P6 asserts the cleanse. Gate stays green.
- **Effort: S**

### Phase 3 — Multiplayer player-status sync
Close the co-op gap: a guest player near a Sunlit elite should burn.

- The existing model: host sends enemy HP snapshots; guests replicate enemy state. Player statuses are not in the snapshot.
- Add a `status_sync` RPC on `net_game.gd` (reliable, authority→all peers): `{ peer_id, kind, duration, dpt, slow_factor, tick_interval }`. The host calls it whenever `_player.apply_status` is called on a non-local player. Each peer applies the status locally (cosmetic tick-pulse + HUD icon). Duration is the remaining time at sync point — lag-safe.
- Player status removal is not synced (status expires locally by timer on each peer — the durations are short enough that drift is ≤1 frame; no RPC needed for expire).
- **DoD:** guest is within melee range of a Sunlit elite; guest's HP drains from burn; guest's HUD shows the burning pip. Verified by a co-op smoke test (extend `test_player_status.gd` P7 with a mock RPC or by manual play-test notes).
- See [[system-multiplayer-netcode]] for the RPC naming conventions and the host-authoritative model.
- **Effort: M**

### Phase 4 — Gate integration + registration point
Non-blocking but reduces regression risk.

- Promote `test_statuses.gd` and `test_player_status.gd` into the standard run documented in `CLAUDE.md` (add them alongside the existing four suites, or fold their assertions into `test_wyrd_loop.gd`).
- Extract status kind registration to a single `const STATUS_DEFS` dictionary in `status_effect.gd` (or a new `data/statuses.gd`): each entry holds `color`, `apply_text`, `word`, `particle_kind`, `particle_params`. `combatant.gd`, `player_controller.gd`, and `player_hud.gd` all read from there. Adding a seventh status kind then requires touching exactly one file.
- Verify the boss-bar "Unyielding" tag (boss.gd line 65 comment) actually renders in `boss_bar.gd` — fix if missing.
- **DoD:** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_statuses.gd` and `test_player_status.gd` both exit 0 and are cited in CLAUDE.md as part of the standard suite. A new dummy status "test_kind" added to `STATUS_DEFS` shows up in all three consumers without touching their source files.
- **Effort: S**

## Dependencies & links

- [[system-combatant-ai]] — the enemy AI tick and `_tick_statuses` share `_physics_process`; root and snared interrupt the AI state machine (lines 285–296 combatant.gd).
- [[system-bosses]] — boss immunity override (`apply_status` in boss.gd lines 69–74) is load-bearing; any new status kind must decide whether to add it to `IMMUNE_KINDS` or `REDUCED_DURATION`.
- [[system-elites]] — Briarbound (CC-immune window) and Sunlit (burn-pulse on attack) are the two elite modifiers that interact directly with the status framework.
- [[system-skills-hotbar]] — skills fire `SkillEffect` instances that land statuses on hit; the skill dispatcher in `player_controller.gd` is the call site.
- [[skill-bramble-snare]] — applies root via the `apply_root` alias (combatant.gd line 543); snare AoE is the only skill whose effect bypasses the `SkillEffect` data-driven pipe (calls `apply_root` directly).
- [[skill-hunters-mark]] — applies marked (8s) via `SkillEffect.marked`; marked is the only status with no tick and no slow — just the `MARKED_MULT` amplifier in `take_damage`.
- [[skill-power-shot]] — primary source of burn on enemies.
- [[skill-rain-of-thorns]] — secondary bleed source (2s / 0.5s ticks).
- [[system-hud]] — Phase 1 adds a status pip row to the HP orb in `player_hud.gd`; must use `_draw` (no `load()` inside `_draw` — see the white-texture memory note in CLAUDE.md).
- [[system-multiplayer-netcode]] — Phase 3 adds a `status_sync` RPC; must follow the host-authoritative pattern and avoid guest-authoritative damage.
- [[system-combat-juice-vfx]] — tick-pulse mesh flash reuses `HitFeedback.tick_pulse`; Phase 1 wires the player into the same call.
- Plan.md Part A §2 (combat-feel state table) and Part A Phase 1–5 (SHIPPED) cover all the hit-flash / tick-pulse / HitFeedback infrastructure this system rides on — do NOT re-plan those. Plan.md Part B is about the cozy-verb loop; status effects are orthogonal to it.

## Verification

- **Phase 1 (player visual parity):**
  - `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_player_status.gd` — extend with P5 (tick-pulse call count).
  - Screenshot: `WYRD_SHOT=1` while standing next to a Sunlit elite confirms the pip is visible.
  - Gate suites (`test_wyrd_loop.gd`, `test_wyrd_dungeon_scene.gd`, `test_wyrd_transitions.gd`, `test_skills.gd`) stay green.

- **Phase 2 (cleanse):**
  - Extend `test_player_status.gd` with P6: apply root → quaff `quickroot_tonic` → assert `not has_status("root")`.
  - `test_wyrd_loop.gd` already covers the tonic brew path (lines 384–387); no new loop test needed.

- **Phase 3 (multiplayer sync):**
  - Manual play-test: host + guest, guest near Sunlit elite, confirm guest HP drains.
  - Or headless mock: `test_player_status.gd` P7 instantiates two players, simulates host calling `apply_status` on the guest body, asserts guest has the status.

- **Phase 4 (gate + registration):**
  - `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_statuses.gd` exits 0.
  - `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_player_status.gd` exits 0.
  - Both are cited in CLAUDE.md.
  - Add a dummy kind to `STATUS_DEFS` → confirm all three consumers see it without touching their source; then revert.

All headless runs use `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path .`.

## Open questions

1. Should `marked` ever be applicable to the **player** (e.g., a boss that "marks the prey" for extra damage from its kin)? If yes, Phase 1 must also add a visual for it on the player side.
2. For Phase 2: should a `clearwater_philter` cleanse DoT statuses (burn/bleed) while `quickroot_tonic` cleanses movement statuses (root/snared)? The thematic split is clean but doubles the item surface.
3. Phase 4 registration point: a single `STATUS_DEFS` dict in `status_effect.gd` vs a dedicated `data/statuses.gd` autoload? The autoload form makes the palette available without a preload chain; the `status_effect.gd` form keeps it co-located with the data type.
