# Active abilities — research and design notes

> **Backlog item #9.** Goal: review the slot-based active abilities,
> balance their cooldowns vs power, decide on additions per level milestone.

---

## 1. Current state in our codebase

`src/game/abilities.js` (729 lines) defines:

- **SLOT_BINDINGS** — keys 1-4 map to ability ids
- **12 abilities defined**: cleave, rend, whirlwind, leap, shield_bash, defensive_stance, sunder, bull_rush, backstab, aimed_shot, riposte, last_stand
- Tree categorization (from naming): `atk` tree (cleave, rend, sunder, bull_rush, backstab, aimed_shot), `str` tree (whirlwind, leap), `def` tree (shield_bash, defensive_stance, riposte, last_stand)

Public API:
- `tryActivate(player, slot, ctx)` — main entry
- `isAbilityUnlocked(player, id)` — level gate
- All effects route through existing combat formulas

So the engine + 12 abilities exist. The **balance questions** are:
- Which abilities are over/underperforming?
- Are there meaningful tier-3 abilities to chase?
- Do players actually use slots 3-4, or default to 1-2 for most fights?

### 1a. Full ability audit (added during deep-dive iteration 4)

| ability | slot (default) | tree | reqLevel | cooldown |
|---|---|---|---|---|
| `cleave` | **1** | atk | 5 | 5s |
| `leap` | **2** | atk | 12 | 10s |
| `rend` | **3** | atk | 18 | 12s |
| `whirlwind` | **4** | atk | 25 | 20s |
| `shield_bash` | — | def | 8 | 8s |
| `bull_rush` | — | str | 10 | 12s |
| `defensive_stance` | — | def | 14 | 25s |
| `sunder` | — | str | 15 | 15s |
| `aimed_shot` | — | atk | 16 | 10s |
| `backstab` | — | atk | 20 | 14s |
| `riposte` | — | def | 22 | 18s |
| `last_stand` | — | hp | 25 | 60s |

**Two structural findings the doc missed:**

1. **The default `SLOT_BINDINGS` is all-atk-tree** (cleave / leap / rend / whirlwind). 8 of 12 abilities (def, str, hp trees) are catalog-only on a fresh save — the player has to **proactively rebind** to reach them. Players who never open `ui/spellbook.js`'s rebinding UI literally never see 2/3 of the ability roster.

2. **Atk tree has 6 of 12 abilities; str has 2; def has 3; hp has 1.** Heavily atk-biased catalog. A "tank" build is starved (only 3 def abilities). A "berserker" str build has 2 to choose from.

**Recommendation for Phase 1 polish (cheap, no playtest needed):**

- Change the default `SLOT_BINDINGS` to **one ability per tree**:
  - Slot 1: `cleave` (atk, lv 5) — keeps the early-game starter
  - Slot 2: `shield_bash` (def, lv 8) — introduces the defensive vocabulary
  - Slot 3: `bull_rush` (str, lv 10) — introduces str-tree
  - Slot 4: `last_stand` (hp, lv 25) — late-game panic-button slot
- Players still have the rebind UI for personal preference; this just means the *first encounter* with the slot bar shows the roster's breadth.

**Open question (still gated on user input):**
- Do we add 2-3 str / def / hp abilities to fill out the underrepresented trees, OR do we leave the catalog as-is and just rebalance defaults?

## 2. Wiki principles

### `games/game-balance.md`

> "Balance means **everything is viable**. Options should be
> different but comparably useful... great balance decisions generally
> increase the number of viable options."

For our 12 abilities specifically: at a given player level, are 3-4 of
them viable (i.e. someone slot-binds them) or do players gravitate to
the same 1-2?

> "**5-10% adjustments are often sufficient.** Large swings destabilize
> the metagame."

When we tune cooldowns or damage multipliers, change them by 1 second
or 10% damage at a time, not 50%.

> "**Asymmetric balance**: each option needs comparable win rates,
> distinct fantasy fulfillment, meaningful counterplay."

For us: cleave should feel different from whirlwind even though both
hit multiple enemies. The fantasy difference matters as much as the math.

### `games/power-progression.md`

> "**Horizontal progression**: more options without strictly more
> power. Common at the unlock-cap of a skill tree."

Late-game ability unlocks should be **horizontal** — a level-30 ability
shouldn't just be "cleave but more damage." It should enable a new
playstyle (e.g. self-buff that costs HP, or a movement ability that
breaks line-of-sight for ranged enemies).

