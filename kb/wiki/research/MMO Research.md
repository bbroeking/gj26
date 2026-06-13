---
type: overview
tags: [mmo-research, hub, external-research]
status: maintained
updated: 2026-06-13
sources: ["kb/raw/mmo/"]
---

# MMO Research

A research cluster on how MMOs and large multiplayer games are **designed and
implemented** — built to inform [[Overview|Wayfinder's]] own systems
([[Trades and Leveling]], [[Multiplayer Co-op]], [[Economy]], [[Combat]],
[[Chart Loop]]). External web research; raw provenance (facts + source URLs)
lives in `../../raw/mmo/`, digested in [[mmo-research]]. The synthesis that maps
it all back to Wayfinder is **[[MMO Lessons for Wayfinder]]** — start there if
you want the "so what."

## Game deep-dives
- [[World of Warcraft]] — classes/talents, the 400 ms spell-batch tick, sharding/layering/phasing, Mythic+ and the Great Vault, the Lua addon sandbox, the daily-quest burnout arc.
- [[RuneScape]] — the 23-skill model and 1–99 XP curve, the defining **0.6 s deterministic tick** (and tick manipulation), the Grand Exchange, Ironman, OSRS vs RS3.
- [[EVE Online]] — the single-shard universe, **Time Dilation**, StacklessIO/CarbonIO, the player-run economy with a staff economist, passive offline skill training.
- [[Final Fantasy XIV]] — the 1.0 → A Realm Reborn rebuild, one-character-all-jobs, the Duty Finder, data-center travel, its tick/netcode reputation.
- [[MMO Survey]] — breadth pass: Ultima Online, EverQuest, Guild Wars 2, Lineage II, Diablo/Path of Exile, Albion, Project Gorgon.

## Cross-cutting implementation
- [[MMO Server Architecture]] — authoritative servers; shard/layer/phase/CRZ/megaserver taxonomy; interest management (AoI); zone hand-off; persistence; scaling.
- [[MMO Netcode and Tick Systems]] — tick rates; client prediction, reconciliation, interpolation, lag compensation; snapshot/delta/event replication; reliable vs unreliable transport; listen-server anti-cheat.

## Cross-cutting design
- [[MMO Economy and Itemization]] — faucets & sinks, mudflation, marketplaces (GE vs AH vs EVE), binding, RMT, loot/affix systems, the D3 auction-house disaster.
- [[MMO Progression Systems]] — XP curves, class vs skill-based, vertical vs horizontal, talent trees, the endgame treadmill, retention loops and burnout.
- [[MMO Social and Endgame]] — the holy trinity, guilds and Dunbar limits, matchmaking vs community, raids/lockouts, world bosses, what scales down to 2–4 players.

## Synthesis
- **[[MMO Lessons for Wayfinder]]** — borrow / adapt / avoid, mapped to each Wayfinder system.

## See also
- [[Design Influences]] — the genre lineage already baked into Wayfinder's design
- [[Overview]] · [[index]]
