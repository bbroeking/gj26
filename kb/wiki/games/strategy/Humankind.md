---
type: game
tags: [game-study, strategy, 4x, turn-based, culture, progression, asymmetry, fame]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Humankind_(video_game)
  - https://www.ancientworldmagazine.com/reviews/humankind-game/
  - https://store.steampowered.com/app/1124300/HUMANKIND/
---
# Humankind

4X turn-based strategy (2021, Amplitude Studios / Sega), which replaces Civilization's fixed nation identity with a culture-drafting system — players select one of 10 cultures per era across seven eras, theoretically enabling a million distinct civilizational archetypes, with Fame rather than distinct win conditions determining victory.

## Design

- **Culture-swapping** — at the start of each era, players choose one of 10 available cultures (60 total across eras); each culture grants a unique unit, infrastructure bonus, and Legacy Trait that persists forever. You are never permanently "one civilization" — your empire is an accumulation of cultural choices, making each run narratively unique.
- **Fame-based single victory condition** — instead of Science/Domination/Culture/Religious victories, all players compete on a single Fame score accumulated through wonders, territorial achievements, battle victories, and narrative events. The simplification forces direct competition rather than players racing parallel tracks.
- **FIMS + Influence economy** — Food, Industry, Money, Science, and Influence drive all production; Influence buys territory attachments, faith spreads, and diplomatic maneuvers, functioning as a soft power currency absent from most 4X games.
- **Tactical battle system** — field battles play out on a sub-map over three combat rounds with terrain advantages; after three rounds the result auto-resolves. This makes every battle feel consequential without demanding full real-time control, and terrain becomes a tactical resource.
- **Neolithic opening** — unlike Civilization's Bronze Age start, players begin as a Neolithic tribe choosing their first culture upgrade, making the era 0 a "how you found your empire" origin story beat.
- **Independent cities and city merging** — city-states exist as semi-autonomous entities that can be diplomatically absorbed; cities in adjacent territories can be merged into outposts rather than maintained as separate administrative burdens.

## Implementation

- **GAMES2 Engine** — Amplitude's proprietary engine (C++), shared with Endless Space 2 and Endless Legend 2; handles hex-grid worldgen with biome layering, per-era visual theme shifts for infrastructure, and narrative event triggering.
- Removed Denuvo anti-piracy software post-launch after performance benchmarks revealed measurable framerate impact — notable for being public about the trade-off.
- Metacritic: 77/100 (Windows). Critics broadly praised culture-swapping as the game's standout idea while noting weaker-than-Civilization personality per nation.

## Why it matters

- Humankind proves that **identity as a choice at each era boundary** is more replayable than a fixed nation: the question "what culture should I be?" happens seven times per game, each time under different strategic pressure.
- The single Fame victory condition is a radical simplification worth studying: it eliminates runaway-leader detection complexity (everyone competes on one leaderboard) at the cost of reducing endgame strategic variety. The trade-off is legibility for nuance.
- The three-round tactical battle system hits a middle path between full RTS micromanagement and pure auto-resolve abstraction — it is brief enough to be repeatable, consequential enough to reward terrain reading.

## Relevance to Wayfinder

- **[[Balance Philosophy]]** — Humankind's era-by-era culture drafting is a model for Wayfinder chart affixes as a "build a run" draft: players could select one affix at each dungeon depth tier, producing a cumulative identity for that run without committing at the start.
- **[[Economy]]** — the FIMS+Influence resource split (hard production resources + a soft social-power currency) mirrors Wayfinder's potential split between material economy (gather → craft) and social economy (reputation, trade relationships with town NPCs).
- **[[Dungeon Generation]]** — the Neolithic era as an explicit "origin" before the main game starts suggests Wayfinder could use a chart-inscription phase (before dungeon entry) as a parallel "choose your run identity" beat.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Civilization VI]] · [[Old World]] · [[Endless Legend]]
- [[Balance Philosophy]] · [[Economy]] · [[Dungeon Generation]]

## Sources

- https://en.wikipedia.org/wiki/Humankind_(video_game)
- https://www.ancientworldmagazine.com/reviews/humankind-game/
- https://store.steampowered.com/app/1124300/HUMANKIND/
