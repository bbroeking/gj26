---
type: design
tags: [system-design, interlock]
status: maintained
updated: 2026-06-14
sources:
  - "kb/wiki/design/Chart Loop — Deep Design.md"
  - "kb/wiki/design/Gathering — Deep Design.md"
  - "kb/wiki/design/Crafting and Inks — Deep Design.md"
  - "kb/wiki/design/Trades and Leveling — Deep Design.md"
  - "kb/wiki/design/Charts Affixes and Inks — Deep Design.md"
  - "kb/wiki/design/Dungeon Generation — Deep Design.md"
  - "kb/wiki/design/Combat — Deep Design.md"
  - "kb/wiki/design/Skills and Loadout — Deep Design.md"
  - "kb/wiki/design/Enemies and Bosses — Deep Design.md"
  - "kb/wiki/design/Items Gear and Economy — Deep Design.md"
  - "kb/wiki/design/Multiplayer Co-op — Deep Design.md"
  - "kb/wiki/design/Progression and Endgame — Deep Design.md"
  - "kb/wiki/design/Onboarding and Narrative — Deep Design.md"
  - "kb/wiki/design/UI HUD Camera and Audio — Deep Design.md"
  - "kb/wiki/design/Save and Persistence — Deep Design.md"
  - "kb/wiki/Current State.md"
---

# Systems Interlock Map

> The one-page wiring diagram across the fifteen
> [[Chart Loop — Deep Design|Deep Design]] docs. It answers three questions the
> individual docs cannot: **how the spine flows end to end**, **what must be
> built before what**, and **where two designs disagree or double-own a
> mechanic.** When this map and a Deep Design doc disagree, the Deep Design doc
> wins on detail and this map wins on the seam. When either disagrees with
> `../wyrd/` code, the **code wins** (see [[Current State]]).

---

## 1. The spine dataflow

The cozy spine is a single loop — **gather → craft → chart → delve → return →
grow** — and every system is a station on it. Read this as a diagram in prose;
each `→` is a concrete data handoff, not a metaphor.

```
   [[Gathering]]                    deep ore (pale_deepore) + ore grade 1–3
   vein-reading on Pale Veins  ───────────────────────────────────────────►  Crafting
   ore_rock nodes                                                            bench mixing-pot
   branching seams                                                          refine: deep ore + binder
        ▲                                                                    │
        │ good-twin gather affixes                                           │ Palechalk Ink
        │ place the nodes                                                    │ (stability_bonus field,
        │ (bad twins place nothing)                                          │  grade-matched 0.04–0.10)
        │                                                                    ▼
   [[Dungeon Generation]]  ◄────────────────────────────────────────  [[Inks]] = the value spine (P12)
   TinyKeep gen + biome KIT                                                  │
   seed determinism for co-op                                               │ consumed at inscription,
   room.hazard = boss gimmicks                                              │ reroll (Smudge Stick),
        ▲                                                                    │ and dissolve-to-dust top-up
        │ scope + gen block + resolved twins                                ▼
        │ via run_cfg()                                          Charts / inscription ritual
        │                                                        inscribe() → chart dict
        │                                                        {template_id,tier,scope,name,affixes[],seed,region}
        │                                                        two rolls/slot: WHICH affix (compute_weights)
        │                                                                     WHICH twin  (effective_stability coin)
        │                                                        summary card reads live odds
        │                                                                    │
        │                                                                    ▼
   [[Enemies]] / [[Bosses]]  ◄───────────────  DELVE  ───────────────  player walks the chart
   spawn-table row by scope                          │
   boss = BFS-farthest room                          │ Poise/stance-break (the ONE reading mechanic)
   Poise meter (boss.gd only)                        │ → Reeling 3s → Wayfinder's Mark finisher
        │                                             │ → skill-cooldown reset + Focus refund
        │ trophy drops                                │
        ▼                                             ▼
   THREE OUTPUTS of a delve fan out:
   ┌─────────────────────┬──────────────────────────┬─────────────────────────────┐
   │ completion_xp        │ raw trophy                │ atlas_credit(chart)          │
   │ tier*75+good*40      │ → carried home →          │ → region counter++           │
   │  +bad*10 (×1.3 Tyr)  │   inscribe_ledger()       │ → done>=needed flips         │
   │ → [[Wayfinding]] XP   │   (Wayfinder's Ledger)    │   a town corner RESTORED     │
   │   (Trade leveling)    │   OR socket as den affix  │   (well animates, Hod        │
   │ → Huntcraft XP        │   (TROPHY_TO_AFFIX, the   │   arrives) — Living Atlas     │
   │   from every kill     │   trophy chain up to the  │   v1, the spine-growth        │
   │   (max(2,hp_max/3))   │   Summit)                 │   payoff                      │
   └─────────────────────┴──────────────────────────┴─────────────────────────────┘
                                   │
                                   ▼
                 RETURN → GROW: town corner restored, Codex entry unlocked,
                 Almanac page ticked, Mara's milestone debrief fires —
                 then the player gathers again with one more affix understood.
```

