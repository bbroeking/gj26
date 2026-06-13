---
type: concept
tags: [mmo-research, progression, xp-curves, leveling, endgame, retention, seasons, leagues, talent-trees, power-creep, horizontal-progression]
status: draft
updated: 2026-06-13
sources:
  - https://oldschool.runescape.wiki/w/Experience
  - https://yukaichou.com/gamification-analysis/wow-endgame-item-level-progression/
  - https://www.pcgamer.com/world-of-warcrafts-level-cap-is-being-reduced-to-60/
  - https://medium.com/@PatKrane/leveling-up-the-leveling-system-in-world-of-warcraft-8bfba4c6848c
  - https://www.engadget.com/2014-02-05-mmo-mechanics-comparing-vertical-and-horizontal-progression.html
  - https://massivelyop.com/2019/10/31/massively-overthinking-the-problem-with-mmo-dailies/
  - https://gamerant.com/live-service-battle-pass-seasons-fomo-wow-overwatch-2-diablo-4-bad/
  - https://digitaledge.org/the-live-service-hangover-how-constant-seasons-are-burning-out-players-and-devs/
  - https://www.gdcvault.com/play/1025784/Designing-Path-of-Exile-to
  - https://runescape.fandom.com/wiki/Skills
  - https://forums.mmorpg.com/discussion/502333/vertical-vs-horizontal-progression-how-i-think-you-can-have-both
  - https://pathofexile.fandom.com/wiki/Passive_skill
---

# MMO Progression Systems

A synthesis of how massively multiplayer games structure character advancement — covering XP curve mathematics, level vs skill-based models, vertical vs horizontal progression, talent trees, endgame gear treadmills, and retention loop design — with analysis applicable to Wayfinder's [[Trades and Leveling]], [[Skills]], and [[Balance Philosophy]].

---

## 1. XP Curves: The Mathematics of the Treadmill

An XP curve determines how long each level takes and how that time changes as the player advances. The shape of the curve is one of the most consequential single decisions in an RPG's design.

### The OSRS formula: the genre benchmark

Old School RuneScape uses the most-cited XP formula in the genre:

```
XP(L) = floor( (1/4) × sum_{i=1}^{L-1} floor(i + 300 × 2^(i/7)) )
```

Key milestones:

| Level | Cumulative XP | Notes |
|---|---|---|
| 1 | 0 | Starting point |
| 25 | ~7,200 | Early milestone |
| 50 | 101,333 | First mastery milestone; ~10 casual hours |
| 70 | 737,627 | Solid competence; ~70 casual hours |
| 92 | 6,517,253 | Almost exactly 50% of the XP to 99 |
| 99 | 13,034,431 | Skill mastery; max XP cap is 200,000,000 |

**The key mathematical property:** after approximately level 30, the exponential factor predominates and the XP required **doubles for each 7 additional levels**. This is why level 92 requires almost exactly 50% of the total XP needed for level 99 — the last 7 levels from 92 to 99 cost as much as the first 92 combined. In practical terms, a player who reaches level 92 has done "half the work" to 99, even though 92 *feels* close to the end.

This property creates the famous OSRS pace-feel: early levels are fast (forming habits, learning systems), mid-levels stretch (developing mastery), and high levels are an explicit commitment signal.

**Why it works psychologically:**
- Variable-ratio reinforcement: XP accumulates continuously with every action, providing constant micro-feedback.
- Milestone spacing: the doubling property spaces meaningful milestones (50, 70, 80, 90, 92, 99) so there is always a medium-term goal visible.
- Social signaling: high-level skills are visible to others, creating status display.

### Linear vs exponential curves

| Curve shape | Feel | Risk |
|---|---|---|
| **Linear** (flat cost per level) | Each level costs same effort; feels earned then grindy | Low ceiling; high-level players reach max too fast |
| **Quadratic** (cost ∝ n²) | Steady acceleration; moderate grind | Can feel arbitrary without milestone structure |
| **Exponential** (OSRS: doubles every 7 levels) | Fast early, steep late; high levels are rare/prestigious | Alienates casual players who feel they can't reach the top |
| **Hybrid: fast early, slow late** (WoW leveling) | Hook fast, retain long | Requires careful content density across the full range |

