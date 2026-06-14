---
type: game
tags: [game-study, moba, mobile, super-evil-megacorp, evil-engine, cross-platform, touchscreen, shutdown, community-edition]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Vainglory_(video_game)
  - https://www.gamedeveloper.com/production/why-super-evil-megacorp-built-a-proprietary-mobile-moba-engine
  - https://cloud.google.com/customers/superevilmegacorp
  - https://www.vainglorygame.com/news/vainglory-community-edition/
  - https://www.pocketgamer.biz/news/73049/super-evil-megacorp-rescues-vainglory/
---
# Vainglory

A cross-platform MOBA by Super Evil Megacorp — first released on iOS November 2014 — that pioneered competitive mobile gaming with a bespoke server-authoritative engine designed specifically for touchscreen latency requirements, reaching 45 million players before a 2020 publisher crisis forced a community-managed transition.

## Design

Vainglory launched as a 3v3 MOBA on a single lane with a jungle flanking each side (the Halcyon Fold map). This intentional scope reduction from the standard three-lane format was deliberate: a single contested lane and two jungle approaches gave mobile players a legible strategic space without demanding the map-reading skills that desktop MOBA veterans develop over years. A 5v5 mode with a full three-lane map (Summer of Pain) shipped in Update 3.0 (2018).

The hero roster grew from 7 at launch to 56 by Update 4.11. Heroes carry two in-game currencies: Glory (earned through play) and ICE (real-money). A Talents system in BRAWL modes added 168 collectible upgrades that augment hero abilities. The game supported emoticons, pings, and voice chat — uncommon thoroughness for a 2014 mobile title.

Control options evolved across the game's life: the original precision touch/drag targeting was joined by a joystick mode (Update 3.4) to ease onboarding, at a cost to the precision-control identity that reviewers cited as Vainglory's differentiator (TouchArcade: "probably the best MOBA on iOS").

## Implementation

**Engine:** E.V.I.L. (proprietary, Extensible Visual Interface Layer) — over 10 man-years of internal build, chosen because no existing engine solved networked multiplayer on touch devices to the studio's standard. Cofounder Tommy Krul: "For Vainglory we need technology that delivers a smooth experience for networked, multiplayer gaming, and apart from E.V.I.L., there really aren't any existing engine solutions for running networked games on touch devices."

**Netcode architecture:** Fully server-authoritative. "The entire gameplay runs on the server and not on the client." This eliminated the cheat surface and synchronisation drift common in peer-to-peer or client-authoritative mobile games, but made the server cost structure load-bearing for the business.

**Infrastructure:** Google Cloud (GKE for Kubernetes orchestration, Compute Engine, BigQuery for analytics). Multi-region deployment with auto-scaling via GKE eliminated the manual 5-engineer on-call fleet management the studio had previously relied on. GCP reduced per-user server cost to one-fifth of their legacy provider.

**2020 community edition pivot:** When publisher Rogue Games announced server shutdown (March 2020), Super Evil Megacorp reversed course by converting the game to client-authoritative architecture. Friends lists, chat, leaderboards, quests, and currency systems were stripped out; matchmaking information moved from server to device. The transition was announced April 1, 2020. The original server-authoritative model — central to the game's competitive integrity — could not survive without the publisher's operating budget.

## Why it matters

- **Mobile-first netcode as a design constraint:** Building server-authoritative gameplay for touchscreen devices in 2014 was genuinely hard; E.V.I.L. is evidence that the right answer was to own the stack. Studios targeting mobile co-op or competitive play face the same calculus today.
- **Publisher dependency risk:** The 2020 crisis — Rogue Games withdrawing server funding and announcing shutdown with weeks of notice — is the cleanest example in this wiki of how a game's netcode architecture can become a financial hostage. Server-authoritative design is the right choice for integrity, but it creates ongoing OPEX that any publisher transition must cover.
- **Client-authoritative degradation:** The Community Edition transition illustrates what is lost when server authority moves to the client: the social graph, progression integrity, and competitive fairness all erode together. The app experience "will get worse before it gets better" was an accurate forecast.
- **Cross-platform before crossplay was normal:** Vainglory shipped iOS/Android/PC cross-platform play in 2019, years before the industry normalised it. The E.V.I.L. engine's platform-agnostic design made this tractable; studios on third-party engines had to wait for Unity/Unreal crossplay support to mature.

## Relevance to Wayfinder

- [[MMO Netcode and Tick Systems]]: Vainglory's server-authoritative mobile architecture and its collapse under publishing cost pressure is the canonical cautionary tale for Wayfinder's multiplayer backend planning — operating cost must be modelled at design time, not at launch.
- [[Multiplayer Co-op]]: The 3v3 single-lane scope reduction for a new audience is directly applicable to Wayfinder's dungeon design: a legible co-op space (2–3 players, one dungeon thread) may be more effective than full party complexity at launch.
- [[Combat]]: The joystick-mode addition shows the tension between precision-control identity and onboarding accessibility — Wayfinder's one-verb combat design should pick a lane early.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]] · [[Multiplayer Co-op]]
- [[MMO Netcode and Tick Systems]] · [[Combat]]
- Siblings: [[Dota 2]] · [[League of Legends]] · [[Smite]] · [[Apex Legends]]

## Sources

- https://en.wikipedia.org/wiki/Vainglory_(video_game)
- https://www.gamedeveloper.com/production/why-super-evil-megacorp-built-a-proprietary-mobile-moba-engine
- https://cloud.google.com/customers/superevilmegacorp
- https://www.vainglorygame.com/news/vainglory-community-edition/
- https://www.pocketgamer.biz/news/73049/super-evil-megacorp-rescues-vainglory/
