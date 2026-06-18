# Gap backlog — prompts + verification, in build order

One prompt per gap (from the 2026-06-18 gap audit). Each lands as: code →
**automated verification** (headless scenario assertion in a gate suite, and a
windowed screenshot when the gap is visual) → commit → next. Ordered so the
cheap correctness + the shippable shell come first; asset/decision-blocked items
are parked at the end.

**Verification legend:** `H` = headless assertion (gate suite) · `S` = windowed
screenshot · `I` = input-driven capture (trigger the skill/flow, screenshot).

---

## Wave A — correctness bugs (quick, high-confidence)
1. **Fix thornshelled CC-immunity.** combatant.gd:665 hardcodes `modifier ==
   "briarbound"`; read `cc_immune_window` from the modifier data so `thornshelled`
   (8.0s) also resists root/snare. *Verify (H):* test_coop/test_statuses — apply
   root twice to a thornshelled elite within the window, assert the 2nd is refused.
2. **Add the hedgesteel chest recipe.** crafting.gd has `hedgesteel_cap_smith` +
   `hedgesteel_boots_smith` but no jerkin; add `hedgesteel_jerkin_smith`
   (mirrors palechalk_jerkin, yields leather_chest at the right rarity) + to the
   forge station recipe list. *Verify (H):* test_wyrd_loop — assert the recipe
   exists, is forgeable at its req level, yields a chest.

## Wave B — the shippable shell (self-contained; needed before anyone else plays)
3. **Title screen / main menu.** New `Main.tscn` as the boot scene: New Game /
   Continue / Co-op (Lantern) / Options / Quit. Continue → Town; New Game →
   reset_to_defaults → Town. *Verify (H):* the menu scene instantiates + each
   button routes; *(S)* screenshot the title.
4. **Settings / Options menu.** Master/SFX/Music volume sliders (wire to audio
   buses), fullscreen + window-mode toggle; persist in the save/config. Reachable
   from title + pause. *Verify (H):* setting a volume changes the bus; persists a
   round-trip; *(S)* screenshot.
5. **Pause menu.** In a run, `Esc` opens Pause (Resume / Options / Abandon to
   town / Quit) when not in co-op; co-op keeps the Lantern. Pauses the tree
   offline. *Verify (H):* esc in-dungeon offline toggles pause; *(S)* screenshot.
6. **Credits screen** (from title + a short ADR for asset attribution:
   Claude/Meshy/Midjourney/ElevenLabs). *Verify (S):* screenshot.

## Wave C — combat feel & skill identity (self-contained; screenshot-verifiable)
7. **Mercy Shot execute ring + kill burst** (impl-skill-mercy-shot tasks 1–7):
   amber ring under sub-35% foes, silver-white finisher burst. *Verify (H)* ring
   appears/clears at the threshold via a unit check; *(I)* screenshot the ring.
8. **Heartwood Ward HUD arc + bark tint + SFX-keys + icon** (impl-skill-
   heartwood-ward 1–9). *Verify (H)* get_ward_frac math; *(I)* screenshot the arc.
9. **Piercing Bolt pierce-count upgrade** + **Rain/Thornburst VFX polish**
   (their impl docs). *Verify (H)* bonus_pierce in derived_stats; *(I)* screenshot.
10. **Queen of Thorns phase-3 summon** (impl-system-bosses 10–11): summon_wave +
    skeleton adds + wider telegraph + tighter cooldown. *Verify (H)* phase-3
    triggers the summon path in test_coop boss harness; *(I)* screenshot a den.
11. **Elite depth:** depth-scaled spawn density + `reward_tier_bonus` in
    _spawn_drops. *Verify (H)* density scales with depth; drop rarity floor lifts.

## Wave D — content depth & legibility (self-contained)
12. **Widen the drop pool** — add a few mid-tier droppable gear kinds (or tier
    the existing 6 by depth) so loot varies lv1→17. *Verify (H)* drop kinds by
    depth.
13. **HUD multi-trade readout + quest sub-objective line** (impl-system-hud 5–6).
    *Verify (H)* readout lists all leveled trades; *(S)* screenshot.
14. **SKILL_HINTS** for shrine/status_bleed/status_slow/affix_reading + wire call
    sites. *Verify (H)* first-contact sets the seen_hint.
15. **Quill reactive + Hod greeting dialogue** (npc-story 7–9). *Verify (H)*
    branch picks the right pages by flags.

## Parked — needs you (asset spend / art / a design call)
- **Audio (biggest felt gap):** dungeon + boss music, ~9 missing SFX (inscribe
  seal, town ambience, rain/thornburst impacts, inv_full…). *Blocked:* ~$0.85
  ElevenLabs spend approval. Then *verify (H)* keys resolve to real files.
- **Art:** 6 skill-icon PNGs, 8 item icons, NPC portraits. *Blocked:* Midjourney/
  art gen. Code paths already accept them.
- **Biome GLBs:** hollow/briar_maze/snug decor; barrow_brute rig. *Blocked:* Meshy.
- **Death stakes:** what should dying cost in a cozy game? *Blocked:* design call.
- **Distribution-tier:** gamepad support, key-rebind UI, accessibility (statuses
  are hue-only). *Large; revisit pre-release.*

---
*Default mute is ON (game.gd) — once Settings (#4) ships, that becomes a slider,
so players actually hear the audio when it lands.*
