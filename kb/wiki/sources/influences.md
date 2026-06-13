---
type: source
tags: [source-digest, influences, balance, cozy, mmo, osrs, character-creator]
status: draft
updated: 2026-06-13
sources:
  - "docs/cozy-life-sim-design-playbook.md"
  - "docs/mmo-game-design-playbook.md"
  - "docs/online-games-2000-2010-survey.md"
  - "docs/character-creator-research.md"
  - "docs/game-balance-playbook.md"
  - "docs/adr/0003-cozy-skilling-spine.md"
---

# Source Digest: Influences and Balance

Digest of six documents read during the [[Design Influences]] and [[Balance Philosophy]] ingest pass (2026-06-13).

---

## Documents ingested

### `docs/cozy-life-sim-design-playbook.md`

Condensed reference for Harvest Moon / Stardew Valley / Story of Seasons-style design, explicitly tailored to gj26. Covers:

- Genre lineage: HM 1996 → Stardew 2016 → modern cozies
- Cozy psychology: Safety / Abundance / Softness triad (Lost Garden)
- Three-loop structure: micro (one action) / meso (one day) / meta (one season)
- Calendar design: 28-day season, 14-min day, gentle time pressure
- Energy / stamina as forcing function (not punishment)
- NPC heart system, schedule design, and marriage mechanics
- Activity stack principle: complementary, not redundant
- Cozy anti-patterns: permadeath, mandatory grinds, loud UI, punishing min-maxers
- "Opt-in regret" tension dial (Stardew-level = sweet spot for gj26)
- Multiplayer: personal farm + shared town hub pattern preferred over shared farm
- Decision matrix and MVP slice scoped for a game jam

**Pages fed:** [[Design Influences]], [[Balance Philosophy]], [[Multiplayer Co-op]], [[Economy]]

---

### `docs/mmo-game-design-playbook.md`

Condensed reference for MMO and MMO-flavored games, biased toward RuneScape-shaped / small-team projects. Covers:

- Bartle's four player types: Achiever / Explorer / Socializer / Killer — pick two
- Csíkszentmihályi's flow: skill↔challenge ratio; burst mastery as flow events
- Three-loop model: micro / meso / meta; rule that meta feeds back into micro
- Balance definitions: fairness / viability / pacing; Sirlin's distinction
- Combat archetypes: tab-target, action, hybrid, click-to-move; recommendation for cozy = click-to-move or tab-target
- Progression and retention: churn stage → cause → fix; multiple progression vectors as the retention cheat code
- Social design: Dunbar brackets (5 / 15 / 50 / 150 / 1500)
- Economy: faucets and sinks; player auction + 2% tax sink pattern (RS Grand Exchange); every faucet needs a matching sink
- Endgame: horizontal (RuneScape skill 99s, collection logs) vs. vertical (WoW raids); horizontal recommended for small team
- Failure postmortems: WildStar as canonical dual-audience trap

**Pages fed:** [[Design Influences]], [[Balance Philosophy]], [[Economy]], [[Trades and Leveling]], [[Multiplayer Co-op]]

---

### `docs/online-games-2000-2010-survey.md`

Survey of the 2000–2010 online-game era — the golden age that locked in the genre vocabulary. Covers:

- Era traits: browser-first / low-spec, social-heavy, community-driven, persistent worlds, slow meaningful progression
- Full survey table by category: big MMORPGs (UO, EQ, RS, WoW, CoH, FFXI, EVE, GW1, MapleStory…), browser/social (Neopets, Habbo, Club Penguin, AdventureQuest…), browser strategy (OGame, Travian), lobby games (CS, D2, WC3)
- Ten cross-cutting patterns: multiple progression vectors; persistent world ticks; grind that means something; built-in social glue; community-as-content; F2P + cosmetic monetization; server-reset cadence; identity through character expression; slow generous tutorials; live events
- "What we lost" section: player-run servers, meaningful grinds, forced grouping (in moderation), episodic small content, cosmetic-only monetization
- gj26-specific application table: RS multiple vectors → four Trades; community-as-content → appearance-string export post-jam; charm in writing → KoL lesson; etc.

**Pages fed:** [[Design Influences]], [[Trades and Leveling]], [[Multiplayer Co-op]], [[Onboarding and Tutorial]]

---

### `docs/character-creator-research.md`

Cross-game survey of character-creator scope, patterns, and UX recommendations. Covers:

