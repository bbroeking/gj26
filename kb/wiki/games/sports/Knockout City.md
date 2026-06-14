---
type: game
tags: [game-study, sports, live-service, multiplayer, sunset, postmortem, competitive, dodgeball, free-to-play]
status: draft
updated: 2026-06-14
sources:
  - "https://en.wikipedia.org/wiki/Knockout_City"
  - "https://www.gameshub.com/news/news/knockout-city-shut-down-june-2023-40085/"
  - "https://www.gameshub.com/news/news/knockout-city-velan-studios-closure-explained-2608651/"
  - "https://www.dexerto.com/gaming/yet-another-live-service-game-shut-down-as-eas-knockout-city-reaches-its-end-2051036/"
  - "https://gamerant.com/knockout-city-shutting-down/"
  - "https://www.pcgamer.com/knockout-city-sunset-gdc-talk/"
---

# Knockout City

Velan Studios' 2021 team dodgeball-brawler that launched with genuine mechanical inventiveness — including throwing teammates as weapons — but could not retain enough players to sustain its live-service costs, shutting down in June 2023 after 8 seasons.

## Design

**Core loop.** Teams of three compete to knock opponents out by hitting them with balls. Each player absorbs two hits before elimination; respawning is immediate. The loop rewards positioning and anticipation over precision: throws are charged for speed, incoming balls can be caught if the player times a defensive input precisely (catch window is narrow but learnable), and tackling forces a ball-carrier to fumble. The skill expression sits in prediction — reading whether an opponent is catching or dodging — rather than raw aim.

**Standout mechanic: throw a teammate.** Any player can curl into a ball and be picked up and hurled by a teammate, dealing a hit on contact. This interaction collapses the boundary between player and projectile, demanding team communication and enabling flashy combo plays. It is the single most-discussed design element and the clearest signal of the game's identity: no other mainstream competitive game has done this.

**Ball variety.** Specialised balls augment the core loop without replacing it: Moon Ball raises the holder's jump height; Bomb Ball detonates on a timer after impact; Sniper Ball fires at extremely high velocity. Each ball type shifts tempo and forces positioning adjustments — a lightweight loadout-like system without any persistent unlock gating.

**Online structure.** At launch: five maps, six modes including Team KO (deathmatch), Diamond Dash (loot the fallen), and Ball-Up Brawl (4v4 emphasising teammate-throwing). Eight seasonal updates added new maps, modes, crossover cosmetics (including Teenage Mutant Ninja Turtles), and gameplay twists. A League system provided ranked progression.

**Monetization and lifecycle.** Launched May 2021 under EA Originals at $20 with a trial period. June 2022: Velan took over publishing from EA and converted to free-to-play. Final season removed real-money purchases entirely, replaced with XP and cosmetic drops. Game peaked at 2 million players in its first week, reached 12 million players across its full two-year lifespan.

## Implementation

No publicly documented physics or netcode specifics beyond standard peer-assisted dedicated-server infrastructure for the EA Originals era. Throw trajectory and catch windows are likely client-predicted with server reconciliation; the narrow catch timing window suggests tight latency requirements. Before shutdown, Velan released a standalone Windows executable supporting self-hosted private servers — an act praised at GDC 2024 as a template for live-service sunsets (Velan director of marketing Josh Harrison: "Make a private hosted version of your game").

## Why it matters

Knockout City is the primary cautionary study for a live-service game with strong mechanics and weak retention. Velan cited "colliding economic factors" — rising infrastructure costs, the post-F2P inability to grow a sustainable paying population, and a small indie team unable to make the "systemic changes" needed to reacquire lapsed players. The private-server handoff at shutdown is now the community-care benchmark: Velan's GDC talk explicitly recommended all studios prepare a hostable build before sunset. The game also demonstrates that a distinctive mechanical hook (teammate-as-ball) is necessary but not sufficient for a live-service game; the content loop and social graph must support retention independently of novelty.

## Relevance to Wayfinder

1. → [[Multiplayer Co-op]]: The teammate-throwing mechanic is the most literal "player as resource" design yet seen in a team game; Wayfinder's co-op ability design (using a teammate's Trade buff as part of your own combo) has structural parallels worth examining.
2. → [[Economy]]: Knockout City's mid-life F2P pivot (paid → free → no monetisation) is a compressed live-service cautionary tale — the transition helped player counts but not revenue, and the studio couldn't sustain costs. Wayfinder's economy should be designed from day one to support long-term free engagement.
3. → [[Multiplayer Co-op]]: The private-server sunset is the current best-practice recommendation for any live multiplayer game; Wayfinder's chart-sharing system should be designed so charts remain locally replayable even if servers go down.

## See also

- [[Game Index]]
- [[Game Studies]]
- [[Multiplayer Co-op]]
- [[Economy]]
- [[Design Influences]]
- [[Rocket League]]
- [[FIFA series]]

## Sources

- Wikipedia — Knockout City: https://en.wikipedia.org/wiki/Knockout_City
- GamesHub — Knockout City shutdown announced: https://www.gameshub.com/news/news/knockout-city-shut-down-june-2023-40085/
- GamesHub — Closure explained (inflation/retention): https://www.gameshub.com/news/news/knockout-city-velan-studios-closure-explained-2608651/
- Dexerto — Yet another live-service shutdown: https://www.dexerto.com/gaming/yet-another-live-service-game-shut-down-as-eas-knockout-city-reaches-its-end-2051036/
- Game Rant — Knockout City shutting down: https://gamerant.com/knockout-city-shutting-down/
- PC Gamer — GDC sunset talk (private server recommendation): https://www.pcgamer.com/knockout-city-sunset-gdc-talk/
