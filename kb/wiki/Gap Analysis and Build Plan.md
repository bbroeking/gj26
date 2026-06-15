---
type: overview
tags: [plan, gap-analysis, build-plan, production]
status: maintained
updated: 2026-06-14
sources: ["kb/wiki/design/", "kb/wiki/Universe Build-Out Plan.md", "wyrd/"]
---

> Master gap analysis + populate-everything build plan, from a 10-agent audit workflow (107 gaps across 7 dimensions). Grep-verified against the live code; red-teamed. See [[Universe Build-Out Plan]] and [[Red-Team Findings]].

# Wayfinder — Master Gap Analysis & Populate-Everything Build Plan

*Lead Producer document, rev. 2026-06-14 (post-Red-Team reconciliation). Scope authority: the cut-line ([[Universe Build-Out Plan|Universe Build-Out Plan §5/§7/§10]]). Committed = Pillar Zero (harden the crypt) + Pillar One (the Pale Veins). Everything else is Horizon and is named here only so it is not mistaken for demo-critical.*

*This revision exists because the prior draft failed its own central promise — "honest about what the codebase already ships." It silently omitted the three findings the same-day Red-Team marked **blocking**: the live multi-tier weapon/gear ladder with rolled stat affixes, the `layout_loader.gd:813` co-op determinism bug, and the palechalk material collision. It also mis-cited verified data (Boar trophy, Summit boss kind). Every one of those is corrected below against the running build, and the soft definitions-of-done have been replaced with sampled, rubric-backed gates. **The grep-honesty rule is now a standing convention (see §0): no doctrine claim ships in this document without a grep against the live code in its footnote.***

---

## 0. Reading rules for this document (so it cannot lie again)

The prior draft's failure mode was prose that contradicted code. Three rules prevent recurrence; every section below obeys them.

1. **Grep-anchored claims.** Any sentence asserting "the code does/doesn't X" carries a `[verified: <grep/file:line>]` tag or it is struck. The doctrine words the prior draft never grepped — `warbow`/`longbow`/`shortbow`/`fire_rate`/rolled-affix/`prefix`/`suffix`/`randf`/`pale_deepore` — are now load-bearing search terms, run, and reported truthfully.
2. **Doctrine vs. shipped reality are stated as a delta, never as a fait accompli.** Where the design says "no gear tier" and the code ships a gear tier, the document names *both* and assigns the reconciliation an owner, a tier, and a test. No "itemization is one verb" sentence appears without the adjacent "...but the build currently ships a 12+ item gear ladder that `test_wyrd_loop.gd:342` *requires*" delta.
3. **Every definition-of-done is an instrument, not an adjective.** "Demonstrably," "recognizably," "well enough," "honest" are banned as gates. Each is replaced by a named artifact (a forced-choice ID test, a scored rubric with a sample size and a threshold, a specific test assertion). §7 is the rubric appendix all DoDs cite.

---

## 1. Executive read

The design substrate is exceptional: a 46-page master plan, 15 deep-design docs, an interlock map with a Tier 0→4 build order and shared-data ownership, a red-team, 260 case studies. The problem is **not** invention. It is that the prose has never been turned into a tracked build — and in **one load-bearing place the prose flatly contradicts the running code, and the test gate enforces the contradiction.**

### 1.1 THE LINCHPIN — the shipped weapon/gear ladder with rolled stat affixes

This is the Red-Team's #1 blocking finding and the prior draft's largest omission. **It is named first, owned first, and gates Tier 2.** The doctrine the entire demo rests on — *"fire_rate scales the Bow ONLY; no new weapon class or gear tier ever; itemization is the trophy ritual"* — is **false against the running build today:**

- `data/items.gd` ships `shortbow` → `longbow` → `warbow` as distinct `category:weapon` tiers. *[verified: items.gd weapon entries]*
- `data/affixes.gd` rolls combat-power prefixes/suffixes onto gear: `sharp`/`heavy` (+damage), `fierce`/`of_precision` (+crit_chance), `swift` (+2–6% **fire_rate**), `of_fury` (+damage), `of_carnage` (+crit_mult), `of_swiftness` (+5–20% **cooldown_reduction**). *[verified: affixes.gd:7-23]*
- `data/crafting.gd` ships `longbow_smith`, `palechalk_longbow_smith` (magic), a rare longbow, `warbow_smith` — the smithing treadmill. *[verified: crafting.gd grep]*
- `player_controller._derive_stats` (~line 1022) folds `sums.fire_rate` from equipped gear into `fire_cooldown`. **A rolled rare "Swift longbow of Swiftness" literally out-fires the base bow right now.** *[verified: player_controller.gd:1018-1028]*
- **The test gate *requires* this ladder to exist:** `test_wyrd_loop.gd:342` asserts `gear >= 12` ("forge carries the full gear ladder"), inside one of the four protected suites. *[verified: test_wyrd_loop.gd:342]*

**This is a mutually-unsatisfiable pair as currently written:** the "no new gear tier" doctrine and the green `gear >= 12` assertion cannot both hold. If you de-power/remove the ladder per doctrine, you break a protected suite; if you keep it, the doctrine is a lie. *The prior draft asserted both and never named the collision.* Resolving it is **ADR 0010**, the first ADR written, and it is the hard prerequisite for the Ledger, the dissolve-to-ink-dust sink, the no-arbitrage economy, the Palechalk Ink cross-trade chain, and the summary card — **all of which reason about a loot economy whose existence is undecided.**

**The decision space (ADR 0010 must pick one and rewrite the gate accordingly):**

| Option | What it does to combat power | What it does to `test_wyrd_loop.gd:342` | Cozy-doctrine fit |
|---|---|---|---|
| **(a) Remove** weapon tiers + rolled stat affixes entirely | Bow is the only weapon; no rolled combat stats anywhere | Delete or invert the gate; the forge no longer carries a gear ladder | Cleanest; largest blast radius — touches `test_combat`, `test_equipment`, `test_stats`, drops, smithing |
| **(b) Freeze at zero combat power** *(recommended)* | Weapon tiers + affixes still *exist as items/cosmetic/economy fodder* but `_derive_stats` no longer reads `fire_rate`/`crit_*`/`damage`/`cooldown_reduction` from the gear sum — gear confers **zero** combat power; the Bow's only power source is trophy boons | Rewrite the assertion's *intent*: the forge still produces ≥12 craftable items (so the gate still has a target), but a companion assertion proves **no equipped gear changes `fire_cooldown`/`crit`/`damage`** | Preserves the smithing faucet and the dissolve-to-ink sink's input, surgically severs the ARPG power vector, smallest blast radius |

**Recommendation: (b).** It is the only option under which the Ledger's dissolve-to-ink-dust sink (§Tier 3) is *coherent* — there must be gear to melt — while making the cozy claim *true in code*: equip-for-power is gone, the Bow is the one verb, gear is economy/cosmetic fodder. (b) also means `test_wyrd_loop.gd:342` keeps a meaningful target instead of being inverted. Either way, **the rewritten `_test_economy_gate` is the enforcement tripwire** — the doctrine is only as real as the assertion that the gear sum contributes zero combat power.

### 1.2 The other two blocking omissions, now owned

- **The co-op determinism bug is a *shipped bug, not a future risk.*** `layout_loader.gd:813` uses a bare `randf() < 0.25 * _trophy_mult` for the elite-trophy roll inside the per-peer build path, while every sibling roll routes through the chart-seeded `_rng` (line 797 `_rng.randf()`, line 801 `_rng.randi_range`). *[verified: layout_loader.gd:797,801,813]* **Co-op peers diverge on which elites carry trophies** — desyncing party loot and Atlas counters. One-line fix (`randf()` → `_rng.randf()`), but it is a **Tier-0 prerequisite** under every co-op/trophy/Atlas bullet, and `_test_determinism` never asserts trophy placement today. *The prior draft put "RPC boss telegraphs to all peers" in Phase 1 on top of a build path where peers already disagree on trophies, and never scheduled the fix.*
- **The palechalk material collision makes the "cross-trade chain" deepen the gear ladder it claims to avoid.** `palechalk` ships as a raw gatherable ore (`gather.gd:17,175`, req_lv 7) whose current sinks are **gear smithing recipes** (`palechalk_longbow_smith` et al.) and ore-vault drop tables (`gather.gd:216-217`). *[verified: gather.gd:17,121,175,216-217]* The Gathering Deep Design names a *distinct* material, `pale_deepore` — **which does not exist in the data** *[verified: grep `pale_deepore` → 0 hits]*. The plan's headline new craft, "Palechalk Ink refined from deep ore," is therefore false-in-data until either (i) a distinct `pale_deepore` material is introduced as the ink's sole input, or (ii) the palechalk gear recipes are removed per ADR 0010. **Layering an ink-refine onto the existing palechalk *adds a sink to a material on the weapon treadmill* — cozy-washing an ARPG input.** A material-disambiguation step (§Tier 2) now precedes the ink work.

