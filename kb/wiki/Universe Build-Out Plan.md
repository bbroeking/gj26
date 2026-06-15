---
type: overview
tags: [plan, universe, roadmap, design, build-out]
status: maintained
updated: 2026-06-14
sources: ["kb/wiki/research/MMO Lessons for Wayfinder.md", "kb/wiki/games/Game Index.md", "docs/WORLD_BIBLE.md", "docs/WORLD_LORE.md"]
---

> Produced by a multi-agent planning workflow (mine KB → 4 framings → judge panel → synthesize → adversarial critic). Winning framing scored 87/100; grounded against the live codebase by the critic. See [[Game Studies]] / [[MMO Research]] for source ideas.

# The Wolds Remembered — A Pillar-by-Pillar Build Plan for Wayfinder

*Lead designer's final plan to grow the demo into a complete, realized cozy-fairytale dungeon-crawler set in Bramblewood. Single-player and 2–4 co-op. The next demo is hard-cut to two pillars; the rest of the game is a named horizon, not a specced commitment. Honest about a tiny team on an AI asset pipeline — and honest about what the codebase already ships.*

---

## 0. What the code already ships (read this first)

This revision is built on the actual current state, verified in source. Three earlier-draft premises were wrong and are corrected here so step 1 is not a spec built on a misread:

- **Save versioning exists and is destructive.** `save_game.gd` already writes a `VERSION` field (line 11/15) and checks it on load (line 53). On mismatch it **discards the save** ("version mismatch — starting fresh", line 54). There is also an ad-hoc backfill for the Huntcraft key (lines 70–72, per ADR 0005). The real defect is **no migration path** — a destructive reset. The work is "replace the reset with a migration ladder," **not** "add a version field." (This corrects every place the earlier draft said "there is no save versioning.")

- **Briar Maze is a shipped, balance-tuned tier-2 template.** `charts.gd` defines `briar_maze` (tier 2, `req_carto 15`, its own `gen` block) inside `TEMPLATE_ORDER`, with a dedicated spawn table (`bramble_imp/hedge_sprite/skitterling`) in `layout_loader.gd`. It is **not invented.** Deleting it to "replace" it with a new region would re-level a tested template — exactly the churn ADR 0006 forbids. The honest move is to **keep Briar Maze's mechanics and re-skin/re-name** if we want a marsh fiction, not to claim it was a mistake.

- **The Boar and the Wolf are modeled, wired, and chained.** `layout_loader.gd` `BOSS_KINDS` loads `burrow_boar_v3.glb` and `wolf_alpha_v2.glb` with full stat blocks and trophies; the affix comment states the shipped chain explicitly: **elites → Hedgemother → Boar → Wolf → the Summit.** These are not free bosses to discard — they are the spine of the existing trophy chain and the region map must house them.

- **The "Hedgemother Queen" is the same being, not a second boss.** The shipped `hedgemother_queen` boss key reuses `hedgemother_v2.glb` scaled from 3.75 → 4.6, commented "Same silhouette the player learned at level 8, scaled into a monarch." WORLD_LORE is explicit: *"The Hedgemother is the largest threat in the world. There is no Worse Bramble. There is no King of Brambles."* So the Summit is **the Hedgemother at her deepest — the same Onywyn-in-the-bramble — not a bigger Queen above her.** This plan treats it as such everywhere; "Queen" is the form she takes at the bottom of the chain, not a separate, larger creature. Reifying her into a distinct capstone monster would be the exact escalation P6 forbids.

- **The seams that make biome-swapping cheap are real.** `scope` drives spawn tables (`layout_loader.gd`, `dungeon_gen.gd`), room `theme` palettes exist, and the chart math (`compute_weights`/`effective_stability`/`completion_xp`) is real and tested. A new biome is a kit over the existing generator, not a new engine.

- **There is no `evals/` dir** and the four headless suites are the load-bearing regression gate today (`test_skills` guards the frozen-hotbar). Any eval work is net-new and must not stall content (see the cut-line in P10).

---

## 1. Vision

Wayfinder becomes **a storybook atlas you fill in by playing.** You are a Wayfinder — not a conqueror of the Wolds but someone who *remembers the paths the village forgot*. To inscribe a chart is to "remember a way" into a region of Bramblewood; to delve it is to walk a place with its own ecology, weather, and quiet sorrows; to come home is to make the village a little more whole. This reframe — Wayfinding as *remembering*, the trophy chain ending in a **quieting, not a kill** — is the soul of the game and is protected above all the systems below.

The **shipped trophy chain is canon and kept**: **Hedgemother → Burrow Boar → Wolf Alpha → the Summit** (`charts.gd`). The full game houses that chain across named regions of the Wolds and ends at the Summit where the Hedgemother — *the same being, at her deepest* — is **quieted for a season, never killed.** Bramblewood **visibly grows** as the chain is walked — a repaired well that animates, a neighbor at the cookfire, a road cleared — so progression terminates in a place you can walk, never a stat bar.

The cozy-skilling spine — `gather → craft → chart → delve` — is the heart (ADR 0003). Combat is **one verb** (the bow), deepened only by *reading and response*, never a new weapon class or a higher gear tier. The economy runs on **inks**, not gold inflation. There is **no King of Brambles.**

**Scope honesty up front:** the next deliverable is **Pillar Zero (a hardened crypt) + Pillar One (the Pale Veins)** — and nothing else is committed. Everything past Pillar One lives in a one-paragraph **Horizon appendix (§10)**, deliberately *not* specced in phase detail, because every specced phase is a magnet for premature work on a tiny team.

---

## 2. Design pillars

Load-bearing. Every feature is tested against these; the headless suites and the on-demand balance-sim enforce them.