The loop is **circular, not linear**: good-twin gather affixes (set by the chart
the player inscribed last cycle) decide where the *next* cycle's nodes spawn, so
charting feeds gathering feeds crafting feeds charting. That circularity is the
spine's whole point — *"to chart is to remember a way the village forgot."*

**The three faucets of a delve, kept distinct** (this separation is load-bearing
and a frequent seam — see §4):

1. **XP faucet** → completion_xp to [[Wayfinding]] (the Trade's primary channel)
   + per-kill Huntcraft XP. Drives [[Trades and Leveling — Deep Design|Trade leveling]].
2. **Trophy faucet** → one raw trophy per boss, splitting into **two distinct
   paths** that must never be confused: (a) *chart-input* trophies consumed via
   `TROPHY_TO_AFFIX` to guarantee a den affix (the trophy chain), and (b)
   *Ledger* trophies consumed via `inscribe_ledger()` for a flat, capped,
   horizontal boon ([[Items and Gear]]).
3. **Growth faucet** → `atlas_credit` increments a region completion **count**
   (not XP); crossing the threshold (`needed=3` for Pale Veins) restores a
   walkable town corner one-way. This is [[Progression and Endgame — Deep Design|town-growth / Living Atlas]].

---

## 2. Dependency / build-order graph

What must exist before what. Arrows mean *"is a hard prerequisite of."* Tiers are
build waves; everything in a tier can proceed once the tier above is real.

```
TIER 0 — FOUNDATIONS (nothing systemic is safe until these land)
  [[Save and Persistence — Deep Design|Migration ladder]]  ── replaces the destructive line-53 discard;
        │  VERSION 1→2; reserved keys (charter, almanac, codex, deepening)
        │  EVERY new persisted field below depends on this (no half-state on a version bump)
        ▼
  Phase-0 string table (data/strings.gd, stable IDs)  ── every systemic string routes through it
        │
  Host-authoritative co-op contract  ── locked Phase 0; "each peer saves itself; shared run state is host-RAM-only"
        │
  No-arbitrage ADR + _test_economy_gate assertion  ── guards the dissolve sink BEFORE the sink ships

TIER 1 — THE SHIPPED SPINE (already live; the deepenings hang off these)
  [[Chart Loop]] · [[Gathering]] · [[Crafting]] · [[Dungeon Generation]] ·
  four [[Trades and Leveling|trades]] @ cap 17 · [[Combat]] one-verb bow ·
  [[Multiplayer Co-op]] Phase A/B · trophy chain
        │
        ▼
TIER 2 — THE PILLAR ONE DEEPENINGS (ship TOGETHER, gather-depth feeds craft-depth)
  Gathering vein-reading + branching seams ──► produces pale_deepore + GRADE
        │                                              │
        ▼                                              ▼
  Pale Veins biome KIT (clone, no new gen code)   Ink-refining bench step (refine: recipe)
  + room.hazard hook (Boar tusk-quake)                  │ Palechalk Ink + stability_bonus
        │                                              ▼
        ├──────────────────────────────►  Twin roster as a TYPED table (good/bad blocks,
        │                                  replaces the __bad string suffix) — gen reads resolved effect
        │                                              │
        ▼                                              ▼
  Boss: Hedgemother thorn-arena + hedge-sprite     Affix biome FLAVOR table (biome_affixes.gd,
  summon (closes spec-05); Boar tusk-quake          stab_delta capped ±5)
        │                                              │
        └──────────────┬───────────────────────────────┘
                       ▼
            Poise / stance-break + Reeling + Wayfinder's Mark
            (the ONE reading mechanic; lives on boss.gd ONLY)
                       │
                       ▼  (Mark finisher resets skill cooldowns → )
            [[Skills and Loadout — Deep Design|Loadout]] answer-coverage tag (tank/pack/space/survive)
                       │  Reel skill-reset wired to the BOSS reeling signal, never inside _try_skill
                       ▼
            Co-op CORRECTNESS: _boss_state RPC (Poise/telegraphs/Reeling to all peers)  ── P9, not polish

TIER 3 — SURFACES & SINKS (depend on Tier 2 producing the things they display/route)
  [[UI and HUD|Summary card]] + Almanac (ninepatch + WYRD_UI_SHOT)  ← needs compute_weights + affix table
  HUD Poise meter + ghost-trail + Reeling flourish               ← needs Poise (Tier 2)
  Wayfinder's [[Items and Gear|Ledger]] + 3 boons + dissolve-to-ink-dust  ← needs trophy faucet + no-arbitrage gate
  Earthcraft pick-one-of-N MASTERY (Lv13)                         ← needs the migration ladder (stores choice)
  Smudge Stick single-twin reroll                                 ← needs the twin table + ink sink

TIER 4 — RETENTION / NARRATIVE LAYER (rides everything above)
  Living Atlas v1 (3 completions → town corner) + minimal Almanac pages
  Wayfarer's Codex shell (verbatim WORLD_LORE, first-discovery, never a gate)
  Onboarding: first-teach-the-affix bias + Mara's 5 milestone debriefs
  Co-op Phase C correctness polish (reconnect grace, downed-revive "Second Pour")
```

**The single hardest ordering constraint:** the
[[Save and Persistence — Deep Design|migration ladder]] is Tier 0 because
**six other systems add persisted fields** — `chart.region`, `trades[].masteries`,
ink `stability_bonus`, `seen_affixes`/`seen_debriefs`, `codex_seen`/`region_depth`/
`atlas_counts`, ore grade. If the destructive version-mismatch discard is still in
place when any of those ship, a version bump wipes earned state. Resolve the
ladder first, then every deepening's new field is an additive default.

---

## 3. Shared data — what each pair of systems touches

The interlocks live in a handful of shared data structures. Each row is a piece
of data **co-owned** by two or more systems; the "owner" column names who writes
it, "readers" who depend on it.

| Shared data | Owner (writes) | Readers (depend on it) | The seam |
|---|---|---|---|
| **`chart` dict** `{template_id,tier,scope,name,affixes[],seed,region}` | [[Charts Affixes and Inks — Deep Design|inscription]] (`inscribe()`) | [[Dungeon Generation]] (`run_cfg()`), [[Save and Persistence — Deep Design|save]] (persists the case, NOT the layout), onboarding (`first_teach_affix`), [[UI and HUD|summary card]] | Stays thin: rumor header **recomputed** on display, not stored. `region` defaults `'crypt'` for old saves. |
| **Inks** (instances w/ `stability_bonus`, bias dicts) | [[Crafting and Inks — Deep Design|crafting]] (refine step) | charts (consumed at inscription; `compute_weights` reads bias), economy (dissolve→ink-dust tops them up), trades (mastery re-pick fee) | Inks are the **value spine (P12)** — the single currency every sink routes to. |
| **`effective_stability`** `= min(95, base+carto*0.6+(ink+perk)*100)` | charts.gd (shipped, verbatim) | crafting (refined ink + Stabilizing Draught feed it), the twin coin-flip, the summary card (must show the SAME number — tested for no drift) | 95 ceiling means a bad twin is **always possible** — cozy ≠ guaranteed-good. |
| **`completion_xp`** `= tier*75+good*40+bad*10 (×1.3 Tyr)` | charts.gd (shipped) | [[Wayfinding]] (primary faucet), [[Progression and Endgame — Deep Design|Deepening]] (more slots = more terms), balance philosophy | **Bad twins still pay XP** — "a botched roll is still a lesson." |
| **Focus** (one regenerating resource, 3/s combat vs 10/s) | [[Combat]] | [[Skills and Loadout — Deep Design|loadout]] (slots 2–4 cost it; Mark refunds it), affixes (`echoing` bends regen) | Bow (slot 1) is **free**; Focus is the spend-rhythm lever, not a build resource. |
| **Poise** (`poise_max=round(hp_max*0.5)`, per-boss) | [[Enemies and Bosses — Deep Design|boss.gd]] ONLY | [[Skills and Loadout — Deep Design|skills]] (Reel resets cooldowns), [[UI and HUD|HUD]] (second meter), co-op (`_boss_state` RPC) | Deliberately NOT on combatant.gd — keeps cost off the trash-mob path; trash use stagger. |
| **Ore grade (1–3)** | [[Gathering — Deep Design|vein-reading]] | crafting (grade-match → ink stability_bonus); the gather→craft *handshake* | **Open:** where grade persists — a per-stack satchel field (save-schema touch) or rolled at refine time. Resolve before the migration ladder. |
| **`pale_deepore`** | gathering (gather-only by construction) | crafting (sole input to Palechalk refine) | **No-arbitrage:** never shelf-stocked AND a peak recipe input. The ADR test asserts it. |
| **Save schema** (versioned dict) | [[Save and Persistence — Deep Design|save_game.gd]] | trades (lv/xp + masteries), charts (chart case), items (grid via `__v2`, `Color` via `__col`), inks (`discovered_inks`), onboarding (`seen_*`), progression (`codex_seen`/`region_depth`/`atlas_counts`) | The migration ladder is the **shared contract** for every additive field; <256 KB budget is the seam against Horizon bloat. |
| **`chart_seed`** | inscription (the seed in the dict) | [[Dungeon Generation]] (`rng.seed = chart_seed ^ 0x5DEECE66`), co-op (every peer builds identically) | **Fragile to any non-seeded `randf()`** — trophy rolls in `_build_enemies`/`_read_chart_modifiers` must route through the chart-seeded RNG or peers diverge. |
| **Trophies** (raw item) | [[Enemies and Bosses — Deep Design|boss drop]] | charts (chart-input → `TROPHY_TO_AFFIX`), items (Ledger → `inscribe_ledger()`) | **Two distinct paths, same raw item** — the most-confusable double-ownership (see §4). |
| **`_boss_state` RPC** `{phase,tele_kind,tele_t01,poise01,reeling_t}` | [[Multiplayer Co-op — Deep Design|host]] (~10Hz) | every peer's HUD/combat (Poise, telegraphs, Reeling window) | A **correctness** requirement (P9), not polish — the whole party must read the same Reel window. |

---

## 4. Contradictions & seams

Where two Deep Designs disagree, double-own a mechanic, or leave a gap the other
assumes is filled. Ordered by how load-bearing the resolution is.

### S1 — The trophy ritual is double-owned (chart-input vs Ledger)
The **same raw trophy item** is consumed by two systems for two unrelated
outcomes: [[Charts Affixes and Inks — Deep Design|charts]] consume it via
`TROPHY_TO_AFFIX` to guarantee a den affix (the trophy *chain*, the LONG-cadence
spine leg), while [[Items Gear and Economy — Deep Design|the Ledger]] consumes it
via `inscribe_ledger()` for a permanent horizontal boon. Both designs explicitly
call this out and both *insist they stay separate*, which is exactly the smell:
one boss kill, one raw trophy, two consumers competing for it.
**Resolution needed:** a clear faucet rule — is it *one trophy per kill* (the
designs' current assumption, forcing the player to choose chain-vs-Ledger) or
*one per chain-leg-completed*? Items' Deep Design flags this as open ("one
raw-trophy-per-boss-kill … or one per chain-leg"). Until decided, the inventory
can't know how many trophies to grant. **Lean:** one per kill, player chooses the
path — preserves the cozy "what do I want to remember this for" beat.

### S2 — The MEDIUM cadence is double-counted (Almanac vs Living Atlas)
[[Chart Loop — Deep Design|Chart Loop]] declares every chart as SHORT / MEDIUM /
LONG and assigns *both* "an Almanac page" *and* "a town corner" to MEDIUM.
[[Progression and Endgame — Deep Design|Progression]] then has **the Almanac
restore corners** *and* the **Living Atlas counter** restore corners — two
mechanics feeding the same town-growth payoff. Chart Loop's own open question
names it: *"Does the Almanac page share completion counters with the Living Atlas
or track separately (risk of double-feeling the same MEDIUM beat)?"*
**Resolution needed:** one counter, two surfaces — make the Almanac a *view* onto
`atlas_counts`, not a parallel tally. Otherwise a single completion feels like it
pays twice, or two completions are needed to move one corner.

### S3 — Who owns the corner-restore wiring?
[[UI HUD Camera and Audio — Deep Design|UI]] asks outright: *"Almanac page
completion → which town corner animates, and is that wiring owned here or by
Progression?"* [[Progression and Endgame — Deep Design|Progression]] treats the
threshold→restore as its own (`atlas_counts[scope] >= [3,8,16]`), and Chart Loop
treats `atlas_credit` as the writer. Three docs touch the corner; none owns the
*animation trigger*.
**Resolution needed:** Progression owns the **state** (counter + threshold flip),
UI owns the **presentation** (which corner art animates), Chart Loop owns the
**write** (`atlas_credit` on completion). Name this split before any of them ship.

### S4 — "Second Pour" name collision (hard, pre-strings)
[[Multiplayer Co-op — Deep Design|Co-op]] flags it directly: the Wildcraft
downed-revive is named **"Second Pour,"** but a Lv17 Wildcraft *crafting perk*
already owns that name (`game.gd:383,446`). Two mechanics, one player-facing
string.
**Resolution needed:** rename the revive or make it a non-perk flavor echo
**before the string table locks** (Tier 0). This is the cheapest seam to close
and the most embarrassing to ship.

### S5 — Co-op determinism vs. branching seams & trophy rolls
[[Dungeon Generation — Deep Design|Dungeon Generation]] guarantees seed-identical
builds, but two designs introduce randomness that can break it: (a) the
[[Gathering — Deep Design|branching-seam]] minigame's node reveals, and (b)
non-seeded `randf()` in `_build_enemies`/`_read_chart_modifiers` trophy rolls.
Both Deep Designs flag the risk; neither fully owns the fix.
**Resolution needed:** route *all* in-run randomness through the chart-seeded RNG,
and ship branching seams as **decor** (deterministic placement) for the demo, not
grid-mutating passages. This is a build-parity guard, not a feature toggle.

### S6 — Where does mastery re-pick happen, and does it touch the bench?
[[Trades and Leveling — Deep Design|Trades]] leaves open whether mastery re-pick
lives at "Mara's bench or a dedicated 'remembering' interaction," and the re-pick
fee routes through ink. [[Crafting and Inks — Deep Design|Crafting]]'s bench
already hosts refine + inscription + the grade-picker. If re-pick also lands at
the bench, that's a fourth verb on one surface.
**Resolution needed:** a UI-load call — either accept the bench as the
"remembering" place (cheap, co-located with the ink fee) or split it out before
the Trades-page mastery picker ships.

### S7 — Stabilizing Draught: quaffable ladder or bench consumable?
[[Crafting and Inks — Deep Design|Crafting]] is undecided whether the Draught
lives in the Q-key DRAUGHTS ladder or as a distinct inscription-time consumable
applied at the bench. This is a real seam because it changes the *consume path*
the chart loop reads: a quaffable applies a player buff state; a bench consumable
applies directly to `effective_stability` at inscribe time.
**Resolution needed:** the bench-consumable path is cleaner for the cook→chart
link (the design's own lean) but adds a consume-path; pick one before wiring the
Draught into `effective_stability`.

### S8 — Poise meter visibility (discovery vs legibility)
Three docs touch the Poise meter and disagree on *when to show it*:
[[Enemies and Bosses — Deep Design|Enemies/Bosses]] leans "unlock-on-first-Reeling
(less UI noise, more discovery)," while [[UI HUD Camera and Audio — Deep Design|UI]]
specs "a second slim Poise meter under the boss bar" (always visible). Minor, but
it's a genuine design disagreement, not just open phrasing.
**Resolution needed:** a single call — lean *show from fight start* for co-op
legibility (every peer needs to read the same window), accepting slightly more UI.

### Non-contradictions worth noting (resolved; kept here so they're not re-opened)
- **Poise OR Rally:** the plan picks **Poise**, not Rally, across Combat / Skills /
  Enemies. Settled. Do not re-introduce Rally.
- **No new boss / no King of Brambles / no new gear tier or weapon class:** P6/P8
  anti-escalation, held identically across Enemies, Items, Skills, Progression.
- **Completion-XP formula:** code (`tier*75+good*40+bad*10`) wins over the stale
  doc figure; every Deep Design now quotes the code value. See [[Current State]].

---

## 5. The single throughline

**Every interlock above routes back to one promise: *progression is
get-wider-and-remember-more, never get-stronger.*** That is what keeps it cozy
under load.

The proof is in the seams. Notice what the dataflow in §1 *refuses* to do:
- The **XP faucet** pays bad twins (a botched roll is still a lesson), so the
  player is never punished for reading the dice wrong.
- The **trophy faucet** produces only flat, capped, horizontal boons — itemization
  is a *way of walking the Wolds*, not a damage number.
- The **growth faucet** counts *completions*, not power — "visiting a place enough
  to remember it whole." Town grows; the player's stats do not.
- The one **combat reading mechanic** (Poise) is upside-only: a clean read shaves
  ~20% TTK; a miss costs nothing. It deepens the *read*, never the *weapon*.
- The **ink value spine** is a closed cozy economy: every sink (inscribe, reroll,
  dissolve, mastery re-pick) routes to ink, and the no-arbitrage gate keeps deep
  materials gather-only so the loop can never be shortcut with gold.

The throughline is the **grammar of "one verb deepened by reading,"** repeated at
every station: the bow is read, not bought; the rock is read (vein-reading), not
grinded; the chart is read (the summary card's honest odds), not slot-machined;
the boss is read (the recovery window), not out-geared. Gather → craft → chart →
delve → return → grow is not five mechanics bolted together — it is one verb
(*remember a way the village forgot*) told five times. That is the single thread
the [[Balance Philosophy]] guards and every Deep Design defers to: **you come home
and it mattered, and nothing you earned is gone** ([[Save and Persistence — Deep Design|Save]]).

---

## See also
- The fifteen Deep Designs: [[Chart Loop — Deep Design]] · [[Gathering — Deep Design]] · [[Crafting and Inks — Deep Design]] · [[Trades and Leveling — Deep Design]] · [[Charts Affixes and Inks — Deep Design]] · [[Dungeon Generation — Deep Design]] · [[Combat — Deep Design]] · [[Skills and Loadout — Deep Design]] · [[Enemies and Bosses — Deep Design]] · [[Items Gear and Economy — Deep Design]] · [[Multiplayer Co-op — Deep Design]] · [[Progression and Endgame — Deep Design]] · [[Onboarding and Narrative — Deep Design]] · [[UI HUD Camera and Audio — Deep Design]] · [[Save and Persistence — Deep Design]]
- Current-state pages: [[Current State]] · [[Chart Loop]] · [[Gathering]] · [[Crafting]] · [[Dungeon Generation]] · [[Combat]] · [[Trades and Leveling]] · [[Multiplayer Co-op]] · [[Save System]] · [[UI and HUD]] · [[Economy]]
- Entities: [[Charts]] · [[Affixes]] · [[Inks]] · [[Skills]] · [[Bosses]] · [[Enemies]] · [[Items and Gear]] · [[Wayfinding]] · [[The Crafting Bench]] · [[The Waystone]]
- Frame: [[Balance Philosophy]] · [[Universe Build-Out Plan]]
