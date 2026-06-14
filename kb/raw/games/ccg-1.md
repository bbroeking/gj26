# Raw Sources: CCG / Autobattler Batch 1

Ingested: 2026-06-14
Feeds: wiki/games/ccg/Hearthstone.md, wiki/games/ccg/Magic The Gathering Arena.md,
       wiki/games/ccg/Legends of Runeterra.md, wiki/games/ccg/Marvel Snap.md,
       wiki/games/ccg/Teamfight Tactics.md

---

## Hearthstone

### Source 1 — Wikipedia: Hearthstone
URL: https://en.wikipedia.org/wiki/Hearthstone
Fetched: 2026-06-14
Key facts:
- Free-to-play digital CCG launched March 11, 2014 (Blizzard Entertainment)
- 30-card constructed decks; hero class determines card pool
- Mana crystals: +1 per turn up to 10, all refreshed at turn start — deterministic ramp, eliminates land variance
- No reactions during opponent's turn — simplifies networking, enables mobile
- Arena: draft 30 cards from sequential 3-card choices; play until 12 wins or 3 losses
- Dust crafting: disenchant unwanted cards for arcane dust; craft target cards at dust cost
- Pack acquisition: 100g per pack; daily quests yield 40–100g; 10g per 3 wins
- Modes: Standard/Wild (rotation), Arena, Tavern Brawl (weekly rotating), Battlegrounds (autobattler, Nov 2019), Mercenaries (roguelike, Oct 2021)
- Engine: Unity; cross-platform PC/Mac/iOS/Android
- 10 million accounts within first month; 100M+ by Nov 2018; ~20M monthly actives (2020)
- Revenue: ~$600M annually (2019 estimate)

### Source 2 — Game Developer: Hearthstone Business Model Case Study
URL: https://www.gamedeveloper.com/business/how-business-model-and-economic-design-can-change-player-s-behavior-the-hearthstone-case
Fetched: 2026-06-14
Key facts:
- F2P gold trickle (40–100g quests; 10g/3 wins) makes real-money packs feel necessary for timely set completion
- 2 major expansions/year ~130 cards each; impossible to keep up in Standard via F2P alone
- Critical finding: gold-per-win incentive pushes F2P players toward fast aggro decks → meta distortion → Blizzard must counteract via card design (treating symptom not cause)
- Pack RNG + dust disenchant at ~25% return value creates meaningful scarcity

### Source 3 — VentureBeat: Hearthstone Year of the Phoenix Economics
URL: https://venturebeat.com/business/hearthstone-year-of-the-phoenix-diving-into-economics-and-monetization/
Fetched: 2026-06-14
Key facts:
- Annual pass models and pre-purchase bundles added to supplement pack economy
- Year-of-the-Phoenix introduced Legendary guaranteed in first 10 packs of a new set
- Core Set (free, refreshes annually) implemented to reduce new player barrier

### Source 4 — GameDesignStrategies: Hearthstone Beta Review
URL: https://gamedesignstrategies.wordpress.com/2013/09/12/hearthstone-beta-designer-review/
Fetched: 2026-06-14
Key facts:
- Original analysis of mana crystal simplification vs. MTG land system
- Hero powers as stable identity anchor (2 mana, once per turn)
- No-interrupt turn design identified as the key differentiator from physical CCGs

---

## Magic The Gathering Arena

### Source 1 — Wikipedia: Magic: The Gathering Arena
URL: https://en.wikipedia.org/wiki/Magic:_The_Gathering_Arena
Fetched: 2026-06-14
Key facts:
- Full rules fidelity: phases (untap/upkeep/draw/main/combat/second main/end), priority passing, stack
- Game Rules Engine (GRE): implements per-card rules individually; Unity client
- Launched Windows Sep 26 2019; macOS Jun 25 2020; iOS/Android Mar 24 2021; cross-save
- Draft: 7 wins or 3 losses best-of-one; break-even at 50% win rate for skilled drafters
- Wildcard system: wildcards earned from packs at set rates; 1:1 exchange for any card of same rarity
- Fifth-copy conversion: common/uncommon → vault progress; rare/mythic → gems
- Formats: Standard (rotating), Historic (non-rotating), Alchemy (digital rebalanced), Explorer
- Dual currency: Gold (earned) and Gems (purchased); packs = 1,000 gold or 200 gems
- Esports: $10M prize pool (2019); Mythic Invitational ($1M)
- ~3M active users projected end of 2019