**P1 — The cozy-skilling spine is protected by GROWTH, not just rhetoric (ADR 0003).**
It is not enough to assert the spine is safe while spending the design budget on combat. **Each shipped pillar must add real, new gather/craft/cook DEPTH** — a new gather interaction, a craft-tree deepening, or a cooking mechanic — specced at the same level of detail as any combat move. The spine is the thing that gets the *most* new depth, not a solved substrate things are bolted onto. (cf. [[Stardew Valley]], [[Rune Factory 4]])

**P2 — The biome kit is the atomic unit of release.**
A pillar ships only with all of: ~20 tile GLBs + a 4-creature family + a boss-with-gimmick + an ASCII legend + a locked `--cref` anchor + biome-coupled affixes + 1–2 signature inks + a gather palette + a one-line lore anchor — **and** the cross-cutting workstreams it touches (audio bed, kit-compliant UI, perf check). Cloned from the proven crypt pipeline.

**P3 — Fiction and the roll are one continuous loop.**
Unlocking a region teaches its ink; its ink biases its affixes; its affixes flavor its dungeons; its boss gimmick reads off the room theme; its legend is delivered diegetically. A Pale Veins chart must *feel like* the Pale Veins.

**P4 — Town grows with the chain.**
Completing a leg of the trophy chain physically restores a piece of Bramblewood. Reward is a place and a neighbor, never a stat bar.

**P5 — Systems-first, art-later, value-first.**
Systems built and balanced against **tinted dummy clones** with a tracked dummy-debt burn-down. Art backfills in tonal batches of 3–5 against the locked stem. Custom Meshy clips for boss signature moves only.

**P6 — Anti-escalation is canon and is the endgame's shape.**
The Hedgemother is the largest threat; **there is no King of Brambles.** The Summit is the same being at her deepest, *quieted*. The only honest long-tail is therefore **horizontal** (Codex, Deepening) — the endgame falls out of the lore constraint rather than being bolted on. **No capstone may introduce a creature larger or worse than the Hedgemother.** (cf. [[World Lore]], [[Hades]])

**P7 — The cut-line: no new system ships until a region that uses it is complete end-to-end.** Elevated to an ADR. (cf. [[MMO Lessons for Wayfinder]])

**P8 — Combat depth comes only from reading/response and loadout opportunity cost — and is kept SHORTER than the spine.**
For the demo, combat additions are deliberately small (see P9). No new weapon class, no new gear tier ever. The length a section gets in this document is itself a spine-protection signal: combat is short here on purpose.

**P9 — Demo combat is exactly: stagger + death-flourish + ghost-trail (pure feel) + ONE reading mechanic.** Everything richer (Rally, Poise *and* both, living-pack rival AI, charm-notch, named synergies, behavior affixes, Hearth-ember, Vigil, item-skill modifiers) is **post-demo Horizon**, not built now.

**P10 — Infra serves content; it never gates it.** The balance-sim is a **script run on demand**, not a commit gate. Schema/cross-ref linters are deferred until a *second* biome exists to cross-reference. The four headless suites remain the only hard gate. Pillar One is **never blocked on green evals.**

**P11 — Region↔trade flavor is gather-palette dressing, not structure.** Per ADR 0005, Huntcraft is the one combat trade fed by *all* kills *everywhere* (`max(2, hp_max/3)` per kill), and all four trades (carto/earth/wilds/hunt) level in *every* region. A region therefore cannot "be" the Earthcraft region or the Huntcraft region. The table's "trade flavor" column is demoted to **which gather node kinds and creature families a region is rich in** — flavor, never an XP rule.

**P12 — Inks are the value spine.** Chart inscription + reroll sinks + dissolve-to-ink-dust all route through ink. (cf. [[Path of Exile]], [[MMO Economy and Itemization]])

---

## 3. The universe — Bramblewood expanded

### 3.1 The through-line: Wayfinding as remembering

The differentiating trade gets its reason in two strings, not a cutscene. **Mara Linnet's tutorial** is reframed: a Wayfinder doesn't *make* a dungeon, she *remembers a way* the village forgot. A **first-Deepening return line** lands the rest: "Every chart you draw is a path that was always there. You only have to remember it hard enough." On-voice with the locked lore ("we tend the brambles, we don't tame them"). This is the single strongest move in the plan and is protected. (cf. [[Wayfinding]], [[World Lore]])

### 3.2 The cosmology and the Summit myth

The **Bramble Bargain** — the village's buried kindness, the Hedgemother as bound human cognition — is **never explained.** It is delivered only as diegetic fragments: a carved well-stone, a tale Hod stops halfway, a Last Light candle "lit from inside the hedge," the Hedgemother's quieting line. The Summit approach is a small **green → red → quiet** arc, never grimdark. **The Summit boss is the Hedgemother herself at her deepest** — the same `hedgemother_v2` silhouette the player met at level 8, scaled into the form she takes at the heart of the bramble. She is **quieted, not killed.** There is **no separate Queen, no King of Brambles** — an ADR.

### 3.3 Regions of the Wolds — housing the SHIPPED chain

The map exists to **house the four shipped bosses** (Hedgemother, Burrow Boar, Wolf Alpha, Summit-Hedgemother), not to invent new ones. The "palette" column is **gather/creature flavor only** (P11), not a trade assignment. Only the **bolded** regions are committed (Pillar Zero + One); the rest are Horizon (§10) and shown here for continuity, not as a build order.

