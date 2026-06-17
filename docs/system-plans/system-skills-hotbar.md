---
title: Skills, Hotbar & the Mastery Tree
domain: Player & Abilities
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Skills, Hotbar & the Mastery Tree

> The 4-slot hotbar, Focus resource, and loadout picker are fully shipped; the one load-bearing gap is **pick-one-of-N mastery** — the lv-5/10/14/17 choice nodes that turn auto-unlock rows into a player-identity decision.

## Current state

**Hotbar & dispatch — complete.** Slot 1 is always `BasicShot` (free, ~0.28s cadence via `fire_rate`); slots 2–4 are picked from a 9-skill pool (`game.gd:113` `SKILL_POOL`). `_try_skill` (`player_controller.gd:896–914`) guards every cast: dead/non-NORMAL move-state, Focus deficit, and cooldown are all silent no-ops; slot 1 routes through the fire buffer, slots 2–4 deduct `skill.cost` and seed `_skill_cooldowns`. `rebuild_skills` (`player_controller.gd:1417–1436`) uses `SKILL_FACTORY` to construct fresh `Skill` instances from `Game.loadout` and re-seeds cooldown keys 1–4 (the bare-clear regression was fixed here — `test_skills.gd` is the regression gate).

**Focus resource — complete.** `FOCUS_MAX = 50`, regen 10/s out of combat, 3/s in (`player_controller.gd:157–163`), modulated by chart affixes (`_chart_focus_mult`) and tonics (`_buff_focus_mult`). The only refund is Even Breath (lv 17 perk: +6 Focus per kill). No second bar exists by design (ADR 0014).

**Hotbar UI — complete.** `skill_bar.gd` + `scripts/ui/hotbar_slot.gd` + `hotbar_tray.gd` draw a carved-wood tray with per-slot radial cooldown wedge and a gold ready-flash. The bar reads Focus + `_skill_cooldowns` each `_process` frame and greying-out is the player's silent rejection signal. Four of 9 skills have painted icons (`skill_basic/power/multi/snare.png`); the remaining five use inked Unicode glyphs (`skill_bar.gd:44–51`). Tooltips include name, desc, cost, and cooldown.

**Loadout picker — complete.** `scripts/ui/loadout_panel.gd` opens at the dungeon Hearth and the Cottage Hearth; `Game.set_loadout` (`game.gd:242–259`) validates pool membership, deduplication, and Wayfinding-level gates then calls `rebuild_skills` on the live player. Three skills gate on Wayfinding level: HuntersMark @ 4, HeartwoodWard @ 7, MercyShot @ 9 (`game.gd:118`); locked cards appear dim with a level badge but are not hidden.

**Mastery ladder (Trades page) — structurally shipped, but auto-unlock only.** `inventory_panel.gd:_draw_trades_tab` (`lines 798–900`) renders a scrollable level-1→17 spine with per-perk cards — lit when `trade_lv >= perk.lv`, dim otherwise. `perk_active` (`game.gd:461–465`) auto-grants a perk whenever the level threshold is met; there is no player choice. Multiple perks share the same unlock level (lv 5: 4 perks; lv 10: 4 perks; lv 14: 2 perks; lv 17: 4 perks), which is exactly the shape the pick-one-of-N mechanic would resolve. ADR 0012 (`docs/adr/0012-one-skill-wayfinding.md`) explicitly flags "Pick-one-of-N mastery is a planned refinement."

**Skill icons** — 5 of 9 hotbar skills and 3 of 9 loadout-panel skills are still using fallback glyphs/shared icons. No functional gap, but a visual roughness.

## Gaps — what needs fleshing out

1. **[BLOCKER for mastery identity] Pick-one-of-N mastery choice at multi-perk levels.** lv 5/10/14/17 each have 2–4 perks that auto-unlock together. The design intent (ADR 0012, ADR 0014) is that the player chooses one. Requires: a choice signal on `award_xp` level-up when the new level is a multi-perk node, a choice UI (modal or Trades-page inline), `game.gd` storage of picked perks, and `perk_active` checking the pick set rather than just the level threshold.
2. **Painted skill icons for 5 of 9 skills.** PiercingBolt, RainOfThorns, Thornburst, HuntersMark, HeartwoodWard, MercyShot still fall through to glyphs in the hotbar and reuse incorrect icons in the loadout panel (`loadout_panel.gd:31–41` maps thorn skills to the snare icon, hunter/ward/mercy to the basic icon). Purely cosmetic but misrepresents skill identity.
3. **Level-up visual moment (Plan.md Part B / Phase B3).** `leveled_up` fires but there is no perk-name banner, no burst, no HUD flash. This is Plan.md's Phase B3; see that doc for the implementation contract — do not re-plan here. The mastery-choice modal (gap 1) should fire *after* the level-up burst, not instead of it.
4. **Skill-slot count is hardcoded to 4.** `_try_skill` bounds-checks `slot > skills.size()`, but the bar always builds exactly 4 slots. Future expansion (a 5th slot) needs a single-place change; the current structure supports it but it is not documented.
5. **No "unlock preview" for gated skills.** Locked cards show "Wayfinding N" as a badge but do not preview what the skill does until the level is met. A playtest note (wyrd-roadmap.md item 14) flagged discoverability.
6. **CDR cap and Even Breath not surface-visible.** `CDR_CAP = 0.80` (`skill.gd:9`) and the Even Breath refund (+6 Focus on kill) are never shown to the player. A tooltip or Trades-page annotation would close the "why did my cooldown stop improving?" question.

