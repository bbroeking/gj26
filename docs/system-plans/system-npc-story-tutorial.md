---
title: NPCs, Story & Tutorial
domain: World & Interactables
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# NPCs, Story & Tutorial

> Three NPCs are live (Mara, Quill, Hod), dialog panel is polished, and tutorial steps 0–7 are gated correctly — the gaps are: no shrine/status-effect/chart-affix tutorial hints, Quill has no reactive content, the summit payoff ends abruptly, and NPC portraits are ghosted silhouettes.

## Current state

**Mara Linnet (WayfinderNpc):** fully authored tutorial arc, steps 0–7 (`wayfinder_npc.gd:45–74`). Step-keyed dialog branches off `game.tutorial_step`; step 0→1 advance wires to `dlg.finished` (`wayfinder_npc.gd:43`). Post-tutorial she delivers lore about elites → trophy chain → Summit. Summit-cleared branch lands at `wayfinder_npc.gd:32–36` — three pages, then silence (no "what now" content). First-time hint dialogs for all seven gather verbs/stations fire via `game.first_time_hint()` (`game.gd:136–176`) — authored in Mara, Hod, and Quill's voices. This is the only proactive in-world tutorialization that exists.

**Quill (QuillNpc):** three static flavor lines, no state-reactive branches (`quill_npc.gd:30–36`). Her still + buff system is fully shipped (alchemy A8-full); she never reacts to a player having quaffed a tonic, reached a level gate, or completed the Summit.

**Hod (VendorNpc):** opens the vendor panel directly on interact (`vendor_npc.gd:28–30`), no dialog lines. The roadmap notes his hint should stop promising ore-selling once the full gear ladder is visible — that line was removed (`docs/wyrd-roadmap.md:128`) but he has no replacement flavor.

**Dialog panel:** production-ready — carved wood frame, portrait well (ghosted silhouette, `dialog_panel.gd:137–145`), speaker name in terracotta, body text, E/Space/click/Esc navigation, `finished` signal, modal pause/unpause (`dialog_panel.gd:80,130`).

**Tutorial gate:** steps advance by talk (step 0), materials check (step 1), `mix_ink` (step 2), `add_chart` (step 3), `enter_dungeon` (step 4), `return_to_town` (step 5), `add_chart` non-snug (step 6); all at `game.gd:546–655`. `objective_text()` and `objective_progress()` feed the HUD quest plate. Mid-run steps 0–4 redirect the tracker to "Find the far waystone" (`game.gd:813`). Post-tutorial the standing objective is "Chart your way to the Summit" until `summit_cleared`.

**Absent:** no contextual hint for shrines (first shrine encountered in-dungeon), no hint for status effects (bleed/slow), no hint for chart-affix reading (the signature Wayfinding verb, step 6 teaches it minimally), no Quill reactive content, no post-Summit extended content, no painted portraits.

## Gaps — what needs fleshing out

1. **BLOCKER (player confusion): No shrine hint.** First shrine encounter has no tutorial — players can skip the buff without understanding the cost (one-shot, no cancel). A `first_time_hint("shrine")` keyed to the first `Shrine.interact()` call, voiced by Mara, fixes this. Simple addition following the existing pattern.
2. **BLOCKER (player confusion): No status-effect hint.** Bleed and slow land silently on the player; no NPC explains what the icons mean. A `first_time_hint("status_bleed")` / `first_time_hint("status_slow")` keyed from `status_effect.gd` on first application.
3. **Gap: No chart-affix reading hint.** Step 6 (inscribe a Tier 1) advances the tutorial but no one explains good/bad twin affix color coding or how to read the odds preview. Mara should fire a one-time hint at step 6 completion.
4. **Gap: Quill is inert post-A8.** She brewed a tonic system; she should reference it in reactive dialog (first tonic quaffed, buff fading, level-gated recipes). Three variant line-sets following the SKILL_HINTS pattern.
5. **Gap: Summit payoff ends.** After `summit_cleared`, Mara delivers three pages then returns to her post-tutorial lore loop (`wayfinder_npc.gd:70–74`) — no distinction between "haven't done the Summit" and "already cleared it." The game ends silently. A post-summit extended conversation (4–6 pages, Mara naming the journey, hinting at what deeper hollows might mean) plus a final Quill and Hod reaction would close the arc.
6. **Gap: NPC portraits are silhouettes.** The portrait well (`dialog_panel.gd:43–45`) renders a parchment disc + ghosted body shape — atmospheric but signals "placeholder". Painted portraits are listed as "art one-offs" in the roadmap.
7. **Gap: Hod has no voice.** The vendor panel opens directly; a brief greeting-then-open pattern (one page, then auto-open panel) would make him feel like a character rather than a menu.
8. **Polish: Tutorial step 5 ("find the far waystone") has no in-world aid.** A ghosted indicator on the exit waystone, or Mara's step-4 dialog explicitly naming "the glowing stone at the far end," would reduce aimless wandering on a first run.

