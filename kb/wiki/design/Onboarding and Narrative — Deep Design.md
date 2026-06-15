---
type: design
tags: [system-design, onboarding-narrative]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/Universe Build-Out Plan.md"
  - "kb/wiki/systems/Onboarding and Tutorial.md"
  - "kb/wiki/world/Voice and Tone.md"
  - "kb/wiki/world/World Lore.md"
  - "kb/wiki/entities/NPCs.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "kb/wiki/games/puzzle/Portal 2.md"
  - "kb/wiki/games/puzzle/The Witness.md"
  - "kb/wiki/games/rpg/Disco Elysium.md"
  - "wyrd/scripts/game.gd"
  - "wyrd/scripts/save_game.gd"
  - "wyrd/data/charts.gd"
  - "wyrd/data/affixes.gd"
---

# Onboarding and Narrative — Deep Design

> Forward-looking deep design. Current-state: [[Onboarding and Tutorial]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are a Wayfinder who *remembers paths the village forgot* — not a conqueror, a rememberer (Plan §1, §3.1). Onboarding's job is to make the first hour feel like that: the player learns the spine — `gather → craft → chart → delve → come home` — without ever reading a wall of rules, and the story arrives *as a consequence of playing*, never as a quest stop. The throughline ("Wayfinding is remembering") is the single most-protected move in the whole plan (§3.1) and it is delivered in **strings, not cutscenes**: Mara's tutorial, her return-debriefs, and the Codex are the entire narrative surface for the demo.

## What ships today (grounded in code)

- **A 7-step linear tutorial** in `game.gd`: `TUTORIAL_OBJECTIVES` (line 185) + `tutorial_step` (195), advanced by `advance_tutorial()` (795) and re-checked on entry by `_tutorial_check_satisfied()` (830). Steps: talk Mara → forage 3 herbs → mix `hedge_ink` (gated specifically, line 549) → inscribe Snug → socket+enter → reach far waystone → inscribe a Tier-1 with an affix. It is robust to pre-gathered/pre-inscribed state (the adversarial round, [[Onboarding and Tutorial]]).
- **First-use hints** via `SKILL_HINTS` (139) + `first_time_hint()` (170), keyed by station/node kind, shown once and persisted in `seen_hints` (127). This is already the "teach by doing, once" pattern, in Bramblewood voice.
- **Save versioning that is destructive**: `save_game.gd` writes `VERSION` (11) and `load_into()` discards on mismatch (line 53–54: "version mismatch — starting fresh"). The Huntcraft backfill (lines 70–72) is the only migrator. `tutorial_step` and `seen_hints` already persist.
- **Affix copy already exists as data**: `charts.gd` `AFFIXES` (line 72) carries `name`/`bad_name`/`good_desc`/`bad_desc` per affix; `affixes.gd` is a display/compose helper. **All player strings are inline literals today** — there is no string table.

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

**1. Teach-the-affix the Portal way (Plan §4.8).** The first time the player inscribes a *never-before-seen* affix, that den is biased to feature **only** that affix — debut alone, then combine freely (the Portal 2 isolate-then-recombine model; [[Portal 2]]). Mechanics:
- A new save field `seen_affixes: Array[String]` (persisted like `seen_hints`).
- At inscription, `game.gd` computes `unseen = [a for a in chart.affixes if a.id not in seen_affixes]`. If exactly one affix on the chart is unseen, the run is flagged "first-teach": the generator is told to **suppress competing affix spawns** so the den reads as a clean demonstration of that one affix's effect (e.g. a first Mineral Vein den is *visibly* ore-rich and nothing else).
- On run completion, all affixes that appeared are added to `seen_affixes`. **No popup** beyond the affix's existing storybook `name` on the summary card (§4.8: "no popup beyond the affix's storybook name"). The teaching is the *den itself*, per [[The Witness]]: introduce symbol → player infers rule → player applies it later when it combines.
- Self-rescuing: if the player force-quits mid-run, `seen_affixes` is not written, so the teach re-arms — no half-taught state.

**2. Mara's return-debrief leaks Wayfinding fragments (§4.8).** On each return to town that crosses a **milestone**, Mara's dialog rotates in *one* new Wayfinding fragment — story by playing, never a quest stop ([[NPCs]]: her pages already key off `Game.tutorial_step`). Milestones are existing signals, not new content gates: first run completed, first affix combined, first Tier-2 chart, first boss trophy carried home, first town corner restored. Each fires its fragment **once**, tracked in `seen_debriefs: Array`. The capstone fragment is the locked line (§3.1): *"Every chart you draw is a path that was always there. You only have to remember it hard enough."*

**3. Codex-by-verbatim-quote (§4.7).** Every affix twin, enemy, biome, recipe, and boss has a Codex entry written in `WORLD_LORE` voice **by verbatim quote, not paraphrase** — unlocked on first-discovery as a *reward, never a gate*. The cozy completion engine; near-free once the string pipeline exists. Voice register is the Codex sample from [[Voice and Tone]]: short paragraph, one wry parenthetical, stops before it explains ("There isn't. The village laughs because there is.").

**4. New Game + skip-tutorial (§4.8, [[Onboarding and Tutorial]] open items).** A title screen with **New Game** (wipes `user://wyrd_save.json` via a guarded call, re-enters at `tutorial_step = 0`) and **Continue**. A returning-player **skip path**: if a completed-tutorial save is detected, New Game offers "Skip the first lessons" which seeds `tutorial_step = TUTORIAL_OBJECTIVES.size() - 1` and marks core hints seen.

### Data model & formulas (GDScript-flavored)

New persisted fields on `Game` (mirroring `seen_hints`):

| Field | Type | Purpose |
|---|---|---|
| `seen_affixes` | `Array[String]` | which affix ids have been delved; drives first-teach bias |
| `seen_debriefs` | `Array[String]` | milestone-debrief ids already leaked |
| `strings_locale` | `String` (`"en"`) | reserved for the string table |

First-teach predicate:
```gdscript
func first_teach_affix(chart: Dictionary) -> String:
    var unseen := []
    for a in chart.get("affixes", []):
        if not seen_affixes.has(String(a.id)):
            unseen.append(String(a.id))
    return unseen[0] if unseen.size() == 1 else ""  # "" = combine freely
```

**Phase-0 string table.** A `data/strings.gd` dictionary `STRINGS: { id -> text }` with **stable IDs** (`affix.mineral_vein.good_name`, `codex.enemy.hedgemother`, `debrief.first_run`, `tutorial.step.2`). A thin `S(id, args := {})` lookup. Rumor headers (§4.3) compose from fragment IDs, never inline literals (§6 localization). Migration of existing inline strings is mechanical: move `AFFIXES[*].name/bad_name/desc` and `TUTORIAL_OBJECTIVES` and `SKILL_HINTS` into `STRINGS`, leave behind `S(...)` calls. This is the §6 deliverable "string table stood up in Phase 0, single-locale."

**Save migration ladder (Plan §0, §9).** Replace the destructive `version != VERSION → discard` with an ordered migrator chain on `version < VERSION`. The new fields default-empty on old saves (additive migrators), so onboarding state survives a version bump instead of resetting the tutorial.

### Content to author (tiers / worked examples)

- **~9 affix Codex entries** (the existing roster) + **4-creature crypt family + Hedgemother + 2 Pale Veins additions (Hedgewight, Burrow Boar)** = ~16 Codex stubs for the demo, each a 2–3 sentence verbatim quote.
- **5 Mara debrief fragments** (one per milestone above), ending on the locked capstone line.
- **One worked first-teach example:** player inscribes their first Mineral-Vein chart → den is suppressed to ore-only → on return, summary card shows "Mineral Vein" + the Codex unlocks its entry verbatim → next chart, Mineral Vein may combine with Bramble Bloom freely.
- **Codex sample (voice-checked):** *Hedgewight* — "Old quarry-folk, kept walking after the rock took them. They mean no harm; they just forgot the way out. (So did the rock.)"

### Edge cases, failure modes, anti-frustration

- **Double-unseen charts:** if two affixes are unseen on one chart, fall back to combine-freely (no forced single-teach) so the player is never blocked from inscribing what they want — they just learn both at once, like a late [[The Witness]] panel.
- **Skip-tutorial player misses hints:** mark all `SKILL_HINTS` keys seen on skip so a veteran isn't lectured.
- **Debrief never stalls play:** fragments are passive dialog rotations; the loop never waits on talking to Mara (the §4.8 "never a quest stop" rule). Missing a milestone debrief (player never returns) is fine — it simply waits.
- **No grimdark leak:** every authored string passes the [[Voice and Tone]] anti-pattern list; the Codex stops before explaining the Bramble Bargain (§3.2 — *never explained*). Anti-escalation holds: no Codex entry implies anything worse than the Hedgemother (P6).
- **Self-rescue over hints:** following [[The Witness]], a stuck player can always walk to another node/station; the open world of the yard is the hint system. No yellow-`!` dependency beyond the one in [[Onboarding and Tutorial]]'s existing reference.

## Interlocks — how this feeds/uses other systems

- [[Charts]] / [[Affixes]] — first-teach reads `chart.affixes` and biases generation; affix `name`/`bad_name` are the only popup.
- [[Chart Loop]] — milestones that trigger debriefs are loop completion events.
- [[Dungeon Generation]] — first-teach suppresses competing affix spawns for one run.
- [[Save System]] — `seen_affixes`/`seen_debriefs`/string-locale persist; depend on the §0 migration ladder.
- [[NPCs]] — Mara owns tutorial + debriefs; Hod's Pale Veins arrival line (Plan §3.6) is a later debrief surface.
- [[Voice and Tone]] / [[World Lore]] — the verbatim-quote source for every Codex entry and fragment.
- [[Multiplayer Co-op]] — debriefs/teach are host-authoritative onboarding state; guests inherit the host's taught-affix view (correctness, not a new system).

## Demo scope vs Horizon

**DEMO (built now, per §4.7/§4.8):**
- First-teach-the-affix bias + `seen_affixes` tracking.
- Mara's 5 milestone return-debriefs (incl. the locked capstone line).
- The **Codex shell** by verbatim quote, seeded crypt + Pale Veins (§4.7).
- **Phase-0 string table** with stable IDs (§6).
- New Game button + skip-tutorial path (§4.8 onboarding hardening).
- Saturate every systemic string through [[Voice and Tone]] (§4.8 copy pass).

**HORIZON (named, not built):** the **full Codex** with cosmetic-title milestones (§10.3); domestically-motivated NPC questlines and den set-dressing-by-affix recurrence at depth (§4.8 Horizon); the full NPC mentor cast beyond Mara + Hod (§3.6); festivals as narrative beats (§3.5). None of these gates the demo (P7 cut-line: no new system ships until a region using it is complete).

## Implementation notes (Godot)

- **`scripts/game.gd`** — add `seen_affixes`/`seen_debriefs`; `first_teach_affix()`; debrief check in the existing return-to-town path beside `advance_tutorial()`; teach-flag passed to the run config (near `active_chart` assembly, ~line 747).
- **`scripts/save_game.gd`** — persist the new fields (mirror `seen_hints`, lines 24/78); **replace the line-53 destructive reset with the migration ladder** (the load-bearing §9 step).
- **`data/strings.gd`** (new) — `STRINGS` + `S(id)`; migrate inline literals from `charts.gd` `AFFIXES`, `game.gd` `TUTORIAL_OBJECTIVES`/`SKILL_HINTS`.
- **`data/codex.gd`** (new) — `{ id -> { name, quote } }`, unlocked into a `discovered_codex: Array` on first-discovery; rendered by a new kit-compliant Codex panel (Horizon for the *full* UI; the demo shell can reuse `dialog_panel.gd`).
- **`scripts/wayfinder_npc.gd`** — Mara's debrief rotation reading `seen_debriefs`.
- **Title scene** — New Game / Continue / Skip, guarded by `WYRD_NO_SAVE`.
- **Tests:** `test_wyrd_loop.gd` guards the chart/economy path (extend with a first-teach assertion: a never-seen affix yields a single-affix run). `test_skills.gd` guards hotbar hint dispatch. A **save-migration assertion** (a v0 file migrates, keeping `tutorial_step`) belongs in `test_wyrd_loop.gd` per §8. All four headless suites stay green (the only hard gate, P10).

## Open questions

- Should the first-teach bias *fully* suppress competing affixes, or just down-weight them? Full suppression reads cleaner (Portal) but a barren-feeling den risks the cozy contract — lean down-weight if playtest finds it sterile.
- Milestone set for debriefs: are 5 enough to land the throughline, or does the capstone line need a dedicated first-Deepening trigger (which is Horizon)?
- Codex panel: ship a real kit-compliant panel in the demo, or reuse `dialog_panel.gd` and defer the panel to Horizon? (§6 says any new panel needs a ninepatch pass + capture surface.)
- Does skip-tutorial mark `seen_affixes` as fully seen (no first-teach for veterans) or leave affix-teaching armed even on skip? Leaving it armed preserves the best "remembering" beat.

## See also / Sources

- [[Onboarding and Tutorial]] · [[Voice and Tone]] · [[World Lore]] · [[NPCs]] · [[Universe Build-Out Plan]] · [[Balance Philosophy]]
- [[Charts]] · [[Affixes]] · [[Chart Loop]] · [[Save System]] · [[Dungeon Generation]]
- [[Portal 2]] (isolate-then-combine) · [[The Witness]] (wordless, self-rescue) · [[Disco Elysium]] (world-voice saturates the UI)
- Code: `wyrd/scripts/game.gd`, `wyrd/scripts/save_game.gd`, `wyrd/data/charts.gd`, `wyrd/data/affixes.gd`
