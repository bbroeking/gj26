# 45 — Trade ladders: Huntcraft 11→17

> **Outcome**: Huntcraft has a complete unlock ladder to the demo cap of 17 —
> two new stat perks (H12, H14), one behavioral capstone perk (H17), no new
> skill gates above 9 — and the xp pacing math shows H17 lands within a run
> or two of the Summit without touching the shared curve.

**Status: DESIGN.** No code changes in this spec; it is the build sheet for
the Huntcraft half of the ADR 0006 ladder-extension work (specs 45-*).

## Why

ADR 0006 capped the demo at 17 and ruled "extend the other ladders, don't
compress Wayfinding." Huntcraft (ADR 0005's single combat trade) tops out at
H10 today: perks at 5/10, skill gates at 1/4/7/9. Levels 11–17 are silent.
Per ADR 0005, anything we add must feed back into *how you fight*, not how
much you must — Huntcraft is a ledger for the combat verb, not a second spine.

## Scope

**In:**
- Perk design for H12 / H14 / H17 (names, values, mechanisms, hook costs).
- The skill-gate decision for levels above 9 (recommendation: none).
- XP-pacing math: kills-to-17 against the shipped curve and enemy roster.
- One fully-statted skill proposal documented as the *rejected* alternative.

**Out (explicit non-goals):**
- No atk/str/def split (ADR 0005; the revisit clause — weapon families — is
  not triggered, combat is bow-only).
- No changes to the shared xp curve (`xp_for_level`) — ADR 0006 explicitly
  keeps it; Wayfinding's tuned 1–16 spread depends on it.
- No new hotbar slots; loadout stays 3 picks from the pool.
- Earthcraft / Wildcraft ladders (their own 45-* specs).

---

## 1. The ladder — Huntcraft 1–17

Total XP is `xp_for_level(n) = (n-1)²·8 + (n-1)·32` (cumulative; the trade
stores lifetime xp). Existing unlocks unchanged; new rows in **bold**.

| Lv | Total XP | Δ XP | Unlock | Notes |
|---:|---:|---:|---|---|
| 1 | 0 | — | Bow + six open skills | PowerShot, MultiShot, BrambleSnare, PiercingBolt, RainOfThorns, Thornburst (absent from `SKILL_REQS` = open) |
| 2 | 40 | 40 | — | |
| 3 | 96 | 56 | — | |
| 4 | 168 | 72 | **Skill gate:** HuntersMark | existing (`SKILL_REQS`) |
| 5 | 256 | 88 | **Perk:** Steady Hands | existing — +5% crit chance |
| 6 | 360 | 104 | — | |
| 7 | 480 | 120 | **Skill gate:** HeartwoodWard | existing |
| 8 | 616 | 136 | — | Hedgemother den opens at carto 8 — first boss xp |
| 9 | 768 | 152 | **Skill gate:** MercyShot | existing — gate arc complete: 9 skills, 3 slots |
| 10 | 936 | 168 | **Perk:** Hunter's Stride | existing — +5% move speed |
| 11 | 1120 | 184 | — | |
| 12 | 1320 | 200 | **Perk: Quick Nock** *(new)* | +10% skill cooldown recovery — lands in the same band as the Boar den (carto 12) |
| 13 | 1536 | 216 | — | |
| 14 | 1768 | 232 | **Perk: Heavy Draw** *(new)* | +25% crit damage — lands with the Wolf den (carto 14) |
| 15 | 2016 | 248 | — | |
| 16 | 2280 | 264 | — | carto's Summit level; hunt stays quiet on purpose — the spotlight is Wayfinding's |
| 17 | 2560 | 280 | **Capstone perk: Even Breath** *(new)* | every kill returns 6 Focus |

The empty levels are deliberate. Kills are a constant background drip (every
fight pays), so Huntcraft doesn't need Wayfinding's "every level unlocks
something" pacing — it needs a few unlocks that audibly change the fight.
The 14→17 stretch (792 xp, ~170 trash kills) is the quiet run-up to the
capstone; see Open Questions if playtests find it flat.

---

## 2. Perk table

