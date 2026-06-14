---
type: game
tags: [game-study, metroidvania, game-feel, emotional-design, unity, indie, microsoft]
status: draft
updated: 2026-06-14
sources:
  - https://www.gamedeveloper.com/audio/postmortem-moon-studios-heartfelt-i-ori-and-the-blind-forest-i-
  - https://en.wikipedia.org/wiki/Ori_and_the_Blind_Forest
  - https://www.orithegame.com/moon-studios/
  - https://indiegameworld.com/features/oris-legacy-the-platformer-that-dances-breathes-and-breaks-your-heart/
---
# Ori and the Blind Forest

Metroidvania platformer (2015, Moon Studios / Microsoft Studios, PC/Xbox One) whose "Animation Design" workflow and emotional-narrative integration set a new benchmark for expressive game feel in the genre.

## Design

- **Animation-first prototyping ("Animation Design"):** Before committing to any movement or ability, Moon Studios produced throwaway concept videos testing feel, then built the game to match. This reversed the typical code-then-animate pipeline and eliminated costly late animation pivots.
- **Metroidvania structure:** Players navigate a contiguous forest world, acquiring abilities (bash, charge-jump, stomp) that gate previously inaccessible zones — explicitly inspired by *Super Metroid* and *Symphony of the Night*. Ability unlocks feel earned because movement itself is so polished.
- **Music as spatial narrative:** Composer Gareth Coker was embedded from pre-production, reading story drafts and attending design meetings. Fully-scored animatics were edited like film before translation into the engine. Dynamic scoring reacts to stakes; color and lighting in hand-painted backdrops signal safe/danger zones without HUD intrusion.
- **Emotional difficulty:** The game is famously hard in places (Ginso Tree escape, Forlorn Ruins) but emotionally soft in framing. Death is non-punishing (custom save-anywhere via "Soul Link"); failure reads as a platform challenge, not narrative punishment.
- **Visual world-reading:** Hand-painted backgrounds use color temperature and depth-of-field to signal traversable versus decorative layers, reducing navigation confusion without waypoints.

## Implementation

- Moon Studios operated as a **distributed virtual studio** — talent hired globally, never required to co-locate. Founded by Thomas Mahler (ex-Blizzard cinematic artist) and Gennadiy Korol (ex-senior graphics engineer).
- Engine: **Unity** (after an early prototype in Construct). Chose Unity to avoid sinking a year into proprietary tech. Shipped at 1080p/60fps on Xbox One and PC simultaneously.
- Development: ~4 years total. Team of roughly 20 multi-disciplinary people. Published by Microsoft Studios, which granted near-total creative freedom.
- Reception: Best Debut at 2016 GDC Awards; sold strongly enough to greenlight *Will of the Wisps* (2020), which expanded every system.

## Why it matters

Ori proved that a small distributed team using Unity could produce a Metroidvania with AAA visual and audio quality by front-loading animation feel rather than back-loading polish. The "Animation Design" workflow is now cited frequently in indie postmortems as the reason the game *moves* like it does. It also demonstrated that emotional narrative and precision platforming are not in tension — story beats can be *implemented* in the platforming geometry itself (e.g., escape sequences as timed puzzle-platformers).

## Relevance to Wayfinder

- **[[Camera and Game Feel]]:** The approach of building the game to match a pre-visualised feel target (not the reverse) is directly applicable; Wayfinder's FATE camera and combat-as-one-verb should be prototyped as animatics before final implementation.
- **[[Skills]]:** Ori's ability unlocks gate geography but feel physically expressive (bash changes direction mid-air); Wayfinder's Trade skill unlocks should feel similarly physical and distinctive, not just UI flags.
- **[[Dungeon Generation]]:** Ori's use of color-coded biomes and depth cues to communicate traversability without waypoints is a strong reference for Wayfinder's dungeon rooms, especially in low-light crypt environments.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Super Metroid]] · [[Celeste]]
- [[Camera and Game Feel]] · [[Skills]] · [[Dungeon Generation]]

## Sources

- https://www.gamedeveloper.com/audio/postmortem-moon-studios-heartfelt-i-ori-and-the-blind-forest-i-
- https://en.wikipedia.org/wiki/Ori_and_the_Blind_Forest
- https://www.orithegame.com/moon-studios/
- https://indiegameworld.com/features/oris-legacy-the-platformer-that-dances-breathes-and-breaks-your-heart/
