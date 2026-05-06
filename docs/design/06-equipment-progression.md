# Equipment progression — research and design notes

> **Backlog item #6.** Goal: make weapon variety, set bonuses, and the tier
> curve feel intentional rather than flat-stat-bumps.

---

## 1. Current state in our codebase

`src/data/items.js` has 22 entries with `equipBonus`. Tier ladder, by metal:

| tier | metal | weapon stats (atk/str/def) | armor stats (def) |
|---|---|---|---|
| 1 | Brindle | sword 1/2/0 · dagger 2/1/0 | leather body 0/0/2 |
| 2 | Bogiron | sword 2/4/0 · dagger 4/2/0 · cuirass 0/0/4 | shield 0/0/2 |
| 3 | Cinderbloom | sword 3/6/0 · dagger 6/3/0 · plate 0/0/6 | shield 0/0/3 |

Weapon stat-class signature (from the existing data):
- **Sword** = atk:str = 1:2 (str-leaning, average)
- **Dagger** = atk:str = 2:1 (atk-leaning, fast)
- **Axe** = (no atk/str hooked yet — `tool: 'axe'` is a *gathering* tool)

Armor: only `body` and `shield` slots are wired. No helmet / legs /
gloves / boots / cape entries with stats.

So the progression is **clean and linear** — each tier is +50% stats
across the board with the same archetypes. This is fine as scaffolding
but is exactly the "vertical-only" progression the wiki cautions
against.

## 2. Wiki principles

### `games/power-progression.md`

> "**Vertical progression** — strictly more powerful (higher stats, better
> gear, more health). **Horizontal progression** — more options without
> being strictly stronger. Most games blend both: vertical provides the
> compulsion-loop drive, while horizontal provides variety and player
> expression."

Bramblewood currently has **only vertical** progression on equipment. The
sword/dagger split is a horizontal axis but it's identical at every
tier (always atk:str = 1:2 vs 2:1, just bigger numbers). That's not
horizontal progression — that's a vertical scale with two flavors.

> "Curve types: linear, exponential, logarithmic, S-curve. **S-curve** is
> typical RPG: slow start, rapid mid-game, plateau."

Our +50% per tier is exponential-ish on aggregate stats. An S-curve
would be: tier 1 → 2 doubles (steep climb), tier 2 → 3 +50%, tier 3 → 4
+25%, etc. That keeps late-game gear meaningful but doesn't power-creep
out of control.

### `games/game-balance.md`

> "Balance means everything is **viable** — options should be different
> but comparably useful. If everything is equal, you've collapsed the
> decision; if one option dominates, you've collapsed it the other way."

For weapons specifically: at a given tier, the sword and dagger should
be ROUGHLY equally good but for DIFFERENT situations. Currently
sword's str advantage just means more flat damage; dagger's atk
advantage means slightly higher hit-chance. Both end up dealing similar
DPS in practice — they're not differentiated enough to drive a real
choice.

### `games/game-economy-design.md` (referenced)

> "Set bonuses are a **horizontal lever** that ties items together
> without adding raw power."

A 4-piece tier-2 set giving +1 bonus skill XP is horizontal — it
incentivizes wearing the matching set without making the player
unbeatable.

---

## 3. Reference games to study

| game | technique | takeaway for Bramblewood |
|---|---|---|
| **OSRS — combat-style triangle** | Atk vs Str vs Def "stance" applied to damage type. Wears a Whip → can pick which combat style modifies your XP gain | a per-weapon **combat style toggle** is horizontal; it changes which skill levels up, not damage |
| **Diablo 2 — affixes** | Same base item with different prefixes (Hawk's, Ferocious, etc.) | random affix table on dropped weapons — turns "another short sword" into "a short sword *of haste*"; we already have AFFIXES referenced in main.js |
| **Hades — Boons + weapon aspects** | Each weapon has 4 "aspects" that completely change how it plays | post-game horizontal: tier-3 weapons unlock 1 of 2 aspects |
| **Cult of the Lamb — fleeces** | One vertical slot ("weapon"), one horizontal slot ("fleece") that modifies playstyle | model: keep our weapon as vertical, add a **trinket slot** that's purely horizontal |
| **Stardew Valley — galaxy weapons** | One late-game tier above all others, plus a mythic-tier as a long-form goal | a single tier-4 "named" weapon as a quest reward (e.g. "The Lampwright's Iron") |

---

## 4. Open questions

1. **Do we want horizontal progression at all?** Bramblewood is cozy
   and short-arc. Maybe the linear ladder IS the right call (1-2 hours
   of content total = no time to develop horizontal mastery). But if
   we're aiming for a 10+ hour playthrough, horizontal is worth adding.

2. **Set bonuses or trinkets?** Two paths to horizontal:
   - **Set bonus**: 4-piece full-tier-2 outfit gives "+10% combat XP"
   - **Trinket slot**: separate equipBonus on a small accessory ("Apprentice's Hammer" already in items.js — repurpose as a trinket?)

3. **Affix system.** Code references `AFFIXES` already (main.js:40). Are
   they implemented or just stubbed? If implemented but unused, that's
   the easiest horizontal lever to turn on.

4. **Weapon-style differentiation.** Currently sword vs dagger is
   "slightly more str" vs "slightly more atk." If we want the choice to
   matter, the difference needs to be felt:
   - Dagger = +20% attack speed (faster CD), -20% damage
   - Sword = balanced
   - Axe (new) = -20% attack speed, +30% damage, AoE secondary attack

5. **Slot expansion.** Add helmet/legs/gloves/boots/cape with stats?
   Or stay with body+shield+weapon for cozy simplicity?

---

## 5. Recommended next steps

**Cheapest meaningful upgrade** (1-2 hours of work):

1. **Differentiate weapon classes** — change `equipBonus.atk/str/def` to
   meaningful divergence by weapon class, not just "+1 across the board":
   - Dagger: lower str but trigger a faster `attackCdFrames` bonus
   - Sword: balanced
   - Axe: highest str, slowest CD, +sweep AoE on power-swing
2. **Wire the existing AFFIXES** if they're implemented. ~5 affixes
   per weapon class is enough horizontal variety for an indie scope.
3. **One trinket slot + one tier-4 named weapon** as quest rewards.
   This is the minimum-viable horizontal lever.

**More ambitious** (1-2 days):

4. Set-bonus system: when player equips matching tier-2 cuirass + tier-2
   helmet + tier-2 shield, get +1 bonus skill (e.g. "Cinderbloom Set: +5
   max stamina").
5. Weapon aspects (Hades-style) for tier-3 weapons only — each tier-3
   weapon has 1 of 2 aspects unlocked via late-game quest.

**Smoke test** — for any change we make:

- [ ] Does this preserve viability of LOWER tier? (a tier-1 weapon should
      still be useful in early game; a player shouldn't feel forced to
      grind to tier-2 to clear early content)
- [ ] Does this differentiate WITHIN a tier? (sword vs dagger vs axe at
      tier 2 should each be "the best" for SOMETHING)
- [ ] Does this support BOTH playstyles? (a melee build + a magic build
      should both have meaningful tier-3 endgame gear)

---

## Sources

- `~/projects/research/wiki/games/power-progression.md`
- `~/projects/research/wiki/games/game-balance.md`
- `~/projects/research/wiki/games/game-economy-design.md`
- `src/data/items.js`
- `src/data/affixes.js` (referenced in main.js)
- `src/game/inventory.js`
