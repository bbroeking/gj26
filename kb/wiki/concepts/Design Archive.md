---
type: concept
tags: [archive, superseded, design-history, three-js, prototype]
status: draft
updated: 2026-06-13
sources:
  - "docs/DESIGN_VISION.md"
  - "docs/rune-magic-design.md"
  - "docs/cartography-skill-explorations.md"
  - "docs/cartography-keystone-design.md"
  - "docs/cartography-inscribing-table-design.md"
  - "docs/cartography-inscribing-table-ux-prompts.md"
  - "docs/design/05-boss-design.md"
  - "docs/design/05a-hedgemother-bramble-pull.md"
  - "docs/design/06-equipment-progression.md"
  - "docs/design/07-skill-level-pacing.md"
  - "docs/design/09-active-abilities.md"
  - "docs/design/10-spell-system.md"
  - "docs/design/cartography-depth-20.md"
  - "docs/design/cartography-keystone.md"
  - "docs/design/skills-consolidation.md"
  - "docs/design/town-layout-plan.md"
  - "docs/design/whats-next-research.md"
  - "docs/design/_progress.md"
  - "docs/skills/falconry.md"
  - "docs/skills/magic.md"
---

# Design Archive

A curated record of superseded, cut, and deferred design decisions from the Wayfinder project. These ideas shaped the current design or illuminate why the current shape was chosen. The originals are preserved here so the source docs can be safely removed or archived. Nothing in this page reflects current design — see [[Current State]] and [[Design Decisions]] for what the game does today.

---

## 1. The three.js Prototype (DESIGN_VISION.md)

**Idea.** `docs/DESIGN_VISION.md` (locked 2026-04-29, status "v3 in flight") described a browser-native toon RPG running on vanilla three.js + Vite. The pitch was "Stardew Valley meets RuneScape, in your browser." The design had a OSRS-lineage skill list (Woodcutting, Fishing, Cooking, Attack) plus a RuneScape-style click-to-attack tab-target combat system, six named NPCs with a 5-heart relationship system, a 12-minute real-time day cycle, localStorage save, and a single zone called Lumbridge Plains.

**Status: superseded.** The entire three.js codebase was removed 2026-06-12 (lives in git history). The engine move to Godot 4.6 was decided 2026-05-20; the pivot to cozy-skilling-as-spine was locked 2026-05-29 (ADR 0003).

**Why superseded.** The "Stardew meets RS" browser pitch was replaced by a more focused identity: a cozy fairytale dungeon-crawler where the [[Chart Loop]] is the spine and combat is one verb. The day cycle, NPC hearts, and seasonal calendar were deferred as scope not central to the differentiator. The skill list was completely redesigned (see §3 below).

**What replaced it.** The Godot project in `wyrd/`, the [[Wayfinding]] trade as the progression keystone, [[Bramblewood]] as the setting (replacing "Lumbridge Plains"), and the [[Chart Loop]] as the primary content loop.

---

## 2. Rune Magic and the Magic Skill

### 2a. The rune-magic design doc

**Idea.** `docs/rune-magic-design.md` proposed a full RuneScape-flavored magic system: 13 rune types (Air/Water/Earth/Fire/Mind/Body/Chaos/Cosmic/Law/Nature/Death/Blood/Soul), 21–22 spells across 3 tiers, a separate `magic` skill leveled by casting, and a Runestone Pedestal crafting station. Runes were made by pressing inks into rune-stones at the Pedestal using chant scrolls dropped by dungeons. The doc explicitly framed runes as "inks made permanent" — a one-step extension of the Cartography ink pipeline. Integration points included a rune slot baked into charts at Carto 50 + Magic 30.

**Status: cut (combat branch) / partly-live (infrastructure).** The full magic-as-separate-skill system was cut when [[Design Decisions|ADR 0003]] established "combat is one verb." The Runestone Pedestal exists in the three.js codebase but was not ported to Godot. The ink-to-rune mapping and rune-slot-in-chart concept survived as [[Charts|chart affix infrastructure]] in the current Godot build.

**Why cut.** A standalone Magic skill with its own gather/craft/cast loop would double the surface area of the game. The cozy-skilling-as-spine decision (ADR 0003) means all skill loops funnel through Cartography, not alongside it.

**What replaced it.** Rune slots in charts (baked passive at Carto 50 + Magic 30) survive as a cross-skill hook. The `magic` skill entry exists in the Godot codebase but as a catalog/stub, not an active loop.

