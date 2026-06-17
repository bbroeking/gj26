---
title: Audio, SFX & Music
domain: Audio & Animation
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Audio, SFX & Music

> The SFX pool and all 19 mp3 files are on disk and wired at the major call sites; the single gap that blocks the next milestone is dungeon ambience — there is no music key or call site for the dungeon layer, and the feel-beat SFX keys Plan.md B0 adds aren't registered yet.

## Current state

`wyrd/scripts/sfx.gd` is an autoloaded 8-player round-robin pool with ±7% pitch jitter (`sfx.gd:86–93`). All 19 one-shot keys in `PATHS` and the single `MUSIC_PATHS["town_theme"]` have corresponding mp3 files on disk (`wyrd/audio/`). The town theme starts via `town.gd:64` (`sfx.music("town_theme")`); the dungeon entry stops it via `layout_loader.gd:182` (`sfx0.stop_music()`) but starts nothing in its place. Master mute defaults **on** (`game.gd:109` — `var muted := true`) and is toggled via F10 (`player_controller.gd:517`), persisted in save (`save_game.gd:21/82`), and applied through `AudioServer.set_bus_mute(0, muted)` (`game.gd:203, 265`).

All major call sites are wired: gather (`gather_node.gd:207, 244`), craft (`game.gd:409`), boss attacks (`boss.gd:213, 253, 261`), roll (`player_controller.gd:632`), level-up (`game.gd:294`), combat (`hit_feedback.gd:69`, `projectile_skill.gd:60`), and interactables (`chest.gd:65`, `hearth.gd:57`, `shrine.gd:116`, `exit_waystone.gd:57`). There is no second music/ambience bus — the single `_music` `AudioStreamPlayer` (`sfx.gd:51`) carries everything. No per-category volume mixing exists. The Plan.md B0 feel-beat keys (`gather_chip`, etc.) are not yet registered in `PATHS`.

## Gaps — what needs fleshing out

- **[BLOCKER for dungeon feel]** No dungeon ambience key in `MUSIC_PATHS` and no call to `sfx.music()` from dungeon entry — the dungeon is silent throughout (`layout_loader.gd:182` only stops town theme).
- **[B0 dependency]** `sfx.gd:PATHS` is missing the feel-beat keys Plan.md B0 defines (`gather_chip`, `harvest_pop`, `inscribe_chime`, `craft_flare`, `level_burst`) — these are no-ops until registered.
- **No per-channel mixing** — SFX and music share a single Master bus mute; there is no separate SFX bus / Music bus split, so a user cannot lower music without killing SFX.
- **Music crossfade / ducking** — entering combat or a boss room has no adaptive music response; the single music player cuts or plays at a fixed -8 dB (`sfx.gd:64`).
- **Dungeon ambience** has no generated mp3 — `generate_audio.py:SOUNDS` has no "dungeon_ambience" entry and the ElevenLabs prompt hasn't been written.
- **`skill_snare` shared across three skills** — `bramble_snare.gd:100`, `thornburst.gd:36`, and `rain_of_thorns.gd:41` all play `"skill_snare"`, which works but means the audio feedback is identical; a `skill_burst` variant would help differentiation.
- **No headless smoke test for SFX** — there is no test that asserts `Sfx.play("fire")` doesn't crash headlessly; the 5-suite gate exercises many call paths but no test explicitly exercises the SFX autoload mock.

## Plan

### Phase 1 — Dungeon ambience + audio bus split  *(unblocks dungeon feel)*

