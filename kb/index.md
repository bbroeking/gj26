# Wayfinder KB — index

The content catalog. Every wiki page, grouped by category, one line each. Read
this first to locate pages, then drill in. Start at [[Overview]]; for status see
[[Current State]]. Maintained by the LLM on every ingest (see [`CLAUDE.md`](CLAUDE.md)).

## Entry points
- [[Overview]] — what Wayfinder is + how this wiki is organized
- [[Current State]] — what's playable, in-flight, queued; known doc/code deltas
- [[Development History]] — three.js → Godot pivot and the spec 01–46 timeline
- [[Universe Build-Out Plan]] — the plan to grow the demo into a full cozy co-op game (mined from this KB)
- [[Gap Analysis and Build Plan]] — what's MISSING across the whole framework (107 gaps) + the Tier 0→4 populate-everything plan + the Tier 0 sprint
- [[Demo Design Decisions]] — the opinionated baseline answer to the 7 open design questions (the doc we iterate against)

## World
- [[Bramblewood]] — the setting: places, the Summit, factions, mood
- [[World Lore]] — the deeper myth layer (the Bramble Bargain, the Hedgemother)
- [[Voice and Tone]] — the cozy-fairytale writing rules for player-facing text

## Systems
- [[Chart Loop]] — the core loop: gather → craft → chart → delve → trophy chain → Summit
- [[Gathering]] — channel-time gathering, node kinds, tool tiers, interrupts
- [[Crafting]] — the four stations: Hearth, Quill's still, Hod's anvil, the bench pot
- [[Trades and Leveling]] — the four-trade XP system, the level-17 cap, perks
- [[Combat]] — combat-as-one-verb, the hotbar, Focus, status effects, AoE
- [[Dungeon Generation]] — how charts/affixes parameterize the procedural hollows
- [[Economy]] — gold, Hod's vending, the no-arbitrage smithing gate
- [[Multiplayer Co-op]] — host-authoritative ENet co-op (Phase A town, Phase B dungeon)
- [[Save System]] — what persists, save timing, the roundtrip-test caveat
- [[UI and HUD]] — the Wayfinder UI Kit, globes + skill tray, the page windows
- [[Camera and Game Feel]] — the FATE camera, locomotion/physics, the juice stack
- [[Onboarding and Tutorial]] — first-time flow, per-verb hints, the tutorial machine

## Entities — Trades
- [[Wayfinding]] — the cartography trade: charting, ink slots, perks to 17
- [[Earthcraft]] — ore tiers (copper→hedgesteel), smelting/smithing, perks
- [[Wildcraft]] — 6 herb tiers, heal/buff brews, perks
- [[Huntcraft]] — the kills-feed-it combat trade, perks to Even Breath (17)

## Entities — Charting
- [[Charts]] — the parameterized dungeon key: templates, tiers, seeds
- [[Affixes]] — good/bad twins, the ~15 rollable affixes + boss-den affixes
- [[Inks]] — the 8 inks and which affixes each courts; recipe discovery
- [[The Crafting Bench]] — sockets, live odds, on-bench mixing pot, codex
- [[The Waystone]] — socketing a chart, entering a run, exit/abandon stones

## Entities — Content
- [[Skills]] — the 9-skill pool, Huntcraft gates, the 4-slot loadout
- [[Enemies]] — per-kind roster + AI, elites + affix modifiers, pack scaling
- [[Bosses]] — the trophy chain: Hedgemother → Boar → Wolf → Summit
- [[Items and Gear]] — categories, rarities, base stats + affixes, the pack
- [[Gather Nodes]] — ore_rock / forage_node / log_pile, tiers, regrowth
- [[NPCs]] — the town roster (Mara, Hod, Quill…): who, where, what they teach/sell

## Concepts
- [[Design Influences]] — the genre lineage; what was adopted vs rejected
- [[Balance Philosophy]] — cozy pacing, no-arbitrage economy, XP/heal tuning
- [[Design Archive]] — superseded/cut/deferred design, preserved and labeled

