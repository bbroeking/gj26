---
type: system
tags: [tutorial, onboarding, first-play, ux]
status: draft
updated: 2026-06-13
sources: ["docs/ONBOARDING.md", "docs/wyrd-guide.md", "docs/wyrd-slice.md", "docs/wyrd-implementation-notes.md", "docs/wyrd-roadmap.md"]
---

# Onboarding and Tutorial

The onboarding system is the first-time player flow that walks a new wayfinder through every core verb before releasing them to free play — the single most important UX moment, as retention data in `docs/mmo-game-design-playbook.md` §5 shows launch-month players have 10× the retention of later cohorts.

Two distinct tutorials exist in the project's history: the **three.js OSRS-modeled flow** (designed in `docs/ONBOARDING.md`, targeting a life-sim prototype) and the **Wayfinder Godot tutorial** (implemented in `wyrd/`, tracking `Game.tutorial_step`, driven by Mara Linnet). The Godot tutorial is the live system; the ONBOARDING.md doc captures the design reference and UX rules that still inform it.

---

## The three.js design reference (ONBOARDING.md)

Modeled on OSRS Tutorial Island — one NPC per system, can't progress without completing each step, ~10 minutes end-to-end. `docs/ONBOARDING.md`

### Sequence (designed, not shipped in this engine)

| Stage | NPC | Verb taught |
|---|---|---|
| 0 | Title screen | Begin Adventure / Continue |
| 0.5 | Character creator | Name, hair, skin tone, tunic, cape — live 3D preview |
| 1 | Wizard Aric | Movement, click-to-talk, dialog flow |
| 2 | Farmer Brom | Woodcutting, inventory, XP bar, item drops |
| 3 | Cook Cynthia | Cooking verb, item-to-station, energy refill |
| 4 | Smith Gareth | Equip, click-to-attack, HP bar, damage floaters, kill XP |
| 5 | Cook Cynthia (return) | Fishing, NPC trade |
| 6 | Romance NPC | Gift system, heart progression, NPC schedules |
| 7 | Cottage bed | Day cycle, sleep verb, save-on-sleep |

**State key:** `player.quest.tutorialStage` (integer 0–7), resumable on page refresh.

### UX rules (ONBOARDING.md §3)

- Yellow `!` over the next NPC at all times — new players fixate on the highlight.
- Dialog auto-advances on click; never timed (reading speed varies).
- Hostile actions disabled outside the goblin field — no rage-quits from combat interrupting a text read.
- Each verb taught in isolation before combination.
- Every action gives positive feedback within 200ms (XP floater, sound cue, bar update).
- Tutorial cannot be re-entered after completion; settings toggle can replay tips.

### Character creator spec (ONBOARDING.md §4)

60–90 second modal before Stage 1. Options: name (max 12 chars), hair color (4 swatches), skin tone (4 swatches), tunic color (4 swatches), cape color (4 swatches + none). Live rotating 3D character preview. Data saved to `localStorage['gj26.save']`; subsequent visits skip to `tutorialStage`. Planned integration: `src/ui/charCreator.js`, `src/scene/characters.js` extended `buildKnightMesh(appearance)`.

---

## The Godot / Wayfinder tutorial (live system)

Implemented in `wyrd/scripts/game.gd` via `Game.tutorial_step` (integer). Objective line rendered on the HUD shows live progress (e.g., "2 / 3 herbs"). `docs/wyrd-slice.md §Tutorial beats`

### Tutorial step machine

| Step | Objective displayed | Gate |
|---|---|---|
| 1 | Speak with Mara Linnet | Dialog with Mara completes |
| 2 | Forage 3 hedge herbs | Herb count in satchel reaches 3 |
| 3 | Mix a pot of hedge ink | `hedge_ink` appears in satchel |
| 4 | Inscribe a Snug chart | Snug template inscribed |
| 5 | Socket it at the Waystone and step through | Chart consumed, dungeon scene loads |
| 6 | Find the far waystone | (in dungeon) exit waystone reached |
| 7 | Inscribe a Tier 1 chart — this time with an affix slot | tutorial done |

Step 7 fires on return to town after completing the first run; the first Wayfinding XP (75) lands here. Tutorial ends at step 7 completion.

### Tutorial robustness fixes (adversarial review, 2026-06-09)

`docs/wyrd-implementation-notes.md §Adversarial review round`

