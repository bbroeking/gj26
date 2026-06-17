---
title: Audio, SFX & Music — Implementation Plan
parent: "[[system-audio-music]]"
domain: Audio & Animation
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Audio, SFX & Music — Implementation Plan

> Build doc for [[system-audio-music]]. Done when: dungeon ambience loops from entry, all Plan.md B0 feel-beat keys are registered in `sfx.gd`, the audio bus is split into SFX / Music, boss telegraph starts boss_theme and death resumes dungeon ambience, skill_burst differentiates AoE skills, and a headless smoke test guards the SFX autoload — all five gate suites green.

## Definition of done

- Entering a dungeon starts `dungeon_ambience` looping; exiting to town resumes `town_theme`; F10 mutes both; `WYRD_MUTE_MUSIC=1` silences only the Music bus.
- `sfx.gd:PATHS` contains `gather_chip`, `harvest_pop`, `inscribe_chime`, `craft_flare`, `level_burst`, `skill_burst` — graceful no-ops before mp3 files land, playable after generation.
- `data/feel.gd` exists (required by Plan.md B0; see Preconditions).
- Audio bus layout has three buses: Master → SFX → Music; `_music.bus = "Music"`, pool players `bus = "SFX"`.
- Boss fight plays `boss_theme` on telegraph entry and returns to `dungeon_ambience` on death.
- `duck_music(factor, duration)` helper exists on `Sfx` and is called by level-burst and craft-flare hooks.
- `thornburst.gd:36` and `rain_of_thorns.gd:41` use `"skill_burst"` instead of `"skill_snare"`.
- All five headless suites green; a new assertion in `test_wyrd_loop.gd` confirms `Sfx.play("gather_chip")` does not error.

## Preconditions / dependencies

- **`data/feel.gd` does not exist** — Plan.md B0 says to create it before any Part B audio work. This impl plan assumes [[impl-system-combat-juice-vfx]] or a standalone commit creates `data/feel.gd` first, OR task 1 below creates the stub. Creating it here is safe; the two impl plans just must not race.
- [[system-audio-music]] parent note — all strategic rationale lives there; this note is build-only.
- [[impl-system-combat-juice-vfx]] — shares `data/feel.gd` constants; both plans read tunables from the same file. Audio B0 keys must land before B1–B7 VFX phases.
- [[impl-system-trades-progression]] — `level_up` SFX already fires from `game.gd:294`; `level_burst` key (Task 5) feeds Plan.md B3 burst wired there.
- [[impl-system-bosses]] — boss_theme transition (Task 8) wires into `layout_loader.gd:_build_boss` (line 643) and the `boss.died` signal already connected at line 694.
- [[impl-system-gathering]] — `gather_chip` (Task 5) is the per-beat tick SFX for B1; `gather_node.gd:207,244` already calls `Sfx.play("mine"/"chop"/"forage")` — new key plugs into same pattern.
- **`wyrd/audio_bus_layout.tres` does not exist** — Task 6 creates it.
- Plan.md Part A §3 (pitch-jitter, ElevenLabs pipeline) is shipped; this plan reuses it without change.
- ElevenLabs spend must be pre-approved before running generation steps (Tasks 3, 7, 9, 11): ~$0.10 Phase 1, ~$0.60 Phase 2, ~$0.10 Phase 3, ~$0.10 Phase 4.

## Tasks (ordered)

### Phase 1 — Dungeon ambience (unblocks dungeon feel)

1. **Register `dungeon_ambience` in MUSIC_PATHS** — `sfx.gd:43`.  
   Add `"dungeon_ambience": "res://audio/dungeon_ambience.mp3"` to the `MUSIC_PATHS` dict after `town_theme`. Play is a graceful no-op until the mp3 exists.  
   _Verify:_ all five headless suites green (no crash; graceful no-op path hits `ResourceLoader.exists` → false → `_music.stop()`). Suites: `test_wyrd_dungeon_scene`, `test_wyrd_loop`, `test_wyrd_transitions`, `test_skills`, `test_stats` with `WYRD_NO_SAVE=1`.  
   _Effort:_ S.

