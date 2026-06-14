# Raw sources — roguelike batch 2
Ingested: 2026-06-14
Games: Spelunky 2, Dead Cells, Risk of Rain 2, Enter the Gungeon, Vampire Survivors
Wiki pages written to: wiki/games/roguelike/

---

## Spelunky 2

### Sources fetched
- https://en.wikipedia.org/wiki/Spelunky_2
- https://game-wisdom.com/analysis/spelunky-2
- https://spelunky.fandom.com/wiki/Cosmic_Ocean_(2)
- https://mossranking.com/cat_coop.php?cat=720

### Key facts extracted
- Developer: Mossmouth (Derek Yu) + BlitWorks (programming). Custom C++ codebase from Spelunky HD.
- Released PS4 Sep 15 2020, PC Sep 29 2020. Metacritic: PS4 87, PC 91, Switch 92.
- Procgen: Same 4×4 grid / room-template system as Spelunky 1, expanded template library per biome; branching at world-map level (player chooses Volcana vs Tide Pool after Dwelling).
- New mechanics: branching biome paths, backlayer parallel space, rideable mounts, liquid physics (water/lava/acid simulation), 19 unlockable characters in coffins.
- Cosmic Ocean: 94-level gauntlet (7-1 to 7-99); each level requires destroying 3 floating orbs to move a Celestial Jelly from the exit door; beating 7-99 creates a Constellation.
- 4-player online + local co-op; ghost jars allow revive; still fully lethal for all players.
- Difficulty notably harder than Spelunky 1 from floor 1; <10% Steam players reach credits (per game-wisdom analysis).

---

## Dead Cells

### Sources fetched
- https://en.wikipedia.org/wiki/Dead_Cells
- https://www.gamedeveloper.com/design/building-the-level-design-of-a-procedurally-generated-metroidvania-a-hybrid-approach-
- https://www.gametruth.com/guides/dead-cells-biome-progression-guide-routes-secrets-and-boss-cell-paths/
- https://medium.com/@tunganh0806/difficulty-as-design-dead-cells-progressive-challenge-and-player-engagement-74f086064bf6

### Key facts extracted
- Developer: Motion Twin (EA + 1.0 2018); post-launch by Evil Empire. Engine: Heaps.io (Haxe). CastleDB for room tile authoring.
- Hybrid procgen: fixed world map (biomes connect in predetermined ways), procgen within biomes via concept-graph-driven room chunk selection. Six-step process: fixed world → hand-designed tiles → concept graphs → algorithm assembly → monster placement → loot generation.
- Cells: per-run currency lost on death; spend to unlock blueprints with Collector at safe zone transitions. Blueprint must survive to transition or it is lost permanently.
- Boss Stem Cells (BSC): 1–5, each raises difficulty (enemy damage/HP/constellations, fewer flask recharges); BSC levels gate certain blueprints and biome paths.
- Three stats: Brutality (red), Tactics (purple), Survival (green). Weapons have color affinity + scale with matching stat. Scrolls raise one stat + bonus HP if color matches build.
- Colorless weapons (from Cursed Chests): scale with highest single stat; cursed = one-hit-kill until X enemies killed.
- Commercial: 730K first year, 2M by May 2019, 10M by June 2023. Multiple DLCs (Bad Seed, Fatal Falls, Queen and the Sea, Return to Castlevania).

---

## Risk of Rain 2

### Sources fetched
- https://en.wikipedia.org/wiki/Risk_of_Rain_2
- https://yeenlikestowrite.medium.com/risk-of-rain-2-roguelite-perfection-6a439f60e8f5
- https://riskofrain2.wiki.gg/wiki/Difficulty
- https://riskofrain2.wiki.gg/wiki/Level
- https://www.dualshockers.com/risk-of-rain-2-perfect-roguelike-introduction/

### Key facts extracted
- Developer: Hopoo Games. Engine: Unity (3D). IP acquired by Gearbox 2022; Hopoo founders joined Valve 2024.
- Released EA March 2019, full release August 2020. 1M copies in first month; 4M by March 2021.
- Supports up to 4-player co-op. Multiplayer scaling: shared money pool divided among players; difficulty bar rises faster with more players; initial difficulty is higher.
- Difficulty coefficient: rises continuously over time from the moment the run starts. Ambient level displayed top-right. Enemies scale HP/damage/aggression with coefficient.
- Teleporter: player must find, activate, and survive 90-second boss fight to advance. Stage gate and high-stakes moment.
- Items: no stacking cap; white/green/red/yellow/lunar/void tiers. Items stack on character model visually.
- Lunar Coins: persistent cross-run currency (rare enemy drops). Spend at Newt Altars to access Bazaar Between Time.
- Artifacts: run-wide toggle modifiers (Command = choose items; Glass = 500% dmg/10% HP etc.). Discoverable in stages.
- Run structure: 5 main stages (randomized from stage-slot pools) + final stage; fixed stage maps, no procgen layout — all variance from items + scaling.

