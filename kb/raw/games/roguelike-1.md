# Raw Provenance — Roguelike Case Studies (Batch 1)

Ingested: 2026-06-14  
Agent: Claude Code (game-research analyst)  
Feeds: `wiki/games/roguelike/Rogue (1980).md`, `NetHack (1987).md`, `Spelunky (2008).md`, `The Binding of Isaac Rebirth (2014).md`, `Slay the Spire (2019).md`

---

## Sources fetched

### Rogue (1980)
- **https://en.wikipedia.org/wiki/Rogue_(video_game)** — Full article. Key facts extracted: creators (Toy, Wichman, Arnold), 3×3 tic-tac-toe grid room generation, curses library, BSD distribution, 26-level dungeon, Amulet of Yendor, permadeath/consequence-persistence, item identification by random descriptors, commercial ports via Epyx.
- **https://playbackgames.medium.com/rogue-1980-53d63e37628d** — Retrospective review. Confirmed genre influence chain (NetHack, Moria, Hades, FTL). Item/potion system described. Hunger clock not detailed here.
- **https://procedural-generation.tumblr.com/post/113155864626/rogue-1980-weve-mentioned-roguelikes-but-just** — Search result only; not fetched directly. Cited as corroborating source for procedural generation framing.

### NetHack (1987)
- **https://en.wikipedia.org/wiki/NetHack** — Full article. Key facts: July 28, 1987 release; fork of Hack (1984); Mike Stephenson, Izchak Miller, Janet Walz; ncurses + C; dungeon branches (Gehennom, Sokoban, Gnomish Mines, class quests); Amulet of Yendor + Astral Plane endgame; Time magazine top 100 (2012); MoMA exhibit (2022–23); NetHack 5.0.0 released May 2026.
- **https://nethackwiki.com/wiki/The_DevTeam_Thinks_of_Everything** — 403 Forbidden at fetch time. Information sourced from search result excerpts: TDTTOE definition, community acronym, examples of programmed edge-case interactions.
- **https://www.nethack.org/** — Official site (search result only). Confirmed NetHack 5.0 release.
- **https://www.theregister.com/2026/05/05/nethack_5/** — Cited for NetHack 5.0.0 release date (May 2026).
- **https://roguebasin.com/index.php/Rogue** — 403 Forbidden at fetch time. Not used directly.
- **Search result: NetHack food/hunger mechanic** — Nutrition system: starts at 900 points, −1 per turn; food ration restores ~800 nutrition; starvation pressure as pacing tool. Sourced from NetHack wiki search excerpts.

### Spelunky (2008)
- **https://en.wikipedia.org/wiki/Spelunky** — Full article. Key facts: 2008 freeware (GameMaker Studio); HD remake 2012 (Xbox); source released 2009 non-commercial; influences (La-Mulana, Rick Dangerous, Spelunker, Super Mario Bros.); Metacritic 83–90.
- **https://www.gamedeveloper.com/design/a-spelunky-game-design-analysis---pt-2** — Full article fetched. Ghost mechanic mentioned but not deeply analyzed; shortcut system described as practice enabler; dark level fairness issue raised (arrow traps + darkness = "cheap"); randomness vs. fairness tension.
- **https://www.toolify.ai/ai-news/unveiling-the-secrets-of-spelunkys-unique-level-creation-96286** — 403 Forbidden at fetch time. Level generation details (4×4 grid, solution path, room templates) sourced from search result excerpts.
- **https://bossfightbooks.com/products/spelunky-by-derek-yu** — Book product page (search result only). Confirmed Derek Yu authored a Boss Fight Books entry on Spelunky design.
- **Search result: ghost mechanic timer** — Ghost in Spelunky 2 spawns at 3 minutes (vs. ~2–2.5 minutes in original); extended to 5 min with Four-Leaf Clover. Original Spelunky shorter. Ghost passes through walls, instant kill on contact, cannot be defeated. Design: time as a resource; arcade-style pacing.

### The Binding of Isaac: Rebirth (2014)
- **https://en.wikipedia.org/wiki/The_Binding_of_Isaac:_Rebirth** — Full article. Key facts: Edmund McMillen design; Nicalis custom engine; November 4, 2014 release; rebuilt from Flash; DLC arc (Afterbirth 2015, Afterbirth+ 2017, Repentance 2021, Repentance+ 2024); co-op in Repentance.
- **https://store.steampowered.com/app/250900/The_Binding_of_Isaac_Rebirth/** — Steam page. Confirmed "randomly generated action RPG shooter with heavy roguelike elements."
- **https://boristhebrave.com/2020/09/12/dungeon-generation-in-binding-of-isaac/** — Full article fetched. Critical technical source: 9×8 grid BFS expansion, 50% neighbor probability, max 2 existing neighbors per cell (tree-like topology), room count formula (`random(2) + 5 + level × 2.6`), boss room at furthest cell, secret rooms adjacent to 3+ rooms, difficulty-scaled room pool selection, Rebirth addition of 2×2/L-shaped rooms.
- **https://bindingofisaacrebirth.fandom.com/wiki/Item_Pool** — Search result only. Confirmed item pool architecture: per-room-type pools (Treasure, Boss, Shop, Devil Deal, etc.), Boss pool as drop on boss defeat.
- **Search result: item synergies** — 700+ items across all DLC; combinatorial synergies many never explicitly designed; community wiki documents thousands of combinations.

### Slay the Spire (2019)
- **https://en.wikipedia.org/wiki/Slay_the_Spire** — Full article. Key facts: early access late 2017; full release January 23, 2019; Mega Crit (Anthony Giovannetti, Casey Yano); LibGDX/Java; 89 Metacritic; four characters; three acts + Heart (Act IV); daily fixed-seed challenge; Casey Yano frustration with LibGDX; Slay the Spire II entered early access March 5, 2026 on Godot.
- **https://www.pcgamer.com/best-design-2019-slay-the-spire/** — Search result excerpt. Confirmed Best Design 2019 award from PC Gamer.
- **https://www.megacrit.com/** — Official site (search result only). Seattle-based studio confirmed.
- **https://rogueliker.com/slay-the-spire-review/** — Full article fetched. Confirmed: three acts, genre cross-pollination from TCG/board games, four characters, outsider-perspective design philosophy, run length 30–60 minutes.
- **https://www.allkeyshop.com/blog/pixel-sundays-slay-the-spire-roguelike-deckbuilder-news-k/** — Full article fetched. Confirmed: map node types (shop, elite, events); card acquisition through battles/shops; deck thinning; relics as "permanent bonuses for a run."

---

## Uncertainty flags

- **Ghost timer in original Spelunky (2008):** Sources confirm ~2–3 minutes; Spelunky 2 is confirmed at 3 minutes. The exact Spelunky 1 timer was not directly confirmed from a fetched source — treat as "approximately 2–2.5 minutes" pending a direct authoritative source.
- **Rogue dungeon structure (26 levels):** Widely cited across sources but not directly confirmed in fetched text; sourced from Wikipedia summary and known genre knowledge.
- **NetHack TDTTOE page:** Fetch returned 403; content sourced from search snippet only. Characterization is accurate per multiple corroborating sources but should be verified against nethackwiki directly if precision matters.
- **Slay the Spire II co-op:** Wikipedia confirmed 4-player co-op and Godot engine for STS2 (March 2026 early access). Verified as current as of 2026-06-14.