| Lv | Perk (id) | Stat | Value | Mechanism | New hook? |
|---:|---|---|---|---|---|
| 5 | Steady Hands (`steady_hands`) | `crit_chance` | +0.05 | existing — `player_controller.gd::_derive_stats()` adds into the stat sums | no (shipped) |
| 10 | Hunter's Stride (`hunters_stride`) | `move_speed` | +0.05 | existing — same sums; multiplies RUN/WALK_SPEED | no (shipped) |
| 12 | **Quick Nock** (`quick_nock`) | `cooldown_reduction` | +0.10 | new `PERKS["hunt"]` entry in `game.gd` + one `_add_stat(sums, "cooldown_reduction", 0.10)` line in `_derive_stats()` — rides `Skill.effective_cd()` (`base_cd / (1+cdr)`, capped at `CDR_CAP` 0.80) | **no** — exact shape of the two shipped perks |
| 14 | **Heavy Draw** (`heavy_draw`) | `crit_mult` | +0.25 | same shape — `_add_stat(sums, "crit_mult", 0.25)`; flows through `arrow.crit_mult` into `combatant.take_damage` where crits are `×(2.0 + bonus)`, supers `×(3.0 + bonus)` → crits ×2.25, supers ×3.25 | **no** |
| 17 | **Even Breath** (`even_breath`) | behavioral: +6 Focus per kill | n/a | see §4 — the one behavioral perk; needs a small new hook | **yes** — ~8 lines across 2 files, costed below |

Player-visible copy (perk `desc` strings, matching the terse shipped style):

- **Quick Nock** — `"Skills come back a tenth sooner"`
- **Heavy Draw** — `"Your telling hits land a quarter harder"`
- **Even Breath** — `"A clean kill steadies you — every kill returns 6 Focus"`

Why these two stats and not more crit-chance/move-speed: Quick Nock changes
*rotation cadence* (BrambleSnare every 3.6s instead of 4.0, Thornburst every
7.3s instead of 8 — you weave skills into packs more often), and Heavy Draw
changes *which shot you build around* (it makes the Steady Hands → Hunter's
Mark → MercyShot crit line a real spike build instead of a smear). Both
reshape decisions; neither inflates raw numbers the content wasn't tuned for
(crit chance stays 25%, base damage untouched). That's the ADR 0005 bar:
how you fight, not how much.

---

## 3. Skill gates above 9 — recommendation: (a) none, perks-only

The pool stays 9; `SKILL_REQS` stays `{HuntersMark: 4, HeartwoodWard: 7,
MercyShot: 9}`. Arguments:

1. **The teaching arc is already complete at 9.** Gates 1/4/7/9 exist to
   stagger the *learning* of the verbs; at H9 the player holds 9 skills for
   3 slots — a real 84-combination loadout decision. A 10th skill raises
   option count but not decision quality.
2. **ADR 0005's spirit names the shape of the high ladder.** "Huntcraft's
   perks feed back into *how you fight*" — above the gate arc, the trade's
   voice is perks that recolor verbs you already own, not more verbs.
3. **Cost honesty.** Every shipped skill carries a full VFX/SFX/balance pass
   (BrambleSnare alone is ~550 lines of 5-beat telegraph choreography after
   spec 34). A skill gated at H15 unlocks at ~80% of the way through the
   demo — the most expensive content in the game getting minutes of play.
4. **UI scope.** The loadout panel lays out 9 entries; growing the pool late
   in the demo is silent panel/scroll work nobody budgeted.

### The rejected alternative, specced anyway (post-demo candidate)

If post-demo the pool grows, this is the verb no existing skill covers —
**displacement**. (Coverage today: big hit + burn, fan, ground root, line
pierce, delayed nuke + bleed, self-burst + snare, mark amp, absorb, execute.
Nothing *moves* enemies.)

| Field | Value |
|---|---|
| Name | **Driving Volley** |
| Gate | H12 (would displace Quick Nock to H15) |
| Verb | close fan that *shoves the pack back* — the make-room shot |
| Focus cost | 26 |
| Cooldown | 6.0s |
| Projectiles | 5 arrows, 60° spread, 0.4× damage each (2.0× total if all land — point-blank only) |
| On hit | knockback strength ~6 away from the player + snared 1.0s / 0.5 slow |
| Framework | `ProjectileSkill` fields (`projectile_count: 5`, `spread_deg: 60`, `damage_mult: 0.4`) + a `KnockbackEffect` subclass of `SkillEffect` — explicitly anticipated by the comment in `skill_effect.gd` ("future effect kinds (knockback-on-hit…) can subclass SkillEffect") — calling the already-shipped `combatant.apply_knockback(dir, strength)` (combatant.gd:355) |
| New code | one ~15-line effect subclass + one ~15-line skill file; no engine work |

It's deliberately *not* in the demo ladder: Thornburst already owns the
"they're on top of me" panic slot, and two panic buttons in a 3-slot loadout
cannibalize each other.

---

## 4. The capstone — H17: Even Breath

**Every kill returns 6 Focus.**

Why this is the capstone and not another stat line:

- **It changes the texture of every pack fight.** Focus is 50, in-combat
  regen is 3/s; one kill = two seconds of combat regen, a 5-kill room =
  a free PowerShot+HuntersMark. At H17 the loop becomes kill → cast → kill —
  the hunt funds itself. That's a felt, audible change, not a percent.
