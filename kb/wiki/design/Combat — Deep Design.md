---
type: design
tags: [system-design, combat]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/systems/Combat.md"
  - "kb/wiki/systems/Camera and Game Feel.md"
  - "kb/wiki/entities/Skills.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "wyrd/scripts/player_controller.gd"
  - "wyrd/scripts/combatant.gd"
  - "wyrd/scripts/boss.gd"
  - "wyrd/scripts/boss_bar.gd"
  - "kb/wiki/games/soulslike/Sekiro Shadows Die Twice.md"
  - "kb/wiki/games/soulslike/Hollow Knight.md"
  - "kb/wiki/games/soulslike/Dark Souls.md"
  - "kb/wiki/games/soulslike/Bloodborne.md"
  - "kb/wiki/games/arpg/Hades.md"
  - "kb/wiki/games/co-op/Monster Hunter World.md"
---

# Combat — Deep Design

> Forward-looking deep design. Current-state: [[Combat]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are a Wayfinder with **one verb** — the bow — and you get *better at the bow* by learning to **read what's in front of you**, never by buying a bigger bow. Combat is seasoning, not the meal (ADR 0003). Every combat piece passes the **spine test** ([[Combat]]): would a player do this with no quest pointing at it? The demo's entire combat ambition is to lift the seven-pillar feel score ([[Camera and Game Feel]]: avg ~6/10) into a clean reading-and-response loop and **nothing more** — per P8/P9, the brevity of this doc is itself a spine-protection signal. No King of Brambles, no new weapon class, no new gear tier — ever.

## What ships today (grounded in code)

The bow loop is **whole but thin**, and well-built:

- **Locomotion + i-frames** — `player_controller.gd`: `enum Move { NORMAL, DASH, ROLL }`; `ROLL_IFRAMES = 0.27` (60% of `ROLL_TIME = 0.45`, a punishable tail); recovery-cancel in the last 30% of a burst; `_soft_aim()` cone assist (`AIM_ASSIST_CONE = 28°`, `AIM_ASSIST_BLEND = 0.7`). Dash has **no** i-frames (reposition, not survival).
- **Focus + hotbar** — `FOCUS_MAX = 50`, regen `10/s` out of combat vs `3/s` in (`COMBAT_TIMER = 3.0`); `_try_skill(slot)` dispatches the four [[Skills]]; slot 1 (BasicShot) is free; insufficient Focus is a silent no-op (D3 model).
- **Hit feedback (juice)** — `combatant.gd` + `HitFeedback.play_hit`: six channels; crit (×2, `CRIT_CHANCE 0.20`) / super-crit (×3, `SUPER_CRIT_CHANCE 0.04`); `HITSTOP_SEC = 0.09`; mesh flash, knockback, `shake()`, scatter damage numbers. Bleed-on-crit auto-applies (`BLEED_TICK_FRACTION 0.0625`).
- **Status framework** — `_statuses` Dictionary, highest-wins + duration-refresh; burn/bleed/snared/root/marked; bosses immune to root/snared, burn/bleed at 50% (`boss.gd` `IMMUNE_KINDS`, `REDUCED_DURATION`).
- **Boss phase machine** — `boss.gd`: HP-gated phases (`PHASE2_FRAC 0.66`, `PHASE3_FRAC 0.33`), telegraphed `sweep`/`stomp`/`charge`/`lunge` per-kind (`hedgemother`/`burrow_boar`/`wolf_alpha`), `reset_fight()` on player death, `_phase_telegraph()` shrinking the wind-up by phase.

**What's missing** (the demo's exact job, P9): bosses have **no Poise** (pure HP-race), death has no flourish, the boss HP bar (`boss_bar.gd`, a `WyrdUi.make_meter`) has no ghost-trail, and the Hedgemother's authored thorn-arena + phase-3 hedge-sprite summon (spec-05) are unbuilt.

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

The demo adds **exactly four things** — three pure-feel, one reading mechanic.

