---
title: Mercy Shot
domain: Combat Skills
type: skill
status: partial
effort: M
tags: [wayfinder, plan]
---

# Mercy Shot

> The execute finisher is mechanically live but has no in-world cue that the threshold is crossed; the single biggest gap is a visual indicator on the enemy and a distinctive kill burst when Mercy Shot lands the finishing blow.

## Current state

The data layer is fully wired. `mercy_shot.gd` (`wyrd/scripts/skills/mercy_shot.gd:8-19`) sets `execute_mult = 3.0`, `execute_below = 0.35`, `cost = 28.0`, `base_cd = 5.0` in `_init()`, extending `ProjectileSkill`. The base class (`projectile_skill.gd:21-23, 74-77`) bakes both values onto every spawned arrow. The hit logic lives in `arrow.gd:201-203`: when `hp / hp_max < execute_below`, `dealt` is multiplied by `execute_mult` before `take_damage` is called. The level gate is registered in `game.gd:118` (`SKILL_REQS["MercyShot"] = 9`) and verified by `skill_unlocked()` at `game.gd:120-121`. Two headless tests cover it: `test_wyrd_loop.gd:169-182` checks that `execute_below == 0.35` and that the level gate opens at Wayfinding 9; `test_skills.gd:132-139` confirms the trio (HuntersMark / HeartwoodWard / MercyShot) becomes equippable. The hotbar shows a `✜` glyph and the tooltip reads "The clean kill — strikes 3× harder once the quarry staggers below 35% vigor." (`skill_bar.gd:50, 62`). The `even_breath` perk (`game.gd:456-457`) returns 6 Focus on every kill, so a Mercy Shot kill already triggers it.

**What is missing:** there is no in-world cue on the enemy that the execute threshold is active (no ring, no colour shift, no pulse), no distinct impact VFX when Mercy Shot delivers the finishing blow (it reuses the standard gold `_explode` burst), and no upgrade path for the skill's threshold or multiplier values.

## Gaps — what needs fleshing out

1. **[BLOCKER] Execute-threshold indicator on the enemy.** Nothing in `combatant.gd` changes appearance below 35% vigor. A player equipping Mercy Shot has no HUD feedback that the multiplier is live; it reads as a luck-based proc.
2. **Distinct kill-burst VFX for a Mercy Shot finishing blow.** `_kill_burst()` (`combatant.gd:1067`) fires on every death with the same warm-gold embers. A Mercy-executed kill should read differently — a cleaner, more emphatic pop aligned with the "clean kill" fantasy.
3. **Execute indicator readable in co-op.** In multiplayer (`net_game.gd`, `netd.active`) puppet combatants replicate HP but `combatant.gd:182-184` returns early on puppets. The indicator logic must live on data that is already synced (HP fraction) and fire purely on the local visual layer.
4. **Threshold and multiplier are magic constants.** `execute_below = 0.35` and `execute_mult = 3.0` live only in `mercy_shot.gd:15-16`; they are not exposed to `feel.gd` tunables (a Part B / Phase B0 responsibility). Tuning currently requires editing the class.
5. **No mastery-tree upgrade path.** The existing perk ladder (`game.gd:419-458`) has no Mercy Shot–specific upgrades (e.g., widen the threshold to 40%, reduce focus cost). `PERKS` uses a flat pick-one model that `game.gd:417-418` explicitly labels as "planned refinement."
6. **Icon missing.** `skill_bar.gd:44-51` shows a `✜` glyph fallback; no entry in `SKILL_ICON` for `MercyShot`. Needs a painted icon to match the four that already have one (BasicShot, PowerShot, MultiShot, BrambleSnare).

## Plan

### Phase 1 — Execute-threshold visual (blocker; do first)

