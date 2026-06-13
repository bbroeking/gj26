# Raw Provenance: MMO Economy and Progression Research
*Ingested: 2026-06-13. Do not edit — raw facts + source URLs only.*

---

## Economy: Faucets, Sinks, Inflation

### Faucets & Sinks (Game Developer / Scott Hartsman)
Source: https://www.gamedeveloper.com/design/the-f-words-of-mmos-faucets

- MMOs operate on a MIMO (money-in, money-out) model; currency generation = faucet, currency removal = drain/sink.
- The author argues the "real faucet" in many MMORPGs isn't gold drops but the overflow of gathered/crafted items that flood markets and drive price deflation when players undercut to sell junk.
- Pure currency faucets are bounded by NPC price floors and ceilings — items can never sell below buyback or above vendor prices, creating natural limits on gold inflation.
- Gold buying = negligible economic harm (comparable to receiving gear from friends). Gold *farming* (via hacking, account compromise, RMT exploits) is the genuine damage vector: causes credit card fraud, account theft, and MasterCard/Visa fines for studios. Quote: "Over the last three or four years, I would dare anybody to ask an exec at a gaming company how much they've had to pay in Master Card and Visa fines." — Scott Hartsman, Trion Worlds.
- EverQuest II's nine-craft system created alchemist monopolies — a few players could stall the entire economy, illustrating how opaque interdependency enables exploitation.
- Recommended design checklist: gatherable resources accessible to new players; reward specialization without monopoly; allow role-switching; transparent transaction systems (visible buy/sell order books); prioritize equipment drains over currency drains; avoid permanent gear.

### Gold Sinks (Wikipedia)
Source: https://en.wikipedia.org/wiki/Gold_sink

- Gold sink = "an economic process by which a video game's ingame currency ('gold'), or any item valued against it, is removed."
- Two categories:
  - **Passive sinks**: item degradation, consistent taxes, natural decay — low friction, continuous.
  - **Active sinks**: accelerated decay, NPC-vendor cosmetics priced above intrinsic value, feedback-control dynamic pricing — high-intervention.
- Real examples:
  - Ultima Online: exclusive blue-tinted armour purchasable at inflated NPC prices (cosmetic sink).
  - RuneScape Construction skill: players spend millions building houses — no tradeable output, pure sink.
  - Kingdom of Loathing: high-priced collectibles with zero gameplay value drained "meat" currency.
- Systems can be **linked** (destroyed items return raw materials to world) or **unlinked** (items simply vanish). Unlinked = simpler removal; linked = maintains ecological balance.

### Mudflation
Source: https://medium.com/@msahinn21/designing-game-economies-inflation-resource-management-and-balance-fa1e6c894670 and https://massivelyop.com/2015/09/13/mmo-mechanics-economic-stagnation-in-mmo-economies/

- **Mudflation** = item devaluation caused by new expansions introducing strictly stronger gear, making old "god-tier" items worthless overnight.
- Named after MUD (Multi-User Dungeon) precedents.
- OSRS mitigation: favors horizontal variety (situational side-grades) over pure vertical power; item sinks (GE tax, Zulrah scales, high-alchemy) preserve value in lower tiers.
- Diablo III early launch: gold dropped everywhere, repair costs were trivial, stockpiles ballooned into the millions — new players couldn't buy meaningful gear while wealthy players dictated prices.
Source: https://askagamedev.tumblr.com/post/757353839637790720/mmorpg-ingame-economies-have-inflation-thats

---

## Marketplaces: WoW AH vs OSRS GE vs EVE Regional Markets

### OSRS Grand Exchange
Source: https://oldschool.runescape.wiki/w/Grand_Exchange

- Introduced 26 February 2015 (OSRS); passed community poll with 76.3% approval.
- First-come-first-served matching with price prioritization: buy offer below existing sell price matches "at the lowest sell offer; buyer gets gold back." Sell offer above existing buy price matches "at the highest buy offer; seller gets more gold."
- Buy limits: quantity cap per 4 hours per item. No sell limits. Purpose: prevent market corners on critical items (e.g., Prayer Potions). Related items (different potion doses) share one limit.
- Price updating: supply/demand driven; low-volume items (partyhats) update every few days or weekly.
- GE 2% transaction tax introduced December 9, 2021 (raised from 1% to 2% on May 29, 2025), capped at 5M coins per trade. Jagex uses collected tax to purchase and delete regulated items weekly — a gold/item sink.
- Members: 8 GE slots. Free-to-play: 3 slots, cannot trade members-only items.
- Price range enforcement prevents extreme manipulation; Jagex reserves intervention rights.
- Community impact: GE became a "public square" / social hub despite performance issues from player density.