---

## Enter the Gungeon

### Sources fetched
- https://en.wikipedia.org/wiki/Enter_the_Gungeon
- https://enterthegungeon.wiki.gg/wiki/The_Gungeon
- https://enterthegungeon.wiki.gg/wiki/Synergies
- https://enterthegungeon.wiki.gg/wiki/Chambers
- https://www.pcgamer.com/games/roguelike/as-enter-the-gungeon-celebrates-its-10th-anniversary-...

### Key facts extracted
- Developer: Dodge Roll (4 ex-Mythic Entertainment employees, debut game). Engine: Unity. Publisher: Devolver Digital.
- Released April 2016 PC + PS4. 3M copies by January 2020. Metacritic 82–87. Final free update "A Farewell to Arms" 2019.
- Five chambers: Keep of the Lead Lord → Gungeon Proper → Black Powder Mine → Hollow → Forge. True final floor: Bullet Hell (Lich boss, 3 phases). ~20 rooms per chamber.
- Rooms: hand-authored and playtested individually; procedurally assembled by a generator that selects from category-appropriate pools per chamber slot. Room categories: combat, shop, boss, secret — some at fixed positions.
- Dodge roll: brief invincibility frames; inspired by Ikaruga + Dark Souls. Core survival mechanic.
- Synergies: named item combinations with unique effects. Indicated by blue arrow + name in Ammonomicon. Formally named/expanded in Advanced Gungeons & Draguns update. Hundreds exist.
- Meta-arc: each of 4 characters has a "past" — killed by obtaining the Gun That Can Kill The Past and reaching the relevant floor. All 4 pasts unlocked → Bullet Hell accessible → Lich → Gungeon Master.
- Breach (hub): rescued in-dungeon NPCs return to set up shops/services. Relationship-progression layer.
- 2-player co-op (second player = Cultist character).

---

## Vampire Survivors

### Sources fetched
- https://en.wikipedia.org/wiki/Vampire_Survivors
- https://vampire-survivors.fandom.com/wiki/Arcanas
- https://vampire.survivors.wiki/w/Evolution
- https://goombastomp.com/vampire-survivors-snippet/
- https://www.kokutech.com/blog/gamedev/design-patterns/power-fantasy/vampire-survivors

### Key facts extracted
- Developer: Luca Galante (poncle), solo. Engine: GameMaker Studio 2. Inspired by Magic Survival (2019 mobile). Galante drew from gambling industry (slot machine feedback design).
- Released 2021 EA, 1.0 December 2022. 30K concurrent players by Jan 2022; peak ~68K CCU. Creator estimated £40M earned by Aug 2024. BAFTA 2023 Best Game + Game Design. Metacritic: PC 87, Xbox Series 95, iOS 91.
- Core mechanic: all weapons auto-attack on internal timers. Player input = movement only. Sessions 15–30 minutes; fixed-length stage ending with The Reaper at 30:00 (indestructible unless player holds Tiragisu item).
- Weapon evolution: weapon max level (usually 8) + specific paired passive item → boss chest at 10:00+ → evolved weapon. Qualitatively different behavior (not just stat bump).
- Unions: two weapons fuse into one. Both evolutions + unions can fill all 6 weapon slots.
- Arcana: 22 tarot-card modifiers. Unlock via char lv50 or surviving to 31:00 on certain stages. First selected at run start; two more from Arcana Chests at 11:00 and 21:00. Post-multiplier layer for expert builds.
- Meta-progression: gold coins (persist across deaths) → Powerup shop in main menu (permanent base stat boosts). New content unlocks via character level milestones and stage records.
- Enemy spawning: scripted escalation schedule per stage with randomized positions. No spatial procgen — fixed stage maps.
- Spawned "survivors-like" / "bullet heaven" sub-genre (Brotato, 20 Minutes Till Dawn, Halls of Torment, etc.).