2. **Call `sfx.music("dungeon_ambience")` from dungeon entry** — `layout_loader.gd:_ready` (line 179).  
   After the existing `stop_music()` block (lines 181–183), add:
   ```gdscript
   if sfx0 != null and sfx0.has_method("music"):
       sfx0.music("dungeon_ambience")
   ```
   _Verify:_ `WYRD_DEV_CHART=crypt godot --path wyrd` — boot into dungeon, listen for ambience loop. `test_wyrd_dungeon_scene` stays green.  
   _Effort:_ S.

3. **Add `dungeon_ambience` prompt to `generate_audio.py:SOUNDS`** — `tools/generate_audio.py:28` (after `town_theme` entry).  
   Add entry:
   ```python
   "dungeon_ambience": ("Low eerie underground stone dungeon ambience, "
                        "distant dripping water, faint wind through corridors, "
                        "cozy storybook tense, seamless loop", 24.0),
   ```
   Then run `python3 tools/generate_audio.py --only dungeon_ambience` to produce `wyrd/audio/dungeon_ambience.mp3` (requires pre-approved ElevenLabs spend ~$0.10).  
   _Verify:_ `wyrd/audio/dungeon_ambience.mp3` exists; boot dungeon, confirm audible loop.  
   _Effort:_ S.

4. **Confirm town_theme resumes on dungeon exit** — `exit_waystone.gd` (find call site).  
   `town.gd:64` already calls `sfx.music("town_theme")`. Verify exit_waystone → town scene transition restores town_theme by listening in a `WYRD_DEV_CHART=crypt` run. No code change needed if town re-_ready fires correctly — add a `# verified B-audio-1` comment as a breadcrumb.  
   _Verify:_ manual playtest: enter dungeon (ambience plays), exit waystone (town_theme resumes). `test_wyrd_transitions` green.  
   _Effort:_ S.

### Phase 2 — B0 feel-beat SFX keys + data/feel.gd stub

5. **Register B0 SFX keys in `sfx.gd:PATHS`** — `sfx.gd:8`.  
   Add after the `roll`/`waystone` entries (line 38):
   ```gdscript
   # Plan.md B0 — feel-beat keys. Graceful no-ops until audio is generated.
   "gather_chip":   "res://audio/gather_chip.mp3",
   "harvest_pop":   "res://audio/harvest_pop.mp3",
   "inscribe_chime":"res://audio/inscribe_chime.mp3",
   "craft_flare":   "res://audio/craft_flare.mp3",
   "level_burst":   "res://audio/level_burst.mp3",
   "skill_burst":   "res://audio/skill_burst.mp3",
   ```
   _Verify:_ `test_wyrd_loop.gd` — add one assertion: `assert(sfx_node != null)` + call `sfx_node.play("gather_chip")` (should not error). All five suites green.  
   _Effort:_ S.

