# Spell system — research and design notes

> **Backlog item #10.** Goal: review the 22-spell rune-magic system, fix any
> broken cast handlers, balance damage vs cost across the tier curve.

---

## 1. Current state in our codebase

`src/game/spells.js` (282 lines) — Phase B catalog. Sample shape:

```js
wind_strike: { id, name, element: 'air', tier: 1,
  reqLevel: 1, range: 6, minDmg: 3, maxDmg: 6, effect: 'damage',
  cost: { air: 1, mind: 1 }
}
```

Categorical breakdown (from grep):

- **Common attacks** (4): wind_strike, water_strike, earth_strike, fire_strike — tier 1, reqLevel 1-13, range 6, increasing damage by element
- **Utility** (variable): sense_aggro, quench_stamina, ignite, quiet_thought, stone_skin, ...
- **Buffs** (variable): stone_skin, ...
- **Travel** (variable): teleport-related per `cosmic` rune
- **Tier-2 attacks** (variable): chaos-rune-fueled
- **Nature** spells, **Risk** spells, **Endgame** unique-named

Cost system: rune items consumed per cast. Reference `ITEMS` for rune resources.

Cast effect dispatch:
- `effect: 'damage'` → rolls dmg in `[minDmg, maxDmg]` against locked target
- `effect: 'utility' / 'buff' / 'travel'` → custom handler in main.js keyed off spell.id

So we have **scaffolding for 21 spells** (the doc said 22 — actual count is **21**, corrected during deep-dive iteration 5) but each non-damage spell needs a custom handler.

### 1a. Spell handler audit (added during deep-dive iteration 5)

Audit pass against `src/main.js:4691` (`runUtilitySpell` switch) for every spell with `effect: 'utility' / 'buff' / 'travel'`. Damage spells (7) flow through the combat dispatcher and don't need a custom handler.

#### ✅ Wired and working (8)

| spell | tier | status |
|---|---|---|
| wind_strike | 1 | damage — uniform combat path |
| water_strike | 1 | damage |
| earth_strike | 1 | damage |
| fire_strike | 1 | damage |
| wind_wave | 2 | damage |
| water_wave | 2 | damage |
| deaths_whisper | 3 | damage |
| teleport_bramblewood | 3 | utility — teleports player.x/y to spawn ✅ |

#### ⚠️ State-only — handler runs but nothing reads the flag (4)

| spell | tier | bug |
|---|---|---|
| sense_aggro | 1 | sets `player.senseAggroT` — **no minimap reader exists**. Spell appears to do nothing. |
| stone_skin | 1 | sets `player.stoneSkinT` and logs "+30% defence" — **defence never multiplied anywhere**. False advertising. |
| vigor | 2 | sets `player.vigorT = 10` for HoT — **no per-frame HoT tick reads it**. Heal never happens. |
| teleport_chartmaker | 3 | gated on `CHARTMAKER_TILE` const which may or may not exist depending on world scope. Likely works in dungeon context, breaks elsewhere. |

#### ❌ Explicit stub — logs "not yet wired (Phase C)" (8)

| spell | tier |
|---|---|
| ignite | 1 |
| quiet_thought | 2 |
| levitate | 2 |
| bind_plant | 2 |
| animal_sight | 2 |
| holdinghut | 3 |
| blood_pact | 3 |
| soul_bind | 4 |

#### ❌ Broken — runtime bug (1)

| spell | tier | bug |
|---|---|---|
| quench_stamina | 1 | handler reads/writes `player.stamina.cur` and `.max` — **but `player.stamina` is a NUMBER** (see `player.js:52`), not an object. The math evaluates to `NaN`. Spell appears to consume runes and do nothing. |

#### Summary

Of 21 spells in the catalog, only **8 are fully wired** (7 damage + Bramblewood teleport). 13 are broken to varying degrees. **The "22-spell rune magic system" the doc described is mostly scaffolding** — only the damage spells and one teleport survived the move from spec to implementation.

This is significantly worse than the doc anticipated. The Phase 1 audit reveals a much bigger fix-pass than the doc implied.

## 2. Wiki principles

### `games/game-balance.md`

> "Numeric tuning. Adjusting values until options feel comparably viable.
> Baseline metrics. Data-driven iteration. **5-10% adjustments are often
> sufficient.**"

For damage spells: each tier-1 elemental should be ROUGHLY equally
viable, just at different reqLevels. Currently:
- Wind: reqLevel 1, dmg 3-6 (avg 4.5)
- Water: reqLevel 5, dmg 4-8 (avg 6.0, +33%)
- Earth: reqLevel 9, dmg 5-10 (avg 7.5, +25%)
- Fire: reqLevel 13, dmg 6-11 (avg 8.5, +13%)

That's a **flattening curve** — diminishing returns per element. By
tier-2 spells, the choice should be based on situation (single-target
vs AoE vs DoT) not just damage.

### `games/power-progression.md`

> "Vertical progression... Horizontal progression... Most games blend
> both."

