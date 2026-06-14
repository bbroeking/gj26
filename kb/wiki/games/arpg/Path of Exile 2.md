---
type: game
tags: [game-study, arpg, campaign, gem-socketing, passive-tree, endgame, early-access, accessibility]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Path_of_Exile_2
  - https://www.mmojugg.com/news/path-of-exile-2-skill-gem-changes-and-impact.html
  - https://mmonster.co/blog/path-of-exile-2-overview
  - https://game-wisdom.com/general/design-philosophy-behind-poe-2s-seasonal-model-resetting-everything-works
  - https://pathofexile.fandom.com/wiki/Path_of_Exile_2
---
# Path of Exile 2

ARPG in Early Access since December 6, 2024, by Grinding Gear Games — a full sequel that redesigns the gem-socketing system for accessibility, overhauls the campaign, and doubles down on skill diversity and challenging boss encounters while retaining PoE 1's deep economy.

## Design

**Separate game, not an expansion.** Originally planned as a seven-act story campaign alongside PoE 1, Path of Exile 2 became a separate title. It ships with six acts (three available at Early Access launch); PoE 1 continues as a live game on a parallel track. Both games share the same cosmetic library and microtransaction purchases.

**Campaign redesign.** The new six-act campaign is structured to be a more complete, cinematic narrative experience — a deliberate response to criticism that PoE 1's campaign was a repeated chore. Acts are geographically distinct and not recycled across difficulty passes. The early access campaign (Acts 1–3) spans roughly 30–40 hours of first-playthrough content.

**Gem socketing overhaul — the headline change.** In PoE 1, support gems were placed in linked sockets on gear (matching colors required). Finding a 6-linked item with the right colors was itself a weeks-long crafting project. PoE 2 inverts this:
- Sockets are now on the **skill gem itself**, not the gear. An active skill gem starts with 3 support gem sockets and expands to 6 as the player levels the gem.
- Gear still has sockets, but these accept active skill gems only; links between gear sockets are gone.
- Socket **colors are eliminated entirely** — no attribute color matching required.
- Result: every character effectively starts with a 3-link (expanding to 6-link over time) without hunting specific gear. The barrier to building a functional character is dramatically lowered.

**Passive tree.** Expanded to approximately 2,000 nodes. Dual specialization allows players to invest in two separate endgame paths on the same character without wiping all points. This partially replaces the full respec cost that was a friction point in PoE 1.

**New classes and resources.** Twelve classes at full release (six at Early Access: Warrior, Ranger, Sorceress, Monk, Mercenary, Witch); Druid and Huntress added in subsequent patches. **Spirit** replaces Mana Reservation — a dedicated resource pool for persistent aura-type abilities, removing the PoE 1 problem of mana reservation competing with active skill mana costs.

**Combat redesign.** A **dodge roll** (cooldown-based) is a universal movement tool, bringing PoE 2 closer to soulslike feel. Boss encounters are designed around precise timing and reading telegraph animations rather than outscaling bosses with raw stat investment. Monsters hit harder; sustain is more deliberate.

**Weapons and items.** New weapon types: spears, crossbows, flails. Supplementary item slots: focuses, traps, redesigned scepters. 240 active skill gems and 200 support gems vs. PoE 1's smaller set.

**Economy and leagues.** PoE 2 retains the orb-based currency-as-crafting model (see [[Path of Exile]]). The seasonal league model continues — each league resets the economy and introduces a fresh mechanic. The seasonal philosophy (fresh start as shared competitive moment) is inherited wholesale.

## Implementation

Rebuilt engine featuring improved lighting, physically-based rendering, and higher-fidelity assets than PoE 1. Vulkan/DirectX 12. Cross-platform: PC, PS5, Xbox Series X|S. GGG cited the engine rebuild as a primary reason the game required years of additional development beyond original estimates. Early Access launched December 6, 2024; full release targeted for 2025–2026. During Early Access, GGG collected player feedback rapidly, shipping major patches (0.2.0, 0.4.0) that restructured endgame content and passive skill point distribution.

## Why it matters

PoE 2's gem socketing overhaul is a textbook example of reducing friction on a deep system without removing depth. The design insight: the complexity players valued was in choosing which support gems to use, not in hunting for a correctly-colored 6-link base item. Separating "item hunt" from "build expression" solves an onboarding problem that kept PoE 1 inaccessible to new players. The dual-specialization passive tree similarly preserves build depth while reducing the punishment for experimentation.

The dodge roll and skill-diverse combat signal a genre shift: post-Elden Ring, even deep ARPGs must offer satisfying moment-to-moment combat, not just number escalation.

## Relevance to Wayfinder

- **[[Skills]] — gems on skills not gear.** Wayfinder's hotbar Skill system could adopt the same decoupling: abilities level independently and gain modifiers through use or crafting, not through item-hunt luck. This keeps [[Items and Gear]] focused on stats and [[Affixes]] rather than build-enabling socket counts.
- **[[Chart Loop]] accessibility.** PoE 2's 3-link-by-default model shows that a genre with deep build systems can front-load a functional experience. Wayfinder's Chart system should similarly let a new player run a basic chart on day one, with affix complexity unlocked progressively rather than gated behind item hunting.
- **[[Combat]] — dodge and timing.** The soulslike dodge signal in PoE 2 aligns with Wayfinder's FATE-camera single-verb combat model — precise, readable bosses that reward attention over stat-checking are the design direction to hold.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Progression Systems]] · [[MMO Lessons for Wayfinder]]
- [[Path of Exile]] · [[Diablo II]] · [[Diablo III]] · [[Diablo IV]]
- [[Skills]] · [[Chart Loop]] · [[Affixes]] · [[Items and Gear]] · [[Combat]] · [[Economy]] · [[Balance Philosophy]]

## Sources

- https://en.wikipedia.org/wiki/Path_of_Exile_2
- https://www.mmojugg.com/news/path-of-exile-2-skill-gem-changes-and-impact.html
- https://mmonster.co/blog/path-of-exile-2-overview
- https://game-wisdom.com/general/design-philosophy-behind-poe-2s-seasonal-model-resetting-everything-works
- https://pathofexile.fandom.com/wiki/Path_of_Exile_2
