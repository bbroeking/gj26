---
title: Multi Shot
domain: Combat Skills
type: skill
status: complete
effort: M
tags: [wayfinder, plan]
---

# Multi Shot

> Fully-shipped fan-of-three (±20°, 0.5×, Snare, 25 Focus, 2.0s CD) — expansion roadmap covers spread-count upgrades, a 5-arrow mastery variant, balance tuning, and a dedicated SFX asset.

## Current state

`multi_shot.gd` is a 99-line concrete subclass of `ProjectileSkill` (`wyrd/scripts/skills/multi_shot.gd`). `_init()` (line 23) sets all data fields: `cost = 25.0`, `base_cd = 2.0`, `damage_mult = 0.5`, `projectile_count = 3`, `spread_deg = 40.0`, `on_hit_effects = [SkillEffect.snared(1.5, 0.5)]`, `recoil_amount = -0.45`, `bow_pop_mult = 1.20`, `sfx_key = "skill_multi"`. The spread math lives in `ProjectileSkill.fire()` (projectile_skill.gd:47–53): arrows fan symmetrically over `spread_deg`, the center arrow is marked `focal = true` (full brightness), outer arrows are non-focal (dimmer, desaturated) per Spec-34 cookbook. `fire()` override (multi_shot.gd:36–49) calls `super.fire()` then spawns a GPU fan-burst of 14 gold particles (`FAN_BURST_AMOUNT`, line 18) with spread matching the arrow cone (line 62), anchoring the three arrows as a single visual ability. The Snare effect (1.5s, 50% slow, no DoT) is carried by all three arrows via `arrow.effects`. `skill_multi` SFX key is registered; capture/GIF exists (`docs/skills/captures/multishot.gif`). `test_skills.gd` verifies dispatch: Focus deduction, cooldown seeding, and the loadout-swap regression gate. Status is **complete** — the core ability works and is gate-green.

## Gaps — what needs fleshing out

1. **`sfx_key = "skill_multi"` has no dedicated audio asset** — if `Sfx` falls back to the basic-shot sound or is silent, the fan reads weaker than it should. Verify whether `skill_multi` is wired in `audio/` or is a silent stub; generate a layered 3-arrow-release SFX via `tools/generate_audio.py` if missing.
2. **No spread-count upgrade path** — `projectile_count` and `spread_deg` are plain fields set once in `_init()`; no mechanism exists to widen to 5 arrows at higher Wayfinding levels or via a chart affix. The spec-32b notes (line 25–26) explicitly flag "Skill variants / runes" as a planned D3-model feature.
3. **Arrow count / spread not exposed to chart affixes** — `data/affixes.gd` has no entry for `multi_spread` or `multi_count`; a "Scattering" good-affix (wider cone or 5 arrows) doesn't yet exist.
4. **Damage balance is unverified at scale** — 3 × 0.5× = 1.5× total on a 2.0s CD sits between BasicShot and PowerShot; no DPS spreadsheet or playtest note confirms the trade-off holds at depth 3+ where elites have boosted HP.
5. **No `data/skills.gd` registry** — `player_controller.gd` still carries an orphaned `const MultiShotScript` preload (line 30), noted as a followup in spec-32b notes. A factory (`class_loadout`) for configurable loadouts is also missing.
6. **Fan-burst particle size was hand-bumped 3×** (`qmesh.size = Vector2(1.05, 1.05)`, line 79, comment says "3x bumped from 0.35") without a named `feel.gd` constant — the value is a magic number not in the central tuning block that Plan.md Part B / Phase B0 wants to establish.

## Plan

### Phase 1 — Audio & magic-number cleanup (polish)
*Unblocked; standalone; lowest risk.*

