---
type: game
tags: [game-study, puzzle, programming, tomorrow-corporation, visual-programming, teaching, optimization]
status: draft
updated: 2026-06-14
sources:
  - "https://en.wikipedia.org/wiki/Human_Resource_Machine"
  - "https://tomorrowcorporation.com/humanresourcemachine"
  - "https://medium.com/@rachaelversaw/human-resource-machine-teaching-coding-basics-56e79e7db175"
  - "https://store.steampowered.com/app/375820/Human_Resource_Machine/"
---

# Human Resource Machine

Tomorrow Corporation's 2015 visual programming puzzle game that teaches assembly language fundamentals through office-worker drag-and-drop, with optional optimization challenges that expose algorithmic elegance to players who never expected to care about it.

## Design

Human Resource Machine's conceptual hook is ruthlessly efficient: the player is an office drone directing a worker to move boxes from an inbox conveyor to an outbox conveyor. The "boxes" are integers or characters; the "office floor" has a fixed number of labeled memory slots. The instruction set starts at two commands and expands to eleven over forty puzzles — exactly the set needed to implement most classical computer-science algorithms. By the final levels, players are writing what amount to sorting routines and string parsers, though the game never uses those words.

The office metaphor is load-bearing, not decorative. Tomorrow Corporation's stated rationale: the physical, spatial layout of inbox → memory slots → outbox makes the abstract Harvard architecture of a CPU (accumulator, memory addresses, I/O) tangible through everyday analogy. Players who have never encountered a register understand "pick up this box, put it in the slot marked 4" before they realize they are modeling `MOV AX, [4]`.

Each puzzle comes with two optional Optimization Challenges — one for minimum steps (program size), one for minimum executions (runtime). These are genuinely hard: solutions that clear the puzzle comfortably are rarely efficient. The challenges convert the game's audience: casual players finish the puzzles and feel satisfied; algorithm-minded players return to shave steps, discovering the beauty of tight loops and branch elimination.

The corporate satire — "Management is watching," dystopian flavour text, a company that literally consumes its workers — gives the game a tonal personality absent from most programming games. The narrative is underused by most reviewers' accounts, but the atmosphere sustains engagement through the harder late-game puzzles.

## Implementation

Released October 2015 by Tomorrow Corporation (Kyle Gabler, Allan Blomquist, Kyle Gray — the World of Goo team). Available on Windows, macOS, Linux, iOS, Android, and Nintendo Switch. The drag-and-drop interface was purpose-built to lower the barrier for non-programmers; there is no keyboard-based code editor. A sequel, *7 Billion Humans* (2018), expands to multi-agent parallelism, where players program crowds of workers simultaneously.

## Why it matters

Human Resource Machine proves the accessibility ceiling for programming-puzzle games is higher than the genre assumed. By removing syntax entirely and grounding every concept in a physical metaphor, Tomorrow Corporation delivered a game that genuinely taught loops, conditionals, and memory addressing to players with no coding background — while still offering enough depth to satisfy experienced programmers. Its Hour of Code edition (a free, simplified variant) was adopted by schools globally, validating the core teaching loop at scale.

## Relevance to Wayfinder

1. [[Onboarding and Tutorial]] — The game's graduated command introduction (2 commands → 11 over 40 levels) is the clearest industry example of a tutorial that is also the full game. Wayfinder could apply this to chart affix introduction: start each chart type with a single affix, layer combinations only after the player has internalized each element alone.
2. [[Crafting]] (systems-as-toys) — The dual optimization challenge (size vs. speed) mirrors how a crafting recipe in Wayfinder could have two competing excellence dimensions: yield efficiency vs. time-to-complete. Players who satisfy the base recipe move on; players who want mastery return to optimize.
3. [[Balance Philosophy]] — The Harvard architecture metaphor demonstrates that abstraction is a design tool: the right model hides real-world messiness without lying. Wayfinder's stat system can borrow this — surface only the variables that produce interesting decisions, hide the implementation detail.

## See also

- [[Game Index]]
- [[Game Studies]]
- [[Design Influences]]
- [[Crafting]]
- [[Onboarding and Tutorial]]
- [[Balance Philosophy]]
- [[Opus Magnum]] (parallel: programming puzzle with broader accessibility)
- [[SpaceChem]] (parallel Zachtronics — harder, chemistry-coded)
- [[Shenzhen I O]] (Zachtronics counterpart — assembly language, more authentic)

## Sources

- [Human Resource Machine — Wikipedia](https://en.wikipedia.org/wiki/Human_Resource_Machine)
- [Human Resource Machine — Tomorrow Corporation Official](https://tomorrowcorporation.com/humanresourcemachine)
- [Human Resource Machine: Teaching Coding Basics — Medium](https://medium.com/@rachaelversaw/human-resource-machine-teaching-coding-basics-56e79e7db175)
