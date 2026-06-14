---
type: game
tags: [game-study, survival, crafting, jungle, health-systems, co-op, sanity, realism]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Green_Hell_(video_game)
  - https://steamcommunity.com/sharedfiles/filedetails/?id=3256423835
  - https://nerdschalk.com/is-green-hell-multiplayer/
  - raw/games/survival-3.md
---
# Green Hell

A hyper-realistic first-person jungle-survival game (2019, Creepy Jar) in which players manage not just hunger and thirst but a four-axis biological state — nutrition macros, psyche, body integrity, and sleep — in an Amazon rainforest that is actively trying to kill them.

## Design

- **Four-axis survival model.** Most survival games track food and health. Green Hell layers in four distinct meters: caloric nutrition (broken into carbohydrates, fat, protein, hydration, tracked via in-game smartwatch), psyche/sanity (drops through witnessing death, darkness, or eating wrong food; triggers hallucinations and voices), body integrity (individual wounds, parasites, and infections per limb shown on a first-person body map), and sleep. Each axis degrades independently and feeds back into the others — an infected leg drains sanity; low sanity impairs decision-making. This creates compounding emergencies rather than a single health bar to watch.
- **Body inspection mechanic.** Players must physically look down at their own hands and arms to spot parasites, leeches, or infected wounds. Wound care is procedural: extract the parasite, disinfect with ash or alcohol tincture, apply a leaf bandage. Maggot therapy is a real treatment option for infected wounds. This first-person embodiment of consequence is the standout design gesture — the body itself is the UI.
- **Notebook-based crafting discovery.** Recipes are not handed to players; they appear in Jake's notebook as he attempts combinations. Drag-and-drop items in the backpack interface and the recipe either works or fails, gradually filling the notebook. The system favors material logic (stick + stone + rope = axe) over arbitrary number lookup.
- **Narrative survival.** Unlike pure sandbox survival games, Green Hell has a story mode: Jake searches for his missing wife Mia through Amazonian territory, which grounds the survival mechanics in an emotional context. Co-op story mode (added v1.6.0) allows up to four players to experience the narrative together, a relatively rare feature in survival games.
- **Co-op sanity coupling.** In multiplayer, each player death inflicts −35 sanity on surviving teammates. This mechanical coupling turns individual mistakes into shared psychological pressure — dying recklessly punishes the group.

## Implementation

- **Engine:** Unity (PC and all console ports).
- **Co-op:** Up to 4 players; listen-server model; no PvP; both story and sandbox survival modes are co-op-capable as of v1.6.0. Community mods extend to 8 players.
- **World:** Fixed (not procedurally generated) Amazon rainforest map; hand-authored biome areas (bamboo groves, swamps, cave systems, beaches). No random seed — consistency enables authored narrative pacing.
- **Sales:** 1 million copies by June 2020; 6 million by June 2024. Metacritic 78–84/100 across platforms.

## Why it matters

Green Hell demonstrated that survival-game health systems can be a storytelling medium, not just a punishment loop. The body-as-interface design — looking down at your own limbs for wounds, choosing between maggot therapy and starvation — generates genuine dread without scripted horror. Its co-op sanity coupling is a rare example of a mechanical system that enforces social responsibility: you cannot play recklessly without making your teammates suffer psychologically. For an early-access indie, 6 million sales across four years proves the audience for detailed simulation over streamlined survival exists.

## Relevance to Wayfinder

- **Multi-axis health** suggests Wayfinder's [[Items and Gear]] (potions, food, bandages) could each address a different deficit — nutrition, stamina, morale — rather than collapsing into a single HP bar, making [[Crafting]] preparation feel medically purposeful rather than arbitrary.
- **Notebook discovery** is a clean template for Wayfinder's recipe-reveal design in [[Crafting]]: gating recipes behind attempted combinations or exploration discovery rather than presenting a full menu at the start.
- The **co-op sanity coupling** is a design pattern worth considering for Wayfinder's [[Multiplayer Co-op]]: shared consequences that make individual decisions matter to the group without requiring PvP.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[Gathering]] · [[Crafting]] · [[Items and Gear]] · [[Multiplayer Co-op]]
- [[Valheim]] · [[The Forest]] · [[Rust]] · [[Subnautica]]

## Sources

- https://en.wikipedia.org/wiki/Green_Hell_(video_game)
- https://steamcommunity.com/sharedfiles/filedetails/?id=3256423835
- https://nerdschalk.com/is-green-hell-multiplayer/
- raw/games/survival-3.md
