# Raw: Fighting Games Batch 1
Ingested: 2026-06-14
Pages fed: [[Street Fighter II]], [[Tekken 7]], [[Guilty Gear Strive]], [[Super Smash Bros Ultimate]], [[Mortal Kombat 1]]

---

## Sources consulted

### Street Fighter II
- https://en.wikipedia.org/wiki/Street_Fighter_II — release year, hardware (CPS-1), roster (8 chars), six-button layout, combos as accidental bug left in as "secret technique," legacy (25M US plays by 1994, EVO ancestry)
- https://screenrant.com/street-fighter-2-bug-best-combos-fighting-games/ — combo discovery story confirmed as CPS-1 animation glitch
- https://shmuplations.com/streetfighterii/ — 1991 developer interview with director Akira Nishitani; Final Fight was originally going to be SF2
- https://bitvint.com/pages/street-fighter — overview of CP System board specs and arcade legacy

### Tekken 7
- https://en.wikipedia.org/wiki/Tekken_7 — Unreal Engine 4, 51-character roster (Season 4), Rage System, Screw Attack, Power Crush, 12M+ copies sold
- https://www.eventhubs.com/news/2021/jun/12/tekken-rollback-netcode/ — Harada's full technical explanation: variable 0–5 frame input buffer, 3D vs 2D animation rollback visibility, PS4/Xbox One CPU/memory cap on rollback budget
- https://www.oneesports.gg/tekken/katsuhiro-harada-claims-tekken-7-already-has-rollback-netcode/ — Harada's claim of "3 frame rollback since launch"; community skepticism
- https://www.resetera.com/threads/the-biggest-lie-in-gaming-this-year-tekken-7s-rollback-frames-counter.623008/ — community analysis showing the "rollback frames" counter in-game is misleading; behavior matches delay-based

### Guilty Gear Strive
- https://en.wikipedia.org/wiki/Guilty_Gear_Strive — UE4, 15 base / 31 total roster, Wall Break, Roman Cancel, Best Fighting Game TGA 2021, 3M+ copies
- https://www.unrealengine.com/en-US/developer-interviews/how-guilty-gear--strive--hits-an-ultra-combo-with-groundbreaking-visuals-and-gameplay — UE4 cel-shading pipeline, 60fps/4K PS5, distinct Guilty Gear style vs imitation hand-drawn anime
- https://primagames.com/gaming/arc-system-works-interview-guilty-gear-strive-rollback-netcode — in-house rollback (not GGPO), designed from earliest planning stages, more issues than anticipated in testing
- https://dotesports.com/fgc/news/guilty-gear-strive-will-have-the-same-type-of-rollback-netcode-as-xx-accent-core-plus-r — confirms in-house type matching GGXXACPR approach
- https://www.eventhubs.com/news/2021/jan/29/guilty-gear-rollback-online-feature/ — producer comments on rollback strength; online training mode included

### Super Smash Bros Ultimate
- https://en.wikipedia.org/wiki/Super_Smash_Bros._Ultimate — 89 characters total (74 base), Spirits system, Stage Morph, 36M+ copies, developed by Sora Ltd. + Bandai Namco Studios
- https://www.inverse.com/gaming/smash-ultimate-rollback-netcode-vs-delay-based — Sakurai: "side effects were too big"; delay-based retained; wired connection recommended
- https://gamedev.net/forums/topic/708690-smash-bros-ultimates-netcode-doesnt-use-rollback-because-it-would-cause-too-many-side-effects/ — community technical discussion on why 4-player physics-heavy Smash state makes rollback expensive
- https://www.eventhubs.com/news/2023/may/22/smash-bros-online-sakurai/ — Sakurai 2023: online and Smash "not a good fit"; doubles down on user environment explanation
- https://www.ssbwiki.com/Directional_influence — DI mechanics, LSI, blue angle indicator visual feedback detail

### Mortal Kombat 1
- https://en.wikipedia.org/wiki/Mortal_Kombat_1 — Sept 19 2023, NetherRealm/WB Games, UE4, 22 base roster, Kameo system (15 fighters), Invasions mode, 8M+ copies
- https://twistedvoxel.com/mortal-kombat-1-unreal-engine-4-kameos-not-playable/ — confirms UE4; Kameos not independently playable; lore drives roster split
- https://www.eventhubs.com/news/2023/jun/28/mk1-stress-test-tech-breakdown/ — Digital Foundry stress-test confirms UE4 base with custom rendering adaptations
- https://www.theloadout.com/mortal-kombat-1/rollback-netcode — rollback confirmed on PS5/XSX/PC; Switch absent at launch
- https://www.psu.com/news/mortal-kombat-1-ps5-rollback-netcode-confirmed/ — PS5 rollback confirmation pre-release

---

## Key themes extracted

1. **Rollback netcode trajectory:** SF2 (no netcode) → Tekken 7 (contested delay-hybrid) → Strive (in-house true rollback, watershed moment) → MK1 (rollback as new standard on capable hardware)
2. **3D vs 2D rollback cost:** Tekken/Smash both identify that smooth 3D animation and/or complex multi-actor game state make visual rollback jarring or computationally expensive
3. **Accessibility without dilution:** Strive's wall break + simplified inputs + no ranked mode expanded the player base while retaining expert ceiling; transferable to Wayfinder's combat design
4. **Live service layer over fighting games:** MK1 Invasions shows seasonal boardgame overlay as retention tool — a direct parallel to Wayfinder's chart loop concept
5. **Roster as value proposition:** Smash Ultimate's "everyone is here" and Tekken 7's 51-character depth are extreme cases of roster breadth as core marketing; Wayfinder's party-role system is the co-op analog