### 1.3 Verified-data corrections (the prior draft cited these backwards)

| Prior-draft claim | Shipped reality *[verified]* |
|---|---|
| "Boar tusk = +knockback resist" boon example | `burrow_boar` trophy = `wightpelt`, **not a tusk** *(layout_loader.gd:124)* |
| "Hedgemother thorn = bleed full-duration" boon example | `hedgemother` trophy = `tusker_tusk` — **the tusk belongs to the Hedgemother, not the Boar** *(layout_loader.gd:121)* |
| "Wolf fang = +1 dodge i-frame" | `wolf_alpha` trophy = `alpha_fang` — **correct** *(layout_loader.gd:127)* |
| "Summit reuses scaled `hedgemother_v2` — already-the-same-being" | The **model** is reused (`hedgemother_v2.glb`, scale 3.75→4.6) but `hedgemother_queen` is a **distinct `boss_kind` string** with its own stat block (hp 160, trophy "") *(layout_loader.gd:130-131; charts.gd:64)*. "Already the same being" is an **unresolved reconciliation, not canon.** |

The trophy-boon table in §Tier 3 is rebuilt against the **actual trophy strings** (`wightpelt`, `tusker_tusk`, `alpha_fang`). The Summit reconciliation is filed as an explicit ADR-0009 question, not asserted as fact.

### 1.4 The 5–8 most important gaps overall

1. **The gear-ladder linchpin** (§1.1) — blocker. Contradicts the differentiator *and* the test gate; everything in itemization depends on its resolution.
2. **No meta-shell exists at all.** The game boots straight into `Town.tscn` — no title screen, main menu, pause menu, options, quit, death screen, or credits. Esc opens the co-op "Lantern" (misnamed `system_menu.gd`). *A demo with no front door cannot be distributed.* Framework, not Horizon.
3. **The asset pipeline has no executable.** `clean_ai_mesh.py` / `register_ai_character.py` were deleted with the three.js prototype; `scripts/` is empty; `docs/character-pipeline/` is gone from disk. The "clone the crypt" cadence the *entire* Pillar One exit criterion rests on has zero runnable tooling.
4. **The save migration ladder does not exist and the test harness is destructive.** `save_game.gd` is `VERSION=1` with a destructive discard (line 53–54) the design forbids. Six Tier-2 systems each assume an additive migrator slot. `_test_save_roundtrip` writes-then-deletes the *real* save path. Hardest ordering constraint in the build.
5. **The co-op determinism break is a shipped bug** (§1.2). One-line fix; underlies the entire trophy/Atlas/co-op chain.
6. **The KB has no operating surface.** No backlog, no status dashboard, no traceability (zero of 17 deep designs cite a spec path), no DoD convention. The three bridge artifacts the plan names — `pillar-one-pale-veins.md`, `biome-kit-template.md`, ADR 0007/0008/0009 — **do not exist** *[verified: ADRs stop at 0006, specs at 46]*.
7. **The combat-reading mechanic — the differentiator — is 100% unbuilt.** `boss.gd` has no Poise / recovery-window / Reeling (only `_charging/_atk_cd/reset_fight`) *[verified]*. The "rides off the existing phase machine" claim is false; it must be authored from scratch **plus a deterministic headless Poise-fill hook** (no `WYRD_FAST_COMBAT` exists). The one verb that makes Wayfinder *Wayfinder* is zero code with no test harness.
8. **The spine's third verb (cook) and Pillar One gather-depth are under-designed and collide with shipped data** (§1.2 palechalk). Cooking has no deep-design doc (only "one stabilizing draught"). The signature ink's input/name/"sole-sink" claim is false until `pale_deepore` lands and the palechalk gear recipes are reconciled.

**The through-line:** every blocker is a *contract reasoned through in prose but never written as an ADR, a spec, a tracker row, or a test assertion.* The fix is Tier-0 governance + three bridge documents + making the KB drive the build.

---

## 2. The dependency graph (reproducing the Interlock's Tier 0→4 build order)

The prior draft collapsed the Interlock's prerequisite arrows into two prose phases, so it could not detect when a Tier-3 surface was sequenced before its Tier-2 producer. **This section reproduces the prerequisite graph so mis-ordering is visible.** Read top-to-bottom; nothing builds before everything it points to.

```
TIER 0 — FOUNDATIONS (build-parity + persistence + governance)
  [0.0] non-destructive _test_save_roundtrip ──┐ (MUST precede 0.1; ladder testing writes the real save)
  [0.1] save migration ladder (MIGRATORS[]) ◄──┘
          ▲   ▲   ▲   ▲   ▲   ▲   (six persisted fields below each REQUIRE the ladder)
          │   │   │   │   │   └── seen_debriefs (Tier 4)
          │   │   │   │   └────── atlas_counts (Tier 4)
          │   │   │   └────────── trades[].masteries (Tier 3 Earthcraft pick) ← named field, reserved here
          │   │   └────────────── ink_stability_bonus per-instance (Tier 2)
          │   └────────────────── ledger boons earned (Tier 3)
          └────────────────────── Pale-Veins typed-twin resolution state (Tier 2)
  [0.2] co-op determinism fix (layout_loader.gd:813 → _rng.randf()) ── REQUIRED-BY all co-op/trophy/Atlas work
  [0.3] gear-ladder ADR 0010 (LINCHPIN) ── REQUIRED-BY ledger, dissolve-sink, no-arbitrage, palechalk-ink, summary-card
  [0.4] WYRD_FAST_COMBAT deterministic hook ── REQUIRED-BY Poise/Reel assertions (Tier 2)
  [0.5] string table strings.gd (+ "Second Pour" rename) ── REQUIRED-BY every player-facing surface
  [0.6] ADRs 0007 (no-arbitrage) / 0008 (cut-line) / 0009 (anti-escalation) / 0011 (host-auth co-op)
  [0.7] run_tests.sh gate + biome-kit-template spec (#47) + perf-budget numbers + Build Board

TIER 1 — SHIPPED SPINE (verify + retrofit to new contracts; do NOT rebuild)

TIER 2 — PILLAR ONE DEEPENINGS
  [2.0] pillar-one-pale-veins spec (#48) ── content contract for everything below
  [2.1] palechalk material disambiguation (pale_deepore) ◄── 0.3   ── REQUIRED-BY 2.4 ink-refine
  [2.2] Poise/stance-break/Reeling on boss.gd ◄── 0.4              ── REQUIRED-BY 2.3, summary-card
  [2.3] co-op _boss_state RPC ◄── 0.2, 2.2
  [2.4] gather-depth: ink-refine + GRAIN_WINDOW ◄── 2.1
  [2.5] biome_affixes.gd typed-twin table (additive) ◄── 0.1       ── REQUIRED-BY summary-card (Tier 3)
  [2.6] room.hazard hook + Boar tusk-quake verb (NET-NEW boss code, not a reskin)
  [2.7] Summit kind reconciliation ◄── 0.6 (ADR 0009)

TIER 3 — SURFACES & SINKS
  [3.0] ledger.gd + TROPHY_BOONS + dissolve-to-ink ◄── 0.3, 0.1
  [3.1] summary card ◄── 2.5 (typed twins), 2.2 (Poise display)   ── (was mis-placed into Phase 1)
  [3.2] Almanac/HUD/rumor copy ◄── 0.5, 3.1
  [3.3] Earthcraft pick-one mastery ◄── 0.1 (trades[].masteries reserved at 0.1)

TIER 4 — RETENTION / NARRATIVE
  [4.0] Living Atlas ONE counter atlas_credit() ◄── 0.1, 0.2  ── (Almanac is a VIEW, not a 2nd counter)
  [4.1] Codex / Mara debriefs / Hod arrival ◄── 0.1, 0.5
```

