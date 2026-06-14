---
type: game
tags: [game-study, sandbox, ugc, platform, creator-economy, lua, virtual-currency]
status: draft
updated: 2026-06-14
sources:
  - https://naavik.co/deep-dives/the-state-of-ugc-games-2025-deep-dive/
  - https://about.roblox.com/newsroom/2025/12/how-roblox-impacts-the-global-economy
  - https://rowatcher.com/news/inside-roblox-s-ugc-economy-who-s-winning-in-2026
  - https://en.wikipedia.org/wiki/Roblox
---
# Roblox

A browser-and-app UGC platform (2006, Roblox Corporation) where millions of player-built experiences are published and monetized inside a closed Robux economy — the dominant archetype for creator-platform game design.

## Design

Roblox is less a single game than an operating system for games: the host platform provides physics simulation, character rigs, a social graph, and a currency (Robux), while every "experience" is a distinct game built atop that substrate by a creator. The standout mechanic is the **flywheel**: players enter for free, spend Robux on game passes and cosmetics, creators cash out via the Developer Exchange (DevEx) program, and earnings fund better games that attract more players.

The UGC accessory marketplace (opened to ID-verified Premium subscribers in April 2024) extended this further: any creator can publish hats, clothing, and accessories for a 70% revenue share, with Roblox retaining 30%. The minimum price barrier (750 Robux to upload; 1,500 Robux to enable sales) gatekeeps quality without closing the door to newcomers.

Social design is deliberately lightweight — friends lists, party systems, and in-experience chat — so that the games themselves supply depth. The platform's age demographic has historically skewed young (under-13), which constrains chat moderation and pushes discovery toward algorithmic curation rather than word-of-mouth. An AI coding assistant ("Assistant") launched in 2024 to lower the Lua scripting barrier for new creators.

## Implementation

- **Engine:** Proprietary Roblox Engine; experiences scripted in Lua (now Luau, a typed superset).
- **Scale (2024):** 82.93 million daily active users; 73.5 billion hours engaged; $4.4 billion in bookings.
- **Creator economy:** $922 million paid out to developers in 2024 (≈25% of bookings); over 29,000 creators enrolled in DevEx as of mid-2025. Median DevEx creator earned $1,440 USD over 12 months.
- **AI tooling:** "Assistant" offers code completion, texture generation, and automated avatar creation; adopted most heavily by newer creators.
- **Virtual economy:** Robux purchased with real money; converted back at a fixed DevEx rate. Roblox controls the exchange rate, making it a closed economy — unlike Second Life's open L$↔USD exchange.
- **Marketplace:** 44 million experiences published as of Q2 2025; creators retain 70% on marketplace items, but the platform takes ~75% of overall bookings across the economy.

## Why it matters

Roblox proved that a platform can outcompete any single game by converting players into creators: the supply of content scales with the user base rather than requiring studio investment. Its Lua-scripted game-mode system anticipated the shift toward UGC that now shapes Fortnite, Core, and others. The Robux flywheel — virtual currency bought in bulk, spent in tiny increments — is the canonical model for reducing friction in micropayment economies.

## Relevance to Wayfinder

1. **[[Economy]]** — Robux's closed-loop virtual currency is the most-studied UGC economy; its creator payout mechanics (DevEx rate, marketplace cut) are a direct reference point for any Wayfinder player-market or chart-resale feature.
2. **[[Multiplayer Co-op]]** — Roblox experiences demonstrate how lightweight social scaffolding (friends + parties) lets the actual game content supply the social bond; Wayfinder's co-op delves can lean on the same principle.
3. **[[MMO Social and Endgame]]** — The creator flywheel shows how endgame engagement can be redirected from consumption to production — relevant if Wayfinder ever adds chart-sharing or community tools.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Economy]] · [[Multiplayer Co-op]] · [[MMO Social and Endgame]]
- [[Second Life]] (pioneer of creator IP rights) · [[Garry's Mod]] (PC sandbox archetype) · [[VRChat]] (social UGC)
- [[EVE Online]] (virtual economy depth)

## Sources

- https://naavik.co/deep-dives/the-state-of-ugc-games-2025-deep-dive/
- https://about.roblox.com/newsroom/2025/12/how-roblox-impacts-the-global-economy
- https://rowatcher.com/news/inside-roblox-s-ugc-economy-who-s-winning-in-2026
- https://en.wikipedia.org/wiki/Roblox
