---
type: concept
tags: [influences, genre, osrs, cozy, mmo, history, character-creator]
status: draft
updated: 2026-06-13
sources:
  - "docs/cozy-life-sim-design-playbook.md"
  - "docs/mmo-game-design-playbook.md"
  - "docs/online-games-2000-2010-survey.md"
  - "docs/character-creator-research.md"
  - "docs/adr/0003-cozy-skilling-spine.md"
---

# Design Influences

Wayfinder draws from four genre lineages — cozy life-sim, OSRS-style MMO skilling, the 2000–2010 online-game era, and character-creator UX research — each contributing a distinct set of principles that were selectively adopted, adapted, or explicitly rejected.

---

## 1. The genre lineage

### Cozy life-sim (Harvest Moon → Stardew Valley)

The spine of the project (ADR 0003) is cozy skilling, and the cozy life-sim tradition defines what "cozy" actually means mechanically. Three non-negotiable values, as identified in Lost Garden's foundational analysis (`docs/cozy-life-sim-design-playbook.md` §2):

| Value | Wayfinder application |
|---|---|
| **Safety** | No permadeath; death = fade to bed with minor penalty, not failure. |
| **Abundance** | Resources renew; GatherNodes respawn; inks can be purchased from [[NPCs|Hod]] if gathering stalls. |
| **Softness** | Bramblewood palette, IM Fell English typography, fairytale voice (see [[Voice and Tone]]). |

**Adopted:** the Stardew model's cozy pacing dial — "opt-in regret, not failure." The day ends without brutal punishment. **Multiple overlapping reward schedules** (skilling, trophies, chart runs, leveling) so the player always feels something nudging up, even on a "bad" session.

**Adapted:** Stardew's day-as-forcing-function becomes the chart-run-as-forcing-function. Wayfinder's session unit is the dungeon run (enter, delve, return), not a 14-minute calendar day. The cozy loop is gather → craft → chart → delve, not wake → water → sleep.

**Rejected:** the farming-sim literal template (seasons, watering crops, NPC marriage arcs). Those are mechanisms; Wayfinder borrows the *psychology* but runs it through the [[Chart Loop]] rather than an agrarian calendar.

**Relevant games in the lineage:**

| Year | Game | Lesson borrowed |
|---|---|---|
| 1996 | Harvest Moon | Routine-as-comfort; daily-reset-feels-generous |
| 2016 | Stardew Valley | 28-day arc; light combat as optional pressure; visible incremental progress |
| 2020s | Coral Island, Fields of Mistria | Multiplayer cozy; personal plot + shared town hub |
| 2020s | Animal Crossing: NH | Pure cozy without productivity pressure — rejected as *too* pressureless |

### OSRS / RuneScape MMO skilling

Old School RuneScape is the most direct influence on the Trade and leveling structure. Key traits transplanted:

- **Multiple parallel progression vectors.** Four Trades (Wayfinding, Earthcraft, Wildcraft, Huntcraft) mean one stall never kills retention. When the chart loop is blocked, gather or forge. (`docs/mmo-game-design-playbook.md` §2)
- **Every action gives XP.** No dead activities — gathering logs, foraging herbs, and fighting all train distinct Trades.
- **Skill grind that means something.** The OSRS XP curve (`b ≈ 1.104`) is used directly: level 50 ≈ 101k XP, level 99 ≈ 13M XP. The slow ramp is deliberate — it makes leveled Trades feel earned. (`docs/game-balance-playbook.md` §4)
- **Combat is one verb.** ADR 0003 explicitly names the OSRS model: "you are not primarily a fighter." [[Huntcraft]] is a single Trade, not three (attack/strength/defence). (`docs/adr/0003-cozy-skilling-spine.md`)
- **Horizontal endgame.** Completion logs, cosmetics, and Trophy chains rather than a vertical raid treadmill. (`docs/mmo-game-design-playbook.md` §8)

**Adapted:** OSRS's click-to-move + tab-target combat is replaced with real-time WASD + FATE camera (ADR 0004), but the *stakes* of combat remain OSRS-light — trivial mobs fall in 5–15 s, bosses in 30–60 s.

**Rejected:** RuneScape's three combat skills (attack/strength/defence) — would turn the Trades screen into a stat block and weight combat above skilling (ADR 0005).

### The 2000–2010 online-game era

The survey (`docs/online-games-2000-2010-survey.md`) catalogues the era that locked in the genre vocabulary Wayfinder inherits. Key patterns:

**Adopted:**
- **Grind that means something.** Modern games shortcut progression; Wayfinder keeps the OSRS curve's weight so a level 17 cap *feels* earned inside the demo. Players who came up on RS feel the right curve immediately.
- **Community-as-content.** The survey notes FFXIV and BDO's appearance-string export as a community multiplier; character sharing is flagged for post-jam implementation.
- **Persistent-world ticks.** Day/night cycles, GatherNode respawn, and NPC schedules create stakes even when the player is not in a dungeon.
- **Built-in social glue (post-multiplayer).** When [[Multiplayer Co-op]] ships, the town hub should force passive contact — don't instance everything.