### WoW level squish: when exponential growth breaks the new-player experience

After 16 years of expansion-over-expansion level cap increases (60 → 70 → 80 → 85 → 90 → 100 → 110 → 120), WoW's leveling had become dissociated from meaningful feedback. With Shadowlands (2020), Blizzard implemented a **level squish**: level 120 compressed to level 50, new cap set at 60.

Design rationale: "leveling didn't feel meaningful anymore." Goals of the squish:
1. Every level-up unlocks a tangible reward (new ability, talent point, or upgrade).
2. New players pick one expansion to level through (10→50), experiencing its complete story.
3. After an expansion retires from max-level content, it rotates into the leveling pool.

The squish addressed a structural problem: vertical XP treadmills inevitably inflate over time as developers add content. If unchecked, the treadmill becomes the new-player experience — a grinding slog through content that was designed for veterans — before the actual game begins. The squish is a one-time reset, not a systematic fix; the underlying inflation dynamic resumes with each expansion.

---

## 2. Levels vs Skills: Classes vs the RuneScape Model

### Class-based systems (WoW, most MMOs)

In class-based progression, character creation selects a role (warrior, mage, rogue). All advancement is constrained within that role's power budget. Talent trees provide within-class customization.

**Advantages:**
- Onboarding clarity: players know immediately what their character does.
- Balanced group content: designers tune for known role combinations.
- Strong identity: "I am a Paladin" is a meaningful statement of playstyle and community belonging.

**Disadvantages:**
- "Wrong class" regret: players who choose at creation without full information can feel locked into a bad choice.
- Social friction: class mismatch creates loot competition and group composition anxiety.
- Limits horizontal exploration: switching to a new class requires starting a new character in most games.

### Skill-based classless systems (OSRS, RuneScape 3)

RuneScape has no class. Characters are blank slates defined entirely by which of the **24 skills** (OSRS) they have trained and to what level.

"In RuneScape, every player can be equally good at everything." Accessibility claim: any player can train any skill at any time — there is no wrong-path character creation. The tradeoff is that new players must research which skills matter to their goals, since the game provides less guided progression than class-based alternatives.

The skill-based model is also RuneScape's core retention mechanism: the breadth of independent 1–99 progressions means there is always a distinct skill progression in progress, regardless of what activity the player prefers. A player who tires of combat can pivot to Farming or Herblore without feeling their time investment was wasted.

### Hybrid: talent/perk trees within classes

The dominant contemporary design. WoW's talent tree (class-specific node choices per level) and Path of Exile's passive skill tree (a single shared tree of 1,384 nodes, all classes use it but start at different positions) represent two ends of this spectrum.

**PoE passive tree design:**
- All seven classes share one tree; class determines starting position and unlocks three Ascendancy sub-class options.
- Players allocate one node per level (plus quest rewards).
- Near-infinite build variation: the number of viable paths through 1,384 nodes creates emergent build diversity the developers themselves cannot fully enumerate.
- Keystones (high-value nodes that fundamentally change mechanics) create distinct build identities within the shared graph.

**WoW talent tree design (post-Dragonflight rework):**
- Class-specific and specialization-specific trees per character.
- Nodes are much smaller in count (~40–80 per tree) and more curated.
- Less emergent than PoE; more legible and less overwhelming for new players.
- Trade-off: fewer truly "surprising" builds; the meta solution to each tree is usually well-known.

---

## 3. Vertical vs Horizontal Progression

### Vertical progression (the dominant model)

Vertical progression = increasing raw power over time. Gear tiers, level caps, item level increments — all forms of vertical advancement.

**Advantages:**
- Tangible "getting stronger" feedback loop; satisfying power fantasy.
- Simple legibility: higher number = better.
- Content tiering becomes natural: each tier requires the gear from the previous tier.

