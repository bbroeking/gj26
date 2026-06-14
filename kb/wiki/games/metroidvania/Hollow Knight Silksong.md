---
type: game
tags: [game-study, metroidvania, action-platformer, crafting, boss-design, solo-dev]
status: draft
updated: 2026-06-14
sources:
  - https://hollowknight.wiki/w/Hollow_Knight:_Silksong
  - https://hollowknightsilksong.wiki.fextralife.com/Tools
  - https://nintendoeverything.com/team-cherry-explains-why-hollow-knight-silksong-took-so-long-to-launch/
  - https://esportsinsider.com/silksong-saga-explained
---
# Hollow Knight Silksong

Metroidvania action-platformer sequel (released September 4, 2025; PC/console), developed by Team Cherry, following Hornet through the kingdom of Pharloom with a richer tool, crafting, and boss ecosystem than its predecessor.

## Design

- **Protagonist swap drives new systems.** Hornet's moveset departs from the Knight's nail-and-soul loop: she uses a needle and silk, with a four-colour tool taxonomy — Red (active gadgets with limited uses), Blue (passive defensive), Yellow (passive offensive/exploration), White (Silk Skills that spend the Silk resource). Tools gate traversal exactly as abilities gated areas in the original.
- **Crafting as resource economy.** Shell Shards replenish Red tools at benches; Crafting Kits permanently upgrade tool damage. Quills auto-update the map on rest. This creates a lightweight gather-and-bench loop missing from the first game.
- **~40 legendary bosses, ~200 enemies.** Team Cherry designed the world so objects react to Hornet's tools, demanding a large animation budget per environment — the primary driver of the game's extended development.
- **Act-gated content.** Certain tools are restricted to Act 3, and specific tool combinations (e.g. Cling Grip + Faydown Cloak) unlock new zones, preserving the classic ability-gating structure while layering equipment choice on top.
- **Crest slots** gate how many tools Hornet can equip simultaneously, forcing loadout decisions analogous to Hollow Knight's Notch/Charm system but tilted toward active gadget variety.

## Implementation

- Engine: same custom C#/Unity pipeline used for Hollow Knight (Team Cherry has not publicly confirmed an engine switch).
- Three-person core team (Ari Gibson, William Pellen, and composer Christopher Larkin). Pellen described a 2–3 year window where release felt "12 months away" before scope kept expanding.
- The studio went silent from 2019 onward deliberately — they judged that status updates would only produce repetitive noise. This generated one of indie gaming's most notorious wait cycles; Sea of Sorrow DLC was confirmed in 2026 post-launch.

## Why it matters

- Demonstrates how swapping protagonists with a distinct resource vocabulary (silk/tools vs soul/nail) can justify a full sequel without retreading the original's design space.
- The Crest/tool-slot system is a compact alternative to deep skill trees: meaningful loadout choice without stat bloat.
- The crafting-at-bench loop (Shell Shards, Quills, Crafting Kits) shows a minimal viable crafting system that adds texture without replacing exploration as the core driver.

## Relevance to Wayfinder

- **[[Skills]]** — Silksong's four-colour tool taxonomy (active/passive/silk-cost) maps cleanly onto Wayfinder's hotbar skill design; a colour-coded cost model could inform skill-slot UI legibility.
- **[[Dungeon Generation]]** — Act-gated tool exclusivity is a structural precedent for Wayfinder's affix-driven chart runs where certain abilities or gear tiers only appear in deeper dens.
- **[[Camera and Game Feel]]** — Hornet's needle-and-silk feel (fast, tether-y, precision-demanding) contrasts with Wayfinder's FATE-style cozy camera; useful as a reference for what *not* to borrow from high-precision platformers in a cozy context.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Hollow Knight]] (predecessor) · [[Blasphemous]] · [[Ori and the Blind Forest]]
- Wayfinder: [[Skills]] · [[Dungeon Generation]] · [[Combat]] · [[Bosses]]

## Sources

- https://hollowknight.wiki/w/Hollow_Knight:_Silksong
- https://hollowknightsilksong.wiki.fextralife.com/Tools
- https://nintendoeverything.com/team-cherry-explains-why-hollow-knight-silksong-took-so-long-to-launch/
- https://esportsinsider.com/silksong-saga-explained
- https://hollowknightsilksong.wiki.fextralife.com/Upgrades
