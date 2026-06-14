---
type: game
tags: [game-study, puzzle, rule-manipulation, systems, indie, top-down]
status: draft
updated: 2026-06-14
sources:
  - "https://www.gamedeveloper.com/design/designing-i-baba-is-you-i-s-delightfully-innovative-rule-writing-system"
  - "https://en.wikipedia.org/wiki/Baba_Is_You"
  - "https://www.paulwetzelgamedesign.de/baba-is-you-rule-creation"
  - "https://cleverwasteoftime.com/baba-is-you-rulebending-mechanics-and-creative-problem-solving/"
---

# Baba Is You

Arvi Teikari's 2019 top-down puzzle game in which the rules of reality are physical objects the player can push and rearrange — dissolving the boundary between game system and game world.

## Design

Every rule in Baba Is You is a sentence of three pushable word tiles: `[NOUN] IS [PROPERTY]`. Push "ROCK" out of the line "ROCK IS PUSH" and rocks immediately cease to be pushable. Push "BABA IS YOU" into "WALL IS YOU" and the player character becomes the wall. The win condition is a rule (`FLAG IS WIN`), not a fixed level element — which means the player can also push that rule apart.

This architecture produces a peculiar difficulty curve. Early levels require discovering which rules can be broken; later levels require constructing entirely novel rule chains the designer planted as possibilities but the player must synthesize independently. The game avoids explicit teaching by making experimentation cheap (undo is instant, levels reset in one keypress) and discovery intrinsically satisfying: the moment a rule combination produces an unexpected effect is its own reward.

The standout mechanic is **meta-rule manipulation**: words like TEXT (the word blocks themselves) and LONELY (triggers when a noun is alone on the board) allow rules to modify the rule system itself. Late-game levels require players to construct multi-step logical chains — more formal theorem-proving than traditional puzzle-solving.

A structural constraint worth noting: levels become hard to design when too many rules are active simultaneously. Creator Teikari acknowledges that "levels very easily become overwhelming as the number of initially-active rules increases," which forced some level cuts. Elegant puzzles require sparse starting states.

## Implementation

Built in Multimedia Fusion 2 with Lua scripting. The rule engine updates lazily — it only re-evaluates the active rule set when a word tile moves, not every frame — which keeps the system efficient even as rule counts scale. Rule parsing follows a fixed grammar: scan for nouns, then check right and downward for valid IS + property sequences. Stacked or branching sentences (a word appearing in two perpendicular sentences simultaneously) required a significant engine rewrite to handle all permutations. Released 2019 on PC and Nintendo Switch; mobile in 2021.

Awards: D.I.C.E. Outstanding Achievement in Game Design, GDC Best Design, IGF Excellence in Design and Best Student Game.

## Why it matters

Baba Is You is the most radical answer yet to "what if mechanics were content?" It demonstrates that making a game's own ruleset inspectable and mutable by the player is not a gimmick but a generative design space capable of sustaining hundreds of distinct puzzles. The implication for systems design is that well-structured, player-legible rules can themselves be a form of environmental storytelling.

## Relevance to Wayfinder

1. [[Onboarding and Tutorial]] — Baba's approach of making rules visible (literally readable) rather than abstracted into numbers is a model for how Wayfinder could surface affix logic as legible text on chart tiles rather than stat deltas.
2. [[Dungeon Generation]] — The sparse-state-start principle (too many active rules overwhelms players) is applicable to procgen affix stacking: Wayfinder should limit simultaneous affix interactions per den to a readable number.
3. [[Design Influences]] — The "undo is instant" convention is worth adopting in Wayfinder's chart-crafting UI — low-cost experimentation drives engagement with complex systems.

## See also

- [[Game Index]]
- [[Game Studies]]
- [[Design Influences]]
- [[Onboarding and Tutorial]]
- [[Dungeon Generation]]
- [[The Witness]] (sibling: single-verb grammar generating complexity)
- [[Cocoon]] (sibling: systems that nest inside each other)

## Sources

- [Designing Baba Is You's Innovative Rule-Writing System — Game Developer](https://www.gamedeveloper.com/design/designing-i-baba-is-you-i-s-delightfully-innovative-rule-writing-system)
- [Baba Is You — Wikipedia](https://en.wikipedia.org/wiki/Baba_Is_You)
- [Baba Is You: Rule Creation — Paul Wetzel Game Design](https://www.paulwetzelgamedesign.de/baba-is-you-rule-creation)
- [Baba Is You: Rule-Bending Mechanics — Clever Waste of Time](https://cleverwasteoftime.com/baba-is-you-rulebending-mechanics-and-creative-problem-solving/)