### 2b. The spell-system audit (docs/design/10-spell-system.md)

**Idea.** The three.js codebase shipped `src/game/spells.js` with scaffolding for 21 spells and `src/ui/spellbook.js`. The design doc `docs/design/10-spell-system.md` audited these and found only 8 of 21 spells were fully wired; 13 were broken to varying degrees (4 "state-only" with no reader, 8 explicit stubs, 1 runtime bug). The doc recommended capping the v1 catalog at 8–10 spells and demoting the rest to v2.

**Status: superseded.** The three.js codebase (including `spells.js`) was removed. The Godot port does not include a spell system.

---

## 3. The Old OSRS-Style Skill List

### 3a. 13-skill list (skills-consolidation.md)

**Idea.** The three.js prototype had 13 skills: `atk str def hp cook wc fish mine smith forage carto falconry magic`. This was an explicit OSRS lineage — one skill per verb, each with its own XP track and level-gate milestones.

**Status: superseded.** `docs/design/skills-consolidation.md` (2026-05-04) formally merged the five gathering skills into two umbrella skills (`wilds` = forage+fish+wc; `earth` = mine+smith), bringing the total to 10. Then the engine move and ADR 0003 pivot superseded even those 10 in favor of the four-Trade model in the Godot build.

**What replaced it.** The four [[Trades and Leveling|Trades]] of the current game: [[Wayfinding]] (cartography), [[Earthcraft]] (earth/forge), [[Wildcraft]] (wilds/foraging), [[Huntcraft]] (combat). "Skill" in the current game's vocabulary means hotbar abilities only, not leveling disciplines.

### 3b. Falconry as a standalone skill

**Idea.** `docs/skills/falconry.md` documented a `falconry` skill with Pernel the falcon as a companion gained from Sir Withering's quest. Three milestones: Lv 1 (Pernel), Lv 15 (sight +2), Lv 30 (combat assist swoop). The skill was described as "the smallest gameplay surface of any skill — by design, a cozy companion." Only Pernel's persistent companion and partial sight-range overlay were shipped in the three.js build.

**Status: superseded.** Falconry as a distinct leveling discipline was superseded by the Trade redesign. In the current Godot build, the falcon companion concept may survive as a [[Wildcraft]] unlock or quest reward, but not as an independent Trade.

### 3c. Skill-level pacing research (docs/design/07-skill-level-pacing.md)

**Idea.** The doc audited the three.js `xpForLevel(n) = (n-1)² × 8` curve (quadratic, not OSRS-exponential). Key finding: Lv 99 was reachable in ~236h of pure-combat grind; Lv 25 took ~3.6h. The doc recommended capping at 25, raising the early-level coefficient to slow Lv 1–5, and defining 3 milestones per skill. Three candidate curves were proposed: current `(n-1)²×8`, a `×12` bump, and a "linear floor" variant `(n-1)²×8 + (n-1)×40`.

**Status: deferred.** The curve analysis was never applied in the three.js build. The Godot build has its own progression system. The research findings (avoid pure quadratic, set a level cap well below 99, 3–5 milestones per skill) remain valid design principles.

---

## 4. Cartography — Early Design Explorations

### 4a. Cartography Keystone Design (cartography-keystone-design.md)

**Idea.** An early design doc for the Cartography skill as a WoW Mythic+-style keystone system. It specified a full affix list (~25 affixes across bias/modifier/boss/pacing/risk/atmosphere categories), 7 chart templates (Snug through Summit), a completion-XP formula (`tier×30 + good_affixes×25 + bad_twins×5`), and the good/bad-twin gambit mechanic (stability% determining good vs. bad-twin landing). This was the foundation for the current chart system.

**Status: partly-live.** The affix categories, good/bad-twin design, chart templates, and XP formula were all ported to the Godot build. The specific affix list has evolved (see `wyrd/data/affixes.gd`). The "keystone" framing has been replaced by "chart" throughout (per domain language in `CONTEXT.md`).

**What replaced it.** The live system is documented in [[Charts]] and [[Affixes]].

### 4b. Cartography Skill Explorations (cartography-skill-explorations.md)

