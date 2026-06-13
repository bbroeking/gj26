---
type: concept
tags: [mmo-research, wow, blizzard, dungeon-crawler, talent-trees, instancing, economy, netcode, addon-api, progression, retention]
status: draft
updated: 2026-06-13
sources:
  - "https://warcraft.wiki.gg/wiki/Sharding_(term)"
  - "https://github.com/magey/classic-warrior/wiki/Spell-batching"
  - "https://worldofwarcraft.blizzard.com/en-us/news/2878505/dev-watercooler-cataclysm-talent-tree-post-mortem"
  - "https://news.blizzard.com/en-us/world-of-warcraft/23797209/world-of-warcraft-dragonflight-talent-preview"
  - "https://warcraft.wiki.gg/wiki/Lockout"
  - "https://warcraft.wiki.gg/wiki/Instance_difficulty"
  - "https://warcraft.wiki.gg/wiki/Great_Vault"
  - "https://www.gamedeveloper.com/game-platforms/gdc-learning-from-i-world-of-warcraft-i-s-quest-design-mistakes"
  - "https://warcraft.wiki.gg/wiki/World_of_Warcraft_API"
  - "https://www.datacenterknowledge.com/archives/2009/11/25/wows-back-end-10-data-centers-75000-cores"
  - "raw/mmo/world-of-warcraft.md"
---

# World of Warcraft

The defining mass-market MMORPG (Blizzard, launched November 23 2004), which established most of the conventions that later games — including Wayfinder's reference set — treat as defaults: tab-target combat, instanced dungeons with lockouts, talent trees, a player-driven auction house, daily quests, reputation gates, and the expansion treadmill of gear obsolescence and power resets.

---

## 1. Overview and Scale

WoW peaked at **12 million subscribers in October 2010** (pre-Cataclysm; confirmed by Activision Blizzard investor release). Blizzard stopped publishing subscriber numbers after 2015 (last official figure: 5.5 million). Third-party estimates for 2026 place it around 7.25 million. The game has shipped **10 expansions** as of 2026, with the 11th (Midnight) launching March 2, 2026.

The game defined — and later re-iterated — the subscription MMO template. Monthly subscription ($15/month) drove constant "reason to log in" design pressure visible in every retention system described below.

---

## 2. Expansion Timeline

| Expansion | Year | Level Cap | Key Mechanic Introduced |
|---|---|---|---|
| Vanilla | 2004 | 60 | Launch; 40-man raids; 51-pt talent trees |
| The Burning Crusade | 2007 | 70 | Heroic dungeons; Arenas; flying mounts |
| Wrath of the Lich King | 2008 | 80 | 10/25-man raid split; Death Knight class |
| Cataclysm | 2010 | 85 | Rebuilt 1-60 world; talent pruning (71→41 pts) |
| Mists of Pandaria | 2012 | 90 | Talent grid replaces trees; 54 dailies/day |
| Warlords of Draenor | 2014 | 100 | Garrisons; Mythic raids; sharding (6.0.2) |
| Legion | 2016 | 110 | Mythic+; Artifact Weapons; World Quests |
| Battle for Azeroth | 2018 | 120 | Azerite / Heart of Azeroth (borrowed power) |
| Shadowlands | 2020 | 60 | Level squish; Covenants; Great Vault |
| Dragonflight | 2022 | 70 | Dual talent trees restored; profession quality |
| The War Within | 2024 | 80 | Worldsoul Saga; Delves (solo instanced content) |
| Midnight | 2026 | TBD | True player housing |

> **Expansion treadmill:** all gear earned in one expansion is obsoleted by the first zone of the next. Item level inflation is the mechanism — each expansion raises the ilvl ceiling by ~100-200+ points, compressing the entire previous expansion's range into irrelevance.

---

## 3. Client-Server Architecture

### 3.1 Realm Infrastructure

WoW runs on a **realm-per-server model**. As of 2009: 700+ realms served by 10 global data centers (US: WA, CA, TX, MA; EU: France, Germany, Sweden; Asia: South Korea, China, Taiwan); 13,250 server blades; 75,000 CPU cores; 112.5 TB blade RAM; 1.3 PB storage. Operations staff: 68 people in a Global Network Operations Center (GNOC).

The client is authoritative for local display only; all combat resolution and world state run server-side.

### 3.2 Sharding, Layering, Phasing, CRZ

WoW uses four related but distinct mechanisms to manage player density:

