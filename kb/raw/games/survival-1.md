# Raw Provenance — Survival Batch 1
<!-- Ingest date: 2026-06-14 | Agent: game-research analyst -->
<!-- Source pages fetched for five survival/sandbox case studies -->

## Minecraft

- https://en.wikipedia.org/wiki/Minecraft — release year (Nov 2011), developer (Mojang Studios), engine (LWJGL for Java; C++ for Bedrock), procedural world gen (Perlin noise + Fractal Brownian Motion, chunk-based, seed-deterministic), crafting tiers, three dimensions (Overworld/Nether/End), sales (350M+ copies), multiplayer (LAN, Realms, cross-platform Bedrock).
- https://www.alanzucconi.com/2022/06/05/minecraft-world-generation/ — technical deep dive: stacked layer system (Island → Zoom → Climate → Edge-blending), 1.18+ 3D climate mapping with 5 noise parameters (temperature, humidity, continentalness, erosion, weirdness), Perlin worms for caves, chunk phases (terrain outline → surface definition → feature carving).
- https://gamedesignskills.com/game-design/minecraft/ — design principles: emergent systems, player agency, sandbox freedom, the "no set goal" design philosophy (403 blocked, summary from search).

## Terraria

- https://en.wikipedia.org/wiki/Terraria — release May 16 2011, Re-Logic (11 members), XNA framework, 70M+ copies sold, procedurally generated worlds (small/medium/large), tModLoader as official free DLC (2020), local/online co-op, Wall of Flesh as hardmode gate.
- https://terraria.wiki.gg/wiki/Hardmode — hardmode transition: Wall of Flesh defeat → Pwnhammer → smash Demon/Crimson Altars → spawn Cobalt/Palladium / Mythril/Orichalcum / Adamantite/Titanium ores; each tier requires upgraded crafting stations (Mythril Anvil, Titanium Forge).
- https://www.switchbladegaming.com/terraria/progression-guide-2026/ — pre-hardmode loop: surface → underground → underworld; Molten Armor as pre-hardmode peak; crafting stations gate gear tiers throughout.

## Valheim

- https://en.wikipedia.org/wiki/Valheim — release Feb 2 2021 early access (full release Sep 9 2026), Iron Gate Studio (Swedish, 5 devs), Unity engine, 9 biomes (Meadows → Black Forest → Swamp → Mountains → Plains → Ocean → Mistlands → Deep North → Ashlands), 8 bosses gate biome progression, 10-player co-op, procedural worlds from seed.
- https://edgegap.com/blog/valheim-multiplayer-game-backend-deep-dive — ZDO (Zone Data Object) sync system; dual backend (Steam P2P for PC, PlayFab/Azure relay for crossplay); dedicated server binary free on Steam; 10-player cap due to ZDO bandwidth cost; crossplay and mods mutually exclusive.
- https://forgeandmead.com/progression/food-system — food as "real difficulty slider": three-food active stack (health/stamina/eitr); food is a progression gate unlocked via cauldron upgrades; biome-matched food preparation required before boss attempts.
- https://techraptor.net/gaming/guides/valheim-hearth-and-home-update-guide-new-items-cooking-changes-and-more — Hearth & Home update (Sep 16 2021): separated health/stamina foods; comfort system grants Rested buff (bonus health/stamina regen proportional to comfort level in home).

## Don't Starve

- https://en.wikipedia.org/wiki/Don%27t_Starve — release Apr 23 2013, Klei Entertainment (Canadian), three survival meters (hunger 75pts/day depletion / sanity / health), permadeath with rare revival items (Meat Effigy, Touch-Stone, Life-Giving Amulet), 8-min day/night cycle, 9 biomes, character unlock via XP (Wilson free; others up to 1,600 pts).
- https://en.wikipedia.org/wiki/Don%27t_Starve_Together — multiplayer announced May 7 2014, Early Access Dec 2014, standalone release Apr 21 2016; up to 6 players; unique characters (Winona, Warly, Wormwood) exclusive to Together.
- https://annamalecki.medium.com/game-design-analysis-dont-starve-50d06561097d — design analysis: trial-and-error learning loop; meta-goal of "reach day X"; sandbox landmarks (pig farms, Beefalo herds) reward exploration; audio design amplifies isolation.
- https://errorandexp.substack.com/p/the-game-design-behind-dont-starves — hunger mechanic as central puzzle: forage → cook → preserve loop; recipe efficiency (meatballs outperform raw); randomized world prevents memorization.

## Subnautica

- https://en.wikipedia.org/wiki/Subnautica — full release Jan 23 2018 (PC), Dec 4 2018 (consoles), Unknown Worlds Entertainment, Unity engine, single-player only, story about curing planet-wide bacterium and escaping; motivated by Sandy Hook (non-violent design); no traditional quest system; intrinsic motivation design.
- https://subnautica.fandom.com/wiki/Depth_Levels — depth zones: Safe Shallows (0-80m) → Grassy Plateaus (40-200m) → Kelp Forest / Mushroom Forest (mid) → Blood Kelp Zone (100-675m) → Lost River (500-1000m+) → Inactive Lava Zone (deepest); each zone requires upgraded vehicle with depth modules.
- https://www.gamepur.com/guides/all-subnautica-biomes-locations-depths-and-harvesting-nodes — biome resource specificity: each depth zone has unique harvestable materials gating fabricator recipes.
- https://crosspadgaming.com/reviews/subnautica-2-no-killing-ethos — no-killing design as "core tenet of the franchise"; design lead Anthony Gallegos confirmed to Rock Paper Shotgun; scan-to-craft blueprint unlock loop.