- Confirm whether `skill_multi` is a live SFX or silent stub in `audio/`; if silent, run `tools/generate_audio.py` to generate a 3-arrow release burst (layered `pfft-pfft-pfft`, short, 0.10–0.15s) and register under `skill_multi` in `Sfx`.
- Move `FAN_BURST_AMOUNT`, `FAN_BURST_LIFETIME`, `FAN_BURST_SPEED_MIN/MAX`, and `qmesh.size` into `data/feel.gd` (the `Feel.MULTI_*` block) once Part B / Phase B0 lands. Until then annotate the constants with `# feel.gd candidate`.
- Remove the orphaned `const MultiShotScript` from `player_controller.gd` (spec-32b followup, line 30 of player_controller.gd).
- **DoD:** `skill_multi` plays a distinct 3-arrow release; `FAN_BURST_*` constants carry `# feel.gd candidate`; orphaned const removed; all 5 suites green (`WYRD_NO_SAVE=1 cd wyrd`).
- **Effort: S**

### Phase 2 — Spread-count upgrade support (expansion)
*Depends on Phase 1 cleanup; pairs with `data/skills.gd` registry spec-32b followup.*

- Add `var spread_upgrade: int = 0` to `ProjectileSkill` (or `MultiShot` only if the upgrade is exclusive). At `spread_upgrade = 1` → `projectile_count = 5`, `spread_deg = 60.0`; `fire()` already handles any count symmetrically (projectile_skill.gd:47–53) — no logic change needed.
- Wire the upgrade into the Wayfinding perk ladder (`game.gd PERKS`): add a `multi_spread` perk at lv 13–14 (between `rich_seams` and `heavy_draw`) that calls `player.skills[slot].spread_upgrade = 1` on perk activation. OR expose it as a chart affix (see Phase 3).
- Update `FAN_BURST_AMOUNT` to scale with `projectile_count` (e.g., `4 + projectile_count * 3`) so the visual burst matches the wider fan at 5 arrows.
- **DoD:** at Wayfinding lv 13+, Multi Shot fires 5 arrows in a 60° cone; the fan-burst particle count scales; `test_skills.gd` still passes (add a test asserting `projectile_count == 5` after perk activation); headless gate green.
- **Effort: M**

### Phase 3 — Chart affix integration (expansion)
*Depends on Phase 2; pairs with `system-chart-affixes` / `data/affixes.gd`.*

- Add a `"Scattering"` good-affix pair to `data/affixes.gd`:
  - Good twin `"wide_fan"`: `{mult: 1.0, tag: "multi_count+1"}` — widens the cone by one extra arrow on Multi Shot (stacks with Phase 2 perk for up to 6–7 arrows at deep charts).
  - Bad twin `"tight_nock"`: `{mult: 1.0, tag: "multi_count-1"}` — reduces to 2 arrows (narrower, less pack-clear; intended for single-target compositions).
- In `player_controller.gd` or the buff pipeline, consume `multi_count+/-` tags during dungeon entry to set `MultiShot.projectile_count` and `spread_deg` for the run.
- **DoD:** entering a chart with the `wide_fan` affix fires 4 arrows (or 6 with the Phase 2 perk); `tight_nock` fires 2; both revert on exit to the base or perk-leveled value; no test_skills regression.
- **Effort: M**

### Phase 4 — Balance audit & DPS benchmarking (polish)
*Can run in parallel with Phase 3; no code blocker.*

- Document the intended DPS curve in a comment block at the top of `multi_shot.gd`: 3 × 0.5× dmg × (1/2.0s) = 0.75 DPS-multiplier before Snare; compare to PowerShot (1.4× / 2.8s ≈ 0.50) and BasicShot (1.0× / fire_cooldown). Confirm Multi Shot is the fastest pack-clear tool, not a single-target upgrade, as the file comment (line 4–8) intends.
- Playtest Snare duration (1.5s, 50% slow) against the Briarbound elite's 4.0s CC-immunity window — a Briarbound hit once is immune for 4s, making Multi Shot's Snare irrelevant for the follow-up two arrows. Decide: leave as-is (skill interaction, intentional), or give Multi Shot a shorter Snare that resets the window more gracefully.
- If total damage per CD feels too low at depth 3+, consider raising `damage_mult` to 0.55–0.6 (total 1.65–1.8×) — a 10–20% buff that preserves the single-target inferiority to [[skill-power-shot]].
- **DoD:** a comment block in `multi_shot.gd` documents the DPS math and the Briarbound interaction decision; any balance change is covered by an `_check` in `test_skills.gd` that asserts the expected damage output.
- **Effort: S**