## Plan

### Phase 1 — Pick-one-of-N mastery choice (the centerpiece)

**Rationale:** This is ADR 0012's "planned refinement" and ADR 0014's open followup. The perk table already has the right shape (multi-perk level nodes). This phase turns auto-unlock into a one-time identity decision per tier.

**Data model changes (`game.gd`):**
- Add `var chosen_perks: Dictionary = {}` (perk_id → bool, persisted in the save alongside `loadout`).
- Define which levels are choice nodes: `const MASTERY_CHOICE_LVS := [5, 10, 14, 17]`.
- Change `perk_active` to: for levels in `MASTERY_CHOICE_LVS`, return `chosen_perks.get(perk_id, false)` if `trade_lv >= lv`; for single-perk levels (2, 3, 12, 13), keep the existing threshold check. This preserves behavior for non-choice perks unchanged.
- Add `func choose_perk(perk_id: String) -> bool` — validates the perk exists, the choice node's level is met, the node is not already chosen, and writes `chosen_perks[perk_id] = true`; calls `save_now()` and `_derive_stats()`.
- In `award_xp`, after a level-up, if the new level is a `MASTERY_CHOICE_LVS` node, emit a new `mastery_choice_ready(level: int)` signal.

**Choice modal (`scripts/ui/mastery_choice_panel.gd`):**
- Triggered by the `mastery_choice_ready` signal. Blocks `_unhandled_input` (same pattern as `loadout_panel`); Esc does not close it — a choice must be made.
- Layout: title "A new mastery opens" + the tier level; one drawn skill-card per perk at that level (reuse `_SkillCard` from `loadout_panel.gd`, stripped of the pick-toggle); tapping a card calls `Game.choose_perk(id)` and closes.
- Cards show: perk name, description, and a thematic category label (gather / combat / chart / craft) derived from a `PERK_CATEGORY` const added to `game.gd`.

**Trades page update (`inventory_panel.gd:_draw_trades_tab`):**
- At choice-node levels, split the card row into a side-by-side comparison layout. Chosen = sage ring; unchosen but available = dim; not yet reachable = locked.
- Show a "Choose one" prompt chip if the level is reached but no choice has been made yet (edge: the player loaded a save made before this system existed — default to all-granted for backward compat).

**Save migration:** `save_game.gd` — on load, if `chosen_perks` key is absent and `trade_lv >= 5`, populate it by granting the first perk at each choice node (preserves old-save behavior without breaking anything).

- **DoD:** at lv 5, 10, 14, and 17, a modal fires; the player picks one perk; unchosen perks are not active; the choice persists across saves; old saves auto-migrate without regression; `test_skills.gd` extended with a `_test_mastery_choice` suite (set lv → check signal fires → call `choose_perk` → assert `perk_active` for chosen, not for unchosen); all five gate suites stay green.
- **Effort: M**

### Phase 2 — Painted skill icons for the remaining 5

**Rationale:** Glyphs are functional but undermine skill identity. Four icons exist; five need creating. This is a pure-asset pass — no code changes except adding entries to `SKILL_ICON` in `skill_bar.gd` (line 35) and `loadout_panel.gd` (line 31). The code path already handles the presence of an icon (`ResourceLoader.exists` check at `skill_bar.gd:112`).

**Steps:**
- Commission or generate painted 64×64 ink-style icons for: PiercingBolt, RainOfThorns, Thornburst, HuntersMark, HeartwoodWard, MercyShot. Style anchor: match `skill_basic/power/multi/snare.png` (ink-line, warm parchment, bold read at 72px).
- Drop into `wyrd/assets/ui/icons/skill_<name>.png` and run `wyrd/tools/check_ninepatch.py` (not a ninepatch, but the tool also validates icon sizes).
- Add to `SKILL_ICON` in both `skill_bar.gd` and `loadout_panel.gd`; remove the redundant shared-icon entries in `loadout_panel.gd:31–41`.

- **DoD:** all 9 skill slots in hotbar and loadout panel display a distinct painted icon; no glyphs remain; screenshot-verified at 72×72 slot size.
- **Effort: S** (code) + asset round-trip time.

### Phase 3 — Discoverability & CDR transparency

**Rationale:** Addresses gaps 5 and 6 without new systems; pure data-display work reusing existing tooltip and Trades-page patterns.

**Unlock preview in loadout panel:** Locked `_SkillCard` rows already show "Wayfinding N". Extend: below the gate badge, render the first ~60 chars of the skill's description in dim text (use the existing `draw_multiline_string` call at `loadout_panel.gd:263`). No change to click behavior; locked cards remain non-interactive.