- In `combatant.gd`, add a method `_update_execute_ring(hp_frac: float)` that creates or destroys a thin pulsing ground-ring under the enemy when `hp_frac < 0.35`. Follow the torus recipe from `_death_burst()` (`combatant.gd:1039-1056`): a `TorusMesh` at `y ≈ 0.05`, colour warm amber `Color(1.0, 0.65, 0.1, 0.6)`, scale ~0.6 of the character's footprint, pulsing via a looped `Tween` on `albedo_color:a` between 0.45 and 0.75 over 0.8 s. Call `_update_execute_ring(float(hp) / float(hp_max))` at the end of `take_damage` (after `hp -= dmg`).
- Guard so the ring only spawns once: store it as `_execute_ring: Node3D = null`; skip creation if already valid.
- Puppet combatants must also show it: the ring reads purely from `hp / hp_max`, which is snapshot-replicated. Call `_update_execute_ring` from the snapshot-apply path in `combatant.gd` so guests see the indicator without a separate RPC.
- Constant `EXECUTE_RING_BELOW := 0.35` co-located with the `TELEGRAPH_SEC` constants block (`combatant.gd:41`). This decouples the visual from the `mercy_shot.gd` scalar; update both if the design threshold moves.
- **DoD:** fire a dev run; any enemy drops below 35% HP and the amber ring appears; rises back above (e.g. after HeartwoodWard absorbs a hit via player-side logic if ever relevant) or on death, ring disappears. Verify `_execute_ring` does NOT appear on enemies that never drop below 35%.
- **Effort:** S

### Phase 2 — Distinct Mercy Shot kill-burst