## Plan

### Phase 1 — In-dungeon first-contact hints (shrine + status)
Plugs the two player-confusion blockers with minimal code, following the proven `first_time_hint` pattern.

- Add `"shrine"` key to `Game.SKILL_HINTS` (`game.gd:135`): speaker Mara Linnet, 2 pages explaining one-shot cost and color-coded buff choices. Call `game.first_time_hint("shrine")` from `Shrine.interact()` before opening the modal — check for `_consumed` false so repeat clicks don't re-fire.
- Add `"status_bleed"` and `"status_slow"` keys (same dict). Speaker Mara for bleed (Thorn Essence flavor); Mara or a neutral "Wayfinder's Note" for slow. Call from `StatusEffect._ready()` or from `player_controller.gd` on first application (check `seen_hints` gate, same as gather verbs).
- Add `"affix_reading"` key. Fire from `Game.advance_tutorial()` when `tutorial_step` crosses 6 (inscribe Tier 1 complete). Two pages: good twin (gold tint) vs bad twin (red tint), how odds shift with ink quantity.
- **DoD:** fresh save — first shrine in any crypt dungeon shows the Mara hint before the choice modal; first bleed status fires the hint once; completing step 6 shows the affix hint. All four headless suites stay green (`WYRD_NO_SAVE=1`). No new files needed.
- **Effort: S**

### Phase 2 — Quill reactive dialog
Brings Quill's three static lines in line with her shipped A8 system.

- Extend `QuillNpc.interact()` to branch on `game.seen_hints` and `game.tutorial_step` (same access pattern as `wayfinder_npc.gd:29`).
- Three branch states:
  - **Pre-tonic-use:** current three lines (unchanged).
  - **Post-first-tonic-quaff:** detected via a new `seen_hints["tonic_quaffed"]` flag set in `Game.quaff_buff_draught()` on success. Two pages — Quill notices, names the duration ("keeps a week"), points at her recipe scroll.
  - **Buff-level-gated:** if `game.trade_lv("wayfinding") >= 6` (Clearwater Philter gate), Quill offers a hint about the deeper brew.
- Add `"still"` first-time hint (already authored in `SKILL_HINTS` at `game.gd:160–163`) — verify it fires on first still interaction (it should via `first_time_hint` but the trigger site needs confirming in `craft_station.gd`).
- **DoD:** talking to Quill after quaffing a tonic returns a distinct 2-page response; the gates are mutually exclusive (only the deepest-relevant branch fires); four suites green.
- **Effort: S**

### Phase 3 — Hod greeting + voice
Gives Hod a brief character moment before opening the vendor panel.

- Change `VendorNpc.interact()`: instantiate a `DialogPanel`, one page greeting ("Bring me ore or coin — I'll make either work"), connect `finished` to open `VendorPanelScript`. This is the same deferred-open pattern Mara uses for tutorial advance (`wayfinder_npc.gd:42–43`).
- Add two reactive variants: first visit (explains the buy/sell split); repeat visits after `summit_cleared` (gruff congratulation, one line).
- Add a `seen_hints["hod_intro"]` gate so the greeting plays once per save, then skips to panel-open on subsequent interactions.
- **DoD:** first Hod interaction shows one greeting page then opens vendor panel; repeat visits go direct to panel; `summit_cleared` triggers a one-off congratulation line; four suites green.
- **Effort: S**

### Phase 4 — Summit narrative payoff
Closes the story arc. Do after Phase 1–3 (all NPC voices are warm by then).

- Extend `WayfinderNpc._pages_for()` (or a new helper) with a `post_summit` state distinct from the generic post-tutorial lore loop (`wayfinder_npc.gd:70–74`). Mara gets 4–6 pages: name the journey, acknowledge the trophy chain, hint at "deeper hollows" as an open world-hook rather than a game-over beat. World Bible voice rules apply — plain-spoken, no fantasy-isms.
- Add a one-time `seen_hints["summit_mara"]` gate so the extended conversation only fires on the first post-summit talk; subsequent visits fall through to the short "go deeper" loop.
- Quill one-time post-summit reaction (1 page, herbal metaphor for endurance): gate on `seen_hints["summit_quill"]`.
- Hod one-time post-summit reaction (1 page): gate on `seen_hints["summit_hod"]`.
- **DoD:** after `summit_cleared`, talking to each NPC once triggers their unique reaction page(s); second visit shows normal post-tutorial dialog; four suites green. Playtest sign-off on tone (these lines carry narrative weight — the user should read them).
- **Effort: S–M**