1. **Stagger threshold (feel).** A hit where `dmg >= STAGGER_FRAC * hp_max` (≈ `0.25`; a super-crit or PowerShot-sized blow) **interrupts a non-boss enemy's `ATTACK` telegraph** and plays a sharper recoil. Gates off the existing `_telegraph_t`/`_react_t` machinery in `combatant.gd` — near-zero cost. This is the Hollow-Knight lesson applied honestly: no parry, **positioning-first** — the player creates the stagger by *out-aiming a wind-up*, not by twitch-timing a deflect.
2. **Death-flourish (feel).** On `_die()`, the planned 0.12s extended hitstop + larger spark burst + brief FOV nudge ([[Camera and Game Feel]], "Death flourish (planned)"). Replaces the current bare sink-and-shrink tween with a weighty crumple.
3. **HP-ghost-trail (feel).** A lagging white "ghost" drains to the real value over ~`0.4s` behind the boss HP fill, so a big chunk *reads* as taken — closes feel-pillar 3 (damage readability). UI-only, attaches to `boss_bar.gd`'s meter + the enemy HUD.
4. **Poise / stance-break — the ONE reading mechanic.** A **per-boss Poise meter, separate from HP**, taken from Sekiro's Posture but **inverted for a ranged one-verb game.** In Sekiro you fill enemy Posture by *deflecting melee*; we have no melee and no parry, so the Wayfinder fills Poise by **landing shots into the boss's vulnerable windows** — post-telegraph recovery, a whiffed charge, the tail of a lunge chain. Poise gained outside a window is heavily discounted, so the mechanic *teaches the player to read the boss's rhythm*. At full Poise the boss enters **Reeling** (~3s): it staggers to its knees, telegraphs are suppressed, it takes amplified damage, and a **Wayfinder's Mark** finisher prompt appears — a charged shot dealing a large flat bonus **and** resetting all skill cooldowns + refunding Focus, so the player empties their kit into the opening. This is the skill-expression that replaces hard CC (bosses are root/snare-immune). **Poise is the only reading mechanic in the demo — Rally is NOT built (Horizon).**

Plus the two **shipped boss gimmicks get implemented** (Phase 0 + Pillar One): the Hedgemother's **thorn-arena** (brambles grow over the exits; a few BasicShots cut a gap) + phase-3 hedge-sprite summon (spec-05), and the **Burrow Boar's tusk-quake** phase in the Pale Veins.

### Data model & formulas (GDScript-flavored)

Poise lives on `boss.gd` **only** — trash mobs use stagger, not Poise — keeping the cost off the common `combatant.gd` path.

```gdscript
# boss.gd additions
var poise: float = 0.0
var poise_max: float = POISE_MAX        # per-kind (table below)
var _reeling_t: float = 0.0
const POISE_DECAY := 6.0                 # /sec, only while no window is open
const REEL_TIME := 3.0
const VULN_MULT := 2.5                   # poise multiplier inside a window
const NONVULN_MULT := 0.4                # poise multiplier outside a window
const REEL_DMG_MULT := 1.5               # damage taken while Reeling
signal reeling_started()
signal reeling_ended()
```

| Term | Rule |
|---|---|
| Vulnerable window | `not _charging and not _telegraphing and _atk_cd > 0.6` (post-attack recovery), OR the frame a `charge`/`lunge` ends with `_charge_hit == false` (a whiff) |
| Poise on hit | in `take_damage`: `poise += dmg * (VULN_MULT if _in_window() else NONVULN_MULT)`; **direct hits only** — DoT ticks (`_apply_tick_damage`) never fill Poise |
| Decay | `if not reeling and not _in_window(): poise = max(0, poise - POISE_DECAY*delta)` |
| Stance-break | `poise >= poise_max` → `_reeling_t = REEL_TIME`; `reeling_started.emit()` |
| Reeling | AI frozen (skip `_tick_ai` body), `take_damage` scaled by `REEL_DMG_MULT`, telegraphs cancelled, Mark prompt shown |
| Finisher | flat `MARK_BONUS` dmg + `player.reset_all_cooldowns()` + `player.refund_focus()` |
| Reset | on Reeling end and in `reset_fight()`: `poise = 0` |

| Boss | `poise_max` | Vulnerable shape | Tuning intent |
|---|---|---|---|
| Hedgemother | 70 | long sweep recovery | breaks ≈ once/phase if recovery is read |
| Burrow Boar | 90 | the **missed charge** (huge window) | rewards sidestepping over tanking |
| Wolf Alpha *(Horizon)* | 60 | end-of-lunge-chain | faster, smaller windows |

