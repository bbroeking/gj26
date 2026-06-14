---
type: game
tags: [game-study, sports, racing, simulation, collection, economy, always-online, controversy, progression]
status: draft
updated: 2026-06-14
sources:
  - "https://www.dexerto.com/gaming/gran-turismo-7-devs-quickly-backtrack-on-credits-controversy-1791210/"
  - "https://www.digitaltrends.com/gaming/gran-turismo-7-credit-payout-update/"
  - "https://www.thedrive.com/news/44911/gran-turismo-7-is-sorry-will-give-1m-free-credits-and-make-serious-changes"
  - "https://gamerant.com/gran-turismo-7-how-to-complete-every-menu-book-rewards/"
  - "https://gamerant.com/gran-turismo-7-online-connection-always/"
  - "https://tomsguide.com/news/gran-turismo-7-maintenance"
---

# Gran Turismo 7

Polyphony Digital's 2022 love letter to automotive culture — 430+ meticulously modelled cars, a campaign built around car-collecting Menu Books, and a credit economy so initially tight it triggered the worst user-review bombing of any Sony first-party title.

## Design

**Core loop.** Players earn Credits (in-game currency) by racing, then spend them on cars in the Used Car Dealership, Legend Cars (rare vintage models), or on tuning parts. The primary campaign is the GT Café, a curated story-wrapper in which Luca, the café owner, assigns Menu Books — 39 at launch, expanded via post-launch patches — each asking the player to collect three thematically linked cars and win a specified championship. Completing Menu Books unlocks new dealerships, race categories, and story vignettes about automotive history.

**Standout mechanic: car as collector's item.** GT7 leans harder into the museum-piece framing than any prior entry. Cars have detailed interior renders, engine sounds recorded from real vehicles, and a dedicated Scapes mode for photographic staging. Approximately 90% of the 430+ cars are modelled to near-showroom accuracy. The Legend Cars roster rotates weekly, creating FOMO-driven urgency for rare vehicles.

**Progression.** After completing the 39 Menu Books (~20 hours), the game opens World Circuits — a hub of global race events tiered by PP (Performance Points, a car stat). Licence tests (timed sectors with gold/silver/bronze medals) gate certain events and teach driving technique. The post-campaign grind for the most expensive cars (some costing 20 million Credits) is where the economy controversy ignited.

**Online structure.** Sport Mode offers daily and weekly online races with a Sportsmanship Rating (SR) and Driver Rating (DR) system that functions as a clean skill ladder. GT7 also supports standard multiplayer lobbies. Critically, almost the entire single-player game requires a persistent internet connection — only Arcade mode is fully offline — a decision made to prevent save-file editing and cheating.

**Monetization.** Cars can be bought with real money via Credit packs (up to £15.99 for 2 million Credits). The most expensive cars cost 20 million Credits, implying up to £160 real-money equivalent. Update 1.07 (March 2022) cut payout rates on many popular farming events, effectively funnelling players toward microtransaction purchases. The user Metacritic score fell to 1.8 — Sony's lowest-rated first-party release of all time — triggering a Polyphony apology, 1 million free Credits awarded to all players, and a comprehensive doubling of payouts in subsequent patches.

## Implementation

Physics employ computational fluid dynamics to model downforce changes in real time. Rear-wheel-drive cars lose traction predictably; front-drivers respond to mid-corner throttle. The simulation is classified as "simcade" — accessible enough to play without a wheel, realistic enough to be used by professional racing simulators. The always-online enforcement is implemented server-side: save progression, Credit balances, and the rotating dealership state live on Sony's servers, making offline play of the full campaign technically impossible (and practically dangerous during the 30-hour server outage in March 2022).

## Why it matters

GT7 is the canonical live example of a developer deliberately suppressing in-game economy rewards to drive microtransaction purchases, getting caught, and being forced to reverse course publicly. The review-bomb response and the 1.8 Metacritic score demonstrate that players will weaponize review platforms against perceived economic manipulation at scale. The always-online single-player requirement also crystallised a growing anti-player-ownership sentiment: when GT7's servers went down for 30 hours, 100% of single-player content was inaccessible, illustrating the fragility of the model. The subsequent credit rebalance shows that hostile economy design is reversible but costly to reputation.

## Relevance to Wayfinder

1. → [[Economy]]: GT7's credit-payout manipulation and player backlash is the clearest cautionary tale against suppressing earned-currency rewards to push spending — Wayfinder's chart-reward and drop rates should feel generous relative to player time.
2. → [[Multiplayer Co-op]]: GT7's SR/DR Sportsmanship Rating system is a well-tuned approach to online behaviour incentivisation worth examining for Wayfinder's potential PvP or leaderboard layers.
3. → [[Camera and Game Feel]]: Scapes mode and the detailed interior renders illustrate how visual presentation of collectibles (cars / gear / charts in Wayfinder) deepens ownership satisfaction without requiring gameplay changes.

## See also

- [[Game Index]]
- [[Game Studies]]
- [[Economy]]
- [[MMO Economy and Itemization]]
- [[Camera and Game Feel]]
- [[Design Influences]]
- [[Forza Horizon 5]]
- [[FIFA series]]

## Sources

- Dexerto — GT7 devs backtrack on credits controversy: https://www.dexerto.com/gaming/gran-turismo-7-devs-quickly-backtrack-on-credits-controversy-1791210/
- Digital Trends — GT7 credit payout update: https://www.digitaltrends.com/gaming/gran-turismo-7-credit-payout-update/
- The Drive — GT7 apology and 1M credits: https://www.thedrive.com/news/44911/gran-turismo-7-is-sorry-will-give-1m-free-credits-and-make-serious-changes
- Game Rant — GT7 Menu Books guide: https://gamerant.com/gran-turismo-7-how-to-complete-every-menu-book-rewards/
- Game Rant — GT7 always-online explanation: https://gamerant.com/gran-turismo-7-online-connection-always/
- Tom's Guide — GT7 server outage and always-online folly: https://tomsguide.com/news/gran-turismo-7-maintenance
