---
type: game
tags: [game-study, metroidvania, precision-platformer, game-feel, input-fidelity, indie, accessibility]
status: draft
updated: 2026-06-14
sources:
  - https://maddythorson.medium.com/celeste-forgiveness-31e4a40399f1
  - https://en.wikipedia.org/wiki/Celeste_(video_game)
  - https://www.gamespot.com/articles/celeste-dev-explains-how-they-made-their-game-feel/1100-6474775/
  - https://www.nintendolife.com/news/2018/01/feature_conquering_the_indie_mountain_with_celeste_creator_matt_makes_games
---
# Celeste

Precision platformer (2018, Maddy Makes Games, PC/console) that systematized "forgiveness mechanics" to make a brutally hard game feel kind, while integrating themes of anxiety and self-acceptance directly into its geometry.

## Design

- **Forgiveness as core philosophy:** Every input system is fudged slightly in the player's favor — the overarching goal was "widening timing/positioning windows so everything is fudged a tiny bit." This makes the game feel fair even at extreme difficulty.
- **Key forgiveness mechanics (documented by Thorson):**
  - *Coyote time* — jump is valid for a few frames after leaving a ledge edge.
  - *Jump buffering* — holding jump before landing triggers an immediate jump on the landing frame.
  - *Corner correction* — both jump and dash automatically nudge Madeline around ledge corners rather than cancelling.
  - *Halved gravity at jump apex* — holding jump reduces gravity at peak, extending hang time and adjustment window.
  - *Lift momentum storage* — platform velocity transfers to jump speed and persists briefly after leaving the platform.
  - *Wall-jump proximity* — standard wall-jump works from 2 pixels away; harder super wall-jump from 5+ pixels.
- **Simple moveset, deep emergent complexity:** Only run, jump, wall-climb, and 8-directional dash. The combination space of these four verbs across dense screen-scale rooms produces enormous variety without ability gating.
- **Assist Mode:** A late-addition accessibility layer allowing reduced game speed, unlimited dashing, and invincibility — implemented after community discourse around Cuphead's difficulty. Framed as a design tool, not a "cheat."
- **Narrative-geometry integration:** Madeline's anxiety and self-doubt are expressed through the mountain resisting her — rooms get harder as internal doubt peaks, and the climax requires accepting a shadow-self rather than defeating it.

## Implementation

- Developed by Maddy Thorson (director) and Noel Berry (lead programmer) as a two-person core, later expanded. Started as a **PICO-8 prototype built in four days** (August 2015 game jam); the full game took roughly two years from prototype to release.
- Engine: **Microsoft XNA** (Berry's engine of choice for tight input control). XNA gave frame-level input precision that higher-abstraction engines would have made harder to guarantee.
- Shipped January 2018 across PC, PS4, Xbox One, Switch simultaneously. Sold 1.7 million copies by early 2025; Metacritic 92–94/100 across platforms. Lena Raine's OST widely cited as one of the best video game soundtracks.

## Why it matters

Celeste is the canonical reference for *designed forgiveness* in precision platforming: Thorson's public write-up of the game-feel techniques is one of the most-cited documents in indie game design. It proved that difficulty and kindness are not opposites — a hard game can still feel cooperative by systematically widening player windows. The PICO-8-to-XNA pipeline is also a model for rapid validation before engine commitment.

## Relevance to Wayfinder

- **[[Combat]]:** Wayfinder's "combat as one verb" mantra is congruent with Celeste's simple moveset — the goal is deep feel from a narrow verb set. Forgiveness mechanics (buffer windows, corner correction) apply directly to Wayfinder's attack and dodge timing.
- **[[Camera and Game Feel]]:** Coyote time, jump buffering, and lift-momentum storage are transferable to any action game; they should be in Wayfinder's input layer regardless of whether it has platforming.
- **[[Skills]]:** The Assist Mode design principle — expose tuning parameters to the player without calling them difficulty settings — is worth adopting for Wayfinder's accessibility options in the hotbar/skill system.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Ori and the Blind Forest]] · [[Blasphemous]]
- [[Combat]] · [[Camera and Game Feel]] · [[Skills]]

## Sources

- https://maddythorson.medium.com/celeste-forgiveness-31e4a40399f1
- https://en.wikipedia.org/wiki/Celeste_(video_game)
- https://www.gamespot.com/articles/celeste-dev-explains-how-they-made-their-game-feel/1100-6474775/
- https://www.nintendolife.com/news/2018/01/feature_conquering_the_indie_mountain_with_celeste_creator_matt_makes_games