**Three mis-orderings the prior draft hid, now corrected by this graph:**

- **The summary card is Tier 3, not Phase 1.** It depends on `[2.5]` the typed-twin table, which the prior draft *partially deferred* to "one biome." Building the card before the resolved-twin data model exists meant displaying state it could not populate. The card is now `[3.1]`, gated on `[2.5]`. **And the inscribe()-seam contradiction is resolved (§7-S10): the card shows *one* state, not two.**
- **`masteries[]` is a named, reserved migrated field at `[0.1]`,** not an afterthought. The prior draft's Phase-0 save work named only the Huntcraft backfill; the Earthcraft mastery pick `[3.3]` would have shipped against a schema the ladder didn't cover — the exact version-bump-wipe the ladder exists to prevent.
- **The Boar tusk-quake is net-new Tier-2 code `[2.6]`, not a pre-existing asset to "house."** `boss.gd` has only `_charging/_atk_cd/reset_fight` — no tusk-quake verb, no `room.hazard` hook *[verified]*. The plan now budgets the new boss verb *and* its room-hazard plumbing as real build work.

---

## 3. The Gap Map

By dimension, then severity. Cross-auditor duplicates merged and flagged **[CONSOLIDATED]**. Severity: 🔴 blocker · 🟠 high · 🟡 medium · ⚪ low.

### 3A. The linchpin & code-vs-design contradictions

| Sev | Gap | Tier | Files / contract *[verified]* |
|---|---|---|---|
| 🔴 | **Gear/weapon ladder reconciliation (THE LINCHPIN)** | 0 | `items.gd`, `affixes.gd:7-23`, `player_controller.gd:1018-1028`, `crafting.gd`, `test_wyrd_loop.gd:342` |
| 🔴 | **Co-op determinism break — bare `randf()` trophy roll** | 0 | `layout_loader.gd:813` (siblings: 797/801); untested by `_test_determinism` |
| 🔴 | **Save migration ladder absent + destructive discard** `[CONSOLIDATED ×3]` | 0 | `save_game.gd:11,53-54`; `_test_save_roundtrip` |
| 🔴 | **Poise / stance-break + recovery-window on `boss.gd`** | 2 | `boss.gd` (only `_charging/_atk_cd/reset_fight`) |
| 🟠 | **Palechalk material collision + `pale_deepore` disambiguation** `[CONSOLIDATED with Content]` | 2 | `gather.gd:17,175,216-217`; `pale_deepore` = 0 hits; depends on 0.3 |
| 🟠 | Co-op `_boss_state` RPC (Poise/telegraph/Reeling sync) | 2 | `net_game.gd` (no `_boss_state`); depends on 0.2 + 2.2 |
| 🟠 | `ledger.gd` + TROPHY_BOONS (`wightpelt`/`tusker_tusk`/`alpha_fang`) + dissolve-to-ink-dust | 3 | `data/ledger.gd` (missing); depends on 0.3 |
| 🟠 | **`room.hazard` hook + Boar tusk-quake verb — NET-NEW boss code** | 2 | `boss.gd` (no hazard hook, no quake verb) |
| 🟡 | `strings.gd` Phase-0 string table + **"Second Pour" name collision** `[CONSOLIDATED ×4]` | 0 | `data/strings.gd` (missing); `game.gd:383,446` |
| 🟡 | `biome_affixes.gd` Pale Veins typed-twin table (**additive-only** over boolean path) | 2 | `game.gd:766-774`, `charts.gd:365` |
| 🟡 | Summary card / Almanac / HUD Poise meter; **inscribe() honesty seam (S10)** | 3 | `charts.gd:348-365` (twin resolves at inscribe) |
| 🟡 | No-arbitrage ADR + economy-gate assertion for the ink sink | 0 | `test_wyrd_loop.gd:316-342`; ADR (missing) |
| 🟡 | Wayfinder's Mark cooldown-reset balance gate (wire to **boss reeling signal**, never `_try_skill`) | 2 | `boss.gd` (no reeling signal) |
| 🟡 | **Huntcraft XP-faucet guardrail** (combat must not dominate gather/craft throughput) | 2 | ADR 0005 formula `max(2, hp_max/3)`; balance-sim threshold |
| ⚪ | Summit capstone kind reconciliation (`hedgemother_queen` distinct kind vs reused model) | 2 | `layout_loader.gd:130-131`, `charts.gd:64` |
| ⚪ | `ink_stability_bonus` per-instance migration | 2 | `game.gd:351`, `save_game.gd:81-86` |

### 3B. Framework / meta-shell

| Sev | Gap | Tier | Note |
|---|---|---|---|
| 🔴 | **Title screen / main menu** | fwk | sole mention = a 4-line aside in Onboarding DD §4 |
| 🔴 | **Pause menu + quit-to-menu / quit-to-desktop** | fwk | Esc currently opens the Lantern, not pause |
| 🟠 | Options / settings (audio sliders, graphics, gameplay) | fwk | audio is binary-mute-only today |
| 🟠 | Controller / gamepad + input remapping (no `[input]` map) | fwk | table-stakes for couch co-op |
| 🟠 | Accessibility (colorblind-safe twins, reduce-motion, captions, text-scale) | fwk | SAGE/TERRACOTTA red-green fails CVD |
| 🟠 | **Death / defeat / run-failure return UX** | fwk | only a silent white-out respawn exists |
| 🟠 | Save-slot / load / delete UI + New-Game-over-save confirm | fwk | destructive wipe with no confirm dialog |
| 🟠 | **Cold-open / first-boot presentation** ("first 2 minutes") | 0 | mechanics designed, presentation undesigned |
| 🟡 | Credits / attribution (ElevenLabs, Meshy, Midjourney, Caveat OFL) | fwk | license obligation, zero coverage |
| 🟡 | Co-op session/lobby front-end vs meta-shell (Lantern mislabeled) | fwk | naming collision is itself a clarity gap |
| 🟡 | Build / distribution readiness (export presets, icon/splash, version) | fwk | absent from cross-cutting workstreams |
| 🟡 | Controls / how-to-play reference | fwk | hints are once-only, in-world |
| 🟡 | **Cooking as a designed system** (no Cooking DD; only one draught) | 2 | spine's third verb under-designed |

### 3C. Content authoring (Pale Veins ≈ zero authored)

| Sev | Gap | Tier |
|---|---|---|
| 🔴 | **Pale Veins tile kit** (concept art + ~20 GLBs) — unstarted | 2 |
| 🟠 | Hedgewight signature mob + 4-creature family (orphan `hedgewight_v2.glb`, not in ENEMY_KINDS) | 2 |
| 🟠 | **Boss gimmick wiring + text** (Hedgemother thorn-arena + phase-3 summon; **Boar tusk-quake = net-new verb**) | 2 |
| 🟠 | Pale-Veins affix twin roster (good/bad copy + typed table) | 2 |
| 🟠 | **Palechalk Ink recipe + `pale_deepore` disambiguation** `[CONSOLIDATED with 3A]` | 2 |
| 🟠 | Wayfarer's Codex content + `codex.gd` (~16 verbatim-lore entries) | 4 |
| 🟠 | **String table `data/strings.gd`** `[CONSOLIDATED ×4 auditors]` | 0 |
| 🟠 | Mara milestone debriefs + Hod Pale-Veins arrival line (`seen_debriefs` not a save field) | 4 |
| 🟠 | **Biome-kit template doc + crypt-retrofit punch-list** `[CONSOLIDATED ×3]` | 0 |
| 🟡 | **Almanac pages + request board (blocked on the ONE-counter merge — see §scope-drift)** | 4 |
| 🟡 | Procedural rumor headers + summary-card copy (blocked on S10 honesty resolution) | 3 |
| 🟡 | Stabilizing-draught cook content + recipe row (seam S7) | 2 |
| 🟡 | Pale Veins lore anchor delivered diegetically + new gather flavor | 4 |
| 🟡 | Pale Veins audio bed + Boar sting + foley `[CONSOLIDATED with Art]` | 2 |
| 🟡 | **Trophy-boon copy — keyed to actual strings** (`wightpelt`/`tusker_tusk`/`alpha_fang`, demo needs only the Boar `wightpelt` boon) | 3 |
| ⚪ | World expansion (Wolds, festivals, factions, full cast) — **Horizon, do not build (P7/P10)** | post |