| Region | Houses (shipped boss) | Gather / creature palette (flavor only) | Dungeon theme | Boss gimmick | Signature ink(s) | Lore anchor |
|---|---|---|---|---|---|---|
| **The Crypt under the Bramble** *(Pillar Zero — reference)* | **Hedgemother** (`hedgemother_v2`, scale 3.75) | bones; the four crypt mobs | tomb halls, bramble-choked vaults | thorn-arena seals exits with growing brambles you cut; phase-3 hedge-sprite summon (spec-05) | Foxglove (existing) | the bound figure half-seen near her den |
| **The Pale Veins** *(Pillar One)* | **Burrow Boar** (`burrow_boar_v3`) — its **wallow** is here (the shipped `burrow_boar_den` affix) | ore-rich; **Hedgewight** + Boar | pale stone, branching veins, ore vaults | collapsing-vein gimmick + true phase-2/3 verbs (the shipped Boar tusk-quake) | **Palechalk Ink** (Stoneflesh-biasing) | "passages that branch into other things"; a carved well-stone; Hod's half-finished tale |
| Briarward *(Horizon)* — the **re-skinned shipped Briar Maze**, not a new region | **Wolf Alpha** (`wolf_alpha_v2`) — its den lives at the thorny end of the maze | bramble/hedge; bramble_imp/hedge_sprite/skitterling (shipped spawn table) | the shipped twisted maze topology (corridors over rooms) | the shipped Wolf howl-buff phase | re-skin of existing Briar Maze inks | keep Briar Maze's tuned mechanics; re-name/re-dress only |
| The Marl *(Horizon, optional)* | — (no shipped boss; a *cosmetic re-skin* of Briarward's mechanics if marsh fiction is wanted, per the "don't re-level a tested template" rule) | marsh forage | maze-marsh re-dress | reuses maze/zone-denial | re-skin inks | Cricket's hated 3-day letter route; Seventh Cottage hook nearby |
| **The Summit** *(Horizon — capstone)* | **the Hedgemother at her deepest** (`hedgemother_v2`, scale 4.6 — *same being*) | — | green → red → quiet | the deep-form thorn-walls section the arena; **quieted, not killed** | capstone Wayfinding tools | Linnet's Vow; the Bargain implied |

**Why this map.** It places **every shipped boss** in a home (Hedgemother → Crypt, Boar → Pale Veins, Wolf → re-skinned Briar Maze, Summit-Hedgemother → Summit), keeps the **tested Briar Maze template** instead of deleting it, and invents **zero** new bosses — closing the "free bosses thrown away" gap and honoring ADR 0006. The Marl appears only as an *optional cosmetic re-skin* of the maze, never as new balance work.

### 3.4 Factions as quiet texture (never a side to win)

Two gentle undercurrents surfaced as flavor/codex marginalia: **the two old soldiers** (Hod and Sir Withering drink at the Well but don't speak — scheduled co-presence, never a quest) and **the two herb-tenders** (Brother Pell's *Marked Pages* vs Mother Onywyn's freer foraging — a Wildcraft flavor axis, not a reputation grind). (cf. [[Disco Elysium]])

### 3.5 Seasons & festivals (soft, streak-free)

The four authored festivals (**Quickening, Lampwright's Eve, Pieday, Last Light**) wire to the 10-min day cycle as opt-in FSM toggles with **no streaks, no expiring rewards** — the ACNH "world exists without you" feeling minus FOMO. **Festivals are Horizon for the demo** (Pillar Zero/One ship without them); listed here for the world bible's continuity. (cf. [[Animal Crossing New Horizons]])

### 3.6 NPC cast growth (mentor voices)

The village populates as cottages restore; each trade gets a **mentor voice** on level-up lines (Mara/Wayfinding, Hod/Earthcraft, Onywyn-Pell/Wildcraft) so leveling reads as deepening a relationship. **Demo scope: Mara (tutorial + return-debrief) and Hod (Pale Veins arrival) only.** The rest is Horizon. (cf. [[Ultima VII]], [[Disco Elysium]])

---

## 4. Systems build-out

This section catalogs moves; §5 sequences only the two committed pillars. **A "DEMO" tag = built now. A "HORIZON" tag = named, not built (see §10).** The spine sections (4.2) are intentionally the most detailed; combat (4.4) is intentionally short — that ordering is the P1 word-budget inversion the critique demanded.

### 4.1 Trades & progression (DEMO: Earthcraft only)

- **DEMO — Mastery perks become pick-one-of-N choices** above ~lv10, *for Earthcraft only* in Pillar One: pick **Rich Seams OR smelt-yield OR faster-channel** — same power budget, real identity, zero balance cost. Proves the pattern before it spreads.
- **DEMO — One two-hop cross-trade chain:** deep ore → Wayfinding deep-ink, so Earthcraft demonstrably feeds Wayfinding.
- **HORIZON** — pick-one-of-N for all four trades; post-17 horizontal titles/grand-routes; trade-flavored skill voices across the cast. (cf. [[RuneScape]])

### 4.2 Cozy skilling & content cadence — THE SPINE GETS NEW DEPTH (DEMO)

This is the heart, so it gets the most new mechanics, per P1.

**New GATHER depth (DEMO, Pillar One):**
- **Vein-reading at ore_rock nodes.** The Pale Veins introduce a gather interaction beyond hold-to-channel: an ore node shows a faint **grain direction**; tapping *with* the grain (a generous timing/aim window, cozy-tuned) yields a bonus chunk and a chance at the deep ore that feeds Wayfinding ink. Missing the grain still yields the base — no punish, only upside. This is a *new gather minigame*, the kind the spine was missing.
- **Branching seams.** A mined Pale Veins node can **branch** — exposing 1–2 adjacent nodes ("passages that branch into other things," the region's lore anchor made mechanical). Gives gathering a tiny spatial puzzle and a reason to clear a vault wall-to-wall.

**New CRAFT depth (DEMO):**
- **Ink-refining as a craft step, not a buy.** Palechalk Ink is *refined* from deep ore at a small bench interaction (combine grades, the better the grade-match the higher the stability bonus) — the first **craft-tree deepening**, and it directly stabilizes inscriptions (the cross-trade chain made tangible).

**New COOK depth (DEMO, minimal):**
- **One stabilizing draught** the player cooks and consumes to raise an inscription's stability roll — a single, concrete cook→chart link that proves cooking matters to the spine. (Full cooking depth is Horizon.)

**The Almanac (DEMO — minimal):**
- A Stardew-bundle-style request board in the Chartmaker's Yard. **For the demo: 1–2 pages only**, spanning all four trades, each completion **visibly restoring one walkable town corner** (the Living Atlas made concrete). Expansion is Horizon. **UI deliverable named:** the Almanac is a new kit-compliant panel — see §6 UI workstream; it must pass `check_ninepatch.py` and gets a `WYRD_UI_SHOT` capture surface.

**Cadence & anti-idle (DEMO contract):**
- **The three-cadence contract** (SHORT = a run/gather session; MEDIUM = an Almanac page; LONG = the trophy chain) as an audit lens — every feature declares its cadence. **No idle downtime:** gather channels stay minigame-lite; timed crafts complete *during* a delve so town and delve feed each other.
- **Extend the pre-combat runway:** the Snug tutorial chart and first Almanac page are fully peaceful; Huntcraft is introduced as a clearly optional fourth verb only after the cozy core is felt.

**HORIZON** — cottage home base, discovery-seeded recipes, full Almanac, the rest of cooking. (cf. [[My Time at Portia]])

### 4.3 The chart loop & procgen variety (DEMO)

- **DEMO — Biome as the chart's second axis**, implemented as a swap of theme pools / tilesets / spawn tables over the existing generator and 6-metric scorer. Verified-feasible (`scope` already picks the spawn table; room `theme` palettes exist). Pillar One = a ~20-piece kit, not a new engine.
- **DEMO — Biome-coupled affixes & inks for the Pale Veins:** flavor the *existing* affix roster to stone (Stoneflesh/Cursed-Key twins) and ship **1–2 signature inks (Palechalk)** whose recipe is gated behind gathering in the region. **Honest affix budget:** `charts.gd` defines ~9 affixes today and `affixes.gd` is a display/compose helper with **no twin roster** — so the demo ships **Pale-Veins-flavored variants of the existing affixes plus the deferred risk twins for ONE biome only**, authored as a small data table and validated by the on-demand balance-sim. Pushing *every* affix to an interacting Balatro-style rule-changer across many biomes is a large unscoped balance workstream and is **explicitly Horizon** (§10), not a demo bullet.
- **DEMO — Procedural "rumor" headers:** a deterministic one-line storybook blurb per chart from `template + affixes + scope`, voice-checked ("A wallow in the Pale Veins, where the stone branches into other things"). Near-zero authoring per run.
- **DEMO — The "what this run feels like" summary card** on the inscribing bench: biome name + one-line fiction, resolved good/bad twin icons in plain English, the boss-gimmick implied, and **honest live odds** built on the real `compute_weights`/`effective_stability`. The legibility keystone — cheap (strings + existing math). **UI deliverable named** (kit panel + ninepatch + capture surface, §6).
- **DEMO — One reroll sink:** **Smudge Stick** (ink-priced reroll of one resolved twin). Informed randomness + an ink sink + zero gear inflation. (Fresh Quill / Steady Hand are Horizon.)
- **HORIZON** — soft in-run fork at the rest room; Echo Charts; the full affix-as-rule-changer table across biomes.

### 4.4 Combat (DEMO is deliberately SHORT — P8/P9)

For the demo, combat gets **exactly four things**, all chosen for *feel* and *one* reading mechanic, nothing that pressures ADR 0003:

- **DEMO — Stagger + death-flourish + HP-bar ghost-trail.** Pure feel, no new system — closes three weak feel-pillars (world response, power fantasy, damage readability).
- **DEMO — ONE reading mechanic: Poise/stance-break.** A per-boss Poise meter (separate from HP) fills on hits during recovery/whiff frames; at full Poise the boss enters a ~3s **Reeling** state opening a **Wayfinder's Mark** finisher + a skill-reset window. Bosses are already root-immune, so Poise is the skill expression that replaces CC. **This is the only reading mechanic in the demo — Rally is NOT built now** (the plan picks Poise *or* Rally, per the cut-line; it picks Poise).
- **DEMO — The shipped boss gimmicks get implemented for the two demo bosses:** the Hedgemother's thorn-arena + phase-3 hedge-sprite summon (spec-05), and the **Burrow Boar's tusk-quake** phase (the shipped Boar lives in the Pale Veins — see §3.3).

**HORIZON (explicitly NOT built for the demo):** Rally, living-pack rival-kind LOS AI, charm-notch loadout re-cost, named cross-skill synergies, behavior affixes, Hearth-ember revive, Waystone Vigil, item-skill modifiers. Each of these is a real ARPG-combat workstream and belongs after the spine is proven, never alongside it.

### 4.5 Economy & itemization (DEMO: the trophy ritual ONLY)

The full inscribed-gear/temper/Uniques/Weaves/smart-drops stack is a Last-Epoch/PoE itemization subsystem disproportionate to a one-verb-bow game and would create vertical power deltas that contradict P8 ("no new gear tier"). For the demo, itemization is **one verb**:

- **DEMO — The two-beat trophy ritual.** The shipped boss kill drops a *raw* trophy; it must be carried home and inscribed into a permanent **Wayfinder's Ledger** charm by the chartmaker for a small, thematically-tied combat boon — **using the existing inscription mechanic, no new tech.** Boar tusk = +knockback resist; Wolf fang = +1 dodge i-frame; Hedgemother thorn = bleed lands full-duration on bosses. This is the ONE itemization verb worth keeping: it gives town a combat-relevant reason to exist (*you go home to craft, not just to sell*) and reuses inscription. Boons are flat, small, and capped — explicitly **horizontal**, balance-sim-checked to carry no raw-damage creep.
- **DEMO — One ink sink:** dissolve-unwanted-gear-to-ink-dust (item-overflow → ink), routing overflow back to the value spine (P12).
- **DEMO — "Top-of-ladder materials are gather-only" becomes an ADR** with an automated **no-arbitrage assertion** extending the existing smithing test — any deep material can never be both shelf-stocked and a peak input.
- **HORIZON (dropped from the demo entirely):** inscribed-gear temper budget at Hod's Anvil, the Uniques-as-mechanics roster, Bramblewood Weaves/sockets, smart drops. These are named in §10 and built only if a region needs them (P7).

### 4.6 Co-op (DEMO: finish Phase C correctness, then STOP)

`net_game.gd` is ~289 lines at Phase B/C. The chart-reader seat is a **new authoritative multiplayer subsystem** and is **Horizon**, not a demo deliverable.

- **DEMO — Finish Co-op Phase C correctness** (the roadmap's open item): walk-anim sync, 30s reconnect grace, host-lantern-out toast, guest damage numbers, party UI, join/leave lines in Bramblewood voice, and **RPC boss telegraphs + Poise to all peers** so every screen reads the same stance-break window (a correctness requirement, not polish). Downed-not-dead **Wildcraft "second pour"** revive before party-wipe.
- **DEMO — Host-authoritative contract is locked in Phase 0** and the **Charter/persistence schema question is resolved before any persisted shared data ships** (see §6 persistence workstream): how the per-party logbook survives a host change, and the save-size budget for it.
- **HORIZON (explicitly NOT built now):** the shared chart-object + **chart-reader seat**, asymmetric room density, party-pooled Trade-roles, the full Charter, two-person inscribing, cookfire feast, Well-seat rested-XP, SOS-flare/Friends-Pass. The chart-reader seat is a post-launch ambition. (cf. [[Multiplayer Co-op]])

### 4.7 Endgame (DEMO: Codex shell only; Deepening is Horizon-leaning)

The seven-system retention tail (Living Atlas, full Codex, Deepening, Cartographer's Board, Wandering Seasons, Vows, Deeper Quieting, Echo Charts) is an MMO live-team's remit. The demo seeds **one**:

- **DEMO — The Wayfarer's Codex shell.** Every affix twin, enemy, biome, recipe, boss written in WORLD_LORE voice **by verbatim quote, not paraphrase**, unlocked on first-discovery as a reward (never a gate). Seeded with the crypt + Pale Veins entries. It is the cozy completion engine and costs almost nothing once the fiction pipeline (4.8) exists.
- **HORIZON (named, not built):** the **Deepening ladder** (the strongest longevity primitive — +1 affix slot per depth rank, density not bigger bosses, bad twins still pay `completion_xp` which already exists) is the *first* thing built post-demo. Everything else — full Living-Atlas port, Cartographer's Board, Wandering Seasons (parallel save), Vows, Deeper Quieting, Echo Charts, homestead — is the "if it lands" list in §10. The demo ships **Codex only**; the *first* post-demo system is **Deepening**.

### 4.8 Narrative, quests & onboarding (DEMO)

- **DEMO — Teach affixes the Portal way:** the first time a player inscribes a never-seen affix, bias that den to feature **only** that affix; after that it combines freely. Tracked in save; no popup beyond the affix's storybook name.
- **DEMO — Mara's rotating return-debrief** leaks one Wayfinding fragment per milestone — story by playing the loop, never a quest stop.
- **DEMO — The Folk Book / Codex** unlocks on first-discovery with WORLD_LORE quotes verbatim.
- **DEMO — Saturate every systemic string** (affix twins, ink names, completion/death/return lines) through the Voice & Tone register as a pure copy pass — routed through the lore-grader gate and the **string table** (see §6 localization workstream).
- **DEMO — Onboarding hardening:** New Game button, skip-tutorial path, self-rescuing steps.
- **HORIZON** — domestically-motivated NPC questlines; den set-dressing-by-affix recurrence at depth.

---

## 5. Phased roadmap — TWO committed pillars only

Only Phases 0 and 1 are specced, deliberately. Phases 2–6 of the earlier draft are **removed from the build and collapsed into the §10 Horizon appendix** so the team is not invited to build toward the whole thing. **The biome kit (P2) is the unit; the cut-line (P7) is the guardrail; the spine-growth rule (P1) is the acceptance bar.**

---

### Phase 0 — Pillar Zero: Harden the Frame & Finish the Crypt

**Goal:** Turn the demo's whole-but-thin crypt into the *reference pillar* and lay the **minimum** foundation Pillar One leans on — **without** building a giant horizontal infrastructure phase (the earlier draft's Phase 0 violated P7 by front-loading evals/fiction-pipeline/biome-template/Almanac all at once; this is cut back).

**Foundation (the load-bearing wall — small and targeted):**
- **Replace the destructive save reset with a migration ladder.** `save_game.gd` already has `VERSION` and discards on mismatch (line 54). Add a **migration hook**: on version < current, run ordered migrators (the existing Huntcraft backfill is migrator #1) instead of "starting fresh." **Fix the destructive `_test_save_roundtrip`** (back up the real save path first).
- **ADRs:** `top-of-ladder materials are gather-only` (+ no-arbitrage test), `the cut-line (P7)`, `anti-escalation / no King of Brambles (P6)`. Lock the **host-authoritative co-op contract**.

**Biome-kit template + crypt retrofit (the real Phase-0 product):**
- **Document the biome-kit template** as the unit of release and retrofit the crypt to it (the crypt already *is* one). File any gaps as the Phase-0 punch-list.
- **Hedgemother gets her real gimmick** (thorn-arena seals exits with growing brambles) + the **phase-3 hedge-sprite summon** (spec-05) as the boss-gimmick reference.
- **Crypt lore anchor + procedural rumor header** per inscribed chart.
- **Codex shell** seeded with the crypt's first entries by verbatim quote, and the **rumor-header + return-debrief** strings — i.e. the *minimal* fiction-delivery wiring, **not** a full pipeline build.

**Explicitly DEFERRED out of Phase 0 (was overloaded before):**
- The full eval pipeline (schema/cross-ref/balance-sim as a commit gate) → **the balance-sim is a script run on demand in Pillar One**, and cross-ref/schema linters wait for a second biome (P10).
- The Almanac → **Pillar One** (minimal), not here.
- The full fiction-delivery pipeline → only the crypt's strings are wired now; the reusable pipeline generalizes *as Pillar One consumes it*, not before (P7).

**Exit criteria:** crypt re-expressed as a complete biome kit; the four headless suites stay green on every commit; **save migrates a v0 file instead of discarding it**, and the roundtrip test is non-destructive; no-arbitrage / cut-line / anti-escalation are ADRs with tests; the biome-kit template is documented well enough that **one new pillar can be produced by cloning it.**

---

### Phase 1 — Pillar One: The Pale Veins (Earthcraft, Spine Depth, the Boar)

**Goal:** Ship the first new full region — **housing the shipped Burrow Boar** — proving the clone cadence, and pairing it with **new gather/craft/cook depth** (the spine) and the **one** combat reading mechanic.

**World:** Build the **Pale Veins** (ore + Hedgewight + the **Boar's wallow**, "passages that branch into other things," Hod stops his stories halfway). Deliver its legend diegetically (a carved well-stone) + Codex by quote. **Restore the well** (it animates) and reveal the Pale Veins as a walkable town corner. Hod arrives as the **Earthcraft mentor voice**.

**Systems (spine FIRST, combat short):**
- **Spine depth (the headline work):** vein-reading + branching-seam gather minigame; ink-refining craft step; the one stabilizing-draught cook→chart link; the **minimal Almanac (1–2 pages)** restoring a walkable corner; the no-idle/three-cadence contract enforced.
- **Pale Veins biome kit** by cloning the crypt pipeline (tileset + 4-enemy family incl. Hedgewight + the **shipped Burrow Boar** as the region's boss + legend + `--cref`), **on tinted dummies first**.
- **Boss gimmick:** the Boar's collapsing-vein + **shipped tusk-quake** phase.
- **Biome-coupled affixes (Pale-Veins-flavored, one biome) + Palechalk ink** gated behind gathering.
- **Combat (short, per P9):** Poise/stance-break + Reeling finisher + stagger + death-flourish + ghost-trail. **No Rally, no charm-notch, no synergies.**
- **Earthcraft deepening:** pick-one-of-N mastery + the deep-ore → deep-ink cross-trade chain.
- **The "what this run feels like" summary card** ships here.
- **Trophy ritual:** the Boar's raw tusk → Ledger charm at home (the one itemization verb).
- **Balance-sim script** validates the Pale Veins data table **on demand** (not a gate).

**Cross-cutting deliverables that ship WITH this pillar (not optional):** the Pale Veins **audio bed + Boar boss sting + gather/craft foley**; the Almanac + summary-card **kit-compliant panels** (ninepatch-passing, with capture surfaces); a **perf check** at the target budget (§6); a **playtest pass** against the §8 metrics.

**Exit criteria:** Pale Veins playable end-to-end (gather→refine→cook→ink→chart→delve→Boar→trophy→Ledger→town-grow) and passes the biome-kit checklist; the **second biome shipped purely by cloning** (no new generator code); the **spine demonstrably deepened** (a blind tester names a new gather/craft thing they liked); combat reads as a stance-break loop; audio/UI/perf/playtest workstreams all delivered for this pillar.

---

## 6. Cross-cutting workstreams (each is a named, recurring cost)

These were missing from the earlier draft and are now first-class for **every** committed pillar.

**Audio / music (recurring).** The repo has `audio/` (ElevenLabs SFX, `tools/generate_audio.py`). Cozy-fairytale tone lives or dies on audio (Stardew, ACNH). **Each pillar ships:** an ambient bed, a boss sting, and gather/craft/UI foley. Pillar One's audio is a named deliverable; festival cues are Horizon. Budgeted as a recurring per-pillar line, generated via the existing tool.

**UI/UX for every new system (recurring).** Per CLAUDE.md everything derives from the Wayfinder UI Kit (`wyrd_ui.gd` tokens, `check_ninepatch.py`). **Demo-named UI deliverables:** the **Almanac panel** and the **"what this run feels like" summary card** — each a new kit-compliant screen needing styleboxes, a `check_ninepatch.py` pass, and a `WYRD_UI_SHOT` capture surface (extend `tools/capture_ui.sh`). The Codex, Charter, chart-reader seat, temper bench, homestead are Horizon and inherit this same checklist when/if built. **No new panel ships without a ninepatch pass and a capture surface.**

**Performance / target hardware (gate per pillar).** Target: **desktop, Forward+, 60fps**. Budget set in Phase 0 (draw-call ceiling for a ~20-piece tileset, instancing plan for repeated tiles, an enemy-count cap that keeps the Boar fight + room density inside budget). Pillar One **must hit the budget** before it ships; co-op enemy-state RPC batching is checked when Phase C lands. AI-behavior richness is Horizon partly *because* it costs frames.

**Balance ownership & tuning loop.** A named owner (the lead) tunes HP/damage/XP/ink curves **against the existing crypt as the reference difficulty curve** — Pillar One's curve is set *relative to* the shipped crypt, not from scratch, to respect ADR 0006's "re-balancing shipped content is expensive." Methodology: the **balance-sim script** simulates N runs and reports outliers; the owner adjusts the data table; re-run. Difficulty target: the cozy curve (generous windows, upside-only gathers). Every new biome is one explicit, owned balance pass — not assumed free.

**Playtest / user-research ops.** `docs/PLAYTEST.md` (currently untracked) is **adopted and referenced** as the cadence doc. Per pillar: **3–5 blind testers**, a fixed script (gather→chart→delve→home), instrumentation of the §8 feel-pillar scores, run by the lead. Metrics in §8 are only valid because this apparatus exists; without a tester, a metric is aspiration and is marked so.

**Localization / string externalization.** Every player-visible string (rumor headers, codex-by-quote, milestone debriefs) flows from WORLD_BIBLE voice. **A string table with stable IDs is stood up in Phase 0** (even if single-locale), and the **verbatim-quote-from-WORLD_LORE pipeline writes into it** so the lore-grader gate has something to check and future localization is not a rewrite. Procedural rumor headers compose from string-table fragments, not inline literals.

**Persistence / data-escape schema.** Before any long-tail or shared data ships: define the **save-size budget**, the migration ladder (Phase 0), and — for co-op — **how the Charter/logbook survives a host change** (it does not ship until this is answered). The Living-Atlas/Seasons parallel-slot file format is **Horizon** and is *not* designed now, but the save schema is versioned so it can be added without a destructive reset.

**Art & content pipeline.** Systems-first against tinted dummy clones with a tracked **dummy-debt burn-down** in `concept-art/INDEX.md`. Art in tonal batches of 3–5 against the locked `--cref` stem. New mobs inherit the locked rig templates; **custom Meshy clips reserved for boss signature moves only.** Meshy → clean_ai_mesh → Blender sockets → Godot is the proven motion. Art throughput is the binding constraint — this workstream's job is to keep it from stalling design.

**QA / gates.** The four headless suites (`test_wyrd_loop`, `test_wyrd_dungeon_scene`, `test_wyrd_transitions`, `test_skills`) stay green on every commit (`test_skills` guards the frozen-hotbar). The **balance-sim is a script, run on demand, never a commit gate** (P10). Every pillar passes the biome-kit acceptance checklist end-to-end before it ships.

---

## 7. Risks & mitigations

| Risk | Failure mode | Mitigation |
|---|---|---|
| **Cozy-spine erosion under combat/itemization pressure** | The design energy quietly goes to combat/itemization (the ADR-0003 drift the critique flagged). | **P1 inverts the word-budget:** each pillar must add *new* gather/craft/cook depth specced as richly as combat; combat is hard-capped at stagger+flourish+ghost-trail+ONE reading mechanic (P9); itemization is the trophy ritual only (4.5). |
| **Escalation at the capstone** | A bigger "Queen" reads as a King of Brambles, violating canon. | **The Summit boss is the same `hedgemother_v2` being at her deepest, quieted not killed** (§3.2, ADR P6). No creature larger/worse than the Hedgemother may ship. |
| **Discarding shipped bosses / re-leveling tested templates** | The map invents new bosses and deletes Briar Maze, causing exactly the ADR-0006 churn. | The region map **houses the four shipped bosses** and **keeps Briar Maze's tuned mechanics** (re-skin only); zero new bosses; the Marl is an optional cosmetic re-skin (§3.3). |
| **Foundation built on a misread** | "Add a save version" wastes the first week on something that exists. | Step 1 is **replace the destructive reset with a migration hook** (§0, §9), not add a field. |
| **Region↔trade mapping contradicts the XP model** | "The Pale Veins is the Earthcraft region" is false under ADR 0005. | **P11 demotes region↔trade to gather-palette flavor;** all four trades level everywhere. |
| **Infra stalls content** | The eval pipeline becomes a Phase-0 gate that blocks Pillar One. | **P10:** balance-sim is on-demand; linters wait for a second biome; only the four headless suites gate. Pillar One never blocks on evals. |
| **Phase 0 overload** | A giant horizontal infra phase violates the plan's own cut-line. | Phase 0 is **cut back** to migration + ADRs + crypt-retrofit + crypt-only fiction strings; Almanac/eval-gate/full-pipeline pushed into Pillar One *as it consumes them* (P7). |
| **Affix budget unscoped** | "Push every affix to a rule-changer across biomes" is a hidden balance subsystem. | Demo ships **Pale-Veins-flavored variants of the existing ~9 affixes + deferred twins for ONE biome**, balance-sim-checked; the full rule-changer table is Horizon (§10). |
| **Missing recurring costs** | Audio/UI/perf/playtest/strings silently un-budgeted. | §6 makes each a named per-pillar deliverable with an exit-criteria line in Phase 1. |
| **Art throughput** | Bottleneck stalls design. | Systems-first on dummies, tracked dummy-debt burn-down, tonal batches, boss-only custom clips. |
| **Tiny-team overreach** | Speccing Phases 2–6 invites building the whole MMO. | **Hard cut:** only Pillars Zero+One are specced; everything else is the one-paragraph Horizon appendix (§10). |

---

## 8. Success metrics (each tied to the §6 playtest apparatus)

**Phase 0 (foundation):**
- Four headless suites green on every commit; a **v0 save migrates cleanly** (not discarded) and the roundtrip test is non-destructive.
- A fresh dev can produce a *throwaway* second biome from the documented template in < 1 day.
- Playtest (3–5 blind testers): testers describe charting as "remembering a way," not "rolling a dungeon."

**Phase 1 (clone cadence + spine depth + reading mechanic):**
- The Pale Veins shipped *purely by cloning* — no new generator/engine code.
- **Spine-growth check:** a blind tester names a *new* gather/craft/cook thing they enjoyed (vein-reading, branching seams, ink-refining, or the draught) — the spine got real depth, not just protection.
- "World response" and "power fantasy" feel-pillars rise from 4–5/10 toward 7+/10 (Poise/stance-break + stagger + ghost-trail).
- A Pale Veins chart is *recognizably* the Pale Veins to a blind tester (place-identity, not recolor).
- Every session advances at least one of SHORT/MEDIUM/LONG (the "no dead actions" audit passes).
- Audio/UI(ninepatch)/perf-budget/playtest deliverables all signed off for the pillar.

**Co-op (when Phase C lands within Pillar One's window):**
- Boss telegraphs + Poise read correctly on guest screens (zero "I couldn't see the wind-up" reports).

---

## 9. The first three concrete steps (next week)

1. **Replace the destructive save reset with a migration hook + fix the destructive test.** `save_game.gd` *already* has `VERSION` (line 11) and discards on mismatch (line 54). Add an ordered **migration ladder** invoked on `version < current` (the existing Huntcraft backfill, lines 70–72, becomes migrator #1) so old saves *migrate* instead of starting fresh. In the same week, back up the real save path and make `_test_save_roundtrip` non-destructive. Draft `ADR 0007 — top-of-ladder materials are gather-only` (+ no-arbitrage test), `ADR 0008 — the cut-line`, `ADR 0009 — anti-escalation / no King of Brambles`. This is the load-bearing wall.

2. **Document the biome-kit template by retrofitting the crypt to it.** Write `docs/specs/biome-kit-template.md` — the hard checklist (~20 tiles + 4-enemy family + boss-with-gimmick + ASCII legend + locked `--cref` + biome-flavored affixes + 1–2 inks + gather/creature palette + one-line lore anchor + **audio bed + kit-compliant UI + perf budget**) — and check the crypt against every box, filing gaps (the Hedgemother's missing gimmick, the unimplemented phase-3 hedge-sprite summon from spec-05) as the Phase-0 punch-list. Proves the clone unit before any new art.

3. **Spec Pillar One as one document, spine-first.** Write `docs/specs/pillar-one-pale-veins.md` covering, in this order: the **new gather/craft/cook depth** (vein-reading, branching seams, ink-refining, the stabilizing draught) and the **minimal Almanac**; then the **Pale-Veins-flavored affix table + Palechalk ink** (a small data table the on-demand balance-sim validates); then **the shipped Burrow Boar as the region's boss** (housing it per §3.3) with its tusk-quake gimmick; then the **short combat layer** (Poise + stagger + flourish + ghost-trail, no Rally); then the **trophy-ritual Ledger charm**; and the **cross-cutting deliverables** (audio bed, Almanac + summary-card UI with ninepatch pass + capture surface, perf budget, playtest script). Note explicitly that the eval-as-gate, full fiction pipeline, and full Almanac are deferred per P7/P10. This is the demo, end to end.

---

## 10. Horizon (named, NOT specced — deliberately one section)

Everything below is the long-game. It is listed so the world bible stays coherent and so no one re-invents it — but **none of it is committed, and the plan deliberately does not phase-spec it**, because every specced phase is a magnet for premature work (the core scope lesson from review). Each item ships *only* when a completed region needs it (P7), built in roughly this priority:

1. **The Deepening ladder** — the first post-demo system: +1 affix slot per depth rank, density not bigger bosses, bad twins still pay `completion_xp`. The single best longevity primitive.
2. **Briarward** (the re-skinned, re-named **shipped Briar Maze**, housing the **shipped Wolf Alpha**) and **the Summit** (the **Hedgemother at her deepest**, quieted) — completing the shipped trophy chain across the map.
3. **The full Codex** with cosmetic-title milestones; the rest of **cooking/craft depth**; the **full Almanac**; the **cottage home base**.
4. **Affixes-as-rule-changers** across multiple biomes (the Balatro-Joker table) — a large, owned balance workstream, not a bullet.
5. **Co-op together-play:** the shared chart-object + **chart-reader seat**, asymmetric density, party Trade-roles, the **Charter**, cookfire feast, Well-seat rested-XP; then SOS-flare/Friends-Pass.
6. **The richer combat layer** (Rally, living-pack rival AI, charm-notch loadout, named synergies, behavior affixes, Hearth-ember, Waystone Vigil, item-skill modifiers) — only if the spine stays the heart.
7. **The fuller itemization** (inscribed-gear temper at Hod's Anvil, Uniques-as-mechanics, Weaves/sockets, smart drops) — only if a region needs it; never a new gear tier.
8. **The retention tail:** Living-Atlas port, Cartographer's Board, Wandering Seasons (parallel save slot), Wandering Vows, Deeper Quieting prestige (cosmetic-only), Echo Charts, the homestead — the "if it lands" list, each named and unbuilt.
9. **Festivals, the full NPC cast, faction texture, questlines** — soft, streak-free, garden-scale.

The Summit ends in a **quieting, never a kill**; **there is no King of Brambles.** The whole horizon is **horizontal** by the lore's own constraint — that is the point.

---

*The demo is two finished places: a hardened crypt and the Pale Veins, where the spine grows new depth, the shipped Boar finds his wallow, and town grows by one walkable corner. The rest of the Wolds is a horizon we walk toward one finished place at a time — until a Wayfinder remembers the whole map of Bramblewood, and quiets her for a season at the top.*