### Source 2 — Wizards of the Coast: MTG Arena Economy 2022
URL: https://magic.wizards.com/en/news/mtg-arena/mtg-arena-economy-2022-03-17
Fetched: 2026-06-14
Key facts:
- Official statement on economy adjustments: increased wildcard rates, improved mastery pass value
- Confirmed fifth-copy system for commons/uncommons via vault

### Source 3 — Cardmarket: Arena Economy Guide
URL: https://www.cardmarket.com/en/Insight/Articles/Everything-You-Should-Know-About-the-Arena-Economy
Fetched: 2026-06-14
Key facts:
- Detailed breakdown of wildcard earn rates per pack tier
- Historic anthology purchases: buy fixed card sets directly for flat gem price (bypasses RNG)
- Seasonal rewards track (Mastery Pass) provides reliable cosmetic + card progression for pass holders

---

## Legends of Runeterra

### Source 1 — Wikipedia: Legends of Runeterra
URL: https://en.wikipedia.org/wiki/Legends_of_Runeterra
Fetched: 2026-06-14
Key facts:
- Announced Oct 15 2019; full launch April 29 2020 (Riot Games)
- Unity engine; Windows + iOS + Android cross-platform
- Attack token alternates each round; can be passed; some cards allow attack without token
- Spell speeds: Slow / Fast / Burst / Focus (four tiers, not a full stack)
- Champion leveling: condition-based mid-game transform of all copies in deck
- Ten regions; max 2 regions per deck; no neutral cards
- Original monetization: cosmetics only (card backs, boards, guardian pets); no random card packs
- Weekly Vault: tiered chest leveled by weekly play; yields cards, shards, wildcards
- Jan 2024: Riot downsized LoR team; shifted to PvE focus
- Community backlash in 2023 when paid card bundles were introduced, reversing free-card promise

### Source 2 — PC Gamer: LoR Microtransactions
URL: https://www.pcgamer.com/Legends-of-runeterra-coins-microtransactions-economy/
Fetched: 2026-06-14
Key facts:
- At launch: could only buy 3 champion cards per week with coins (pacing mechanism)
- Shard currency earned in-game; used to craft any card directly (no randomness)
- Coins (premium) purchasable for cosmetics; card cost in coins was weekly-capped

### Source 3 — PC Games N: LoR Monetization Philosophy
URL: https://www.pcgamesn.com/legends-of-runeterra/monetisation
Fetched: 2026-06-14
Key facts:
- Riot explicitly stated they didn't want booster pack RNG; wanted players to access any card
- Weekly cap on card purchases was to ensure players always had something to work toward
- Described as "League of Legends cosmetics approach" applied to a card game

### Source 4 — Mastering Runeterra: Does LoR Make a Profit?
URL: https://masteringruneterra.com/does-legends-of-runeterra-make-a-profit/
Fetched: 2026-06-14
Key facts:
- Revenue analysis suggests LoR consistently underperformed vs. Hearthstone and MTG Arena
- Cosmetics-only model generated insufficient revenue to sustain AAA-level competitive development
- Game's generous model won critical acclaim but not commercial success at required scale

---

## Marvel Snap

### Source 1 — Wikipedia: Marvel Snap
URL: https://en.wikipedia.org/wiki/Marvel_Snap
Fetched: 2026-06-14
Key facts:
- Developed by Second Dinner; launched Oct 18 2022 (iOS/Android early access); Aug 23 2023 (Windows full)
- Originally published by Nuverse (ByteDance); transferred to Skystone Games Jan 2025
- 22 million downloads, $200M+ revenue by 2024
- Unity engine; Android/iOS/Windows
- 12-card decks; no duplicates; 6-turn max matches; 3 locations
- Locations revealed turns 1–3, one per turn; each has unique effect
- Win = majority power in 2 of 3 locations
- Snap: either player doubles cube stakes; opponent retreats or accepts; mutual snap doubles twice
- Collection level: XP-gated unlock of cards within pool tiers (Pool 1–5); cosmetic variants purchased
- Season Pass ($9.99/month): premium card + cosmetics; card enters regular pool post-season
- 1,000+ cosmetic card variants available

