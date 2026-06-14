---
type: game
tags: [game-study, roguelike, dice, party-combat, procgen, indie, turn-based, tactics]
status: draft
updated: 2026-06-14
sources:
  - https://tann.itch.io/slice-dice
  - https://automaton-media.com/en/news/slice-dice-strategic-monster-battling-roguelike-with-tons-of-variety/
  - https://www.resetera.com/threads/slice-dice-coming-to-steam-and-ios-on-march-20th-addictive-turn-based-dice-throwing-roguelike-demo-on-itch-io-for-pc-mac-android.824907/
  - https://rpgcodex.net/forums/threads/slice-dice-dice-oriented-party-combat-roguelike.145894/
---
# Slice and Dice

A solo-developed dice-tactics roguelike (tann, itch.io/Steam/iOS) in which a party of five heroes fights through 20 procedurally staged battles, with every action — attack, heal, shield, spell — determined by the dice faces on each hero's custom die.

## Design

Slice and Dice was made by a solo developer using the alias "tann," built with libGDX, and released in iterated versions: v2.0 shipped October 2, 2022; v3.0 launched on Steam and iOS March 20, 2024. The itch.io version is priced at $18 (desktop + Android) with a free demo; it holds a 4.9/5 star rating across 756 reviews as of mid-2025 with active updates through at least May 2025.

**Dice as character sheets.** Each of the five heroes in a party has a unique six-faced die; each face represents an action (damage, block, heal, special ability). The die's face composition is the character's stat sheet, kit, and personality in one object. Heroes are chosen or drafted at the start of the run; different classes produce radically different face distributions.

**Combat flow.** Monsters roll first and reveal their intentions; the player then rolls all five hero dice simultaneously. The player can lock ("align") desired faces and re-roll the rest a limited number of times. Knowing what the enemy will do before committing hero rolls creates tactical interplay: if a monster is charging a heavy hit, does the player fish for a shield face on a tank, or burn the reroll to get a heal on the cleric? The telegraphed-monster-intent + selective-reroll system generates more decision depth than a pure random-roll would, without removing variance.

**Party composition as meta-decision.** The run's primary strategic layer is which five heroes to assemble. Classes range from warriors (high damage faces) to clerics (heal-heavy) to wizards (AoE spell faces) to exotic classes with unique face types. A cohesive party creates synergies — a bard who buffs adjacent dice, for example, rewards specific adjacency layouts.

**Shop and upgrade system.** Between battles, the player visits item shops and upgrade events. Items modify hero dice (adding faces, improving existing ones) or provide passive party-wide bonuses. This upgrades the character sheet mid-run, compounding synergies built in draft. No persistent meta-progression between runs beyond unlocking harder difficulty modes (Nightmare mode), keeping each run a clean slate.

**Procgen structure.** Twenty battles are arranged with branching paths that allow mild route selection — different enemy compositions and event types appear on different branches. Boss encounters appear at intervals. The dungeon is light on spatial generation; the procgen manifests in enemy roster variation, event selection, and item pool shuffling rather than map topology.

## Implementation

Built with libGDX (Java game framework), available on Windows, macOS, Android, iOS, and Steam. Session length averages about 30 minutes per run, making it highly replayable in short windows. No external assets or extensive audio — deliberately minimal presentation emphasizes the mechanical clarity of the dice-face system. The itch.io free demo version retains core mechanics with a reduced hero roster.

## Why it matters

Slice and Dice demonstrates that **the die is a design atom**: encoding a character's complete action vocabulary onto six faces produces an immediately readable, highly composable system. The selective-reroll-after-reveal pattern turns what could be pure gambling into a genuine decision space. For small teams building encounter-based combat, this is a reference for how to achieve high variety from a minimal system — tann shipped it solo.

## Relevance to Wayfinder

1. **[[Combat]]:** The telegraphed-enemy-intent + player-roll-decision structure is a strong model for Wayfinder's one-verb combat — even without dice, showing enemies' next action before the player commits to theirs creates the same read-and-respond depth without complexity inflation.
2. **[[Affixes]]:** Slice and Dice's item upgrades that modify specific die faces are a micro-level analog to Wayfinder affixes — targeted, readable modifications to a single interaction slot rather than global stat bumps.
3. **[[Dungeon Generation]]:** The light branching-path procgen (choose your encounter sequence) is a reference for how Wayfinder's chart dungeon could offer route agency without requiring full spatial map generation.

## See also

- [[Game Index]] · [[Game Studies]] · [[Design Influences]]
- [[Slay the Spire]] — run-based encounter-by-encounter cousin; [[Hades]] — roguelite combat reference
- [[Combat]] · [[Affixes]] · [[Dungeon Generation]]

## Sources

- https://tann.itch.io/slice-dice
- https://automaton-media.com/en/news/slice-dice-strategic-monster-battling-roguelike-with-tons-of-variety/
- https://www.resetera.com/threads/slice-dice-coming-to-steam-and-ios-on-march-20th-addictive-turn-based-dice-throwing-roguelike-demo-on-itch-io-for-pc-mac-android.824907/
- https://rpgcodex.net/forums/threads/slice-dice-dice-oriented-party-combat-roguelike.145894/