Rune magic is a perfect place for **horizontal progression**: you
unlock the spell catalog over leveling, but at any given level you have
3-5 spells with the SAME power level that differ in *application*.

> "Introducing new mechanics that reset the player's mastery."

Tier-2 spells should introduce a NEW interaction (DoT, AoE, status
effect) — not just a flat damage upgrade.

### `games/game-economy-design.md`

Rune costs are a **resource-loop integration point**. If runes are
gathered (mining, crafting), every cast is a tiny economic cost.
Important to ensure:

- Tier-1 runes are abundantly available (else combat magic is trivially gated)
- Tier-2 runes are meaningfully scarce (so the player chooses carefully)
- Endgame "unique" runes are quest-only (terminal beat)

---

## 3. Reference games to study

| game | magic system | takeaway |
|---|---|---|
| **OSRS — Magic** | 4 elemental tiers × 3 levels each + utility spells; rune costs; combat-style triangle | **The model we're already imitating.** Worth studying actual rune costs / damage at each tier to set our baseline. |
| **D&D 5e — Spell Slots** | Cast count limited per long rest; spells scale to slot level | per-day cast budget instead of per-rune; doesn't fit our "click-spend" loop |
| **Path of Exile — Spell Synergy** | Support gems modify base spells (Cleave + Multistrike + Critical Strikes) | the "support gem" pattern is post-game horizontal — not for v1 |
| **Hades — Casts** | One slot, one mechanic (placed beam), works alongside attacks | minimalism is OK — cozy game can ship with 8 spells, not 22 |
| **Tunic — Magic** | 4-spell build with limited slots; you pick 3 | **slot scarcity** as a balance lever — even with 22 spells in catalog, equip only 4 at a time |

---

## 4. Open questions

1. **Are all 22 spell handlers wired?** Likely some `effect: 'utility'`
   spells point at functions that don't exist yet in main.js. Need to
   audit by spell.id.

2. **Casting interface.** Do players bind spells to slots like
   abilities, or open a spellbook and click? Currently looks like the
   latter (see `ui/spellbook.js`). Tradeoffs:
   - Slot-bound → fast, but UI takes slots that abilities want
   - Spellbook → discoverable but slower, breaks combat flow

3. **Rune economy.** Are runes obtained by:
   - Mining (rune_air, rune_earth ores) — which means magic is gated by Mining skill?
   - Buying from a shop — flat cash gate?
   - Quest rewards only — extreme scarcity?
   
   The choice ties magic to the broader economy.

4. **Magic skill.** `skills.js` has `magic` as one of 13 skills. How does
   it grow? What unlocks at what level? Currently each spell has its own
   reqLevel — the skill tree IS the spell catalog.

5. **Spell cost tuning.** A wind_strike costing 1 air + 1 mind rune
   gets you 3-6 damage. At what mining level does the player produce
   1 mind rune? Is this gated by levels in TWO skills now?

6. **Endgame "unique" spells.** Do these exist in the catalog yet, or
   are they stubs?

---

## 5. Recommended next steps

**Phase 1 — audit** (no code changes, ~1h):

1. **List all 22 spell ids + their effect types** from spells.js.
2. **For each `effect: 'utility' / 'travel' / 'buff'`, check main.js** for
   the corresponding handler. Mark each spell: ✅ wired, ⚠️ stub, ❌ missing.
3. **Print the rune economy** — what each spell costs, what each rune
   costs to obtain.
4. **Test cast each damage spell** — confirm range / damage / target lock works.

**Phase 2 — fix** (small code changes):

5. **Implement missing utility handlers** for any ❌ marked above.
   Priority order: combat utility (sense_aggro, stone_skin) → travel
   (teleport) → flavor (ignite for cooking).
6. **Fix any broken casts** identified by playtest.

**Phase 3 — tune** (data-only):

7. **Apply 5-10% adjustments** per the wiki, to bring underused spells
   in line.
8. **Audit rune costs** vs gather rates — confirm tier-1 rune supply >
   tier-1 spell cast rate.
9. **Cap the spell list at 8-10 v1 spells** (cozy scope) and demote the
   other 14 to "v2 catalog."

**Phase 4 — late-game:**

10. **Design endgame quest spells** (1-3 unique-named spells) tied to
    boss/quest rewards. These are the *terminal beat* of magic
    progression.

**Smoke tests:**

- [ ] Every spell in the v1 catalog has a working handler
- [ ] At magic level 1, the player has at least 1 castable damage spell
- [ ] At magic level 20, the player has 4-5 viable spells across categories
- [ ] Rune costs scale with spell power (tier-2 spell costs ≥ tier-1)
- [ ] No spell is strictly worse than another (the wiki "viable options"
      principle)

---

## Sources

- `~/projects/research/wiki/games/game-balance.md`
- `~/projects/research/wiki/games/power-progression.md`
- `~/projects/research/wiki/games/game-economy-design.md`
- `src/game/spells.js`
- `docs/rune-magic-design.md` (referenced by spells.js header comment)
- `src/ui/spellbook.js`
