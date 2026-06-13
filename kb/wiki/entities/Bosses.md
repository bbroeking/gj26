---
type: entity
tags: [combat, boss, trophy-chain, phase-machine, hedgemother, chart-loop]
status: draft
updated: 2026-06-13
sources:
  - docs/BOSS_SPEC.md
  - docs/specs/05-hedgemother-boss.md
  - docs/specs/17-hedgemother-boss-fight.md
  - docs/wyrd-skills-combat-plan.md
  - wyrd/scripts/boss.gd
  - wyrd/scripts/layout_loader.gd
---

# Bosses

Bosses are the HP-gated phase machines at the end of the [[Chart Loop]] — sealed-arena encounters with telegraphed AoE attacks and trophy drops that unlock the next tier of chart.

## The trophy chain

There are four bosses in the current roster, forming the progression spine. Each boss's trophy is an ink ingredient that lets the player inscribe a chart to a deeper den:

| # | Boss | Trophy | HP | Damage | Chart biome |
|---|---|---|---|---|---|
| 1 | **Hedgemother** | `tusker_tusk` | 60 | 8 | Crypt dens |
| 2 | **Burrow Boar** | `wightpelt` | 80 | 11 | Burrow dens |
| 3 | **Wolf Alpha** | `alpha_fang` | 55 | 7 | Wolf dens |
| 4 | **Hedgemother Queen** | — | 160 | 13 | Summit (final chart) |

Stats from `wyrd/scripts/layout_loader.gd::BOSS_KINDS` (authoritative).

> ⚠️ The docs (BOSS_SPEC.md, spec 05) describe the full trophy chain as Hedgemother → Pale Hag → Chartmaker's Echo. Code confirms the actual in-game chain is Hedgemother → Burrow Boar → Wolf Alpha → Hedgemother Queen. BOSS_SPEC.md covers art/model briefs for future/alternate bosses not yet in the trophy chain.

All bosses extend `wyrd/scripts/boss.gd`, which extends `combatant.gd`. This gives them HP, hurtbox, flash, knockback, death, and navmesh chase from Combatant, while `boss.gd` replaces the simple AI with the phase machine.

## Shared mechanics

**Arena seal**: when the player enters a boss room, the entry seals (a wall segment blocks the doorway). The seal opens on the boss's death. If the player dies, the fight resets: boss heals to full, de-aggros, telegraphs cancel (`boss.reset_fight()`).

**Boss HP bar**: a banner-style bar at the top of the viewport (`BossBar.tscn` / `boss_bar.gd`), shown on aggro. Displays the boss name.

**Status immunity**: Hedgemother (and by extension the Queen) are fully immune to root and snared; burn and bleed land at 50% duration. The boss bar appends " — Unyielding" so the player understands why their Bramble Snare didn't take (spec 31).

**No elite modifiers**: boss rooms never roll elites (pack formula explicitly excludes the boss room).

## Hedgemother

*A bramble-queen 2.4 m tall, crowned in living thorns, robed in woven vine.*

The first boss and the tutorial for the phase-machine language. She fights with escalating attacks keyed to HP gates:

### Phases (from `wyrd/scripts/boss.gd`)

| Phase | HP range | Attack cadence | Telegraph |
|---|---|---|---|
| 1 | 100–66% | 2.6 s CD | 0.75 s wind-up |
| 2 | 66–33% | 1.9 s CD | 0.6 s wind-up |
| 3 | 33–0% | 1.3 s CD | 0.46 s wind-up |

Later phases hit faster and give less time to read the tell — the fight escalates without adding new mechanics, just increasing pressure.

### Attacks

- **Thorn sweep** (`SWEEP_RADIUS = 3.6 m`): radial AoE centred on her. A ground decal telegraph (flat tinted disc) shows the danger zone 0.75 s before the hit. Active from phase 1.
- **Root stomp** (`STOMP_RADIUS = 2.3 m`): targeted at the player's position when the telegraph starts — move out of the decal. Active from phase 2.

Spec 05 proposed a **summon** attack (hedge-sprites at phase 3); it is described in the spec but not confirmed in the current `boss.gd` code. The telegrahed-attack set in code is sweep + stomp.

### Victory

Killing the Hedgemother: seal lifts, gold exit becomes interactive, a tier-5 reward chest spawns at her death position, `player.flags.cryptCleared = true`. The trophy `tusker_tusk` rolls in the chest — it is the ink ingredient for Burrow Boar den charts.

## Burrow Boar

*A massive tusked boar that charges in a straight line.*

Introduced in spec B4a. The Boar replaces the Hedgemother's radial sweep with a **line charge** (a very different dodge pattern — sidestep, not back-pedal):

- **Charge** (`CHARGE_RANGE = 8 m`, `CHARGE_WIDTH = 1.7 m`, `CHARGE_SPEED = 11 m/s`): windup → line telegraph → dodgeable dash. One hit per charge, 11 damage. The telegraph shows the lane; sidestepping avoids it.

Playtest via `WYRD_DEV_CHART=tier_1 WYRD_DEV_BOSS=burrow_boar_den`. The boar and wolf are quadrupeds — their GLBs use a procedural hop-bob animator (not a full rig) per the Meshy quadruped limitation.

## Wolf Alpha

*A massive dire wolf that chains lunges in rapid succession.*

Introduced in spec B4b. The Wolf's signature is a **chained pack-lunge** — multiple short re-aimed dashes that re-telegraph at the player's current position with only 0.32 s of wind-up:

- **Lunge chain** (`LUNGE_RANGE = 4.5 m`, `LUNGE_SPEED = 13 m/s`, `LUNGE_RETELEGRAPH = 0.32 s`): 2 lunges in phase 1, 3 in phase 2, 4 in phase 3. Each re-aims at the player — standing still is punished. The cadence is intentionally snappy so the player must keep moving rather than dodging a single predictable direction.

Playtest via `WYRD_DEV_CHART=tier_1 WYRD_DEV_BOSS=wolf_alpha_den`.

## Hedgemother Queen

*The Summit's nest-mother — the final chart's boss.*

Same model as the Hedgemother (`hedgemother_v2.glb`) scaled up (4.6× vs Hedgemother's 3.75×), with 160 HP and 13 damage. She is the endgame boss gating the Summit — the deepest den in the [[Chart Loop]]. Her full fight design (attacks, phase gates) is not yet specified in docs; she uses the inherited phase-machine and attack dispatch from `boss.gd` with her higher stats.

## See also

- [[Chart Loop]] — how trophies unlock deeper dens
- [[Charts]] — the parameterized keys that set boss den type
- [[Enemies]] — the trash mobs and elites in the same run
- [[Combat]] — shared fight mechanics (status immunity, sealed arenas)
- [[Skills]] — effective tools against boss immunities (burn, bleed over snare/root)
- [[The Waystone]] — the in-run exit gated behind the boss kill
- [[Design Decisions]] — ADR 0003 (combat as one verb), FATE/Diablo boss conventions

## Sources

- `docs/BOSS_SPEC.md` — model briefs (Hedgemother rebuild, Pale Hag, Chartmaker's Echo art/rig)
- `docs/specs/05-hedgemother-boss.md` — Hedgemother fight design (three.js origin)
- `docs/specs/17-hedgemother-boss-fight.md` — Godot port of the Hedgemother phase machine
- `docs/wyrd-skills-combat-plan.md` — B4a/B4b boss implementation notes
- `wyrd/scripts/boss.gd` — authoritative phase constants, immunity table, moveset
- `wyrd/scripts/layout_loader.gd` — `BOSS_KINDS` HP/damage/trophy values
