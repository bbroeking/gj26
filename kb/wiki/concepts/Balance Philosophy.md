---
type: concept
tags: [balance, pacing, xp-curve, economy, combat, ttk, level-cap]
status: draft
updated: 2026-06-13
sources:
  - "docs/game-balance-playbook.md"
  - "docs/mmo-game-design-playbook.md"
  - "docs/cozy-life-sim-design-playbook.md"
  - "docs/adr/0003-cozy-skilling-spine.md"
  - "wyrd/data/economy.gd"
---

# Balance Philosophy

Wayfinder's balance is governed by a single governing principle — "always winnable, occasionally tense, never frustrating" — applied through three distinct lenses: cozy pacing (never punish the player), a no-arbitrage economy (gather is always cheaper than buy), and math-first XP/TTK tuning backed by small-group playtests.

---

## 1. The three kinds of balance (and which Wayfinder targets)

Sirlin's foundational distinction (`docs/game-balance-playbook.md` §1):

| Kind | Definition | Wayfinder's concern? |
|---|---|---|
| **Fairness** | Equal skill → equal chance, regardless of starting option | Low — no PvP in demo scope |
| **Viability** | Meaningful options remain worth picking (no dead builds) | Medium — [[Affixes]] and [[Items and Gear]] tiers should all have use-cases |
| **Pacing** | Challenge tracks player progression — never too easy, never too hard | **Primary** — cozy single-player |

