# 17 — Hedgemother boss fight (phase machine)

> **Outcome**: the Hedgemother stops being a big melee dummy and becomes a real boss — an HP-gated phase machine with telegraphed attacks and a sealed arena, ported (as a vertical slice) from the three.js spec-05 boss.

## Why

She's the climax of the shareable-demo milestone (agreed in the grill). Right now `combatant.gd` runs her as a scaled-up melee enemy — chase, melee, die. Spec 05 built a real Hedgemother in three.js (`src/game/bosses.js`): phases, telegraphed attacks, a room that seals. This spec ports that loop to Godot at vertical-slice fidelity — enough to feel like a boss, not a 1:1 port of every tuning value.

## Scope

**In:**
- A **`boss.gd`** — drives the Hedgemother. Either extends `combatant.gd` or composes it (keeps HP, hurtbox, death). Adds:
  - **3 HP-gated phases** — e.g. 100–66% / 66–33% / 33–0%. Each phase changes attack cadence / which attacks are used.
  - **Telegraphed attacks** (2–3): a wind-up tell (ground decal or the scale/tilt telegraph), a brief delay, then the hit. Candidates from spec 05: a **thorn-sweep** (radial AoE around her), a **root-stomp** (a targeted AoE at the player's position), a **summon** (spawn 1–2 minor enemies). v1 picks the 2–3 that port cleanly.
  - Attacks damage the player via the spec-15 `take_damage` path.
- **Arena seal** — when the player enters the boss room, the entry seals (a wall/gate); it opens when she dies. Reuse the procgen boss-room data.
- A **boss HP bar** — a banner-style bar at the top (distinct from the player HUD), shown on aggro.
- Death → the seal opens + a victory beat.
- Eval coverage in `test_combat.gd` — phase transitions fire at the HP gates, a telegraphed attack damages the player, the seal opens on death.

**Out:**
- A 1:1 port of spec-05's exact numbers / every attack.
- New attacks beyond what ports cleanly.
- Multi-phase arena geometry changes, adds, environmental hazards.
- Cutscenes / dialogue.
- Loot / rewards.

## Files

| Path | Action |
|---|---|
| `godot/scripts/boss.gd` | new — phase machine + telegraphed attacks |
| `godot/scripts/combatant.gd` | modify — hooks for the boss to reuse HP/hurtbox/death |
| `godot/scripts/layout_loader.gd` | modify — spawn the boss via `boss.gd`; arena seal gate |
| `godot/scenes/BossBar.tscn` + `boss_bar.gd` | new — boss HP banner |
| `godot/scenes/World.tscn` | modify — add the boss bar |
| `godot/test_combat.gd` | modify — boss-phase evals |
| `docs/GODOT_PIPELINE.md` | modify |

## Acceptance criteria

1. Entering the boss room seals it; the seal opens when she dies.
2. The Hedgemother cycles telegraphed attacks — each has a readable wind-up before the hit.
3. Crossing an HP gate visibly changes her behaviour (cadence/attack set).
4. Her attacks damage the player (HP drops, feedback fires).
5. A boss HP bar shows and drains.
6. `test_combat.gd` — spec 14/15 checks still pass + the boss-phase checks pass.
7. Boots clean; the fight runs without errors.

## Open decisions

- **`boss.gd` extends vs composes `combatant.gd`** — recommend **extends** (inherits HP/hurtbox/death/flash; overrides the AI). 
- **Which 2–3 attacks** — recommend thorn-sweep (radial) + root-stomp (targeted) for v1; summon if cheap. Confirm in the grill.
- **Telegraph form** — ground decal vs the scale/tilt tell. Recommend a flat ground decal (`Decal` or a tinted quad) for AoE attacks — it shows the danger zone; readability is the point.
- **Arena seal** — a rising wall segment at the room entry vs an invisible blocker. Recommend a visible wall segment.

## ARPG inspiration

Lean on FATE / Diablo boss conventions: a **sealed arena**, **phases** that
escalate, and **telegraphed AoE** the player reads and dodges — the danger
zone is shown *before* the hit lands. The fight should be about reading and
reacting, not stat-checking.

## References

- Spec 05 + `src/game/bosses.js` — the three.js Hedgemother (reference, not 1:1)
- `combatant.gd`, `layout_loader.gd` `_build_boss`, `test_combat.gd`
- Spec 15 — `take_damage`, AI patterns

## Done check

- [ ] `boss.gd` — 3 HP-gated phases
- [ ] 2–3 telegraphed attacks that damage the player
- [ ] Arena seal on entry, opens on death
- [ ] Boss HP bar
- [ ] Eval coverage; all combat evals pass
- [ ] No boot/runtime errors