**CDR annotation on the Trades page:** Add a compact "Skills" section to `_draw_trades_tab` after the mastery ladder. List each skill in the current loadout with its `base_cd`, the effective CDR at the current `cooldown_reduction` stat, and the resulting `effective_cd` (computed via `Skill.effective_cd`). One line: "Quick Nock · CDR 10% → PowerShot 1.36s". Show CDR cap notice when `cooldown_reduction >= CDR_CAP`.

**Even Breath tooltip:** In the Trades-page perk card for `even_breath`, add a second description line: "+6 Focus on every kill (not XP — a Focus refund)". This requires only a `desc` edit in `game.gd:PERKS`.

- **DoD:** a player can read any locked skill's description without reaching the gate level; the Trades page shows the current effective cooldown for each loadout skill; `even_breath` card clarifies it is a Focus refund not XP. No new headless test needed; screenshot-verified.
- **Effort: S**

## Dependencies & links

- [[system-trades-progression]] — the single Wayfinding XP/level engine that drives perk unlocks; `award_xp` is where the `mastery_choice_ready` signal must fire; ADR 0012 and ADR 0013 live here.
- [[system-player-controller]] — hosts `_try_skill`, `rebuild_skills`, `SKILL_FACTORY`, `focus`/`focus_max`, and `FOCUS_REGEN_OUT/IN`; the hotbar is a view over this controller's live state.
- [[system-hud]] — `skill_bar.gd` + `hotbar_slot.gd` are HUD components; the mastery-choice modal must respect HUD layering (layer 95, above layer 50 of the skill bar).
- [[system-ui-panels]] — `loadout_panel.gd` and the planned `mastery_choice_panel.gd` inherit the WyrdUi kit (`wyrd_ui.gd`); the `_SkillCard` inner class from `loadout_panel.gd` is the reuse target for the choice modal.
- [[system-status-effects]] — HuntersMark, HeartwoodWard, and BrambleSnare produce status effects that interact with enemies; any skill-tree changes touching those skills must track here.
- [[system-combatant-ai]] — enemy `hp`/`dmg` scaling (ADR 0013) is the context in which loadout choices matter; the level-delta bands determine which skills are live or panic buttons.
- [[system-save-load]] — `chosen_perks` must be added to the save schema; the migration path (absent key → auto-grant first at each node) must be coordinated here.
- [[skill-basic-shot]], [[skill-power-shot]], [[skill-multi-shot]], [[skill-bramble-snare]], [[skill-piercing-bolt]], [[skill-rain-of-thorns]], [[skill-thornburst]], [[skill-hunters-mark]], [[skill-heartwood-ward]], [[skill-mercy-shot]] — the 9 concrete skills in the pool; each note is the spec for that ability's behavior and balance.
- **Plan.md Part B / Phase B3** — the level-up burst + perk banner beat. The mastery-choice modal should fire *after* B3's visual moment, not replace it. Do not re-plan B3 here; implement B3 first (or in parallel), then hook the choice modal to follow it.

## Verification

**Phase 1 (mastery choice):**
- Extend `test_skills.gd` with a `_test_mastery_choice` function: set `trades["wayfinding"]["lv"] = 5`, call `award_xp("wayfinding", 0)` to trigger the signal, invoke `Game.choose_perk("steady_hands")`, assert `perk_active("", "steady_hands") == true`, assert `perk_active("", "double_ore") == false`, assert `perk_active("", "curious_fingers") == false`, assert the save round-trip preserves the choice. Run: `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd`.
- Verify save migration: create a save with lv 9, no `chosen_perks` key, load it, assert all four lv-5 perks do not error (one auto-granted for each node).
- All five gate suites must stay green: `test_wyrd_loop`, `test_wyrd_dungeon_scene`, `test_wyrd_transitions`, `test_skills`, `test_stats`.

**Phase 2 (icons):**
- Screenshot the hotbar at 72×72 slot size in-game (`WYRD_SHOT=1`); confirm all 9 slots show a painted icon (no Unicode glyphs).
- Screenshot the loadout panel opened at the Cottage Hearth; confirm all 9 skill cards show distinct icons.

**Phase 3 (discoverability):**
- Open the loadout panel at lv 1 (HuntersMark locked at 4); screenshot confirms the skill description is visible under the gate badge.
- Open the Trades page at lv 12 (Quick Nock active); screenshot confirms the skill CDR section shows effective cooldowns.

## Open questions

1. **How many picks per choice node?** The current design implies exactly one-of-N at each tier. A two-of-four model at lv 5 would reduce anxiety but also reduce identity. Needs a player decision before Phase 1 ships.
2. **Can the player ever re-pick?** The charter-at-a-Hearth model allows loadout swaps mid-session. Should mastery choices be permanent per-save, or re-pickable at the Trades Hearth? Permanent is simpler; re-pickable is friendlier. This changes whether Phase 1 needs an "undo" path.
3. **Perk categories for the choice modal** — the `PERK_CATEGORY` const (gather / combat / chart / craft) is proposed but not defined. The labels affect how players reason about builds. Worth a quick list pass before the modal is built.
