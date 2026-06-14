---
type: game
tags: [game-study, arpg, loot, affixes, itemization, crafting, sockets, economy]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Diablo_II
  - https://en.wikipedia.org/wiki/Diablo_II:_Lord_of_Destruction
  - https://maxroll.gg/d2/items/runes
  - https://diablo-archive.fandom.com/wiki/Rune_Words_(Diablo_II)
  - https://diablo.fandom.com/wiki/Prefix_(Diablo_II)
  - https://diablo.fandom.com/wiki/Suffix_(Diablo_II)
---
# Diablo II

Action-RPG released in 2000 by Blizzard North that invented the randomized-affix loot loop and socket/rune system that defines the genre to this day.

## Design

**Core loop.** Kill monsters → collect randomized gear → equip or trade → push deeper difficulties (Normal → Nightmare → Hell). Each difficulty pass on the same acts creates a steepening power curve, requiring better gear to survive. The reward for completing Hell was the chase for the rarest drops, not a new story.

**Itemization tiers.** Items exist in a strict quality hierarchy: Normal, Magic (1–2 affixes), Rare (3–6 affixes), Set (fixed bonuses rewarding collection), and Unique (fixed gold-text affixes, the "chase" tier). This five-tier structure is still the industry template.

**Affix system.** Magic items roll a prefix, a suffix, or both from weighted pools. Rare items roll 3–6 modifiers (never more than 3 of either prefix or suffix type). Each affix has an item-level requirement (ILVL/ALVL/MLVL), meaning the same affix pool produces dramatically different gear across the difficulty spectrum. Weighted frequency ensures the best affixes are genuinely rare. On rare items the name is randomly generated — two items with identical stats can have different names — hiding information and feeding the inspection loop.

**Socket system.** Eligible items have 1–6 sockets. Players insert Gems (elemental bonuses), Jewels (random mini-affixes), or Runes (stat bonuses per slot type). Sockets are permanent; removing contents requires a Hel Rune + Town Portal scroll, keeping experimentation accessible but never cost-free.

**Rune words (Lord of Destruction, 2001).** Inserting specific runes in a precise order into a socketed base item of the right type creates a Runeword — a fixed bonus set that far exceeds individual rune bonuses. The same rune sequence in the wrong order produces nothing. This creates: (a) a second chase layer beyond unique items, (b) a tiered rune economy where 33 runes stratify naturally into Low/Mid/High trading bands, and (c) a "base hunting" meta where the exact number of sockets in the right item type becomes valuable in its own right.

**Economy.** No in-game gold for high-value trades. Players barter items directly, with High Runes (e.g., Ber, Jah) serving as de facto reserve currency. Trading migrated to forums, fan sites, and later Diablo II's Battle.net trade channels — organic but uncontrolled.

## Implementation

Built on a proprietary engine by Blizzard North. Assets are isometric 2D sprites with pre-rendered environments. Multiplayer runs on Battle.net dedicated servers with character saves stored server-side (to reduce hacking). Development took approximately three years, including 18 months of significant crunch. Item generation is server-authoritative in online mode — a design choice that set the bar for anti-cheat in the genre.

The Lord of Destruction expansion (2001) added Act 5, Runes, Runewords, Jewels, Charms, and the two new character classes Druid and Assassin, dramatically extending endgame lifespan. Diablo II: Resurrected (2021, Vicarious Visions) updated the engine to 3D rendering while preserving the original server logic.

## Why it matters

Diablo II established the ARPG genre's foundational contract with players: meaningful randomness in every drop, a quality tier that communicates rarity at a glance, and layered crafting (sockets/runewords) that gives players agency over otherwise-random gear. The rune economy proved that a game can support a complex player-driven market without explicit auction house infrastructure. Twenty-five years on, every ARPG either inherits or explicitly reacts to D2's affix grammar.

## Relevance to Wayfinder

- **[[Affixes]] grammar.** D2's prefix/suffix pools with ILVL gating is the direct ancestor of Wayfinder's Affix system on [[Charts]]. The "good/bad twin" convention in Wayfinder's affixes mirrors D2's design of balancing power with drawback at the pool level.
- **[[Items and Gear]] tiers.** The five-tier quality hierarchy (Normal → Unique) maps directly to how [[Items and Gear]] in Wayfinder can signal rarity and drive the chase loop without UI clutter.
- **[[Economy]] — barter over gold.** D2's emergent rune-barter economy shows that durable trading currencies can arise organically from consumable item scarcity. Relevant to Wayfinder's ink/reagent [[Economy]] where chart materials could serve a dual crafting-and-trade role.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Design Influences]] · [[MMO Economy and Itemization]] · [[MMO Progression Systems]] · [[MMO Lessons for Wayfinder]]
- [[Diablo III]] · [[Diablo IV]] · [[Path of Exile]] · [[Path of Exile 2]]
- [[Affixes]] · [[Items and Gear]] · [[Chart Loop]] · [[Economy]]

## Sources

- https://en.wikipedia.org/wiki/Diablo_II
- https://en.wikipedia.org/wiki/Diablo_II:_Lord_of_Destruction
- https://maxroll.gg/d2/items/runes
- https://diablo-archive.fandom.com/wiki/Rune_Words_(Diablo_II)
- https://diablo.fandom.com/wiki/Prefix_(Diablo_II)
- https://diablo.fandom.com/wiki/Suffix_(Diablo_II)
