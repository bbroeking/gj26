---
type: decision
tags: [adr, architecture, design, deferred, controls, trades, leveling, inventory]
status: draft
updated: 2026-06-13
sources:
  - "docs/adr/0001-inventory-controller-deferred.md"
  - "docs/adr/0002-dungeon-layout-typing-deferred.md"
  - "docs/adr/0003-cozy-skilling-spine.md"
  - "docs/adr/0004-controls-stay-numeric.md"
  - "docs/adr/0005-huntcraft-single-combat-trade.md"
  - "docs/adr/0006-demo-level-cap-17.md"
---

# Design Decisions

A digest of all six Architecture Decision Records (ADRs) for Wayfinder — the surprising or hard-to-reverse calls, their context, the trade-offs, and their current status.

---

## ADR 0001 — InventoryController extraction deferred

**Decision (2026-05-26):** Do not extract an `InventoryController` from `scripts/inventory_panel.gd`. Defer until a second view (vendor, trade, bank) exists.

**Context:** A codebase architecture review flagged that `inventory_panel.gd` conflates controller logic (drag state, `try_equip`) with view logic. The "right" architecture is a controller owning cross-cutting state with the panel as a pure view.

**Trade-off:** A single caller (one inventory UI) is a hypothetical seam, not a real one. Extracting now risks getting the shape wrong and re-refactoring later; the panel already works. The split pays off only when a second adapter (spec 37 vendor, trade UI, or bank) creates the seam that justifies the boundary.

**Status: Deferred.** Revisit when spec 37 (vendor) or a multiplayer/serialization spec lands.

---

## ADR 0002 — DungeonLayout typing deferred

**Decision (2026-05-26):** Do not replace the Dictionary returned by `DungeonGen.generate()` with a typed `DungeonLayout` RefCounted. Defer until a second consumer of the layout exists.

**Context:** Same review as ADR 0001. The generated dict has ~10 fields (`grid`, `rooms`, `entry`, `exit`, `boss_room`, `decor`, `room_depths`, `room_edges`, `seed`, `score`). Typing it would be pure clarity work — no behaviour change — and the dict has a single consumer (`layout_loader._ready`).

**Trade-off:** One consumer = hypothetical seam. The dict contract is implicit but works; a typed class would require every existing field to be migrated with no new functionality. Additive cost today, real payoff when a dungeon editor, multiplayer sync, or layout serializer creates a second consumer.

**Status: Deferred.** Revisit when a second consumer of `DungeonGen.generate()` appears, or when a new complex field makes the dict contract hard to track.

---

## ADR 0003 — Cozy-skilling is the spine; combat is one verb among many

**Decision (2026-05-29):** The game's center of gravity is **cozy skilling**. Gather / cook / craft / chart are the heart. Combat is one verb among many — the OSRS model, not the Diablo model. The ARPG roadmap (specs 30–43) is re-contextualized as seasoning.

**Context:** The project had been pulling in three directions — cozy OSRS-style skilling, New World gathering depth, and FATE/Diablo ARPG combat — with no document stating which was the spine. A grill session resolved it.

**Trade-off:**
- ARPG spine rejected — most competitive genre, hardest feel to nail, would make [[Wayfinding]] (the genuinely novel system) secondary to derivative combat.
- Co-equal hybrid (New World model) rejected — effectively two games; highest scope and risk for a solo developer.
- Cozy-skilling spine accepted — most-built side (three.js maturity), most differentiated ([[Charts]]/[[Wayfinding]]), most achievable solo.

**Downstream commitments:** three.js `src/` is a design prototype (port decisions/data; reimplement in GDScript). Vertical-slice-first: **gather → cook → sustain → fight** is slice 1. Cartography ([[Chart Loop]]) is slice 2 — the differentiator layers on a working base.

**Status: Locked.** Revisit if the gather→cook→sustain→fight slice fails playtest, or if combat consistently playtests as more compelling than skilling.

---

## ADR 0004 — Controls stay 1–4 + F; click-to-move fork is closed

**Decision (2026-06-11):** Keep the current control scheme: WASD movement, F for basic shot, 1–4 for [[Skills]], E to interact, Space to roll, Q to quaff. The click-to-move + QWER fork is not built.

**Context:** The skills & combat plan (`docs/wyrd-skills-combat-plan.md`) flagged a fork decision after B3/B4a (per-kind enemy stats + Boar charge) gave real fights to judge against. Three options were evaluated after those playtest builds.

