# Design-doc deep-dive loop — progress tracker

Self-paced iteration over the 5 design docs. One doc per iteration. Each
iteration logs: what I read, what I shipped, what's still gated on user input.

---

## Iteration 1 — `05-boss-design.md` (DONE)

**Read:** full doc (boss infrastructure summary + wiki principles +
references + open questions).

**Shipped:**
- Audited existing boss-tagged enemies in `src/game/enemies.js`. Three
  bosses already exist: Hedgemother, Burrow Boar, Wolf Alpha. Documented
  HP / atk / def / maxHit / mechanic / drops / log line for each in a new
  §1a "Existing boss audit" table in the doc.
- Identified that the cheapest meaningful upgrade is **differentiating
  the three existing bosses** rather than writing a new one. Listed one
  unique-mechanic candidate per boss (Hedgemother bramble-root, Burrow
  Boar burrow-emerge, Wolf Alpha pack-summon).

**Code changes:** none in this iteration. The audit was the deliverable.

**Gated on user input:**
- Q: do we want to ship the unique-mechanic polish on the 3 existing
  bosses, OR park bosses entirely until v2, OR design a new narrative-
  driven boss instead (Eldra's vigil / Withering's last hunt)?

**Surfaced for user decision at end of loop.**

---

## Iteration 2 — `06-equipment-progression.md` (DONE)

**Read:** full doc.

**Shipped:**
- Discovered `AFFIXES` is for **dungeon charts**, not weapon mods (the doc had assumed otherwise — corrected my mental model).
- Implemented Phase 1's **weapon-class differentiation**:
  - Added `weaponClass` / `cdMul` / `dmgMul` fields to all 6 sword/dagger items in `src/data/items.js` (3 tiers × {sword, dagger}).
  - Sword: `cdMul=1.0, dmgMul=1.0` (baseline)
  - Dagger: `cdMul=0.75, dmgMul=0.80` (25% faster swings, 20% less damage per hit ≈ 6% more single-target DPS but with more crit-roll opportunities)
- Wired the modifiers into `src/game/combat.js`:
  - New `weaponMods(player)` helper reads the equipped weapon's class/cdMul/dmgMul (defaults to fist baseline if unarmed).
  - `rollPlayerSwingDetailed` scales `maxHit` by `dmgMul`.
  - `applySwing` scales `attackCd` by `cdMul`.

**Code changes:**
- `src/data/items.js` — 6 weapon entries gained class/cdMul/dmgMul fields
- `src/game/combat.js` — new `weaponMods()` helper + applied at swing roll + swing cooldown

**Gated on user input:**
- Q: do we add a combat-axe family (currently axes are only `tool: 'axe'` for woodcutting)? Doc proposed `cdMul=1.40, dmgMul=1.30` + AoE on power-swing.
- Q: should AFFIXES be extended to apply to weapons too (random suffixes like "Brindle Sword *of Haste*")? Currently they only apply to dungeon charts.
- Q: trinket slot? tier-4 named weapons?

**Smoke test (manual play required):**
- [ ] Equip Brindle Sword: same swing cadence as before (no regression)
- [ ] Equip Brindle Dagger: visibly faster swings, smaller damage numbers
- [ ] Verify equal-ish DPS in a single-target fight

---

## Iteration 3 — `07-skill-level-pacing.md` (DONE)

**Read:** full doc.

**Shipped:**
- Discovered the actual `xpForLevel` formula in `src/data/config.js:79` is `(n-1)² * 8` — **quadratic**, not exponential. The doc had assumed it was OSRS-style exponential; corrected.
- Computed the actual curve: level 25 = 39,200 cumulative XP = ~3.6h of combat grind at 12 xp/kill. Level 99 = 2.55M XP = ~236h.
- Added §1a "Measured curve" to the doc with the full table (levels 2-99) and three candidate Phase 2 curves to discuss.

**Code changes:** none — Phase 1 is a measurement step per the doc's own structure.

**Key insight:** the doc had the *wrong diagnosis* (assumed exponential grind). Real issue is the LOW end is too fast (level 2 in 3 seconds). High end is already gentler than OSRS.

**Gated on user input:**
- Q: cap at 25 (matches existing 3.6h-to-cap)? Or 50 (30h)?
- Q: which Phase 2 curve candidate? (current quadratic, +50% bump, or "linear floor"?)
- Q: combat XP source — keep "scales with damage dealt" or also award flat per-kill?
- Q: HP scaling change with new cap?

---

## Iteration 4 — `09-active-abilities.md` (DONE)

**Read:** full doc.

**Shipped:**
- Pulled the full 12-ability roster + their tree / reqLevel / cooldown into a §1a audit table in the doc.
- **Discovered the structural bias:** the default `SLOT_BINDINGS` was `cleave / leap / rend / whirlwind` — all 4 from the **atk tree**. 8 of 12 abilities (str/def/hp trees) were catalog-only on a fresh save unless the player opened the rebind UI in `ui/spellbook.js`.
- **Verified safe to change:** `abilities.js:694` resolves `player.actionBar?.[slot-1] || SLOT_BINDINGS[slot]` — saved bindings override defaults, so existing saves are unaffected.
- **Shipped:** rebalanced default `SLOT_BINDINGS` to one-per-tree:
  - Slot 1: `cleave` (atk lv 5) — kept (early-game starter)
  - Slot 2: `shield_bash` (def lv 8) — was `leap`
  - Slot 3: `bull_rush` (str lv 10) — was `rend`
  - Slot 4: `last_stand` (hp lv 25) — was `whirlwind`
