---
type: game
tags: [game-study, survival, story-driven, no-combat, crafting, depth-progression, solo]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Subnautica
  - https://subnautica.fandom.com/wiki/Depth_Levels
  - https://crosspadgaming.com/reviews/subnautica-2-no-killing-ethos
---
# Subnautica

A story-driven underwater survival game (full release January 2018, Unknown Worlds Entertainment) in which a sole crash survivor on an alien ocean planet explores progressively deeper and more dangerous biome zones, crafting vehicles and equipment to unlock depth rather than defeating enemies — a deliberate no-weapons design that became the franchise's core identity.

## Design

- **Depth as progression gate.** Subnautica's world is not horizontal: it descends. Depth zones function like the genre's biomes but are literal meters of water pressure. Safe Shallows (0–80 m) is the tutorial zone; Grassy Plateaus (40–200 m) introduces early resources; Blood Kelp Zone (100–675 m) demands better equipment; the Lost River (500–1,000+ m) requires a depth-upgraded vehicle to enter; the Inactive Lava Zone is the game's deepest tier. Each depth ceiling is enforced by vehicle crush depth — penetrating a new zone requires fabricating the next depth module upgrade, which requires resources only available in the previous tier. Depth gates are materially enforced, self-explanatory, and viscerally felt (the crushing darkness and ambient audio shift dramatically with depth).
- **Scan-to-blueprint crafting loop.** Players carry a Scanner tool; scanning debris, creatures, or flora adds PDA entries and, critically, unlocks fabricator blueprints. Scanning enough fragments of a vehicle or tool (e.g., 3 Seamoth fragments) unlocks its full recipe. This means exploration directly gates crafting — the world is the recipe book, and you must physically visit the location where a resource or wreck exists to unlock its tech. There is no crafting tree visible upfront; the loop rewards curiosity.
- **No-weapons design.** Unknown Worlds made a principled choice to build without lethal weapons, citing post-Sandy Hook motivation. Players cannot kill large predators; they can repel them with the Stasis Rifle (freezes), Propulsion Cannon (moves), or simply flee. This constraint reframes the ocean as an environment to coexist with rather than conquer, producing an atmosphere of awe rather than aggression — one of the most distinctive tonal choices in the survival genre.
- **Narrative structure with a beginning, middle, and end.** Unlike most survival games, Subnautica has a scripted story (Ryley Robinson, the dying Sea Emperor Leviathan, the quarantine enforcement platform) that unfolds through PDA audio logs and environmental discovery. Progression in the story is gated by the same depth/crafting ladder as survival progression — you cannot reach the final story beats without the gear to go deep. Story and systems are unified rather than parallel tracks.
- **No explicit quests; intrinsic motivation.** The game offers no quest markers. Players are pointed toward the story only by PDA logs and the survival incentive to find food/water/power. Design lead Charlie Cleveland described this as intentional: "no missions or quests that force extrinsic motivation." The design trusts the environment to generate curiosity.
- **Solo only.** No multiplayer mode. The atmosphere of isolation — being alone on an alien ocean — is a deliberate narrative and tonal choice, not a resource constraint. Community-made multiplayer mods exist but are unofficial.

## Implementation

- **Engine:** Unity.
- **World design:** Handcrafted fixed map (not procedurally generated); each biome zone is artistically designed to communicate its depth and danger through lighting, creature design, and ambient audio. The non-procedural approach allowed precise control of story pacing and resource placement — players always encounter the Aurora wreck in the same relative location.
- **Crafting system:** Fabricator (main station), Vehicle Bay, and Modification Station cover all recipes. Blueprint unlocks via scanning are stored per save-file; crafting is resource-gated, not station-gated beyond the three main stations.
- **PDA audio log system:** Hundreds of text/audio PDA entries provide lore, recipes, survivor logs, and creature data — a lightweight narrative delivery system that requires no cutscenes and remains optional.
- **Sales:** Sold over 5 million copies by 2019; highly praised for atmosphere, with a Metacritic score of 87. Spawned sequel Below Zero (2021) and Subnautica 2 (in development as of 2026, also no-weapons).

## Why it matters

Subnautica is the clearest proof that **constraint-as-design** works at commercial scale: removing weapons forced the team to invent a richer set of survival tools and a more interesting relationship between player and environment. The **scan-to-blueprint** loop is among the most elegant crafting-unlock designs in the genre because it ties progression directly to curiosity and exploration rather than time-gating or random drops. The game also demonstrates that a survival game can have a **satisfying narrative endpoint** — a rarity in the genre — which makes each run feel purposeful rather than endless.

## Relevance to Wayfinder

- The **scan/discover → unlock** pattern is a compelling model for [[Crafting]] in Wayfinder: instead of all chart affixes being available from the start, discovering them through dungeon exploration (finding affix rune fragments, interacting with shrine rooms) would make [[Dungeon Generation]] feel like the recipe book — exploration has direct crafting payoff.
- **Depth-gated biomes enforced by gear** (not arbitrary walls) are the ideal template for Wayfinder's den depth system: each chart-depth tier should require a consumable or gear slot the player physically cannot have without completing the previous tier, making the [[Items and Gear]] ladder feel materially necessary.
- The **no-explicit-quest / intrinsic motivation** design is relevant to Wayfinder's cozy tone: chart affixes could hint at destinations or encounters rather than marking quest waypoints, letting discovery feel like wonder rather than checklist completion.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[Balance Philosophy]]
- [[Crafting]] · [[Gathering]] · [[Items and Gear]] · [[Dungeon Generation]] · [[Economy]]
- [[Minecraft]] · [[Terraria]] · [[Valheim]] · [[Don't Starve]]

## Sources

- https://en.wikipedia.org/wiki/Subnautica
- https://subnautica.fandom.com/wiki/Depth_Levels
- https://crosspadgaming.com/reviews/subnautica-2-no-killing-ethos
- https://www.gamepur.com/guides/all-subnautica-biomes-locations-depths-and-harvesting-nodes
- raw/games/survival-1.md