**Sharding** (introduced patch 6.0.2, October 2014): when a zone exceeds a player-density threshold, the server creates additional shard copies of that zone and routes incoming players to them. Players on different shards are invisible to each other; each shard has independent NPC and resource spawns. Players can be re-sharded when joining a party in the same zone, toggling War Mode, or using Chromie Time. Enabled on all retail Normal realms; disabled by default on RP realms.

**Layering**: sharding applied realm-wide (all zones simultaneously). Used at WoW Classic launch (2019) to handle the population surge, then removed once population normalized.

**Phasing**: changes what version of the world the player sees based on their quest/story progression, not player density. Players in different phases cannot see each other. Party Sync allows the group to adopt the party leader's phase. Predates sharding — introduced in Wrath of the Lich King.

**Cross-Realm Zones (CRZ)**: the inverse of sharding — designed to solve *undercrowding*. Merges players from multiple realms into one zone instance to keep zones feeling alive. Matches realms of the same server type (PvE/PvP/RP) within the same datacenter and within ±3 hours server time. **Connected Realms** (patch 5.4, 2013) are a permanent merge at the server level — two or more low-population realms share the same world space as though they are one realm.

> **For Wayfinder:** the sharding/layering split is the clearest model for the "session population" problem in co-op: instances eliminate the density problem entirely, at the cost of world presence. See [[Multiplayer Co-op]].

### 3.3 Instancing

Dungeons and raids are fully instanced — a private copy of the zone is created for each group. The instance persists until the lockout timer expires or all players leave. No sharding inside an instance; the group is alone in the zone. See §5 for lockout details.

---

## 4. The Spell-Batching Tick

> This is WoW's most distinctive netcode decision and a source of both emergent gameplay and persistent community debate.

WoW's original (Vanilla through Warlords of Draenor) combat server ran on a **400ms batch window**. Blizzard's own language: *"Any action that one unit takes on another different unit used to be processed in batches every 400ms."*

**Self-cast actions** (healing yourself, buffing yourself, self-targeted abilities): applied **instantly**.

**All other actions** (damage to enemy or ally, debuff/buff application to others, knockbacks, interrupts): calculations (hit/miss, damage roll, proc triggers) resolve immediately when the cast finishes, but the **effect is queued** and applies at the next 400ms batch boundary.

Consequences:
- Both a Warrior's Pummel and a Mage's Polymorph could each succeed simultaneously if they entered the same batch window — both were valid at batch-start.
- Double charges: two Warriors charging each other could both connect, leaving both stunned at their original positions.
- Healing and damage output feel delayed for group targets relative to self-healing.
- Combat log shows two event types with different timestamps: `SPELL_CAST_SUCCESS` (calculation) and `SPELL_DAMAGE_LANDED` (application).

**Timeline:**
- Pre-WoD: 400ms batch.
- Post-WoD (better servers): ~20ms batch — effectively instant, eliminating the simultaneous-action interactions.
- WoW Classic (2019, patch 1.13): 10ms batch — also near-instant; Blizzard chose not to restore the 400ms window for Classic despite community requests.

> **For Wayfinder:** the batch tick is why WoW's combat *felt* different to Vanilla players — the batching created surprising simultaneous-outcome moments that reads as "realistic lag" rather than desync. Most modern co-op games run sub-50ms authority ticks and don't replicate this. See [[MMO Netcode and Tick Systems]].

---

## 5. Classes and Specializations

WoW uses a **holy trinity**: Tank, Healer, DPS. As of the Midnight era:

- **13 classes**: Warrior, Hunter, Mage, Rogue, Priest, Warlock, Paladin, Druid, Shaman, Monk, Demon Hunter, Death Knight, Evoker.
- **39 specializations** (3 per class; Druid = 4, Demon Hunter = 2): 6 tank, 7 healer, 13 ranged DPS, 13 melee DPS.
- Specialization chosen at level 10; abilities auto-granted as you level; talent points (Dragonflight era) purchased on top of baseline.

Each spec has a distinct rotation, utility profile, and visual identity — a major driver of player identity and replayability ("alt characters").

---

## 6. Talent Trees — Full Evolution

### 6.1 Original System (Vanilla–WotLK, 2004–2010)

51 talent points at level 60, growing to 71 by WotLK level 80. Three trees per class; 31-point capstone talents gated the most powerful abilities. Problems: 80+ talents per class; passive talents that every player took regardless of playstyle; overpowered cross-tree hybrid builds; 30–50% performance gap between best and worst specs.

### 6.2 Cataclysm Pruning (2010)

