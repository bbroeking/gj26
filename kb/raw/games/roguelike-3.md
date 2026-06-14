# Raw source digest: roguelike-3
**Ingested:** 2026-06-14
**Covers:** Noita, Caves of Qud, Darkest Dungeon, Balatro, Hades II
**Fed into:** wiki/games/roguelike/Noita.md, Caves of Qud.md, Darkest Dungeon.md, Balatro.md, Hades II.md

---

## Noita

**Sources fetched:**
- https://en.wikipedia.org/wiki/Noita_(video_game)
- https://noitagame.com/
- https://store.steampowered.com/app/881100/Noita/
- https://www.gamedeveloper.com/design/video-understanding-the-remarkable-tech-and-design-of-i-noita-i- (GDC 2019 Purho talk — page gated; description scraped)
- https://handwiki.org/wiki/Software:Noita_(video_game)

**Key facts confirmed:**
- Studio: Nolla Games (Helsinki); three senior devs: Petri Purho (Crayon Physics Deluxe), Olli Harjola (The Swapper), Arvi Teikari (Baba Is You)
- Release: Early Access Sep 2019; full release Oct 15, 2020
- Engine: "Falling Everything" (custom C++); falling-sand / cellular automata pixel physics
- Core design axes: pixel-physics world, wand building (spell-as-program), alchemy (material reactions), no meta-progression (knowledge only)
- Metacritic: 76/100; Finnish GOTY; IGF + GDC nominations
- GDC 2019 talk covers: scaling falling-sand to continuous worlds, rigid body integration, emergent gameplay fine-tuning

---

## Caves of Qud

**Sources fetched:**
- https://en.wikipedia.org/wiki/Caves_of_Qud
- https://www.cavesofqud.com/
- https://www.gamedeveloper.com/design/tapping-into-the-potential-of-procedural-generation-in-caves-of-qud
- https://media.gdcvault.com/gdc2019/presentations/Grinblat_Jason_End-to-End_Procedural_Generation.pdf

**Key facts confirmed:**
- Studio: Freehold Games (USA); co-creators Brian Bucklew and Jason Grinblat
- Release: 9-year Early Access; 1.0 December 5, 2024; Switch February 16, 2026
- Engine: Unity (C#); originally ASCII/console-mode
- World gen: history generation (5 ancient rulers) → faction/settlement placement → wilderness → dungeons; each layer consumes prior layer's artifacts
- Character: True Kin (cybernetics) vs. Mutant (mutations) binary; every NPC runs player's rules
- Metacritic: 91/100; 2025 Hugo Award Best Game; IGF Excellence in Narrative
- Design philosophy: "deeper couplings between process and culture" (Grinblat); surreal ASCII leverages imagination

---

## Darkest Dungeon

**Sources fetched:**
- https://en.wikipedia.org/wiki/Darkest_Dungeon
- https://www.darkestdungeon.com/darkest-dungeon/
- https://gdcvault.com/play/1023089/Darkest-Dungeon-A-Design (GDC Vault — access description only)
- https://media.gdcvault.com/gdc2016/Presentations/Sigman_Tyler_Darkest_Dungeon_a.pdf
- https://thegemsbok.com/art-reviews-and-articles/darkest-dungeon-red-hook-critique-mechanics-design/

**Key facts confirmed:**
- Studio: Red Hook Studios (BC, Canada); founders Chris Bourassa, Tyler Sigman
- Release: January 19, 2016 (Kickstarted 2014; Early Access 2015)
- Engine: Custom "homebrewed, lightweight cross-platform engine" (Kelvin McDowell)
- Core systems: Stress (0→100 Meltdown, 0→200 heart attack), Affliction vs. Virtue, rank-based positional combat, Hamlet hub
- 15 hero classes; permanent permadeath; 4-hero parties; darkness light dial
- Metacritic: 84/100; 2M+ copies by Dec 2017
- GDC 2016 postmortem (Sigman) covers: stress origin (Call of Cthulhu sanity), Early Access iteration challenges, CRPG/boardgame/roguelike synthesis

---

## Balatro

**Sources fetched:**
- https://en.wikipedia.org/wiki/Balatro
- https://store.steampowered.com/app/2379780/Balatro/
- https://balatrogame.fandom.com/wiki/Balatro
- https://blakecrosley.com/guides/design/balatro
- https://www.kokutech.com/blog/gamedev/design-patterns/power-fantasy/balatro
- https://www.pcgamer.com/i-dont-play-poker-at-all-says-solo-developer-who-made-the-poker-roguelike-i-cant-stop-playing/

**Key facts confirmed:**
- Developer: LocalThunk (solo); Publisher: Playstack; 2.5-year development
- Release: February 20, 2024; mobile Sep 26, 2024
- Engine: Löve2D (Lua)
- Core: Chips × Mult scoring; 150 Joker cards; Tarot/Planet/Spectral card layers; 8-ante run structure; Voucher permanent upgrades
- Jokers fire left-to-right sequentially; multiplicative Jokers compound; animated per-Joker feedback
- No power meta-progression (unlock=content, not power)
- Sales: 5M+ copies by Jan 2025; GDC GotY 2025; GTA/TGA 2024 GOTY nominee (first solo-dev nomination)
- Inspired by: Big Two card game + Luck Be a Landlord roguelike

---

## Hades II

**Sources fetched:**
- https://en.wikipedia.org/wiki/Hades_II
- https://www.gamespot.com/articles/hades-2-everything-we-know-about-supergiants-upcoming-roguelite/1100-6520218/
- https://www.pcgamesn.com/hades-2/arcana-cards
- https://www.thegamer.com/hades-2-arcana-cards-upgrades-unlock-cost-activate/
- https://wolfsgamingblog.com/2026/05/06/hades-2-review-god-tier-roguelike-action/
- https://finalboss.io/hades-ii-s-the-unseen-update-is-supergiant (early access patch notes context)
- https://www.ingamenews.com/2025/09/hades-2-mastering-essential-resources.html

**Key facts confirmed:**
- Studio: Supergiant Games; first sequel; full release 2025
- Engine: Custom proprietary C++ (same as all Supergiant titles)
- New systems vs. Hades 1: dual paths (underworld + surface), Arcana cards (27 cards, Ash cost, Grasp cap), Hex attacks (Selene; Magick meter), in-run gathering + cauldron crafting (incantations), familiars, Fear difficulty system
- Arcana: unlock with Ashes; activate with Grasp (expandable with Psyche); 9 visible at start, 27 total; upgradeable with Moon Dust
- Gathering: Silver Spade tool (crafted via cauldron); dig Nightshade in Erebus; plant in garden; harvest post-encounter
- Metacritic: 94/100 PC, 98/100 Switch
- Ending backlash post-launch; Supergiant added scenes one month later
