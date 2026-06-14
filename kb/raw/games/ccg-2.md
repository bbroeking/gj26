# CCG / Deckbuilder Batch 2 — Raw Research Digest
_Ingested: 2026-06-14_

## Sources fetched

| Game | Primary URLs |
|------|-------------|
| Faeria | https://en.wikipedia.org/wiki/Faeria · https://mmohuts.com/review/faeria · https://faeria.fandom.com/wiki/Faeria_Wiki · https://www.faeria.com/the-hub/guide/139-faeria-economy-part-1 |
| Gwent The Witcher Card Game | https://www.playgwent.com/en/news/41252/gwents-design-01-provision · https://www.playgwent.com/en/faq · https://wccftech.com/gwent-witcher-card-game-dev-doesnt-want-people-spend-money-advantage/ (403) |
| Underlords | https://en.wikipedia.org/wiki/Dota_Underlords · https://dotesports.com/dota-2/news/dota-underlords-how-to-play-guide · https://boosteria.org/guides/dota-underlords-the-rise-fall-and-steady-persistence-in-the-gaming-world |
| Inscryption | https://en.wikipedia.org/wiki/Inscryption · https://www.gamedeveloper.com/design/how-game-jam-sacrifices-became-inscryption · https://www.gamedeveloper.com/marketing/inscryption-s-journey-from-game-jam-joint-to-cult-classic |
| Dominion | https://en.wikipedia.org/wiki/Dominion_(card_game) · https://cardboardedison.com/blog/meaningful-decisions-donald-x-vaccarino-dominion · https://dominionstrategy.com/2012/12/20/interview-with-donald-x-vaccarino-part-i-boardgame-design/ |
| Eternal Card Game | https://en.wikipedia.org/wiki/Eternal_(video_game) · https://store.steampowered.com/app/531640/Eternal_Card_Game/ · https://www.direwolfdigital.com/eternal/ |
| Mythgard | https://en.wikipedia.org/wiki/Mythgard · https://nerdlab-games.com/episode-42-mythgard-review-8-exceptional-design-choices-and-what-we-can-learn-from-them/ · https://www.quartertothree.com/fp/2020/12/29/just-when-you-though-it-was-safe-to-ignore-collectible-card-games-mythgard-shows-up/ |
| Cobalt Core | https://en.wikipedia.org/wiki/Cobalt_Core · https://www.gamedeveloper.com/design/how-cobalt-core-makes-movement-as-exciting-as-fighting-in-its-roguelike-deckbuilder-combat · https://www.pcgamer.com/deckbuilder-fans-owe-themselves-some-time-with-the-brilliant-cobalt-core/ |

## Blocked / 403 URLs
- `wccftech.com/gwent-witcher-card-game-dev-doesnt-want-people-spend-money-advantage/` — HTTP 403; Gwent monetization philosophy sourced from playgwent.com FAQ and TV Tropes search results instead.
- `tvtropes.org/pmwiki/pmwiki.php/VideoGame/GwentTheWitcherCardGame` — not fetched directly (search result summary used).

## Key raw findings per game

### Faeria
- Abrakam; Kickstarter 2013, Steam EA March 2016, full launch March 2017; consoles 2020.
- Living board = hex grid where both players lay land tiles each turn. Tiles gate which cards can be played (elemental colour matching). Faeria resource banks without cap (vs fixed mana bars). Well control = income + board pressure in one decision.
- Monetization: oscillated pay-once → F2P → buy-to-play (July 2018). Currently buy-once + cosmetic DLC.
- Metacritic 80. Combat deterministic (no RNG after draw). 30-card decks.

### Gwent
- CD Projekt Red; standalone after being Witcher 3 mini-game. PC/iOS/Android.
- Three-round structure: best-of-three, shared hand across rounds. Passing a round is strategic (concede cheap to draw cards and win rounds 2+3).
- Point salad model: no life totals; round won by highest board power total.
- Provision system: 25-card deck from base ~150-provision budget. High-cost/low-cost trade-offs. Designed to encourage "polarised" decks.
- Three currencies: Ore (buys Kegs/packs), Scraps (craft cards), Meteorite Powder (premium cosmetics). Devs committed publicly to no pay-to-win advantage.
- Five factions each with leader ability.