- When `arrow.gd` fires the execute branch (`arrow.gd:201-203`) AND the hit kills the target (`c.hp - dealt <= 0`), set a flag `_was_execute_kill = true` on the arrow before calling `take_damage`. This requires peeking at `c.hp` before the call — safe because `take_damage` is synchronous.
- After `take_damage`, if `_was_execute_kill` and `c.dead`, spawn a secondary "clean kill" burst at `global_position`: a tight upward spray of silver-white particles (contrast with the warm-gold standard kill-burst) plus a thin sharp ring that expands fast (0.15 s) and disappears (like PowerShot's ring in `arrow.gd:343-349` but smaller, silver, `Color(0.85, 0.92, 1.0, 0.7)`). 20-25 particles, lifetime 0.5 s, spread 40°, upward bias.
- Play `sfx_key = "skill_power"` (already set in `mercy_shot.gd:18`) — distinct audio from the basic arrow pop.
- Keep the standard `_kill_burst()` suppression: if `last_hit_peer` skill type is "mercy", `combatant._kill_burst()` is skipped and the arrow's burst substitutes. Alternatively (simpler) layer both and accept the slight visual stack. Start with layering — revisit if it reads as noisy.
- **DoD:** in a dev run, land a killing Mercy Shot on a sub-35% enemy; the burst is visually brighter/cooler than a standard kill; the normal BasicShot kill still shows the warm-gold burst. Screenshot comparison is the gate.
- **Effort:** S

### Phase 3 — feel.gd tunables (Part B dependency)

This phase is owned by Plan.md Part B / Phase B0 (`feel.gd` tunables). Mercy Shot's `execute_below` (0.35) and `execute_mult` (3.0) should be registered as named constants in `feel.gd` once that file exists, and `mercy_shot.gd` should reference them instead of hard-coding. No standalone work warranted here until B0 lands.

- **DoD:** `feel.gd` exports `EXECUTE_BELOW := 0.35` and `EXECUTE_MULT := 3.0`; `mercy_shot.gd` reads them; tweaking `feel.gd` adjusts both the arrow behaviour and the Phase 1 ring without editing two files.
- **Effort:** S (dependent on Plan.md B0)

### Phase 4 — Mastery-tree upgrade path (expansion)

The perk ladder (`game.gd:419-458`) currently has no Mercy Shot entries. Two candidates that fit the "cozy skilling spine" design (ADR 0003) — unlocked by gather/craft/chart XP, not kills:

- `"mercy_reach"` at lv 11 — "The huntsman's patience opens the window wider — execute below 40% vigor instead of 35%." (`execute_below` → 0.40 in `mercy_shot.gd` when perk active; or a multiplier checked in `arrow.gd`).
- `"steady_release"` at lv 15 — "A calm breath before the draw — Mercy Shot's focus cost drops to 20." (`cost` reduction in a derived-stats-aware check, same pattern as `Skill.effective_cd`).

Implementation: add both entries to `PERKS["wayfinding"]` in `game.gd`. `arrow.gd`'s execute check queries the arrow's `owner_peer` against the game autoload's perk state, or the player pre-bakes the effective threshold onto the arrow before `add_child` (cleaner, matches how `crit_chance` is baked at `projectile_skill.gd:70`).

- **DoD:** set lv 11, fire a Mercy Shot at a dummy at 37% HP — the execute triple fires. Set lv < 11 — same shot deals normal damage. Headless test: extend `test_wyrd_loop.gd` with a perk-active branch.
- **Effort:** M

### Phase 5 — Painted icon (polish)

Add `"MercyShot": "res://assets/ui/icons/skill_mercy.png"` to `SKILL_ICON` in `skill_bar.gd:36-40` once the icon exists. Commission via the icon-gen workflow (see `/icon-gen` skill). Glyph fallback stays in place until the asset lands; no logic changes required.

- **DoD:** hotbar slot shows the painted icon with no white-rect artefact (preload check per `check_ninepatch.py` convention).
- **Effort:** S

## Dependencies & links

- [[system-skills-hotbar]] — the dispatch path (`_try_skill`), level gating (`SKILL_REQS`), and hotbar tooltip for Mercy Shot all live here; any icon or tooltip update must be tested through this system.
- [[skill-hunters-mark]] — the natural pre-execute combo: mark the target (lv 4), whittle to 35%, close with Mercy Shot (lv 9). Phase 4 upgrade tuning should treat the combined mark+execute burst as the expected peak-damage window.
- [[skill-heartwood-ward]] — lv 7 defensive skill unlocked between Hunter's Mark and Mercy Shot; they form the lv 7-9 gated bloc. Ensure the execute-ring indicator (Phase 1) does not fire while Heartwood Ward's absorb shield is absorbing — i.e., true HP fraction, not displayed HP, drives the ring.
- [[system-combatant-ai]] — `combatant.gd` is where both the execute check (arrow hits) and the ring indicator (Phase 1) land; Phase 2's burst fires from `arrow.gd` but reads combatant state.
- [[system-combat-juice-vfx]] — the kill-burst pattern (`_kill_burst`, `_spawn_power_aoe_burst`) and the tween-ring recipe (`_death_burst`) are the templates for Phase 1 and Phase 2 VFX; reuse, don't rebuild.
- [[system-status-effects]] — `even_breath` perk already integrates with `_die()` to return 6 Focus on any kill; a Mercy Shot kill triggers it automatically. Future Phase 4 perk work should confirm it still fires via the same path.
- [[system-trades-progression]] — Wayfinding level gates (`SKILL_REQS`, `skill_unlocked`) and the perk ladder (`PERKS["wayfinding"]`) are the unlock mechanism; Phase 4 adds two new perk entries here.
- [[system-hud]] — Phase 1's execute ring is a world-space indicator on the enemy, not a HUD element; but if a screen-edge cue ("execute ready") is ever desired, it lands in the HUD system.
- Plan.md Part A (combat feel, SHIPPED) provides the animation toolkit reused by Phase 2 (burst timing, hitstop floor, camera shake). Part B / Phase B0 is a prerequisite for Phase 3 (feel.gd constants).

## Verification

**Phase 1** — `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` must stay green. Then a live run: spawn a weak enemy, deal damage until HP drops to ~34%, confirm the amber ring appears; kill it, confirm ring is gone. Screenshot the ring in place.

**Phase 2** — Live run only: land a Mercy Shot kill at < 35% HP. Screenshot the silver-white burst. Confirm a BasicShot kill on the same enemy type shows the warm-gold burst only.

**Phase 3** — After B0 lands: `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` still green. Manually verify `feel.EXECUTE_BELOW` resolves without error in --headless.

**Phase 4** — Extend `test_wyrd_loop.gd`'s skill-gating section: set lv 11, fire Mercy Shot at an enemy with 37% HP (mock `hp/hp_max`), assert `dealt == dmg * 3`. Set lv 10, assert `dealt == dmg * 1`. All four headless suites stay green (`cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`, same for `test_skills.gd`).

**Phase 5** — `wyrd/tools/check_ninepatch.py` passes on `skill_mercy.png`. Hot-reload the game, confirm the hotbar icon renders with correct colour (not white rect).

## Open questions

1. **Threshold symmetry:** `execute_below = 0.35` was chosen for Mercy Shot. Should the Phase 1 ring fire at the same value, or slightly earlier (e.g. 0.40) to give the player a "you're getting close" window before the multiplier is actually live? Design call.
2. **Ring on bosses:** bosses have much larger HP pools. The ring at 35% on a boss lasts much longer. Should the ring pulse faster on bosses to read as "this is a multi-phase execute window" rather than looking the same as a trash enemy?
3. **Layered vs. exclusive kill burst (Phase 2):** the simple path layers the standard warm-gold `_kill_burst` plus the silver Mercy Shot burst. If playtests find it noisy, suppress `_kill_burst` for Mercy Shot kills. Defer the decision until Phase 2 is built.
