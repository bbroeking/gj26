---
type: design
tags: [system-design, presentation]
status: draft
updated: 2026-06-14
sources:
  - "kb/wiki/systems/UI and HUD.md"
  - "kb/wiki/systems/Camera and Game Feel.md"
  - "kb/wiki/pipeline/UI Workflow.md"
  - "kb/wiki/Universe Build-Out Plan.md"
  - "kb/wiki/concepts/Balance Philosophy.md"
  - "wyrd/scripts/ui/wyrd_ui.gd"
  - "wyrd/scripts/inventory_panel.gd"
  - "wyrd/scripts/ui/craft_panel.gd"
  - "wyrd/scripts/player_hud.gd"
  - "wyrd/scripts/skill_bar.gd"
  - "wyrd/scripts/boss_bar.gd"
  - "wyrd/scripts/camera_rig.gd"
  - "wyrd/scripts/sfx.gd"
  - "wyrd/tools/generate_audio.py"
  - "wyrd/tools/capture_ui.sh"
  - "games/arpg/Hades.md"
  - "games/roguelike/Slay the Spire.md"
  - "games/sports/Tetris Effect Connected.md"
  - "games/metroidvania/Celeste.md"
  - "games/roguelike/Dead Cells.md"
---

# UI HUD Camera and Audio — Deep Design

> Forward-looking deep design. Current-state: [[UI and HUD]], [[Camera and Game Feel]]. Constrained by [[Universe Build-Out Plan]].

## Player fantasy & role in the cozy spine

You are reading a storybook that reads you back. The HUD is the *margin of a hand-bound book* — carved-oak frames, sepia ink, parchment — never a sci-fi cockpit. The camera holds you large and warm at a low telephoto 3/4 so the Wolds have a horizon, not a map. Audio is the room's breath: a cozy bed at the cookfire, a held note when the Hedgemother turns. This system is **legibility as a first-class pillar** (Universe Plan §8): the spine — gather → craft → chart → delve — is only as cozy as it is *clear*. The "what this run feels like" card is where Wayfinding-as-remembering becomes legible; the Almanac is where town-growth (P4) becomes a place you can see fill in.

## What ships today (grounded in code)

- **The kit is real and consolidated.** `wyrd_ui.gd` (`class_name WyrdUi`) is the single source of palette tokens (`INK`/`TERRACOTTA`/`SAGE`/`GOLD`/`CREAM`/`KIT_PLATE`/`KIT_WELL`/`KIT_EDGE`), `panel_stylebox()`/`chip_stylebox()`/`style_kit_button()`/`make_meter()`, three IM Fell/Caveat font loaders, and spec-44 pure-vector `_draw` primitives (`draw_well`, `draw_round_well`, `draw_carved_button`, `draw_flourish`, `draw_ink_bottle`, `draw_scroll`, `draw_parchment_grain`). The nine-patch is `panel_frame_v2_9p.png` (margins 34/37/32/40).
- **Two hard rules are encoded.** Never `load()` a texture first inside `_draw` (white-rect forever) — `inventory_panel.gd::_ready` preloads into `_tex_cache` and even its scroll-mask path (`_draw_page_patch`) only touches the already-cached texture. New frame art must pass `tools/check_ninepatch.py`.
- **HUD layout ships "6 always, 4 contextual."** `player_hud.gd` builds two `GlobeGauge` `_draw` orbs (HP red / Focus blue) at ±220px flanking a bottom-center cluster, a quest plate, toast stack, mute chip, draught chip; `skill_bar.gd` is a 4-slot 72px tray with keybinds, painted-icon-or-inked-glyph fallback, cooldown alpha sweep, and tooltips; `boss_bar.gd` is the "Unyielding"-tagged Hedgemother banner via `make_meter()`.
- **The page windows exist** (`inventory_panel.gd` tabs Gear/Satchel/Charts/Trades with drawn-page scrolling; `craft_panel.gd`, vendor/dialog/waystone/bench panels).
- **Camera + juice ship.** `camera_rig.gd` is the FATE rig (pitch 38°, FOV 35°, zoom 14m, follow-lerp + lead, raycast wall-fade, `shake()`); the seven-layer juice stack (shake/hitstop/flash/number/knockback/spark/death-flourish) lives across `combatant.gd`/`hitstop.gd`/`damage_number.gd`.
- **Audio ships as a no-op-safe pool.** `sfx.gd` autoload (8-voice pool + pitch jitter + one looping music channel) and `tools/generate_audio.py` (ElevenLabs, keyed prompts) cover gather/craft/combat/transition foley + `town_theme` loop. Missing files degrade silently.

