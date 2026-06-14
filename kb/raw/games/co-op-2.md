# Raw sources: co-op batch 2
# Generated: 2026-06-14
# Games: Monster Hunter Rise, Phasmophobia, Among Us, Lethal Company, Palworld

---

## Monster Hunter Rise

**Wikipedia:** https://en.wikipedia.org/wiki/Monster_Hunter_Rise
- Released March 26, 2021 (Nintendo Switch). Director: Yasunori Ichinose. Published by Capcom.
- 1–4 players online co-op; single player uses two companion creatures (Palico/Palamute); online uses one.
- 14 weapon types, each with unique moveset. Wirebug adds weapon-specific aerial moves.
- Hub quests (multiplayer tier) distinct from Village quests (solo campaign); HP/resistance scales per additional hunter.
- PS5/Xbox Series X: 4K/60fps (120fps option); no cross-play between Switch and PC/console families.
- NPLN (Nintendo's new middleware replacing NEX) tested during the demo; handles auth/matchmaking/presence only.
- Underlying netcode is P2P: one player hosts, no dedicated servers, relay support on some platforms.

**Game Rant — Co-op analysis:** https://gamerant.com/monster-hunter-rise-co-op-good/
- "Wordless synchronization" in 10–20 minute hunts.
- Greatsword: tail sever + big wake-up hit; Hammer: partbreak + KO; Hunting Horn: support buffs; Insect Glaive: mobility.
- Specialist builds enabled by co-op (e.g. status-effect Hammer).
- "Lifepowders or Dust of Life" distribute heals to full party.
- Difficulty scales per player joining (not flat 4x).
- "Playing with two hunters is no more difficult than any other number" — encourages immediate multiplayer.

**Game Rant — 8 Things:** https://gamerant.com/monster-hunter-rise-things-to-know-about-co-op/
- Three carts (deaths) shared across the party.
- PC/PlayStation/Xbox have native voice chat; Switch does not.
- Hunter Connect feature for persistent group codes.

**Game8 — Sunbreak Scaling:** https://game8.co/games/Monster-Hunter-Rise/archives/322653
- Monster HP/resistance increases with each additional hunter in Hub quests.
- Status ailments require more hits in multiplayer.

**ResetEra — NPLN article:** https://www.resetera.com/threads/nintendo-is-replacing-its-decade-old-multiplayer-server-system-nex-with-npln-in-preview-phase-with-the-monster-hunter-rise-demo-testing-server-load.371361/
- NPLN = new Nintendo networking middleware (spotted in Rise demo executable).
- Replaces NEX (a decade-old system). Handles auth, matchmaking, presence, data storage.
- Not a netcode improvement — underlying session transport unchanged (P2P).

---

## Phasmophobia

**Wikipedia:** https://en.wikipedia.org/wiki/Phasmophobia_(video_game)
- Early access September 18, 2020 (Windows). Developer: Kinetic Games (UK, solo developer at launch).
- Console versions: PS5/Xbox Series X/S — October 2024. Nintendo Switch 2 — 2026.
- 1–4 players co-op. Built on Unity.
- 27 ghost types, each with 3-piece evidence combination from 7 evidence types.
- Speech recognition engine: ghosts and Spirit Box respond to actual player voice.
- Players can be inside building or monitor from van via CCTV.

**Driffle review:** https://driffle.com/blog/phasmophobia-review-a-deep-dive-into-ghost-hunting-horror/
- Became 6th-most-watched Twitch game Oct 2020; top Steam seller Oct–Nov 2020.
- Ghost-hunting equipment: Spirit Box, EMF Reader, Thermometer, Night Vision Cameras.
- Evidence recorded in in-game journal.

**Phasmophobia Wiki — Evidence:** https://phasmophobia.fandom.com/wiki/Evidence
- 7 evidence types: EMF Level 5, D.O.T.S. Projector, Ultraviolet (fingerprints), Ghost Orb, Ghost Writing, Spirit Box, Freezing Temperatures.
- Standard: collect 3; Nightmare: 1 hidden; Insanity: 2 hidden.
- Ghost behaviors/hunt triggers independent of evidence.

**Soren — 2026 Roadmap:** https://soren.com/en/news/phasmophobia/2026-01-31-phasmophobia-2026-roadmap-the-path-to-version-10
- Full Unity 6 migration planned for 1.0.
- Total netcode rewrite — current P2P netcode causes ghost desyncs, laggy hunt sequences.
- Dedicated relay infrastructure expected post-rewrite.

**Co-Optimus listing:** https://www.co-optimus.com/game/7473/pc/phasmophobia.html
- Confirmed 4-player online co-op. No couch co-op.

---

## Among Us

**Wikipedia:** https://en.wikipedia.org/wiki/Among_Us
- Released June 15, 2018 (iOS/Android), November 16, 2018 (Windows). Developer: Innersloth (3-person studio).
- Nintendo Switch: December 2020. PlayStation/Xbox: December 2021.
- 4–15 players. Up to 3 Impostors depending on player count/host settings.
- Crewmates complete tasks (minigames/puzzles/toggles); Impostors kill and sabotage.
- Additional roles post-launch: Engineer, Scientist, Guardian Angel, Shapeshifter, Phantom, Detective, Tracker, Noisemaker, Viper.
- Maps: Skeld, Mira HQ, Polus, The Airship.
- Cross-platform play across all platforms.
- Free Amazon servers buckled during Oct 2020 surge.

**Game Developer — social deduction design:** https://www.gamedeveloper.com/design/from-mafia-to-among-us-can-social-deduction-evolve-as-online-multiplayer-
- "Can an informed secret minority manipulate the uninformed majority?"
- Key design: shorter discussion phase limits toxic play; spatial visual map anchors claims.
- Success tied to external Discord/Twitch voice, not in-game chat.
- Simplicity of processing made it shareable/streamable.

**Among Us Protocol (roobscoob):** https://github.com/roobscoob/among-us-protocol/blob/master/README.md
- Custom P2P protocol called Hazel.
- UDP on ports 22023–22923.
- SendOption types: 0x00 Normal (unreliable), 0x01 Reliable, 0x08 Hello, 0x0c Ping.
- Innersloth supported the reverse-engineering writeup.

**Mechanics of Magic — critical play:** https://mechanicsofmagic.com/2024/04/06/among-us-critical-play-of-social-deduction/
- Social deduction mechanics, voting analysis, role system breakdown.

---

## Lethal Company

**Wikipedia:** https://en.wikipedia.org/wiki/Lethal_Company
- Early access October 23, 2023 (Windows/Steam). Developer: Zeekerss (American, solo).
- Up to 4 players co-op. Proximity voice/text chat.
- 12 moons, procedurally-arranged facilities (factory/mansion/mine).
- 4-item carry limit; two-handed items prevent climbing.
- 3-day quota deadline; sell at 71-Gordion; increasing quota over time.
- Ship's midnight autopilot departs stranding late players.
- Reached 100k concurrent players November 2023.

**Lethal Company Wiki:** https://lethal-company.fandom.com/wiki/Lethal_Company
- Monster types: Bracken (retreats from eye contact, hunts when ignored), Jester (invincible, hunts after winding up), Hoarding Bug (passive near loot), Thumper, Spore Lizard.
- Weather hazards: fog, quicksand, lightning, flooding, eclipses, meteor showers.
- Terminal: moon navigation, equipment purchase, CCTV, door/trap controls.

**Lethal Modding Wiki — Networking:** https://lethal.wiki/dev/advanced/networking
- Unity Netcode for GameObjects (NGO).
- Host-authoritative: host/server owns all state; only host can spawn network objects.
- ClientRpc (server→client) and ServerRpc (client→server, RequireOwnership=false).
- SampleSceneRelay (ship) scene persists; objects destroyed on disconnect.
- No dedicated server; no host migration.

**The Tartan review:** https://the-tartan.org/2023/12/10/lethal-company-review-a-co-op-of-horror-and-fun/
- Emergency co-op comedy from panic-driven decisions.
- Walkie-talkies as spatial communication layer between inside/outside.

**Steam discussion — netcode:** https://steamcommunity.com/app/1966720/discussions/0/4034728517977094473/
- Community-documented P2P host model; host drop ends session.

---

## Palworld

**Wikipedia:** https://en.wikipedia.org/wiki/Palworld
- Early access January 19, 2024 (Windows/Xbox). Developer: Pocketpair (Tokyo, Japan).
- 2 million concurrent Steam players by January 24, 2024. 32 million players across platforms as of Feb 2025.
- Unreal Engine 5 (migrated from Unity). Open-world.
- P2P co-op: up to 4 players. Dedicated server: up to 32 players (capped, setting >32 silently clamps to 32).
- Cross-platform (Steam + Xbox) added March 2025.
- Pals captured via combat-and-Pal-Sphere mechanic. Also tradeable between players.
- Bases as fast-travel hubs; Pals auto-complete assigned tasks.

**Game Developer — automation mechanic:** https://www.gamedeveloper.com/design/pocketpair-ceo-palworld-owes-its-success-to-automation-mechanics
- CEO Takuro Mizobe: automation (assigning Pals to factories) is the core engagement driver.
- Watch-the-factory-run dopamine loop.

**Dexerto — co-op details:** https://www.dexerto.com/gaming/palworld-multiplayer-co-op-2481417/
- 4-player P2P or 32-player dedicated server.
- Shared exploration, dungeons, Pal-catching, base-building.
- XP shared; only one player can capture a boss Pal per encounter.

**Game Informer — Raid boss update:** https://gameinformer.com/news/2024/04/04/new-palworld-update-includes-first-raid-boss-pal-and-base-changes-and-more
- April 2024 update: first raid boss added.
- Summoning Altar triggers raids. Boss Pals resist capture.
- "Extreme" difficulty variant described as "incredibly powerful."

**Valebyte — dedicated server:** https://valebyte.com/en/blog/palworld-dedicated-server-from-installation-to-anti-cheat/
- Hardware: 16 GB RAM min (32 GB recommended), 4 cores at 3.5 GHz+, NVMe 40 GB+.
- Single-thread bound (Unreal limitation). Progressive RAM growth under load.
- UDP/TCP ports required. Anti-cheat via EasyAntiCheat.

**Sportskeeda — raids:** https://sportskeeda.com/mmo/palworld-raids-everything-need-know
- Raid Pals cannot be captured. Requires coordinated team + Pal squad.
- Defeat credit shared; kill XP shared.
- Post-game raid bosses at Summoning Altars.