### 3D. Art & audio assets

| Sev | Gap | Tier |
|---|---|---|
| 🔴 | **`clean_ai_mesh.py` + `register_ai_character.py` deleted — pipeline has no executable** | fwk |
| 🔴 | **`docs/character-pipeline/` gone from disk** (recipes A/B/C + socket bone-map live only in wiki prose) | fwk |
| 🟠 | **Pale Veins biome kit ≈ no art** (only `prop_ore_vein_v1.glb`) `[CONSOLIDATED with Content]` | 2 |
| 🟠 | Music: only `town_theme.mp3` — no dungeon bed, no boss sting (crypt ships without its bed) | 1 |
| 🟠 | Almanac panel + summary-card UI absent; `capture_ui.sh` exposes 2 surfaces, not 10 | 3 |
| 🟠 | `docs/concept-art/INDEX.md` dummy-debt tracker missing — dummies can ship as final | 0 |
| 🟡 | **Boss-clip pipeline UNPROVEN end-to-end** (socket empties just authored "on the B-approach"; no shipped boss clip) — custom-clips-for-bosses is highest-risk path, not safe | 2 |
| 🟡 | Hedgemother gimmick wiring (`vine_grow.gdshader` exists but unused; no summon) | 2 |
| 🟡 | Quadruped auto-rig impossible (rat/Boar/Pale-kin → Godot procedural animator only) | 2 |
| 🟡 | Burrow Boar model is an unvalidated early clone (3 competing GLBs, pre-locked-art) | 2 |
| 🟡 | Art Bible locked palette table blank; hero shots stale Lumbridge framing | 0 |
| ⚪ | Inventory icons exist for ~6 items; no trade emblems / full material set | 3 |

### 3E. Tooling & infra

