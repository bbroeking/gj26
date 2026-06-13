---
type: overview
tags: [overview, entry-point]
status: maintained
updated: 2026-06-13
sources: ["CLAUDE.md", "CONTEXT.md", "docs/WORLD_BIBLE.md", "docs/wyrd-roadmap.md", "docs/adr/0003-cozy-skilling-spine.md"]
---

# Overview

**Wayfinder** is a cozy fairytale dungeon-crawler built in **Godot 4.6**, set in
**[[Bramblewood]]**. Its heart is a trade called **[[Wayfinding]]**: you forage,
mix [[Inks]], and inscribe **[[Charts]]** — parameterized dungeon keys whose
[[Affixes]] shape every run. The spine is **cozy skilling**, not combat
([[Design Decisions|ADR 0003]]): *gather → craft → chart → delve*.

This is the front door to the Wayfinder knowledge base — an LLM-maintained wiki
over the game's design. Start here, then follow links or read [[index|the index]].
For where the build actually stands today, see **[[Current State]]**.

## The shape of the game

- **The loop.** [[Gathering]] feeds [[Crafting]], which yields the inks and gear
  you need to inscribe a chart at [[The Crafting Bench]]; you socket it at
  [[The Waystone]] and delve a [[Dungeon Generation|procedurally generated hollow]]
  shaped by its affixes. See **[[Chart Loop]]**.
- **Four trades to level 17** ([[Design Decisions|ADR 0006]]): [[Wayfinding]]
  (charting), [[Earthcraft]] (ore & forge), [[Wildcraft]] (herbs & brews), and
  [[Huntcraft]] (kills feed it). See **[[Trades and Leveling]]**.
- **Combat is one verb** ([[Design Decisions|ADR 0005]]): a 4-slot hotbar drawn
  from a pool of nine [[Skills]], per-kind [[Enemies]], and a trophy chain of
  [[Bosses]] leading to the Summit. See **[[Combat]]**.
- **Invite-your-friends co-op:** a host-authoritative listen-server; the party
  crosses into the same seed. See **[[Multiplayer Co-op]]**.

## How this wiki is organized

| Folder | What's in it |
|---|---|
| `world/` | [[Bramblewood]], [[World Lore]], [[Voice and Tone]] — setting & canon |
| `systems/` | the loops & machinery ([[Chart Loop]], [[Combat]], [[Crafting]], [[UI and HUD]], [[Camera and Game Feel]], [[Multiplayer Co-op]]…) |
| `entities/` | concrete game things (the trades, [[Charts]], [[Affixes]], [[Inks]], [[Skills]], [[Bosses]], [[Items and Gear]], [[NPCs]]…) |
| `concepts/` | [[Design Influences]], [[Balance Philosophy]], [[Design Archive]] |
| `decisions/` | [[Design Decisions]] — the ADR digest |
| `pipeline/` | how art/assets/code get made ([[Godot Pipeline]], [[Blender Pipeline]], [[Asset Pipeline]], [[Concept Art Prompts]]…) |
| `sources/` | per-cluster digests of the raw docs each page draws from |

This wiki is the synthesized map; the immutable per-feature contracts live in
`../docs/specs/`, and the canon lives in `../docs/WORLD_BIBLE.md`. When a doc
disagrees with the `../wyrd/` code, the **code wins** for "what the game does
today" — such contradictions are flagged on the pages.

## See also
- [[Current State]] — where the build stands and what's queued
- [[Development History]] — the three.js → Godot arc and the spec timeline
- [[Chart Loop]] — the single most important system page
