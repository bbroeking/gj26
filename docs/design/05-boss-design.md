# Boss design — research and design notes

> **Backlog item #5.** Goal: a hand-designed boss fight with phased mechanics
> and telegraphed counter-windows. Lower priority than tuning (#1) but the
> highest-impact single piece of late-game content.

---

## 1. Current state in our codebase

We already have substantial boss infrastructure (`src/game/enemies.js`):

| feature | line | what it does |
|---|---|---|
| `e.isBoss` flag | 16, 38, 345-416 | gates respawn, interrupt, telegraphs, intro lines |
| Phase-2 trigger | 819-820 | flips `e.phase === 2` at HP ≤ 50% |
| Frenzy state | 803, 808, 847 | windups quicken at low HP |
| Lash alternation | 1218 | phase-2 boss alternates between two attack types |
| Slam telegraph | 1222 | 3×3 AoE telegraphed via `scene/telegraph.js` |
| Red parry-only attacks | 971-973 | only riposte negates |
| `_bossIntroShown` log | 986 | printed combat-log primer when first encountering |
| Token-based windup pool | 6 (file header) | "Hades-style" — global windup tokens cap how many enemies can simultaneously commit to attacks |

So a single-boss-with-phases is **already shippable** — what's missing is **boss content** (a specific designed fight, not infrastructure).

### 1a. Existing boss audit (added during deep-dive iteration 1)

Three boss-tagged enemies already exist in `enemies.js`:

| boss | HP | atk / def / maxHit | aggro radius | unique mechanic | drop | log line |
|---|---|---|---|---|---|---|
| **Hedgemother** | 220 | 22 / 16 / 7 | 7 | `parryOnly: true` — red thorn-slam, riposte-only | `hedgemother` table (likely `thorn_crown`) | "★ The Hedgemother falls. The brambles around you slacken." |
| **Burrow Boar** | 280 | 24 / 14 / 8 | unset (default) | none — uses generic boss attacks | `burrow_boar` table | "★ The Burrow Boar topples. The earth quiets." |
| **Wolf Alpha** | 240 | 26 / 12 / 7 | 8 | none — uses generic boss attacks | `wolf_alpha` table | "★ The Wolf Alpha falls. The pack scatters into the brambles." |

All three share the same boss AI scaffold (telegraphed slam OR lash in phase 1; phase-2 frenzy at HP ≤ 50%). Only Hedgemother has unique attack flavor today.

**Therefore the cheapest meaningful upgrade for boss design is NOT to author a new boss — it is to differentiate each existing boss with one unique mechanic.** Concrete candidates:

- **Hedgemother** — already has `parryOnly`. Optional polish: bramble-vine *root* attack on phase 2 (slows the player toward her so kiting fails)
- **Burrow Boar** — burrow → emerge under player. Telegraphed dust ring at her target tile, ~1.5s windup, then deals AoE damage to the tile she emerges on. Forces the player to relocate during windup.
- **Wolf Alpha** — pack-summon at phase 2: spawn 2 wolves to flank. Adds die when alpha dies. Tests the player's AoE / multi-target capability instead of pure single-target DPS.

Each is ~30-50 lines of code, reuses existing telegraph + spawn infra, and gives each boss a distinct identity without writing a new fight from scratch.

**Open question (still gated on user input)**: do we want to ship these unique-mechanics polish passes, or are bosses parked entirely until v2?

## 2. Wiki principles

From `~/projects/research/wiki/games/`:

### `game-ai-decision-making.md`

> "Game AI prioritizes creating fun, believable behavior that serves
> gameplay. Pac-Man's AI is utterly challenging and yet exceptionally
> straightforward."

For boss AI specifically: **simple state-machines beat complex planning** in the cozy-RPG context. Players should be able to *learn* the boss's pattern within 3-5 attempts. Behavior trees > GOAP for designer control.

### `gaming/game-ai-behavior-trees.md`

A boss's AI is a textbook **selector + sequence** problem:

```
selector("BossRoot")
  ├── sequence("Phase2-Special")    if hp < 50% && phase != 2 → trigger frenzy
  ├── sequence("ParryOnlyStrike")   every 3rd attack OR if player is not in melee range
  └── sequence("BasicAttack")       default — telegraphed slam or lash
```

Our existing `e.phase === 2` + `_lashAlt` is a hand-rolled FSM doing this.

### `games/power-progression.md`

> "If enemies don't scale, early-game content becomes trivial. Solutions
> include gating content by level/area, scaling difficulty nonlinearly,
> and **introducing new mechanics that reset the player's mastery**."

Boss fights are the canonical "reset player's mastery" moment. The boss
should introduce ONE new mechanic the player has never seen before — a
mechanic that DOESN'T appear in any normal mob — so the boss isn't just
"a beefier mob."

### `games/compulsion-loops.md` (read summary)

Boss fights work as a *terminal moment* in a content loop: player gathers,
crafts, levels up, **prepares**, then commits. The "preparation" beat
matters as much as the fight. A boss that you can walk into without
preparing reads as a normal mob with extra HP.

---

## 3. Reference games to study

| game | what it does well | what we can borrow |
|---|---|---|
| **OSRS — Bandos / Verzik / Tombs** | Each boss has 2-3 mechanics, all telegraphed, all defeatable solo with prep | one **safe-spot exploit** the smart player finds; one **forced-engage** mechanic that prevents pure ranged kiting |
| **Hades — Megaera / Theseus / Hades** | Multi-phase escalation; new mechanics each phase; visible HP bar | clean phase transitions with a beat of breathing room (boss roars, takes 1s of immunity, spawns adds) |
| **Hollow Knight — Mantis Lords / Soul Master** | Dance-like rhythm, every attack has a parry/dodge window | every attack must have a counter-window (parry, dodge-through, run-around) — none "just deals damage if you stand there" |
| **Cult of the Lamb — Bishops** | Single bosses with 3 attacks each; learning curve is 2-3 deaths | 3 attacks total per phase max — too many is unreadable in cozy art style |
| **Stardew Valley — no bosses** | The genre opt-out | A *cozy* game can have NO bosses and instead use long-form quests as terminal beats. Worth considering. |

---

## 4. Open questions

1. **Does Bramblewood have bosses at all?** We have boss infrastructure
   (the Hedgemother already, references in code) but the cozy-fairytale
   tone of the project might be better served by *narrative climaxes*
   (Eldra's vigil, Withering's last hunt) than HP-bar boss fights. **Ask
   the user before building combat content.**

2. **Number of bosses for v1.** One unmissable story-quest boss + 1-2
   optional dungeon-end bosses? Or zero (cozy mode)?

3. **Death penalty for boss fights.** Currently dying is `respawn at start`
   — soft penalty. For boss fights specifically, do we want lost
   consumables / dropped tier-3 ore / a "scaffolding" mechanic
   (Hollow-Knight-style shade)?

4. **Prep loop.** What does "preparing for the boss" cost / require?
   Crafting a tier-2 weapon? Stocking 5 healing draughts? This is the
   **content-loop bridge** — it's how the boss earns its terminal-beat
   role.

---

## 5. Recommended next steps

If we commit to building one v1 boss:

1. **Pick the fight first** — narrative + space. Likely candidates:
   - **The Hedgemother** (already referenced in items.js — `thorn_crown` is her drop). Probably the natural one.
   - **The Withered Knight in the chapel.** Lore exists.
   - **A new endgame entity** — would need writing.

2. **Design 3 attacks max** — per phase. One "telegraphed AoE slam"
   (existing infrastructure), one "forced-engage" (charge or pull), one
   "parry-only red strike" (existing) for the rhythm beat.

3. **Phase-2 rule** — at HP < 50%, ONE attack changes (Hades pattern). Not
   "all attacks change." Players already memorized the pattern; the
   change should *modify* not *replace*.

4. **Win/lose-condition writing** — boss-defeated log line, drop
   reveal, return to village beat. **The story moment matters more than
   the mechanics.**

5. **Smoke test against the wiki rules**:
   - [ ] Every attack has a counter-window
   - [ ] No more than 3 attacks per phase
   - [ ] One mechanic the player has never seen in normal mobs
   - [ ] Defeatable solo at the gated level requirement

---

## Sources

- `~/projects/research/wiki/games/game-ai-decision-making.md`
- `~/projects/research/wiki/gaming/game-ai-behavior-trees.md`
- `~/projects/research/wiki/games/power-progression.md`
- `~/projects/research/wiki/games/compulsion-loops.md`
- `src/game/enemies.js` — current boss infrastructure