Damage stays the cozy subtractive curve ([[Balance Philosophy]]): `dmg = max(1, atk - def + jitter)`; boss TTK 30–60s. Poise is tuned so a *reading* player breaks ~once per phase (shaving ~20% of TTK), and a Focus-on-cooldown spammer never breaks. **Poise is upside-only — never a wall.**

### Content to author (tiers / tables / worked examples)

- **Per-boss Poise block** (the 3-row table) — a small data table validated by the balance-sim **on demand** (P10), never a commit gate.
- **Worked example — Boar (Pale Veins):** player kites; Boar telegraphs a charge; player sidesteps; the charge whiffs into a vein wall → vulnerable frame → 3 PowerShots into the recovery fill Poise to 90 → Reeling → Wayfinder's Mark dumps PowerShot + MultiShot + RainOfThorns into the kneeling Boar. Reads as *"I outsmarted the charge,"* not *"I out-DPS'd it."*
- **Hedgemother thorn-arena:** bramble tiles grow over exits across phases (reuse `AoeQuery.query_circle` + the `_make_telegraph` decal pattern); a few BasicShots cut a gap. Diegetic, on-theme, no new tech.
- **VFX/audio:** a thin Poise sub-bar under the boss HP banner (`WyrdUi.make_meter`, ninepatch-clean); a stance-break crack SFX; one Reeling "kneel" pose (a single Meshy boss clip — custom clips are boss-only, P5); a Mark finisher flash + sting (per the §6 per-pillar audio bed).

### Edge cases, failure modes, anti-frustration

- **Poise must never gate progress.** A player who ignores it still wins on HP; never lock a phase or the kill behind a break.
- **Cozy guardrails hold ([[Balance Philosophy]]):** no one-shot below 50% HP, auto-flee at ~25%, retreat always allowed. A Reeling boss is frozen, so the damage-amp can never let it one-shot the player on the way down.
- **Reeling-into-death:** if the Mark would kill, route straight to the death-flourish — no awkward stand-up.
- **Decay (`POISE_DECAY`)** stops a player banking Poise across a whole fight by tickling whiff frames; it rewards *clustered* reads. Decay pauses whenever a window IS open, so an honest read is never punished by the clock.
- **Status interaction:** `marked` (×1.3) amplifies Poise gain naturally via larger hits — good. Burn/bleed DoT deliberately does **not** fill Poise (it isn't a read).
- **Stagger vs. elites:** elites (`apply_elite`) are still staggerable; Briarbound's CC-immunity is unrelated (stagger isn't a status).

## Interlocks — how this feeds/uses other systems

- **[[Skills]] / Focus** — the Mark's cooldown-reset + Focus-refund is the payoff that makes carrying a full 4-skill loadout matter. **Loadout opportunity cost is the only build depth** (P8); the charm-notch re-cost ([[Hollow Knight]]) stays Horizon.
- **[[Huntcraft]]** — every kill still pays `max(2, hp_max/3)` XP (`combatant._die()`, ADR 0005). A stance-broken boss dies *faster*, not for *more* XP — Poise carries **zero raw-power creep**.
- **[[Chart Loop]] / [[Affixes]]** — `cooldown_reduction`/`quiver`/`echoing` already shape combat per-run (Hades-style run-authored difficulty); Poise reads the same boss the chart's biome themed.
- **[[Bosses]]** — Poise rides the existing `boss.gd` phase machine and the shipped trophy chain (Hedgemother → Boar → Wolf → Summit). The **trophy ritual** (raw trophy → Ledger charm at home via the existing inscription mechanic) is the one itemization verb — flat, capped, horizontal ([[Universe Build-Out Plan]] §4.5).
- **[[Multiplayer Co-op]]** — **co-op readability is a correctness requirement** (P9/§6), not polish: Poise, the Reeling state, and boss telegraphs RPC to all peers so every screen reads the same window. Host-authoritative: only the host simulates Poise; the Mark prompt shows for whoever lands the breaking shot. This is the [[Monster Hunter World]] lesson — shared, legible boss state is what makes co-op choreography work.
- **[[Camera and Game Feel]]** — stagger/flourish/ghost-trail directly raise feel-pillars 3 (readability), 4 (power fantasy), 7 (world response); the FOV nudge rides the existing `shake()` rig.

## Demo scope vs Horizon

