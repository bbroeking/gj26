# Wayfinder KB — log

Append-only, chronological. Prefix: `## [YYYY-MM-DD] ingest|query|lint | <subject>`.
Greppable: `grep "^## \[" log.md | tail`.

## [2026-06-13] ingest | KB bootstrap — first full compile
- Scaffolded the LLM Wiki (`kb/`): schema in [`CLAUDE.md`](CLAUDE.md)/[`AGENTS.md`](AGENTS.md),
  pattern reference [`LLM-WIKI-PATTERN.md`](LLM-WIKI-PATTERN.md), registered as an
  Obsidian vault via `obsidian-cli`.
- Wave 1 (7 parallel agents): world & decisions, charting, trades & progression,
  combat/skills/enemies/bosses, items/nodes/NPCs, multiplayer & save, pipelines.
- Wave 2 (6 parallel agents): UI & HUD, camera & game feel, onboarding &
  development history, design influences & balance, design archive, art &
  content pipelines.
- Wrote [[Overview]], [[Current State]], `index.md`, this log.
- **57 pages** created (45 content + 12 source digests) from ~140 source docs.
- Flagged a consistent pattern: much of `../docs/` is stale three.js-prototype
  material superseded by the Godot build (catalogued in [[Design Archive]] and
  [[Current State]]). Notable code-wins-over-doc deltas: completion-XP formula,
  9 vs 4 skills, 18 affixes / 8 inks, dead `req_carto` gates.

