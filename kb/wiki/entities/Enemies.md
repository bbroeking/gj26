---
type: entity
tags: [combat, enemy, elite, pack-scaling, ai, crypt]
status: draft
updated: 2026-06-13
sources:
  - docs/specs/04-crypt-enemies.md
  - docs/specs/15-enemy-ai-player-hp.md
  - docs/specs/19-enemy-pathfinding.md
  - docs/specs/32-pack-scaling.md
  - wyrd/scripts/combatant.gd
  - wyrd/scripts/layout_loader.gd
  - wyrd/data/elites.gd
---

# Enemies

Enemies are the combat population of the Hollows — per-kind Combatant nodes with distinct HP/damage/speed stats, a 3-state AI, and an optional elite modifier that meaningfully changes how a fight plays.

## Per-kind roster (crypt biome)

Stats sourced from `wyrd/scripts/layout_loader.gd::ENEMY_KINDS` (authoritative; spec B3 tuning):

| Kind | HP | Damage | Speed | Atk CD | Tier debut | Notes |
|---|---|---|---|---|---|---|
| **skeleton** | 18 | 7 | 1.55 m/s | 1.7 s | 1 | Slow, hits hard |
| **rat** | 10 | 2 | 2.6 m/s | 0.9 s | 1 | Fast nibbler; quad-body with hop-bob anim |
| **ghost** | 14 | 5 | 1.35 m/s | 1.5 s | 2 | Slow floater; melee with longer reach |
| **hedge_sprite** | 22 | 6 | 1.9 m/s | 1.4 s | 3 | Tankiest trash mob |
| **crypt_warden** | 60 | 10 | 2.2 m/s | ~1.0 s | 4 (guard slot) | Mini-boss; guards tier-4/5 rooms |
| **bramble_imp** | 12 | 4 | 2.2 m/s | 1.1 s | — | Forge-cellar / briar biome |
| **skitterling** | 7 | 2 | 3.0 m/s | 0.8 s | — | Fastest trash; briar maze |

> ⚠️ Spec 04 listed skeleton HP as 18 and damage as 4; code (`ENEMY_KINDS`) shows damage = 7. Code wins — spec 04 stats were design intent, tuned by spec B3.

HP scales with depth: `effective_hp = base_hp × _hp_mult × (1.0 + 0.15 × (tier − 1))`. Affix **Tyrannical** (good twin) adds ×1.5 HP; **Erratic** (bad twin) jitters per-enemy. Speed can also be buffed by chart affixes (**Hateful** = ×1.25 speed).

### Biome spawn pools (layout_loader)

| Biome tag | Pool |
|---|---|
| `crypt` | skeleton 40%, rat 25%, ghost 20%, hedge_sprite 15% |
| `snug` | rat 70%, skeleton 30% |
| `hollow` | skeleton 45%, rat 20%, bramble_imp 20%, ghost 15% |
| `briar_maze` | bramble_imp 50%, hedge_sprite 30%, skitterling 20% |

## AI state machine

All enemies run a 3-state machine on `combatant.gd` (spec 15):

- **IDLE** — bind pose until player enters `aggro_radius` (default 7 m; some chart affixes like `fog_of_hedge` scale this per spawn).
- **CHASE** — navmesh-guided pursuit (spec 19, `NavigationAgent3D`); falls back to straight-line if no nav path. Leash radius 11 m — beyond that, enemy idles.
- **ATTACK** — within 1.8 m: stop, 0.35 s telegraph (scale/tilt punch), deal `damage` once, then cooldown, then back to CHASE.

Root status (`has_status("root")`) short-circuits the AI — the enemy freezes in place while rooted, though knockback from arrows still applies.

## Pack scaling

Room density scales by chart depth (spec 32):

```
n = 4 + clamp(depth / 2, 0, 6)
```

Depth 0 → 4 enemies; depth 6 → 10 enemies. The **festival_pace** affix (good twin) adds ×1.5 density; **lockstep** (bad twin) applies ×0.75.

## Elites

Each combat room rolls one elite with probability ≈ `n/8` (spec 32). An elite spawns with 2–3 same-kind retinue within 2.5 m. Visuals: persistent **golden tint** on all meshes, **scale boost**, and a **golden feet-ring** particle. The elite tint survives every hit-flash thanks to the `HitFeedback` material-restore path (spec 32c).

Elite modifiers (from `wyrd/data/elites.gd`, spec 32):

| Modifier | HP mult | Scale mult | Special mechanic |
|---|---|---|---|
| **Brambled** | ×1.25 | ×1.25 | On death: emerald bleed-nova (2.5 m radius, all nearby enemies bleed 4 s / 1 dpt) |
| **Swift** | ×1.0 | ×1.15 | ×1.5 move speed, ×1.2 attack speed |
| **Sunlit** | ×1.5 | ×1.25 | Melee swing applies **burn** to player (3 s / 0.5 s / 1 dpt per hit) |
| **Briarbound** | ×1.3 | ×1.15 | After first root/snared lands, **immune to CC for 4 s** |

All elites guarantee at least one item drop (`role = "elite"`, drop chance 1.0 in `drops.gd`). Boss rooms contain no elites.

## Drops and loot

Drops are governed by `wyrd/data/drops.gd` with role and depth context set at spawn:

- `role = "combat"` — standard trash mob, low drop chance
- `role = "elite"` — 100% drop chance, tier bias
- `role = "guard"` — crypt warden tier-4/5 slot

XP on kill flows to [[Huntcraft]] via `game.award_xp("hunt", max(2, int(hp_max / 3)))` (spec B7 / ADR 0005). The **Even Breath** perk (Huntcraft) refunds 6 Focus on a clean kill.

## See also

- [[Combat]] — hit feedback, status effects, AoE helpers
- [[Skills]] — which skills apply which statuses to enemies
- [[Bosses]] — the boss-tier combatants at the end of each chart
- [[Dungeon Generation]] — how rooms are typed and enemy slots assigned
- [[Huntcraft]] — the trade that grows from enemy kills
- [[Affixes]] — chart modifiers that buff enemies (Tyrannical, Hateful, Bursting)

## Sources

- `docs/specs/04-crypt-enemies.md` — design intent stats (code supersedes for damage)
- `docs/specs/15-enemy-ai-player-hp.md` — 3-state AI design
- `docs/specs/32-pack-scaling.md` — pack formula, elite system
- `wyrd/scripts/layout_loader.gd` — `ENEMY_KINDS`, `BOSS_KINDS`, spawn tables, pack formula
- `wyrd/scripts/combatant.gd` — AI state machine, status handling, elite mechanics
- `wyrd/data/elites.gd` — modifier catalogue
