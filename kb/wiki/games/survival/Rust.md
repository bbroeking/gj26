---
type: game
tags: [game-study, survival, pvp, crafting, server-wipe, procedural-generation, open-world, unity]
status: draft
updated: 2026-06-14
sources:
  - https://en.wikipedia.org/wiki/Rust_(video_game)
  - https://facepunch.com/games/rust
  - https://www.pcgamer.com/games/survival-crafting/rust-doubles-down-on-its-controversial-meta-changes-by-wiping-everyones-crafting-blueprints-to-bring-back-that-sense-of-discovery-and-it-might-become-a-regular-thing/
  - https://www.mexc.co/news/985648
---
# Rust

Hardcore multiplayer survival sandbox (2018, Facepunch Studios) in which players spawn naked on a procedurally generated island, race to craft tools and build bases, and compete or cooperate on servers that wipe all progress on a monthly schedule.

## Design

- **Radical player-driven world.** Facepunch's stated philosophy is "we give them the tools, they make the world" — no quest givers, no NPC economy, no narrative. All social structure (clans, alliances, trade, war) emerges from player interaction on shared servers supporting up to 1,000 players.
- **Blueprint progression via discovery.** Crafting is unlocked through blueprints found by researching scavenged items at a research table (consuming the item) or earned via Workbench-tier leveling. This creates a knowledge economy: knowing *how* to build something is as valuable as having the materials. Facepunch controversially wiped all player blueprints in 2025–2026 updates to "bring back the sense of discovery."
- **Forced wipes as a design pillar.** Monthly Force Wipes reset all bases and blueprints server-wide. Wipe day is consistently the game's peak concurrent player moment — players flood back knowing the field is level. This transforms what is normally a negative (losing progress) into a recurring content event.
- **Procedural map generation with monument seeding.** Maps are generated per-server using noise functions with deterministic monument placement (military bases, power plants, harbors). Monuments hold high-tier loot and radiation zones, creating contested PvP hotspots without hand-authored content updates.
- **Naked vulnerability as onboarding.** Every player starts with only a rock and torch, creating shared low-status entry that normalizes early cooperation and later betrayal. The extreme entry friction filters for players who tolerate emergent social risk.

## Implementation

- Built in **Unity** (migrated from a Garry's Mod Lua prototype). Facepunch engineered a custom server architecture handling 1,000 concurrent players per instance — a significant netcode challenge for a physics-simulated building game.
- Procedural generation seeds from a server-chosen integer; the same seed produces the same map, allowing server operators to repopulate a known layout after wipes.
- Building uses a socket-based snap system (foundations, walls, roofs, doorframes) with structural integrity checks — unsupported structures decay and collapse.
- The game runs on dedicated servers only; Facepunch operates official servers and enforces the monthly wipe schedule, while community servers can set custom wipe intervals.

## Why it matters

Rust codified the "server society" design pattern: a survival game where the most interesting content is other players rather than the environment. Its forced-wipe mechanic is arguably the most important design innovation in the live-service survival genre — it solves long-term player-count decay by manufacturing recurring fresh starts. Selling 9 million copies by 2019 (generating $142M, more than Garry's Mod) proved brutal-access survival had a massive commercial audience.

## Relevance to Wayfinder

- **Wipe as reset-and-return hook:** Chart runs in Wayfinder are structurally similar to a wipe — each run starts from a known baseline. Rust proves players will *happily* repeat content if the reset is framed as an event, not a punishment; this supports making [[Economy]] resets (market fluctuations, chart expiry) feel exciting rather than lossy.
- **Blueprint knowledge economy:** separating *knowing how to craft* from *having materials* is directly applicable to [[Crafting]] — Wayfinder could make rare affix recipes discoverable rather than automatically unlocked, giving experienced crafters a meaningful asymmetry over new players.
- **Procedural monument seeding:** spawning contested high-value nodes at predictable-but-distributed map locations (analogous to Rust's monuments) is a template for Wayfinder's [[Gathering]] hotspot design inside charted dens.

## See also

- [[Game Index]] · [[Game Studies]] · [[MMO Economy and Itemization]] · [[Design Influences]]
- Siblings: [[Valheim]] · [[Minecraft]] · [[The Forest]] · [[Grounded]]
- Wayfinder: [[Crafting]] · [[Economy]] · [[Gathering]] · [[Multiplayer Co-op]]

## Sources

- https://en.wikipedia.org/wiki/Rust_(video_game)
- https://facepunch.com/games/rust
- https://www.mexc.co/news/985648
- https://www.pcgamer.com/games/survival-crafting/rust-doubles-down-on-its-controversial-meta-changes-by-wiping-everyones-crafting-blueprints-to-bring-back-that-sense-of-discovery-and-it-might-become-a-regular-thing/
- https://www.pcgamer.com/games/survival-crafting/rust-developer-is-fed-up-with-survivors-cowering-in-their-homes-so-its-reworking-progression-to-get-players-back-out-of-their-bases/