- Steps re-check on entry: pre-gathered herbs and pre-inscribed Snug no longer stall the machine.
- Mix step requires `hedge_ink` specifically (not arbitrary ink).
- In-dungeon HUD shows "Find the far waystone" instead of a frozen town objective.
- `Dialog.finished` fires exactly once (`_done` guard) — mashing E on the last page no longer advances tutorial several steps simultaneously.

### Per-verb first-use hint dialogs

The roadmap (`docs/wyrd-roadmap.md`) notes "first-time hint dialogs per verb" as shipped. Specific verbs:
- **Gather nodes** — hint on first channel interaction.
- **Quill's still** — first-use still hint in Quill's voice when the player first uses her alchemy station. `docs/wyrd-roadmap.md §A8`
- **Bench tooltips** — tooltips appear everywhere on the Crafting Bench after spec 42 shipped.

NPC lines follow [[Voice and Tone]] (Bramblewood-world voice, first-person character, warmth over exposition).

### Snug chart — the tutorial dungeon

The tutorial dungeon is inscribed from the **Snug** template: 28-grid, rooms 6–9, `enemy_density` 0.5 (halves default), no boss ever, 0 ink slots. Cost is 1× hedge ink (gathered in step 2, mixed in step 3). This is the only template that charges no inks (0 affix slots means `craft_cost` never subtracts inks — a bug in early code was fixed in the adversarial round). `docs/wyrd-implementation-notes.md §Decisions made during implementation`

### Dev tools

- `WYRD_DEV_CHART=tier_1` — boots straight into a chart run, bypassing tutorial, all gather affixes good (seed 12345).
- `WYRD_SHOT=1` — self-captures `/tmp/wyrd_town.png` for visual verification.
- `WYRD_UI_SHOT=<surface>` — opens a specific UI panel for automated screenshot.

---

## Playtest learnings (docs/PLAYTEST.md)

The combat playtest checklist (`docs/PLAYTEST.md`) is the post-tutorial feel check, not the tutorial itself. It covers 21 dimensions (movement speed, fire cadence, boss telegraphs, camera distance, wall occlusion) rated OK / "too X" / note. Constants exposed for one-pass tuning: `HITSTOP_SEC 0.09`, `FLASH_SEC 0.12`, `KNOCKBACK 0.6`, `AGGRO_RADIUS 7.0`, `DEATH_PAUSE 1.2`, boss HP gates 66%/33%.

Key finding: default zoom of 17 felt like "a map screen, not a character" — tuned to 12 in the Session 3 economy pass. `docs/wyrd-implementation-notes.md §Session 3`

---

## Open items

- Fresh-save manual tutorial run still owed as of 2026-06-12 roadmap.
- Boss-fight feel playtests (Boar charge, Wolf lunge) owed: `WYRD_DEV_CHART=tier_1 WYRD_DEV_BOSS=burrow_boar_den|wolf_alpha_den`.
- "New Game" button (wipes save, re-enters tutorial) not yet implemented — save deleted manually via `rm user://wyrd_save.json`.
- Skippable tutorial for returning players not implemented (mentioned in ONBOARDING.md §5 as post-jam).

---

## See also

- [[Chart Loop]] — the core loop the tutorial teaches
- [[Charts]] — templates, inks, affix slots
- [[Gathering]] — forage/mine/chop verbs taught in tutorial steps 2–3
- [[The Crafting Bench]] — ink mixing and chart inscribing (steps 3–4)
- [[The Waystone]] — chart socketing and dungeon entry (step 5)
- [[NPCs]] — Mara Linnet (tutorial guide), Quill, Hod
- [[Voice and Tone]] — dialog voice rules
- [[Camera and Game Feel]] — camera zoom tuning, playtest feel
- [[UI and HUD]] — quest objective line, HUD elements

## Sources

- `docs/ONBOARDING.md` — full three.js onboarding design, OSRS reference, character creator spec, UX rules
- `docs/PLAYTEST.md` — combat feel checklist, 21-dimension tuning table
- `docs/wyrd-guide.md` — player-facing game guide, controls, tutorial flow overview
- `docs/wyrd-slice.md §Tutorial beats` — tutorial step machine design, town layout
- `docs/wyrd-implementation-notes.md §Adversarial review round` — tutorial robustness fixes
- `docs/wyrd-roadmap.md` — shipped status of hint dialogs, bench tooltips