| Sev | Gap | Tier |
|---|---|---|
| 🟠 | **No test runner / commit gate** for the four protected suites (each hand-typed) | 0 |
| 🟠 | **Biome-kit clone template + scaffold tooling** `[CONSOLIDATED ×3]` | 0 |
| 🟠 | **Balance-sim script** (designed against deleted `src/game/combat.js`; must re-home to GDScript) | 1 |
| 🔴 | **No deterministic test hook for timing mechanics** (no `WYRD_FAST_COMBAT`; only vein-reading has `WYRD_FAST_CHANNEL`) | 0 |
| 🟠 | **Save-migration tooling + non-destructive roundtrip** `[CONSOLIDATED with blocker]` | 0 |
| 🟠 | **Headless 2-process co-op harness** (build-parity contract test = the Tier-0 piece) | 0 |
| 🟡 | No CI / automation (no `.github/workflows`) | fwk |
| 🟡 | String table (no Godot i18n, no `tr()`) `[CONSOLIDATED]` | 0 |
| 🟡 | Missing `WYRD_UI_SHOT` surfaces for Almanac + summary card | 3 |
| 🟡 | PLAYTEST.md + playtest instrumentation unbuilt (no telemetry) `[CONSOLIDATED with Process]` | fwk |
| 🟡 | No `WYRD_SEED` top-level run-pin hook (procgen seeded, boot isn't) | 1 |

### 3F. Process & production

| Sev | Gap | Tier |
|---|---|---|
| 🔴 | **`biome-kit-template.md` spec (#47)** — unit of release — does not exist | 0 |
| 🔴 | **`pillar-one-pale-veins.md` spec (#48)** — demo content contract — does not exist | 2 |
| 🔴 | **Planned bridge ADRs 0007/0008/0009 do not exist** `[CONSOLIDATED with KB]` | 0 |
| 🔴 | **Destructive `_test_save_roundtrip` named in 4 docs, fixed in none** — symptom of the missing tracker | 0 |
| 🟠 | ADRs: 0007 (no-arbitrage), 0008 (cut-line, P7), 0009 (anti-escalation), 0010 (**gear-ladder linchpin**), 0011 (host-auth co-op) | 0 |
| 🟠 | **Single task board / backlog** — none; state smeared across 3 disagreeing docs `[CONSOLIDATED with KB]` | fwk |
| 🟠 | Per-system Definition of Done `[CONSOLIDATED with KB]` | fwk |
| 🟠 | **Mechanic→suite assertion map (17-vs-4 reconciliation)** — which suite gains which new assertion | 0 |
| 🟠 | Playtest recruiting + cadence ops + scoring rubric (no instrumentation/session-script) | fwk |
| 🟠 | Risk register (living, owned) — §6 table + red-team are static | fwk |
| 🟡 | Milestones with Tier-0→4 gates ("migration ladder shipped" unblocks Tier 2) | fwk |
| 🟡 | QA gate governance — 17 `test_*.gd`, only 4 are gates; other 13 undefined | fwk |
| 🟡 | Per-pillar perf budget numbers (named gate, no value) | 0 |
| 🟡 | Dummy-debt burn-down tracker `[CONSOLIDATED with Art]` | fwk |

### 3G. KB-as-operating-system

| Sev | Gap | Tier |
|---|---|---|
| 🔴 | **No master backlog / status tracker** — `Current State.md` predates the plan `[CONSOLIDATED with Process]` | fwk |
| 🔴 | **Bridge specs + ADRs do not exist** `[CONSOLIDATED with Process]` | 0 |
| 🔴 | **Open red-team reconciliations + seams S1–S10 have no tracked closure path** | 0 |
| 🟠 | No traceability ledger: deep-design → spec → code → test (zero designs cite a spec path) | fwk |
| 🟠 | **CONTEXT.md glossary missing every new demo term** + still self-describes as "ARPG / Diablo/PoE" | 0 |
| 🟡 | No frontmatter dashboard (all 17 designs frozen `status:draft`; no `build_tier`/`impl_status`) | fwk |
| 🟡 | KB schema has no "build" operation (only ingest/query/lint) | fwk |

**De-duplication summary.** Four findings were each flagged by 3–4 auditors and are the genuine cross-cutting blockers: **(1)** the string table `strings.gd`, **(2)** the save migration ladder + destructive roundtrip, **(3)** the biome-kit-template spec, **(4)** the missing backlog/DoD/traceability surface. Their repeated independent discovery is the signal — these are the substrate everything routes through.

---

## 4. The populate-everything plan

Sequenced by the §2 dependency graph. Three parallel tracks: **CONTENT** (strings + asset authoring), **ART/AUDIO** (AI pipeline), **FRAMEWORK/PROCESS** (meta-shell + governance). "Who does it": **DEV** (human lead — decisions, GDScript, balance), **AI-PIPE** (Midjourney→Meshy→Blender→Godot art / ElevenLabs audio / LLM copy drafts), **AGENT** (Claude Code subagent — scaffolding, linters, mechanical wiring under DEV review).

**Scope honesty up front (correcting the prior draft's anti-overreach rhetoric).** Pillar One as previously bundled — five net-new systems + five cross-cutting workstreams "as one demo" — is a multi-month senior-team slate, and the Red-Team flagged co-op and the affix table as *individually* over-scoped. This revision **cuts Pillar One to a defensible core** and moves the over-reach to an explicit *Pillar-One-Stretch* shelf (§4 end) that ships only if the core lands. The cut-lines are named below per item, not buried.

### TIER 0 — Foundations

| Deliverable | Fills | Who | Definition of Done (instrumented) |
|---|---|---|---|
| **Non-destructive `_test_save_roundtrip`** *(FIRST)* | tooling blocker | DEV | Roundtrip redirects `SAVE_PATH` to a temp path; a unit assertion proves the real save path is untouched after the suite runs. **Lands strictly before the ladder** so ladder testing cannot nuke a dev save. |
| **Save migration ladder** | save blocker | DEV | `save_game.gd` gains `MIGRATORS[]`; version-mismatch *migrates* not discards (replaces line 53–54); Huntcraft backfill = migrator #1; **`trades[].masteries`, `ink_stability_bonus`, `ledger_boons`, `atlas_counts`, `seen_debriefs`, twin-resolution-state reserved as named additive fields.** A checked-in v0 fixture migrates to current with zero field loss (asserted). |
| **Co-op determinism fix** | randf blocker | DEV | `layout_loader.gd:813` → `_rng.randf()`. `_test_determinism` extended: **two builds on the same `chart_seed` produce identical trophy/elite placement** (asserted, not eyeballed). |
| **Gear-ladder ADR 0010 + reconciliation (LINCHPIN)** | linchpin | DEV | ADR records the chosen option (recommend **b: freeze-at-zero-power**). `_derive_stats` no longer folds `fire_rate`/`crit_*`/`damage`/`cooldown_reduction` from the gear sum. `_test_economy_gate` rewritten: the forge still produces ≥N craftable items **AND a new assertion proves equipping any gear changes `fire_cooldown`/crit/damage by 0.** Four suites green. **The other 13 suites (`test_combat`/`test_equipment`/`test_stats`) audited and any gear-power assertion in them updated.** |
| **`WYRD_FAST_COMBAT` deterministic combat hook** | tooling blocker | DEV | Env-collapsed/frame-stepped Poise-fill + recovery-window timing analogous to `WYRD_FAST_CHANNEL`. **Acceptance: `test_skills` can drive a boss to a Reel window headlessly and assert the Reel reset fires** — the harness the Red-Team says cannot exist today. Lands before Tier-2 combat. |
| **String table `strings.gd` + "Second Pour" rename** | 4-way | AGENT (extract) + DEV (review) | Keyed dict + accessor; systemic strings routed through stable IDs; **the chart-revive "Second Pour" renamed before any `perk_active` lookup collides with the shipped Wildcraft `second_pour` perk** *(game.gd:383,446)*. Assertion: no duplicate key resolves to two perks. |
| **ADRs 0007/0008/0009/0011** | governance | DEV | 0007 no-arbitrage (+ economy-gate assertion); 0008 cut-line governance (trigger + promote-from-Horizon ritual + where the cut-line lives); 0009 anti-escalation (no King of Brambles; Summit is a quieting; **includes the `hedgemother_queen`-kind reconciliation as a named open question, not a settled fact**); 0011 host-auth co-op invariant (each peer saves itself; shared run state host-RAM-only; Charter blocked on host-change survival). |
| **`run_tests.sh` + commit gate + mechanic→suite map** | tooling/process | DEV | One wrapper runs the four protected suites with an aggregated exit code; pre-commit hook/Makefile. **A `docs/qa-gate.md` maps each new mechanic to its owning suite + assertion** (Poise→`test_skills`; trophy parity→`_test_determinism`; ink-refine→`test_items` or `test_wyrd_loop`; ledger→new assertion in `test_wyrd_loop`; gear-zero-power→`_test_economy_gate`) and classifies the other 13 suites as gate/non-gate. |
| **biome-kit-template spec (#47)** | unit-of-release | DEV | `docs/specs/47-biome-kit-template.md`. **DoD is concrete, not "well enough": every checklist box names a file path, an owner, and is filled-in against the crypt as the worked example.** Gaps (Hedgemother gimmick, spec-05 summon) filed as rows on the Build Board. |
| **Perf budget numbers** | process | DEV | Draw-call ceiling for a ~20-piece tileset, instancing plan, Boar-fight enemy cap — written **as numbers**; a headless or in-editor check reports actual vs. ceiling. |
| **CONTEXT.md glossary + Current State refresh** | KB | DEV | Every demo term (Poise/Reeling, Wayfinder's Mark, vein-reading, Ledger, **`pale_deepore` vs. palechalk**, Almanac, Codex, biome kit, migration ladder) added with an *Avoid* line; the "ARPG / Diablo/PoE" self-framing struck. |

**Tier DoD:** *Tier-0 complete* = the milestone that unblocks Tier 2. All four suites green via `run_tests.sh`; ladder + roundtrip safe; **ADR 0010 merged and the gear sum proven zero-power**; determinism fix asserted; the three bridge specs/ADRs exist; the mechanic→suite map exists.

### TIER 1 — Already-shipped spine (verify, don't rebuild)

The cozy spine (gather→craft→chart→delve→economy→trophy chain→Summit) already ships and is the game. Tier-1 work is **verification + retrofitting to new contracts**, not features. DoD: existing systems route systemic strings through `strings.gd`; persisted fields are migrator-clean; the crypt passes the #47 checklist (with filed gaps); the **balance-sim is re-homed to GDScript** (it was designed against the deleted `src/game/combat.js`) so Tier-2 power spikes have a check to run against.

### TIER 2 — Pillar One deepenings (CUT to a defensible core)

| Deliverable | Fills | Who | DoD (instrumented) |
|---|---|---|---|
| **pillar-one-pale-veins spec (#48)** | content contract | DEV | `docs/specs/48-pillar-one-pale-veins.md` covers the **CORE** demo content only (below). Tier 2 builds against it. |
| **Palechalk disambiguation: `pale_deepore`** *(precedes the ink)* | linchpin-adjacent | DEV | A distinct `pale_deepore` material is added as the **sole** input to Palechalk Ink, **OR** ADR 0010 removes the palechalk gear recipes so palechalk itself becomes gather-only. Assertion: the ink's input material has **no gear-recipe sink** *(grep the crafting table)*. The "gather-only, ink is the sole sink" claim is now true-in-data. |
| **Poise / stance-break + Reeling window** | combat blocker | DEV | `boss.gd` gains `poise/poise_max/in_recovery_window/reeling` authored against the **real** phase vars (`_charging/_atk_cd`); Mark reset wired to a **boss `reeling` signal, never `_try_skill`**; `test_skills` asserts the Reel reset fires inside a Reel window via `WYRD_FAST_COMBAT`. |
| **Gather-depth: ink-refine + GRAIN_WINDOW** | high | DEV + AGENT | `refine:` recipe consumes `pale_deepore` → grade-matched ink `stability_bonus`; **branching seams ship as deterministic *decor* (not grid-mutating)** so co-op peers stay parity-clean (seam S5). |
| **`biome_affixes.gd` Pale Veins typed-twin subset** | medium | AGENT + DEV | **Additive-only** typed twin table for the Pale-Veins subset *only*; the boolean `good` path is untouched (30+ call-sites depend on it — assertion: existing affix tests still green). |
| **`room.hazard` hook + Boar tusk-quake verb** | high *(NET-NEW)* | DEV | The hazard plumbing is built and the tusk-quake is authored as a real boss verb — **budgeted as new code, not a reskin.** Boar fight playable end-to-end headless. |
| **Huntcraft XP-faucet guardrail** | high | DEV | Balance-sim asserts a concrete threshold: **combat XP/hour ≤ the slower of the gather/craft faucets across a representative Pale-Veins session** (threshold value recorded in the ADR-0005 notes). Ships as a balance-sim acceptance check, not prose. |
| **Co-op `_boss_state` RPC** | high | DEV | `net_game.gd` carries `{phase, tele_kind, tele_t01, poise01, reeling_t}`; whole party reads the same Reel window. **CUT to Stretch: reconnect-grace, Party-Lantern, voiced-join.** |
| **Summit kind reconciliation** | low | DEV | Per ADR 0009: either `boss_kind` collapses to the scaled `hedgemother_v2` (quieted-not-killed) **or** the doc records `hedgemother_queen` as the deliberate distinct kind. **No new boss either way; the choice is written down, not assumed.** |
| **Stabilizing-draught cook content** | medium | DEV + AI-PIPE | One cook→chart recipe + item + Bramblewood-voice flavor; seam S7 (quaffable vs bench-consumable) resolved in the spec. |

**Tier DoD:** the #48 **core** spec is fully built; the balance-sim validates the Pale-Veins affix table, the Mark cooldown-reset, **and** the Huntcraft-faucet threshold on demand; each new mechanic has its named assertion in its named suite (per the mechanic→suite map); co-op guests see boss telegraphs + Poise correctly **on top of the fixed determinism path.**

### TIER 3 — Surfaces & sinks

| Deliverable | Fills | Who | DoD |
|---|---|---|---|
| **`ledger.gd` + dissolve-to-ink-dust** | high | DEV | TROPHY_BOONS keyed to the **actual** trophy strings — demo needs only the Boar `wightpelt` boon; boon examples re-authored (NOT the prior draft's wrong tusk/thorn cites). `LEDGER_CAP`; seam S1 resolved (one trophy per kill, player chooses). **Ships only after ADR 0010 decides whether gear loot exists** — the dissolve sink presupposes a gear stream. |
| **Summary card + Almanac panel + HUD Poise meter** | medium | DEV + AI-PIPE | Depends on the typed-twin table `[2.5]`. **Honesty seam S10 resolved by picking ONE card state, written into #48:** the card shows **pre-roll live odds at the *preview* step** (before inscribe stamps the coin), **and the *stamped* chart shows the resolved twins** — two surfaces, never one card claiming both. Assertion: the previewed odds and the stamped resolution are produced by the same seed and never drift. Each panel: ninepatch pass + `WYRD_UI_SHOT` surface + `capture_ui.sh` entry. |
| **Rumor headers + summary-card copy** | medium | AI-PIPE draft → DEV | Deterministic one-line storybook blurb per chart from fragments in `strings.gd`; honest twin descriptions. |
| **Earthcraft pick-one-of-N mastery** | medium | DEV | Stored in the **reserved `trades[].masteries` field** (added at Tier 0, not retrofitted). The choice survives a version bump (asserted via the v0→current fixture). |

### TIER 4 — Retention / narrative

| Deliverable | Fills | Who | DoD |
|---|---|---|---|
| **Living Atlas v1 + `atlas_credit()` — ONE counter** | medium | DEV | **ONE `atlas_counts` counter; the Almanac is a *view* onto it, not a second counter** (resolves the S2/S3 double-feel the Interlock forbids — see §scope-drift). One chart completion moves one corner exactly once. Counter stored via the migration ladder. Assertion: a single completion increments the counter by exactly 1 and restores exactly one corner. |
| **Wayfarer's Codex + `codex.gd`** | high | AI-PIPE → DEV | ~16 verbatim-from-WORLD_LORE entries; unlocked first-discovery, never a gate. |
| **Mara debriefs + Hod arrival line** | high | AI-PIPE → DEV | 5 rotating milestone fragments ending on the locked capstone line; Hod's Pale-Veins-corner arrival; `seen_debriefs` (reserved migrator-clean field). |
| **Almanac pages + request board** | medium | DEV + AI-PIPE | 1–2 request pages across four trades; finalized only after the ONE-counter merge. |

### Pillar-One-STRETCH shelf (ships only if the core lands; cut without penalty)

Named here so it is *visible as cut*, not smuggled into "the demo": full co-op reconnect-grace / Party-Lantern / voiced-join; a second non-Boar Pale-Veins boss; the Hedgemother phase-3 hedge-sprite summon (depends on the **unproven** custom-boss-clip pipeline — §6 risk); affixes-as-rule-changers; the full typed-twin roster beyond the Pale-Veins subset.

### Parallel CONTENT track
- **Pale Veins lore anchor** delivered diegetically (carved well-stone + Hod's half-finished tale) — AI-PIPE draft, DEV places. Story-by-playing is the most-protected move; these strings must exist.
- All player-facing copy is *quoted/wired from locked WORLD_LORE*, not invented.

### Parallel ART/AUDIO track (the binding constraint — start the pipeline rebuild Day 1)
- **Rehome the pipeline executable** *(blocker; gates this whole track)*: re-author `clean_ai_mesh.py` against the **Godot** loader (`layout_loader.gd` ENEMY_DEFS/TILE_GLBS, `_rigged.glb`-preferred ~line 596, `calibration.gd`) — DEV.
- **Restore `docs/character-pipeline/`** recipes A/B/C + socket bone-map — DEV/AGENT.
- **Prove ONE boss clip end-to-end before banking two boss gimmicks on it.** The socket-empty/B-approach pipeline has *not* shipped a boss clip *[verified: recent commits author sockets, no shipped clip]*. **Gate: a single working Boar-or-Hedgemother signature clip must round-trip Meshy→Blender→Godot before the Hedgemother summon (Stretch) is scheduled.**
- **Pale Veins biome kit** (~20 tile GLBs + Hedgewight family + Boar dressing + locked `--cref` + PROMPTS.md) — AI-PIPE, cloned from the proven crypt pipeline. **Cadence: tonal batches of 3–5, not a single bulk drop** (matches the plan's own throughput model — see the corrected <1-day metric in §6).
- **Audio:** crypt ambient bed (retro-fix the reference biome), Pale Veins bed, Hedgemother + Boar stings, vein-read/seam-branch/ink-refine foley — AI-PIPE via `generate_audio.py`, **with a tonal-acceptance gate (§7 rubric A): a 3-tester forced-choice "Bramblewood vs. generic-fantasy" pass at ≥2/3 before a bed is accepted.** Tone is not a solved line-item; ElevenLabs generation alone does not guarantee it.
- **Art Bible:** fill the 24–48 swatch palette table; re-anchor hero shots to Bramblewood.
- **Quadruped story:** document the Godot procedural-only animator for rat/Boar/Pale-kin (auto-rig is humanoid-only — a hard fact). Validate the Boar model (pick one of three GLBs) before Pillar One ships.

### Parallel FRAMEWORK/PROCESS track (meta-shell — design THEN build)
DoD per shell piece: designed (layout + states + first-boot-vs-returning logic) → built → routed through `strings.gd` → ninepatch+capture surface → **behaves correctly under the host-auth contract** (can a guest open options mid-run? does quit-to-menu cleanly leave the party? does pause keep the host's world breathing safely?).
- **Tier-0 framework:** cold-open / first-boot presentation (the "first 2 minutes").
- **Pre-ship framework:** Title/main menu → Pause (reclaim Esc from the Lantern; rename `system_menu.gd`) → Options (audio buses + sliders, graphics, gameplay) → input remap + gamepad → accessibility (colorblind-safe twins, reduce-motion, captions, text-scale) → death/defeat return UX → save-slot/load/delete + confirm → controls/help → credits/attribution + license manifest → build/distribution (export presets, icon/splash, version footer).

---

## 5. Make the KB operational

The KB is *almost* an operating system: the [[Systems Interlock Map]] encodes Tier 0–4, the [[Red-Team Findings]] names live bugs with file/line fixes, every deep design carries "Implementation notes (Godot)." The connective tissue is missing. Add exactly these, at near-zero cost:

1. **Master backlog — `kb/wiki/Build Board.md`** (highest-leverage single artifact). One row per §2 graph node. Columns: `item · tier · status(todo/doing/done/blocked) · owner(DEV/AI-PIPE/AGENT) · spec-link · DoD-link · blocked-by`. **The gear-ladder linchpin (ADR 0010) is row #1, status `blocked` until merged.** Make it the third `index.md` entry point beside Overview and Current State.
2. **Status frontmatter that drives a dashboard.** All 17 designs are frozen `status:draft` — conflating "design unfinished" with "designed but unbuilt." Add `build_tier`, `impl_status` (designed/specced/coded/tested/shipped), `spec`, `owner`; one Dataview page rolls them into a live table.
3. **Traceability ledger — `kb/wiki/Traceability.md`.** `deep-design row → docs/specs/<NN> → code symbol → test hook → status`. Closes the design→spec discontinuity (zero of 17 designs cite a spec path today) and gives seams **S1–S10** and the red-team per-item reconciliations a tracked closure path. The #1 row is the gear-ladder linchpin.
4. **Definition of Done — `kb/wiki/Definition of Done.md`.** One reusable checklist: *merged behind a spec · four suites green via `run_tests.sh` · new mechanic has a deterministic headless assertion in its mapped suite · ninepatch + `WYRD_UI_SHOT` for any panel · balance-sim run for any power spike · string routed through `strings.gd` · save field additive + migrator added · behaves under host-auth co-op.* (This is the same instrument §7 rubrics cite.)
5. **A "build" operation in the KB schema.** `kb/CLAUDE.md` Operations has ingest/query/lint only. Add **promote** (design→spec) + **build-status update**, plus a `build`/`ship` `log.md` prefix.
6. **Refresh the front door.** `Current State.md` gains a "committed next: Pillar Zero foundation + Pillar One core" section pointing at the Build Board, plus a "How to build from this KB" note: *read plan → §2 graph → red-team blockers → Build Board → pick item → spec → DoD.* Aggregate the 17 scattered "Open questions" into one owned, dated list flagging which must resolve before the migration ladder.

---

## 6. The Tier 0 sprint — exact ordered task list

Ordering is deliberate: **safety before destructive tests; decisions before code that depends on them; the linchpin before anything that reasons about loot.**

1. **Non-destructive `_test_save_roundtrip`** — `wyrd/test_wyrd_loop.gd`. *DoD:* redirects `SAVE_PATH` to a temp path; an assertion proves the real save is untouched. **First — makes all later Phase-0 testing safe.**
2. **Save migration ladder** — `wyrd/scripts/save_game.gd` (add `MIGRATORS[]`; replace the line 53–54 discard; Huntcraft backfill = migrator #1; **reserve `masteries`/`ink_stability_bonus`/`ledger_boons`/`atlas_counts`/`seen_debriefs`/twin-state**) + a checked-in v0 fixture. *DoD:* v0 → current, zero field loss (asserted).
3. **Co-op determinism fix** — `wyrd/scripts/layout_loader.gd:813` (`randf()` → `_rng.randf()`); extend `_test_determinism`. *DoD:* two builds on one seed agree on trophy/elite placement (asserted).
4. **Gear-ladder ADR 0010 + reconciliation (LINCHPIN)** — `docs/adr/0010-gear-ladder.md`; `player_controller.gd:~1022`; `affixes.gd`; `crafting.gd`; `items.gd`; rewrite `test_wyrd_loop.gd:342` + the 13-suite audit. *DoD:* ADR records option (b) freeze-at-zero-power; gear sum proves zero combat power; economy gate asserts the new intent; all suites green. **This unblocks every Tier-2/3 itemization item.**
5. **`WYRD_FAST_COMBAT` deterministic hook** — `wyrd/scripts/` combat/poise timing. *DoD:* `test_skills` drives a boss to a Reel window headlessly and asserts the reset. **Built now so Tier-2 Poise has a harness from day one.**
6. **ADR 0007 no-arbitrage** — `docs/adr/0007-no-arbitrage-gather-only.md` + assertion in `test_wyrd_loop.gd:316`. *DoD:* test guards that a top-of-ladder material is never both shelf-stocked and a peak recipe input.
7. **ADR 0008 cut-line governance (P7)** — `docs/adr/0008-cut-line.md`. *DoD:* documents the trigger, the promote-from-Horizon ritual, where the cut-line lives; §Stretch shelf is its first enforcement target.
8. **ADR 0009 anti-escalation** — `docs/adr/0009-anti-escalation.md`. *DoD:* "no creature worse than the Hedgemother; Summit is a quieting"; **records the `hedgemother_queen`-kind reconciliation as a named open question.**
9. **ADR 0011 host-auth co-op** — `docs/adr/0011-host-auth-coop.md`. *DoD:* invariant locked; future co-op work cites it.
10. **String table `strings.gd` + "Second Pour" rename** — new file; rename the chart-revive so it can't collide with the Wildcraft `second_pour` perk (`game.gd:383,446`). *DoD:* accessor + stable IDs; no name collision (asserted).
11. **`run_tests.sh` + commit gate + `docs/qa-gate.md` mechanic→suite map** — `wyrd/tools/run_tests.sh` + Makefile/hook. *DoD:* one command runs the four suites with an aggregated exit code; every new mechanic mapped to a suite + assertion; the other 13 suites classified.
12. **biome-kit-template spec (#47) + perf-budget numbers** — `docs/specs/47-biome-kit-template.md`, `docs/specs/47-notes.md`. *DoD:* every checklist box names a file + owner; crypt is the filled-in worked example; perf ceilings written as numbers.
13. **Build Board + CONTEXT.md glossary + Current State refresh** — `kb/wiki/Build Board.md`, `CONTEXT.md`, `kb/wiki/Current State.md`. *DoD:* backlog seeded (ADR 0010 = row #1, blocked); glossary defines every demo term with an *Avoid* line; front door points at the board.

*Parallelizable while DEV does the above (no dependency on code-side Tier-0):* the ART/AUDIO **pipeline-executable rebuild** (`clean_ai_mesh.py` re-homed to the Godot loader) and the `docs/concept-art/INDEX.md` dummy-debt tracker.

---

## 7. Definition-of-Done rubric appendix (the gates that were soft, now instrumented)

The prior draft used "demonstrably," "recognizably," "well enough," "no new generator code," and "honest live odds" as ship gates. Each is replaced below by a named instrument with a sample size and a threshold. **No exit criterion in this document passes on an adjective.**

- **Rubric A — "Pale Veins reads as the Pale Veins" (place-identity, not recolor).** *Instrument:* a **forced-choice ID test** — show 3–5 blind testers an unlabeled Pale-Veins screenshot among 3 decoys (crypt + 2 distractors) and ask "which is the stone-vein region?" *Gate:* **≥4/5 correct *and* ≥3/5 free-recall at least two place-specific elements** (veins, branching seams, pale palette) without prompting. "It's the stone one" alone fails the free-recall half.
- **Rubric B — "the spine is deepened."** *Instrument:* a **scored post-session survey** of 3–5 testers, each rating "did you find a new gather/craft thing worth doing again?" on a 1–5 scale and naming it. *Gate:* **≥3/5 rate ≥4 AND name the *same* mechanic family** (vein-reading or ink-refine). One person "liking" one thing does not pass.
- **Rubric C — feel-pillars (world-response, power-fantasy).** *Instrument:* the **PLAYTEST.md scoring sheet** (which must exist first — it is a Tier-0/fwk deliverable, not a phantom). Each pillar is scored 1–10 against a **defined anchor rubric** (1 = no response/no agency; 10 = every action visibly moves the world / the Reel reset reads as earned mastery), by ≥3 testers, baseline captured *before* Pillar One. *Gate:* **median rises by ≥2 points AND lands ≥7**, not "toward 7." If PLAYTEST.md does not yet exist, these numbers are marked *aspiration* on the Build Board and are **not** used as a ship gate.
- **Rubric D — biome-kit template "documented enough to clone."** *Instrument:* the #47 checklist with **every box naming a file + owner + a filled-in crypt example.** *Gate:* a reviewer can trace each box to an existing crypt artifact. (The "<1-day throwaway biome" claim is **deleted as a hard metric** — see below.)
- **Rubric E — "second biome by cloning."** The prior "no new generator code" gate is **unfalsifiable** (any new code reclassifies as "not generator code") and **false-in-advance** (vein-reading, branching seams, the `room.hazard` hook, biome-coupled affixes all require new code). *Replacement:* the gate is **"the second biome's *tile-kit + affix-table + gather-palette + creature-roster* are produced purely as kit-DATA against #47, with the *mechanic* code (Poise, seams, hazard) shared from Pillar One, not re-authored."** Generator-code-vs-kit-data boundary is defined in #47 so the gate is checkable.
- **Rubric F — no-idle / three-cadence contract.** "Audit lens" is not a pass/fail. *Instrument:* a **named session audit** run by DEV on a recorded 20-minute play trace: every player-decision point is tagged short/medium/long-cadence; a "dead action" = a UI affordance that produces no state change. *Gate:* **zero dead actions in the trace AND ≥1 of each cadence advanced.** **The "timed crafts complete *during* a delve" cross-context-timer claim is removed from the demo contract** — it is an unspecced background-timer mechanic (Horizon), not an audit lens; the demo contract is only "town actions and delve actions each advance a cadence within a session," which the current scene model already supports.
- **Rubric G — summary-card honesty (S10).** *Instrument:* the two-surface resolution in §Tier-3 — **preview shows pre-roll odds, stamped chart shows resolved twins, both from one seed.** *Gate:* an assertion that the previewed probability and the stamped resolution never disagree for a given seed (no drift), and **no single card claims both states.** "Honest" is now defined as: the surface the player sees at each step matches the seed's actual state at that step.

The throwaway-second-biome-in-<1-day success metric is **struck entirely.** The plan's own model — art is the binding constraint, asset cadence is tonal batches of 3–5 — makes generating + cleaning + socketing ~20 tiles and 4 rigged creatures in under a day self-contradictory. The replacement success metric is Rubric E (clone-by-kit-data) plus a **tracked throughput number** on the Build Board (GLBs/week through the rebuilt pipeline), not a heroic one-day claim.

---

## 8. Risks & sequencing traps

**The single biggest trap — building Tier 2 before ADR 0010.** The Ledger, the dissolve-to-ink sink, the no-arbitrage economy, the Palechalk-ink chain, and the summary card all reason about a loot economy whose *existence* is undecided. Build them first and you build them twice. **Gate:** ADR 0010 merged + gear sum proven zero-power before any Tier-2 itemization.

**The palechalk drift trap.** Layering an ink-refine onto the *existing* palechalk adds a sink to a material on the weapon treadmill — cozy-washing an ARPG input. **Gate:** `pale_deepore` lands (or the palechalk gear recipes are removed) *before* the ink recipe; the ink's input must have no gear-recipe sink (asserted).

**The save-ladder ordering trap.** Six Tier-2/3 systems each add a persisted field. They must share ONE version bump + ONE `MIGRATORS[]`. **Gate:** "migration ladder shipped" is the milestone that unblocks Tier 2 — on the Build Board, not in prose — and `masteries`/`atlas_counts`/etc. are *reserved at Tier 0*, not retrofitted.

**The determinism-under-co-op trap.** You cannot ship correct shared boss/trophy state on a build path where peers diverge on trophies (`layout_loader.gd:813`). **Gate:** the one-line `_rng.randf()` fix + the parity assertion land *before* any `_boss_state` RPC work.

**The art-pipeline binding constraint.** The "second biome by cloning" exit criterion depends on a pipeline executable that *does not exist* (deleted with three.js) **and** on a custom-boss-clip path that has *never shipped a clip*. **Mitigation:** start the `clean_ai_mesh.py` Godot re-home Day 1; **prove one boss clip end-to-end before banking the Hedgemother summon (Stretch)**; track every GLB's dummy-vs-final status in `docs/concept-art/INDEX.md`.

**The balance-sim circular-dependency trap.** The sim is named as the gate for three power spikes (Pale-Veins affixes, Mark cooldown-reset, Huntcraft faucet) **but does not exist** and is also declared "never a gate." *Resolution:* the sim is **built in Tier 1** (re-homed from the deleted JS), and it is an **on-demand acceptance check with written thresholds** (faucet ratio, TTK floor) — run before each power-spike ships, recorded in a run-log. It is not a per-commit gate, but it *is* a per-power-spike gate with a numeric pass/fail. The "forbidden from gating" framing is dropped as incoherent.

**Throughput reality of a solo + AI shop.** (1) Meshy/Midjourney/ElevenLabs are credit-metered and async — kick off art batches *before* needed and let them cook while DEV codes. (2) AGENT subagents hit usage windows — bound them to *mechanical* tasks (string extraction, additive-table scaffolding, linters) under DEV review, never load-bearing decisions or balance. (3) The deterministic hooks (`WYRD_FAST_COMBAT`, `WYRD_SEED`, the 2-process co-op harness) are the agents' eyes — without them every change needs manual play-test and throughput collapses. Build them in Tier 0.

**Cozy-spine-drift — the most insidious.** The shipped code already has a full ARPG gear ladder *[verified]* and CONTEXT.md still self-describes as "Diablo/PoE." Drift shows up three ways: (a) the gear ladder re-asserting itself if ADR 0010 isn't enforced by the rewritten economy test; (b) the combat layer over-growing — *combat is one verb*, so Poise/Reeling/Mark is the **ceiling**, not a foundation; (c) Horizon creep — the §10 list is richly named and tempting, and the Stretch shelf is where it gets parked, not the demo. **Mitigations:** ADR 0008 (cut-line) is the tripwire; the Build Board tier column is where drift becomes visible; the blind-tester check ("does charting feel like *remembering a way*") is ground-truth that the spine, not the loot, is the heart. **The Huntcraft faucet is the quantitative drift sentinel:** if combat XP/hour exceeds the gather/craft faucets (Rubric in §Tier 2), the spine is losing to the seasoning regardless of vibe.

**The two-town-growth-systems drift (corrected).** The prior draft shipped *both* the Almanac restoring corners *and* the Living Atlas counter restoring corners — the exact double-feel the Interlock S2 forbids (a single completion pays twice, or two completions move one corner). **Resolved:** ONE `atlas_counts` counter; the Almanac is a *view*; one completion moves one corner exactly once (asserted in Tier 4 DoD).

**The Summit false-certainty drift (corrected).** "The Summit is already the same being (scaled `hedgemother_v2`)" was asserted as source-fact but the data ships `hedgemother_queen` as a **distinct kind** *[verified: layout_loader.gd:130-131, charts.gd:64]*. The reconciliation is a *named open question* in ADR 0009, not canon — and the Summit is Horizon, so no certainty about it leaks into committed scope.

**The phantom-doc trap.** PLAYTEST.md is cited as "adopted" and exists nowhere; §8/Rubric C numbers are valid *only if* the apparatus exists. **Until PLAYTEST.md and the scoring sheet are real, Rubric C numbers are marked aspiration on the Build Board and are not ship gates.**

**The universally-acknowledged-but-unmoved trap.** The destructive `_test_save_roundtrip` is named in CLAUDE.md, the roadmap, and the plan — flagged everywhere, fixed nowhere. That is the precise symptom of the missing tracker: a blocker can be universally known and still not move because nothing owns it to closure. The Build Board + Traceability ledger exist to kill this mode — which is why making the KB operational (§5) is itself a Tier-0-adjacent deliverable, not a documentation chore.

---

*Verification footnotes (run against the live build, 2026-06-14): `affixes.gd:7-23` (rolled fire_rate/crit/damage/cooldown_reduction); `player_controller.gd:1018-1028` (gear sum folds into `fire_cooldown`); `test_wyrd_loop.gd:342` (`gear >= 12`); `layout_loader.gd:813` (bare `randf()`) vs `:797,:801` (`_rng`); `layout_loader.gd:121/124/127` (trophies `tusker_tusk`/`wightpelt`/`alpha_fang`); `layout_loader.gd:130-131` + `charts.gd:64` (`hedgemother_queen` distinct kind, hp 160, reused model scaled 3.75→4.6); `gather.gd:17,175,216-217` (palechalk raw + gear/vault sinks); grep `pale_deepore` → 0 hits; `boss.gd` (no poise/hazard/reeling); `save_game.gd:11,53-54` (VERSION=1, destructive discard); 17 `test_*.gd` files, 4 protected; `docs/adr/` stops at 0006; `docs/specs/` stops at 46; `data/` has no `strings.gd`/`ledger.gd`/`biome_affixes.gd`; `scripts/` empty; `docs/character-pipeline/`, `docs/concept-art/INDEX.md`, `docs/PLAYTEST.md` absent. KB plan: [[Universe Build-Out Plan]]; tiers: [[Systems Interlock Map]]; blockers: [[Red-Team Findings]].*
