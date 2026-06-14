---
type: game
tags: [game-study, roguelike, dungeon-crawler, procgen, permadeath, item-identification, tolkien, ascii]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Angband_(video_game)
  - https://www.roguebasin.com/index.php/Angband
  - http://angband-dev.blogspot.com/2011/09/so-what-exactly-is-ego-item-anyway.html
  - http://www.phial.com/angband/angfaq2.html
---
# Angband

A free, open-source dungeon-crawling roguelike descended from Moria (1983) and set in Tolkien's Middle-earth, notable for its 100-floor non-persistent dungeon, deep item modding system, and status as the direct design ancestor of Diablo.

## Design

Angband was created by Alex Cutler and Andy Astrand at the University of Warwick around 1990, building on Robert Koeneke's Umoria/Moria codebase. Public release came in April 1993 (v2.4); the game is still actively developed, reaching 4.2.6 in December 2025. The goal: descend 100 procedurally generated floors and defeat Morgoth, Lord of Darkness, then escape alive — a two-leg win condition that sharpens every resource decision.

**Non-persistent levels** are Angband's defining structural choice. Every time the player leaves a floor and returns, it is regenerated from scratch with new monsters and loot. This makes the dungeon effectively infinite and pressures upward movement rather than farming depth — you cannot grind a cleared floor. David Brevik has cited Angband's randomized levels and items as a "huge influence" on Diablo and "the model of what we wanted."

**Item modification tiers** give Angband its loot depth. Equipment falls into plain items, ego items (e.g., a Scimitar of Frost with typed resistances), and fixed artifacts — unique named pieces drawn from a static list (one per game). Most ego items and artifacts look like mundane junk until identified; the identification game is Angband's equivalent of NetHack's potion-shuffle, but extended across all equipment slots and all 100 floors.

**Town level** sits at depth 0 and houses shops where the player buys supplies and sells dungeon finds. It provides a safe hub between delves but also a gold economy that shapes what you risk carrying back versus what you consume in the dungeon.

**Permadeath** is absolute; there is no resume from a dead save. This, combined with non-persistent levels and a 100-floor descent, makes each run a marathon of careful resource stewardship rather than a sprint.

## Implementation

Built in C; compiled for Windows, Linux, macOS, and historically dozens of platforms. Procgen uses room-and-corridor generation seeded per level with no cross-level persistence. The open codebase spawned a prolific variant ecosystem: MAngband (1997, multiplayer), Zangband, and Tales of Maj'Eyal (ToME, 2012) are the most significant. The "Great Code Cleanup" by Ben Harrison in the mid-1990s modularized the codebase and made Angband function as a reusable engine, enabling dozens of derivative works. The game runs on libGDX is not applicable here — Angband is pure C with ncurses/tile frontends.

## Why it matters

Angband proves that **stratified loot with opaque identification** is a game in itself — the dopamine of naming an unidentified ring comes from the same root as opening a card pack or rolling an item in an ARPG. The non-persistent level design also shows how structural constraints can enforce pacing: if the floor regenerates, grinding is impossible by architecture rather than by timer or explicit anti-farm rule. It is the missing link between NetHack's simulation depth and Diablo's item-slot satisfaction.

## Relevance to Wayfinder

1. **[[Affixes]]:** Angband's ego-item system (typed prefix/suffix bonuses on equipment) is the mechanical grandparent of affix grammar. Wayfinder's chart affixes function as run-scoped ego items — each affix pair shapes what the dungeon rewards and punishes, exactly as a Scimitar of Frost shapes what resistances matter.
2. **[[Dungeon Generation]]:** Non-persistent, regenerating floors suggest a counter-model to level permanence; Wayfinder's chart-keyed runs are spiritually similar — each chart run generates a fresh dungeon rather than returning to a persistent one.
3. **[[Items and Gear]]:** Angband's identification mini-game (discovering item properties through use or explicit ID scrolls) is a precedent for giving mundane Wayfinder loot a discovery arc rather than labeling everything on pickup.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[NetHack]] — sibling; [[Hades]] — modern roguelite heir
- [[Dungeon Generation]] · [[Affixes]] · [[Items and Gear]] · [[Chart Loop]]

## Sources

- https://en.wikipedia.org/wiki/Angband_(video_game)
- https://www.roguebasin.com/index.php/Angband
- http://angband-dev.blogspot.com/2011/09/so-what-exactly-is-ego-item-anyway.html
- http://www.phial.com/angband/angfaq2.html