## Deep design

### Core mechanics (precise, Wayfinder-flavored)

**Two NEW kit panels (the demo's named UI deliverables, Universe Plan §6):**

1. **The Almanac** — a Stardew-bundle request board in the Chartmaker's Yard. Pages of trade requests; each completed page restores one walkable town corner. It reuses `panel_stylebox()` + `draw_scroll()` (each request a sealed/unsealed scroll: sealed = unmet, broken-seal = filled), and a sage `draw_flourish` divider per page. Opens with `J`-family key; gets a `WYRD_UI_SHOT=almanac` surface.
2. **The "what this run feels like" summary card** — sits on the inscribing bench/waystone. Biome name + one-line procedural rumor header, resolved good/bad twin icons in plain English (SAGE check / TERRACOTTA cross, the exact language `inventory_panel.gd::_draw_charts_tab` already uses), the boss-gimmick implied as one line, and **honest live odds** read off the real `compute_weights`/`effective_stability` — never a hidden number. This is the legibility keystone: it makes a chart *feel like* what it is before you commit ink. `WYRD_UI_SHOT=summary`.

Both are pure strings + existing math + existing kit helpers — no new art, no new tech. Both inherit the §6 checklist: **styleboxes from `WyrdUi`, a `check_ninepatch.py` pass on any new frame, and a capture surface in `capture_ui.sh`.**

**HUD reading-layer additions (combat clarity, P9-scoped):** the demo's one combat reading mechanic is Poise/stance-break. The HUD must make it *legible on every screen* (a co-op correctness requirement, not polish): a **second slim meter under the boss bar** (reuse `make_meter()`, a pale-bramble fill) that fills toward Reeling, plus a brief full-screen "Reeling" flourish (a Tetris-Effect-style heightened-feedback window — slowed time + amplified sting + a SAGE vignette) when the finisher opens. The **HP-bar ghost trail** (feel-pillar 3, currently 5/10) is a cheap `GlobeGauge` addition: a second lagging liquid level in a dimmed tint that catches up over ~0.4s so damage reads as a quantity, not a jump.

**Camera/feel additions (pure feel, no new system):** the planned **death-flourish FOV nudge** (already named in `camera_rig.gd` neighborhood) and a **gather/craft "small satisfaction" pulse** — a soft 1-frame zoom-in + foley on a completed channel or craft, the cozy analogue of a hit. Forgiveness is already the house style ([[Camera and Game Feel]] input buffers, roll i-frames); we extend it to *targeting-camera follow on the Reeling window* so the finisher is never lost off-screen.

**Audio per pillar (the recurring §6 cost):** each pillar ships an **ambient bed** (looped, music channel), a **boss sting** (one-shot, fired on aggro/phase), and **gather/craft/UI foley**. Pale Veins = a stone-drip cave bed + a low Boar tusk-quake sting + vein-reading/ink-refining foley. UI foley extends to the two new panels (a page-turn for the Almanac, a quill-scratch on summary-card resolve).

### Data model & formulas (concrete, GDScript-flavored)

A small `data/ui_config.gd` resolves the open `UI_SCALE` debt ([[UI and HUD]] warns it is still a local `1.5` in three HUD scripts). Centralize it and the capture-surface registry:

```gdscript
const UI_SCALE := 1.5                          # one home, was 3 copies
const SHOT_SURFACES := ["hud","pack","satchel","charts","trades",
    "dialog","vendor","cook","smith","inscribe","almanac","summary"]
```

| Layer | Source of truth | Formula / rule |
|---|---|---|
| Globe fill | `current/max` | `frac = clampf(cur/max(1,mx),0,1)` (live, exact) |
| HP ghost trail | lagging `_ghost_frac` | `_ghost_frac = move_toward(_ghost_frac, frac, GHOST_RATE*delta)`, `GHOST_RATE≈2.2` |
| Poise meter | `boss.poise/poise_max` | fills on hits in recovery/whiff; full → Reeling ~3s |
| Summary odds | `compute_weights` / `effective_stability` | shown verbatim; **no rounding that lies** |
| Ambient bed gain | scene state | `-8 dB` base (matches `sfx.gd` music), duck `-6 dB` under boss sting |
| Reeling window | Tetris-Effect pattern | `Engine.time_scale 0.85` for 0.25s + sting + vignette |

Audio keys extend the `sfx.gd` `PATHS`/`MUSIC_PATHS` dicts and the `generate_audio.py` `SOUNDS` table (key → prompt → duration), inheriting the no-op-if-missing contract so a pillar's audio can land in a later batch without breaking the build.

### Content to author (tiers / worked examples)

| Asset | Tool | Notes |
|---|---|---|
| Almanac frame (if not reusing panel) | Midjourney/Meshy → `check_ninepatch.py` | prefer reusing `panel_frame_v2_9p` — no new frame is cheaper |
| Summary-card chrome | `WyrdUi` `_draw` only | zero new art |
| Pale Veins ambient bed | `generate_audio.py` `pale_veins_bed` | ~22s seamless loop, cave-drip + low hum |
| Boar tusk-quake sting | `generate_audio.py` `boar_sting` | ~1.6s, reuse `charge.mp3` voice register |
| Vein-reading / ink-refine foley | `generate_audio.py` | mirrors `mine`/`craft_smith` cozy-toon voice |
| Almanac page-turn, quill-scratch | `generate_audio.py` | short UI foley |

Worked example (summary card, a Pale Veins chart): header *"A wallow in the Pale Veins, where the stone branches into other things."* · `✓ Rich Seams` (SAGE) · `✗ Cursed Key` (TERRACOTTA) · *"Something heavy waits at the wallow's end."* · *"Stability 72% · Foxglove odds 1-in-5."*

### Edge cases, failure modes, anti-frustration

- **Missing texture** → kit degrades to flat-ink (already handled in `style_panel`/`make_meter`); never a white rect.
- **Missing audio file** → silent no-op (`sfx.gd`); a pillar ships even if its bed is queued for a later ElevenLabs batch.
- **Ornament-over-legibility drift** — the 2026-06-10 ruling holds: ornament on frames/headers only; body rows are clean high-contrast `style_body`. Every new surface must pass the 3-second read test (UI Workflow success metric).
- **Co-op divergence** — Poise/Reeling and boss telegraphs must RPC so every screen reads the same window (Universe Plan §4.6 correctness item); a guest who can't see the wind-up is a bug, not polish.
- **Hidden math** — Balance Philosophy forbids it; the summary card and Poise meter exist precisely to surface odds and stagger.
- **Scale/anchor regressions** — the `skill_bar.gd` comment records a real bug where a scaled `CanvasLayer` pushed the tray off-screen; `ui_config.gd` centralization must not re-introduce it (guarded by `test_skills`).

## Interlocks — how this feeds/uses other systems

- [[Charts Affixes and Inks — Deep Design|Charts/Affixes]] — the summary card renders affix twins + `compute_weights` odds; the rumor header composes from `template + affixes + scope`.
- [[Chart Loop — Deep Design|Chart Loop]] — the waystone/bench surfaces are where a run is read before it is walked.
- [[Combat — Deep Design|Combat]] & [[Enemies and Bosses — Deep Design|Bosses]] — Poise meter, Reeling flourish, boss sting, ghost-trail all visualize the one reading mechanic and its gimmicks.
- [[Gathering — Deep Design|Gathering]] & [[Crafting and Inks — Deep Design|Crafting]] — vein-reading/ink-refine get foley + the small-satisfaction camera pulse; the Almanac requests pull from all four trades.
- [[Progression and Endgame — Deep Design|Progression]] — the Almanac is the visible face of town-growth (P4) and the Codex shell.
- [[Multiplayer Co-op — Deep Design|Co-op]] — telegraph/Poise RPC; party-screen-consistent HUD.
- [[Trades and Leveling — Deep Design|Trades]] — the Trades tab in the pack window.

## Demo scope vs Horizon

**DEMO (built for Pillar Zero/One):** the two new kit panels (Almanac minimal 1–2 pages + summary card); `ui_config.gd` (UI_SCALE + capture-surface registry); Poise/Reeling HUD meter + Reeling flourish; HP-bar ghost trail; death-flourish FOV nudge; gather/craft satisfaction pulse; Pale Veins audio bed + Boar sting + vein/ink/page foley; both panels pass `check_ninepatch.py` + get capture surfaces. All are strings/math/existing-helper work or a single ElevenLabs batch.

**HORIZON (named, NOT built — respect P7 cut-line, P1 spine-priority):** the full Almanac; the Codex/Charter/chart-reader-seat/temper-bench/homestead panels (each inherits the §6 checklist *when/if* a region needs it); a synesthesia-style audio engine that drives the bed off encounter intensity (Tetris-Effect-grade — Horizon, not demo); per-pillar boss themes; festival cues; controller/HUD-scale accessibility settings ("assist mode" framing à la Celeste). No new weapon class or gear tier is ever introduced by this system; no capstone audio/UI escalates past the Hedgemother (P6).

## Implementation notes (Godot)

- **Kit:** all styleboxes stay in `wyrd/scripts/ui/wyrd_ui.gd`. New `data/ui_config.gd` for `UI_SCALE` + `SHOT_SURFACES`.
- **New panels:** `wyrd/scripts/ui/almanac_panel.gd` and `summary_card.gd` (or fold the card into `waystone_panel.gd`/`inscribing_table.gd`). Follow `inventory_panel.gd`'s `_ready` preload-then-`_draw` pattern.
- **HUD:** extend `player_hud.gd` (ghost trail in `GlobeGauge`, Reeling flourish) and `boss_bar.gd` (Poise meter). `skill_bar.gd` untouched except via `ui_config`.
- **Camera/feel:** `camera_rig.gd` (FOV nudge), the juice scripts for the gather/craft pulse.
- **Audio:** extend `sfx.gd` dicts + `tools/generate_audio.py` `SOUNDS`; run the tool per pillar.
- **Capture:** extend `tools/capture_ui.sh` loop with `almanac` and `summary`.
- **Tests:** the four headless suites stay the only hard gate (P10). `test_skills.gd` guards the hotbar/`ui_config` change (it caught the frozen-hotbar regression once). UI fidelity is the side-by-side sign-off + 3-second read test, not an automated gate.

## Open questions

- Does the summary card live inside `waystone_panel.gd`/`inscribing_table.gd`, or as a standalone overlay reused by both? (Reuse argues standalone.)
- Almanac page completion → which town corner animates, and is that wiring owned here or by [[Progression and Endgame — Deep Design|Progression]]?
- Reeling flourish vs. cozy tone — how strong can the time-slow get before it reads "intense" rather than "satisfying"? (playtest-tuned.)
- Is `UI_SCALE` centralization safe to land before Pillar One, or does it ride with the panel work to share one `test_skills` pass?

## See also / Sources

- [[UI and HUD]] · [[Camera and Game Feel]] · [[UI Workflow]] · [[Balance Philosophy]] · [[Universe Build-Out Plan]]
- Code: `wyrd/scripts/ui/wyrd_ui.gd`, `inventory_panel.gd`, `ui/craft_panel.gd`, `player_hud.gd`, `skill_bar.gd`, `boss_bar.gd`, `camera_rig.gd`, `sfx.gd`, `tools/generate_audio.py`, `tools/capture_ui.sh`
- Refs: [[Hades]] (boss legibility, themed feedback) · [[Slay the Spire]] (read-the-run before committing) · [[Tetris Effect Connected]] (heightened-feedback window, audio-reactive horizon) · [[Celeste]] (forgiveness, assist-as-design) · [[Dead Cells]] (make the bank moment weighty)