### Underlords
- Valve; early access June 2019, full release Feb 2020. Source 2 engine. F2P, cosmetic battle pass only.
- Autobattler: shared 8-player lobby, heroes drawn from a shared fixed pool (~45 copies per hero tier). Positioning on 8×8 half-board; combat auto-resolves.
- Gold economy: base gold + win/loss streak bonuses + 1 gold interest per 10 banked (cap 5). Rolling the shop costs gold.
- Alliance synergies: class + species, triggered by fielding requisite count. 3-star merging: three identical heroes combine into powered-up single unit.
- Underlord commander system: personal unit with talent upgrades layered on top.
- 200k+ concurrent Steam players in first week; 1.5M downloads; GameSpot 9/10. Entered maintenance mode late 2020.

### Inscryption
- Daniel Mullins Games (solo developer); Devolver Digital publisher. Windows Oct 2021.
- Ludum Dare 43 prototype ("Sacrifices Must Be Made") → full game.
- Sacrifice mechanic: blood from sacrificed creatures is the resource for summoning. No external mana.
- Scale victory condition: deal 5 net damage to tip scales and win.
- 3×4 four-lane grid. Totem sigil-building (permanent upgrades between runs).
- Three-act genre shift: cabin deckbuilder → pixel RPG → Isaac-like roguelike.
- ARG: physical floppy disks mailed to players who decoded in-game easter eggs.
- 1M+ sales by Jan 2022. GDC GOTY 2022. Seumas McNally Grand Prize.

### Dominion
- Donald X. Vaccarino / Rio Grande Games. October 2008. Board game (physical + Dominion Online digital).
- First deck-building game. Core mechanic: everything in the deck (treasure, actions, VP cards all cycle).
- Draw five per turn. Buy cards from shared supply piles. VP dilution: buying provinces adds dead draws.
- No politics: attack cards hit all opponents equally.
- Spiel des Jahres + Deutscher Spiele Preis 2009. 2.5M+ copies by 2017. 16 expansions.
- No RNG in resolution (only shuffle order). No board; cards + supply piles only.

### Eternal Card Game
- Dire Wolf Digital (Denver, CO), founded 2010. iOS/Android Nov 2016; Steam Nov 2018.
- Fast spells: reactive plays during opponent's turn (unlike Hearthstone).
- Influence + Power: Power cards drawn from deck, one playable per turn. Cards require both total Power and Influence (faction mana) — dual constraint on multicolour.
- Aegis: one-time effect negation shield on affected cards.
- No deckbuilding restrictions: any card in any deck. Throne (eternal), Expedition (rotating), Draft, Forge, Gauntlet modes.
- Designed by Magic Hall of Famers Luis Scott-Vargas and Patrick Chapin.
- "Most generous F2P economy in digital CCGs" — first win daily = pack; daily quest = pack or gold.
- Steam: Mostly Positive, 79%, ~4,680 reviews.

### Mythgard
- Rhino Games (San Mateo, founded 2016 by Peter Hu + Paxton Mason). Monumental took over Oct 2021 after Rhino ceased dev Sep 2021.
- Card-burning: any card can be burned for coloured mana gems; burnt cards cycle back. No land/power cards. Every card has dual value.
- Seven lanes: creatures attack three adjacent lanes (two on edges). Creatures must clear lane ahead to reach opponent face.
- Lane enchantments (Paths): persist after creatures die, creating durable battlefield geography.
- No reaction stack; second-player advantage via lane path bonuses.
- Rarity-copy limits: commons 4x, uncommons 3x, rares 2x, mythics 1x.
- Draft boost/cull: influence upcoming pack colour distribution.
- Urban fantasy setting. Expansions: Rings of Immortality, The Winter War.

### Cobalt Core
- Rocket Rat Games; Brace Yourself Games publisher. Windows/Switch Nov 2023; macOS Jul 2025.
- 1D movement axis: ships slide left/right; attacks target columns; dodge by moving.
- Movement costs card actions; some enemies seek (follow movement).
- Three-crew party from eight; each crew member contributes a specialised sub-deck; all shuffled together.
- Small numbers: single-digit everything. No currency in shops ("choose one treat"). No stat-inflating meta-progression.
- Time loop narrative: crew + CAT AI gradually recover memories across loops.
- Metacritic 94. D.I.C.E. nomination for Strategy/Simulation. Single-purchase, no MTX.

## Wiki pages produced
- `wiki/games/ccg/Faeria.md`
- `wiki/games/ccg/Gwent The Witcher Card Game.md`
- `wiki/games/ccg/Underlords.md`
- `wiki/games/ccg/Inscryption.md`
- `wiki/games/ccg/Dominion.md`
- `wiki/games/ccg/Eternal Card Game.md`
- `wiki/games/ccg/Mythgard.md`
- `wiki/games/ccg/Cobalt Core.md`
