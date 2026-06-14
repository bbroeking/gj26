# Raw Provenance — Colony Sim Batch 1
<!-- Ingest date: 2026-06-14 | Agent: game-research analyst -->
<!-- Source pages fetched for five colony-sim case studies -->

## RimWorld

- https://en.wikipedia.org/wiki/RimWorld — release 2018, Ludeon Studios / Tynan Sylvester; Unity engine; three AI storytellers (Cassandra / Phoebe / Randy); pawn traits + needs + mood system; production chains; modding ecosystem; $100M+ revenue by 2020; console port 2022.
- https://zaydqazi.substack.com/p/the-story-generator-a-game-design — deep design analysis: AI storyteller as event-director not script; pawn trait interaction examples (pyromanic surgeon); cascade mechanic (one injury → food shortage → morale crisis → colony collapse); tile-based UI readability; modding longevity.
- https://www.gamedeveloper.com/design/dwarf-fortress-and-rimworld-tell-very-different-stories — contrast with Dwarf Fortress: RimWorld uses scripted event pools filtered by colony wealth/threat score; DF uses emergent world simulation; RimWorld's smaller colony size reduces attachment vs. DF's hundreds of dwarves.
- https://rimworldgame.com/ — official site; genre self-description; storyteller system marketing copy.

## Dwarf Fortress

- https://en.wikipedia.org/wiki/Dwarf_Fortress — release 2006 alpha / 2022 Steam paid edition; Bay 12 Games (Tarn & Zach Adams); C/C++ + Microsoft Visual Studio; ASCII Code Page 437 rendering; three modes (Fortress, Adventure, Legends); dwarf needs (food/drink/sleep/mood); Strange Mood artifacts; yearly trade caravans; procedural world generation (offline historical simulation); 1M+ copies sold April 2025.
- https://www.gamedeveloper.com/design/dwarf-fortress-and-rimworld-tell-very-different-stories — DF emergent narrative vs. RimWorld's scripted events; "unfettered play" philosophy; hundreds of dwarves enable genuine personalisation; memorialisation (engravings depict real events); "losing is fun" community ethos.
- https://www.researchgate.net/publication/356686095_Characterization_and_Emergent_Narrative_in_Dwarf_Fortress — academic paper on characterisation and emergent narrative; Tarn Adams 2019 Procedural Storytelling chapter cited; player-driven art (engravings, memorials) as novel-like artifacts.
- https://en.wikipedia.org/wiki/Boatmurdered — community collaborative playthrough; canonical example of emergent DF storytelling; demonstrates how fortress failures become memorable shared narratives.

## Factorio

- https://en.wikipedia.org/wiki/Factorio — release August 14 2020; Wube Software (Czech); C++ proprietary engine; launched via 2013 Indiegogo (€21,626 raised); belt/inserter transport system; assembler recipe system; circuit network; blueprint sharing; science pack research tiers; 3.1M copies by Feb 2022; Space Age expansion 400K copies week-1 (2024); inspiration: Minecraft IndustrialCraft + BuildCraft mods.
- https://medium.com/gaming-is-good/factorio-taught-me-systems-thinking-part-i-f8a1d2a8a349 — systems-thinking analysis: belt bottleneck as legible spatial feedback; main-bus design evolution; automation as progressive elimination of manual steps; late-game train logistics networks; "Cracktorio" nickname; Shopify CEO allows expense.
- https://arxiv.org/pdf/2102.04871 — "The Factory Must Grow": academic analysis of Factorio's automation design; scalability spiral from manual → local automation → mega-factory; pollution/biters as expansion-limiting feedback loop.
- https://arxiv.org/html/2502.01492v1 — AI agent research paper using Factorio as benchmark; confirms game-tick model (60 ticks/second); entity update scheduling; belt transport-line simulation avoids per-item physics.

## Oxygen Not Included

- https://en.wikipedia.org/wiki/Oxygen_Not_Included — release July 30 2019 (early access Feb 2017); Klei Entertainment (Vancouver); Unity engine; three initial duplicants; gas diffusion + liquid gravity simulation; hunger/waste/oxygen tracking; task prioritisation by skill; Metacritic 86; Spaced Out DLC; three additional DLCs 2024–2025; inspired by Dwarf Fortress, Prison Architect, The Sims.
- https://www.gamedeveloper.com/design/layering-challenges-in-klei-s-survival-sim-i-oxygen-not-included-i- — design lead Graham Jans interview; layered simultaneous challenges philosophy; "every pixel is a resource" mass conservation principle; thermodynamics described as "mostly an illusion" (selective simulation); duplicant needs hierarchy (oxygen → food → décor → stress → morale); discovery-based learning (no tutorial) following Don't Starve model; cellular automaton gas sim; material heat capacities and conductivity.
- https://www.neogaf.com/threads/oxygen-not-included-is-a-masterclass-in-colony-sim-design.1685195/ — community analysis: managing thermodynamics / gas diffusion / fluid dynamics / power networks / automation / disease / interplanetary logistics simultaneously; Klei's expressive art style humanises simulation; deliberate divergence from Dwarf Fortress complexity.
- https://game-wisdom.com/series/game-wisdoms-best-2019-8-oxygen-not-included — "Best of 2019" writeup; notes complexity may deter casual players; praises layered depth and interacting systems.

## Frostpunk

- https://en.wikipedia.org/wiki/Frostpunk — release April 24 2018; 11 Bit Studios (Poland); proprietary Liquid Engine; PS4/XBO Oct 2019; macOS Feb 2021; mobile Oct 2024; 250K copies 3 days / 1.4M 1 year / 5M+ 6 years; three story expansions (DLC); Frostpunk 2 Sep 2024.
- https://en.wikipedia.org/wiki/Frostpunk_2 — sequel set 30 years later; expands to faction politics at city-state scale; confirms Frostpunk 1886 remaster (2027) migrates to Unreal Engine 5 with mod support.
- https://www.gamedeveloper.com/design/frostpunk-an-analysis-of-emotional-narrative-engagement — narrative engagement analysis: Hope/Discontent dual bars; Book of Laws irreversibility; citizen feedback via flavour text (not agent simulation); tipping-point mechanic (dissatisfaction accumulates silently before threshold event); bird's-eye view creates emotional distance; linearity limits replayability; moral-storytelling-through-gameplay (not cutscenes); scale converts individual welfare to impersonal governance.
- https://techraptor.net/gaming/features/how-11-bit-studios-created-society-survival-simulator-frostpunk — developer retrospective: iterative development of discontent bar; "what they are really after is an experience"; radial city layout tied to heat source; first city-builder for studio.
- https://twincitiesgeek.com/2018/05/frostpunk-is-a-struggle-between-morality-and-survival/ — design critique: moral choice framework; child labour / dead-storage / medical procedure decisions as law examples; once enacted laws are "written stone"; city-builder structure unusual for genre.