## [2026-06-13] ingest | MMO Research — EVE Online + Final Fantasy XIV
- Created [[EVE Online]] at `wiki/research/EVE Online.md` via WebSearch+WebFetch of 13 primary sources
- Created [[Final Fantasy XIV]] at `wiki/research/Final Fantasy XIV.md` via WebSearch+WebFetch of 11 primary sources
- Created `raw/mmo/eve-ffxiv.md` with full fact provenance + source URLs for both games
- EVE covers: single-shard Tranquility cluster (SOL/Proxy/DB tiers, solar-system-per-core), StacklessIO → CarbonIO/BlueNet evolution, Time Dilation mechanics (10% floor, O(n²) load, B-R5RB battle stats), PLEX/ISK economy (CCP Lead Economist), passive real-time skill queue, full-loot PvP + emergent politics
- FFXIV covers: 1.0 failure + ARR rebuild (Yoshida's 4m50s diagnosis, 80% of changes unreachable without full rebuild), job system (one character all jobs, soul crystal swap), Duty Finder (cross-world matchmaking, role composition rules, Trust/NPC parties), data center travel (regions, restrictions, cross-DC PF gap), 0.3s positional tick + 3s actor tick + ability queue window, patch cadence (x.odd/x.even alternation, Savage unlock lag), Sprout/Mentor onboarding system
- Updated `index.md` MMO Research section with descriptions for both pages
- Key cross-links: [[MMO Server Architecture]], [[MMO Netcode and Tick Systems]], [[MMO Economy and Itemization]], [[MMO Progression Systems]], [[MMO Social and Endgame]], [[Design Influences]], [[Economy]], [[Multiplayer Co-op]], [[Trades and Leveling]], [[Combat]], [[Chart Loop]], [[Affixes]]

## [2026-06-13] ingest | MMO Research — RuneScape
- Created [[RuneScape]] at `wiki/research/RuneScape.md` via WebSearch+WebFetch of 16 primary sources
- Created `raw/mmo/runescape.md` with full fact provenance + source URLs
- Covers: 24-skill model + categories, XP formula + table (levels 1/50/70/85/92/99), 0.6s game tick
  mechanics + action queue types, tick manipulation (3-tick/1-tick/prayer flicking), Grand Exchange
  mechanics (slots, buy limits, 2% tax), Ironman 6 variants, OSRS vs RS3 divergence (EoC 2012),
  poll system (70% threshold, Oct 2022 change), world architecture (258 members + 54 F2P worlds,
  containerized VMs, global vs per-world state), NXT client client history (Java applet → C++11 2016),
  RuneScript scripting language, combat triangle + combat level formula
- Added MMO Research section to `index.md` with stub links for the full survey series
- Key cross-links: [[Trades and Leveling]], [[Economy]], [[Combat]], [[Multiplayer Co-op]], [[Gathering]]

## [2026-06-13] ingest | MMO Research — World of Warcraft
- Created [[World of Warcraft]] at `wiki/research/World of Warcraft.md` via WebSearch+WebFetch of 15+ primary sources (Warcraft Wiki, Blizzard dev blogs, GDC postmortem, Data Center Knowledge, Magey's Classic Wiki, BlizzardWatch)
- Created `raw/mmo/world-of-warcraft.md` with full bullet-fact provenance + 25 source URLs
- DESIGN: 13 expansions 2004–2026; 13 classes / 39 specs / holy trinity; talent tree oscillation (51-pt Vanilla → Cataclysm 41-pt pruning → MoP 18-choice grid → Dragonflight dual Class+Spec tree); GDC quest design post-mortem (Christmas Tree Effect, 511-char cap, progressive drop rate fix, hub-and-spoke breadcrumbs); daily-quest burnout arc → World Quests → semi-weekly reset; Mythic+ keystone/affix/timer loop (Legion 2016); Great Vault weekly-chest loot guarantee (Shadowlands); gear treadmill + borrowed power (Artifact/Azerite/Covenants); professions + Dragonflight quality/Crafting Orders revamp; WoW Token ($20→gold/game time, April 2015); garrison social-isolation lesson; peak 12M subs October 2010
- IMPLEMENTATION: realm infrastructure (700+ realms, 10 DCs, 75k CPU cores, 2009); sharding (patch 6.0.2 Oct 2014, density-based zone copies); layering (Classic launch, realm-wide sharding); phasing (story-driven, Party Sync); CRZ + Connected Realms (5.4 2013); 400ms spell-batch window (self-cast instant; cross-unit batched; pre-WoD 400ms → post-WoD 20ms → Classic 10ms); Lua addon API (266+ C_* namespaces, #hwevent gate prevents bot automation, Lua 5.0→5.1 TBC); lockout types (ID-based hard, loot-based soft, flexible boss-based); Mythic fixed-20 vs flexible 10-30 tier split
- Key cross-links: [[MMO Netcode and Tick Systems]], [[MMO Server Architecture]], [[MMO Progression Systems]], [[MMO Economy and Itemization]], [[MMO Social and Endgame]], [[Chart Loop]], [[Items and Gear]], [[Crafting]], [[Gathering]], [[Skills]], [[Bosses]], [[Combat]], [[Economy]], [[Multiplayer Co-op]]

## [2026-06-13] ingest | MMO Research — Breadth Survey (UO / EQ / GW2 / Lineage / PoE / Albion / Gorgon)
- Created [[MMO Survey]] at `wiki/research/MMO Survey.md` via WebSearch+WebFetch of 20+ primary sources
- Created `raw/mmo/survey.md` with full fact provenance + source URLs
- Covers eight titles: UO (shard model, faucet-drain economy, Trammel/Felucca PvP split, usage-based skills, Koster postmortems); EverQuest (zone-server architecture, holy trinity crystallisation, corpse-run death penalty as social glue, contested spawn camping); Guild Wars 2 (design manifesto, no-trinity cooperative PvE, dynamic events vs quest-givers, megaserver weighted load balancer, dynamic level downscaling formula); Lineage II (castle siege objectives + economic rewards, clan system, bot/RMT structural fragility, 1.38M account bans as of 2026); Diablo 2 (randomized prefix/suffix affix system, shared loot friction); Path of Exile (instanced areas, barter-orb economy + dual-use currency, 2268-node passive tree, seasonal league resets and controlled scarcity); Albion Online ("you are what you wear" classless design, full-loot risk stratification, player-driven economy); Project Gorgon (100+ skill freeform system, NPC favour as world-access gate, discovery-first design)
- Includes comparative table (8 games × launch / architecture / standout design idea)
- Key cross-links: [[Design Influences]], [[Items and Gear]], [[Affixes]], [[Chart Loop]], [[Economy]], [[Multiplayer Co-op]], [[Combat]], [[Trades and Leveling]], [[Dungeon Generation]], [[NPCs]], [[MMO Server Architecture]], [[MMO Economy and Itemization]], [[MMO Progression Systems]], [[MMO Social and Endgame]]

## [2026-06-13] ingest | MMO Research — Server Architecture and Netcode (cross-cutting)
- Created [[MMO Server Architecture]] at `wiki/research/MMO Server Architecture.md` via WebSearch+WebFetch of 17 sources
- Created [[MMO Netcode and Tick Systems]] at `wiki/research/MMO Netcode and Tick Systems.md` via WebSearch+WebFetch of 17 sources
- Created `raw/mmo/architecture-netcode.md` with full fact provenance + uncertainty register for all claims
- SERVER ARCHITECTURE covers: authoritative-server model (DB is not source of truth); login/world/zone tier separation; precise definitions of realm/shard/layering/phasing/CRZ/instance/megaserver with games using each; EVE Online single-shard deep-dive (SOL/Proxy blades, Stackless Python, TiDi 10% floor, Battle of B-R5RB 7,548 players, 250M DB transactions/day); GW2 megaserver weighted load balancer; AoI/interest management (fixed-cell grid, quadtree, pub/sub); zone hand-off protocol; DB persistence patterns (write-behind, checkpoint, CAS); scaling strategies; container/cloud trends
- NETCODE covers: server game loop anatomy; tick-rate comparison table (OSRS 0.6s → VALORANT 128 Hz); RuneScape's 600ms deterministic tick (client 20ms UI tick separate); WoW spell batching (400ms Vanilla → ~20ms Modern); CS2 sub-tick event timestamping; client-side prediction algorithm (sequence numbers, input buffer, reconciliation replay); entity interpolation mechanics (100ms display lag at 10Hz; Hermite/slerp); Valve lag compensation (1s history, rewind formula); snapshot vs delta vs events; reliable vs unreliable transport semantics; O(N²) bandwidth scaling and AoI as mitigation; listen-server anti-cheat limitations
- Updated `index.md` MMO Research section with full descriptions for both new pages
- Key cross-links: [[Multiplayer Co-op]], [[Save System]], [[Dungeon Generation]], [[Combat]], [[Enemies]], [[RuneScape]], [[World of Warcraft]], [[EVE Online]], [[Final Fantasy XIV]], [[MMO Research]], [[MMO Lessons for Wayfinder]]

## [2026-06-13] ingest | MMO Research — Social Structures and Endgame Design
- Created [[MMO Social and Endgame]] at `wiki/research/MMO Social and Endgame.md` via WebSearch+WebFetch of 14 sources
- Created `raw/mmo/social-endgame.md` with full fact provenance + source URLs
- Covers: holy trinity (origins, advantages, failure modes, trinity-less alternatives); guilds/clans as
  social glue (Dunbar's layers, friendship formation, Star Wars Galaxies cantina case study); matchmaking
  vs server community (LFD debate, convenience-community tradeoff); raid size evolution (40→10→8→6 players),
  difficulty tiers, weekly lockouts, world-first culture; GW2 dynamic events and FFXIV FATEs; PvP
  structures (battlegrounds, arenas, full-loot, EVE Online trust-as-gameplay); endgame loops (gear
  treadmill, Mythic+ keystone scaling, FFXIV tiered endgame, seasonal rotation); the social contract
  (friendship as primary retention, kind games norm-setting, Palia cozy MMO model)
- Includes "What Scales Down to 2–4 Player Co-op" mapping table and Relevance to Wayfinder section
- Key cross-links: [[Multiplayer Co-op]], [[Bosses]], [[Combat]], [[Chart Loop]], [[Affixes]], [[Design Influences]]

## [2026-06-13] ingest | MMO Research — Economy & Itemization + Progression Systems (cross-cutting)
- Created [[MMO Economy and Itemization]] at `wiki/research/MMO Economy and Itemization.md` via WebSearch+WebFetch of 15 sources
- Created [[MMO Progression Systems]] at `wiki/research/MMO Progression Systems.md` via WebSearch+WebFetch of 13 sources
- Created `raw/mmo/economy-progression.md` with full fact provenance + source URLs for both pages
- ECONOMY covers: faucet/sink theory (MIMO model, passive vs active sinks, GE tax, OSRS Construction skill); mudflation definition and OSRS horizontal-variety mitigation; GE vs WoW AH vs EVE regional market design tradeoffs (friction, manipulation protection, arbitrage); BoP/BoE/Account-Bound binding taxonomy and RMT surface tradeoffs; Diablo III RMAH post-mortem (short-circuited core reward loop, Loot 2.0 fix); Castronova RMT research (Norrath GDP, social-contract analogy); ARPG itemization (rarity tiers, affix scaling, randomized vs deterministic crafting, Last Epoch determinism, loot treadmill mechanics); PoE economic integrity stance (Chris Wilson, league-season fresh economics, rollback policy)
- PROGRESSION covers: OSRS XP formula (exact formula, doubling every 7 levels, "92 is half of 99" property, key milestones); WoW level squish rationale (Shadowlands 120→50 cap compress, every level must unlock tangible reward); WoW ilvl endgame treadmill (two-ladder architecture, seasonal catch-up, Black Hat psychology drivers); classless (OSRS 24-skill) vs class-based (WoW) comparison with design tradeoffs; talent/perk trees (PoE 1384-node passive tree vs curated WoW trees); vertical vs horizontal progression (power creep, gear gating, GW2 experiment, hybrid strategies); retention loop ethics (daily burnout tipping point ~1hr, FOMO battle pass mechanics, PoE seasonal league fresh-start as ethical alternative, FFXIV optional weekly model)
- Relevance section in each page explicitly ties to: [[Economy]] no-arbitrage gate, [[Trades and Leveling]] quadratic vs OSRS formula discrepancy, [[Balance Philosophy]] anti-patterns, [[Chart Loop]], [[Affixes]], [[Items and Gear]]
- Updated `index.md` MMO Research section with full descriptions for both new pages

## [2026-06-13] ingest | MMO Research — synthesis + cleanup (orchestrator)
- Wrote the hub [[MMO Research]] (reading order across all 12 research pages) and
  the synthesis [[MMO Lessons for Wayfinder]] (borrow / adapt / avoid, with a
  pattern→system map: M+/league → [[Chart Loop]], one-char-all-jobs/no-trinity/
  in-game-best-loot/host-authoritative already validated, player-market/daily-
  obligation/vertical-treadmill to avoid at cozy co-op scale).
- Wrote source digest [[mmo-research]] (`wiki/sources/mmo-research.md`) mapping the
  7 `raw/mmo/*.md` provenance files to their pages.
- Tidied the racy `index.md` MMO Research section (deduped, grouped: deep-dives /
  cross-cutting impl / cross-cutting design / synthesis).
- Fixed 13 newline-spanning wikilinks + one non-page [[Wayfinder]] link.
- Lint clean: **72 pages, ~97K words, 0 unresolved links, 0 multi-line links.**

## [2026-06-14] ingest | Game Studies — 260 game case studies (complete)
- Built [[Game Index]] (260 titles, 19 genres) + [[Game Studies]] hub; added games/ folder + `game` type to schema.
- Wrote all 260 dedicated game case studies (design + implementation + Wayfinder relevance), web-researched via 4 waves of parallel research agents; raw provenance in `raw/games/`.
- Genres: MMORPG, ARPG/looter, roguelike, survival, life-sim, RPG/immersive-sim, soulslike, metroidvania, strategy/4X, colony-sim, MOBA, CCG/deckbuilder, fighting, FPS/hero/BR, co-op, sandbox/UGC, sports/rhythm, puzzle, tower-defense.
- Lint clean: 0 unresolved wikilinks, frontmatter on every page.

## [2026-06-14] query+file | Universe Build-Out Plan (multi-agent workflow)
- Ran a 29-agent planning workflow (mine KB across 10 themes → 4 competing framings → 3-lens judge panel → synthesize → adversarial critic).
- Winner: "The Wolds Remembered — A Pillar-by-Pillar Wayfinder" (87/100, over 86/86/83).
- The critic forced a codebase-verification pass that caught 3 factual errors (save versioning exists-but-destructive; Briar Maze shipped; Boar/Wolf modeled+chained; the "Queen" is the same Hedgemother scaled) — the final plan is grounded in source (its §0).
- Filed the result back into the wiki as [[Universe Build-Out Plan]] (cozy-spine-protected, scope hard-cut to Pillar Zero + Pillar One, rest = a named Horizon). Lint clean.

## [2026-06-14] design | Deep system designs for all 15 systems (multi-agent workflow)
- Ran a deep-design workflow (15 system designers grounded in live code + KB + the plan → Systems Interlock Map → adversarial red-team). First run hit a server rate-limit storm (14/15 failed); re-ran throttled in batches of 4 → all 15 succeeded.
- Wrote 15 [[Systems Interlock Map|"— Deep Design" docs]] under wiki/design/ + the interlock map + [[Red-Team Findings]].
- Red-team verdict CONDITIONAL: the designs assert "one verb, no gear tier" but the SHIPPED code has a full weapon/gear ladder (shortbow→longbow→warbow, rolled magic/rare affixes, fire_rate scaling) — the linchpin reconciliation. Also found a live co-op determinism break (layout_loader.gd:813 bare randf()), a "Second Pour" name collision, and the summit using a distinct hedgemother_queen kind.
- 4 intentional forward-ref links remain ([[Almanac]], [[Deepening]], [[Living Atlas]], [[Wayfarer's Codex]] — planned feature pages).

## [2026-06-14] query+file | Gap Analysis & Build Plan (10-agent audit workflow)
- Audited the whole framework for what's MISSING across 7 dimensions (design completeness, code-vs-design, content, art/audio, tooling, process, KB-as-OS) → 107 gaps, 15 demo blockers.
- Red-team caught the first synthesis omitting the gear-ladder linchpin + mis-citing data (Boar trophy is wightpelt not "tusk"; Summit ships a distinct hedgemother_queen kind); final doc grep-verifies every code claim (§0 "rules so it cannot lie again").
- Notable: the AI asset pipeline has NO runnable executable (clean_ai_mesh.py/register_ai_character.py gone with the three.js removal), and docs/character-pipeline/ was deleted in the aggressive cleanup (recoverable from git b17d221^).
- Filed [[Gap Analysis and Build Plan]] with a 13-step Tier 0 sprint, instrumented definitions-of-done, and a "make the KB operational" plan (Build Board, status frontmatter, traceability ledger).
