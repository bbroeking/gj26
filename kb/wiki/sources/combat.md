---
type: source
tags: [combat, skill, enemy, boss, status, hit-feedback, pack-scaling]
status: draft
updated: 2026-06-13
sources: []
---

# Source Digest: Combat Cluster

Digest of the 16 source docs read to build the Combat, Skills, Enemies, and Bosses wiki pages.

## Sources read

| Doc | Summary |
|---|---|
| `docs/wyrd-skills-combat-plan.md` | Build plan v2 (spec 30–B8). Tracks done/todo with gate criteria. Key: combat is "one verb" per ADR 0003; spine test defines what ships. B3/B4a/B4b/B8 all green as of 2026-06-11. |
| `docs/BOSS_SPEC.md` | Art/model briefs for Hedgemother rebuild, Pale Hag (alt boss), and Chartmaker's Echo. Rig structure, material names, bevel recipe, export steps. **Not the fight mechanics doc.** |
| `docs/specs/30-skills-and-cooldowns.md` | The 4-skill v1 hotbar: BasicShot/PowerShot/MultiShot/BrambleSnare. Focus resource (50 max, 10/3 regen), 4-slot bind, `cooldown_reduction` affix. Bramble Snare's root is intentionally minimal one-off. |
| `docs/specs/30-skills-and-cooldowns-research.md` | (Not read directly; referenced by spec 30.) Genre synthesis: FATE Reawakened, Diablo 3, PoE 2 — 4-skill hotbar, hybrid CD+cost gating, ailment identity. |
| `docs/specs/31-status-and-aoe.md` | Status framework (`StatusEffect`, `_statuses` dict, `apply_status` with highest-wins + refresh-duration stacking). Ships burn/bleed/snared/root; generalises spec 30's one-off root. `aoe_query.gd` helpers. Boss immunity table (full immune to lock-down, 50% duration on damage statuses). |
| `docs/specs/32-pack-scaling.md` | Pack formula `n = 4 + clamp(depth/2, 0, 6)`. Elite system: probabilistic roll, retinue, golden tint + scale + feet-ring, 4 modifiers (Brambled/Swift/Sunlit/Briarbound). Drops: `role="elite"`, 100% drop chance. |
| `docs/specs/32b-skill-module.md` | Skill class hierarchy: `Skill` (base) → `ProjectileSkill` (data-driven) → concrete subclasses. `SkillEffect` carries on-hit consequences as data. Collapses 4 hardcoded `_fire_*` methods into a clean dispatch. |
| `docs/specs/32c-hit-feedback.md` | `HitFeedback` static module with two entry points: `play_hit` (6 channels: flash/knockback/hitstop/spark/shake/SFX) and `tick_pulse` (soft status-coloured mesh pulse). Tier-keyed const tables (hitstop/shake/knockback/SFX). |
| `docs/specs/33a-player-status.md` | Player-side status framework mirroring Combatant's. `_statuses` dict on `player_controller.gd`, `apply_status`/`_tick_statuses`/`_apply_tick_damage`, HP-bar suffix (`"burning · snared"`). Sunlit elite now applies real burn DoT. |
| `docs/specs/04-crypt-enemies.md` | Crypt enemy roster design: skeleton, rat, ghost, hedge_sprite, crypt_warden. Niji 6 concept art pipeline, Meshy Image-to-3D, tier spawn tables. **Design intent stats** (damage values superseded by B3 code tuning). |
| `docs/specs/05-hedgemother-boss.md` | Hedgemother boss design (three.js origin): 3 HP-gated phases, 3 attack types (thorn-sweep / root-stomp / summon), arena seal, boss HP bar, crypt-cleared flag, reward chest. |
| `docs/specs/17-hedgemother-boss-fight.md` | Godot port of the Hedgemother phase machine. `boss.gd` extends `combatant.gd` (inherits HP/hurtbox). Phase gates at 66%/33%. Telegraphed attacks with ground-decal zone shows. Arena seal opens on death. |
| `docs/specs/14-fluid-combat.md` | Foundational combat feel: hitbox/hurtbox Area3D, single-hit dedup, hitstop, enemy flash, floating damage numbers, knockback, input buffering (150 ms). 10 headless evals (E1–E10). |
| `docs/specs/15-enemy-ai-player-hp.md` | Closes the combat loop: enemy 3-state AI (IDLE/CHASE/ATTACK), player HP (30), i-frames (0.6 s), death/respawn at entry. Tunables: AGGRO_RADIUS 7, ATTACK_RANGE 1.6, ENEMY_DAMAGE 5. |
| `docs/specs/26-combat-juice.md` | MapleStory maximalism: crit system (20%/×2, 4%/×3), damage-number pop+scatter+colour tiers, hit spark, screen shake scaled by crit, ElevenLabs SFX (fire/hit/crit/death). Arrow speed 34 m/s, fire cooldown 0.28 s. |
| `docs/specs/37-skill-depth-research.md` | New World gathering/crafting depth research (not combat); referenced as skill-depth input. Not directly relevant to combat pages — no facts drawn from it for this cluster. |

## Wiki pages fed

- [[Combat]] — Focus, hotbar, hit feedback, status effects, AoE, player survival, pack density
- [[Skills]] — all 9 skills, costs/CDs, Huntcraft gates, status applied per skill
- [[Enemies]] — roster stats, AI, biome pools, pack formula, elite modifiers
- [[Bosses]] — trophy chain, phase machines, boss-specific movesets, immunity

## Key contradictions found

1. **Enemy damage values**: Spec 04 (`docs/specs/04-crypt-enemies.md`) lists skeleton damage = 4, rat = 2. Code (`wyrd/scripts/layout_loader.gd::ENEMY_KINDS`) shows skeleton damage = 7, rat = 2. Code wins (spec B3 tuning). Flagged in [[Enemies]].

2. **Skill pool size**: Spec 30 describes a 4-skill pool. Code (`wyrd/scripts/game.gd::SKILL_POOL`) has 9 skills shipped across specs 30 and B5. Flagged in [[Skills]].

3. **Boss trophy chain**: `docs/BOSS_SPEC.md` covers Hedgemother → Pale Hag → Chartmaker's Echo as future/alternate bosses (model briefs). Code (`BOSS_KINDS`) implements Hedgemother → Burrow Boar → Wolf Alpha → Hedgemother Queen as the live chain. These are parallel tracks: BOSS_SPEC.md = model pipeline; BOSS_KINDS = gameplay chain. Flagged in [[Bosses]].

4. **Hedgemother summon attack**: Spec 05 describes a phase-3 summon (2 hedge-sprites). Not confirmed in `boss.gd` code; sweep + stomp are the verified attacks. Flagged in [[Bosses]].
