---
type: game
tags: [game-study, arpg, passive-tree, currency, crafting, economy, leagues, seasons, itemization]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Path_of_Exile
  - https://scrolldroll.com/the-economy-of-path-of-exile/
  - https://www.notebookcheck.net/Path-of-Exile-co-creator-online-RPGs-must-protect-their-economies-even-if-it-costs-developers-cash.1199206.0.html
  - https://game-wisdom.com/general/design-philosophy-behind-poe-2s-seasonal-model-resetting-everything-works
  - https://www.poe-vault.com/guides/path-of-exile-beginner-guide-welcome-to-wraeclast-fresh-exiles-start-here
---
# Path of Exile

Free-to-play ARPG released in 2013 by Grinding Gear Games (Auckland) — the genre's deepest expression of player-driven economy and build complexity, built as a spiritual successor to Diablo II.

## Design

**Passive skill tree.** A single, enormous network shared across all classes — 2,268 passive skill nodes as of recent patches. Each class starts at a different position on the tree. Players gain passive points through leveling (123 total via quests) and allocate them freely, pathing through the web. The tree contains: minor nodes (+10 to a stat, filler), notable passives (significant build modifiers), and Keystone passives (paradigm-shifting mechanics that often impose trade-offs — e.g., Acrobatics gives 30% dodge but halves armour). Classes have no locked-out sections, only starting positions — a Witch and Marauder can reach the same nodes given enough points. The tree is the dominant expression of build identity; the actual active skills come from socketed gems.

**Currency-as-crafting.** No gold. Instead, PoE's economy runs entirely on consumable **Orbs** — items with inherent crafting utility. Key orbs:
- **Orb of Alteration** — reroll magic item affixes
- **Chaos Orb** — reroll all affixes on a rare item; serves as baseline trading currency for mid-tier items
- **Exalted Orb** — add a new affix to a rare item; historically the premium trade standard (now largely superseded by Divine)
- **Divine Orb** — randomize the values (not types) of existing affixes; current premium trade currency
- **Orb of Fusing** — relink sockets on an item (PoE 1's 6-link mechanic)

The dual-purpose design creates natural economic sinks: every crafting attempt consumes orbs, removing currency from circulation. A player must decide whether to spend Chaos Orbs crafting or save them for trading — the risk-reward tension of crafting vs. buying sustains the market. Inflation is structurally suppressed because currency is consumed, not hoarded indefinitely without purpose.

**League mechanic.** Every ~3–4 months, GGG launches a new Challenge League. Each league introduces a fresh mechanic — thematically distinct, layered onto the existing game — and resets the economy to zero. Characters from ended leagues migrate to the permanent Standard league (no items lost). The design philosophy: the fresh start recreates the moment "when every player is at level one, the economy is genuinely open, and the new mechanic is genuinely unknown." This shared competitive reset is what Standard can never replicate. League mechanics that prove popular are integrated into the base game; underperformers disappear. The league cadence also packages each season's balance changes, preventing the meta from calcifying.

**Build gem system (PoE 1).** Active skills are gems socketed into gear. Support gems socketed into linked sockets modify those skills. The number and color of sockets (Strength/red, Dexterity/green, Intelligence/blue) must match the gem's attribute requirement and be physically linked to each other. A 6-linked item enables one active gem supported by five supports — the pinnacle of build power. Achieving a 6-link on a specific item type is itself a multi-week crafting project.

**Business model.** Cosmetic-only microtransactions, plus stash tab and character slot expansions. GGG designed microtransactions to be purely cosmetic from day one, building player trust that progression is never purchasable. Chris Wilson (co-creator) publicly argued that online RPGs must "protect their economies" and that pay-to-win would destroy the game's long-term integrity even if it generated short-term revenue.

## Implementation

Originally DirectX; Vulkan and macOS support added 2020. All non-encampment areas are procedurally generated. Instance-based multiplayer — each party gets its own dungeon instance, preventing interference from strangers. No shared open-world zones. Developed entirely by GGG Auckland, a studio that grew from hobby project to ~300+ employees on the back of PoE's success.

## Why it matters

Path of Exile is the definitive proof that extreme depth (2,000+ node tree, hundreds of currency types, dozens of league systems) can sustain a passionate community for over a decade on a free-to-play model. The currency-as-crafting invention is arguably the most influential economic design decision in ARPG history after D2's rune system: it eliminates gold inflation by making every currency unit a consumable with a purpose. The league mechanic is the purest "fresh start" model in ARPGs.

## Relevance to Wayfinder

- **[[Economy]] — currency as crafting material.** PoE proves that items which are simultaneously tradeable and consumable create self-regulating economies without inflation. Wayfinder's ink/reagent system for [[Chart Loop]] crafting should lean into this principle — inks spent crafting [[Charts]] become scarce, holding value.
- **[[Affixes]] and informed randomness.** PoE's orb system lets players target affix improvement (Chaos Orb = reroll all) or narrow adjustment (Divine Orb = adjust values). Wayfinder's Affix layer on Charts could offer analogous targeted and wholesale reroll options at different cost points.
- **[[Balance Philosophy]] — leagues as live balance.** PoE's league mechanic bundles balance changes with new content, framing nerfs as part of a fresh experience rather than punishment. Wayfinder's chart rotation could adopt this framing — each Chart set comes with tuned affix pools, not permanent changes to existing characters.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Economy and Itemization]] · [[MMO Progression Systems]] · [[MMO Lessons for Wayfinder]]
- [[Diablo II]] · [[Diablo III]] · [[Path of Exile 2]]
- [[Affixes]] · [[Items and Gear]] · [[Chart Loop]] · [[Economy]] · [[Skills]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Path_of_Exile
- https://scrolldroll.com/the-economy-of-path-of-exile/
- https://www.notebookcheck.net/Path-of-Exile-co-creator-online-RPGs-must-protect-their-economies-even-if-it-costs-developers-cash.1199206.0.html
- https://game-wisdom.com/general/design-philosophy-behind-poe-2s-seasonal-model-resetting-everything-works
- https://www.poe-vault.com/guides/path-of-exile-beginner-guide-welcome-to-wraeclast-fresh-exiles-start-here