- **Loadout-agnostic.** Works with all 84 loadouts (unlike, say, "Mark
  spreads on kill," which is dead weight for the two-thirds of loadouts
  that skip HuntersMark — considered and rejected for exactly that).
- **In voice.** Seventeen levels of hunting and the hunt no longer winds
  you. Plain, warm, no fantasy-ism — "Even Breath."
- **Honest scope** (the one behavioral perk the brief allows):

| Hook | File | Change |
|---|---|---|
| Kill-side | `wyrd/scripts/combatant.gd::_die()` | next to the existing `game.award_xp("hunt", …)` block (~line 671): `if game.perk_active("hunt", "even_breath"):` → `get_tree().get_first_node_in_group("player")` → `player.add_focus(6.0)` (~4 lines) |
| Player-side | `wyrd/scripts/player_controller.gd` | new `add_focus(amount: float)` helper: `focus = clampf(focus + amount, 0.0, focus_max)` + HUD `set_focus` ping (~4 lines) |
| Data | `wyrd/scripts/game.gd` `PERKS["hunt"]` | one dict entry |

Known limitation, accepted: it does nothing *during* a boss fight (one kill,
at the end). Boss-fight focus economy already has owners (Echoing Steps
affix, Clearwater Philter); the capstone owns pack play. Suggested garnish
(optional, not required): a small gold pip on the focus globe per refund so
the perk is visible the moment it triggers.

---

## 5. XP pacing — kills to 17

**Inputs (all from shipped code):** kill award is `maxi(2, int(hp_max / 3.0))`
(`combatant.gd:671`, per ADR 0005); curve totals in the §1 table; enemy HP
from `layout_loader.gd` `ENEMY_KINDS` / `BOSS_KINDS`.

### Per-kill xp

| Enemy | hp_max | XP/kill |
|---|---:|---:|
| skitterling | 7 | 2 (floor) |
| rat | 10 | 3 |
| bramble_imp | 12 | 4 |
| ghost | 14 | 4 |
| skeleton | 18 | 6 |
| hedge_sprite | 22 | 7 |
| elite (×1.25–1.5 hp) | 23–33 | 7–11 |
| wolf_alpha / hedgemother / burrow_boar | 55 / 60 / 80 | 18 / 20 / 26 |
| hedgemother_queen (Summit) | 160 | 53 |

Weighted average per trash kill, by spawn table (`SPAWN_TABLES`):
snug ≈ **3.9**, briar_maze ≈ **4.5**, hollow ≈ **4.7**, crypt ≈ **5.0**.

### Per-run yield (tier-2 hollow, full clear)

Combat rooms spawn `4 + clampi(depth/2, 0, 6)` trash (layout_loader:747);
with ~5–6 combat rooms plus setpiece/treasure/shrine spawns a full clear is
**~35–40 kills** ≈ 35–40 × 4.7 ≈ **170–190 xp**, +5–10 elite margin, +20–26
when a den is inked → call it **~180 plain / ~210 with a den boss**.

The affix lever (this is the good part): **Tyrannical** (+50% enemy HP)
scales kill xp ×1.5 → ~280/run; **Tyrannical + Festival Pace** (+50%
density) → ~420/run. Wayfinding affixes are the Huntcraft training dial —
the chart loop trains the combat trade, exactly the gather→craft→chart→delve
spine closing on itself. Worth surfacing in a tooltip someday; costs nothing
now (hp_mult already flows into hp_max before `_die()` reads it).

### Kills / runs to 17

