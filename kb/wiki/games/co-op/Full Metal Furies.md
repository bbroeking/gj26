---
type: game
tags: [game-study, co-op, brawler-rpg, role-specialization, barrier-system, gear-system, loot, 4-player, meta-puzzle]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Full_Metal_Furies
  - https://store.steampowered.com/app/416600/Full_Metal_Furies/
  - https://www.nintendolife.com/reviews/switch-eshop/full_metal_furies
  - https://www.pcgamer.com/rogue-legacy-devs-announce-full-metal-furies-a-four-player-co-op-brawler/
  - https://www.cellardoorgames.com/our-games/full-metal-furies
---
# Full Metal Furies

Co-op brawler-RPG (2018, Cellar Door Games) for up to 4 players in which four mechanically distinct Furies — tank, sniper, engineer, fighter — must cooperate to break color-coded enemy shields through a "barrier system" that hardwires interdependence into every combat encounter; it is the Rogue Legacy studio's attempt to modernize the 2D brawler with loot, skill trees, and co-op-mandatory design.

## Design

- **The barrier system — co-op encoded into combat.** Each Fury is assigned a color (Triss/blue, Erin/green, Meg/yellow, Alex/red). Enemies spawn with color-coded shields that can *only* be broken by the corresponding Fury. While the shield is up, the enemy is immune to all other players' damage. This is not a suggestion — it is a hard rule. The mechanic forces players to communicate which target each Fury should focus on and prevents any single player from soloing encounters above their color. In a full 4-player session, shield juggling across enemies becomes the central coordination puzzle of every fight.
- **Revival dependency.** Knocked-out characters can only be revived by teammates physically reaching them and holding a button — and the reviving character must often be the one whose color was needed to break the shield keeping the threat alive. This creates a recursive dependency: losing the key-color Fury locks the party into a crisis that only that Fury can resolve, generating high-stakes co-op pressure.
- **Four distinct roles.** Alex (melee combos and counters), Meg (ranged sniper with deployable mines), Triss (tank with shield bash), Erin (engineer with automated turret). The roles are not symmetric variants — their ranges, risk profiles, and positioning requirements are fundamentally different, making the party's spatial composition a live tactical variable.
- **Skill trees per character.** Each Fury has a personal skill tree, not a shared pool. This enables long-term build specialization (e.g., giving Triss a freezing shout, converting Alex's leap to a power dive) and encourages party members to discuss their builds, not just their in-session positions.
- **Modular gear system.** Each character equips four items (one per attack slot). New gear unlocks via mission completion and blueprint acquisition. Items have tradeoffs, not straight upgrades, which pushes build experimentation. Leveling individual gear pieces benefits the whole team — a shared-investment loop that aligns individual and group incentives.
- **Meta-puzzles overlaying combat.** The game layers cryptic environmental riddles onto the combat zones. Decoding these puzzles requires collective attention and discussion, adding an intellectual co-op layer above the brawler action. These puzzles are the most distinctive design element compared to peers in the genre.
- **Solo support via Pick 2 quick-switch.** Single players control two characters simultaneously, switching between them. This lets the co-op content be played solo at the cost of real-time multi-tasking rather than stripping the barrier system out for solo mode — an elegant accommodation.

## Implementation

- **Developer/Publisher:** Cellar Door Games (Rogue Legacy studio). Self-published.
- **Release:** January 17, 2018 (PC and Xbox One); November 6, 2018 (Nintendo Switch).
- **Session size:** 1–4 players (solo via Pick 2 switch, 2–4 players co-op).
- **Co-op modes:** Full couch and online co-op supported. Xbox Play Anywhere and cross-play between Xbox One and Windows 10. Steam (PC) and Xbox ecosystems are separate.
- **Online model:** Online co-op supported; no public documentation on server architecture or netcode. Community reports indicate standard peer-to-peer or Steam relay architecture. The game received "Very Positive" Steam reviews (90% of ~989 reviews) at time of research, suggesting the online implementation is functional if not technically distinguished.
- **Commercial outcome:** Metacritic 85/100 on PC, 75 on Xbox One and Switch. Despite critical praise, the game "failed to break even" — described by Cellar Door as "a pretty massive failure" commercially. The co-op design is regarded as technically strong; the title underperformed on discoverability and marketing.

## Why it matters

Full Metal Furies is the clearest extant example of a co-op brawler that uses a **mechanical barrier system** to make every player role *load-bearing* rather than additive. Most co-op action games allow any player to damage any enemy — Full Metal Furies makes each Fury uniquely necessary at every encounter. The commercial failure despite critical success is itself instructive: co-op design quality does not guarantee commercial viability, particularly for brawler-RPG hybrid genres that lack a clear genre anchor in players' mental models.

## Relevance to Wayfinder

- **Barrier system as role design template.** The color-coded shield mechanic is a transferable pattern: Wayfinder could apply an "affix-reactive" combat mechanic where certain dungeon enemies are only vulnerable to specific gear affix combinations, Trade skill interactions, or player-applied effects, forcing party members to communicate loadout coverage before a chart run. See [[Combat]] and [[Affixes]].
- **Gear-as-team-investment.** Full Metal Furies' gear leveling that "benefits the entire team" aligns with how Wayfinder's [[Crafting]] output could work in co-op: crafted gear or inscribed chart affixes that give the whole party a benefit, rewarding the crafter Trade's investment with party-wide value rather than only personal stats.
- **Commercial signal: discoverability over design.** Cellar Door's post-mortem ("pretty massive failure") on a critically-praised co-op game suggests that niche co-op titles compete hard on discoverability. Wayfinder's cozy-skilling identity and the Bramblewood world provide a clearer anchor than "co-op brawler-RPG" — the lesson is to lean into the identity that differentiates, not just the co-op feature.

## See also

- [[Game Index]] · [[Game Studies]]
- [[Multiplayer Co-op]] · [[Combat]] · [[Affixes]] · [[Crafting]]
- [[Design Influences]]
- [[Deep Rock Galactic]] · [[Helldivers 2]] · [[It Takes Two]]
- [[Barotrauma]]

## Sources

- https://en.wikipedia.org/wiki/Full_Metal_Furies
- https://store.steampowered.com/app/416600/Full_Metal_Furies/
- https://www.nintendolife.com/reviews/switch-eshop/full_metal_furies
- https://www.pcgamer.com/rogue-legacy-devs-announce-full-metal-furies-a-four-player-co-op-brawler/
- https://www.cellardoorgames.com/our-games/full-metal-furies