### Phase 5 — NPC portraits (art-dependent, deferred)
The portrait well is ready (`dialog_panel.gd:43`); this phase is blocked on painted assets.

- When painted portrait PNGs exist for Mara, Quill, and Hod: subclass or extend `PortraitWell` to accept a `portrait_texture: Texture2D`. Pass it from the NPC `interact()` call. Preload in `_ready` (never `load()` inside `_draw` — see `feedback_godot_draw_load_white_texture`).
- The `PortraitWell._draw()` ghosted silhouette stays as fallback until each portrait is ready.
- **DoD:** each NPC's dialog panel shows their painted portrait instead of the silhouette; `check_ninepatch.py` not affected (portrait is drawn, not a nine-patch).
- **Effort: S** (code-side only; art effort is separate). **Blocked on art delivery.**

## Dependencies & links

- [[system-town-hub]] — Mara, Quill, and Hod are placed in the Chartmakers Yard; their positions and interaction radii are part of the town scene. Quill's still and Hod's forge are town interactables.
- [[system-interactables]] — `WayfinderNpc`, `QuillNpc`, and `VendorNpc` all `extend Interactable`; the prompt/collision/GlbFit stack is inherited, not duplicated.
- [[system-charts-wayfinding]] — Tutorial steps 3 (inscribe Snug) and 6 (inscribe Tier 1 with affix) are chart-system events. The affix-reading hint (Phase 1) explains content defined there.
- [[system-trades-progression]] — Tutorial step 2 (mix ink = Wayfinding verb) and the Quill buff-level gate (Phase 2) depend on the Wayfinding ladder. Perk names referenced in Phase 3's `PERKS` dict.
- [[system-ui-panels]] — `dialog_panel.gd` is the delivery vehicle for all NPC and hint content; portrait work (Phase 5) touches only this file's `PortraitWell` inner class.
- [[system-gathering]] — Phase 1's shrine/status hints and the existing `SKILL_HINTS` gather-verb hints share the same `first_time_hint()` gate pattern in `game.gd`.
- [[system-hud]] — The quest plate (`player_hud.gd:133–245`) surfaces `objective_text()` and `objective_progress()` from `game.gd`; tutorial step changes fire `tutorial_changed` which the HUD listens to. Phase 1's new hints do not change the objective text.
- [[system-bosses]] — The trophy chain (Hedgemother → Boar → Wolf → Summit) is the post-tutorial standing quest. Mara's lore pages (`wayfinder_npc.gd:70–74`) name it; Phase 4 closes that arc.
- Plan.md Part B / Phase B6 — the inscribing-table ritual (chart appears, affixes reveal one-by-one) is a feel pass that complements Phase 1's affix-reading hint without duplicating it. Do B6 and Phase 1 in either order; they touch different files.
- Plan.md Part B / Phase B7 — the town arrival beat (ambient swell, board reacts to unlock) is the environmental complement to the NPC reactions in Phase 4. They compose: B7 is visual; Phase 4 is voiced.

## Verification

- **Phase 1:** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` (shrine is placed in crypt layouts — test enters a dungeon; verify hint logic doesn't crash). All four suites green. Manual: fresh save, enter crypt, approach shrine — hint fires before modal; take a bleed hit — status hint fires once; complete step 6 — affix hint fires.
- **Phase 2:** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` — loop test crafts at the still; verify `quaff_buff_draught` sets the new flag without panic. All four suites green. Manual: fresh save, brew and quaff tonic, talk to Quill — reactive dialog shows.
- **Phase 3:** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` (loop visits the town scene where Hod lives). All four suites green. Manual: fresh save, first Hod interact — greeting page then vendor panel; second interact — panel direct.
- **Phase 4:** All four suites green. Playtest sign-off required — the user reads the summit dialog and approves the tone before merging. No automated assertion possible for narrative content.
- **Phase 5:** `wyrd/tools/check_ninepatch.py` (portraits are drawn, not nine-patches, so this is a no-op regression check). Manual: screenshot of dialog with painted portrait visible.

## Open questions

1. Should the shrine hint pause before or after the choice modal appears? Showing it first (before the modal) is pedagogically cleaner but delays the interaction. Showing it as a follow-up (post-choice) misses players who skip. Current plan: fire before modal, same frame.
2. Hod greeting on every fresh session vs. once ever — current plan is once per save (seen_hints gate). Is that the right call, or should he greet silently (straight to panel) after the very first visit?
3. Phase 4 summit dialog: does Mara hint at a sequel / deeper hollows, or close the loop cleanly? The World Bible supports both. Needs a call from the user before writing the lines.
