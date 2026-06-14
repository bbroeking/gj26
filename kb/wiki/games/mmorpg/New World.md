---
type: game
tags: [game-study, mmorpg, crafting, economy, territory-war, azoth, amazon, action-combat, cautionary-tale]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/New_World_(video_game)
  - https://gamerant.com/new-world-how-to-get-find-farm-use-azoth-guide/
  - https://gamerant.com/new-world-azoth-cap-travel-costs/
  - https://www.mmorpg.com/news/new-world-team-talks-q2-economy-inflation-whats-working-and-changes-to-come-2000131269
  - https://kotaku.com/new-world-players-face-massive-queues-wait-times-on-ov-1847763621
---
# New World

Action MMORPG released September 2021 by Amazon Games, set on the supernatural island of Aeternum, built around skill-based combat (no tab-targeting), a crafting-centric player economy with territory war, and the Azoth resource as a multi-purpose sink — a game that peaked at 913,000 concurrent Steam players and collapsed to under 4% of that within months; servers shut down January 2027.

## Design

- **Azoth as multi-purpose currency:** Azoth is a supernatural resource with three core uses: (1) fast travel — base 50 Azoth per trip, scaling with distance, encumbrance, and whether the destination is enemy-faction controlled; (2) crafting — imbued into weapon/armour recipes to increase chance of bonus affixes and gem slots; (3) weapon mastery respec. The Azoth cap was widely criticised as too low relative to its multi-role demand. Players sometimes preferred dying (free instant respawn) over paying fast-travel costs — a notorious sign of a friction tax that exceeded its entertainment value.
- **Three-faction territory system:** Players join Marauders (military), Syndicate (espionage), or Covenant (religious). Companies (guilds) within factions capture settlements through Declaration of War and 50v50 siege battles. Controlling companies set local tax rates, crafting fees, and settlement upgrades (economy vs. war focus). In theory: rich emergent politics. In practice: faction imbalance (everyone piling into the dominant faction) was endemic, and the absence of checks let single companies monopolise regions.
- **Crafting economy:** Trade skills span Gathering (logging, mining, harvesting), Refining (smelting, woodworking, tanning), and Crafting (weaponsmithing, armoring, engineering, jewel crafting, arcana, cooking, furnishing). Intended to be the primary gear acquisition path, but inflation plagued the Trading Post throughout the game's life — oversupply of lower-tier materials, price crashes, and periodic economic exploits.
- **No auto-targeting:** Combat is skill-based, requiring manual aim with dodges, blocks, and timed attacks. This distinguished it from tab-targeting MMOs but raised the skill floor and reduced the accessible audience.
- **Settlement economy layer:** Upgrade paths for settlements (crafting stations, housing, storage) created a player-driven urban development loop — one of the most innovative governance designs in the genre.

## Implementation

- **Engine:** Amazon Lumberyard (CryEngine fork, later open-sourced as O3DE). An Amazon-internal engine used to showcase AWS integration — the choice drove longer iteration cycles than Unity/Unreal would have allowed.
- **Launch queue crisis:** 700,000+ concurrent players day one (5th most-played Steam game ever); queue times reached 212 hours on some servers. Amazon rapidly deployed additional servers and enabled free cross-region character transfers.
- **RTX 3090 bricking:** During beta, uncapped frame rates in menu screens exceeded 9,000 fps and destroyed GPU power delivery hardware on Nvidia RTX 3090 cards — a famous technical incident requiring an emergency patch.
- **Player retention collapse:** Peak concurrency of 913,000 players dropped to under 4% within months. Root causes: endgame content drought, crafting economy inflation without adequate sinks, faction imbalance in territory wars, and a series of economy-breaking exploits.
- **Console relaunch:** October 2024 rebranded as "New World: Aeternum" with PS5/Xbox Series X|S support — insufficient to reverse the decline. Shutdown announced for January 31, 2027.

## Why it matters

New World is the genre's most instructive cautionary tale of the 2020s: a **well-funded, high-concept MMORPG that got the launch right and the retention wrong**. Its core lessons:

1. **Economy sinks must be designed before launch.** Azoth's multi-use demand was sound but the cap was wrong; the Trading Post needed more powerful deflationary mechanisms before players could flood it.
2. **Territory war requires faction balance mechanics.** Open faction choice with no incentives to join losing sides produces a feedback loop that collapses the PvP ecosystem.
3. **Friction taxes destroy convenience loops.** Azoth fast-travel cost so much that it punished engagement rather than rewarding it — the opposite of a good resource sink.

## Relevance to Wayfinder

- **Azoth as a friction lesson for [[Chart Loop]]:** Wayfinder's Azoth analogue is the Chart itself (parameterized dungeon key). Charts should never become a resource so scarce that players avoid content — the loop must ensure players always have a chart to run (see [[Chart Loop]], [[Economy]]).
- **Crafting-centric design validation:** New World proves there is a market for crafting-first MMOs. Its failure was economic balancing, not the premise. Wayfinder's gather → craft → chart → delve spine is vindicated, not refuted — but the [[Economy]] needs sinks from day one.
- **Territory war → co-op social layer:** The settlement governance idea (players controlling upgrade paths for shared spaces) is unexploited design space that Wayfinder's eventual multiplayer hub could reference for [[Multiplayer Co-op]] social depth.

## See also

- [[Game Index]] · [[Game Studies]]
- [[MMO Economy and Itemization]] · [[MMO Server Architecture]] · [[MMO Lessons for Wayfinder]]
- [[Black Desert Online]] · [[Albion Online]] · [[World of Warcraft]]
- [[Chart Loop]] · [[Economy]] · [[Crafting]] · [[Gathering]] · [[Multiplayer Co-op]]

## Sources

- https://en.wikipedia.org/wiki/New_World_(video_game)
- https://gamerant.com/new-world-how-to-get-find-farm-use-azoth-guide/
- https://gamerant.com/new-world-azoth-cap-travel-costs/
- https://www.mmorpg.com/news/new-world-team-talks-q2-economy-inflation-whats-working-and-changes-to-come-2000131269
- https://kotaku.com/new-world-players-face-massive-queues-wait-times-on-ov-1847763621