- Add `"dungeon_ambience"` key to `MUSIC_PATHS` in `sfx.gd:43`.
- Add an ElevenLabs prompt to `generate_audio.py:SOUNDS` for `dungeon_ambience` (approx 20–25 s loop: "low eerie underground stone dungeon ambience, distant dripping water, faint wind through corridors, cozy storybook tense, seamless loop", 24.0).
- Run `python3 tools/generate_audio.py --only dungeon_ambience` to produce `wyrd/audio/dungeon_ambience.mp3`.
- In `layout_loader.gd`, after `stop_music()` add `sfx0.music("dungeon_ambience")` so the dungeon has a looping ambience from the moment the layout loads.
- Add an `AudioBusLayout` resource (`wyrd/audio_bus_layout.tres`) with three buses: Master → SFX → Music. Set `_music.bus = "Music"` (`sfx.gd:64`); set pool players `p.bus = "SFX"` in `_ready` loop (`sfx.gd:59`). Expose `set_music_volume(db)` and `set_sfx_volume(db)` on the `Sfx` autoload.
- **DoD:** entering a dungeon plays looping ambience; town returns to `town_theme`; F10 mutes master (both channels silent); a new `WYRD_MUTE_MUSIC=1` env var silences only the Music bus (useful for dev iteration). All five headless suites stay green.
- **Effort:** S

### Phase 2 — Register B0 feel-beat SFX keys + generate files

This phase is a direct prerequisite for Plan.md phases B1–B5 (do it first, before any Part B work).

- Register in `sfx.gd:PATHS` the keys Plan.md B0 names: `"gather_chip"`, `"harvest_pop"`, `"inscribe_chime"`, `"craft_flare"`, `"level_burst"`. File paths follow the existing pattern (`res://audio/<key>.mp3`).
- Add ElevenLabs prompts to `generate_audio.py:SOUNDS` for each (examples: `gather_chip` → "short sharp chip of stone or bark flicking away, crisp game sound effect, 0.4s"; `harvest_pop` → "bright cartoonish pop with a quick ascending tinkle, game reward sound, 0.6s"; `inscribe_chime` → "quill scratching parchment followed by a soft ink-seal chime, cozy storybook, 1.2s"; `craft_flare` → "brief sizzle and cheerful bell chime, crafting success, 0.5s"; `level_burst` → "bright ascending three-note chime burst, warm strings, level up, 0.8s").
- Run `python3 tools/generate_audio.py --only gather_chip,harvest_pop,inscribe_chime,craft_flare,level_burst`.
- **DoD:** `Sfx.play("gather_chip")` is a graceful no-op before file generation and plays correctly after; all keys appear in `sfx.gd:PATHS`; Plan.md B0 smoke test (`data/feel.gd` + SFX stubs resolve headlessly) passes. Gate green.
- **Effort:** S

### Phase 3 — Adaptive music (boss room ducking + combat swell)

This phase layers on top of Phase 1's bus split.

- Add a `"boss_theme"` key to `MUSIC_PATHS`. Add a corresponding ElevenLabs prompt (approx 25 s tense loop) to `generate_audio.py`.
- In `boss.gd`, on telegraph phase entry call `Sfx.music("boss_theme")`; on boss death call `Sfx.music("dungeon_ambience")`.
- Add a `duck_music(factor: float, duration: float)` helper on the `Sfx` autoload that tweens `_music.volume_db` down temporarily (for craft-flare / level-burst moments), then back to the baseline `MUSIC_VOL` constant. Call it from the Plan.md B3 level-up burst and B5 craft reaction hooks.
- **DoD:** a boss encounter transitions town\_theme → boss\_theme → dungeon\_ambience cleanly; music ducks on level-up burst and returns within 1.5 s. Verified by a `WYRD_DEV_BOSS=` run + listening playtest. Headless suites stay green (the duck tween is pure code — can be unit-tested by checking `_music.volume_db` after `duck_music(0.5, 0.0)`).
- **Effort:** M

### Phase 4 — Skill SFX differentiation + per-verb audit

- Introduce `"skill_burst"` key (for `thornburst.gd` and `rain_of_thorns.gd` — area AoE feel differs from the line-snare) and generate a distinct sound (short explosive rustle + thorn crack).
- Update `thornburst.gd:36` and `rain_of_thorns.gd:41` to use `"skill_burst"` instead of `"skill_snare"`.
- Walk every `Sfx.play()` call site (there are ~20 — see list in Current state) and verify pitch variance is appropriate: gather calls already pass `0.12` (`gather_node.gd:244`), others use the default `0.07`. Tighten or expand where repetition fatigue would be highest (gather = wider variance; boss charge = tighter, intentionally mechanical).
- **DoD:** `skill_snare` and `skill_burst` are audibly distinct in back-to-back playtest; `skill_snare` still plays for `bramble_snare.gd`. No regression in combat SFX. Gate green.
- **Effort:** S