**Idea.** A wide exploration doc covering: 6 alternative survey verbs (rhythm-based Pace Step, active-aim Theodolite, dead-reckoning compass, sketch slider, memory palace two-phase, consumable Geomancer's Stake); 3 sketch decay models (real-time vs game-time vs copy-pressure erosion); multiplayer hooks (Chart Trading Post, share codes, NPC guild leaderboard); accessibility modes; cross-skill bleed (minimap glow for sketched flora, combat telegraph bonus for sketched enemies, ore hints for sketched veins); narrative hooks (Lost Cartographer quest, Cartographer's Curses, Master Atlas village artifact); and wild ideas (drawing minigame, borrowed NPC sketches, anti-cartography Forgotten Map).

**Status: superseded / deferred.** The survey verb was not carried forward — the current game's Cartography is centered on the inscribing table and chart dungeon loop, not a field-survey mechanic. Most cross-skill bleed concepts (minimap flora glow, combat telegraph bonus) were rejected or deferred. The Lost Cartographer quest and village atlas artifact were noted "worth shipping later." Share codes survive as a design seed (chart seeds, #8 in cartography-depth-20.md).

**What replaced it.** The current [[Wayfinding]] trade focuses on the five-station craft loop (inscribing table → pedestal → charting → dungeon → atlas tick) rather than field-surveying.

### 4c. Inscribing Table Design (cartography-inscribing-table-design.md)

**Idea.** A detailed design doc for a two-tier alchemical crafting system: Tier 1 = a 3×3 grid where ingredient position/pattern determines which ink is produced (15 ink recipes across 5 pattern shapes — singleton, vertical line, cross, X-corners, T-shape, L-shape); Tier 2 = inks dropped into ink-slots on a chart template to bias affix-roll weights. The doc included a full reagent catalog (20 ingredients across 4 essence types: verdant/earthen/sanguine/lumen), a Recipe Codex discovery loop, mastery unlocks (auto-arrange at Lv 25, all commons known at Lv 75, extra ink slot at Lv 99), and 10 Midjourney UI prompts.

**Status: partly-live.** The two-tier ink-then-chart structure, the affix-bias model (inks shift roll weights), and the 4-essence ingredient categories were all ported to the Godot build. The specific 3×3 grid UI and pattern-based recipe system are the current inscribing table implementation. The Recipe Codex and mastery unlocks (auto-arrange) were partially implemented. The specific reagent catalog and Midjourney prompts are superseded by the live `wyrd/data/` item definitions and [[Concept Art Prompts]].

### 4d. Inscribing Table UX Prompts (cartography-inscribing-table-ux-prompts.md)

**Idea.** 8 Midjourney prompts for specific UX interaction moments of the inscribing table: empty-first-open, mid-experiment, recipe-matched, hover-ghost, inscription-success, smudge-recovery, codex-three-tabs, auto-fill-flow. Used a locked stem for parchment/watercolor style and `--sref` to an image anchor for consistency across the batch.

**Status: superseded.** These were for the three.js browser UI, not the Godot UI. The visual style locked by these prompts (parchment, watercolor, sepia) informed the [[Art Bible]] but the specific Midjourney prompts are not reusable in Godot's canvas UI system.

### 4e. Cartography Depth-20 Backlog (design/cartography-depth-20.md)

