# Spec 31 research — status effects + AoE in FATE: Reawakened, Diablo 3, Path of Exile 2

Background synthesis for spec 31 (status framework + AoE damage shapes). Saved per the ARPG-spec workflow so the spec's "References" section can link back to the genre research that informed each decision.

## 1. FATE: Reawakened (Crate, 2025 remaster)

FATE is the cozy reference. Spell schools loosely group as Fire, Ice (Frost), Lightning, Venom/Poison + Charm/Summon/Healing. Status conditions in the [console patch notes](https://playfate.com/patch-notes/fate-reawakened-console-patch-notes/) are **Muffle, Drain, Slow, Blind, Confusion, Poison, Web** — about seven distinct debuffs, all *functional* rather than damage-multiplying. Visual layer is intentionally light: small particle/icon overlay + Poison surfaces in the HP bar text ("poisoned") — storybook-friendly choice worth stealing.

AoE shapes are simple: the [Spells page](https://fate.fandom.com/wiki/Spells) and patch notes mention **projectile multishot** (Frost spell fires *two* projectiles), **cone**-style cleaves, and **zone/area** versions that cost +2 spell level. Damage falloff isn't a thing — full damage inside the zone, nothing outside. No chain skills.

**Gets right:** small + legible debuff catalogue; each does one obvious thing. **Pitfall:** spells lack interaction — Ice doesn't really synergise with Fire; statuses are flavor not strategy.

## 2. Diablo 3 (Blizzard)

D3 has the canonical CC taxonomy: **Hard CC** (Stun, Freeze, Blind, Fear, Charm, Immobilize, Taunt, Hex) which completely disables monsters, and **Soft CC** (Chill, Slow, Knockback, Daze) which only modifies them. The [Maxroll CC guide](https://maxroll.gg/d3/resources/crowd-control-explained) + [Diablo wiki](https://diablo.fandom.com/wiki/Crowd_Control) document the **diminishing-returns rule: every second of Hard CC builds +10% resistance, capped at 95%**, decaying −5%/s out of combat. Below 0.65s effective duration (0.85s for bosses), hard CC stops working entirely. Soft CC ignores the system.

Stacking: "highest wins, refresh duration." DoTs tick **~2×/sec**, damage = % of weapon damage *at apply time* (re-applying a stronger version overwrites).

AoE shapes are a buffet: **Frost Nova** (~15 yd point-blank circle, 2s freeze), **Arcane Orb** (targeted explosion), **Locust Swarm** (cone-initial then chain-spread within 20 yd), **Disintegrate** (line/beam), **Meteor** (targeted ground circle with delay). Falloff: **flat — full inside, zero outside**. Loud visual: cold tints turn enemies blue + ice shards; burn shows orange flames; stun = stars-and-birds icon.

**Gets right:** Hard/Soft split + DR keeps CC interesting without trivializing elites. **Pitfall:** DR system is opaque — players never see the resistance bar.

## 3. Path of Exile 2 (GGG, 2024–2026)

PoE 2 is the most rigorous, with **7 ailments tied to damage types**: Ignite (fire DoT, 4s, 20% of fire-hit-dmg/s), Bleed (physical DoT, 5s, 70% of phys-hit-dmg/s), Poison (chaos DoT, 2s, 20% of phys+chaos-hit-dmg/s, **stackable**), Chill (cold slow, 2s), Freeze (cold lock, 4s), Shock (lightning, +20% dmg taken, 4s), Electrocute (lightning interrupt, 5s) — see [Mobalytics' guide](https://mobalytics.gg/poe-2/guides/ailments) and the [Fextralife wiki](https://pathofexile2.wiki.fextralife.com/Status+Ailments).

Stacking is the interesting part: **Ignite uses "biggest" — highest-damage instance ticks, others wait their turn** ([Mobalytics Ignite](https://mobalytics.gg/poe-2/guides/ignite)); **Poison is the only one that truly stacks** (default cap 1, modifiable up) and all stacks add their damage ([Mobalytics Poison](https://mobalytics.gg/poe-2/guides/poison)). Application is probabilistic via an **Ailment Threshold** (roughly target HP) — see [Screen Plays Mag](https://screenplaysmag.com/blog/poe-2-elemental-ailment-threshold-mechanics-explained/) — so giant hits ignite, chip damage usually doesn't.

AoE shapes: **circle** (Fireball detonation), **line** (Lightning Arrow), **cone** (Galvanic Shards), **nova** (Ice Nova expanding from Frostbolt seeds), **chain** (Chain support gem jumps between nearby enemies). The [Increased AoE Support](https://pathofexile.fandom.com/wiki/Increased_Area_of_Effect_Support) gem scales radius, never adds falloff — PoE 2 is full damage inside, none outside.

**Gets right:** ailments *encode the damage type identity* — fire feels different from cold because of the ailment, not just the number. **Pitfall:** ailment-only builds (zero-base-damage Ignite stacking) eventually divorce DPS from the hit itself.

## Comparison table

| Dimension | FATE: Reawakened | Diablo 3 | Path of Exile 2 |
|---|---|---|---|
| # of statuses | ~7 (Muffle/Drain/Slow/Blind/Confusion/Poison/Web) | ~9 hard + 3 soft | 7 (3 damaging, 4 elemental) |
| Stacking | refresh/replace | highest wins, refresh | Ignite: biggest; Poison: stack-cap; Bleed: biggest |
| Tick rate | ~1/s (cozy) | ~2/s | 1/s (but instance-based) |
| Damage formula | flat scalar | % weapon damage at apply | % of hit damage of *that* type |
| Visual | particle + HP-bar text | tint + icon + particles | tint + animated icon + particles |
| AoE shapes | projectile, cone, zone | circle, nova, cone, line, beam, ground-target | circle, nova, cone, line, chain |
| Falloff | none (full inside) | none (full inside) | none (full inside, radius scales target size) |
| CC resistance | none | hard-CC DR (+10%/s, cap 95%) | hard immune on bosses; ailment threshold gate |

All three converge on **no spatial damage falloff** — industry default. They diverge on stacking — PoE 2's "biggest + per-type rules" is the deepest, D3's "highest wins, refresh" is the simplest. For gj26 the simple model is the right choice.

## Recommendations for gj26 spec 31

### Ship 4 statuses in v1

The current code already has **Root** (`apply_root` in `combatant.gd`) as our zeroth status. Extend that exact pattern.

| Status | Trigger | Duration | Tick rate | Per-tick dmg | Visual | Stacking |
|---|---|---|---|---|---|---|
| **Root** (existing) | BrambleSnare | 2.0 s | n/a | 0 | emerald disc (current) | refresh-to-max |
| **Burn** (new) | PowerShot hit | 3.0 s | 0.5 s (6 ticks) | 1 dmg/tick = 6 total (~40% of PowerShot) | flame particle + warm tint | highest-dmg wins, refresh |
| **Bleed** (new) | Crit hit (any skill) | 4.0 s | 1.0 s (4 ticks) | 25% of crit dmg / 4 | red drip particle | refresh; only one instance |
| **Snared** (new, soft) | MultiShot hit | 1.5 s | n/a | 0 (50% slow) | brown vine wisp at feet | refresh |

Why these:
- **Root** stays — the v1 prototype, already shipped.
- **Burn** gives PowerShot a *reason to exist over BasicShot spam* — burst + DoT layer.
- **Bleed-on-crit** is a *passive* reward for the crit system (spec 26) — no new input, "crits hit harder *and* linger." Storybook flavor: faerie-thorns leave little cuts.
- **Snared (soft slow)** turns MultiShot from "raw damage cone" into a **kite-enabling pack tool**.

Skipping for v1: Freeze (overlaps Root), Shock (no lightning fantasy yet), Stun (combat already fast), Confusion/Charm (AI hole — wait for class-paths).

### Tick design — fixed 0.5s intervals, not per-frame

Cardinal rule: **never tie DoT damage to `delta`**. The naive "subtract `dps * delta` per frame" loses sub-1-HP fractions to int rounding. Instead, store `time_left: float` and `next_tick: float`; each `_physics_process` decrement both and when `next_tick <= 0` apply integer damage + add 0.5 to next-tick. Frame-rate independent.

### Visual layer — three channels, no more

Borrow FATE's restraint, not D3's loudness:

1. **Particle above head** (small — single GPUParticles3D, one of 4 textures: flame, drip, vine, future-frost).
2. **Material tint pulse** — reuse `_flash_mat` infra: a 0.15-alpha warm/red/green wash pulsing on tick.
3. **Apply-text suffix** — FATE's "poisoned" suffix translates to Bramblewood. A small italic word under floating damage on *apply only* ("singed!", "snared!", "bleeding!"), not every tick.

Skip status icons in the HUD for v1.

### Status immunity for bosses

Extend the existing `apply_root` pass-through. Bosses **fully immune to Root and Snared** (lock-down), take **50% reduced duration on Burn and Bleed**. Skip D3's hidden DR — binary immune-or-not + duration multiplier reads cleaner.

### AoE shape vocabulary — 3 shapes, no falloff

1. **Circle (ground-target)** — already exists as Snare. Use for the next AoE: **ExplosiveArrow** (target-point circle, 2.5m radius, instant). 70% base damage on detonation + Burn to all caught.
2. **Cone (origin-anchored)** — MultiShot is physically a 3-arrow cone; formalise as `_query_cone(origin, dir, range_m, half_angle_deg)`.
3. **Nova (centred on caster, expanding)** — reserve for future *Whisp Burst*. Architect AoE helper to support but don't ship in 31.

**Falloff rule: full damage inside, zero outside.** All three reference games agree.

**Skip: chains.** Expensive to implement well (nearest-not-already-hit, visual arc), 4-slot hotbar doesn't need yet.

### Implementation shape — one StatusEffect + dict on Combatant

```gdscript
# scripts/status_effect.gd (new)
extends RefCounted
var kind: String        # "burn" | "bleed" | "snare" | "root"
var time_left: float
var tick_interval: float
var next_tick: float
var damage_per_tick: int
var slow_factor: float = 1.0    # 1.0 = no slow; 0.5 = half speed
```

On `combatant.gd`, replace single `_root_t` with `var _statuses: Dictionary = {}` keyed by `kind`. Move existing Root logic into this dict. `apply_status(kind, duration, dmg_per_tick, slow)` handles highest-wins/refresh. AI tick reads `has_status("root")` and applies `slow_factor` product (capped 0.25× min). Visual mesh owned by StatusEffect.

### Pitfalls to actively design against

1. **Don't let statuses replace damage** (PoE 2 ailment-only trap). Cap Burn total ≤ 80% of originating hit.
2. **Don't tie tick rate to frame rate** (fixed 0.5s intervals).
3. **Don't over-clutter visuals.** Cap simultaneous particles per enemy at 2.
4. **Don't add hidden DR.** Boss = binary immunity + duration multiplier; visible via "Unyielding" affix text style.
5. **Don't ship Chain or Freeze in v1.** Park for spec 34+.

### Trade-off named: D3 binary CC vs PoE 2 ailment threshold

Both require UI layers gj26 lacks. **Adopt neither.** Cozy compromise: statuses always apply on hit; bosses are binary-immune to lock-down; small monsters take everything.

## Files referenced (for the implementing agent)
- `/Users/bbroeking/projects/gj26/godot/scripts/combatant.gd` — `_root_t` → generalised `_statuses` dict
- `/Users/bbroeking/projects/gj26/godot/scripts/boss.gd` — extend pass-through into per-status immunity table
- `/Users/bbroeking/projects/gj26/godot/scripts/player_controller.gd` — `_fire_powershot` applies Burn; `_fire_multishot` applies Snared
- `/Users/bbroeking/projects/gj26/godot/scripts/arrow.gd` — on hit, call status-apply hook based on `skill_type`
- `/Users/bbroeking/projects/gj26/godot/scripts/status_effect.gd` *(new)*
- `/Users/bbroeking/projects/gj26/godot/scripts/aoe_query.gd` *(new)*

## Sources
- [FATE: Reawakened Console Patch Notes](https://playfate.com/patch-notes/fate-reawakened-console-patch-notes/)
- [FATE Spells (Fandom)](https://fate.fandom.com/wiki/Spells)
- [Diablo 3 CC Explained (Maxroll)](https://maxroll.gg/d3/resources/crowd-control-explained)
- [Crowd Control (Diablo Fandom)](https://diablo.fandom.com/wiki/Crowd_Control)
- [Locust Swarm (Diablo wiki)](https://www.diablowiki.net/Locust_Swarm)
- [PoE 2 Ailments (Mobalytics)](https://mobalytics.gg/poe-2/guides/ailments)
- [PoE 2 Ignite (Mobalytics)](https://mobalytics.gg/poe-2/guides/ignite)
- [PoE 2 Poison (Mobalytics)](https://mobalytics.gg/poe-2/guides/poison)
- [PoE 2 Status Ailments (Fextralife)](https://pathofexile2.wiki.fextralife.com/Status+Ailments)
- [PoE 2 Elemental Ailment Threshold (Screen Plays Mag)](https://screenplaysmag.com/blog/poe-2-elemental-ailment-threshold-mechanics-explained/)
- [PoE 2 All Ailments Explained (Sportskeeda)](https://www.sportskeeda.com/mmo/path-exile-2-poe2-ailment-types-guide-explained)
- [Increased AoE Support gem (PoE wiki)](https://pathofexile.fandom.com/wiki/Increased_Area_of_Effect_Support)
