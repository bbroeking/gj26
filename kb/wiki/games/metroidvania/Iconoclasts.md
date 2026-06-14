---
type: game
tags: [game-study, metroidvania, action-platformer, solo-dev, puzzle-combat, narrative]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Iconoclasts_(video_game)
  - https://www.gamedeveloper.com/design/the-animation-and-game-design-details-that-make-i-iconoclasts-i-sing
  - https://www.gameanim.com/2018/04/24/iconoclasts-animation-and-game-design-details/
  - https://x.com/konjak/status/1201130851360280576
---
# Iconoclasts

Narrative action-platformer (January 2018, Bifrost Entertainment / Joakim "Konjak" Sandberg), a seven-to-ten year solo development starring mechanic Robin in a theocratic world, distinguished by tightly integrated puzzle-combat boss design and expressive hitbox-animation decoupling.

## Design

- **Wrench as multi-function verb.** Robin's wrench serves as melee weapon, bolt-turner for environmental puzzles, grapple hook, and electrification conduit — a single tool whose context-driven usage unifies combat and exploration without separate ability trees.
- **Auto-aim cone.** Rather than mouse aiming, a 90-degree cone in front of Robin auto-targets enemies during jumps. Players directionally activate the cone but never need precise cursor placement; this keeps movement and combat fluid at high speed without sacrificing read on enemy positions.
- **Hitbox-animation decoupling.** Sandberg separates visual polish from mechanical hitboxes: crouch and turn animations play longer than their functional effect, so the game feels responsive while animations can be full and expressive. The attack box lives on the weapon, not Robin's body rectangle.
- **Puzzle-combat boss loop.** Each boss encounter applies mechanics introduced in the preceding level's puzzle sections — players arrive already competent with the tools the fight demands. Sandberg culls redundant attack phases: once a pattern is understood, the fight escalates rather than repeating.
- **20+ boss encounters** with deliberate narrative spacing rather than mandatory interval pacing.

## Implementation

- Built entirely in **Construct Classic** (Construct 1), an older 2D game-creation tool Sandberg had used for prior projects (Noitu Love). He confirmed this via Twitter/X after speculation about Unreal Engine.
- Fully solo development: art, code, music, and story by Sandberg over approximately 7–10 years (concept c. 2007–2008, full-time development from 2010, shipped January 2018).
- No publisher until late-stage; Bifrost Entertainment handled publishing. The protracted timeline reflects Sandberg's perfectionism and scope creep in narrative ambition.

## Why it matters

- Gold standard for **puzzle-combat integration**: bosses don't introduce alien mechanics — they test what levels already taught.
- The auto-aim cone is a specific, citable solution to the "aim vs. movement" tension in 2D action — worth benchmarking against twin-stick or directional combat in other games.
- Proves Construct Classic (an accessible, non-code-first tool) can ship a polished commercial game if the developer has sufficient resolve; solo-dev durability over a decade.

## Relevance to Wayfinder

- **[[Combat]]** — The auto-aim cone is a direct analogue to Wayfinder's "combat as one verb" ethos: reduce fiddly precision, let movement remain king. Investigate whether a cone-based targeting or soft lock is preferable to free-aim for Wayfinder's dungeon fights.
- **[[Skills]]** — Wrench's context-sensitive multi-role (combat / puzzle / traverse) is a model for how a Wayfinder skill could serve gathering, crafting context, *and* combat without being three separate hotbar slots.
- **[[Dungeon Generation]]** — Puzzle-then-boss sequencing suggests chart rooms could prime players on a mechanic (GatherNode interaction, trap, elite modifier) before the boss den tests it at full intensity.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Hollow Knight]] · [[Blasphemous]] · [[Celeste]]
- Wayfinder: [[Combat]] · [[Skills]] · [[Dungeon Generation]] · [[Bosses]]

## Sources

- https://en.wikipedia.org/wiki/Iconoclasts_(video_game)
- https://www.gamedeveloper.com/design/the-animation-and-game-design-details-that-make-i-iconoclasts-i-sing
- https://www.gameanim.com/2018/04/24/iconoclasts-animation-and-game-design-details/
- https://x.com/konjak/status/1201130851360280576
- https://en.wikipedia.org/wiki/Iconoclasts_(video_game) (engine confirmed as Construct Classic)
