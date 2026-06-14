---
type: game
tags: [game-study, arpg, roguelite, roguelike, boons, meta-progression, narrative, single-player]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Hades_(video_game)
  - https://polydin.com/hades-game-design/
  - https://itch.io/blog/772262/blog-post-1-exploring-the-core-systems-and-loops-in-hades
  - https://screenrant.com/hades-roguelike-supergiant-storytelling-accessible/
  - https://hades.fandom.com/wiki/Mirror_of_Night
  - https://hades.fandom.com/wiki/Darkness
---
# Hades

Roguelite action-RPG released in 2020 by Supergiant Games in which the son of Hades fights his way out of the Underworld in a procedurally generated hack-and-slash driven by synergistic god-granted boons and a narrative that advances on every run.

## Design

**Boon system.** Each run, Olympian gods offer boons — single-use power modifications tied to a god's mythological identity (Zeus: chain lightning, Athena: deflect, Poseidon: knockback waves). Boons have rarity tiers (Common → Rare → Epic → Heroic) affecting stat values. Special categories include Duo Boons (requiring two specific gods' boons already equipped) and Legendary Boons (the rarest, build-defining single-god capstones). The gods-as-boon-dispensers mechanic makes build variety feel thematic, not arbitrary.

**Infernal Arms and Aspects.** Six weapons (sword, shield, bow, spear, fists, railgun), each with a distinct primary and special attack pattern. Each weapon has four Aspects unlocked with Titan Blood (earned from bosses), dramatically changing its kit. Hidden Aspects tied to non-Greek mythologies (Arthur's sword, Rama's bow) provide deep late-game targets.

**Meta-progression.** The Mirror of Night converts Darkness (the primary in-run currency) into permanent passive upgrades — extra lives, dash extensions, boon rarity boosts. Chthonic Keys unlock new weapon slots and boons; Gemstones and Diamonds fund cosmetic and relationship gifts. Each currency has a clear purpose, preventing the "bag of numbers" feel common in ARPGs.

**Pact of Punishment (Heat).** Post-completion, players stack difficulty modifiers — e.g., Hard Labor (+20% enemy damage per rank, up to 5 ranks), Lasting Consequences (−25% healing per rank) — each adding Heat points. This is effectively an affix system on the run itself rather than on loot, creating a player-authored challenge loop.

**Narrative integration.** Dialogue with NPCs (Achilles, Meg, Nyx, Chaos) advances across runs regardless of success or failure. Greg Kasavin cited the roguelike structure as enabling branching dialogue that most players would experience, unlike linear games where branching content is mostly missed. Death is narratively diegetic — Zagreus simply returns to the House of Hades, and characters comment on the attempt.

## Implementation

Custom C++ engine with The Forge framework (rebuilt from prior C#/XNA base). Single-player only. Entered Early Access on Epic Games Store December 2018; full release September 2020 on PC and Nintendo Switch. Shipped to consoles August 2021. Sold over one million copies; Metacritic 93/100; BAFTA and D.I.C.E. Game of the Year.

## Why it matters

Hades proved that roguelite structure and authored narrative are not opposites — repeated failure becomes the story delivery mechanism. Its boon system demonstrated how build-space can feel themed and intentional (each god has a coherent identity) while remaining emergent through synergy-hunting. The Pact of Punishment introduced modular self-authored difficulty that gives completionists a meaningful endgame beyond loot.

## Relevance to Wayfinder

- **[[Chart Loop]] and run-authored difficulty.** Wayfinder's [[Affixes]] on charts mirror the Pact of Punishment's modular modifiers: players choose difficulty parameters that shape each delve. The Hades model shows self-authored challenge can be the core endgame loop without requiring gear inflation.
- **[[Skills]] and themed ability sets.** Boons organized by god identity — coherent, synergistic, thematic — is a design model for Wayfinder's [[Skills]] per Trade: each Trade's hotbar abilities should feel like a family, with cross-Trade synergies as the depth layer.
- **Narrative-across-runs.** The diegetic death loop is a reference point for how Wayfinder might surface story beats through repeated dungeon runs without requiring linear progression gates.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Chart Loop]] · [[Affixes]] · [[Skills]] · [[Combat]]
- [[Diablo II]] · [[Path of Exile]] · [[Path of Exile 2]]

## Sources

- https://en.wikipedia.org/wiki/Hades_(video_game)
- https://polydin.com/hades-game-design/
- https://itch.io/blog/772262/blog-post-1-exploring-the-core-systems-and-loops-in-hades
- https://screenrant.com/hades-roguelike-supergiant-storytelling-accessible/
- https://hades.fandom.com/wiki/Mirror_of_Night
- https://hades.fandom.com/wiki/Darkness