## Design (forward-looking deep designs)
Deep, buildable designs for every system — grounded in the live code, constrained by the [[Universe Build-Out Plan]]. Read the map and the red-team first.
- [[Systems Interlock Map]] — how the systems wire into one machine: spine dataflow, build order, shared data, contradictions, the cozy throughline
- [[Red-Team Findings]] — the adversarial review (verdict: CONDITIONAL — the designs contradict the *shipped* gear ladder; required reconciliations)
- **The spine:** [[Chart Loop — Deep Design]] · [[Gathering — Deep Design]] · [[Crafting and Inks — Deep Design]] · [[Trades and Leveling — Deep Design]] · [[Charts Affixes and Inks — Deep Design]]
- **The delve:** [[Dungeon Generation — Deep Design]] · [[Combat — Deep Design]] · [[Skills and Loadout — Deep Design]] · [[Enemies and Bosses — Deep Design]] · [[Items Gear and Economy — Deep Design]]
- **The frame:** [[Multiplayer Co-op — Deep Design]] · [[Progression and Endgame — Deep Design]] · [[Onboarding and Narrative — Deep Design]] · [[UI HUD Camera and Audio — Deep Design]] · [[Save and Persistence — Deep Design]]

## Decisions
- [[Design Decisions]] — digest of the six ADRs (spine, controls, Huntcraft, cap)

## Pipeline
- [[Godot Pipeline]] — engine setup, project layout, dev hooks, the test suites
- [[Blender Pipeline]] — the bevel+toon recipe, two-tier GLB root, socket authoring
- [[Asset Pipeline]] — the Midjourney → Meshy → clean → Blender → game flow
- [[Animation Pipeline]] — the animation approach + the P1/P2/P3 backlog
- [[Art Bible]] — the chunky-toon visual style, palette discipline, anti-style list
- [[UI Workflow]] — how UI is designed: Claude Design → measure → rebuild → verify
- [[Content Generation and Evals]] — the AI content playbooks + the eval pipeline
- [[Character Model Briefs]] — per-character model briefs + the brief template
- [[Concept Art Prompts]] — the Midjourney concept-art prompt library

## Sources (per-cluster digests of raw docs)
- [[world-and-decisions]] · [[charting]] · [[trades]] · [[combat]] · [[items-npcs]]
  · [[multiplayer]] · [[pipeline]] · [[ui]] · [[camera-feel]] · [[onboarding-history]]
  · [[influences]] · [[design-archive]] · [[art-and-content]]

## MMO Research
- [[MMO Research]] — the research hub + reading order; [[MMO Lessons for Wayfinder]] — the synthesis (borrow / adapt / avoid)
- **Game deep-dives:**
  - [[World of Warcraft]] — dual talent trees, 400ms spell-batch tick, sharding/layering/phasing/CRZ, Mythic+ keystones, Great Vault, GDC quest design post-mortem, Lua addon sandbox
  - [[RuneScape]] — 23-skill model, XP curve formula, 0.6s tick system, GE, Ironman, OSRS/RS3 divergence, Java/RuneScript architecture
  - [[EVE Online]] — single-shard cluster (Tranquility), Time Dilation, StacklessIO/CarbonIO, player economy (PLEX/ISK), passive skill training, Battle of B-R5RB
  - [[Final Fantasy XIV]] — 1.0 failure → ARR rebuild, job system (one character all jobs), Duty Finder matchmaking, data center travel, 0.3s positional tick, patch cadence
  - [[MMO Survey]] — UO, EverQuest, GW2, Lineage II, Diablo/PoE, Albion, Project Gorgon
- **Cross-cutting implementation:**
  - [[MMO Server Architecture]] — authoritative servers; shard/layer/phase/CRZ/megaserver taxonomy; AoI/interest management; zone hand-off; DB persistence; scaling
  - [[MMO Netcode and Tick Systems]] — tick rates; client prediction + reconciliation; interpolation; lag compensation; snapshot vs delta vs events; reliable vs unreliable; listen-server anti-cheat
- **Cross-cutting design:**
  - [[MMO Economy and Itemization]] — faucets/sinks/mudflation, GE vs AH vs EVE market, BoP/BoE binding, RMT, affix rarities, loot treadmill, D3 AH disaster
  - [[MMO Progression Systems]] — OSRS XP formula, WoW level squish, classless vs class-based, vertical vs horizontal, talent trees, gear-score endgame, retention loops
  - [[MMO Social and Endgame]] — holy trinity tradeoffs, Dunbar-layer guilds, matchmaking vs community, raids/lockouts, world bosses, PvP, what scales to 2–4 players
- **Provenance:** [[mmo-research]] (source digest) · raw notes in `raw/mmo/`

## Game Studies (260 case studies)
- [[Game Studies]] — the hub; [[Game Index]] — the full 260-title catalog (19 genres), progress-tracked
- One page per game (design + implementation + Wayfinder relevance) in `wiki/games/<genre>/`; provenance in `raw/games/`
- Companion: [[MMO Research]] · [[MMO Lessons for Wayfinder]] · [[Design Influences]]
