---
type: overview
tags: [synthesis, status, roadmap]
status: maintained
updated: 2026-06-13
sources: ["docs/wyrd-roadmap.md", "docs/wyrd-implementation-notes.md", "docs/specs/46-multiplayer-coop.md"]
---

# Current State

The synthesized "where are we" — the evolving thesis this wiki keeps current.
The authoritative running doc is `../docs/wyrd-roadmap.md`; this page is its
distilled, linked form. When they disagree, the roadmap and the `../wyrd/` code
win.

## Playable today (end to end, solo or co-op)

A complete demo slice runs: **tutorial → forage → mix ink → inscribe a
[[Charts|chart]] → delve a parameterized hollow → exit → completion XP → trophy
chain ([[Bosses|elites → Hedgemother → Boar → Wolf → Summit]]) → gold economy →
save/load.**

- **The loop is whole.** [[Chart Loop]], [[Gathering]], [[Crafting]],
  [[Dungeon Generation]], [[The Crafting Bench]] (sockets + live odds + on-bench
  mixing pot + recipe discovery), [[The Waystone]] (+ abandon stone so boss
  charts can't soft-lock).
- **Four [[Trades and Leveling|trades]] to the level-17 cap** with full unlock
  ladders: [[Wayfinding]] (6 perks 2→17), [[Earthcraft]] (copper→hedgesteel,
  forge ladder), [[Wildcraft]] (6 herb tiers, heal/buff brews), [[Huntcraft]]
  (kills feed it; Even Breath at 17).
- **Combat as one verb:** a 9-strong [[Skills]] pool, 4-slot loadout, per-kind
  [[Enemies]] with elites + affix modifiers, the boss trophy chain.
- **[[Multiplayer Co-op]]** — Phase A (town together) and Phase B (dungeon co-op:
  seed-identical enemies, host snapshots, guest casts, kill credit, per-player
  loot, party-wipe boss rules) shipped; two-process headless smoke tests green.
- **Quality gate:** four headless suites (~350 checks) must stay green
  (see [[Godot Pipeline]]).

## In flight

- **UI clarity overhaul (active).** The [[UI and HUD]] pages are being rebuilt
  worst-first — Satchel + the three craft stations first — to make each screen
  answer "where am I / what can I do / what happens if I do it." A HUD/window
  visual-dialect inconsistency (spec 41 cohesion pass) is still open.
- **UI reference round 2** — Midjourney prompts + ChatGPT mock picks, user-side.

## Queued (roadmap tail)

[[Multiplayer Co-op|Phase C]] polish (guest-visible arrows, boss telegraphs on
guests, reconnect grace, exit vote); buff HUD chip; discovery feel pass; a
balance pass on the 140/220 heals vs Summit damage (see [[Balance Philosophy]]);
skill-icon paint-over; fresh-save tutorial + boss-feel playtests.

## Known contradictions surfaced during ingest

The first compile flagged a consistent pattern: **much of `../docs/` is stale
three.js-prototype material** superseded by the Godot build (the prototype was
removed 2026-06-12). The notable live-vs-doc deltas:

- **Completion-XP formula:** design docs say `tier×30 + good×25 + bad×5`; shipped
  `charts.gd` uses `tier×75 + good×40 + bd×10`. Code wins. ([[Chart Loop]], [[Charts]])
- **Skill pool:** spec 30 describes 4 skills; code ships 9. ([[Skills]])
- **Affix/ink counts:** docs target ~25 affixes / 15 inks via a 3×3 grid; code
  ships 18 affixes (15 rollable + 3 boss-den) and 8 inks via a mixing pot.
  ([[Affixes]], [[Inks]])
- **Boss-den `req_carto` gates are dead data** — carried in `charts.gd`, never
  read at `socket_trophy`. ([[Wayfinding]])
- **Whole-doc supersessions:** `DESIGN_VISION.md`, `cartography-progression.md`,
  the `docs/skills/*` and `docs/design/*` trees, and three.js-era pipeline
  framing — all catalogued in [[Design Archive]].

## See also
- [[Overview]] · [[Development History]] · [[Design Archive]] · [[Design Decisions]]