6. **Create `data/feel.gd` B0 stub** — `wyrd/data/feel.gd` (new file; does not exist).  
   Minimal stub with typed constants so Plan.md B0 smoke test resolves; later VFX phases expand it:
   ```gdscript
   # Plan.md B0 — central tunables for Part B feel beats.
   # Each later phase (B1-B7) adds its block here.
   class_name Feel
   
   # Gather
   const GATHER_CHIP_COUNT: int = 6
   const GATHER_SWING_DEPTH: float = 0.18
   const GATHER_SWING_RATE: float = 1.4
   # Harvest
   const HARVEST_MOTE_COUNT: int = 8
   const HARVEST_ARC_TIME: float = 0.45
   # Craft
   const CRAFT_FLARE_INTENSITY: float = 1.0
   # Pickup
   const PICKUP_SUCK_TIME: float = 0.25
   # Level-up
   const LEVEL_PUNCH_SCALE: float = 1.18
   # Town
   const TOWN_GROWIN_DURATION: float = 0.6
   # Performance cap (log if clamped)
   const MAX_BURST_MOTES: int = 8
   const MAX_CHIP_COUNT: int = 6
   ```
   _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` — add assertion `assert(Feel.GATHER_CHIP_COUNT == 6)` to confirm constants resolve. All five suites green.  
   _Effort:_ S.

7. **Add B0 feel-beat prompts to `generate_audio.py:SOUNDS`** — `tools/generate_audio.py:28`.  
   Append after `dungeon_ambience`:
   ```python
   "gather_chip":    ("Short sharp chip of stone or bark flicking away, "
                      "crisp game sound effect", 0.4),
   "harvest_pop":    ("Bright cartoonish pop with a quick ascending tinkle, "
                      "game reward sound", 0.6),
   "inscribe_chime": ("Quill scratching parchment followed by a soft ink-seal "
                      "chime, cozy storybook", 1.2),
   "craft_flare":    ("Brief sizzle and cheerful bell chime, crafting success", 0.5),
   "level_burst":    ("Bright ascending three-note chime burst, warm strings, "
                      "level up", 0.8),
   ```
   Run: `python3 tools/generate_audio.py --only gather_chip,harvest_pop,inscribe_chime,craft_flare,level_burst` (~$0.50 pre-approved).  
   _Verify:_ five mp3 files appear in `wyrd/audio/`; `Sfx.play("gather_chip")` audible in-game.  
   _Effort:_ S.

### Phase 3 — Audio bus split (SFX / Music)

8. **Create `wyrd/audio_bus_layout.tres`** — new file (does not exist).  
   In Godot editor: Audio menu → Audio Bus Layout → add buses "SFX" and "Music", both children of Master. Save to `res://audio_bus_layout.tres`. Then reference in `project.godot`: `audio/buses/default_bus_layout = "res://audio_bus_layout.tres"`.  
   _Verify:_ `AudioServer.get_bus_name(1) == "SFX"` and `AudioServer.get_bus_name(2) == "Music"` — assert in `test_wyrd_loop.gd` headlessly (AudioServer loads in headless mode). All five suites green.  
   _Effort:_ S.

9. **Assign buses in `sfx.gd:_ready`** — `sfx.gd:55`.  
   In the pool-player loop (lines 59–62) add `p.bus = "SFX"` after `add_child(p)`. For `_music`, change line 64 to also set `_music.bus = "Music"`.
   ```gdscript
   for _i in POOL:
       var p := AudioStreamPlayer.new()
       add_child(p)
       p.bus = "SFX"          # <-- add
       _players.append(p)
   _music = AudioStreamPlayer.new()
   _music.volume_db = -8.0
   _music.bus = "Music"       # <-- add
   add_child(_music)
   ```
   _Verify:_ F10 mutes Master (both silent); `WYRD_MUTE_MUSIC=1` silences Music bus only (see Task 10). All five suites green.  
   _Effort:_ S.

10. **Add `set_music_volume`, `set_sfx_volume`, `WYRD_MUTE_MUSIC` env-var hook** — `sfx.gd`.  
    Add after `stop_music()` (line 84):
    ```gdscript
    const MUSIC_BUS := "Music"
    const SFX_BUS := "SFX"
    const MUSIC_VOL_DEFAULT: float = -8.0

    func set_music_volume(db: float) -> void:
        var idx: int = AudioServer.get_bus_index(MUSIC_BUS)
        if idx >= 0:
            AudioServer.set_bus_volume_db(idx, db)

    func set_sfx_volume(db: float) -> void:
        var idx: int = AudioServer.get_bus_index(SFX_BUS)
        if idx >= 0:
            AudioServer.set_bus_volume_db(idx, db)
    ```
    In `_ready`, after bus assignments:
    ```gdscript
    if OS.get_environment("WYRD_MUTE_MUSIC") != "":
        var idx: int = AudioServer.get_bus_index(MUSIC_BUS)
        if idx >= 0:
            AudioServer.set_bus_mute(idx, true)
    ```
    _Verify:_ `WYRD_MUTE_MUSIC=1 WYRD_DEV_CHART=crypt godot --path wyrd` — ambience absent, SFX audible on first hit. All five suites green.  
    _Effort:_ S.

### Phase 4 — Adaptive boss music