**Disadvantages:**
- **Power creep**: each expansion's gear obsoletes the previous. Old content becomes trivially easy ("overgeared soloing") or irrelevant.
- **Gear-based gatekeeping**: players in older gear tiers are excluded from high-end group content by both mechanics and social pressure. Item level becomes a proxy for "deserving" to participate.
- **Skill masking**: sufficiently high gear compensates for low player skill, muddying progression.

### Horizontal progression (the alternative)

Horizontal progression = expanding *breadth* of capability rather than increasing raw power. Multiple viable builds, gear choices, and content routes at the same power ceiling.

**Advantages:**
- Older content remains viable and relevant; no mudflation.
- Rewards strategic thinking ("which tool for this situation?") rather than pure time investment.
- Lower social gating: broad range of gear states can participate in a given piece of content.

**Disadvantages:**
- Harder to design: every option must remain viable, requiring more tuning investment.
- Less visceral "power ramp" feedback; some players find the plateau demotivating.
- Finite horizontal breadth: once all sidegrades are collected, engagement drops.

**Guild Wars 2** is the most-cited horizontal experiment. Its stated design was to cap gear progression (Exotic tier) and provide horizontal variety via Legendary cosmetics and stat-swappable builds. However, the introduction of "Ascended" gear partially reintroduced a vertical tier, and community debate continues about whether the hybrid works.

### Mixed strategies

Most successful games use vertical progression early (forming habits, providing clear wins) and supplement with horizontal options in the endgame (preventing the "I've caught up, now what?" problem):

- OSRS: 24 independent vertical skill ladders (1–99 each) plus horizontal depth in rare drops, minigames, and unlockable areas.
- PoE Leagues: each season resets vertical progress to zero, but builds from prior seasons remain relevant for planning — horizontal knowledge persists across resets.
- Wayfinder (design intent): [[Trades and Leveling]] provides four vertical tracks; the [[Chart Loop]]'s affix system adds horizontal decision texture at each tier.

---

## 4. The Endgame Treadmill: Gear Score, Item Level, and Catch-Up

WoW's endgame is the canonical gear treadmill. After hitting the level cap, progression shifts entirely to **item level (ilvl)** — the average power rating of equipped gear, which has no ceiling and grows with each patch.

**Structure of the WoW treadmill:**
1. Entry-level heroic dungeons → Normal raid gear.
2. Normal raid → Heroic raid gear.
3. Heroic raid → Mythic raid gear.
4. Each tier: a 10–20 ilvl step. Small enough to feel earned, large enough to be meaningful.
5. Seasonal reset: new expansion zone quest rewards exceed the previous season's raid gear, converting months of progression into "vendor trash." This is psychologically analogous to loss aversion — players re-engage to recover lost relative standing.

**Seasonal catch-up mechanics:**
- The ilvl floor rises each patch; alts and returning players gear faster than main characters did at the same point in the season.
- WoW tracks highest ilvl per gear slot; upgrading below that floor receives a large resource discount.
- PoE's seasonal league migration: after a league ends, characters transfer to the permanent Standard league, retaining all progress but in an economy that has accumulated years of wealth — a one-way gate that doesn't punish seasonal players.

**Gear score as social gating:**
The unintended consequence of visible item level: it becomes a participation filter. Group content leaders require minimum ilvl for invites, excluding players in catch-up gear regardless of skill. The irony: catch-up mechanics address the power gap but not the social gatekeeping that item level visibility enables.

---

## 5. Retention Loops: Dailies, Weeklies, FOMO, and Seasons

Retention mechanisms keep players returning regularly. The design spectrum ranges from intrinsic (the content is genuinely appealing) to extrinsic (external incentives or anxiety-driven compulsion).

### Daily and weekly cadences

**Reset-based content** (daily dungeon lockouts, weekly raid resets, capped weekly resources) provides reliable re-engagement triggers. The psychology: players return because missing a reset is felt as a loss, not because they are excited about the content.

The design failure mode (Massively Overpowered, 2019): "the shift from 'I want to play' to 'I need to complete my dailies' is the first symptom of burnout." When daily requirements exceed approximately 1 hour per session, burnout onset accelerates — players are forced to take involuntary breaks from games they still nominally enjoy.