### WoW Auction House vs Grand Exchange: Design Tradeoffs
Source: https://www.mmo-champion.com/threads/2309852-Auction-House-or-Grand-Exchange, https://arxiv.org/pdf/2210.07970

- WoW AH: individual listings, buyer must find each cheapest listing separately (addons like Auctioneer/TSM make this tractable); allows manual price-scouting and arbitrage.
- OSRS GE: automated price-matching, no need to advertise or meet counterparty; items/coins collectible at any bank. Reduces friction dramatically but removes some price-discovery and bartering gameplay.
- GE limits market manipulation more aggressively (buy limits + price range caps); AH relies more on player behavior and addon ecosystem.
- Academic study (arxiv 2210.07970) notes GE-style automated clearing creates efficient, transparent markets but limits arbitrage edge.

### EVE Online Regional Market
Sources: https://www.gamedeveloper.com/pc/ccp-economist-on-i-eve-online-i-s-pure-capitalist-market, https://www.fastcompany.com/3024392/meet-the-alan-greenspan-of-virtual-currency-in-eve-online, https://www.ccpgames.com/news/2025/ccp-games-appoints-central-bank-economist-stefan-thorarinsson-to-advance

- CCP hired Dr. Eyjolfur Gudmundsson (PhD, Rhode Island) as lead economist in 2007 — first in-house MMO economist in the industry.
- EVE = "pure capitalist" player-driven market on a single server (Tranquility). No NPC price floors or government interventions. Supply/demand entirely emergent.
- Prices jump near-instantly when changes are published, demonstrating very high market efficiency.
- Gudmundsson quote: "The number of possible one to one relationships grows like the square of a population" — single-server scale enables emergent institutions.
- When CCP removed the Tritanium price cap: "The market went berserk!" — prices ultimately dropped contrary to expectations, mirroring real-world economic unpredictability.
- Speculative dynamics verified: when devs announced mineral scarcity on the test server, players engaged in speculative buying before changes went live.
- Core economic stability: everything is crafted, everything can be destroyed — continuous replacement demand prevents stagnation.
- In 2025 CCP hired Stefán Þórarinsson (former Central Bank of Iceland economist) for the new EVE Frontier project.

---

## Binding: BoP / BoE / Account-Bound

Sources: https://wowpedia.fandom.com/wiki/Bind_on_Pickup, https://www.gamedev.net/forums/topic/678343-soulbound-items-in-mmorpgs/5290363/

