# MMO Game Design Playbook

A deep, condensed reference for designing MMO (or MMO-flavored) games that are *fun, balanced, and interesting* — biased toward small-team / cozy / RuneScape-shaped projects but applicable broadly.

---

## 1. What "fun" actually is

There is no single fun. Different brains get different rewards. Plan for **at least two of these motivations** or you build a niche game by accident.

### Bartle's four player types (the foundation, MUD1, 1996)

| Type | Acts on | Acts with | What they want |
|---|---|---|---|
| **Achievers** | World | — | Levels, gear, achievements, completion. "I beat it." |
| **Explorers** | World | — | Map corners, lore, hidden systems, secrets, mechanic depth. "I found it." |
| **Socializers** | — | Players | Friendships, guilds, chat, weddings, drama. "I'm with people." |
| **Killers** | — | Players | PvP, world bosses, leaderboards, dominance. "I beat *you*." |

Use it diagnostically: which type is your design *accidentally* serving? RuneScape leans Achiever + Explorer with Socializer scaffolding. EVE is Killer + Achiever heavy. FFXIV is Socializer + Achiever. Don't try to serve all four equally — pick a primary and a secondary.

### Csíkszentmihályi's flow

The skill ↔ challenge ratio. Too easy → boredom. Too hard → anxiety. Players stay engaged when challenge ramps just slightly ahead of skill. **Implication for MMOs**: gate progression so the challenge curve always feels reachable but not trivial. Bursts of mastery (a clutch dodge, a clean rotation) are flow events; design moments where they happen often.

### The four kinds of fun (Lazzaro)

1. **Hard fun** — challenge & mastery (boss kill, PvP win)
2. **Easy fun** — exploration, novelty, curiosity (new biome, new pet)
3. **Serious fun** — meaning, change, belief (helping a guildmate, building something lasting)
4. **People fun** — social interaction (banter, shared hardship)

Most MMOs nail Hard + Easy. The retention winners (FFXIV, RuneScape, EVE) also nail People fun.

---

## 2. Core loops — micro, meso, meta

Every MMO needs three nested loops:

| Loop | Tick | Activity | Example (RuneScape) | Example (WoW) |
|---|---|---|---|---|
| **Micro** (seconds) | Each click/tick | The thing you do | Click rock, get ore, animation plays | Cast → cast → cooldown → cast |
| **Meso** (minutes) | A "session" | Goal-driven sequence of micros | Mining run: gather a load, bank it, repeat | Quest: kill 10 boars, return |
| **Meta** (hours/weeks) | Long arcs | Progression that re-skins the micro/meso | Skill 1→99, unlocks new tier of rocks | Dungeon → gear → harder dungeon |

**Rule:** the meta loop must feed *back into* the micro loop, making it slightly different (new sound, new visual, new mechanic, new location). RuneScape is the canonical example — mining at level 50 *feels* different from mining at level 10 because the rocks, locations, and animations changed enough to mark progress.

**Pitfall:** reskinning without rebalancing. WoW's gear treadmill became "same fight, bigger numbers" — Achievers loved it for years, then got fatigue. Your meta loop needs to introduce a *new vector* every few cycles, not just bigger digits.

---

## 3. Game balance — definitions and methods

### Three distinct things people call "balance"

1. **Fairness** — given equal skill, no player has a structural advantage (PvP).
2. **Viability** — each option/build/class has a meaningful use-case (no dead choices).
3. **Pacing** — challenge is appropriate to player progression (PvE).

You can have any one without the others. Don't conflate them in design discussions.

### Balance methods

| Method | Use it for | Cost |
|---|---|---|
| **Symmetric design** | Chess, Pong | Boring beyond a point |
| **Asymmetric — intransitive (rock-paper-scissors)** | Class A > B > C > A loops | Removes meaningful in-game choice once matchup is known |
| **Asymmetric — orthogonal differences** | Different tools for different jobs (mage vs warrior solve same problem differently) | Hard to tune |
| **Mathematical modelling** | DPS spreadsheets, time-to-kill targets | Demands data; Riot/Blizzard scale only |
| **Playtesting + telemetry** | Anything with humans | Slow, but truth |
| **Self-balancing economies** | Player-driven markets | Emergent — needs intervention when broken |