11. **Register `boss_theme` in MUSIC_PATHS + generate mp3** — `sfx.gd:43`, `generate_audio.py:SOUNDS`.  
    `sfx.gd`: add `"boss_theme": "res://audio/boss_theme.mp3"` to `MUSIC_PATHS`.  
    `generate_audio.py`: add prompt:
    ```python
    "boss_theme": ("Tense urgent dungeon boss encounter loop, ominous low strings "
                   "and staccato percussion, cozy storybook danger, seamless loop", 25.0),
    ```
    Run: `python3 tools/generate_audio.py --only boss_theme` (~$0.10 pre-approved).  
    _Verify:_ `wyrd/audio/boss_theme.mp3` exists; graceful no-op before that. Suite: `test_wyrd_dungeon_scene`.  
    _Effort:_ S.

12. **Trigger boss_theme on aggro, restore dungeon_ambience on death** — `layout_loader.gd:_build_boss` (lines 693–694).  
    After `boss.aggroed.connect(_raise_gates)` (line 693), add:
    ```gdscript
    boss.aggroed.connect(func():
        var sfx_r := get_node_or_null("/root/Sfx")
        if sfx_r != null and sfx_r.has_method("music"):
            sfx_r.music("boss_theme"))
    boss.died.connect(func():
        var sfx_r := get_node_or_null("/root/Sfx")
        if sfx_r != null and sfx_r.has_method("music"):
            sfx_r.music("dungeon_ambience"))
    ```
    _Verify:_ `WYRD_DEV_BOSS=burrow_boar_den godot --path wyrd` — boss_theme on aggro, dungeon_ambience on death. `test_wyrd_dungeon_scene` green.  
    _Effort:_ S.

13. **Add `duck_music(factor, duration)` to `sfx.gd`** — `sfx.gd` (after `stop_music`, line 84).  
    ```gdscript
    func duck_music(factor: float, duration: float) -> void:
        var target_db: float = MUSIC_VOL_DEFAULT + linear_to_db(factor)
        var tw: Tween = create_tween()
        tw.tween_property(_music, "volume_db", target_db, 0.05)
        if duration > 0.0:
            tw.tween_interval(duration)
            tw.tween_property(_music, "volume_db", MUSIC_VOL_DEFAULT, 0.3)
    ```
    Call from `game.gd:294` level-up path (after existing `sfx_lv.play("level_up")`):
    ```gdscript
    if sfx_lv.has_method("duck_music"):
        sfx_lv.duck_music(0.4, 1.0)
    ```
    _Verify:_ headless frame test — call `duck_music(0.5, 0.0)` and assert `_music.volume_db` changed (requires accessing the autoload node in test); OR manual playtest: level up and confirm music dips then recovers within 1.5 s. All five suites green.  
    _Effort:_ S.

### Phase 5 — Skill SFX differentiation

14. **Add `skill_burst` prompt to `generate_audio.py:SOUNDS`** — `tools/generate_audio.py:28`.  
    ```python
    "skill_burst": ("Short explosive thorn rustle and crack, area-of-effect "
                    "plant magic, game sound effect", 0.6),
    ```
    Run: `python3 tools/generate_audio.py --only skill_burst` (~$0.05 pre-approved).  
    _Verify:_ `wyrd/audio/skill_burst.mp3` exists.  
    _Effort:_ S.

15. **Swap `thornburst.gd` and `rain_of_thorns.gd` to use `skill_burst`** — `scripts/skills/thornburst.gd:36`, `scripts/skills/rain_of_thorns.gd:41`.  
    `thornburst.gd` line 36: `sfx.play("skill_snare")` → `sfx.play("skill_burst")`.  
    `rain_of_thorns.gd` line 41: `sfx.play("skill_snare")` → `sfx.play("skill_burst")`.  
    `bramble_snare.gd:100` remains `"skill_snare"` — no change.  
    _Verify:_ `test_skills` green. Manual: back-to-back bramble_snare vs thornburst must be audibly distinct.  
    _Effort:_ S.

### Phase 6 — Headless smoke test for SFX autoload