**Rejected from the era:**
- **Forced grouping** (EverQuest style) — incompatible with solo-friendly cozy design.
- **PvP / territory control** — outside genre scope entirely.
- **Subscription / gacha monetization** — if Wayfinder ever monetizes: cosmetic-only, per the RS/MapleStory precedent.

### Character-creator research

The research (`docs/character-creator-research.md`) establishes the scope spectrum from Animal Crossing (lightest) to BDO/Saints Row (maximum sliders). Wayfinder targets **light** — between OSRS and Stardew:

| Axis | Decision |
|---|---|
| Scope | Preset swatches (hair, skin, tunic, cape); no sliders for jam |
| Preview | Real-time rotating 3D (already shipped) |
| Random button | Add — 80%+ players use it at least once |
| Re-customization | Free at the cottage mirror (cozy default, not a gold sink) |
| Body/voice | Single body type for jam; no gender lock |
| Save/share | localStorage jam scope; export-to-string post-jam |

**Adopted universal patterns:** presets as starting points; random button; cinematic 3/4 preview framing; re-customization in-game.

**Rejected:** BDO-style deep sliders (mismatched to the toon-painted, low-poly art style); gender-locked classes (BDO paid for this in reviews); "male/female" binary (behind the curve as of 2026).

**Noted for post-jam:** appearance-string export/import (FFXIV `.dat` pattern) — community sharing is a content multiplier with near-zero dev cost once the system exists.

---

## 2. Cross-cutting principles that shaped Wayfinder

Drawing the lineages together, five principles proved durable across all four sources:

### A. One forcing function, gently applied
Cozy life-sim: energy + day cycle. Wayfinder: the chart run + dungeon depth. The player is never forced to stop — but optimal play has a natural rhythm. (`docs/cozy-life-sim-design-playbook.md` §8)

### B. Multiple progression vectors
RuneScape's cheat code for retention: four Trades, trophy chain, gear tiers, and [[Affixes]] mean one stall never kills a session. (`docs/mmo-game-design-playbook.md` §5; `docs/online-games-2000-2010-survey.md` §3.A)

### C. Optional everything (except the core loop)
The Stardew principle: combat optional (ADR 0003), min-maxing rewarded but not required, completion voluntary. The game suggests but does not gate. (`docs/cozy-life-sim-design-playbook.md` §7)

### D. Visible, incremental progress
Skill bar, level-up flash, Trophy chest — something always nudging upward. This is the cozy anti-anxiety design: even a "bad" run yields XP, gear, or materials. (`docs/mmo-game-design-playbook.md` §5)

### E. The creator matches the game
Light character-creator scope fits low-poly toon art. A BDO-style slider interface would be genre-inappropriate. The creator's aesthetic derives from the [[Art Bible]] UI Kit. (`docs/character-creator-research.md` §1, §5)

---

## 3. Explicit rejections

| Pattern | Source | Why rejected |
|---|---|---|
| ARPG spine (combat is core) | ADR 0003 | Most competitive genre; sidelines [[Wayfinding]] (the differentiator) |
| New World co-equal hybrid | ADR 0003 | Effectively two games; maximum scope/risk for solo dev |
| Three combat trades (atk/str/def) | ADR 0005 | Turns Trades screen into stat block; weights combat above skilling |
| WoW vertical raid treadmill | mmo-playbook §8 | Exhausts content fast; exclusionary; unsustainable for small team |
| Mandatory daily grinds | mmo-playbook §5 | Time-respect is cozy principle; FFXIV/GW2 win here vs WoW chain |
| Maximum-slider character creator | cc-research §1 | Scares casuals; mismatched to game depth |
| Genuinely scarce resources | cozy-playbook §7 | Anxiety without payoff; breaks cozy promise |
| Permadeath / real save loss | cozy-playbook §7 | Genre-fatal |

---

## See also

- [[Balance Philosophy]] — the concrete balance decisions downstream of these influences
- [[Trades and Leveling]] — the four-Trade structure derived from OSRS parallel-vector model
- [[Chart Loop]] — the differentiating system that is Slice 2 (ADR 0003)
- [[Combat]] — "one verb" bounded by the OSRS model (ADR 0003, 0004, 0005)
- [[Economy]] — faucets/sinks following MMO-playbook §7
- [[Multiplayer Co-op]] — personal plot + shared town hub, influenced by cozy-MMO section
- [[Design Decisions]] — ADR digest (especially ADR 0003, 0005)
- [[Art Bible]] — toon-painted style that constrains character-creator scope

## Sources

- `docs/cozy-life-sim-design-playbook.md` — Harvest Moon/Stardew lineage, cozy psychology, safety/abundance/softness values
- `docs/mmo-game-design-playbook.md` — Bartle types, multiple progression vectors, economy faucets/sinks, endgame archetypes
- `docs/online-games-2000-2010-survey.md` — RuneScape, EverQuest, Habbo, era cross-cutting patterns
- `docs/character-creator-research.md` — scope spectrum, universal patterns, gj26-specific recommendations
- `docs/adr/0003-cozy-skilling-spine.md` — the identity lock (cozy skilling as spine)