### Key principles

- **No dominant strategy.** If one option is strictly better, the others are decoration. Cut them or buff them.
- **Meaningful choices.** A choice with no tradeoff isn't a choice. Always ask: "what does this option give up?"
- **Counter-play exists.** Every powerful thing must have a counter — even if asymmetric (e.g., burst-DPS class is countered by sustain or mobility).
- **Avoid power creep.** New content that invalidates old gear is the cheapest retention trick and the most expensive long-term cost.

### Sirlin's distinction (essential reading)

David Sirlin: *fairness* is about starting conditions (PvP), *balance* is about the meta-game over time (which strategies win across a population). A symmetric game can still have terrible balance if 90% of players converge on one strat. Tournament play reveals balance; casual play reveals fairness.

---

## 4. Combat archetypes — pick deliberately

| System | Strength | Weakness | Examples | Good for |
|---|---|---|---|---|
| **Tab-target** | Designable boss mechanics, accessible, low input load, supports complex builds | Less viscerally exciting, "rotation trance" | WoW, FFXIV, RuneScape | Casual playerbase, deep build-craft |
| **Action combat** | Visceral, marketable, positioning matters | High input load (excludes casuals), constrains boss design (telegraphs everywhere) | BDO, Lost Ark, ESO action mode | Younger / console-feeling audience |
| **Hybrid** | Best of both, configurable | Lots of design surface to balance | GW2, ESO, Wildstar | Mixed audiences |
| **Turn-based** | Tactical depth, asynchronous-friendly | Pacing can feel slow in MMO | Atlas Reactor, some indies | Strategy crowd, mobile-first |
| **Click-to-move + skill** | Easy on hands, runs anywhere | Reads as "old" | RuneScape | Cozy/idle audiences |

**Important:** ~80% of MMO playerbase is casual. Action combat *looks* harder but actually has a lower skill ceiling than a deep tab-target rotation game. Don't equate "twitchy" with "deep."

For a RuneScape-flavored project: tab-target or click-to-move is the right call. Don't try to ship action combat in a game jam — the camera and feel polish required is enormous.

---

## 5. Progression & retention

### The retention curve (industry data)

| Player cohort | 1-year retention |
|---|---|
| Launch month | ~6% (10x the rest) |
| 12 months in | ~0.6% |
| 24+ months in | rises again — self-selected diehards |

Translation: launch matters. Get the first 30 days right or you don't have a game.

### Where players churn (and why)

| Stage | Churn cause | Fix |
|---|---|---|
| **Hour 1** | Confusion, boring tutorial, ugly first impression | Hero moment in <10 min; readable UI; one core verb early |
| **Day 1–7** | No progression visible | Visible level-ups, frequent rewards, see-the-next-goal |
| **Week 2–4** | Hit a content/skill wall | Multiple progression paths so one can stall while another moves |
| **Month 1–3** | No social ties formed | Force soft socialization (city hubs, world events, party-finder) |
| **Month 3+** | Endgame drought, daily-quest burnout | Optional dailies; horizontal not vertical endgame; expansions |

### Retention tactics that work

- **Multiple progression vectors** (level + skills + cosmetics + housing + reputation). When one stalls, another moves.
- **Time-respectful design.** Don't punish missed days. FFXIV and GW2 win here vs. WoW's daily reset chains.
- **Sticky social moments early.** Force first-week players into shared content (dungeon, world boss, hub event).
- **Predictable content cadence.** Players will leave if you don't refresh, but they'll come back if you've trained them to expect a drop.

### Anti-pattern: WildStar

Six years late, "hardcore endgame attunement" walled off 95% of players, mixed messaging ("get hardcore, cupcake" tone repelled casuals it needed). Lesson: pick your audience early, validate it cheap, don't ship a 9-year game to a market that's moved on.

---

## 6. Social design — Dunbar-aware

Robin Dunbar: humans cap at ~150 meaningful relationships. Online behaviour follows the same curve. Design with these brackets:

| Layer | Size | Function | Examples |
|---|---|---|---|
| **Core friends** | 5 | Tight party | Static raid group, daily co-op |
| **Sympathy group** | 15 | Active guild core | Small guild, weekly raid |
| **Active network** | 50 | Guild that still feels like a "group" | Mid-size guild |
| **Dunbar's 150** | 150 | Maximum cohesive community | Large guild, game's social ceiling |
| **Tribe / faction** | 1500 | Recognition, not relationship | Faction, server, alliance |

### Implications

- **Guild caps matter.** 500-person mega-guilds break socially around 150 active. Either cap them, or design tools (officer roles, sub-guilds, channels) that let them shard internally.
- **Multiscale design.** Solo / duo / 5-man / raid / world-event / faction — every player needs entry points at every scale.
- **Make randoms recognizable.** Persistent cosmetics, naming, profiles — turning strangers into "the dwarf I keep seeing in the meadow" is the single biggest social retention multiplier.
- **Don't make solo punishing.** Players shouldn't be *forced* to socialize, just nudged. Socializers will find each other; everyone else just needs the option.

---

## 7. Economy design

A virtual economy is **faucets** (currency/items entering the world) and **sinks** (currency/items leaving). Imbalance in either direction is fatal.

### Failure modes

| Imbalance | Result | Real example |
|---|---|---|
| Too many faucets | Inflation, gold becomes worthless, pay-to-win pressure rises | Diablo 3 launch |
| Too few faucets | Deflation, new players locked out, hoarders dominate | Tibia early years |
| Items don't decay/destruct | Market saturates, items lose value | Most early MMOs |
| Bots/RMT exploit faucets | Currency floods, real-money trading dominates | RuneScape pre-Jagex crackdown |

### Sinks that work (in order of player tolerance)

1. **Repair costs.** Invisible sink, accepted as "realism."
2. **Travel/teleport fees.** Convenience tax.
3. **Consumables.** Potions, food, ammo. Reliably destroyed.
4. **Auction-house tax.** RuneScape GE: 2% trade tax. EVE: broker fee + sales tax. Largest sink in EVE for years.
5. **Cosmetics.** Whales pay for them. Keeps gold tier-flat.
6. **Vanity sinks** (housing, mounts, pets). RuneScape's Construction skill is a brilliant gold sink disguised as content.
7. **Taxes on player-to-player trade.** Forces value to evaporate on every transaction.

**Hard rule:** every faucet needs a sink of comparable magnitude. Audit them quarterly.

### Player-driven vs NPC-driven markets

| Model | Pro | Con |
|---|---|---|
| **NPC vendor at fixed price** | Predictable, anti-bot | No emergent economy |
| **Player auction (RuneScape GE)** | Good UX, player-driven, taxable | Botable — needs intervention |
| **Pure player markets (EVE)** | Maximum emergence | Brutal for new players |
| **Hybrid (GW2)** | Easy on-ramp | Tax tuning is constant work |