## Dependencies & links

- [[skill-basic-shot]] — slot 1, always equipped; Multi Shot's pack-clear role is only meaningful because Basic Shot handles the single-target fallback on slot 1.
- [[skill-power-shot]] — the single-target counterweight; balance anchor for damage_mult decisions in Phase 4.
- [[skill-bramble-snare]] — Snare status is shared; `SkillEffect.snared()` factory (skill_effect.gd:32) is the same static constructor Multi Shot uses.
- [[skill-piercing-bolt]] — corridor skill; spec comment in piercing_bolt.gd calls it "the counterweight to MultiShot's fan" — balance these two as a pair.
- [[system-skills-hotbar]] — loadout slots, `SKILL_POOL`, `set_loadout`, `rebuild_skills`, and the Phase 2 perk-ladder plumbing all live here.
- [[system-status-effects]] — Snare duration / slow-factor / stacking rules; Briarbound CC-immunity interaction from Phase 4 is resolved here.
- [[system-combatant-ai]] — Briarbound elite's `_cc_immune_until` field (combatant.gd) determines how Snare interacts with the most Snare-resistant enemy type.
- [[system-chart-affixes]] — Phase 3 `wide_fan` / `tight_nock` affix pair lands here; see `data/affixes.gd`.
- [[system-trades-progression]] — Phase 2 perk (`multi_spread` at lv 13) plugs into the Wayfinding perk ladder in `game.gd PERKS`.
- [[system-combat-juice-vfx]] — fan-burst particle tuning (Phase 1); `feel.gd` migration (Plan.md Part B / Phase B0) owns the constant extraction.
- **Plan.md Part A** — fully shipped; Multi Shot's recoil, bow-pop, and focal/non-focal arrow VFX all rely on the animation toolkit built in Phases 1–5. No re-planning needed.
- **Plan.md Part B / Phase B0** — `feel.gd` tunables block; Phase 1 above defers the magic-number extraction until B0 lands.

## Verification

- **Phase 1:** run `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_skills.gd` — all 7 asserts pass. Confirm `skill_multi` SFX plays by launching the game (`godot --path wyrd`) and firing Multi Shot; a distinct layered sound should play (not the basic-shot click).
- **Phase 2:** add to `test_skills.gd`: after setting `game.trades["wayfinding"]["lv"] = 14` and calling `game.perk_active("wayfinding", "multi_spread")`, assert `p.skills[1].projectile_count == 5` and `p.skills[1].spread_deg == 60.0`. All 5 headless suites must stay green.
- **Phase 3:** add a chart-entry integration test (extend `test_wyrd_dungeon_scene.gd` or a new `test_chart_affixes.gd`): start a chart with `wide_fan` affix, assert `player.skills[1].projectile_count == 4`; exit chart, assert revert to base count.
- **Phase 4:** visual playtest (fire Multi Shot at a 3-enemy pack, confirm Snare lands on all three and they slow visibly); add a `_check` in `test_skills.gd` asserting `p.skills[1].damage_mult * 3 == expected_total` after any damage_mult change.

## Open questions

1. **Perk ladder vs chart affix for spread-count unlock** — Phase 2 proposes a Wayfinding perk; Phase 3 proposes a chart affix. Both can coexist, but does a permanent +2-arrow perk make the bad-affix `tight_nock` feel punishing or trivial? Decide which vector (permanent vs per-run) carries the upgrade before implementing Phase 2.
2. **Snare on all 3 arrows vs only the center** — currently all three arrows carry the same `on_hit_effects` (projectile_skill.gd:73). Against a single boss, all three arrows can Snare the same target: the status refreshes three times per cast. Is that intended (reliable Snare application) or should outer arrows carry no Snare effect (center only = more skillful aim required)?
3. **5-arrow count cap** — at Phase 2 + Phase 3 wide_fan stacked, the player could reach 6–7 arrows. Set an explicit `MAX_PROJECTILE_COUNT` constant or cap at 5 in the upgrade logic?