**Idea.** A tagged backlog of 20 ideas to deepen the Cartography skill: themed chart families (#1), boss charts/Wardens (#2), Echo Charts (#3 — overworld inversion), layered multi-floor charts (#4), decaying charts (#5), survey verb (#6), Cartographer's Atlas codex (#7), chart seeds/sharing (#8), cursed charts (#9), folded charts (#10), NPC-signed charts (#11), dynamic daily wheel (#12), inkwell vessels (#13), map fragments from elites (#14), constellation charts (#15), master keys at Lv 99 (#16), annotated charts (#17), reverse cartography Mirror NPC (#18), personal cartographer's signature (#19), living atlas meta-map (#20).

**Status: partly-live / deferred.** The top recommended triad (#7 Atlas, #11 NPC-signed, #1 Themed families) informed the current Living Atlas feature. Echo Charts (#3) was implemented as a Lv 35+ Carto unlock. Inkwell Vessels (#13) became the vessel commission system at Carto 30. Chart seeds (#8), daily wheel (#12), decaying charts (#5), folded charts (#10), and annotated charts (#17) remain deferred backlog. The living atlas meta-map (#20) is live. Survey verb (#6) and constellation charts (#15) are deferred.

### 4f. Cartography as the Keystone Skill doc (design/cartography-keystone.md)

**Idea.** A design framing doc arguing that Cartography should be reframed from "one of 10 skills" to "the player's progression spine," because it's the only skill that (1) consumes outputs from every other skill, (2) produces the only on-demand content (charts as dungeons), and (3) has the most ingredients-per-output ratio. Proposed a unified Cartography Workshop UI replacing three scattered modals, a HUD 📐 button, modal breadcrumbs, and a session-sketch counter.

**Status: live.** The Cartography Workshop UI was implemented (see `wyrd/scripts/ui/cartographyWorkshop.gd`). This framing is now the current design — Wayfinding is the keystone Trade.

---

## 5. Boss Design — Three.js Boss Mechanics

### 5a. Boss design doc (docs/design/05-boss-design.md)

**Idea.** A research and design doc auditing the three.js boss infrastructure (Hedgemother, Burrow Boar, Wolf Alpha — all in `src/game/enemies.js`). Found that three bosses shared the same phase-2 frenzy scaffold; only Hedgemother had a unique mechanic (`parryOnly`). Proposed differentiating the three with one unique mechanic each: Hedgemother bramble-vine root pull, Burrow Boar burrow/emerge-charge, Wolf Alpha phase-2 pack-summon. Referenced Hades, Hollow Knight, OSRS, and Cult of the Lamb as design models.

**Status: superseded.** The three.js codebase was removed. The Godot build has boss entities defined differently. The *design principles* (3 attacks max per phase, every attack has a counter-window, one new mechanic per boss, prep loop before the fight) are relevant to [[Bosses]].

### 5b. Hedgemother Bramble-Pull (docs/design/05a-hedgemother-bramble-pull.md)

**Idea.** A detailed code sketch for the Hedgemother's phase-2 bramble-vine pull mechanic in the three.js codebase: a warm-green-amber telegraph line from boss to player, 0.85s windup, 2-tile pull + 1s root on resolution, negated by dodge i-frames or stepping off the line. ~50 lines of JS in `src/game/enemies.js` + helpers in `player.js` and `main.js`. Noted a tonal open question: does a forced-pull feel appropriate for a cozy fairytale tone?

**Status: superseded.** The three.js codebase was removed. The mechanic concept (anti-kite pull + root as a phase-2 counter to ranged kiting) is worth preserving for the Godot [[Bosses|Hedgemother fight]] design.

---

## 6. Equipment Progression Explorations

**Idea.** `docs/design/06-equipment-progression.md` audited the three.js equipment system (22 items, 3 tiers: Brindle/Bogiron/Cinderbloom; sword/dagger weapon classes). Found the progression was "vertical only" — linear +50% stat scaling with no meaningful horizontal differentiation. Surveyed techniques from OSRS (combat-style toggle), Diablo 2 (random affixes), Hades (weapon aspects), Cult of the Lamb (trinket slot), Stardew (named endgame weapons). Proposed: differentiate weapon classes by attack-speed vs damage trade-off (dagger = faster/lighter, axe = slower/AoE), wire the AFFIXES system to weapons (5 random weapon affixes), add a trinket slot and one tier-4 named weapon as quest rewards.

The design also implemented weapon-class differentiation in the three.js build: sword (`cdMul=1.0, dmgMul=1.0`), dagger (`cdMul=0.75, dmgMul=0.80`) via a `weaponMods()` helper in `src/game/combat.js`.

**Status: superseded.** The three.js codebase was removed. The item tier ladder concept (materials gate weapon tiers), weapon-class differentiation principle (speed vs damage trade-off), and horizontal progression discussion (trinket slot, named endgame weapons) are all relevant to [[Items and Gear]] in the Godot build.

---

## 7. Active Abilities — Slot-Binding Rebalance

**Idea.** `docs/design/09-active-abilities.md` audited 12 abilities in the three.js `src/game/abilities.js` (cleave, rend, whirlwind, leap, shield_bash, defensive_stance, sunder, bull_rush, backstab, aimed_shot, riposte, last_stand) across 4 trees (atk/str/def/hp). Found that default `SLOT_BINDINGS` was all-atk-tree, hiding 8 of 12 abilities behind the rebind UI on fresh saves. The atk tree had 6 abilities; str had 2; def had 3; hp had 1. Shipped: rebalanced defaults to one-per-tree (cleave/shield_bash/bull_rush/last_stand). Proposed adding 2–3 more abilities to underrepresented trees and weapon-bound slot-1 specials (Hades pattern).

**Status: superseded.** The three.js codebase was removed. The design principle (expose tree breadth by default; weapon-bound slot 1, skill-bound slots 2–4) is relevant to the [[Skills]] hotbar design in Godot.

---

## 8. Skill-Level Pacing and XP Curve Research

*(Summarized in §3c above. Additional detail preserved here.)*

**Cross-skill bleed model.** The skills-consolidation doc (`docs/design/skills-consolidation.md`) specified a 10-skill architecture with XP routing: every gathering action that previously awarded a sub-skill now awards the umbrella skill (`wilds` or `earth`). The consolidation kept a migration helper for existing saves. This model was superseded by the Trade system but its XP-routing pattern (pool sub-verb XP into one umbrella track) is used in the Godot Trades.

---

## 9. Town Layout Plan

**Idea.** `docs/design/town-layout-plan.md` designed a coherent Bramblewood village layout on a 60×30 tile map with the village footprint at ~30×16 tiles. Prior state was "scatter, not layout" — Maud's hut isolated 10 tiles NW, no buildings drawn for other NPCs. The plan used Christopher Alexander's *A Pattern Language* (small public squares, activity pockets), Stardew Valley's Pelican Town, and OSRS Lumbridge as references. Proposed: spawn = village green at center, critical NPCs visible from spawn, functional grouping (cooking+forge share fire, herbalist+cartographer share workshop quarter), hedge/fence village boundary, wilderness pull east toward goblins. Specified tile coordinates for each NPC/building slot and a critical-path walk for a new player's first 10 minutes.

**Status: superseded.** The three.js tile-map system was removed. The Godot build uses a 3D world built in Godot scenes, not a 2D tile map. However, the **layout principles** (spawn = readable center, NPCs grouped by function, clear village edge, path east to danger) directly inform the current Godot town scene in `wyrd/scenes/Town.tscn`.

---

## 10. Whats-Next Research Synthesis

**Idea.** `docs/design/whats-next-research.md` (April 2026 state) scored the three.js prototype on seven ARPG-feel pillars (average 6.6→7.1 after that session's pass) and identified key gaps: loop bounce at minute 30 (what's the second hour?), thin reward density (no drop physics, no rarity color, no loot magnetism), absent ambient music, generic bosses (only Hedgemother differentiated), post-tutorial void (no quest tracker, no milestone celebrations), and equipment depth holes (no trinket slot, no named weapons, no combat-axe family). Recommended in priority order: loot juice pass, two more boss mechanics, ambient music per zone.

**Status: superseded.** Written against the three.js build, which was removed. The gap analysis findings (reward density, ambient audio, boss differentiation, post-tutorial guidance) remain relevant design challenges for the Godot build and are reflected in the current [[Design Decisions]] and [[Balance Philosophy]] pages.

---

## See also

- [[Design Decisions]] — ADRs that canonically closed the questions this archive tracks
- [[Chart Loop]] — the live loop that replaced the three.js day-cycle loop
- [[Charts]] — current chart/affix system that evolved from §4a/4c above
- [[Affixes]] — live affix list and good/bad-twin mechanic
- [[Wayfinding]] — the Trade that replaced Cartography-as-skill
- [[Trades and Leveling]] — how the four-Trade model superseded the 13-skill list
- [[Bosses]] — current boss design, informed by §5a/5b
- [[Items and Gear]] — current equipment progression, informed by §6
- [[Skills]] — current hotbar ability system, informed by §7
- [[Inks]] — live ink catalog evolved from the inscribing table design
- [[The Crafting Bench]] — current Godot implementation of the inscribing table
- [[Combat]] — one-verb combat model that cut the rune-magic system

## Sources

- `docs/DESIGN_VISION.md`
- `docs/rune-magic-design.md`
- `docs/cartography-skill-explorations.md`
- `docs/cartography-keystone-design.md`
- `docs/cartography-inscribing-table-design.md`
- `docs/cartography-inscribing-table-ux-prompts.md`
- `docs/design/05-boss-design.md`
- `docs/design/05a-hedgemother-bramble-pull.md`
- `docs/design/06-equipment-progression.md`
- `docs/design/07-skill-level-pacing.md`
- `docs/design/09-active-abilities.md`
- `docs/design/10-spell-system.md`
- `docs/design/cartography-depth-20.md`
- `docs/design/cartography-keystone.md`
- `docs/design/skills-consolidation.md`
- `docs/design/town-layout-plan.md`
- `docs/design/whats-next-research.md`
- `docs/design/_progress.md`
- `docs/skills/falconry.md`
- `docs/skills/magic.md`
