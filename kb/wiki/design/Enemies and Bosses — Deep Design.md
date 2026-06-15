---
type: design
tags: [system-design, enemies-bosses]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/Universe Build-Out Plan.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "kb/wiki/entities/Enemies.md"
  - "kb/wiki/entities/Bosses.md"
  - "wyrd/scripts/combatant.gd"
  - "wyrd/scripts/boss.gd"
  - "wyrd/scripts/layout_loader.gd"
  - "wyrd/data/elites.gd"
  - "kb/wiki/games/soulslike/Sekiro Shadows Die Twice.md"
  - "kb/wiki/games/co-op/Monster Hunter World.md"
  - "kb/wiki/games/arpg/Hades.md"
---

# Enemies and Bosses — Deep Design

> Forward-looking deep design. Current-state: [[Enemies]] and [[Bosses]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are a Wayfinder, not a slayer. Combat is **one verb — the bow** (ADR 0003, P8), and a fight is a *reading* problem: the bramble-things telegraph, you read the tell, you respond. Enemies and bosses exist to give the delve leg of `gather → craft → chart → delve` a heartbeat — a few tense seconds that make the homecoming feel earned — and to feed [[Huntcraft]] (every kill pays `max(2, hp_max/3)` XP, ADR 0005). The fantasy is *competent care*: you quiet a place, you don't conquer it. The capstone is the Hedgemother **quieted, never killed** (P6) — there is no King of Brambles.

## What ships today (grounded in code)

- **Per-kind trash roster** lives in `layout_loader.gd::ENEMY_KINDS` — six kinds (skeleton, rat, ghost, hedge_sprite, bramble_imp, skitterling) each with `hp / damage / speed / atk_cd`, plus a `crypt_warden` guard slot. Per-scope weighted spawn tables (`SPAWN_TABLES`) make a crypt run *feel* different from a briar maze.
- **3-state AI** on `combatant.gd::_tick_ai` — IDLE → CHASE (navmesh via `NavigationAgent3D`, 11 m leash) → ATTACK (1.8 m range, 0.35 s scale-punch telegraph, one hit, cooldown). `has_status("root")` freezes the unit but lets knockback still land.
- **Elites** — `data/elites.gd::MODIFIERS` (Brambled bleed-nova, Swift, Sunlit burn, Briarbound CC-immune), rolled in `layout_loader` at ~`n/8`, promoted by `combatant.gd::apply_elite()`: golden tint (survives hit-flash via the `_saved` material-restore path), scale boost, feet-ring, 2–3 same-kind retinue, guaranteed drop, first chart-chain trophy.
- **Pack scaling** — `n = 4 + clamp(depth/2, 0, 6)`; `festival_pace` ×1.5 / `lockstep` ×0.75 density twins.
- **Boss phase machine** — `boss.gd` extends Combatant, swaps the melee AI for a 3-phase HP-gated machine (`_phase_cooldown` = [2.6, 1.9, 1.3] s, `_phase_telegraph` = [0.75, 0.6, 0.46] s) with floor-decal/lane telegraphs, sealed arena, `reset_fight()` on player death. The four shipped kinds: **Hedgemother** (sweep + stomp), **Burrow Boar** (line charge), **Wolf Alpha** (chained re-aiming lunge), **Hedgemother Queen** (same `hedgemother_v2.glb` scaled 3.75 → 4.6, the Summit — *the same being*). Trophies (`tusker_tusk → wightpelt → alpha_fang`) ink the next den.
- **Status immunity** — bosses reject root/snared, take burn/bleed at 0.5× duration; the bar appends " — Unyielding."

The shape exists. The gaps are: the Hedgemother's **gimmick is not built** (sweep+stomp only; thorn-arena and the spec-05 phase-3 summon are unwired), bosses are **pure damage-race** (no reading reward), and co-op telegraph/credit RPCs are partial.

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

**1. Poise / stance-break — the ONE demo reading mechanic (P9).** Borrowed from [[Sekiro Shadows Die Twice|Sekiro's]] posture engine but cozy-soft: a per-boss **Poise** meter, separate from HP, that fills when arrows land **during the boss's recovery/whiff frames** (i.e. the window after a telegraphed attack resolves, before the next windup). Hits in the windup do *normal* damage but build no Poise — so the skill is *reading the tell and punishing the recovery*, not spamming. At full Poise the boss enters a ~3 s **Reeling** state: it stops attacking, slumps (existing scale-punch + a green-leaf shudder VFX), and exposes a **Wayfinder's Mark** finisher (a charged shot that deals a flat bonus + resets the player's skill cooldowns). This is the *only* CC-equivalent the player gets against root-immune bosses — Poise replaces snare as the expression of skill. Unlike Sekiro, missing the window never punishes the player (cozy contract); it only delays the payoff.

**2. Boss gimmicks as zone-shape, not new weapons (P2/P3).** Each boss reads its gimmick off the *room theme*, so the fight feels like the place:
- **Hedgemother — thorn-arena + phase-3 summon.** On aggro, growing brambles seal the exits (already the shipped seal, dressed as living thorn). Phase 3 spawns 2 hedge_sprites (the unbuilt spec-05 summon) — the only fight where trash and boss overlap; sprites are the player's Poise-building reprieve.
- **Burrow Boar — tusk-quake.** Keep the shipped line charge; add a phase-2 **tusk-quake**: at charge-end-on-wall, a short radial shockwave (reuse `_make_telegraph` disc) cracks the floor, briefly denying that tile. Couples to the Pale Veins' "collapsing-vein" theme.
- **Wolf Alpha — pack-lunge.** Already shipped (2/3/4 chained re-aiming lunges). Horizon: a phase-3 howl that calls one wolf-pup add.

**3. Trash as texture, not threat.** Trash stays a 3-state melee that exists to (a) gate movement, (b) feed Huntcraft, (c) host the elite affixes. No new AI states for the demo — depth comes from *pack composition* (the spawn table) and *elites*, not per-mob scripting.

### Data model & formulas (GDScript-flavored)

| Quantity | Formula / source | Notes |
|---|---|---|
| Effective HP | `base_hp × _hp_mult × (1 + 0.15·(tier−1))` | tier scaling is HP-only (`ENEMY_KINDS`) — speed stays honest |
| Damage | `max(1, atk + floor(str/2) − def ± 1)` | subtractive, floor 1 ([[Balance Philosophy]] §3) |
| Pack size | `n = 4 + clamp(depth/2, 0, 6)` | ×1.5 festival_pace / ×0.75 lockstep |
| Elite roll | `p ≈ n/8` | one per ~8 trash; never in boss rooms |
| Huntcraft XP | `max(2, int(hp_max/3))` | elites/bosses pay their weight (ADR 0005) |
| **Poise max (new)** | `poise_max = round(hp_max × 0.5)` | a half-HP "second bar"; tune per-boss |
| **Poise gain (new)** | `+dmg` only if `boss.in_recovery_window()` | windup hits build 0 Poise |
| **Poise decay (new)** | `−poise_max × 0.10 / s` while not in recovery | no-hold pressure; never resets to 0 instantly |
| **Reeling (new)** | `3.0 s`; Mark finisher = `+round(hp_max×0.08)` flat | flat & capped — no raw-damage creep (P8) |

New boss fields (in `boss.gd`): `poise`, `poise_max`, `_recovery_t`, `_reeling_t`. `in_recovery_window()` returns `_recovery_t > 0`, set for ~0.8 s after each `_resolve_attack()`. Poise is **per-boss and resets on `reset_fight()`** — it is a within-fight skill expression, not persistent power.

### Content to author (tiers / tables / worked examples)

| Tier (chart) | Trash band | Elite chance band | Boss | Poise_max | Target boss TTK |
|---|---|---|---|---|---|
| 1 (crypt) | skeleton/rat/ghost/sprite | ~50% at depth 4 | Hedgemother (60 HP) | 30 | 30–45 s |
| 2 (burrow) | + Hedgewight (new Pale Veins mob) | ~60% | Burrow Boar (80 HP) | 40 | 40–55 s |
| Horizon | briar pool | — | Wolf Alpha (55 HP) | 28 | 35–50 s |
| Capstone | crypt pool, denser | — | Summit-Hedgemother (160 HP, *same being*) | 80 | 50–70 s |

**New mob (Pillar One):** `hedgewight` — `{hp: 28, damage: 6, speed: 1.6, atk_cd: 1.5}`, a slow pale-stone ghost-kin; tankiest non-elite, the Pale Veins' signature. Authored as a data row + a tinted dummy clone first (P5), GLB backfilled in a tonal batch.

**Worked Poise example (Hedgemother):** poise_max 30. Player reads the 0.75 s sweep tell, sidesteps, lands 3 arrows (≈9 dmg each) in the 0.8 s recovery = +27 Poise. Two clean reads → Reeling → Wayfinder's Mark = `60×0.08 ≈ 5` flat + cooldown reset. Skilled reading roughly halves a sloppy fight's length without a damage upgrade — exactly the P8 "depth from reading, never from gear" target.

### Edge cases, failure modes, anti-frustration

- **Cozy guardrails are law** ([[Balance Philosophy]] §2): no one-shot below 50% HP, retreat always allowed, death = fade-to-bed. Boss telegraph minimum (0.46 s at phase 3) is the floor — do not shorten further.
- **Poise must never punish.** Whiffing the window costs nothing; only the upside (faster Reeling) is gated. If a tester reports Poise feels like a *demand*, ship it as pure upside and surface the meter only after first Reeling.
- **Pack + elite stacking** at depth 6 with festival_pace can spike to ~15 bodies + elite retinue — the perf cap (P-workstream, §6) must hold the Boar fight + room density in budget; clamp concurrent elites to 1/room (already true).
- **Summon overlap:** the phase-3 hedge-sprite summon is the *only* trash-in-boss-room case — guard it explicitly so `pack` formula stays boss-room-exclusive otherwise.
- **Reeling during co-op:** Reeling and the recovery window must be host-authoritative and RPC'd to all peers, or a guest punishes a window that already closed.

## Interlocks

- **[[Huntcraft]]** — every kill feeds it; the *only* combat trade fed by all kills everywhere (P11). Even Breath perk refunds Focus on clean kills.
- **[[Charts]] / [[Affixes]] / [[Chart Loop]]** — affixes buff enemies (Tyrannical HP, Hateful speed, Bursting corpse-pop, fog_of_hedge perception); the boss-as-affix sets the den's capstone; trophies ink the next chart. Pale-Veins-flavored affix twins are the demo's affix work.
- **[[Combat]]** — shares the status framework, `HitFeedback` 6-channel hit pipe, crit/bleed-on-crit. Poise lives here as the demo's one reading mechanic.
- **[[Skills]]** — burn/bleed are the boss-effective tools (snare/root bounce off "Unyielding"); the Mark finisher resets skill cooldowns.
- **[[Multiplayer Co-op]]** — host-authoritative; party-wipe before reset; kill credit via `last_hit_peer`; **telegraphs + Poise + Reeling RPC'd to every peer** (a correctness requirement, P9/§6, not polish).
- **[[Dungeon Generation]]** — room theme drives gimmick read; spawn table is biome-keyed.

## Demo scope vs Horizon

**DEMO (Pillar Zero + One, P7 cut-line):**
- Hedgemother thorn-arena seal + **phase-3 hedge-sprite summon** (the spec-05 gap). [DEMO]
- Burrow Boar **tusk-quake** phase in the Pale Veins. [DEMO]
- **Poise / stance-break + Reeling + Wayfinder's Mark** — the one reading mechanic. [DEMO]
- One new trash kind (**Hedgewight**) + Pale-Veins spawn table + flavored affix twins. [DEMO]
- Stagger + death-flourish + HP-bar ghost-trail (pure feel). [DEMO]
- Trophy-ritual Ledger boon on the Boar tusk (small, flat, capped — the one itemization verb). [DEMO]

**HORIZON (named, NOT built):** Rally (the plan picks Poise *or* Rally — Poise); living-pack rival-kind AI / turf-wars ([[Monster Hunter World]] flavor); behavior affixes; Wolf phase-3 add; per-mob AI states; the Deepening ladder's density scaling; any new boss (forbidden — P6). **No King of Brambles, ever; no new weapon class or gear tier, ever.** The Summit ships only as the scaled `hedgemother_v2`, quieted.

## Implementation notes (Godot)

- **`scripts/boss.gd`** — add `poise/poise_max/_recovery_t/_reeling_t`, `in_recovery_window()`, set `_recovery_t` in `_resolve_attack()`, branch the AI on `_reeling_t`. Per-boss `poise_max` from `BOSS_KINDS`. Hedgemother summon: spawn 2 hedge_sprites at phase-3 entry (reuse `layout_loader._spawn_enemy`).
- **`scripts/combatant.gd`** — Poise gain hooks into `take_damage` (check the boss's recovery flag before crediting). Tusk-quake reuses `_make_telegraph` + an AoE tick.
- **`scripts/layout_loader.gd`** — add `hedgewight` to `ENEMY_KINDS`, a `burrow`/Pale-Veins `SPAWN_TABLES` entry, `poise_max` to `BOSS_KINDS`.
- **`data/elites.gd`** — unchanged for demo (four modifiers suffice); new modifiers are Horizon.
- **Tests:** `test_skills.gd` guards the hotbar/Mark-finisher dispatch (the suite that catches a dead keypress); `test_wyrd_dungeon_scene.gd` guards spawn/boss build; add a headless Poise-build + Reeling assertion to `test_wyrd_loop.gd`. Run all with `WYRD_NO_SAVE=1`. Balance-sim **script (on demand, not a gate, P10)** checks boss TTK + Poise pacing stays in the cozy band.

## Open questions

- Should Poise be **visible from fight start** or unlock-on-first-Reeling (less UI noise, more discovery)?
- Does the Mark finisher's **cooldown reset** over-trivialize the skill loop, or is that the intended power-fantasy beat?
- Tusk-quake tile-denial vs. cozy "always allow retreat" — does a denied tile ever trap the player against the seal?
- Co-op: does Poise build from **all peers' arrows pooled**, or per-shooter? Pooled is cozier; per-shooter rewards the reader.

## See also / Sources

- [[Enemies]] · [[Bosses]] · [[Combat]] · [[Huntcraft]] · [[Charts]] · [[Affixes]] · [[Chart Loop]] · [[Multiplayer Co-op]] · [[Balance Philosophy]] · [[Universe Build-Out Plan]]
- Game refs: [[Sekiro Shadows Die Twice]] (posture/stance-break), [[Monster Hunter World]] (part-driven loop, SOS co-op), [[Hades]] (run-authored difficulty), [[Dark Souls]] / [[Elden Ring]] (trophy-as-second-journey), [[Hollow Knight]] (one-verb melee).
- Code: `wyrd/scripts/combatant.gd`, `wyrd/scripts/boss.gd`, `wyrd/scripts/layout_loader.gd`, `wyrd/data/elites.gd`.
