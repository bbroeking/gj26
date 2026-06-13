---
type: source
tags: [mmo-research, source-digest, external-research]
status: maintained
updated: 2026-06-13
sources: ["kb/raw/mmo/"]
---

# Source Digest — MMO Research

Provenance for the [[MMO Research]] cluster. Unlike the rest of this wiki (whose
raw sources are the repo's own docs), these pages were compiled from **external
web research** — official wikis, dev blogs, GDC talks, and engineering writeups.
The extracted facts and the source URLs are preserved in `../../raw/mmo/`; each
research page also lists its URLs in its own `## Sources` section.

## Raw provenance files → pages fed

| Raw notes (`raw/mmo/`) | Wiki page(s) | What it covers |
|---|---|---|
| `world-of-warcraft.md` (25 URLs) | [[World of Warcraft]] | talents, 400ms spell batch, sharding/layering/phasing, Mythic+, Great Vault, Lua API, realm infra |
| `runescape.md` (16 URLs) | [[RuneScape]] | 23 skills, XP formula, 0.6s tick + tick manipulation, Grand Exchange, Ironman, NXT/RuneScript |
| `eve-ffxiv.md` (~24 URLs) | [[EVE Online]], [[Final Fantasy XIV]] | TiDi/single-shard/StacklessIO; ARR rebuild, jobs, Duty Finder, tick/netcode |
| `survey.md` (20+ URLs) | [[MMO Survey]] | UO, EverQuest, GW2, Lineage II, Diablo/PoE, Albion, Project Gorgon |
| `architecture-netcode.md` (17 URLs) | [[MMO Server Architecture]], [[MMO Netcode and Tick Systems]] | shard/layer/phase/megaserver, AoI, prediction/reconciliation/interpolation/lag-comp, snapshots |
| `economy-progression.md` (~18 URLs) | [[MMO Economy and Itemization]], [[MMO Progression Systems]] | faucets/sinks, GE vs AH, binding, RMT, XP curves, level squish, retention/burnout |
| `social-endgame.md` (14 URLs) | [[MMO Social and Endgame]] | trinity, Dunbar limits, matchmaking vs community, raids/lockouts, friendship retention |

The orchestrator-written synthesis pages — [[MMO Research]] (hub) and
[[MMO Lessons for Wayfinder]] (borrow/adapt/avoid) — draw from all of the above.

## Reliability notes
- Sources are weighted toward official wikis (Warcraft Wiki, OSRS Wiki), studio
  dev blogs (CCP, Blizzard, Jagex), GDC talks, and well-known netcode references
  (Gambetta, Fiedler/Gaffer On Games, Valve). Where sources conflicted or a figure
  was inferred, the pages flag it; the `raw/mmo/architecture-netcode.md` file keeps
  an explicit uncertainty register.
- Numbers tied to live games (sub counts, tick windows, tax rates) drift with
  patches — treat them as "as researched 2026-06-13," not eternal.

## See also
- [[MMO Research]] · [[MMO Lessons for Wayfinder]]
