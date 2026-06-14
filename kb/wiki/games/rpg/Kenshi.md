---
type: game
tags: [game-study, sandbox, rpg, open-world, skill-by-doing, faction-system, squad-management, lo-fi-games, emergent-narrative]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Kenshi_(video_game)
  - https://lofigames.com/about-kenshi/
  - https://store.steampowered.com/app/233860/Kenshi/
---
# Kenshi

Open-world sandbox RPG (2018, Lo-Fi Games) — a solo-developed "sword-punk" survival-RPG set in a post-apocalyptic wasteland, where the player begins as nobody in particular, builds a squad through skill-by-doing progression, navigates reactive faction politics, and may end up running an empire or dying forgotten in the desert.

## Design

- **Skill-by-doing, no level-scaling.** All skills improve through use: fight to raise combat, steal to raise thievery, build to raise construction. Crucially, the world does not scale — early-game bandits remain dangerous forever, forcing genuine strategic avoidance and squad-building rather than outleveling content. The design philosophy is explicit: "You are not the chosen one. You're not great and powerful... unless you work for it."
- **Emergent narrative through faction reactivity.** Significant NPC deaths (warlords, faction leaders) trigger cascading world changes: new locations spawn, territories shift, power vacuums open. The player's choices rewrite the map over time without scripted story events. This is narrative-as-emergent-consequence, not authored branching.
- **Squad-based persistence with permanent stakes.** Characters can lose limbs permanently, requiring prosthetic replacements from in-world traders. Unconscious characters can be enslaved, ransomed, or eaten. Party members captured mid-mission must be rescued or written off. The medical system (characters limp, crawl, bleed out) makes each combat encounter feel consequential at the individual-character level.
- **Multi-scale player goals.** The game supports radically different playstyles within the same systems: lone ronin surviving by wit, merchant guild building trading networks, warlord conquering territory, escaped slave seeking revenge. No single "main quest" — the player defines what winning looks like.
- **No experience points, no quests, no hand-holding.** Kenshi is hostile to tutorial conventions. The first hours are brutal by design; creator Chris Hunt described himself as "the player's enemy." This philosophy produces extremely high early drop-off rates alongside the game's passionate long-term community.

## Implementation

- **OGRE engine**, primarily developed by a single person (Chris Hunt) over approximately 12 years, transitioning from part-time (while working as a security guard) to full-time development after early Steam Early Access success. Full release December 6, 2018; 3 million copies sold by May 2026.
- The solo-development approach meant systems were built opportunistically — faction reactivity and injury persistence were implemented because Hunt found them personally compelling, not because a design committee signed off. This produced a game with unusual design coherence and unusual design roughness simultaneously.
- The 870 km² world map runs as a persistent simulation: factions patrol, trade, and war independently of whether the player is present. This ambient world-state simulation is computationally expensive and is the primary reason Kenshi requires substantial PC hardware for a visually modest game.

## Why it matters

Kenshi is the strongest modern proof that **skill-by-doing without level-scaling creates genuine player investment**: when the world stays dangerous, growth feels earned rather than inevitable. The faction reactivity model — where NPC deaths reshape the map — is an existence proof that emergent world narrative can replace authored story for players who engage with it. As a solo-dev commercial success (3 million copies), it also challenges assumptions about the team size required to ship a deeply systemic game.

## Relevance to Wayfinder

- **[[Trades and Leveling]]:** Kenshi's skill-by-doing model (abilities improve through use, no XP bars) is the design ancestor of Wayfinder's "cozy skilling as the spine" identity. The key question Kenshi poses: if Wayfinder's Trades improve through practice rather than quest completion, does that feel rewarding or grindy at cozy pacing?
- **[[Dungeon Generation]]:** Kenshi's faction-territory logic (regions belong to factions with internal logic) maps onto Wayfinder's crypt biome design — each dungeon wing could feel like a contested territory with its own inhabitant logic rather than a neutral room set.
- **[[Balance Philosophy]]:** No level-scaling is a radical commitment that Wayfinder won't copy wholesale, but the underlying principle — "let the world stay dangerous so growth feels real" — is applicable to how [[Affixes]] should scale threat rather than auto-adjusting enemy health.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Deus Ex]] · [[Tyranny]] · [[The Elder Scrolls V Skyrim]]
- Wayfinder: [[Trades and Leveling]] · [[Dungeon Generation]] · [[Balance Philosophy]] · [[Items and Gear]]
- Siblings: [[Tyranny]] · [[Disco Elysium]] · [[Divinity Original Sin 2]]

## Sources

- https://en.wikipedia.org/wiki/Kenshi_(video_game)
- https://lofigames.com/about-kenshi/
- https://store.steampowered.com/app/233860/Kenshi/
- https://sandboxgamesdb.com/games/kenshi/
