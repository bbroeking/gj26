# Skill / level pacing — research and design notes

> **Backlog item #7.** Goal: tune XP rates and per-level HP gains so
> progression feels meaningful in 1-2 hour sessions without becoming a grind.

---

## 1. Current state in our codebase

`src/game/skills.js` (63 lines):

- 13 skills: `atk str def hp cook wc fish mine smith forage carto falconry magic`
- Default level: 1 (HP starts at 10 — gives ~20 hpMax at level 1)
- HP-to-hpMax: `hpMaxForLv(lv) = lv * 2`. So HP Lv 10 → 20, Lv 50 → 100, Lv 99 → 198.
  - 2× the OSRS 1:1 rule. Comment: "cozy-RPG player isn't two-shot by mid-tier enemies before HP-XP catches up."
- XP table: `xpForLevel(n) = (n-1)² * 8` in `src/data/config.js:79` — **quadratic, not exponential**.

`src/data/config.js` is the tuning surface — every constant lives there.

### 1a. Measured curve (added during deep-dive iteration 3)

The actual shape of the current `xpForLevel(n) = (n-1)² * 8`:

| level | XP for next level | cumulative XP | kills @ 12 xp | real-time @ 1 kill / 4s |
|---|---|---|---|---|
| 2 | 8 | 8 | 1 | 3s |
| 5 | 128 | 240 | 20 | 1 min |
| 10 | 648 | 2,280 | 190 | 13 min |
| 15 | 1,568 | 8,120 | 677 | 45 min |
| 20 | 2,888 | 19,760 | 1,647 | 1.8h |
| 25 | 4,608 | 39,200 | 3,267 | 3.6h |
| 30 | 6,728 | 68,440 | 5,703 | 6.3h |
| 50 | 19,208 | 323,400 | 26,950 | 30h |
| 99 | 76,832 | 2,548,392 | 212,366 | 236h (= ~10 days of 24/7 grind) |

**What this tells us:**

- **Level 99 is reachable in ~236 hours of pure-combat grind.** Not OSRS-level (13M XP / ~hundreds of hours per skill), but still cliff-grindy for cozy.
- **The low end is too fast** — level 2 in 3 seconds is a free lever-pull, no satisfaction.
- **Level 5–10 is decently paced** (1-13 minutes).
- **Level 25 is 3.6h of combat grind** — already close to the doc's "5+ sessions" Phase 2 target. **Cap at 25 fits the existing curve well.**
- **Level 50 is 30h** — too much for cozy unless XP sources stack across actions (kills + crafting + gathering all feed combat XP via tool use, etc.).

**Implication:** The doc's recommendation of "cap at 25 + logarithmic curve" is partly right (cap), partly wrong (curve already isn't exponential — it's quadratic, which is gentler than OSRS). The real issue is the **low-end pacing** (levels 1-5 fly by) more than the high-end grind.

A revised Phase 2 hypothesis: *keep the quadratic shape, but raise the low-end coefficient* so level 2 → 5 takes more meaningful time, and cap at 25.

| candidate curve | level 2 | level 5 | level 10 | level 25 cumul |
|---|---|---|---|---|
| current `(n-1)²·8` | 8 xp | 128 xp | 648 xp | 39,200 xp |
| `(n-1)²·12` (simple +50%) | 12 xp | 192 xp | 972 xp | 58,800 xp |
| `(n-1)²·8 + (n-1)·40` (linear floor) | 48 xp | 288 xp | 1008 xp | 47,000 xp |

The "linear floor" candidate (third row) lengthens early levels meaningfully while preserving the late-game shape.

## 2. Wiki principles

### `games/power-progression.md`

> "Curve types: linear / exponential / logarithmic / S-curve. Most RPGs
> use S-curve: slow start, rapid mid-game, plateau."

OSRS XP table is famously **exponential** (each level requires ~7%
more XP than the previous). 99 levels means level 99 is 13M XP while
level 1 → 2 is just 83 XP. Brutal grind by design.