- Scope spectrum: Animal Crossing (lightest) → Stardew → OSRS → WoW → FFXIV → Elden Ring → BDO → Saints Row (maximum)
- Case studies for each position with retention/attachment signals
- Universal patterns: presets as starting points; random button is mandatory above light scope; real-time 3D preview beats static portrait; body/voice/pronouns now independent axes; save/load/share creates attachment; re-customization economy as a design lever (free / gold cost / paid item)
- 3-tab heuristic: Body / Face / Style
- Smoke test: 90-second ship for casual + 30-minute depth for enthusiast
- gj26 recommendations: light scope (OSRS ↔ Stardew); name, hair, skin, tunic, cape; random button (add now); 4 starter presets; free re-customization at cottage mirror; appearance-string export post-jam
- Code sketches: random button event listener; PRESETS object (Knight, Druid, Bard, Wanderer)

**Pages fed:** [[Design Influences]], [[UI and HUD]], [[Onboarding and Tutorial]]

---

### `docs/game-balance-playbook.md`

Deep reference on balance theory and practice for single-player/cozy/RPG. Covers:

- Sirlin's three concepts: fairness / viability / pacing — don't conflate
- Depth as the reward of good balance (chess vs. tic-tac-toe)
- Math toolkit: DPS, EHP, TTK, damage formula, XP/HR — the five governing numbers
- Target TTK by genre (cozy = 5–15 s trivial mob)
- Three damage formula families: subtractive (recommended for gj26 — intuitive, OSRS-classic), multiplicative (LoL/Dota — scales clean), roll-based (OSRS post-2007 hit chance + maxHit)
- XP curve families: linear (treadmill), quadratic (natural), exponential (OSRS `b ≈ 1.104` — recommended)
- OSRS curve formula and key XP milestones (level 50 = 101k, 99 = 13M)
- Linear vs. multiplicative tier scaling — linear recommended for cozy (old gear usable, not invalidated)
- Balance loop: define targets → math → generate content → playtest worst case → tune formulas → repeat
- Three test cases catching 80% of bugs: underleveled / overleveled / spec-mismatch
- Telemetry-driven balance (Riot LoL signals: win rate 48–52%, pick rate >3%, ban rate <30%)
- Without telemetry (gj26): spreadsheet math, pre-mortem playtests against three player archetypes, 3-5 friend playtest, AI sim
- Anti-patterns catalog: power creep, dominant strategy, dead options, false complexity, math floor failure, no counter-play, punitive randomness, hidden math, treadmill catch-up, snowball locks
- Genre-specific tuning: cozy = "always winnable, occasionally tense, never frustrating"; never one-shot below 50% HP; always allow retreat
- gj26-specific application table: subtractive dmg, 5–8 s trivial TTK, OSRS XP curve, linear tier scaling, math + 3-friend playtest, ~monthly patch cadence
- Code sketches: `xpForLevel(L)` (OSRS formula in JS), `rollDamage(attacker, defender)`, brute-force fight simulator

**Pages fed:** [[Balance Philosophy]], [[Economy]], [[Combat]], [[Trades and Leveling]]

---

### `docs/adr/0003-cozy-skilling-spine.md`

Architecture Decision Record 0003. The identity-lock document. Covers:

- Context: project was pulling in three directions (OSRS skilling, New World gathering depth, FATE/Diablo ARPG combat) with no stated spine
- Decision: **cozy skilling is the spine**; combat is one verb (OSRS model); ARPG roadmap specs 30–43 recontextualized as seasoning
- Considered and rejected: ARPG spine (most competitive genre, sidelines the differentiator); co-equal hybrid (New World model, effectively two games, maximum scope)
- Downstream commitments: three.js `src/` is design prototype only (port decisions/data); vertical-slice-first; slice 1 = gather → cook → sustain → fight; cartography (chart loop) is slice 2
- Engine confirmed as Godot (not re-opened by this decision)
- When to revisit: slice 1 fails playtest; combat playtests as more compelling than skilling; cartography is dropped

**Pages fed:** [[Design Influences]], [[Balance Philosophy]], [[Design Decisions]], [[Chart Loop]], [[Trades and Leveling]]

---

## Key contradictions and open questions noted

- The character-creator research is written against the three.js prototype (`cc-form`, `SWATCHES`, `previewApply`). The Godot port status of the character creator is not tracked here — check `wyrd/scenes/` for a CharacterCreator scene or equivalent.
- ADR 0003 refers to "ARPG roadmap specs 30–43" as now demoted seasoning. Those specs may contain balance or design details that contradict the cozy pacing rules in the balance playbook — worth a targeted contradiction scan if specs 30–43 are ever re-implemented.
- The cozy-playbook and online-games survey both flag **live calendar events** (festivals, holidays) as a high-value retention tool. Wayfinder's current implementation scope is unknown — check `wyrd/scripts/game.gd` and the roadmap for festival scheduling.
- The online-games survey recommends **server-reset cadence** (Travian 200-day pattern, Diablo 2 ladder) as underused in modern MMOs. Relevant if [[Multiplayer Co-op]] ever ships seasonal fresh-start runs.