**FFXIV's approach** (widely cited as the industry alternative to WoW's mandatory daily model): the Challenge Log provides optional bonus XP/rewards for completing a checklist of activities. Players feel behind if they skip it but are not mechanically locked out of progression — the primary gear pathway (weekly capped tomestones and raid clears) resets weekly, not daily. This reduces daily obligation anxiety while preserving weekly re-engagement.

### Battle passes and FOMO

The modern battle pass (Fortnite prototype, adopted by WoW, Diablo IV, and most live-service games) is the most aggressive form of FOMO-driven retention: paid content that expires on a fixed date, with progress gated by session frequency.

**Design mechanism:** players who bought the pass feel psychologically obligated to play enough to capture its full value before expiration. Even if the content is uninteresting, the sunk-cost creates sessions.

**Player response (2024–2026):** "live-service hangover" — a reported widespread burnout from the accumulation of simultaneous battle passes across multiple games, each demanding daily attention. Game Rant, Digital Edge, and others documented the pattern of player exhaustion with the model. Riot adjusted VALORANT's pass based on player feedback (added XP weekends, more generous level-up rates).

### Seasons and leagues as fresh-start mechanics

Path of Exile's **League** model is the most influential alternative retention architecture. Every 3 months:
1. A new league launches with a fresh economy and a new gameplay mechanic.
2. Every player starts at level 1 in the new league economy — no advantage for veterans.
3. The new mechanic is featured prominently for the duration; after migration, it enters Standard at lower emphasis.

**Why leagues work:**
- Fresh economy eliminates the "I'm too far behind established players" problem for returning players.
- The new mechanic provides genuine curiosity-driven re-engagement, not FOMO.
- 3-month cadence is long enough for players to feel progression, short enough to prevent permanent staleness.
- Player count spikes sharply with each league launch, demonstrating that the fresh-start mechanic is the primary driver of re-engagement, not the battle pass equivalent.

Chris Wilson's economic integrity principle applies here: seasonal leagues maintain their re-engagement power precisely because the economy is unspoiled — no pay-to-win shortcuts, no exploit survivors, no year-one veterans holding enormous advantage. The fresh-start promise must be genuine.

### The ethics of retention

Retention design sits on a spectrum:

| Design | Psychology | Ethics |
|---|---|---|
| Intrinsically engaging content | Curiosity, mastery, social connection | Neutral-positive |
| Optional bonus rewards (FFXIV Challenge Log) | Opportunity enrichment | Broadly acceptable |
| Daily caps + weekly resets (WoW) | Scheduled reinforcement; mild FOMO | Mixed — depends on session requirements |
| Expiring battle passes | FOMO + sunk cost | Contested; declining player tolerance |
| RNG lootboxes with real money | Variable ratio reinforcement | Widely criticized; regulated in several jurisdictions |

The dominant critical framing: retention mechanics that rely primarily on **loss avoidance** (FOMO, sunk-cost) rather than genuine content appeal cause burnout because they create obligation without intrinsic satisfaction. Players who feel they *must* play rather than *want* to play churn eventually regardless of incentive layer thickness.

---

## 6. Relevance to Wayfinder

**XP curve:** [[Trades and Leveling]] uses a quadratic formula (`xp_for_level(n) = (n-1)² × 8 + (n-1) × 32`) rather than the OSRS near-exponential formula noted in [[Balance Philosophy]]. The implemented curve is intentionally shallower — the level step grows linearly (16n + 24 XP per additional level) rather than exponentially. This is appropriate for a demo-scope game capped at level 17 where the OSRS exponential would barely distinguish early levels. If the cap lifts to 50+, revisiting the curve against the OSRS formula is warranted.

> Note: [[Balance Philosophy]] documents the OSRS formula (xp = sum of floor(i + 300 × 2^(i/7)) / 4) as the design inspiration and calibration reference, while `wyrd/scripts/game.gd::xp_for_level` implements the simplified quadratic. The two are not the same formula. The OSRS formula is the aspiration for post-demo scaling.

