---
type: game
tags: [game-study, strategy, 4x, turn-based, dynasty, orders, character, antiquity]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Old_World_(video_game)
  - https://mohawkgames.com/oldworld/
  - https://www.metacritic.com/game/old-world/
---
# Old World

Historical 4X turn-based strategy (2021, Mohawk Games), designed by Soren Johnson (Civilization IV lead) as a deliberate narrowing of the 4X formula — constraining scope to classical antiquity, limiting action budget via an Orders system, and replacing the immortal-leader trope with a full dynasty and succession simulation.

## Design

- **Orders system** — each turn grants a limited pool of Orders (action points) distributed across all units and cities. Moving a large army requires multiple Orders; a single unit can act multiple times until exhausted. The constraint forces genuine prioritization: players cannot do everything each turn, so every decision forecloses others. This is the game's central innovation.
- **Dynasty and succession** — leaders age and die; players must cultivate heirs, arrange marriages, and manage court intrigue to ensure a capable successor. A great king followed by an incompetent heir reverses decades of progress. Character traits (educated, bold, cowardly, pious) emerge from life events and player choices, making rulers feel like individuals rather than stat blocks.
- **Character event system** — scripted and semi-procedural events fire based on court relationships, terrain, and world state; players make dialogue-style choices that affect character traits, family relationships, and kingdom-level effects. The event layer is borrowed explicitly from Crusader Kings, translating it into a focused classical-era context.
- **Ambitions** — periodic medium-term goals (build a certain building, defeat a specific rival, etc.) give players momentum objectives between the long arc of civilization-building and the immediate tactical turn, functioning as a pacing mechanism to prevent mid-game drift.
- **Focused scope** — unlike Civilization's 6,000-year sweep, Old World covers only the ancient/classical period; this constraint allows deeper thematic coherence, more historically grounded events, and a manageable tech tree without feeling artificially truncated.
- **Yield-based economy** — cities produce yields (food, production, gold, culture, civics) from worked tiles; the Civics yield specifically unlocks government and law improvements, giving culture a concrete mechanical expression separate from research.

## Implementation

- **Unity** (C#), Mohawk Games' engine of choice for an indie team; leverages procedural map generation with terrain biome layering.
- Originally released via Epic Games Store exclusive (2020 early access); released on Steam in July 2021.
- Soren Johnson's design blog (Wayward Thinker) provides extensive designer-commentary on the Orders system and dynasty mechanics — a rare primary source for design intent.
- PC Gamer: Best Strategy Game of 2021. Metacritic: 80/100.

## Why it matters

- Old World's Orders system is the clearest modern answer to the "why can everything act every turn?" problem in 4X design: limited action budgets make every turn a puzzle, not a checklist.
- The dynasty layer proves that **character mortality creates more narrative investment than character persistence**: a beloved king dying mid-campaign is more emotionally resonant than an immortal leader who simply upgrades.
- Soren Johnson's explicit narrow-scoping is a design philosophy lesson: choosing to cover 500 years instead of 6,000 allows depth that breadth-focused games cannot reach. Constraint is a feature, not a compromise.

## Relevance to Wayfinder

- **[[Balance Philosophy]]** — the Orders system (limited action budget per turn) maps to Wayfinder's chart inscription: the Wayfinder trade's ink budget per chart functions as an Orders-equivalent, forcing meaningful affix selection rather than taking everything.
- **[[Economy]]** — Civics as a separate yield (cultural production → governance unlocks) suggests that Wayfinder's Wildcraft and Earthcraft trade progression could have distinct "soft" currencies that gate non-combat upgrades, separate from gold/material economy.
- **[[Combat]]** — character mortality and dynasty succession suggest a Wayfinder mechanic: if hired NPCs or crafted items can be permanently lost in a dungeon run, loss becomes a narrative event rather than a trivial setback.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Civilization VI]] · [[Crusader Kings III]] · [[Humankind]] · [[Endless Legend]]
- [[Balance Philosophy]] · [[Economy]] · [[Combat]]

## Sources

- https://en.wikipedia.org/wiki/Old_World_(video_game)
- https://mohawkgames.com/oldworld/
- https://www.metacritic.com/game/old-world/
