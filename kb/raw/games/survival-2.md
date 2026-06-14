# Raw Sources — Survival Batch 2
*Ingested: 2026-06-14. Five games: The Forest, Grounded, Rust, No Man's Sky, Satisfactory.*

---

## The Forest (2018, Endnight Games)

**Sources fetched:**
- https://en.wikipedia.org/wiki/The_Forest_(video_game) — Wikipedia article covering release history (EA 2014 → 1.0 April 2018 PC, Nov 2018 PS4), developer (Endnight, small Vancouver studio), Unity engine, key mechanics (crafting via material combo, day/night, cannibal AI social behavior), co-op up to 8 players, deliberately scoped away from DayZ/Rust scale, Metacritic 83/100 PC, 78/100 PS4, 5.3M copies sold by late 2018.
- https://endnightgames.com/games/the-forest — official studio page confirming game description.
- https://gameinformer.com/games/the_forest/b/pc/archive/2018/05/14/a-gruesome-champion.aspx — Game Informer review highlighting cannibal AI moral ambiguity and narrative structure via VHS/cassette.
- https://theforest.fandom.com/wiki/The_Forest — wiki confirming crafting mechanics (drag-combine in inventory), building system (snap-grid logs + freeform traps).

**Key facts:**
- Engine: Unity. Team size ~10 at launch.
- 4 years Early Access before 1.0.
- Cannibal AI: state machines with social awareness; share player location, coordinate group pressure, communicate via effigies.
- Narrative: rescue story assembled from VHS tapes (environmental storytelling, optional true ending).
- Co-op: up to 8 players; design intent was intimate scale, not massive-multiplayer.
- Sons of the Forest (2023) is the sequel, same Unity codebase, larger team.

---

## Grounded (2022, Obsidian Entertainment)

**Sources fetched:**
- https://en.wikipedia.org/wiki/Grounded_(video_game) — full article: Early Access July 2020, 1.0 September 27 2022 PC/Xbox, console April 2024; Unreal Engine 4; Honey I Shrunk the Kids / A Bug's Life inspiration; 20M+ players; Metacritic 83/100 PC, 82/100 Xbox Series.
- https://grounded.obsidian.net/game — official page confirming co-op and crafting framing.
- https://www.denofgeek.com/games/grounded-obsidian-interview-pc-xbox/ — developer interview: dynamic insect ecosystem (aphid/ladybug dependency), accessibility-first philosophy.
- https://www.tomsguide.com/reviews/grounded — review noting hunger/thirst mechanics don't kill (just damage), approachable survivability.
- https://www.thegamer.com/grounded-arachnophobia-mode-guide/ — detailed breakdown of 5-level arachnophobia slider (legs → fangs → ball); uses LOD mesh swapping, preserves hitboxes.
- https://www.pcgamingwiki.com/wiki/Grounded — confirms Unreal Engine 4, Microsoft account requirement for Shared Worlds crossplay.

**Key facts:**
- Engine: Unreal Engine 4. Studio: Obsidian (RPG background), smaller team project.
- Insect AI: behavior trees with faction-aware priority; ladybug/aphid dependency is a live example of ecosystem chaining.
- Arachnophobia mode: 5 levels of mesh LOD replacement; landmark accessibility design.
- Co-op: 4 players, shared world persistence on host save, character inventories are per-player.
- Gear tier ladder: insect drops unlock crafting ingredients; no separate XP system.
- Grounded 2 entered Game Preview 2026.

---

## Rust (2018, Facepunch Studios)

**Sources fetched:**
- https://en.wikipedia.org/wiki/Rust_(video_game) — full article: EA December 2013, 1.0 February 8 2018; Unity engine; originally derived from Garry's Mod; blueprint/research-table system; monthly Force Wipes; up to 1,000 players per server; Metacritic 69/100 PC; 9M copies by 2019 / $142M revenue.
- https://facepunch.com/games/rust — official Facepunch page.
- https://www.mexc.co/news/985648 — procedural map generation article: noise-function maps with deterministic monument seeding; same seed = same monument layout.
- https://www.pcgamer.com/games/survival-crafting/rust-doubles-down-on-its-controversial-meta-changes-by-wiping-everyones-crafting-blueprints-to-bring-back-that-sense-of-discovery-and-it-might-become-a-regular-thing/ — 2025–26 PC Gamer article: Facepunch blueprint-wipe controversy; design intent to restore "sense of discovery."
- https://www.pcgamer.com/games/survival-crafting/rust-developer-is-fed-up-with-survivors-cowering-in-their-homes-so-its-reworking-progression-to-get-players-back-out-of-their-bases/ — workbench Tier 2/3 requiring Blueprint Fragments to push players out of base-camping.