**DEMO (built now — P9):**
- Stagger threshold · death-flourish · HP-ghost-trail (pure feel).
- Poise / stance-break + Reeling + Wayfinder's Mark finisher — **the one reading mechanic.**
- Hedgemother thorn-arena + phase-3 summon; Boar tusk-quake.
- Co-op telegraph/Poise RPC (correctness).
- Trophy-ritual Ledger charm (the one itemization verb).

**HORIZON (named, NOT built — protects ADR 0003, the P7 cut-line):** Rally (HK-style come-back resource), charm-notch loadout re-cost, named cross-skill synergies, behavior affixes, living-pack rival AI, Hearth-ember / Waystone Vigil revives, Sekiro-style run-scoped resurrection-with-cost, item-skill modifiers. The plan picks **Poise OR Rally — it picks Poise.** Each is a real ARPG workstream and ships only after the spine is proven (P7), never alongside it.

## Implementation notes (Godot)

- **`wyrd/scripts/boss.gd`** — Poise vars + `_in_window()` predicate (reuse `_telegraphing`/`_charging`/`_atk_cd`/`_charge_hit`), `_reeling_t`, `reeling_started`/`reeling_ended` signals, the Reeling branch in `_tick_ai`, the Poise add in `take_damage`, thorn-arena + tusk-quake; clear Poise in `reset_fight()`.
- **`wyrd/scripts/combatant.gd`** — stagger threshold off `take_damage` (interrupt the `ATTACK` telegraph). **Do not** add Poise here — boss-only.
- **`wyrd/scripts/player_controller.gd`** — `reset_all_cooldowns()` + `refund_focus()` for the Mark; the finisher is a special BasicShot variant (no new weapon). Auto-aim via the existing `_soft_aim`.
- **`wyrd/scripts/boss_bar.gd` + enemy HUD** — ghost-trail + the Poise sub-bar (both via `WyrdUi.make_meter`/`set_meter`, ninepatch-clean per §6); death-flourish in `combatant._die()` and `player_controller._die()`.
- **Co-op:** Poise/Reeling/telegraph RPCs in `net_game.gd` (Phase C).
- **Guarding tests (the four headless suites stay green per commit):** `test_skills.gd` (hotbar dispatch — the frozen-hotbar canary; must catch a dead finisher keypress), `test_wyrd_dungeon_scene.gd` (boss scene boots + a Poise→Reeling transition), `test_wyrd_loop.gd` (no-arbitrage economy gate). The richer hit-feedback evals in `test_combat.gd`/`test_statuses.gd` remain useful but are not the hard gate; the **balance-sim is a script run on demand**, never a gate (P10).

## Open questions

- Mark finisher: auto-aimed (cozy) or skill-shot (tense)? Lean auto-aim with `_soft_aim` for the cozy contract.
- Does Poise decay pause only during Reeling, or whenever no window is open? Probably pause whenever a window is open (honest read never punished by the clock).
- Co-op: one shared Poise bar, or per-player window contributions? Shared, host-authoritative — simplest and most legible.
- Do trophy boons (knockback-resist / +1 dodge i-frame / full-duration bleed) touch Poise tuning? They must stay horizontal and balance-sim-checked for zero raw-damage creep.
- Should stagger also apply to the player (enemy stagger-on-heavy-hit)? Almost certainly not — that pushes toward Souls difficulty and breaks the cozy contract; flagged as a deliberate non-feature.

## See also / Sources

- [[Combat]] · [[Skills]] · [[Bosses]] · [[Camera and Game Feel]] · [[Huntcraft]] · [[Chart Loop]] · [[Affixes]] · [[Multiplayer Co-op]] · [[Balance Philosophy]] · [[Universe Build-Out Plan]]
- Games: [[Sekiro Shadows Die Twice]] (Posture→Poise, inverted for ranged) · [[Hollow Knight]] (no-parry positioning-first; charm-notch = Horizon) · [[Hades]] (run-authored difficulty) · [[Monster Hunter World]] (co-op boss readability, trophy gates) · [[Dark Souls]] · [[Bloodborne]]
- Code: `wyrd/scripts/player_controller.gd`, `wyrd/scripts/combatant.gd`, `wyrd/scripts/boss.gd`, `wyrd/scripts/boss_bar.gd`, `wyrd/scripts/hit_feedback.gd`