**41 talent points**, **31-pt capstones**, with mandatory specialization (players must spend 31 pts in their primary tree before branching). Most passive "filler" talents deleted or made baseline. Mastery stat introduced to delay complexity to higher levels. Result: spec performance variance narrowed to 5–10% (from 30–50%). Design post-mortem (Blizzard, Cataclysm Dev Watercooler): remaining issues included "trap" talents, few genuinely hard decisions per spec, awkward %-chance tiered mechanics.

### 6.3 Mists of Pandaria Grid (2012–2022)

Talent trees **abandoned entirely**. Replaced by a 6-row × 3-choice grid: one choice per row, rows unlocked at levels 15/30/45/60/75/90. Only 18 total talents; choices within a row are mutually exclusive. Goal: every talent a real choice rather than a passive stat tax. Trees absent from MoP through end of Shadowlands (~10 years).

### 6.4 Borrowed Power Systems (Legion–Shadowlands, 2016–2022)

Three consecutive expansions used spec-locked alternate progression systems stapled on top of the grid:
- **Legion**: Artifact Weapons — spec-locked weapons with their own AP-fueled talent constellation.
- **BfA**: Heart of Azeroth necklace + Azerite Armor traits — replaced tier sets with proc-based node rings.
- **Shadowlands**: Covenant abilities + Conduits (socketed stat nodes in a "Soulbind" tree) — players locked to one Covenant per character, a controversial gating of power behind story choice.

All three systems were fully deleted when their expansion ended — the core tension of borrowed power.

### 6.5 Dragonflight Dual Trees (November 2022, restored)

Full branching talent trees restored after ~10-year absence. Two trees per spec:
- **Class Tree**: abilities universal to all specs of the class; emphasizes utility and hybrid flexibility.
- **Specialization Tree**: role-specific power bonuses; enhances primary-role performance.

Points divided equally; players cannot dump all points into one tree. Gate mechanics: 8 points to unlock Row 5+; 20 points for Row 8+. **Choice nodes** (octagonal) present mutually exclusive decisions. Talent loadouts can be saved and shared. Blizzard rationale: "increase player agency," "meaningful rewards while leveling," prevents scenarios where maximizing DPS requires abandoning all utility.

> **For Wayfinder:** the oscillation from 80-talent trees → 18-choice grid → dual trees with 30+ nodes is the clearest documented case study of the "too many/too few choices" design problem. The Dragonflight dual-tree gate mechanic (spend N points to unlock next row) maps well to Affix chains in [[Chart Loop]] and skill unlock ladders in [[Skills]]. See also [[MMO Progression Systems]].

---

## 7. Quest System Design

Scale grew from 600 (design goal) → 2,600 (Vanilla launch) → 7,650 (WotLK). Quest text hard-capped at **511 characters** (Blizzard design rule prioritizing clarity over literary ambition).

GDC postmortem by lead designer Jeff Kaplan identified the core failure modes:

**The Christmas Tree Effect**: Too many quests at one hub simultaneously → players complete them in arbitrary order, bypassing narrative structure. Designers lose control of pacing.

**Collection quest failures**: Arbitrary item gathering without narrative payoff; bad creature density; excessive inventory pressure; "shitty streaks" (pure RNG dry spells). *Fix*: progressive drop rates — drop chance increases per kill, guaranteeing eventual acquisition.

**Gimmick quests**: Vehicle mechanics or specialty gameplay that feels unpolished relative to core movement/combat. "More fun for the designer than the player."

**Mystery mishandling**: Vague objectives that send players to external guides. Mystery should never obscure *mechanics*.

**Design solutions implemented**:
- **Breadcrumb quests**: explicitly route players between hubs via a waypointing chain. Introduced strongly in TBC, became the signature WoW hub-and-spoke flow.
- **Interface clarity**: minimap quest markers, quest log, instant-feedback item counters.
- **Trust-building**: consistent reward tuning so players trust that completing a quest is worthwhile even if the specific reward isn't.

**Evolution of dailies and world quests**:
- **Daily quests** (TBC patch 2.1): initially capped at 10/day, raised to 25/day. By MoP, ~54 possible dailies/day from a pool of ~278 — player "daily quest burnout" backlash.
- Patch 5.0 (MoP): 25-daily cap removed; dailies no longer limited by daily cap.
- **World Quests** (Legion): replaced fixed dailies on the Broken Isles — map-scattered, semi-randomly rotating, scaled rewards. Dragonflight changed World Quest reset from daily to semi-weekly after player pressure.

