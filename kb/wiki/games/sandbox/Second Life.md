---
type: game
tags: [game-study, sandbox, virtual-world, creator-economy, virtual-currency, ugc, ip-rights, social]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Second_Life
  - https://gamesbeat.com/linden-lab-has-spent-1-3b-building-second-life-and-paid-1-1b-to-creators/
  - https://modemworld.me/2024/12/20/second-life-1-3b-to-build-1-1b-paid-to-creators/
  - https://shapes.inc/fandom/second-life/economy
  - https://www.ebsco.com/research-starters/social-sciences-and-humanities/second-life
---
# Second Life

A persistent 3D virtual world (2003, Linden Lab) that pioneered creator intellectual-property rights and an open real-money virtual economy — the foundational model every subsequent UGC economy references, deliberately or not.

## Design

Second Life's defining design decision was made before launch: users own full copyright over everything they create. Linden Lab's Philip Rosedale and team chose to extend IP rights to Residents, and to attach real monetary value to virtual land and goods. This was radical in 2003, when most online games reserved all IP to the publisher.

The economic loop follows from that decision: Residents buy **Linden Dollars (L$)** with real money, spend L$ on land, clothing, furniture, animations, and scripts created by other Residents, and may exchange surplus L$ back into USD. The result is the first-ever player-driven virtual GDP — estimated at $500 million annually by 2015, with over $3.2 billion in cumulative transactions by 2013.

Social design is emergent and open-ended: there are no quests, no leveling, no objectives. The world runs as a series of "regions" (sims), each a 256×256-meter plot on a dedicated server core. Residents rent land, build structures, script behaviors with the proprietary Linden Scripting Language (LSL), and gather in communities that range from roleplay sims to virtual art galleries to commercial malls.

The standout mechanic is **creator-to-creator economics**: top creators earn over $100,000 USD per year from other players; 14 creators have become millionaires. The platform takes only a 10% cut (90% revenue share to creators) — the most creator-favorable split in the industry.

## Implementation

- **Engine / Platform:** Proprietary server software on Debian Linux; Havok physics engine. Each region runs on a single dedicated server core. The viewer client is open-source (LGPL); dozens of third-party viewers exist.
- **Virtual economy:** Linden Dollar is exchangeable but officially "has no monetary value" outside the platform. Real USD flows in through LindeX (currency exchange) and out through PayPal. This open convertibility distinguishes Second Life from Roblox's more tightly controlled Robux.
- **Scale:** Approximately 600,000 active users as of 2024; peak concurrent users reached 88,200 in early 2009. Users average ~14 years on the platform — an extraordinary retention figure.
- **Creator payouts:** $1.1 billion paid to creators since 2003; Linden Lab spent $1.3 billion building the platform. In 2023, 21,152 creators generated income; 139 earned over $100,000.
- **Scripting:** Linden Scripting Language (LSL) — event-driven, C-like. More constrained than Lua (no arbitrary file I/O) but sufficient for game logic, vehicle physics, and HUD systems.

## Why it matters

Second Life established three principles every subsequent UGC platform had to reckon with: (1) **creator IP ownership changes the incentive structure** — people build more ambitiously when they own what they make; (2) **real-money convertibility creates a real economy**, not just a points system; (3) **a 10% platform cut is viable** if the platform provides enough infrastructure value. Roblox launched with a far smaller creator cut (~25%) and grew faster by controlling the economy more tightly — the contrast is instructive.

## Relevance to Wayfinder

1. **[[Economy]]** — The L$ open-exchange model is the reference case for a player-tradeable virtual currency; its GDP-scale outcome shows what happens when you combine creator ownership with real convertibility. Wayfinder's economy design should decide explicitly whether it wants a "closed Robux" or an "open L$" model.
2. **[[Multiplayer Co-op]]** — Second Life's lack of formal game structures shows the outer limit of emergent social design: community forms around shared identity and economics, not game objectives. Useful for understanding what Wayfinder's co-op needs to provide that a pure sandbox doesn't.
3. **[[MMO Social and Endgame]]** — The 14-year average retention and creator-economy endgame (building your own shop, running your own sim) is a model for post-chart endgame aspirations.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Economy]] · [[Multiplayer Co-op]] · [[MMO Social and Endgame]]
- [[Roblox]] (UGC-platform archetype that followed) · [[Habbo Hotel]] (contemporary social-world) · [[VRChat]] (spatial social successor)
- [[EVE Online]] (parallel player-driven economy in a game context)

## Sources

- https://en.wikipedia.org/wiki/Second_Life
- https://gamesbeat.com/linden-lab-has-spent-1-3b-building-second-life-and-paid-1-1b-to-creators/
- https://modemworld.me/2024/12/20/second-life-1-3b-to-build-1-1b-paid-to-creators/
- https://shapes.inc/fandom/second-life/economy
- https://www.ebsco.com/research-starters/social-sciences-and-humanities/second-life