- New players will now encounter the breadth of the catalog by default; veterans keep their saved bindings.

**Code changes:**
- `src/game/abilities.js` — `SLOT_BINDINGS` rebalanced + documented.

**Gated on user input:**
- Q: do we add 2-3 more abilities to fill underrepresented trees (str has 2, hp has 1)? Or accept the current distribution?
- Q: do we instrument slot-binding telemetry to validate via playtest?

---

## Iteration 5 — `10-spell-system.md` (DONE — final iteration)

**Read:** full doc.

**Shipped:**
- Counted actual spell defs (21, not the 22 the doc claimed — corrected).
- For each utility/buff/travel spell, traced the dispatch through `main.js:4691` `runUtilitySpell` switch and checked whether the side-effect flag is *read* anywhere.
- Built §1a "Spell handler audit" with a 4-bucket categorization:
  - ✅ Wired and working: **8** (7 damage + Bramblewood teleport)
  - ⚠️ State-only (flag set but no reader): 4 (sense_aggro, stone_skin, vigor, teleport_chartmaker)
  - ❌ Explicit stub ("Phase C"): 8 (ignite, quiet_thought, levitate, bind_plant, animal_sight, holdinghut, blood_pact, soul_bind)
  - ❌ Broken — runtime bug: 1 (`quench_stamina` writes to `player.stamina.cur` but stamina is a number — NaN)
- **Headline finding: only 8 of 21 spells actually do anything.** 13 are broken to varying degrees. This is significantly worse than the doc estimated.

**Code changes:** none — Phase 1 was an audit pass.

**Gated on user input:**
- Q: prioritize fixing the 4 state-only spells first (cheap — 1 reader each)?
- Q: cut the 8 stubs from the v1 catalog (down to ~13 spells) per the doc's "demote to v2 catalog" recommendation?
- Q: fix the `quench_stamina` bug (5-line change) or cut it?
- Q: spellbook UI — is it still listing the broken ones?

---

# Loop complete — final summary

All 5 docs deep-dived. 2 code changes shipped (weapon-class differentiation + slot-binding rebalance). 3 audit passes added to docs (boss audit, XP-curve measurement, spell-handler audit). All flagged user-input questions are listed per-iteration above.

---

# Iteration 5b — spell-system follow-up (DONE 2026-05-04)

**Driver:** the iteration-5 audit found 13 of 21 spells broken. User asked to tackle the big-ticket gaps. Followed up directly.

**Shipped:**
- **Fixed `quench_stamina`** (`src/main.js`): was writing `.cur`/`.max` on a primitive number → silent NaN. Now restores `min(staminaMax, before+30)` and lifts the exhausted lockout if stamina goes positive. Logs the gain.
- **Wired `stone_skin` reader** (`src/game/combat.js:236`): added `if (player.stoneSkinT > 0) dmg = max(1, floor(dmg * 0.7))` next to the existing defensive-stance reader.
- **Wired `vigor` heal-over-time** (`src/game/player.js:163`): added a `vigorAcc` accumulator + tick that adds `3 * dt` HP/sec while `vigorT > 0`, capped at `hpMax`. Verified: 1s synthetic tick → +3 HP.
- **Wired `sense_aggro` minimap reader** (`src/main.js:1140`): aggroed enemies are now drawn on the minimap regardless of fog/vis while `player.senseAggroT > 0`. Sense-only dots get a soft red halo so the player can tell which dots are LOS vs spell-revealed.
- **Per-frame timer ticks** (`src/game/player.js:163`): `stoneSkinT`, `senseAggroT`, `vigorT` all decrement in `updatePlayerMovement` alongside `defensiveT`/`riposteT`.
- **Stubbed 8 unimplemented spells** (`src/game/spells.js`): added `stub: true` to ignite, quiet_thought, levitate, bind_plant, animal_sight, holdinghut, blood_pact, soul_bind. `castSpell` short-circuits with "<name> isn't implemented yet" before spending runes. Spellbook UI gives them a hatched background + "COMING SOON" badge so players don't try them.

**Verified working** (synthetic-tick test in browser):
- stoneSkinT 5 → 4 after 1s
- senseAggroT 60 → 59 after 1s
- vigor: hp+3, vigorT 10 → 9, accumulator drained to 0
- ignite stub returns `{ok: false, reason: "Ignite isn't implemented yet."}`

**State:** 13 of 21 spells now actually do something (up from 8). 8 are explicitly demoted to v2 with no path to fire — clean for users. `teleport_chartmaker` was already working (the audit incorrectly flagged it; module-scope const works as intended).