**Demo cap at 17:** ADR 0006 sets the level cap at 17 — high enough to span the Wayfinding unlock ladder (boss dens at 8/12/14, Summit at 16) without compressing meaningful unlocks into too few levels. Analogous to WoW's "every level must unlock something tangible" squish rationale. The cap also means XP continues to accrue post-17 (no discard), enabling cap lifts without losing player progress.

**Skill-based vs class-based:** Wayfinder's four Trades ([[Wayfinding]], [[Earthcraft]], [[Wildcraft]], [[Huntcraft]]) are a hybrid: not a class selector (players level all four simultaneously) but also not 24 orthogonal skills. Each Trade is thematically distinct and feeds specific verbs. This sits between OSRS's breadth and WoW's class identity — closer to OSRS but narrower, appropriate for a demo scope.

**Vertical vs horizontal:** Current design is explicitly vertical within each Trade (levels 1–17 unlock new capabilities) but with horizontal texture through the [[Affixes]] and [[Chart Loop]] (different affix combinations at the same tier provide different strategic textures). [[Balance Philosophy]] section 7 explicitly lists "treadmill catch-up" as an anti-pattern to avoid, targeting horizontal-alongside-vertical rather than pure vertical.

**Retention philosophy:** [[Balance Philosophy]] section 7 identifies "mandatory daily grind" as an explicit anti-pattern, citing the FFXIV model as the aspiration. Wayfinder has no dailies, no battle pass, no expiring content — a deliberate departure from the live-service FOMO toolkit. The retention mechanism is intrinsic: the chart-inscribe-clear-trophy loop provides session-bounded progress that feels complete without external compulsion.

**Perk trees:** Each Trade's perk ladder (6 perks at specific levels for Wayfinding; 4 each for the others) is a lightweight curated talent tree — legible and milestone-spaced rather than PoE's 1,384-node emergent web. Appropriate for demo scope; the design scales by adding perks at higher levels rather than by expanding the tree structure.

---

## See also

- [[Trades and Leveling]] — Wayfinder's XP formula, four-Trade structure, and perk ladders
- [[Balance Philosophy]] — XP calibration, cozy pacing rules, anti-patterns
- [[Skills]] — hotbar abilities distinct from Trades
- [[Chart Loop]] — the primary retention loop in Wayfinder
- [[Affixes]] — horizontal progression texture within the chart loop
- [[RuneScape]] — the OSRS XP formula and classless skill model
- [[World of Warcraft]] — level squish, item level endgame, talent trees
- [[MMO Economy and Itemization]] — the gear treadmill as an economy phenomenon
- [[MMO Social and Endgame]] — retention, guilds, and the social dimension of endgame
- [[MMO Lessons for Wayfinder]] — cross-cutting design conclusions
- [[MMO Research]] — index of MMO research pages

## Sources

- `kb/raw/mmo/economy-progression.md` — full provenance with quotes and data
- https://oldschool.runescape.wiki/w/Experience — OSRS XP formula and milestones
- https://yukaichou.com/gamification-analysis/wow-endgame-item-level-progression/ — WoW ilvl psychology
- https://www.pcgamer.com/world-of-warcrafts-level-cap-is-being-reduced-to-60/ — level squish rationale
- https://www.engadget.com/2014-02-05-mmo-mechanics-comparing-vertical-and-horizontal-progression.html — vertical vs horizontal analysis
- https://massivelyop.com/2019/10/31/massively-overthinking-the-problem-with-mmo-dailies/ — dailies and burnout
- https://gamerant.com/live-service-battle-pass-seasons-fomo-wow-overwatch-2-diablo-4-bad/ — FOMO and battle pass burnout
- https://www.gdcvault.com/play/1025784/Designing-Path-of-Exile-to — PoE "played forever" design (GDC 2018, Chris Wilson)
- https://pathofexile.fandom.com/wiki/Passive_skill — PoE passive tree facts
- https://runescape.fandom.com/wiki/Skills — RuneScape skills model
