---
type: game
tags: [game-study, metroidvania, soulslike, indie, checkpoint-design, death-penalty, charm-system, geo-currency, shade-mechanic]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Hollow_Knight
  - https://www.dualshockers.com/hollow-knight-design-choices-that-made-it-a-modern-metroidvania-classic/
  - https://hollowknight.fandom.com/wiki/Hollow_Knight_(game)
  - https://www.gamedeveloper.com/design/how-the-i-hollow-knight-i-devs-mapped-out-their-metroidvania-
  - https://www.pcgamer.com/gaming-industry/hollow-knights-creators-didnt-want-to-be-constrained-by-the-metroidvania-label-but-they-accidentally-set-a-standard-that-every-game-since-even-silksong-has-to-reckon-with/
---
# Hollow Knight

2D action-adventure (2017, Team Cherry, Unity) — a metroidvania-soulslike hybrid set in the insect kingdom of Hallownest, combining Geo currency with a Shade death-penalty, charm-notch build system, and bench checkpoints to create the modern benchmark of the genre.

## Design

- **Geo + Shade death loop.** Geo (the currency) is dropped on death and left at a hostile "Shade" — a dark echo of the player that spawns at the death location. To recover the Geo the player must return and defeat the Shade before dying again; dying a second time destroys both the Shade and all lost Geo. This is the bloodstain mechanic transposed into 2D: one recovery attempt, permanent loss on second death. The Shade is hostile (it fights back), making retrieval a skill challenge, not just a walk of shame. Losing large Geo accumulations — especially late-game — is genuinely consequential.
- **Bench checkpoints.** Benches are the game's bonfire equivalent: rest here to restore health and relocate the respawn point. Unlike bonfires, benches do not respawn enemies; the world's enemy state is not reset on rest. This removes the "bonfire respawn tradeoff" but retains the spatial tension of knowing where the nearest bench is before committing to a difficult section.
- **Charm notch system — soft loadout cap.** Charms are passive ability modifiers (attack speed, ranged spike projectiles, Soul efficiency, etc.) equipped from a pool. Each charm costs 1–3 notches; the player has a fixed total notch count (expandable by finding items). The system creates genuine build decisions within a soft cap: every equipped charm displaces another, so the loadout is a reflection of playstyle. Charms can be swapped freely at any bench, lowering the cost of experimentation without removing the constraint.
- **Soul meter: dual-use resource.** Soul is the single meter powering both spells (offensive) and healing (Focus). The player must choose, mid-combat, whether to spend accumulated Soul on a damage spell or a slow-cast heal. This makes healing a tactical action with opportunity cost — not a free refill.
- **No parry; positioning-first combat.** Team Cherry deliberately omitted a parry. The defensive toolkit is dash + jump; success requires reading enemy patterns and moving around them. This emphasizes spatial awareness over reflex-pressing, aligning with the metroidvania tradition of traversal-as-skill.
- **Progression gating via ability unlocks, not stat gates.** New areas are unlocked by finding traversal abilities (dash, double-jump, wall-cling) rather than by meeting stat thresholds. This is Metroid's model rather than Dark Souls's; gear (Nail upgrades) increase damage but rarely gate a path.
- **Nail: unified melee verb.** The Nail is the single melee weapon, upgradeable but not replaced. Nail Arts (charged attacks) add mechanical depth without adding weapon variety — a "one verb, many expressions" model.

## Implementation

- Engine: Unity (2D).
- Metacritic: 90 (Switch), 87 (PC), 89 (Xbox One), 85 (PS4). Raised A$57,000 on Kickstarter; became a landmark of the 2017 indie wave.
- 15 million copies sold as of August 2025, across PC, Switch, PS4/5, Xbox.
- Four free DLC expansions (Grimm Troupe, Godmaster, etc.) added bosses, game modes, and story. The free DLC model was unusual and generated sustained goodwill.
- Sequel Hollow Knight: Silksong has been in development since 2019 and is one of the most anticipated unreleased games as of 2026. The Silksong design replaces Geo entirely with a crafting-currency system, suggesting Team Cherry's own dissatisfaction with the original currency loop.
- Made with Unity by a three-person Australian team (William Pellen design/code, Ari Gibson art/animation, Jack Hale audio). The scale-vs-team-size ratio is cited as a proof point for small indie studios.

## Why it matters

Hollow Knight is now "the Metroidvania" — the genre benchmark every subsequent game is compared against. Its specific contribution to the soulslike-metroidvania hybrid is the Shade: it proves the bloodstain-style death penalty survives transposition into 2D without a bonfire-respawn tradeoff, and that a hostile Shade makes the retrieval attempt genuinely skill-testing rather than merely cosmetic. The charm-notch system is the cleanest published example of a soft-cap loadout builder: it creates meaningful choices without permanent commitment, making theory-crafting accessible to a wide audience. The Soul dual-use (attack or heal) is the textbook example of single-resource tension.

## Relevance to Wayfinder

- **Shade mechanic as cozy death penalty model.** Wayfinder's cozy tone rules out severe punishments, but the Shade translates well: losing currency/chart-dust at death, recoverable by returning to the death spot and defeating a mild enemy. The Shade is *proportional* — the penalty scales with how much was carried, so early-game deaths sting less. See [[Combat]], [[Items and Gear]].
- **Charm-notch as Skill/hotbar design blueprint.** Wayfinder's hotbar Skill system maps naturally to charms: each Skill costs notches (hotbar slots), the player swaps at a safe location (the Wayfinder's tent/campfire), and the total slot count can increase with progression. The key lesson: the cap creates the choice. See [[Skills]], [[Items and Gear]].
- **Soul dual-use as a co-op resource tension model.** If Wayfinder has a shared-or-individual mana pool, the "attack vs. heal" tension applies directly — spending the resource to finish a fight faster vs. saving it to sustain the party. In co-op this could become a genuine table-discussion moment. See [[Multiplayer Co-op]], [[Combat]].

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Lessons for Wayfinder]]
- [[Dark Souls]] · [[Elden Ring]] · [[Sekiro Shadows Die Twice]] · [[Bloodborne]]
- [[Combat]] · [[Bosses]] · [[Enemies]] · [[Camera and Game Feel]] · [[Skills]] · [[Items and Gear]] · [[Multiplayer Co-op]]

## Sources

- https://en.wikipedia.org/wiki/Hollow_Knight
- https://www.dualshockers.com/hollow-knight-design-choices-that-made-it-a-modern-metroidvania-classic/
- https://hollowknight.fandom.com/wiki/Hollow_Knight_(game)
- https://www.gamedeveloper.com/design/how-the-i-hollow-knight-i-devs-mapped-out-their-metroidvania-
- https://www.pcgamer.com/gaming-industry/hollow-knights-creators-didnt-want-to-be-constrained-by-the-metroidvania-label-but-they-accidentally-set-a-standard-that-every-game-since-even-silksong-has-to-reckon-with/