- **Bind on Pickup (BoP)**: item binds to player the moment it enters inventory. Cannot be traded, sold, or mailed. Purpose: prevents purchasing best gear outright; forces engagement with challenging content; reduces gold farmer/RMT incentive (items can't be transferred).
- **Bind on Equip (BoE)**: item binds only when equipped. Can be traded beforehand, listed on AH. Creates a secondary market for raiders to sell unwanted drops; gold-wealthy players can buy in.
- **Account-Bound (BoA)**: tradeable between player's own characters. Catch-up mechanism for alts.
- Design tradeoff: pure BoE economy → everything purchasable → massive gold farming, bot economy. Pure BoP economy → kills player-to-player trade, undermines crafters. Most modern MMOs use a mix.
- Warcraft's group loot 2-hour grace window: BoP drops can trade to other group members for 2 hours post-drop, allowing loot redistribution without permanent BoE.

---

## Diablo III Auction House Disaster

Sources: https://www.gamespot.com/articles/ten-years-later-lessons-from-diablo-iiis-auction-house-disaster-have-not-been-remembered/1100-6503489/, https://unrealitymag.com/economics-101-with-diablo-3s-real-money-auction-house/, https://www.purediablo.com/diablo-3-auction-house-is-closing

- D3 launched (2012) with both a gold AH and a Real Money AH (RMAH).
- Core reward loop ("kill monsters → get loot") was short-circuited: buying items on the AH was faster and more reliable than finding them in-game.
- Gold inflation: gold dropped everywhere, repair costs negligible → gold stockpiles ballooned into the millions → new players locked out of meaningful gear purchases.
- Blizzard suspected of intentionally balancing drop rates to push RMAH purchases (cut of every transaction).
- Shutdown: March 18, 2014. Concurrent with "Loot 2.0" overhaul (smart loot: class-weighted drops) and Reaper of Souls expansion.
- Loot 2.0 design goal: "playing the game is the most rewarding path to getting items."
- Key lesson: an in-game marketplace must complement the core reward loop, not bypass it.

---

## RMT and Gold Farming

Sources: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=917124 (Castronova), https://firstmonday.org/ojs/index.php/fm/article/download/3035/2566

- Castronova (2005, "Synthetic Worlds"): EverQuest's "Norrath" had GDP-per-capita comparable to several real-world countries. RMT trade volume grew to hundreds of millions of dollars.
- Castronova's analogy: RMT in MMOs disrupts gameplay similarly to trading Monopoly properties for real money mid-game — the assumed social contract is broken.
- Gold farming (grinding for currency to sell for real money) creates: account hacking, credit card fraud, bot armies, server load issues.
- Detection study (ACM CHI Play 2025): anomaly detection frameworks using trade graph analysis can identify gold farming clusters with high accuracy.

---

## Itemization: Affixes, Rarities, Loot Tables

Sources: https://game-wisdom.com/critical/loot-tables-game-design, https://www.gamedeveloper.com/design/the-differences-between-random-and-randomized-progression, https://www.sportskeeda.com/mmo/unlike-diablo-4-path-exile-2-makes-rares-count-post-unique-world

- ARPG rarity tiers: Normal (0 affixes) → Magic (1–2) → Rare (3–6) → Unique (fixed affixes, named items). Rarity controls affix count; affix tiers scale with item level.
- PoE / D3 itemization: items can only drop from enemies at or above their base level. Base type is locked — lower-tier bases never become higher-tier. Affix tiers scale with item level.
- **Randomized vs. random progression** (Game Developer): randomized loot in ARPGs is structured — clear triggers (boss kill, chest), quality scales with level, alternative paths (crafting, trading) exist as backstops. Pure random (lootboxes) = no agency, unpredictable advancement, frustration.
- D3 "smart loot": class-relevant items get higher weight when generating item attributes — reduces bad-luck streaks.
- PoE 2 design: Rares are intended as primary power sources; Uniques provide special mechanics rather than raw stats — this is "make Rares count."
- Last Epoch: deterministic crafting — players control which affixes appear and upgrade them deliberately. Reduces RNG frustration; encourages experimentation.
- **Loot treadmill**: gear upgrades gate access to the next content tier, which drops the next gear tier. Creates continuous engagement but can feel mandatory/exhausting if vertical gaps are too steep.

---

## Path of Exile Leagues / Economy Integrity

Sources: https://www.gdcvault.com/play/1025784/Designing-Path-of-Exile-to, https://www.notebookcheck.net/Path-of-Exile-co-creator-online-RPGs-must-protect-their-economies-even-if-it-costs-developers-cash.1199206.0.html

- GDC 2018: Chris Wilson outlines PoE's "played forever" design: predictable seasonal release cadence, content reusability, procedural generation, layered randomness, deep systems.
- Seasonal Leagues: everyone starts fresh in a new league (fresh economy + new mechanic for 3 months). After league ends, characters migrate to Standard (permanent league). This prevents permanent-league veteran advantage and resets the economy each season.
- Economic integrity stance: progression must come from play and skill, not exploits, bots, purchased accounts, or pay-to-win. Wilson advocates rollbacks + cosmetic compensation for major exploits (never stat rewards). Harsh ban enforcement, including account deletion for economy-disrupting cheating.
- GGG admitted one misstep: allowing paid streamers to skip login queues on launch day — created unfair early-economy advantages; "rightly called out."
- Passive skill tree: 1,384 nodes, all classes share the same tree but start at different positions. Class = starting point + 3 ascendancy options, not a hard role lock. Near-infinite build combinations.

---

## Progression: XP Curves

### OSRS XP Formula
Source: https://oldschool.runescape.wiki/w/Experience

Exact formula:
```
XP(L) = floor( (1/4) × sum_{i=1}^{L-1} floor(i + 300 × 2^(i/7)) )
```

Key milestones:
| Level | Total XP |
|-------|----------|
| 1 | 0 |
| 50 | 101,333 |
| 70 | 737,627 |
| 92 | 6,517,253 |
| 99 | 13,034,431 |

- "By around level 30, the exponential factor predominates, so that the amount of experience required **doubles for each 7th level**."
- Level 92 = almost exactly 50% of level 99's XP — the "92 is half of 99" rule. Emerges from the doubling property.
- ~10% more XP per level in early tiers; fully exponential from ~level 30.
- Max storable XP: 200,000,000 (stored as 32-bit fixed-point integer).
- Difference between level 98 and 99 alone: 388,653 XP.

### WoW Level Squish (Shadowlands)
Sources: https://www.pcgamer.com/world-of-warcrafts-level-cap-is-being-reduced-to-60/, https://medium.com/@PatKrane/leveling-up-the-leveling-system-in-world-of-warcraft-8bfba4c6848c

- Shadowlands squished level 120 → level 50, new cap 60 (2020).
- Design rationale: leveling in WoW "didn't feel meaningful anymore." Goal: every level = a tangible unlock (new ability, talent, or upgrade).
- New players pick one expansion to level through (10→50), experiencing its full story arc.
- Each new expansion rotates into the leveling pool after its max-level era ends.

### WoW Endgame Item Level Treadmill
Source: https://yukaichou.com/gamification-analysis/wow-endgame-item-level-progression/

- Two-ladder architecture: Character Level (bounded, fast, hooks new players) + Item Level (unbounded, asymptotic, retains veterans).
- At max character level: "the game starts a different game without telling you."
- Item level = tiny increments (392, 393, 395…). Each upgrade earnable in one session.
- Seasonal catch-up: gear floor rises each patch; gearing an alt in month 3 is 2× faster than gearing a main in week 1.
- Psychological drivers: Scarcity (daily/weekly resets), Social Influence (ilvl gates group access), Unpredictability (variable loot tables). Seven of eight "Core Drives" active simultaneously.
- Criticism: relies heavily on "Black Hat" anxiety motivators (loss avoidance, FOMO) rather than intrinsic satisfaction.

---

## Progression: Levels vs Skills

### RuneScape's Classless System
Sources: https://runescape.fandom.com/wiki/Skills, https://informer.rsbandb.com/2020/08/is-runescapes-lack-of-a-class-system-what-made-it-popular/

- OSRS: 24 skills (15 F2P, 9 members-only), each leveled independently 1–99.
- No class selected at character creation — characters are blank slates shaped entirely by which skills they train.
- "In RuneScape, every player can be equally good at everything." Eliminates the "wrong class" regret problem.
- Disadvantage: players must research which skills matter to their goals — no guided progression.

### Vertical vs Horizontal Progression
Source: https://www.engadget.com/2014-02-05-mmo-mechanics-comparing-vertical-and-horizontal-progression.html

- **Vertical**: level/gear tiers; higher tier invalidates lower; creates power creep; gates endgame content behind gear score.
  - Advantages: low barrier to entry, simple progression, focused resource investment.
  - Disadvantages: masks player skill; devalues old content; social gating by gear level.
- **Horizontal**: diverse viable builds/items at the same power level; situational choices matter; no single "best."
  - Advantages: keeps older content relevant; broader accessibility; creative problem-solving.
  - Disadvantages: harder to balance; complexity curve; less visceral "getting stronger" feeling.
- Guild Wars 2: attempted horizontal endgame; community debates whether "ascended gear" reintroduced unwanted vertical creep.
- EverQuest II Alternate Advancement: simultaneous horizontal + vertical tracks.

---

## Retention Loops

Sources: https://massivelyop.com/2019/10/31/massively-overthinking-the-problem-with-mmo-dailies/, https://gamerant.com/live-service-battle-pass-seasons-fomo-wow-overwatch-2-diablo-4-bad/, https://digitaledge.org/the-live-service-hangover-how-constant-seasons-are-burning-out-players-and-devs/

- **FOMO-driven retention**: developers weaponize Fear of Missing Out — battle passes are paid content that expires; if not completed in time, rewards are lost.
- Symptom of burnout: shift from "I want to play" → "I need to complete my dailies."
- Tipping point: when daily time requirements exceed ~1 hour, burnout onset accelerates; players take forced breaks.
- Ethical alternative: agency-driven progress. Choice of which content to run, no single mandatory track. Riot adjusted VALORANT Battle Pass after player feedback (added XP weekends, more generous level-ups).
- FFXIV approach (compared to WoW): Challenge Log is optional; players feel behind when missing it but are not mechanically locked out. Primary progression (gear) is gated by weekly caps, not daily caps — reduces daily obligation anxiety.
- PoE league philosophy: new season resets progress, restoring the joy of a fresh start without punishing players who missed prior seasons permanently.