## Dependencies & links

- [[system-gathering]] — gather SFX (`mine`, `chop`, `forage`, `gather_chip`) fire from `gather_node.gd`; Phase 2 keys are required before Plan.md B1 arm-articulation lands.
- [[system-crafting]] — `craft_cook` / `craft_smith` are already wired; `craft_flare` (Phase 2) feeds the Plan.md B5 station reaction.
- [[system-bosses]] — Phase 3 boss theme transitions wire into `boss.gd` telegraph/death; `telegraph`, `charge`, `lunge` already playing.
- [[system-combat-juice-vfx]] — audio and vfx share the feel-timing constants being built in Plan.md B0; both systems read from `data/feel.gd`.
- [[system-skills-hotbar]] — skill SFX keys (`fire`, `skill_power`, `skill_multi`, `skill_snare`) are data-driven via `projectile_skill.gd:sfx_key`; Phase 4 differentiates AoE skills.
- [[system-trades-progression]] — `level_up` SFX fires from `game.gd:294`; `level_burst` (Phase 2) feeds Plan.md B3 visual burst.
- [[system-town-hub]] — town theme already starts in `town.gd:64`; Phase 1 ensures it resumes correctly after a dungeon run.
- [[system-hud]] — mute indicator built in `player_hud.gd:75–100`; Phase 1 per-bus split would let the HUD expose separate SFX/Music sliders in a future settings panel.
- [[system-save-load]] — `muted` is persisted (`save_game.gd:21/82`); per-bus volumes will need the same treatment in Phase 1.
- [[system-animation]] — feel-beat SFX timing couples with procedural arm modifiers (Plan.md B1); the two ship together.

**Plan.md cross-references:**
- Plan.md Part A §3 (audio pipeline — pitch-jitter, ElevenLabs) is **shipped**; this note reuses that pattern without duplicating it.
- Plan.md Phase B0 (`feel.gd` tunables + SFX stubs) maps directly to Phase 2 of this note — do them in the same PR.
- Plan.md B1 (gather arm-articulation), B2 (harvest pop), B3 (level-up burst), B4 (pickup), B5 (craft reaction), B6 (inscribe chime), B7 (town ambience) all require the Phase 2 keys to be registered first.

## Verification

- **Phase 1:** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` must stay green; manually boot with `WYRD_DEV_CHART=crypt` and listen for dungeon ambience loop; exit waystone and confirm town\_theme resumes. Check `WYRD_MUTE_MUSIC=1` silences music only.
- **Phase 2:** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` and all four suites green. Add a one-line assertion to `test_wyrd_loop.gd` that `Sfx.play("gather_chip")` does not error (autoload is available in `--script` mode per harness notes).
- **Phase 3:** Boot with `WYRD_DEV_BOSS=boar` (or equivalent), fight boss — confirm boss\_theme plays on telegraph and dungeon\_ambience resumes on death. `duck_music(0.5, 0.0)` can be called from a headless frame and `_music.volume_db` asserted.
- **Phase 4:** Back-to-back `bramble_snare` vs `thornburst` casts must sound distinct; verified by ear in a standard dungeon run. No headless test needed.
- All runs use `WYRD_NO_SAVE=1` and execute from `wyrd/` as `godot --headless --path .`.

## Open questions

- **ElevenLabs budget:** Phase 1 adds ~1 sound (~$0.10), Phase 2 adds 5 (~$0.50), Phase 3 adds 1 (~$0.10). Confirm spend is pre-approved before running `generate_audio.py` for those phases.
- **Per-bus volume persistence:** should SFX / Music volumes be saved separately in the save file, or is a single `muted` bool sufficient for the demo scope? (If saved separately, `save_game.gd` needs two new fields.)
- **Dungeon ambience variation:** one looping track for all biomes, or one per biome (crypt vs future forest/cave)? One track is feasible for demo; per-biome needs `MUSIC_PATHS` keyed by biome ID and `layout_loader.gd` passing the biome to `sfx.music()`.