16. **Add SFX smoke assertions to `test_wyrd_loop.gd`** — `wyrd/test_wyrd_loop.gd`.  
    After existing test blocks, add:
    ```gdscript
    # Audio smoke — SFX autoload is available in --script mode (see harness notes).
    var sfx_n := get_node_or_null("/root/Sfx")
    _check("Sfx autoload present", sfx_n != null)
    if sfx_n != null:
        sfx_n.play("gather_chip")  # graceful no-op; must not crash
        sfx_n.play("level_burst")  # same
        _check("Feel.GATHER_CHIP_COUNT", Feel.GATHER_CHIP_COUNT == 6)
    ```
    _Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` passes with new assertions. All five suites green.  
    _Effort:_ S.

## First commit (smallest shippable slice)

**Tasks 1 + 2 + 5 + 6 (no audio generated yet):**  
- `sfx.gd`: add `dungeon_ambience` to `MUSIC_PATHS` and all B0 feel-beat keys to `PATHS` (graceful no-ops).  
- `layout_loader.gd:_ready`: call `sfx0.music("dungeon_ambience")` after `stop_music()`.  
- `data/feel.gd`: create with B0 constants stub.  
- `test_wyrd_loop.gd`: add `_check("Sfx autoload present", ...)` + Feel constant assertion.  

**Acceptance:** all five headless suites green; dungeon entry is silent (no mp3 yet) but no crash; `Feel.GATHER_CHIP_COUNT` resolves; Plan.md B0 smoke test passes.

## Test & verification plan

| Task(s) | Suite / playtest | Command |
|---------|-----------------|---------|
| 1, 5, 6 | All five suites | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` (+ other four) |
| 2, 3    | Dungeon entry playtest | `WYRD_DEV_CHART=crypt godot --path wyrd` — listen for ambience |
| 4       | Transition test | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_transitions.gd` + manual exit-waystone listen |
| 8, 9    | Bus-split assertion | Add to `test_wyrd_loop.gd`: `assert(AudioServer.get_bus_name(1) == "SFX")` |
| 10      | Env var test | `WYRD_MUTE_MUSIC=1 WYRD_DEV_CHART=crypt godot --path wyrd` — ambience muted, hit SFX audible |
| 12      | Boss music playtest | `WYRD_DEV_BOSS=burrow_boar_den godot --path wyrd` — boss_theme on aggro, dungeon_ambience on death |
| 13      | duck_music check | Manual level-up: music dips then recovers within ~1.5 s |
| 15      | Skill differentiation | `test_skills` green + manual back-to-back snare/thornburst |
| 16      | Smoke test gate | `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` |

New assertions to author in `test_wyrd_loop.gd`:
- `Sfx.play("gather_chip")` does not error.
- `Feel.GATHER_CHIP_COUNT == 6`.
- `AudioServer.get_bus_name(1) == "SFX"` and `AudioServer.get_bus_name(2) == "Music"` (after Task 8).

## Risks & open questions

- **ElevenLabs budget gating** — Tasks 3, 7, 9, 11, 14 each require spend pre-approval. The graceful-no-op design in `sfx.gd` means keys can ship ahead of generated files, but never run the generator without confirmation. Total est: ~$0.85.
- **`data/feel.gd` collision with [[impl-system-combat-juice-vfx]]** — both plans create/extend `feel.gd`. Coordinate: this plan creates the stub (Task 6); VFX plan adds its constants separately. Do not let them race in the same PR.
- **Dungeon ambience variation** — one loop covers all biomes for demo scope. If a forest/cave biome ships later, `MUSIC_PATHS` needs keys per biome and `layout_loader._ready` must pass the biome ID. Deferred to [[impl-system-biomes-decor]].
- **Per-bus volume persistence** — `save_game.gd:21,82` currently saves only `muted: bool`. If the settings panel exposes SFX/Music sliders (see [[impl-system-hud]]), two new fields (`sfx_volume_db`, `music_volume_db`) must be added. Out of scope here; `set_music_volume` / `set_sfx_volume` are wired for when that lands.
- **`duck_music` tween leak** — `create_tween()` on an autoload node lives past scene changes. The tween target `_music.volume_db` is safe (autoload persists), but confirm in playtest that a scene transition mid-duck doesn't leave volume permanently lowered. If it does, store the tween handle and `kill()` it in `stop_music()`.
- **Headless AudioServer bus naming** — Godot's headless server initialises a default Master bus only. The Task 8 assertion (`AudioServer.get_bus_name(1) == "SFX"`) will fail if `audio_bus_layout.tres` is not picked up headlessly. Test this before committing the assertion; fall back to checking `AudioServer.get_bus_count() >= 3`.