| Target | Total XP | Trash-kill equiv. (÷4.7) | Plain full clears (÷180) | Tyrannical charts (÷280) |
|---|---:|---:|---:|---:|
| H10 (today's top) | 936 | ~200 | ~5 | ~3.5 |
| H14 | 1768 | ~375 | ~10 | ~6.5 |
| H17 (cap) | 2560 | **~545** | **~14** | **~9** |

**Sanity check against the spine:** Wayfinding completion xp is
`tier·75 + good·40 + bad·10` ≈ 200–230 per tier-2 run → carto 16 (2280 xp)
in **~10–11 runs**. A player who full-clears the same runs the trophy chain
already demands banks ~1,800–2,400 hunt xp by Summit time — **H15–16 at the
Summit gate, H17 within a run or two after** (the Queen alone pays 53).
That is where a capstone should land: the last level-up is felt, right at
the demo's crescendo.

**Verdict: no formula change.** `max(2, hp_max/3)` was decided in ADR 0005
*today* and the math holds — Huntcraft paces with Wayfinding under the
play pattern the trophy chain already produces.

**Contingency (pre-tuned, behind a playtest gate):** the risk is partial
clears — at ~60% clears the cap takes ~20+ runs and drifts grindy. If the
median playtester reaches the Summit with Hunt < 14, change the divisor in
the *one hunt-specific line* (`combatant.gd:671`) from `/3` to `/2`:
per-kill becomes skeleton 9 / rat 5 / imp 6 / ghost 7 / sprite 11 → hollow
average **7.3 xp/kill** (×1.55) → **~350 kills, ~9 plain full clears to 17**.
The shared curve stays untouched (ADR 0006), Earthcraft/Wildcraft pacing
unaffected.

---

## Files (for the implementing spec)

| Path | Action |
|---|---|
| `wyrd/scripts/game.gd` | modify — 3 new `PERKS["hunt"]` entries |
| `wyrd/scripts/player_controller.gd` | modify — 2 perk reads in `_derive_stats()`; `add_focus()` helper |
| `wyrd/scripts/combatant.gd` | modify — Even Breath hook in `_die()` (~4 lines) |

No new files. No data-table changes elsewhere.

## Acceptance criteria

1. Trades page shows five Huntcraft perks; Quick Nock / Heavy Draw / Even
   Breath light up at 12 / 14 / 17.
2. At H12, slot 2–4 cooldowns are ~9% shorter (verify `effective_cd` with
   zero CDR gear: BrambleSnare 4.0 → 3.64s).
3. At H14, a crit damage number reads ×2.25 of the non-crit hit (gear-free).
4. At H17, killing a trash enemy visibly bumps the focus globe by 6; focus
   never exceeds `focus_max`.
5. CDR from Quick Nock + gear still clamps at `CDR_CAP` (0.80).
6. All three headless tests stay green (`WYRD_NO_SAVE=1`).

## Open questions

1. **Cap enforcement is nobody's child yet.** ADR 0006 says "the cap is
   enforced at award time," but `game.gd::award_xp` has no clamp today.
   Which 45-* spec owns the shared `lv 17` guard? This spec assumes it
   lands once, centrally — not per-trade.
2. **The 14→17 quiet stretch** (792 xp). Recommended: accept — 12/14 align
   with the Boar/Wolf den levels and the capstone deserves a run-up. If
   playtests find it flat, the fallback is moving Heavy Draw to 15 (gaps
   become 384/696/544), not adding a fourth perk.
3. **Capstone timing vs the Queen.** If playtests show H17 reliably landing
   *after* the Summit kill, consider a den-boss xp doubling (boss-role
   bonus at the same `_die()` site, one line) so Even Breath is usable in
   the final fight — the chain has only 3–4 boss kills, so it adds ≤100 xp
   total and can't distort trash pacing.
4. **Even Breath refund value.** 6 is the anchor (12% of the pool, ~2s of
   in-combat regen); tune within 4–8 in playtest before touching anything
   structural.
5. **Trophy-odds territory.** A "trophies drop more often" perk was
   considered for H17 and rejected: the `marked_quarry` chart affix
   (carto 16) already owns that lever, and giving Huntcraft the same dial
   muddies which trade owns drop luck. Recorded so it isn't re-proposed.

## References

- `docs/adr/0005-huntcraft-single-combat-trade.md` — one trade, kill xp
  formula, "how you fight, not how much"
- `docs/adr/0006-demo-level-cap-17.md` — cap 17, extend-don't-compress,
  curve unchanged, cap enforced at award time
- `wyrd/scripts/game.gd` — `PERKS`, `SKILL_REQS`, `SKILL_POOL`,
  `xp_for_level`, `award_xp`
- `wyrd/scripts/player_controller.gd` — `_derive_stats()` perk reads
  (lines ~912–918), `FOCUS_MAX`/regen, `SKILL_FACTORY`
- `wyrd/scripts/combatant.gd` — kill award (line ~671), crit math
  (lines ~183–186), `apply_knockback` (line ~355)
- `wyrd/scripts/skills/` — the 9 shipped skills; `skill_effect.gd`'s
  anticipated subclass comment
- `wyrd/scripts/layout_loader.gd` — `ENEMY_KINDS`, `BOSS_KINDS`,
  `SPAWN_TABLES`, trash-count formula (line ~747)
- `wyrd/data/charts.gd` — den affixes at carto 8/12/14, Tyrannical /
  Festival Pace, chart completion xp
- `docs/WORLD_BIBLE.md` — voice: plain, warm, no fantasy-isms

## Done check

- [ ] Level table covers 1–17 with every shipped unlock placed correctly
- [ ] Three new perks named in-voice with stat/value/mechanism each
- [ ] Exactly one behavioral perk, hook files + line counts stated
- [ ] Skill-gate recommendation argued; alternative fully specced
- [ ] Kills-to-17 math grounded in shipped HP values and spawn tables
- [ ] Contingency xp tweak shown with math, gated on playtest evidence