**Lesson from EVE:** they hired a real economist in 2007. If your economy matters, treat it as a designed system, not an afterthought. Publish the data (EVE's monthly economic reports) and players will self-police.

---

## 8. Endgame — the hardest design problem

The contradiction: leveling content is for the 95% who'll quit; endgame is for the 5% who stay. You can't make both groups happy with the same systems.

### Endgame archetypes

| Type | Example | Pros | Cons |
|---|---|---|---|
| **Vertical raid treadmill** | WoW classic | Clear targets, prestige gear | Exhausts content fast, exclusionary |
| **Horizontal collection** | RuneScape skills, FFXIV jobs | Endless, casual-friendly | Lacks "summit" feeling |
| **PvP / arena** | Old-school WoW arena, EVE | Self-renewing content (other players) | Toxic without moderation |
| **Player-driven content** | EVE wars, guild politics | Cheapest content for devs | Requires critical mass |
| **Sandbox creation** | Wurm, Eco | Players make content | Hard to design *into* without losing themepark feel |

### Endgame design rules

- **Don't rush players to it.** Stretch leveling — most never reach endgame anyway.
- **Stack it horizontally.** Multiple endgame paths (PvP, raids, collection, social) give different player types a reason to log in.
- **Avoid mandatory grinds.** Optional dailies > required dailies. WoW Azerite trait reset = textbook anti-pattern.
- **Make endgame visible to non-endgame players.** Seeing endgame players in town wearing legendary gear is itself content for the leveling crowd.

---

## 9. Common failure modes (the postmortem checklist)

Before shipping any MMO design decision, test against these:

- [ ] **Vision drift.** Long dev cycles → market shifts → game ships into a world that no longer wants it (WildStar's 9 years).
- [ ] **Dual-audience trap.** "Hardcore endgame for raiders + casual for everyone else" usually means *neither* group gets a good game.
- [ ] **Frontloaded everything.** Showing your best content in the first 5 minutes burns the dopamine loop. Pace the reveal.
- [ ] **Server stability and FPS.** Day-1 lag is unrecoverable for a third of the launch cohort.
- [ ] **Anti-social systems.** If your most efficient strategy is solo, players won't form guilds. If they don't form guilds, they leave at month 3.
- [ ] **No reason to log in tomorrow.** Daily/weekly resets are crude but they work. Replace them with *better* hooks, not nothing.
- [ ] **Economy in freefall.** Gold becomes worthless within 6 months → real-money trading takes over → the game is now an MMO with a black market.
- [ ] **Cosmetics gated behind real money but not gameplay.** Achievers want to *earn* prestige. Whales-only cosmetics insult them.

---

## 10. Decision matrix — small-team cozy MMO

Tailored to a project like gj26 (toon-painted, RuneScape-flavored, jam-scoped, three.js client):

| Decision | Default | Reason |
|---|---|---|
| Combat | Click-to-move + skill abilities (RS-style) | Lowest input load, runs in browser, fits cozy mood |
| Player types served | Achiever (primary) + Socializer (secondary) | Skill grinds + chat hubs, classic RS recipe |
| Progression | Multi-skill horizontal | Stalls in one don't kill retention |
| World | Hub + zones, not seamless | Easier to ship; portals/teleports are forgivable in stylized worlds |
| Combat balance | Asymmetric orthogonal (different roles) | Avoid rock-paper-scissors metas in a casual game |
| Economy | Player auction + 2% tax sink | Proven RS pattern, scales |
| Social unit cap | 50-person clan, in-clan channels | Inside Dunbar's sympathy bracket |
| Endgame | Horizontal (skill 99s, collection logs, cosmetics) | Sustainable for small team |
| Dailies | Optional with stacking | Don't punish missed sessions |
| First-hour goal | One quest, one skill level-up, one social interaction | Hits all three retention vectors |

---

## 11. MVP slicing — what to ship in a jam

You cannot ship "an MMO" in a jam. You can ship a *vertical slice* that demonstrates the loop. Cut ruthlessly:

**In scope (MVP):**
- One zone (hero shot quality)
- One skill loop (e.g., woodcutting → fish → cook → eat)
- One combat encounter (one mob type, one weapon)
- One social affordance (chat, /wave, see other players)
- One persistent thing (inventory saves)

**Out of scope (jam-fatal):**
- PvP
- Trading
- Guilds with hierarchies
- Multiple zones
- Multiple classes
- Quest chains
- Voice / matchmaking
- Authentication beyond a name

The goal of the MVP is to *prove the loop is fun for 20 minutes*. If it isn't, no amount of content saves it.

---

## 12. Checklists

### "Is this fun yet?" smoke test

- [ ] Does the core verb feel good in isolation? (Mining a single rock, swinging a single sword.)
- [ ] Does the meso loop have a clear short-term goal? (Fill the inventory, kill the named mob.)
- [ ] Does the meta loop visibly progress in <10 minutes? (Skill bar moves, gear changes, area unlocks.)
- [ ] Is there one moment of surprise/delight in the first session?
- [ ] Can a new player succeed in their first 60 seconds?

### "Is it balanced?" smoke test

- [ ] Is there a dominant strategy? (If yes, fix or remove the weak ones.)
- [ ] Does every choice have a tradeoff?
- [ ] Is there counterplay to every powerful option?
- [ ] Does new content invalidate old? (Power creep audit.)
- [ ] Are early-game decisions still relevant late-game?

### "Will players stay?" smoke test

- [ ] Visible progression in first 10 minutes
- [ ] Multiple progression paths so one stall ≠ quit
- [ ] Forced soft-social moment in first week
- [ ] Reason to log in tomorrow (not just FOMO)
- [ ] No mandatory daily punishment for missed sessions

---

## 13. References

**Foundational theory**
- Bartle, R. (1996). *Hearts, Clubs, Diamonds, Spades: Players Who Suit MUDs* — [Wikipedia summary](https://en.wikipedia.org/wiki/Bartle_taxonomy_of_player_types)
- Csíkszentmihályi, M. (1990). *Flow: The Psychology of Optimal Experience*
- Lazzaro, N. *4 Keys to Fun*
- Koster, R. *A Theory of Fun for Game Design*
- [Lost Garden — Game design patterns for friendships](http://www.lostgarden.com/2017/01/game-design-patterns-for-building.html)

**Balance**
- [Sirlin — Balancing Multiplayer Games (Part 1: Definitions)](https://www.sirlin.net/articles/balancing-multiplayer-games-part-1-definitions)
- [Game Design Skills — Game Balance Definitive Guide](https://gamedesignskills.com/game-design/game-balance/)

**Retention & loops**
- [Game Design Skills — Core Loops](https://gamedesignskills.com/game-design/core-loops-in-gameplay/)
- [Game Design Skills — 17 Player Retention Strategies](https://gamedesignskills.com/game-design/player-retention/)
- [Bakharev — So You Want to Build an MMO (series, Medium 2026)](https://medium.com/@alexander.bakharev_16063/so-you-want-to-build-an-mmo-7-18-retention-live-service-operations-7d3486eaba18)

**Economy**
- [1kxnetwork — Sinks & Faucets in Virtual Economies](https://medium.com/1kxnetwork/sinks-faucets-lessons-on-designing-effective-virtual-game-economies-c8daf6b88d05)
- [The Economics of Gaming — EVE Online](https://theeconomicsofgaming.wordpress.com/2017/04/23/eve-online-part-1/)
- [Bilir — RuneScape economy SSRN paper](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=1655084)
- [FasterCapital — ISK Sink or Faucet (EVE)](https://fastercapital.com/content/ISK-Sink-or-ISK-Faucet--The-Economic-Balance-in-EVE-Online.html)

**Social design**
- [Project Horseshoe — Dunbar's Number for Online Worlds](https://www.projecthorseshoe.com/2018/10/15/using-dunbars-number-to-design-online-worlds/)
- [Lost Garden — Social Design for Human-Scale Online Games](https://lostgarden.com/2018/12/29/social-design-practices-for-human-scale-online-games/)
- [Raph Koster — Dunbar's Number Online](https://www.raphkoster.com/2009/02/27/dunbars-number-matters-online-too/)

**Combat**
- [MMORPG.com — Tab vs Action: Reviving the Debate](https://www.mmorpg.com/editorials/tab-targeting-vs-action-combat-reviving-the-ancient-mmo-debate-2000133018)
- [Massively OP — Tab vs Action discussion](https://massivelyop.com/2017/01/12/massively-overthinking-tab-target-vs-action-combat-in-mmorpgs/)

**Failure postmortems**
- [Game Design Skills — 10 Reasons WildStar Failed](https://gamedesignskills.com/game-design/why-did-wildstar-fail/)
- [Bio Break — Why WildStar Failed](https://biobreak.wordpress.com/2021/08/24/why-wildstar-failed/)
- [Massively OP — Why Do So Many MMOs Fail](https://massivelyop.com/2024/05/31/vague-patch-notes-why-do-so-many-mmos-fail/)
- [MMORPG.com — Why MMOs Fail](https://www.mmorpg.com/editorials/why-mmos-fail-a-look-at-why-some-games-failed-to-break-into-the-genre-2000124689)

**Endgame**
- [Game Developer — The Contradiction of MMO Endgame](https://www.gamedeveloper.com/design/the-contradiction-of-design-in-mmo-endgame-content)
- [MDPI — Final Fantasy MMORPG Evolution from Explorer/Achiever Perspectives](https://www.mdpi.com/2078-2489/12/6/229)