### `games/game-ai-decision-making.md`

> "Game AI prioritizes creating fun, believable behavior."

Applied to ability AI: enemies in our game don't currently react to the
player's ability use (they're simple chase-attack). A polish step would
be: when player uses defensive_stance, telegraph the enemy noticing it
and changing to a different attack.

---

## 3. Reference games to study

| game | ability system | takeaway |
|---|---|---|
| **OSRS — Special Attacks** | Each weapon has 1 special attack with a cost (special-bar) | weapon-specific specials are horizontal — not just "all swords get cleave"; tied to gear instead of skill tree |
| **Hades — Casts and Specials** | One mouse button = base attack; one = "special"; one = cast (consumable). Each weapon defines what these are. | the **"verb-per-weapon"** pattern. Maybe slots 3-4 should be weapon-bound, not skill-bound? |
| **Diablo 4 — Skill tree with cap** | 6 active slots, 30+ abilities, but you pick at most 6 | **slot scarcity** is a balance lever. We have 4 slots which is good for cozy. |
| **Path of Exile** | More abilities than slots, encouraging build identity | players develop a "build" — the act of slot-choosing is a meta-game |
| **Hollow Knight — Charms** | Equip-cost system: each charm costs 1-3 charm-notch; total notches grow over the game | per-ability **stamina cost** OR **charm-notch system** = both work; latter is a budget you grow into |

---

## 4. Open questions

1. **Are the existing 12 abilities all viable?** Need playtest data. Educated guess: cleave, leap, riposte are in everyone's slot bar; rend, sunder, last_stand are rarely picked.

2. **Should abilities scale with skill level?** Currently they have unlock requirements but flat damage. A per-level multiplier (e.g. cleave damage = baseDmg * (1 + 0.05 * skill_level)) makes leveling matter for slotted abilities, not just unlocks.

3. **Cooldown vs cost.** Currently abilities are on per-slot cooldowns. Adding stamina costs would gate them by stamina pool too. (Note: we considered + reverted stamina-cost-on-swing for normal attacks. Stamina cost on ABILITIES is different — abilities should cost something to keep slot-binding meaningful.)

4. **Slot 3 / 4 utilization**. Most ARPG-style players use slots 1-2 most often. Slot 3/4 should be **higher-impact, longer-cooldown** abilities (the "panic button" reflex slot).

5. **Late-game unlocks**. We have abilities up to certain skill levels, but no level-50+ unlocks. With a level cap of 25 (per #7), we don't need them. With a cap of 50+, we do.

6. **Weapon-bound vs skill-bound abilities**. Currently abilities unlock from skill levels. Hades-pattern would be: weapon determines slot 1 (base), slot 2 (special). Skills determine slot 3/4 (horizontal flavor).

---

## 5. Recommended next steps

**Phase 1 — instrument** (no code changes):

1. **Play 5 sessions, record slot bindings.** Which abilities did the
   player actually slot? If the same 3 are slotted every time, the other
   9 are dead content.
2. **Print the unlock-by-level table.** First ability unlock at level X,
   second at level Y, etc. Is the curve well-paced?

**Phase 2 — pruning + tuning** (small code changes):

3. **Cut or merge dead abilities.** If rend and sunder both show 0 slot
   uses across 5 sessions, merge them or cut one.
4. **Buff weak ones by 5-10%.** Per the wiki — small adjustments only.

**Phase 3 — fill the gap** (medium code changes):

5. **Add 2-3 weapon-bound special attacks** to slot 1 (Hades pattern).
   E.g. when wielding a dagger, slot 1 = backstab (already exists).
   When wielding an axe, slot 1 = cleave. Sword = sunder. Now slot 1
   is contextual, leaving slots 2-4 for tree-tree skills.

**Smoke test:**

- [ ] By level 10, the player has 4 unlocked abilities
- [ ] By level 25 (cap), the player has 8+ unlocked
- [ ] Across a 1-hour session, the player uses ALL 4 slot-bound abilities at least once
- [ ] No slot is "wasted" (a level-1 ability still in slot 4 because no upgrade exists)

---

## Sources

- `~/projects/research/wiki/games/game-balance.md`
- `~/projects/research/wiki/games/power-progression.md`
- `~/projects/research/wiki/games/game-ai-decision-making.md`
- `src/game/abilities.js`