**Key facts:**
- Engine: Unity. Custom server architecture for 1,000 concurrent players.
- Blueprint system: research table consumes items to unlock recipes; knowledge asymmetry between veteran and new players.
- Force Wipe: monthly cadence enforced by Facepunch; wipe day = peak concurrent player spike.
- Procedural gen: seeded noise + deterministic monument placement; same seed → same map each wipe.
- Building: socket-snap system (foundations/walls/roofs) with structural integrity checks; unsupported structures decay.
- Player-driven design ethos: "we give them the tools, they make the world" — no NPC economy, no narrative.

---

## No Man's Sky (2016, Hello Games)

**Sources fetched:**
- https://en.wikipedia.org/wiki/No_Man%27s_Sky — full article: launched August 9 2016; custom C++ engine; 64-bit deterministic procedural gen; 18 quintillion planets; missing-features controversy; major updates timeline (Foundation Nov 2016, NEXT July 2018 for multiplayer, Beyond Aug 2019 VR, Waypoint Oct 2022 Switch, Worlds Part I July 2024); Metacritic 71/100 PS4 at launch.
- https://www.club386.com/no-mans-sky-hello-games-redemption-story/ — Club386 redemption arc article: full silent-then-patch communication strategy analysis.
- https://www.nomanssky.com/release-log/ — official update log confirming 45+ named updates, all free.
- https://activeplayer.io/no-mans-sky/ — player stats: 1,562,847 daily players average as of June 2026; 19,953 Steam concurrent.
- https://www.slashskill.com/every-no-mans-sky-update-and-what-changed-a-returning-players-guide-2026/ — 2026 returning player guide covering refiner system, inventory tiers, economy-typed star systems surfaced in teleporters.

**Key facts:**
- Engine: custom C++ (required full rewrite for Voyager-era planetary terrain).
- Procedural gen: deterministic 64-bit seed; same planet seed = same landscape for all players.
- Co-op: single-player at launch → 16-player sessions (Atlas Rises 2017) → full multiplayer (NEXT 2018) → expanded group content (Beyond 2019).
- Crafting: 4 inventory tiers (exosuit, multi-tool, starship, freighter); blueprints from data modules; refiners as processing step.
- Economy: star systems typed (flourishing/balanced/struggling), affects trade-post prices; surfaced in teleporter menus.
- Live service: 45+ named updates, 5 medium content patches, hundreds of smaller patches — all free, no paid DLC.
- Players 2026: ~1.56M daily average.

---

## Satisfactory (2024, Coffee Stain Studios)

**Sources fetched:**
- https://en.wikipedia.org/wiki/Satisfactory — full article: EA March 2019, 1.0 September 10 2024 PC; originally UE4 → migrated to UE5 November 2023; hand-crafted ~30 km² map; PS5/Xbox Series X/S November 2025.
- https://coffeestain.com/game/satisfactory/ — official Coffee Stain page.
- https://satisfactory.wiki.gg/wiki/Satisfactory — wiki overview of core loop and automation systems.
- https://satisfactory.wiki.gg/wiki/Space_Elevator — detailed Space Elevator progression: 4 phases gate Tiers 3–9 in pairs; Phase 4 unlocks Tier 9 (Quantum Encoder, Converter, Portals).
- https://coffeestain.com/news/satisfactory-1-0-launch/ — 1.0 launch announcement.
- https://xgamingserver.com/blog/satisfactory-milestones-tech-tree/ — Milestone/Tier structure: Tiers 0–9, each phase unlocks two tiers.

**Key facts:**
- Engine: Unreal Engine 5 (migrated from UE4 pre-1.0).
- Map: hand-authored, ~30 km², non-procedural; biomes designed to distribute resources intentionally.
- Core loop: gather → process in machines → assemble components → deliver to Space Elevator → unlock next tier.
- Progression: 10 tiers (0–9), gated by 4 Space Elevator project phases.
- Simulation model: tick-based items-per-minute throughput; steady-state flow calculation is the player's primary planning task.
- Co-op: up to 4 players, shared persistent factory, dedicated server support (factory runs without host online).
- Five-year EA with continuous updates; used player feedback to tune pacing before 1.0.