> **For Wayfinder:** the 511-character quest text limit and the progressive drop rate fix for collection quests are directly applicable. The Christmas Tree Effect is a real danger for any game that front-loads multiple optional objectives at a hub. See [[Gathering]], [[Chart Loop]].

---

## 8. Dungeons, Raids, and Instancing

### 8.1 Lockout System

Introduced patch 1.9.0 (2006), moving from absence-based to fixed-calendar resets. Three lockout types:

| Type | Examples | Mechanic |
|---|---|---|
| **ID-based (hard)** | Classic raids (MC→SWP), all Mythic raids | Bound to specific instance ID; cannot switch groups |
| **Loot-based (soft)** | LFR, Normal/Heroic raids (since Siege of Orgrimmar) | Can re-enter; no loot per boss per week per difficulty |
| **Flexible boss-based** | Normal raids WotLK–Throne of Thunder | Can kill each boss once/week across groups |

Reset schedule: Raids + Mythic dungeons weekly (Tuesday Americas, Wednesday EU); Heroic dungeons daily at 9:00 AM (7:00 AM EU).

### 8.2 Difficulty Tier History

| Difficulty | Introduced | Players | Notes |
|---|---|---|---|
| Normal | Vanilla (2004) | 5 / 10 / 20 / 40 | Only difficulty at launch |
| Heroic | TBC (2007) | 5 (dungeons); 10/25 (raids) | Higher ilvl gear requirement |
| LFR (Raid Finder) | Cataclysm (Dragon Soul) | 10-25 flexible | Lowest loot quality; first accessible raid format |
| Mythic | WoD (2014) | Fixed 20 (raids); 5 (dungeons) | Hardest; no flexible scaling |
| Mythic+ | Legion (patch 7.0.3, 2016) | 5 | Infinite scaling via keystone levels |

### 8.3 Mythic+ System

Introduced July 19, 2016 (patch 7.0.3), replacing Challenge Mode. The foundational "endgame loop for non-raiders":

- **Keystone**: consumable item placed in a Font of Power at a dungeon entrance; sets the Mythic+ level and this week's affix set.
- **Timer**: completing within the time limit upgrades the keystone by 1+ level; failing the timer means the key will not upgrade (still completable, but next key is lower level or depleted).
- **Affixes**: stack as key level rises. Examples: Tyrannical/Fortified (boss or trash harder; alternate weekly) at M+10; additional affixes at M+4 and M+7. Affixes rotate on the weekly reset.
- **Loot**: end-of-dungeon chest awards 2 items (3 if timer beaten in original Legion design); modern system routes loot through the Great Vault.
- **Mythic+ Rating**: numerical score replacing raw key level as the progression metric; tracks best timing across all dungeons in the season.

### 8.4 Great Vault (Weekly Chest)

Introduced in Shadowlands (patch 9.0); replaced Legion's Grand Challenger's Bounty (M+ only) and BfA's War Chest (PvP only).

Mechanism: up to 9 possible items per week (based on activity thresholds); player selects **one** item. Three activity tracks:
- **Raids**: 3/6/9 bosses killed = 1/2/3 choices.
- **Dungeons**: Heroic+ completions (threshold count varies by patch/season).
- **World** (TWW era): Delves + world events (replaced PvP slot in The War Within).

Resets weekly with the raid lockout.

> **For Wayfinder:** the Great Vault is the most studied solution to "loot RNG burnout" — guaranteed weekly meaningful loot choice, with quantity of choices gated on breadth of participation. Directly relevant to [[Items and Gear]] and [[Bosses]] trophy drop design.

---

## 9. Professions and the Economy

### 9.1 Profession Structure