**Trade-off:**
- **(a) Keep 1–4 + F** — accepted. WASD already tuned with FATE camera, roll, dash; plays fine against B3/B4a enemies; zero rework.
- **(b) Alt-bind slots 2/3 onto letters (R/V/C)** — rejected. Marginal reach benefit; new key collision (R = inventory rotate); splits muscle memory.
- **(c) Click-to-move + QWER** — rejected without prototyping. Would force rethinking gather channels, roll, and interact targeting — M-sized build for an unconfirmed problem.

**Consequences:** B5 (loadout choice) is unblocked; new skills bind to the existing 1–4 slots. Q stays quaff.

**Status: Locked.** Revisit only if B4b/B5 playtests surface that aiming skills while strafing feels bad — that is the specific problem click-to-move fixes.

---

## ADR 0005 — Combat XP feeds one Trade (Huntcraft), not an OSRS stat block

**Decision (2026-06-12):** Kills grant XP to a single Trade — **Huntcraft** (`hunt`), the fourth Trade alongside Wayfinding, Earthcraft, and Wildcraft. XP is scaled to the slain enemy's vigor: `max(2, hp_max/3)`. Perks: Steady Hands (Hunt 5, +5% crit) and Hunter's Stride (Hunt 10, +5% move speed).

**Context:** B7 on the build plan asked whether combat should grant Trade XP. The three.js model (attack/strength/defence) would add three combat trades. ADR 0003 says combat is one verb; three combat trades would turn the Trades page into a stat screen.

**Trade-off:**
- **Zero combat trades** — rejected. Kills already drop trophies/essence; without a progression voice, a whole verb contributes nothing persistent to the leveling system.
- **Three trades (attack/strength/defence)** — rejected. You don't choose which to train (all train together with one damage type); stat-screen weight with no gameplay.
- **One trade (Huntcraft)** — accepted. Gives combat a ledger without making it the spine; four total Trade rows keeps the Trades page readable; perks feed back into *how you fight*, not how much you must.

**Migration:** Old saves lacking the `hunt` key are backfilled at lv 1 / 0 XP in `SaveGame.load_into`.

**Status: Locked.** Revisit if melee/magic weapon families land (multiple damage types = genuine training choices that might justify splitting Huntcraft).

---

## ADR 0006 — Demo level cap is 17; extend the other ladders, don't compress Wayfinding

**Decision (2026-06-12):** The demo level cap is 17. [[Wayfinding]]'s unlock ladder (boss dens at 8/12/14, Summit at 16) is left untouched. [[Earthcraft]], [[Wildcraft]], and [[Huntcraft]] are extended to match.

**Context:** The demo needs a complete unlock ladder for every Trade. Two options: cap at 10 and compress Wayfinding, or cap at 17 and extend the other three.

**Trade-off:**
- **Cap at 10, compress Wayfinding** — rejected. Wayfinding's spread is the product of the whole chart-loop balancing arc. Compressing would stack multiple unlocks per level, force re-testing the trophy chain, and squeeze out the "every level matters" pacing for the game's spine Trade.
- **Cap at 17, extend others** — accepted. Extending Earthcraft/Wildcraft/Huntcraft is additive data work in existing table shapes (ORE_TIERS, RECIPES, PERKS, INK_RECIPES) with no re-balancing of shipped content. 17 = Summit req (16) + 1, so the capstone is felt one level before the ceiling.

**Consequences:** Every Trade's ladder gets built out to 17 in specs 45+. XP curve unchanged; cap enforced at award time.

**Status: Locked for demo.** Lift post-demo when the cap extends; the relative order inside each ladder is the durable part.

---

## See also

- [[Chart Loop]] — the cartography system central to ADR 0003 and 0006
- [[Trades and Leveling]] — the four Trades shaped by ADRs 0003, 0005, and 0006
- [[Wayfinding]] — the Trade whose ladder governs the demo cap (ADR 0006)
- [[Huntcraft]] — the single combat Trade established by ADR 0005
- [[Combat]] — the "one verb" bounded by ADR 0003 and controlled by ADR 0004
- [[Skills]] — the hotbar abilities bound to 1–4 (ADR 0004)
- [[Dungeon Generation]] — the typed layout deferred in ADR 0002

## Sources

- `docs/adr/0001-inventory-controller-deferred.md`
- `docs/adr/0002-dungeon-layout-typing-deferred.md`
- `docs/adr/0003-cozy-skilling-spine.md`
- `docs/adr/0004-controls-stay-numeric.md`
- `docs/adr/0005-huntcraft-single-combat-trade.md`
- `docs/adr/0006-demo-level-cap-17.md`
