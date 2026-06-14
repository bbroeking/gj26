---
type: game
tags: [game-study, rhythm, community, user-generated-content, performance-points, free-to-play]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Osu!
  - https://osu.ppy.sh/wiki/en/History_of_osu!/2007
  - https://handwiki.org/wiki/Software:Osu!
  - https://osugame.fandom.com/wiki/Game_modes
  - https://osu.ppy.sh/wiki/en/Beatmapping/Mapping_techniques/Rhythm
---

# Osu!

A free, open-source rhythm game created by Dean "peppy" Herbert in 2007 whose defining feature is an entirely community-authored content library of millions of "beatmaps," with ranked quality control managed through volunteer moderation.

## Design

Osu! launched in September 2007 as a single game mode — osu!standard — in which players click, hold, and spin hit objects (circles, sliders, spinners) placed on-screen in sync with a song's rhythm. Three further modes were added over subsequent years: osu!taiko (drum-hit simulation, based on Taiko no Tatsujin), osu!catch (a catcher character collects falling fruit on beat), and osu!mania (a vertical-scrolling piano/VSRG mode, inspired by Dance Dance Revolution and Beatmania). Each mode is a self-contained game with its own ranking ladder.

The central design asset is the beatmap: a community-created chart pairing a song to hit-object placements. Mappers compose beatmaps in osu!'s built-in editor, then submit them for peer review. Volunteer "Beatmap Nominators" assess maps against the osu! Ranking Criteria — a detailed quality standard covering pattern density, visual readability, audio syncing, and difficulty gradient. Maps that clear two nominations enter the Ranked pool; only Ranked maps award Performance Points (pp).

pp is the core progression currency. Score is not the primary leaderboard metric; instead, pp is computed from map difficulty and accuracy, then aggregated across a player's top performances into a global rank. This incentivizes chasing harder maps, not replaying easy ones for score.

The community scale is significant: over 26 million registered accounts as of late 2025, and a beatmap library covering effectively all popular genres of music. The osu! Museum project, assembled collectively by the community, preserves the digital history of maps, players, and mapping scenes.

## Implementation

Osu! is free to play with an optional supporter subscription that funds server costs. The game client and server are maintained open-source (osulazer, the current client, is on GitHub). The beatmap ranking pipeline is peer-reviewed rather than staff-gated, which scales moderation without requiring Peppy's team to evaluate every submission.

The pp algorithm has been rebuilt multiple times as the community identified score-manipulation exploits. A "difficulty calculator" underpins each mode's pp — for osu!standard it considers aim complexity, tap speed, and approach-rate processing demand. Latency sensitivity is high in osu!standard: competitive play on top-tier maps requires sub-10ms input-to-display timing, making monitor refresh rate and input lag genuinely impactful.

No VR mode exists; osu! is a desktop game designed for mouse, tablet, keyboard, or touch. It intentionally targets a 2D precision-aiming audience.

## Why it matters

Osu! is the largest demonstration that volunteer-run quality curation can sustain a community content library at tens-of-millions-of-items scale. The pp ranking system — where personal best performances aggregate into a single rank — is a clean model for "skill-indexed progression without zero-sum competition": a player always advances by self-improvement, not by displacing others. The ranked/unranked content split (ranked awards currency; unranked is for play only) is a directly useful pattern for any game that needs to separate quality-assured content from a freeform sandbox.

## Relevance to Wayfinder

1. → [[Onboarding and Tutorial]]: Osu!'s pp aggregation model — where your rank rises by hitting harder maps, and easy maps can always be revisited without penalty — maps cleanly to Wayfinder's chart system: lower-den charts could remain replayable for resource gathering while deeper dens unlock pp-style prestige. The incentive structure discourages staying in the same easy loop.
2. → [[Camera and Game Feel]]: The strict latency requirements of top-tier osu! play underline that precision-feel is hardware-dependent. Wayfinder's dungeon input loop should validate its hit-window feel across varying refresh rates rather than assuming a fixed display latency.

## See also

- [[Game Index]]
- [[Game Studies]]
- [[Design Influences]]
- [[Camera and Game Feel]]
- [[Onboarding and Tutorial]]
- [[Beat Saber]]
- [[Guitar Hero III]]
- [[Tetris Effect Connected]]

## Sources

- https://en.wikipedia.org/wiki/Osu!
- https://osu.ppy.sh/wiki/en/History_of_osu!/2007
- https://handwiki.org/wiki/Software:Osu!
- https://osugame.fandom.com/wiki/Game_modes
- https://osu.ppy.sh/wiki/en/Beatmapping/Mapping_techniques/Rhythm
