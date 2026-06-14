---
type: game
tags: [game-study, metroidvania, action-platformer, accessibility, time-powers, amulet-system, ubisoft]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Prince_of_Persia:_The_Lost_Crown
  - https://www.inverse.com/gaming/prince-of-persia-lost-crown-accessibility-interview
  - https://www.ubisoft.com/en-us/help/prince-of-persia-the-lost-crown/gameplay/article/time-powers-in-prince-of-persia-the-lost-crown/000106462
  - https://developer.microsoft.com/en-us/games/articles/2025/03/prince-of-persia-the-lost-crown-accessibility/
  - https://www.techradar.com/gaming/consoles-pc/prince-of-persia-the-lost-crown-senior-designer-says-accessible-design-is-good-design
---
# Prince of Persia The Lost Crown

2D Metroidvania action-platformer (January 18, 2024, Ubisoft Montpellier), playing as Sargon of the Immortals on Persian-myth-infused Mount Qaf, critically lauded (Metacritic ~85) for its time-powers traversal system, amulet-build customization, Memory Shards map innovation, and deep accessibility integration.

## Design

- **Six Time Powers gate exploration and enable combat combos.** Abilities include Rush of Simurgh (air dash, stops falling after a hit), Shadow of Simurgh (place a temporal mark, teleport back to it while carrying an ongoing strike), and a power that traps a projectile or enemy in another dimension and deploys it as a temporary ally. Each power doubles as both traversal key and combat tool — no ability is single-purpose.
- **Amulet system for build customization.** Amulets function like Hollow Knight's Charms: equippable upgrades that alter combat performance without unlocking new areas. Found via exploration, boss drops, or purchase with Time Crystals; slot-limited to encourage build identity.
- **Athra Abilities** — resource-gated super attacks with anime-inspired visual flair, separate from the time-power system, rewarding aggressive play.
- **Memory Shards solve the genre's oldest friction point.** Players can take a screenshot of any location and pin it to the map as a visual reminder. Designed to address the cognitive load of tracking "I can't get through here yet; I'll need ability X" — common in Metroidvanias but previously solved only by external notes or mental overhead.
- **Guided Mode** as optional accessibility layer: marks objectives and warns of obstacles without disabling other difficulty settings, letting players opt into support for navigation while keeping boss combat demanding.

## Implementation

- Engine: Ubisoft Montpellier's **internal proprietary engine** (not Unity or Unreal; the studio confirmed Unreal Engine 5 only for a subsequent project). Development lasted approximately 3.5 years.
- Studio best known for the Rayman series — the 2D platformer expertise translated directly; TLC is praised for controls that match or exceed genre stalwarts despite being a franchise reboot.
- Accessibility was integrated from project inception (~2–3 years of dedicated implementation), not bolted on post-gold. Memory Shards required cross-platform prototyping to function consistently. Senior designer Remi Boutin's framing: "accessible design is good design."
- Won multiple awards including France's Pégases 2025 Game of the Year.

## Why it matters

- **Memory Shards** is the most significant UI innovation in the Metroidvania genre in years — a direct answer to the perennial problem of how players track backtracking goals. Every post-2024 Metroidvania should either adopt it or articulate why they don't need it.
- The Time Powers design (traversal key = combat tool) eliminates "dead" traversal abilities that have no combat presence, keeping the ability set economical and each power feeling consequential in fights.
- Demonstrates that AAA investment in a 2D genre can raise the accessibility and polish bar without sacrificing difficulty depth.

## Relevance to Wayfinder

- **[[Dungeon Generation]]** — Memory Shards is directly applicable to Wayfinder's chart/dungeon UX: players navigating a procedural dungeon with locked paths need an in-run pinning system to track "come back here with Fire Ink" without breaking immersion.
- **[[Camera and Game Feel]]** — Mount Qaf's biome diversity and the fluid time-power animations (especially Shadow of Simurgh's temporal echo) are strong feel-reference points for Wayfinder's dungeon rooms; the "stop fall on hit" mechanic specifically addresses the frustration of punishment-by-knockback in platformer combat.
- **[[Skills]]** — Each Time Power being simultaneously a traversal key and a combat tool is the ideal Wayfinder skill design target: a hotbar skill that does something in the overworld/gather context *and* in a combat encounter reads as more valuable than a combat-only cooldown.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Hollow Knight]] · [[Hollow Knight Silksong]] · [[Metroid Dread]] · [[Axiom Verge]]
- Wayfinder: [[Dungeon Generation]] · [[Skills]] · [[Combat]] · [[Camera and Game Feel]]

## Sources

- https://en.wikipedia.org/wiki/Prince_of_Persia:_The_Lost_Crown
- https://www.inverse.com/gaming/prince-of-persia-lost-crown-accessibility-interview
- https://www.ubisoft.com/en-us/help/prince-of-persia-the-lost-crown/gameplay/article/time-powers-in-prince-of-persia-the-lost-crown/000106462
- https://developer.microsoft.com/en-us/games/articles/2025/03/prince-of-persia-the-lost-crown-accessibility/
- https://www.techradar.com/gaming/consoles-pc/prince-of-persia-the-lost-crown-senior-designer-says-accessible-design-is-good-design
- https://news.ubisoft.com/en-us/article/e1SD5gR3TWqk5GPAjWHSz/prince-of-persia-the-lost-crown-will-put-your-combat-platforming-and-puzzlesolving-skills-to-the-test