Because Wayfinder is a cozy single-player dungeon-crawler, **pacing** is the balance problem that matters most. Fairness becomes relevant only if [[Multiplayer Co-op]] ships PvP (it won't in demo scope). Viability matters for [[Affixes]] and build diversity but is secondary to keeping the difficulty curve smooth.

**Depth** (Sirlin's bonus concept): balance decisions should try to increase strategic depth rather than decrease it. The chart-affix system exists precisely to add decision texture without multiplying complexity.

---

## 2. Cozy pacing rules

From `docs/game-balance-playbook.md` §10 and `docs/cozy-life-sim-design-playbook.md` §7, the governing sub-rules for Wayfinder's cozy category:

| Rule | Rationale |
|---|---|
| Never one-shot a player below 50% HP | Safety is foundational to cozy genre contract |
| Always allow retreat (no force-fights) | Random encounters can be disengaged |
| Death = fade-to-bed + minor penalty | Worst case is a less-productive run, not a reset |
| Underleveled fights possible with potions/skill | Not gated; player agency respected |
| Auto-flee at ~25% HP (cozy sub-rule) | Anti-snowball to prevent unwinnable death spirals |

These are non-negotiable guardrails. Violating any one of them breaks the cozy promise and breaks player trust. They apply regardless of [[Dungeon Generation]] floor depth or boss tier.

---

## 3. TTK targets

Time-to-kill (TTK) is the primary tuning lever. Targets by enemy category (`docs/game-balance-playbook.md` §2):

| Content | Target TTK | Notes |
|---|---|---|
| Trivial mob (goblin, rat) | 5–15 s | Must feel breezy; cozy band |
| Elite / mid-tier | 15–30 s | Room for tension; occasional dodge |
| [[Bosses|Boss]] | 30–60 s (demo) | Enough for a pattern to emerge, not a slog |

These targets are backed out from the damage formula. With a subtractive formula (`dmg = max(1, atk - def ± 1 jitter`) and ~1 hit per 2 s, a goblin with 6 HP should fall in 1–2 hits = 2–4 s. Tuning atk/def stats to land in the 5–15 s band means enemies need more HP or the hit interval slows.

### Damage formula

For Wayfinder, the playbook recommends **subtractive with a floor of 1** (`docs/game-balance-playbook.md` §3):

```
dmg = max(1, atk + floor(str/2) - def + jitter)  // jitter = −1, 0, or +1
```

- Intuitive: defence visibly absorbs damage.
- OSRS-classic feel — players who know RS feel the right formula immediately.
- **Not** multiplicative (used in LoL/Dota) — that scales better across power levels but is harder for players to intuit.
- **Not** roll-based OSRS post-2007 (hit chance + maxHit) — adds a second dimension (accuracy) that is appropriate for deep PvM, not for cozy clearing.

### Tier scaling

Linear tier scaling (not multiplicative): each gear tier adds a constant atk/def bonus (e.g. Bronze +3, Iron +6, Steel +9). Old gear becomes slightly suboptimal but is never invalidated — cozy players can revisit early content without obliterating it. Power creep is bounded by the no-arbitrage economy gate. (`docs/game-balance-playbook.md` §5)

---

## 4. XP curves

The OSRS near-exponential curve is used directly (`docs/game-balance-playbook.md` §4):

```
xp(L) = floor( sum_{i=1}^{L-1} floor(i + 300 × 2^(i/7)) / 4 )
```

Key milestones:

| Level | XP required | Approximate play-hours (casual) |
|---|---|---|
| 25 | ~7.2k | ~0.7 h |
| 50 | ~101k | ~10 h |
| 70 | ~737k | ~70 h |
| 99 | ~13M | (post-demo) |

**Why this curve:** it flattens enough early (level 50 = milestone) that players feel mastery, but each later level requires real commitment. Players who came up on OSRS feel the right pace immediately without being told what the formula is.

### Calibrating to play-hours

Target: level 50 in ~10 hours of casual play. That means ~10.1k XP/hr at the midpoint level — roughly 28 trees/hr at 100 XP each (for a woodcutting analogy), or comparable activity rates for [[Gathering]] nodes. If math shows 100 hours to 50, XP rate is too low; if 30 minutes, too high.

### Demo level cap: 17

ADR 0006 sets the demo cap at level 17. Rationale: [[Wayfinding]]'s unlock ladder has boss dens at 8/12/14 and the Summit at 16. The cap sits at 17 so the Summit capstone is felt one level before the ceiling — a deliberate emotional beat, not an arbitrary stop.

The cap was set at 17 (not 10) to avoid compressing Wayfinding's unlock ladder, which was tuned across the whole chart-loop balancing arc. Compressing would stack multiple unlocks per level and break the "every level matters" pacing for the game's spine Trade. (`docs/adr/0006-demo-level-cap-17.md` via [[Design Decisions]])

---

## 5. Economy balance: the no-arbitrage gate

The economy follows MMO-playbook faucet/sink doctrine (`docs/mmo-game-design-playbook.md` §7) applied to a cozy single-player context:

**Faucet:** selling dungeon gear to [[NPCs|Hod]] by rarity.
**Sink:** buying raw materials and inks from Hod's shelf.

**No-arbitrage invariant:** any forge recipe whose inputs are all purchasable from Hod must cost more at Hod's prices than the output's sell value. This prevents gold farming through the forge — the loop must be gather → craft, not buy → sell. The invariant is enforced by an automated test (`test_wyrd_loop.gd::_test_economy_gate`).

Prices are set ~3–4× the opportunity cost of gathering, so:
- Buying is always *possible* — never a blocker.
- Gathering is always *cheaper* — the chart loop rewards engagement.

Deep ores (palechalk, starsilver, hedgesteel) are never stocked on Hod's shelf. This is gate-safe by construction — tier-2 charts are the only road to those materials. The spec recommends keeping deep ores off the shelf for the demo (`docs/specs/45-trade-ladders-earth.md`).

### Gold is comfort, not power

Gold is a **convenience shortcut into the ink economy**, not a bypass of the [[Chart Loop]]. The balance goal: "gold is always winnable, occasionally tense, never frustrating." It should never block a player who wants to run a chart, but it should never make gathering feel unnecessary either.

---

## 6. The balance loop (process)

Without telemetry (pre-launch, solo dev), Wayfinder uses the following process (`docs/game-balance-playbook.md` §6, §8):

```
[Define target TTK + XP/hr per content tier]
  → [Math out stats from damage formula]
  → [Generate content via content-generation-playbook]
  → [Playtest worst case: underleveled (-5) and overleveled (+5)]
  → [Tune formulas, not individual numbers]
  → [Repeat per tier]
```

### Three test cases that catch 80% of balance bugs

1. **Underleveled fight** — player 5 levels below content. Should be *possible* with consumables and skill, not trivially losable.
2. **Overleveled fight** — player 5 levels above. Should be fast but not one-hit; old zones remain playable.
3. **Spec-mismatch** — player with wrong stat distribution (e.g. high atk, no def vs. a slow-but-hard-hitting boss). Should be stretchy, not binary.

### Balance audit checklist for new content

Before merging any new enemy or gear tier:
- [ ] TTK vs. tier-appropriate player is in the cozy band
- [ ] No fight is unwinnable for an underleveled (-5) player with cooked food
- [ ] No fight is trivially one-shot for an overleveled (+5) player
- [ ] XP rate per hour is within ±20% of the curve target at that content level
- [ ] Drops fit tier — no off-tier surprises
- [ ] Spec-mismatch player can still clear the fight
- [ ] HP-bar width and combat duration match — no "swing 50 times" boredom

---

## 7. Anti-patterns explicitly avoided

| Anti-pattern | Why avoided |
|---|---|
| **Power creep** | Linear tier scaling; economy gate prevents gear treadmill |
| **Dominant strategy** | [[Affixes]] designed as orthogonal (not rock-paper-scissors meta) |
| **Mandatory daily grind** | Optional dailies; FFXIV model, not WoW chain |
| **Death = significant loss** | Cozy genre contract; fade-to-bed pattern |
| **Hidden math** | Damage numbers and tooltips surfaced; players can predict outcomes |
| **Snowball lock** | Auto-flee at ~25% HP; come-back consumables (cooked food) |
| **Treadmill catch-up** | No mandatory grind to stay relevant; horizontal progression |

---

## 8. Viability and build diversity

Viability concerns apply primarily to [[Affixes]] and gear selection. The design rule: every affix must have a use-case; no affix should be strictly dominated by another at the same tier. The good/bad twin structure of Affixes (each positive has a cost) is itself a viability mechanism — players who understand the tradeoffs optimize around them, and casuals pick what sounds good, and both have valid experiences.

For future PvP (if [[Multiplayer Co-op]] ever extends there): Sirlin's fairness definition applies — starting options must be equal-but-different, not strictly better. No current plans; flagged for future-proofing.

---

## See also

- [[Design Influences]] — the genre lineage that produced these balance choices
- [[Trades and Leveling]] — XP curves and the four-Trade leveling structure
- [[Combat]] — TTK targets and the damage formula in code
- [[Economy]] — the no-arbitrage gate and gold faucet/sink
- [[Affixes]] — good/bad twin design and viability
- [[Chart Loop]] — the endgame progression structure the economy protects
- [[Design Decisions]] — ADR 0006 (level-17 cap) and ADR 0003 (cozy-skilling spine)

## Sources

- `docs/game-balance-playbook.md` — TTK targets, damage formulas, XP curves, balance loop process
- `docs/mmo-game-design-playbook.md` §3, §7 — balance definitions, economy faucets/sinks
- `docs/cozy-life-sim-design-playbook.md` §7 — cozy pacing rules, no-punishment design
- `docs/adr/0003-cozy-skilling-spine.md` — combat-as-one-verb governs TTK scope
- `wyrd/data/economy.gd` — SELL_BY_RARITY, WARES (faucet/sink prices)
- `wyrd/test_wyrd_loop.gd` — _test_economy_gate (no-arbitrage enforcement)
- `docs/specs/45-trade-ladders-earth.md` — economy gate proof and deep-ore shelf decision