Players may have **2 primary professions** per character (unlimited secondary: Cooking, Fishing). Categories:
- **Gathering**: Mining, Herbalism, Skinning, Fishing — harvest resource nodes in the open world; feed crafting.
- **Production**: Blacksmithing, Alchemy, Tailoring, Leatherworking, Engineering, Jewelcrafting, Enchanting, Inscription, Cooking.
- **Service**: Enchanting (apply to others' gear), Crafting Orders (Dragonflight+).

For most of WoW's history, professions were "afterthoughts" — crafted gear quickly obsoleted by dungeon/raid drops. Dragonflight (2022) revamped the system:
- **Quality tiers** (1-5 stars) for both gathered materials and crafted outputs — higher quality crafted gear = higher item level; higher quality potions = stronger effects.
- **Crafting Orders**: AH-like interface for players to request another player craft an item (even cross-realm), with reagents and tip supplied by requester.
- **Profession specializations**: separate tree unlocked via crafting XP, enabling expertise in sub-categories (e.g., Alchemist specializing in Transmutation vs Potions).

### 9.2 Auction House and Economy

The Auction House is WoW's primary market. Historical trajectory:
- **Vanilla**: gold scarce; economy driven by farming + direct trade; AH less active.
- **TBC/WotLK**: daily quest income inflated prices and gold supply.
- **Cataclysm**: gold inflation became a visible design problem.
- **Gold sinks**: repair costs, rare mounts (Tundra Mammoth, etc.), in-game services, cosmetics.
- **WoW Token** (April 2015, WoD): $20 USD → in-game gold (price set by supply/demand) or 30 days game time. EU: €20 or €12.99 Battle.net balance. Creates an official real-money/gold exchange, tying server economy to real-world currency floor/ceiling.

> **For Wayfinder:** the WoW Token is the canonical documented design for a "pay-to-gold" system that controls inflation through supply/demand rather than arbitrary gold multiplication. The Dragonflight crafting quality system (higher quality = higher ilvl output) is directly analogous to Wayfinder's [[Crafting]] Affix-conditioned quality design.

---

## 10. PvP Systems

- **World PvP**: default on PvP servers (opt-in via War Mode on Normal servers).
- **Battlegrounds**: instanced objectives-based PvP. Classic BGs: Warsong Gulch (capture-the-flag 10v10), Arathi Basin (domination 15v15), Alterac Valley (territory 40v40). Players travel to BG entrances or use LFG tool.
- **Arenas**: introduced TBC; 2v2, 3v3, 5v5; rating-based rewards (Gladiator, Rival, Challenger titles and gear). First PvP season in TBC.
- **Honor System**: Vanilla rank system (weekly rank recalculation); TBC reformed to honor-as-currency for PvP gear; Legion overhauled to PvP-exclusive talent rows (separate from PvE trees) and honor as an XP-like leveling track.
- **Rated Battlegrounds**: Cataclysm — organized 10v10 rated BGs with arena-parallel rating ladder.

---

## 11. Retention Loops

WoW's subscription model created constant pressure to give players weekly and daily reasons to log in. The systems that resulted:

| Era | Daily/Weekly Loop |
|---|---|
| TBC-WotLK | Daily quests (gold/rep); raid lockouts (weekly boss kills) |
| Cataclysm | Valor Points from heroics and raids (weekly cap); daily quests |
| MoP | 54+ daily quests/day; reputation gating; Timeless Isle (no-lockout outdoor loot) |
| WoD | Garrison missions (passive offline income); apexis crystals (daily) |
| Legion | World Quests (semi-daily); Artifact Power (infinite grind); M+ weekly chest |
| BfA | Island Expeditions; Warfronts; Azerite farming |
| Shadowlands | Covenant Callings (3-day timer, max 3 active); Torghast; Great Vault |
| Dragonflight | World Quests (semi-weekly); Great Vault; Crafting Orders |
| TWW | Delves; Great Vault; Warband system (account-wide progression) |

> Pattern: each expansion introduced a new "daily/weekly activity" mechanic, many of which felt like mandatory chores by mid-expansion. The shift from daily → semi-weekly World Quests in Dragonflight is the most explicit documented developer response to "daily quest burnout." See [[MMO Social and Endgame]].

---

## 12. Addon / Lua API

WoW ships a sandboxed Lua runtime (upgraded from Lua 5.0 to Lua 5.1 with TBC, January 2007).

**AddOn structure**: `.toc` manifest (Interface version, author, dependencies), `.lua` logic files, optional `.xml` frame definitions.

**API surface** (patch 12.0.5, April 2026): 266+ namespaced systems under `C_*` prefixes covering spells, inventory, social, auction house, character systems, UI framework, quests, instances.

**Security model** — the key design for automation prevention:
- **`#hwevent` functions**: only callable from genuine hardware event callbacks (keyboard/mouse input). Casting a spell, interacting with an NPC, clicking a button in the world — none can be triggered from a timer or a script loop. This prevents bots from scripting gameplay while still allowing rich UI addons.
- **`#noscript` functions**: unavailable inside restricted secure frames (the frames that handle protected game actions).
- **`#framexml` functions**: FrameXML-only; not exposed to third-party addons.
- `package/require` unavailable to addon developers (sandboxed Lua; no filesystem access).

**Notable addon categories** enabled by the API: unit frames (health/mana display), combat log parsing (ACT-equivalent damage meters), raid/boss timers (DBM, BigWigs), auction house scanners (TSM), minimap modifications.

---

## 13. Zone Scaling and the Leveling Problem

Zone scaling (patch 7.0, 2016 for Broken Isles; patch 7.3.5 for all older zones) lets zones automatically scale enemy/reward levels to the player's character level within a defined band. This addressed content obsolescence — players could return to older zones without trivializing them.

Chromie Time (Shadowlands, patch 9.0.1): characters choose one expansion's zones to level through (1-10 new starting area → chosen expansion scales to 50 → current expansion 50-60+). Near-complete content flexibility.

**Content obsolescence problem remains at expansion boundaries**: all previous-expansion gear is replaced by first zone quest rewards of new expansion. Item level compression makes this explicit — players can track exactly when their current tier becomes worthless by zone entry.

---

## See Also

- [[MMO Research]] — hub page for all MMO reference
- [[MMO Server Architecture]] — technical architecture patterns across MMOs
- [[MMO Netcode and Tick Systems]] — spell batching, authority model, client prediction
- [[MMO Economy and Itemization]] — AH mechanics, gear treadmill, token economy
- [[MMO Progression Systems]] — talent trees, borrowed power, the expansion reset cycle
- [[MMO Social and Endgame]] — retention loops, guilds, daily burnout
- [[RuneScape]] — contrasting MMO; no holy trinity; skill-as-identity
- [[Final Fantasy XIV]] — contrasting MMO; story-first, catch-up systems
- [[EVE Online]] — contrasting MMO; fully player-driven economy
- [[MMO Lessons for Wayfinder]] — distilled design lessons for this project
- [[Chart Loop]] — WoW's Mythic+ keystone loop is the primary reference for Chart replayability
- [[Items and Gear]] — gear treadmill, quality tiers, loot RNG
- [[Crafting]] — Dragonflight crafting quality system as design parallel
- [[Gathering]] — profession gathering nodes; progressive drop rate fix
- [[Skills]] — talent tree oscillation maps to skill unlock design
- [[Bosses]] — Great Vault weekly chest as trophy/loot design reference
- [[Combat]] — holy trinity and what Wayfinder abandons
- [[Economy]] — WoW Token as documented inflation-management reference
- [[Multiplayer Co-op]] — instancing vs sharding for player density management
- [[MMO Survey]] — comparative overview across all researched MMOs

---

## Sources

- Warcraft Wiki — Sharding: https://warcraft.wiki.gg/wiki/Sharding_(term)
- Magey's WoW Classic Warrior Wiki — Spell Batching: https://github.com/magey/classic-warrior/wiki/Spell-batching
- Blizzard Dev Watercooler — Cataclysm Talent Post-Mortem: https://worldofwarcraft.blizzard.com/en-us/news/2878505/dev-watercooler-cataclysm-talent-tree-post-mortem
- Blizzard News — Dragonflight Talent Preview: https://news.blizzard.com/en-us/world-of-warcraft/23797209/world-of-warcraft-dragonflight-talent-preview
- Warcraft Wiki — Lockout: https://warcraft.wiki.gg/wiki/Lockout
- Warcraft Wiki — Instance Difficulty: https://warcraft.wiki.gg/wiki/Instance_difficulty
- Warcraft Wiki — Great Vault: https://warcraft.wiki.gg/wiki/Great_Vault
- Game Developer (GDC) — WoW Quest Design Mistakes: https://www.gamedeveloper.com/game-platforms/gdc-learning-from-i-world-of-warcraft-i-s-quest-design-mistakes
- Warcraft Wiki — WoW API: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- Data Center Knowledge — WoW backend (2009): https://www.datacenterknowledge.com/archives/2009/11/25/wows-back-end-10-data-centers-75000-cores
- Activision Blizzard investor release (12M subs): https://investor.activision.com/news-releases/news-release-details/world-warcraftr-subscriber-base-reaches-12-million-worldwide
- BlizzardWatch — Cataclysm talent trees to Dragonflight: https://blizzardwatch.com/2022/10/31/wow-cataclysm-talent-trees/
- Warcraft Wiki — Profession: https://warcraft.wiki.gg/wiki/Profession
- Warcraft Wiki — Cross-realm zones: https://warcraft.wiki.gg/wiki/Cross-realm_zones
- Raw provenance notes: raw/mmo/world-of-warcraft.md