For a cozy 1-2 hour playthrough we want **logarithmic** — fast early
gains so the player feels the levels, then slowing to keep late-game
levels meaningful.

### `games/compulsion-loops.md`

> "The compulsion-loop sweet spot is: a clear short-term goal (this
> level), a satisfying medium-term goal (this skill milestone — e.g. 50
> Magic), a long-term aspirational goal (level 99)."

This is canonical OSRS structure. The XP pacing has to support *all
three* simultaneously.

### `games/game-balance.md`

> "Player perception, skill distribution, and fun factor all matter."

Levels per session is a perception metric. If a 1-hour session yields 1
level, the player feels stuck. If it yields 30 levels, levels feel
meaningless. Sweet spot: ~3-8 meaningful levels per session in early
game, dropping to ~1 every couple of sessions in late game.

---

## 3. Reference games to study

| game | XP curve | total levels | hours to max |
|---|---|---|---|
| **OSRS** | exponential, ~7% per level | 99 | hundreds |
| **Skyrim** | linear-ish per skill, soft cap | 100 | ~40h |
| **Cozy Grove** | gentle, time-gated | (unbounded) | months IRL |
| **A Short Hike** | no XP/levels — items unlock progression | — | 1-3h |
| **Stardew Valley** | exponential, soft-capped at 10 | 10 per skill | ~30-60h |

For Bramblewood (cozy + short arc):

- **Logarithmic curve** so early progress is fast, late tiers are aspirational
- **~10-15 levels** per skill is plenty (don't copy OSRS's 99)
- **3-5 milestone unlocks** per skill (instead of one feature unlock per level)

---

## 4. Open questions

1. **Cap level: 10? 25? 50? 99?** Cozy means lower. 25 is probably right.
2. **HP scaling**: currently `lv * 2`. With cap 25, that's 50 hpMax. Is 50 enough for late-game content? Probably yes.
3. **Combat XP source**: currently scales with damage dealt. Maybe also award flat XP for kills? Or split combat XP across atk/str/def by combat style?
4. **Skill milestones**: should hitting cook lv 10 unlock a new recipe explicitly, or is the recipe just *gated* by the level requirement? (Latter is what we have. Former is more rewarding.)
5. **HP regen rate**: currently 1 HP / 3 seconds out of combat (in player.js). Tune?
6. **Stamina regen**: 8/s in combat, 15/s out. Tune?
7. **Death penalty**: currently respawn at start, no XP loss. Cozy = no XP loss. Confirm.

---

## 5. Recommended next steps

**Phase 1 — measure** (no code changes):

1. **Print the current `xpForLevel` curve** and graph it. We need to see
   the actual shape before tuning.
2. **Estimate session yields** — at typical kill / gather rates, how many
   levels per skill in a 1-hour session at level 1? At level 10? At level 25?
3. **Identify the grind cliff** — at which level does XP-per-action drop
   below the "fun" threshold?

**Phase 2 — tune** (data-only, no code):

4. **Rebuild xpForLevel** as logarithmic: fast 1→10, smooth 10→20, slower 20→25.
5. **Cap at 25**.
6. **Define ~3 milestones per skill** with non-trivial unlocks (e.g. cook
   lv 10 = "Pantry Stew" recipe; cook lv 20 = "use any food item as a healing draught ingredient").

**Phase 3 — playtest and adjust:**

7. Single 60-minute playthrough, instrument the XP yield graph, adjust.
8. Repeat until: cook level 10 in ~30 min, atk level 10 in ~60 min, level 25 in any skill takes 5+ sessions.

**Smoke test for the tuning:**

- [ ] First level-up under 5 minutes of play
- [ ] First "milestone" unlock under 30 minutes  
- [ ] Cap is reachable in dedicated play but not in casual
- [ ] Late-game levels still produce a visible boost (HP especially)

---

## Sources

- `~/projects/research/wiki/games/power-progression.md`
- `~/projects/research/wiki/games/compulsion-loops.md`
- `~/projects/research/wiki/games/game-balance.md`
- `src/game/skills.js`, `src/data/config.js`
