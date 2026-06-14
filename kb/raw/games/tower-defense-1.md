# Raw Source Digest: Tower Defense Cluster 1
**Ingested:** 2026-06-14  
**Fed into:** `wiki/games/tower-defense/` (8 pages)

---

## Source list

| Game | URLs fetched | Notes |
|------|-------------|-------|
| Plants vs Zombies | plantsvszombies.wiki.gg/wiki/Plants_vs._Zombies; medium.com/owen-ketillson (PvZ literacy essay); hanadyg.github.io (RL paper) | Engine: PopCap Games Framework; solo only; 2009 |
| Bloons TD 6 | store.steampowered.com/app/960090; bloons.fandom.com/wiki/Bloons_TD_6; co-optimus.com; bloonswiki.com | Engine: Unity; 2–4 co-op unlocked at account level 20; Dec 2018 |
| Kingdom Rush Origins | en.wikipedia.org/wiki/Kingdom_Rush:_Origins; gamedeveloper.com (level design deep-dive); kingdomrushtd.fandom.com; store.steampowered.com/app/816340 | Engine: proprietary (Flash/HTML5-derived); solo only; iOS/Android 2014, PC 2018 |
| Orcs Must Die 3 | en.wikipedia.org/wiki/Orcs_Must_Die!_3; bigbossbattle.com review; checkpointgaming.net review; store.steampowered.com/app/1522820 | Engine: Unreal Engine 4; 2-player co-op; 2021 |
| Defense Grid The Awakening | waywardstrategy.com retrospective; thegemsbok.com review; gamespot.com review | Engine: undocumented; solo only; 2008 |
| Sanctum 2 | store.steampowered.com/app/210770; gameinformer.com review (403); co-optimus.com; metacritic.com | Engine: Unreal Engine 3; 4-player co-op; 2013. Game Informer URL returned 403 — core facts sourced from Steam store + Co-Optimus |
| Dungeon Defenders II | medium.com/@dlcmanager review; store.steampowered.com/app/236110; pcgamer.com; co-optimus.com | Engine: undocumented (Unreal-derived suspected); 4-player co-op; 2017; F2P |
| Mindustry | en.wikipedia.org/wiki/Mindustry; github.com/Anuken/Mindustry; mindustrygame.github.io; tvtropes.org | Engine: Arc framework (LibGDX fork), Java, GPL-3.0 open source; 2017 |

---

## Gaps / uncertainty flags

- **Defense Grid engine**: Hidden Path Entertainment has not publicly disclosed the engine; "undocumented" flagged in the page.
- **Dungeon Defenders II engine**: Not confirmed in fetched sources; suspected Unreal but not stated. Page does not claim engine.
- **Sanctum 2**: Game Informer review URL returned HTTP 403; perk system and character class details sourced from Steam + Co-Optimus only.
- **Bloons TD 6**: bloonswiki.com Co-op page returned HTTP 403; co-op details synthesised from Steam store + Fandom wiki.
- **Kingdom Rush Origins engine**: Wikipedia and Ironhide do not name the engine publicly; noted in page as "proprietary Flash/HTML5-derived engine."
- **Mindustry LibGDX**: Confirmed via WebSearch (Arc = LibGDX fork) but not present in the Wikipedia or GitHub README fetches directly.

---

## Key design facts extracted

### Plants vs Zombies
- 5-lane grid; 5×9 cells; lane isolation is the legibility mechanic
- Sun economy: base sky-drop + Sunflower multiplier; Sunflower cost halved from 100→50 during dev, requiring full economy re-balance
- Zombie roster shown before each wave; flag icon marks big waves on progress bar
- Stage-biome modifiers: Night (no ambient sun), Fog (reduced visibility), Roof (parabolic arc trajectory) — rolling environmental affixes
- Lawn mower safety net: one-shot per lane, one use only
- 50 levels, 5 stages (Day/Night/Pool/Fog/Roof), 10 levels per stage

### Bloons TD 6
- 25 monkey towers; 3 upgrade paths each; only one path to tier 5, one other to tier 2
- 17 heroes; level passively per round; shared Hero XP in co-op
- Co-op: 2–4 players; map-section or full-map sharing; per-player Hero slots and tier-5 upgrades; shared income pool
- Monkey Knowledge: 100+ account-level meta-upgrades
- Live-service modes: Boss Events, Odysseys, Contested Territory, Content Browser

### Kingdom Rush Origins
- 4 tower archetypes; tier-4 splits into 2 specialist variants
- Stars (from lives remaining) fund permanent campaign meta-upgrades
- Barracks deploy 3 melee soldiers; rally mechanic = directional crowd control
- Hero: 5 upgradeable abilities; directable unit; costs microtransactions to unlock most heroes
- Level design: each wave is a focused mechanic test; calm-before-storm pacing; boss at arc end

### Orcs Must Die 3
- 18 levels; Story, Endless, Weekly Challenges, War Scenarios
- Skull system: re-investable (no permanent lock-in); earned per-level by score
- Trap combos: slow → redirect → damage; cooldown-gated throughput
- War Scenarios: 1,000-unit armies; oversized War Machines (catapults, archer battalions)
- Unreal Engine 4; 2-player co-op; Metacritic 73–77

### Defense Grid The Awakening
- Power core retrieval: dropped core floats back to base; still losable if second enemy grabs it
- Tower archetypes: Inferno (swarm), Gun/Cannon (shields), Tesla (endpoint), Laser (DOT + blocking benefit), Meteor (indirect, minimum range)
- Two upgrade levels per tower
- Wave pre-announcement: full creep roster shown before each wave
- Snap-to-grid build positions (not freeform maze); solo only; 2008

### Sanctum 2
- Two-phase loop: build phase (towers + maze walls) → FPS combat phase
- Resource pickups scattered on map; free-for-all collection pressure in co-op
- Loadout selection pre-map: tower set + weapon set + perk set
- 4 character classes, unique weapons per class
- 4-player co-op; co-op balance is the assumed mode; Unreal Engine 3; 2013

### Dungeon Defenders II
- 4 hero classes with non-overlapping tower types: Apprentice (magic turrets), Squire (barricades), Huntress (traps), Monk (auras)
- Mana = build currency; earned each wave; spent on placements and upgrades
- Loot: weapons, armour, accessories with stat rolls + reforge system; pet system
- Incursion modes: wave modifiers analogous to affixes
- 4-player co-op; difficulty scales with count; F2P; 2017

### Mindustry
- Factory → turret supply chain: ammo must be manufactured and conveyed to turrets
- Turrets are ammo-specific; choosing turret = committing to a supply chain
- Enemy pathfinder dynamically targets under-defended gaps
- Tech tree (research from items); two planet campaigns: Serpulo + Erekir (v7.0)
- Java on Arc (LibGDX fork); GPL-3.0 open source; multiplayer: co-op + PvP; 2017