### Source 2 — Game Developer: Second Dinner Physical Prototype
URL: https://www.gamedeveloper.com/design/why-second-dinner-first-prototyped-marvel-snap-using-physical-cards
Fetched: 2026-06-14
Key facts:
- Prototyped on literal business cards; enforced one-sentence ability text discipline
- Top-down (Marvel IP → mechanic) and bottom-up (game needs → card) design blend
- Visual effects reinforced ability meaning, reducing reliance on text comprehension
- Constraint of physical medium eliminated "small novel" ability text syndrome

### Source 3 — Mobile Gamer: Card Design Secrets
URL: https://mobilegamer.biz/second-dinner-reveals-the-secrets-of-marvel-snaps-onboarding-and-card-design/
Fetched: 2026-06-14
Key facts:
- Onboarding designed to teach via Marvel character recognition (players already know Hulk is big)
- Location randomization identified as primary session variety engine

### Source 4 — Games Hub: Designer Interview
URL: https://www.gameshub.com/news/features/marvel-snap-designer-interview-kent-erik-hagman-smart-card-game-design-31692/
Fetched: 2026-06-14
Key facts:
- "Smart card game design" — simplicity of individual card mechanics enables complex emergent interactions at 3-location intersection
- Location design treated as separate content category from cards (200+ locations, each a mini-mechanic)

---

## Teamfight Tactics

### Source 1 — Wikipedia: Teamfight Tactics
URL: https://en.wikipedia.org/wiki/Teamfight_Tactics
Fetched: 2026-06-14
Key facts:
- Launched June 26 2019 (PC); March 19 2020 (mobile); Riot Games
- Built within League of Legends client; 33 million monthly players by Sep 2019
- 8-player lobbies; hex grid board; shared champion pool across all 8 players
- Champions drawn from League of Legends roster; adapted models
- Trait synergies: N units of same trait activates bonuses at thresholds (2/4/6)
- Interest system: hold gold → earn interest (up to 5g/round at 50g+)
- Streak bonuses: consecutive wins or losses both yield bonus gold
- Augments (Set 6+): 3 times per game, choose 1 of 3 (Silver/Gold/Prismatic tiers)
- Carousel: shared draft round where all players simultaneously pick champion+item
- Set rotation: ~quarterly full set reset; mid-set updates swap problematic traits
- Tacticians (Little Legends): cosmetic avatars; primary monetization (loot boxes + direct purchase)
- Battle pass: seasonal cosmetic progression

### Source 2 — Riot Nexus: TFT Design Pillars (2019)
URL: https://nexus.leagueoflegends.com/en-us/2019/06/dev-design-pillars-of-teamfight-tactics/
Fetched: 2026-06-14
Key facts:
- Three stated design pillars: Mastery, Playful Competition, Discovery
- Mastery: 5 domains (knowledge, flexibility, fortune, perception, speed)
- Playful Competition: social, interactive features; "joyful attitude toward competitors"
- Discovery: gradual champion additions + periodic thematic set rotations
- Differentiated from LoL: de-emphasized click accuracy/reaction speed in favor of strategic planning
- Carousel mechanic: "nexus of tough choices, player interaction, competition, and strategy"
- Long-term plan: rotating thematic sets from League's 1,000+ skins library

### Source 3 — ZiberBugs / Medium: TFT Game Design Analysis
URL: https://medium.com/@ZiberBugs/game-design-analysis-teamfight-tactics-bc6eb5aafeff
Fetched: 2026-06-14
Key facts:
- Economy management identified as primary skill differentiator at high level
- Item combinations create secondary composition decision layer
- Positioning (which hexes units occupy) creates tertiary strategic layer

---

_End of raw source batch ccg-1. All facts cited in wiki pages above._
