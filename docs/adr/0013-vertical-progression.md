# ADR 0013 — Vertical progression: power gets bigger, difficulty is level-delta

**Status:** Accepted (2026-06-15)
**Supersedes [ADR 0010](0010-gear-frozen-at-zero-combat-power.md) (the gear freeze).**
**Refines [ADR 0006](0006-demo-level-cap-17.md) (cap stays 17 for the demo) and
[ADR 0012](0012-one-skill-wayfinding.md) (one Wayfinding skill is the power engine).**

## Context

ADR 0010 (one day old) froze gear at *zero* combat power and committed the game
to a *fully horizontal* itemization model: loot was the trophy-Ledger only, flat
and capped, and "you never get numerically stronger." That call was made to
protect the cozy, one-verb doctrine.

The user reversed it directly: **"the numbers should get bigger for sure."**
Wayfinder is to be a *vertical* progression game — the player visibly grows
stronger — but **fueled by the cozy spine, never by grinding kills** (ADR 0012
already removed all combat XP). The design question then becomes: where does
power come from, and how do we keep "cozy when you want it, tense when you ask
for it" without an ARPG gear-screen grind?

The felt-difficulty target the user set, verbatim:

> kill things 2+ levels lower easily. +1 to −1 levels around us is moderately
> hard, then over 2 levels above should be very hard.

## Decision

**Power is vertical and comes from three cozy-gated sources; difficulty is a pure
function of the player↔den level delta.**

### 1. Three sources of power (all fed by the cozy loop)

1. **Leveling** your one Wayfinding trade raises base `damage` and `hp_max`
   multiplicatively. You level by gather / craft / chart — so the cozy loop *is*
   the power engine. (Combat gives no skill XP — ADR 0012.)
2. **Gear** confers real combat power again — **this is the reversal of ADR
   0010.** The `_derive_stats()` freeze-filter is removed; an equipped item's
   `base_stat`/`base_value` and its rolled affixes once again feed all five
   offensive stats (`damage, crit_chance, crit_mult, fire_rate,
   cooldown_reduction`). Power flows from *smithing* (gather-gated crafting), not
   from kill-loot drops.
3. **Boss trophies / Ledger** grant real, capped, per-slot stat boosts tied to
   the trophy chain — the "kill a boss → get permanently stronger" beat.
   *(The Ledger as a live stat source is not yet wired — `ledger.gd` is a
   followup; the seam exists.)*

### 2. Symmetric multiplicative scaling → difficulty is level-delta

A single constant drives both sides:

```gdscript
# game.gd
const LEVEL_POWER := 1.25
```

- **Player** (`player_controller._derive_stats()`, ~line 1021): base damage and
  HP scale by `pf = LEVEL_POWER^(trade_lv − 1)`, with gear added flat on top.
- **Den** (`layout_loader._read_chart_modifiers()`, ~line 284): enemy `_hp_mult`
  and `_dmg_mult` scale by `den_scale = LEVEL_POWER^(den_level − 1)`.
- **Den level** comes from the chart tier (`game.run_cfg()`, ~line 743):
  `{tier 1: 3, tier 2: 8, tier 3: 13}` (Deepening depth will extend this later).

Because both sides use the *same* base, the net threat ratio collapses to the
delta: roughly `(LEVEL_POWER^2)^(den_level − player_level)` — the den's absolute
level cancels out and only **how far above or below you it is** matters. A level
gained flips a den's band; the chart you inscribe sets the delta, so difficulty
stays **opt-in**.

### 3. The bands (tuned to 1.25, verified in `test_stats.gd` DB2)

With `delta = den_level − your_level`, for a baseline lv-7 player, no gear, vs a
skeleton (18 hp / 7 dmg base):

| delta | band | hits to kill it | hits it needs to kill you | feel |
|-------|------|-----------------|---------------------------|------|
| ≤ −2 | **easy** | 1–2 | ~7 | cozy farming |
| −1..+1 | **moderately hard** | ~3 | ~5 | a fair fight |
| ≥ +2 | **very hard** | 5+ | ~3 | read perfectly or come back stronger |

`LEVEL_POWER` was tuned from 1.15 (too gentle — delta −2 still took 3 hits) up to
**1.25**, which lands the bands squarely on the user's spec.

## Consequences

- `_derive_stats()` no longer carries the ADR-0010 freeze filter; `test_stats.gd`
  S2/S3 + GF1/GF2 are flipped back to *gear raises power* invariants, and DB1/DB2
  assert level-scaling and the rising delta-bands. All five suites green at 1.25
  (stats 10, loop 240, dungeon 25, transitions 59, skills 17).
- Anti-escalation lore still holds: deeper ≠ a new worse creature, just bigger
  numbers (the Hedgemother stays the apex being).
- **Cozy guardrail preserved:** the fastest way to get strong is to *play the
  cozy game* (skill / craft / charts / bosses), never to farm mobs.
- The economy stays horizontal alongside the vertical: Codex collection, the
  Living Atlas village, opt-in seasonal novelty — no daily chores/streaks.

## Followups (not in this ADR)

- `ledger.gd` — make trophies a live, capped stat source (source #3 above).
- Summary card: surface the den level and the resulting band ("Den lv 8 · you
  6 → **very hard**") before the player commits to a chart.
- Wire `leveled_up` → `_derive_stats()` so a level-up refreshes live stats
  mid-session (currently derived on equip/load).
- Re-tune `LEVEL_POWER` and the tier→den-level map once Deepening depth and real
  gear/trophy curves are in playtest.

## Alternatives considered

- **Keep ADR 0010 (fully horizontal).** Rejected by the user — sheds the "numbers
  get bigger" player fantasy entirely.
- **Vertical via gear treadmill only (classic ARPG).** Rejected — that makes
  kill-loot the engine of power and undermines the cozy spine.
- **Absolute (non-delta) difficulty curves.** Rejected — delta-driven scaling is
  what makes a single level-up *felt* (flips a den's band) and keeps difficulty
  opt-in through chart choice.
