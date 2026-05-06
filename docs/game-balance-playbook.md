# Game Balance Playbook

A condensed reference on how to balance a game — what balance actually means, the math, the process, and the genre-specific tuning. Biased toward single-player / cozy / RPG balance (gj26's mold), with PvP-specific notes where they apply.

This deepens what `mmo-game-design-playbook.md` §3 covered briefly. Pairs with `content-generation-playbook.md` (tier tables) and the `game-content-generator` skill (which produces tier-conforming content).

---

## 1. The three things people call "balance"

Conflating these is the most common balance discussion failure. Sirlin's distinction (foundational reading):

| Concept | What it is | Where it matters |
|---|---|---|
| **Fairness** | Players of equal skill have a roughly equal chance to win even with different starting options/characters/decks | PvP. Tournament play. Multiplayer. |
| **Viability** | A meaningful number of options remain *strategically viable* — not just "exist," but worth picking | PvE and PvP. Build diversity. |
| **Pacing** | Challenge tracks player progression — never too easy, never too hard | Single-player, PvE. Difficulty curves. |

You can have any one without the others:
- A **fair** game can have terrible viability if 90% of players converge on one strategy
- A **viable**-rich game (lots of working builds) can be unfair if some are 30% stronger
- A perfectly **paced** game can be fair *and* viable but tedious

Rule: **Identify which balance you're tuning before discussing how.** A "balance complaint" usually targets one of the three. Mismatched discussion is a waste.

### Bonus: depth (Sirlin's fourth concept)

> A game is **deep** if it remains strategically interesting after expert players have studied it for years.

Depth is balance's reward, not balance itself. Chess has deep balance because thousands of years haven't exhausted it. Tic-tac-toe is balanced (fair, options viable, paced) but trivially solvable — *zero depth*. When balancing, **try to increase depth, not decrease it**.

---

## 2. The math toolkit

The five numbers that govern every fight in every game:

| Symbol | Meaning | Formula (typical) |
|---|---|---|
| **DPS** | Damage per second | (avg damage per hit) × (hits per second) × (1 + crit chance × crit multiplier) |
| **EHP** | Effective HP (HP factoring damage reduction) | HP / (1 - dmg_reduction) — or HP × (1 + def/100) for stat-based |
| **TTK** | Time to kill | EHP / DPS |
| **Damage formula** | How attack vs defense produces output | See §3 below |
| **XP/HR** | XP per real-time hour at a given content level | (XP per kill) × (kills per hour) |

These five compose. Most balance failures come from one of them being out of band:
- DPS too high → trivial fights → boring
- EHP too high → infinite fights → tedious
- TTK weird → matches don't end / end too fast → both bad
- Damage formula wrong → nonlinear scaling → power creep
- XP/HR wrong → grind too fast (no weight) or too slow (quitting)

### Target TTK by genre

| Genre | Target TTK | Examples |
|---|---|---|
| Twitch shooter | 0.2–0.8s | CS, Valorant headshots |
| Action shooter | 1–3s | Halo, Apex |
| Action RPG | 2–6s for trash, 30s+ for elites | Diablo, ARPGs |
| Tactical RPG | 2–3 turns of focus | Fire Emblem, FFT |
| MMO trash mob | 3–8s solo | RuneScape, classic WoW |
| MMO boss | 2–10 min | WoW raids, FFXIV |
| Cozy combat (gj26) | 5–15s for trivial | Stardew slime, RS goblin |

Pick a TTK band per content tier, then back-solve DPS and EHP from it.

---

## 3. Damage formulas (pick one, stick to it)

Most damage formulas fall into three families. Each has different scaling behavior — the one you pick *defines* how power feels at high levels.

### A. Subtractive: `dmg = max(1, atk - def)`

Simple. Gear matters a lot at low levels, irrelevant at high. Used in classic JRPGs and OSRS pre-2007.

**Behavior:**
- Atk 5, Def 2 → 3 dmg (60% of attack)
- Atk 50, Def 47 → 3 dmg (6% of attack)
- Atk 50, Def 0 → 50 dmg (full)

**Pros:** intuitive. Defense visibly absorbs damage.
**Cons:** invertible by 1-point underlevel; once your attack catches up, defense is irrelevant.

### B. Multiplicative / divisive: `dmg = atk × atk / (atk + def)`  *or*  `dmg = atk × (1 - def / (def + K))`

Both are scale-invariant — atk-vs-def *ratios* matter, not absolute values. Used in League of Legends, Dota, modern RPGs.

**Behavior:**
- Atk 100 vs Def 100, K=100 → 50 dmg (50%)
- Atk 1000 vs Def 1000 → 500 dmg (still 50%)
- Atk 200 vs Def 100 → 133 dmg (66%)

**Pros:** works across power levels without breaking. No "1-point-underlevel = useless."
**Cons:** harder to intuit. Players need a damage tooltip to see the math.

### C. Roll-based: `dmg = roll(0..maxHit)` where `maxHit = f(atk, str)`

Used in OSRS post-2007. Damage is randomized between 0 and a derived max. Defense affects *hit chance*, not damage roll.

**Behavior:**
- Maxhit 10, hit chance 60% → avg 3 dmg per swing
- Higher def → lower hit chance, same maxhit when you do connect

**Pros:** less swingy than pure subtractive at low end (no whiffs feel like missed maxes); satisfying when max-hits land.
**Cons:** defense and offense are separate dimensions (more complex spreadsheet).

### Recommendation by genre

| Genre | Formula |
|---|---|
| Cozy / casual RPG | Subtractive (intuitive, OSRS-classic feel) |
| Competitive ARPG | Multiplicative (scales clean) |
| Roll-based MMO | Hybrid (subtractive maxhit + accuracy roll) |
| Tactical | Subtractive with floors (always hit for ≥1) |

For gj26: **subtractive with a floor of 1**. Matches the cozy / RuneScape-classic feel and is dead-simple to balance.

```js
function damage(atk, def) {
  return Math.max(1, atk - def + Math.floor(Math.random() * 3 - 1)); // ±1 jitter
}
```

---

## 4. XP curves — the spine of progression

Three families, each with different feels:

### Linear: `xp(L) = a * L`
Constant XP per level. Each level takes the same effort.
- **Feels like:** treadmill. Boring after level 10.
- **Used by:** rare. Mostly mobile clickers.

### Quadratic: `xp(L) = a * L²`
Each level needs more XP than the last.
- **Feels like:** natural difficulty. Most RPGs.
- **Examples:** classic JRPGs, Diablo II, EverQuest

### Exponential: `xp(L) = a * b^L` (b > 1)
Each level takes a multiplicative jump.
- **Feels like:** brutal late, brisk early. Classic OSRS pattern.
- **Examples:** RuneScape (b ≈ 1.104, hits 13M XP at level 99), Lineage II, Tibia

### The OSRS curve (gold-standard cozy RPG curve)

OSRS uses a piecewise-near-exponential:

```
xp(L) = floor(sum from i=1 to L-1 of: floor(i + 300 * 2^(i/7)) / 4)
```

Approximately exponential with `b ≈ 1.104`. The famous numbers:
- Level 50 → 101k XP
- Level 70 → 737k XP
- Level 90 → 5.3M XP
- Level 99 → 13M XP

**Why it works:** the curve flattens enough early (level 50 = milestone) that players feel mastery, but level 99 takes *months* of real time, making it the meaningful number that defines status (see `evoke-online-game-feel`, "earned mastery").

For gj26: use OSRS's curve directly, or a simplified version. Players who came up on RS will *feel* the right curve immediately.

### Translating XP to play-hours

Pick a target: how long should level 50 take a casual player?

```
hours_to_50 = xp(50) / (xp_per_hour at_level_25)
```

Example for gj26 woodcutting:
- Target: level 50 in ~10 hours of play
- xp(50) = 101k → need 10.1k XP/hr at level 25
- That's ~2.8 XP/sec average → ~28 trees per hour at 100 XP each → reasonable

If the math says 100 hours to level 50, your XP rate is too low. If it says 30 minutes, too high. Tune.

---

## 5. Stat scaling across tiers

Two approaches. Both work; pick deliberately.

### Linear tier scaling (current gj26 default)

Each tier adds a constant. Bronze +3, Iron +6, Steel +9, Mithril +12, Adamant +15, Rune +18.

**Behavior:**
- TTK against tier-appropriate enemies stays roughly constant
- Enemies at tier N+1 feel slightly harder than tier N (good)
- Old gear becomes obsolete quickly — drives crafting/economy

**Pros:** intuitive, easy to plan, makes new tiers feel like real upgrades
**Cons:** old gear *invalidates* (RuneScape mitigates with cosmetic prestige; modern WoW has the "borrowed power" problem)

### Multiplicative tier scaling

Each tier multiplies. Bronze x1, Iron x1.5, Steel x2.25, etc.

**Behavior:**
- Late-game power feels exponential
- Old content trivializes faster
- Drives "endgame is the only content that matters"

**Pros:** late-game numbers are dramatic and satisfying
**Cons:** old content becomes one-shot; balance audits get harder per patch

For gj26: stick with linear. Cozy game; players should be able to revisit early zones without obliterating mobs. (RS gets this right with combat-level matching.)

### Cross-stat scaling rules

For multi-stat scaling (atk + str + def all going up), keep ratios constant per role:

| Role | atk : str : def |
|---|---|---|
| Tank | 1 : 1 : 4 |
| Bruiser | 1 : 2 : 2 |
| DPS | 2 : 3 : 1 |
| Glass cannon | 3 : 4 : 0 |

These ratios should hold across tiers. If a role's ratio shifts as it gears up, balance breaks.

---

## 6. The balance loop — how to actually do it

For a game with no telemetry (i.e. early-stage / pre-launch / single-dev):

```
[ Define target TTK + XP/HR per content tier ]
              ↓
[ Math out stats from formulas (§2-3) ]
              ↓
[ Generate content via content-generation-playbook ]
              ↓
[ Playtest the *worst case* (max stat differential) ]
              ↓
[ Tune the formulas, not the individual numbers ]
              ↓
[ Repeat per tier ]
```

### The three test cases that catch 80% of balance bugs

1. **Underleveled fight** — player 5 levels below the content
2. **Overleveled fight** — player 5 levels above
3. **Spec-mismatch fight** — player using "wrong" stat distribution (e.g. high atk, no def, into a slow-but-hard-hitting boss)

If any of these is *binary* (always win / always lose), the formula is broken. The right outcome is "stretchy" — underlevel players can win with skill or items, overlevel players can lose with bad play.

### When to use math vs playtest

| Question | Math | Playtest |
|---|---|---|
| Does the curve of TTK across levels make sense? | ✅ math first | |
| Does this fight *feel* right? | | ✅ playtest |
| Will this build dominate? | First math screen, then playtest | |
| Is this skill cap fun? | | ✅ playtest |
| Are 3 builds viable or only 1? | First playtest, then math the loser to fix | |

Math is for catching out-of-band numbers. Playtest is for catching out-of-band *feels*. Need both.

---

## 7. Telemetry-driven balance (when you have data)

For shipped multiplayer games like Riot's LoL: balance is data-informed, not data-driven. They collect petabytes of player interactions but don't let data make decisions.

### The standard signals

| Signal | What it tells you | Good range |
|---|---|---|
| **Win rate** | Is this option overpowered/weak? | 48–52% per option (LoL target) |
| **Pick rate** | Is anyone choosing this? | Above ~3% — below means dead option |
| **Ban rate** (in PvP) | Players' fear signal | < 30% — high ban means oppressive |
| **Average match length** | Pacing | Stable across patches |
| **Match-end snowball %** (one team wins by minute X with 90% certainty) | Comeback potential | 65–80% — too high means snowball-y |
| **Player retention by content tier** | Where do players quit? | No cliffs |

### Cadence

LoL ships balance patches every 2 weeks. WoW does monthly. Smaller games go quarterly. Balance churn fatigues players if too fast; meta stagnation kills them if too slow.

**Rule:** patch cadence should be slow enough that a build/strategy can be learned and mastered, but fast enough that "metagame churn" creates content. 2–6 weeks is the sweet spot.

### What data can't tell you

- **Why** a build is dominant (only that it is)
- Whether a champion *feels* fun to fight against
- Whether a pacing issue is the cause or the symptom
- New-player experience (the dataset is biased toward survivors)

This is why even Riot's data-driven balance team relies heavily on developer instinct and pro feedback alongside the dashboards.

---

## 8. Without telemetry (the gj26 situation)

Pre-launch / solo-dev / cozy game balance has no live signals. Substitute these:

### A. Spreadsheet math
Build a sheet with every gear piece + enemy + skill. Plot DPS/EHP/TTK across player levels. Look for cliffs (sudden power spikes / drops).

### B. Pre-mortem playtests
Before content ships, role-play three player archetypes against it:
1. **The optimizer** — uses the best gear available, exploits the math
2. **The casual** — uses whatever they picked up, suboptimal stat distribution
3. **The narrative player** — ignores stats, picks aesthetic gear

If all three have a usable experience, balance is OK. If only the optimizer survives, fail.

### C. Friend playtest (the gold standard at small scale)
Ship a build to 3–5 friends. Watch (don't help). Note where they stall, where they fly. Time their kills. Their gut reactions are worth more than any spreadsheet.

### D. AI-assisted simulation
For larger combat systems, run 10,000 simulated fights of (player level X with gear Y) vs (enemy tier Z) and plot win rate distribution. Look for win-rate cliffs.

```js
// Sketch: brute-force sim
function simFight(player, enemy, n = 10000) {
  let wins = 0;
  for (let i = 0; i < n; i++) {
    const p = clone(player), e = clone(enemy);
    while (p.hp > 0 && e.hp > 0) {
      e.hp -= damage(p.atk, e.def);
      if (e.hp > 0) p.hp -= damage(e.atk, p.def);
    }
    if (p.hp > 0) wins++;
  }
  return wins / n;
}
```

If a fight has a 95-100% win rate, it's trivial. <10% = unwinnable. 40-70% per the player's tier = sweet.

---

## 9. Anti-patterns (the balance failure mode catalog)

| Anti-pattern | Symptom | Fix |
|---|---|---|
| **Power creep** | Every patch invalidates last patch's gear | Tighten budget per tier; sunset old tiers explicitly |
| **Dominant strategy** | One build/champ has >55% win rate | Buff alternatives until competitive; nerf is last resort |
| **Dead options** | Build/champ has <2% pick rate | Either delete or radically rework — *not* small buffs |
| **False complexity** | Many options that all approximate one strategy | Cut redundant options; differentiate the rest mechanically |
| **Math floor failure** | New gear in tier N is weaker than top gear in tier N-1 | Tier curves must monotonically increase |
| **No counter-play** | Strong option has no answer | Add a counter (rock-paper-scissors logic) or weaken the option |
| **Punitive randomness** | Outcomes feel random rather than strategic | Reduce variance OR add risk-management options |
| **Hidden math** | Players can't predict outcomes | Tooltips, damage numbers, formula docs |
| **Treadmill catch-up** | Daily mandatory grind to "stay relevant" | Make grind optional or rotate it (FFXIV pattern) |
| **Snowball locks** | Once ahead, you always win | Add come-back mechanics: rubber-banding, comeback gold, EXP catch-up |

---

## 10. Genre-specific tuning

### PvP balance (LoL, fighting games, CS)
- **Primary measure:** fairness across roles/champions
- **Tools:** patch cadence, pro feedback, ban rates, win rate dashboards
- **Hardest problem:** maintaining **viability** while keeping 50% win rates (LoL's eternal struggle)

### PvE balance (raids, MMOs, ARPGs)
- **Primary measure:** TTK-vs-difficulty curve at a given gear tier
- **Tools:** fight simulators, parsers (in shipped games), spreadsheets pre-launch
- **Hardest problem:** balancing for both bottom-50% groups and top-1% players in the same fight

### Cozy / single-player / RPG (gj26)
- **Primary measure:** pacing — does the difficulty curve feel right?
- **Tools:** math + small playtest groups
- **Hardest problem:** too generous and the game has no weight; too punishing and it stops being cozy
- **Sweet spot:** "always winnable, occasionally tense, never frustrating"

For cozy specifically, sub-rules:
- Never one-shot a player below 50% HP
- Always allow retreat (no force-fights from random encounters)
- Death = fade-to-bed-with-minor-penalty (see `cozy-life-sim-design-playbook.md` §7)
- Underleveled fights are *possible* with potions and skill, not gated

### Sandbox (EVE, Minecraft)
- **Primary measure:** emergent balance — can players' actions destabilize the system?
- **Tools:** post-hoc dev intervention, economy tracking
- **Hardest problem:** players *will* find dominant strategies. Question is whether the game tolerates them.

---

## 11. The gj26-specific application

Combining everything for gj26's actual situation:

| Decision | Recommendation | Source |
|---|---|---|
| Damage formula | Subtractive with floor of 1 + ±1 jitter | §3 — cozy / classic feel |
| Target TTK trivial mob | 5–8s | §2 — cozy combat band |
| Target TTK boss-tier (post-jam) | 30–60s | §2 |
| XP curve | OSRS-flavored exponential (b ≈ 1.104) | §4 — players know this curve |
| Tier scaling | Linear (current playbook) | §5 |
| Balance method | Math + spreadsheet + 3-friend playtest | §8 — no telemetry |
| Patch cadence (post-launch) | ~monthly for solo dev | §7 |
| Anti-snowball | Auto-flee at 25% HP, retreat home | §10 — cozy sub-rules |

### XP curve to ship

```js
// gj26's XP curve — OSRS-style, simplified for jam scope
export function xpForLevel(L) {
  if (L < 1) return 0;
  let total = 0;
  for (let i = 1; i < L; i++) {
    total += Math.floor(i + 300 * Math.pow(2, i / 7));
  }
  return Math.floor(total / 4);
}
```

This is exactly OSRS's curve. Level 99 = ~13M XP. Level 50 = ~101k. Level 25 = ~7.2k. Tunable to taste.

### Combat math sketch

```js
// dmg = max(1, atk - def + jitter), floor of 1 always lands
export function rollDamage(attacker, defender) {
  const atk = attacker.atkLv + (attacker.weaponBonus?.atk || 0);
  const def = defender.defLv + (defender.armorBonus?.def || 0);
  const jitter = Math.floor(Math.random() * 3) - 1;  // -1, 0, +1
  return Math.max(1, atk + Math.floor(attacker.strLv / 2) - def + jitter);
}
```

A bronze-sword (atk 1, str 2) player at attack level 5 hits a goblin (def 1) for `max(1, (5+1) + floor(2/2) - 1 ± 1) = 5–7 damage`. Goblin HP 6 → 1–2 hits. TTK ~3–6s assuming 1 hit per 2s. ✅ in band.

### Balance audit checklist for any new content

Before merging:
- [ ] TTK against tier-appropriate player is in genre band
- [ ] No fight is unwinnable for an underleveled (-5) player with cooked food
- [ ] No fight is one-shot trivial for an overleveled (+5) player
- [ ] XP rate per hour at this content is within ±20% of the curve target
- [ ] Drops fit tier — no off-tier surprises
- [ ] Spec-mismatch (high atk, no def player) can still beat the fight
- [ ] HP-bar width and combat duration match — no "swing 50 times" boredom

---

## 12. Tools & resources

### Spreadsheets (the universal balance tool)
- Google Sheets / Excel for static balance tables
- One sheet per content type: gear, enemies, skills, XP curves
- Cross-reference cells: "if I change tier 3 bronze, where does it propagate"

### Simulation
- Brute-force JS simulator (50 lines, see §8.D)
- For complex games: Monte Carlo with full mechanics (LoL, MOBAs)
- For tabletop / dice games: AnyDice and similar probability tools

### Playtest tools
- Friend group + voice chat + observation notes
- Steam playtest beta + Discord
- Per-player telemetry hook (kills, deaths, time-per-area) — even basic counters are useful

### Theory references
- Sirlin's *Balancing Multiplayer Games* (4-part essay) — foundational
- Ian Schreiber's *Game Balance Concepts* (Wordpress course) — comprehensive curriculum
- David Sirlin's GDC 2009 talk handout (PDF)

---

## 13. References

**Theory**
- [Sirlin — Balancing Multiplayer Games Part 1: Definitions](https://www.sirlin.net/articles/balancing-multiplayer-games-part-1-definitions)
- [Sirlin — Balancing Multiplayer Games Part 2: Viable Options](http://sirlingames.squarespace.com/articles/balancing-multiplayer-games-part-2-viable-options.html)
- [Sirlin — Balancing Multiplayer Games Part 3: Fairness](https://sirlingames.squarespace.com/articles/balancing-multiplayer-games-part-3-fairness.html)
- [Sirlin — GDC 2009 Handout (PDF)](https://sirlin.squarespace.com/s/GDC-2009-sirlin-handout6.pdf)
- [Game Balance Concepts — Level 7: Advancement, Progression and Pacing](https://gamebalanceconcepts.wordpress.com/2010/08/18/level-7-advancement-progression-and-pacing/)
- [ParadigmPlus — What is Game Balancing?](https://paradigmplus.itiud.org/volume1/number1/becker/)
- [Mathematical balance metrics in competitive multiplayer games (thesis PDF)](https://people.dsv.su.se/~akbj7812/Thesis.pdf)

**Math & formulas**
- [RPG Wiki — Damage Formula](https://rpg.fandom.com/wiki/Damage_Formula)
- [Yujiri — Damage Formulas](https://yujiri.xyz/game-design/damage-formulas.gmi)
- [On Video Games — You Smack The Rat for ??? Damage](https://jmargaris.substack.com/p/you-smack-the-rat-for-damage)
- [Design The Game — Example Level Curve Formulas](https://www.designthegame.com/learning/tutorial/example-level-curve-formulas-game-progression)
- [Medium — Graphs for Player Progression Part II](https://medium.com/js-game-design-journals/graphs-for-player-progression-part-ii-3807b25beee5)
- [GameDev.net — Formulas, Math, and theories for RPG combat/leveling systems](https://www.gamedev.net/forums/topic/660352-formulas-math-and-theories-for-rpg-combatleveling-systems/)

**Telemetry & data**
- [Riot Games Technology — Data team articles](https://technology.riotgames.com/tags/data)
- [WPI — Nerfs, Buffs and Bugs: League of Legends Patching Analysis (PDF)](https://web.cs.wpi.edu/~claypool/papers/lol-crawler/paper.pdf)
- [Esports Insider — League of Legends Balance Data](https://esportsinsider.com/2021/07/league-of-legends-balance-data)

**Difficulty / pacing**
- [Medium — Difficulty in Game Design, Flow, Motivations and Learning Curves](https://ricardo-valerio.medium.com/make-it-difficult-not-punishing-7198334573b8)
- [Strange Encounters — Difficulty Curves and Pacing in Gaming](http://strangeenc.blogspot.com/2016/02/difficulty-curves-and-pacing-in-gaming.html)
- [Gamescrye — 5 Tips for Balancing an RPG Game](https://gamescrye.com/blog/5-tips-for-balancing-an-rpg-game/)
