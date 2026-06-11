# GODOT_PIPELINE.md — secondary engine for evaluation

Spec 07 lands a Godot 4.6.2 project at `godot/` next to the three.js game. The two engines share the same `models/` directory and the same crypt concept-art textures via symlinks. **The three.js game is the live one** — Godot is for hands-on engine comparison.

## Install (one-time)

```bash
# Godot 4.6.2 — Apple Silicon Metal build
brew install --cask godot

# Verify
godot --version
# 4.6.2.stable.official.71f334935  (or newer)

# Node 18+ (already had v24 in this repo)
node --version

# Godot MCP server — runs via npx, no global install needed
npx -y @coding-solo/godot-mcp --help   # exits with "Godot MCP server running on stdio"
```

Claude Code MCP config: project-scoped `.mcp.json` (already committed) — restart Claude Code to pick it up. `mcp__godot__*` tools become available next session.

## Project layout

```
godot/
├── project.godot         # Godot 4.6 config, Forward+ renderer
├── icon.svg              # placeholder app icon
├── models -> ../models                                     (symlink)
├── textures/crypt -> ../../docs/concept-art/dungeons/crypt (symlink)
├── data/
│   └── crypt_floor1.json # static layout snapshot from the JS game
├── scenes/
│   ├── World.tscn        # root scene with WorldEnvironment, Sun, Player, layout_loader
│   ├── Player.tscn       # CharacterBody3D + capsule + SpringArm3D camera
│   └── Enemy.tscn        # thin Node3D stub — future home for per-enemy logic
└── scripts/
    └── layout_loader.gd  # reads JSON, places floors/walls/decor/enemies/boss
```

## Workflow

### Adding a new asset (dual-engine)

The Meshy AI flow does **not change**. Everything that lands a GLB in `models/` is automatically visible to both engines:

1. Generate concept art (Midjourney) → run through Meshy AI Image-to-3D.
2. Run `scripts/clean_ai_mesh.py` → output lands at `models/<name>_v1.glb`.
3. **three.js**: register a loader + factory in `src/scene/characters.js` and a spawn fn in `src/game/enemies.js` (existing pattern).
4. **Godot**: first time the editor opens with the new GLB present, it auto-imports and creates `models/<name>_v1.glb.import`. Commit that sidecar. Reference the model via `res://models/<name>_v1.glb` (the symlinked `models/` directory inside `godot/`).

That's it — no duplicate copies of GLBs anywhere.

### Refreshing the layout snapshot

When the JS dungeon code changes and you want the Godot scene to reflect a new layout, dump a fresh JSON from a running browser session:

```js
// In the running game's JS console (with crypt arc active or after __descendCryptFloor):
(() => {
  const L = window.__dungeon.layout;
  const out = {
    grid: L.grid, entry: L.entry, exit: L.exit, chestTile: L.chestTile,
    rooms: (L.rooms || []).map(r => ({ x: r.x, y: r.y, w: r.w, h: r.h, tag: r.tag || null })),
    decor: (L.decor || []).map(d => ({ kind: d.kind, x: d.x, y: d.y })),
    bossRoom: L.bossRoom ? { x: L.bossRoom.x, y: L.bossRoom.y, w: L.bossRoom.w, h: L.bossRoom.h } : null,
    bossKind: L.bossKind, scope: L.scope, cryptFinalFloor: L.cryptFinalFloor,
  };
  copy(JSON.stringify(out));   // copies to clipboard
  console.log('Layout copied. Paste into godot/data/crypt_floor1.json.');
})();
```

Then paste into `godot/data/crypt_floor1.json` and reopen the World scene.

### Controls

- **WASD / arrow keys** — move the player (camera-relative: W is always
  "away from the camera").
- **Right-mouse-drag** — orbit the camera (yaw + pitch).
- **Q / E** — orbit yaw without a mouse.
- **Scroll wheel** — zoom.

The camera is a smooth-follow third-person rig (`scenes/CameraRig.tscn` +
`scripts/camera_rig.gd`) — a standalone node that eases toward the player,
clamps pitch, and springs in when a wall is between it and the player.
The player is a `CharacterBody3D` driven by `scripts/player_controller.gd`.

### Collision model (spec 10)

- **Floor** — one thin `BoxShape3D` per `floor` tile (top at y=0). Step off
  the floor and there's nothing under you.
- **Kill-plane** — an `Area3D` at y=-6; falling into it respawns the player
  at the entry tile.
- **Walls** — `StaticBody3D` + box, tight to the mesh.
- **Boss / enemies** — each GLB is wrapped in a `StaticBody3D` + capsule so
  the player is physically blocked by them.
- **Decor** — `bookshelf` and `bones` are solid (box collider); `torch_wall`
  is pass-through (wall-mounted).
- **Layers** — `world` (1), `player` (2), `enemies` (3), named in
  `project.godot`. Player collides with world + enemies; the camera spring
  collides with world only.

### Animation (spec 11 — Meshy rig + idle)

The crypt cast animates via skeletal clips, not procedural rotation (that's
the three.js side). The flow:

1. **Regenerate the character in Meshy with `pose_mode="t-pose"`**
   (`meshy_image_to_3d` from concept art, or `meshy_text_to_3d`). Meshy
   auto-rig CANNOT pose-estimate the `clean_ai_mesh.py` low-poly GLBs — the
   source model must be a Meshy-native t-pose generation.
2. **Remesh if over 300K faces** (`meshy_remesh`, target ~50K) — Meshy 6
   generates dense meshes; the rig API caps at 300K.
3. **`meshy_rig`** the model (`input_task_id`). Rigging is humanoid-only —
   quadrupeds (the rat) fail pose estimation and stay static.
4. **`meshy_animate`** with `action_id: 0` (basic Idle).
5. Download the `Animation_Idle_withSkin.glb` → `models/<name>_rigged.glb`.

`layout_loader.gd` prefers `<name>_rigged.glb` when it exists and falls back
to the static `_v1` GLB otherwise. `anim_driver.gd` finds the
`AnimationPlayer`, matches the idle clip by case-insensitive substring, sets
it looping, and plays it. The static `_v1` GLBs are untouched — the three.js
game still uses those.

Probe a rigged GLB's clips: `godot --headless --path godot --script
res://test_anim.gd`.

### Combat (spec 14)

The Ranger fires arrows (key **F**, input-buffered). Arrows carry a hitbox
Area3D; enemies are `Combatant` bodies (`combatant.gd`) with HP + a hurtbox
Area3D. A hit does damage once, then: **hitstop** (global freeze, the
`Hitstop` autoload), an enemy **flash**, a floating **damage number**,
**knockback**, and a hit-react stagger. 0 HP → a death tween + despawn.

It's a real fight (spec 15): enemies wake within aggro range, chase, and
melee-attack on a telegraph; the player has HP, takes damage with a screen
flash + hitstop + knockback + i-frames, and on 0 HP respawns at the entry.
A `PlayerHUD` (CanvasLayer) shows the HP bar.

"Fluid" is measured, not eyeballed — the headless eval harness:

```bash
godot --headless --path godot --script res://test_combat.gd
# E2 hit registers · E3 no dup · E4 hitstop · E5 knockback · E6 damage
# number · E7 death · E8 arrow cleanup · E9 framerate under a volley
# F1 aggro · F2 chase · F3 enemy hit · F4 i-frames · F5 death · F6 respawn
# F7 pathfinding routes around a wall
# G1/G2 boss phases · G3 boss death · G4 telegraphed attack hits
```

Baseline (spec 17): 20/20 PASS.

The Hedgemother (spec 17) is a real boss — `boss.gd` extends `combatant.gd`
with a 3-phase HP-gated machine, two telegraphed AoE attacks (thorn-sweep,
root-stomp), a sealed arena (perimeter gates raised on aggro), and a boss
HP banner (`BossBar`).

The Ranger walks via a **procedural** cycle (spec 18) — `ranger_anim.gd`
poses the leg/arm bones each frame (the baked GLB clips are broken). Its
AnimationPlayer stays stopped. The rat hop-bobs procedurally too
(`rat_anim.gd`, spec 21 — Meshy can't rig a quadruped).

Rigged enemies render their real 2048² GLB textures (spec 20 — the old
`_tint` was masking them); only the untextured Ranger + rat keep a tint.
`layout_loader._unmetal()` zeroes the Meshy materials' metallic so the web
Compatibility renderer doesn't render them chrome.

Web export: `godot --headless --path godot --export-release "Web"
build/web/index.html`. The `export_presets.cfg` `include_filter` must list
every `preload()`-only script/scene — the "scenes" filter doesn't follow
preload chains.

Movement (spec 23): the player has a walk/run/dash/roll state machine.
Keys — WASD move · **Shift** walk (else run) · **Space** dash · **Ctrl**
roll · **F** fire. `Sandbox.tscn` is a dungeon-free arena for tuning the
feel: `godot --path godot res://scenes/Sandbox.tscn`. Evals:
`godot --headless --path godot --script res://test_movement.gd` (6/6).

Dungeon (spec 24): 34×34 grid, 3-tile-wide corridors, rooms 6–12, walls
2.5 m built from the modular crypt wall GLBs — `layout_loader._wall_variant()`
picks straight/inner/outer-corner pieces from the open-floor neighbours
(ported from the three.js `cryptWallVariant`). Camera angle stays 55°.

Interesting dungeons (spec 25): rooms get a **role** + **theme**; decor is
placed by rule per theme (`ROOM_THEMES` in `dungeon_gen.gd`), not scattered.
Varied room shapes (rect/circle/irregular). Authored **setpieces** are 7×7
ASCII templates in `godot/data/rooms/*.txt` stamped into the largest room.
Looped layout + dead-end treasure rooms. Enemy density scales with BFS depth
(calm entrance → dense boss run-up).

Enemies pathfind (spec 19): `layout_loader` builds a `NavigationRegion3D`
from the crypt floor tiles; `combatant.gd` chase follows a
`NavigationAgent3D` path (straight-line fallback if off-mesh) — they route
around walls instead of jamming on corners.

### Running the project

```bash
# Headless lint (catches import + GDScript errors without opening the editor):
godot --headless --path godot --import

# Boot the World scene headlessly for N frames (smoke test):
godot --headless --path godot --quit-after 60 res://scenes/World.tscn
# Look for: [layout_loader] crypt floor built — N decor, N enemies, boss=hedgemother

# Open the editor:
godot --editor --path godot
# Or just: open godot/project.godot
```

## What Godot covers — and what it doesn't (yet)

**Covers** (spec 07):
- Floor + wall tile placement from the JSON grid
- Decor GLBs (bones, torch_wall, bookshelf)
- Boss GLB at boss-room center
- 3 enemy GLBs at hand-picked tiles (skeleton, rat, ghost)
- Player capsule + third-person SpringArm camera at entry tile

**Does not cover yet** (deliberate non-goals for v1):
- Game logic: combat, skills, inventory, quests, NPCs, dialog, charts, save/load
- Per-frame procedural animation (the `src/anim/*.js` pipeline)
- Boss phase machine / HP bar / room seal
- Multi-floor descent
- Procgen in GDScript (use a JSON snapshot from JS instead)
- Player input
- Hedgemother / enemy animations (T-pose)
- Web export

## Procedural generation

`godot/scripts/dungeon_gen.gd` is a self-contained seeded rooms-and-corridors
generator in pure GDScript. `layout_loader.gd` has a `USE_PROCGEN` toggle:

- `USE_PROCGEN = true` (default) — fresh random dungeon every run.
- `USE_PROCGEN = false` — loads the static `data/crypt_floor1.json` snapshot.

### Connection pipeline (spec 08 — the "TinyKeep" method)

Rooms are *not* connected in placement order (that crisscrosses corridors).
Instead:

1. Place non-overlapping rooms.
2. **Delaunay triangulation** of room centers (`Geometry2D.triangulate_delaunay`)
   — edges are spatially local by construction, no long crossings.
3. **Minimum Spanning Tree** (Kruskal + union-find) — cheapest edge set that
   connects every room, guaranteed reachable, no cycles.
4. Re-add **`LOOP_EDGE_FRACTION`** (~15%) of the non-MST Delaunay edges — gives
   loops / alternate routes so the dungeon isn't a forced line.
5. Carve L-corridors only along the final edge set.

Boss room = farthest room from entry by **BFS hop count** on that graph.

### Procgen quality — scoring + generate-and-test

`dungeon_score.gd` scores every layout. `dungeon_gen.gd` generates up to
`MAX_ATTEMPTS` candidates and returns the first to clear `SCORE_THRESHOLD`
(or the best one — it never hard-fails).

| Metric | Meaning | Target |
|---|---|---|
| `connectivity` | BFS flood-fill: fraction of floor reachable from entry | **hard gate** — must be 1.0 |
| `critical_path` | BFS hops entry-room → boss-room ÷ room count | ≥ `CRITICAL_PATH_TARGET_FRAC` (0.5) |
| `room_count` | number of rooms | `[ROOM_COUNT_MIN, ROOM_COUNT_MAX]` = `[5, 12]` |
| `floor_ratio` | floor tiles ÷ grid area | `[FLOOR_RATIO_MIN, MAX]` = `[0.18, 0.45]` |
| `corridor_ratio` | corridor tiles ÷ room tiles | ≤ `CORRIDOR_RATIO_MAX` (0.6) |
| `dead_ends` | room-graph degree-1 nodes | `[1, ceil(rooms × DEAD_END_MAX_FRAC)]` |

`total` = average of the 5 soft metrics; if `connectivity < 1.0` the total
collapses (a broken layout can never look good).

**Tuning**: every knob is in one `const` block at the top of
`dungeon_gen.gd` — room sizes, `LOOP_EDGE_FRACTION`, `SCORE_THRESHOLD`,
`MAX_ATTEMPTS`, and all six metric bands. Change a number, re-run.

**Verifying a tuning change** — the headless 10-run harness:

```bash
godot --headless --path godot --script res://test_procgen.gd
# prints per-run metric breakdowns + avg total + all-connected check
```

Current baseline (spec 08): 10/10 connected, avg total ≈ 0.97.

## Web export

Godot exports to HTML5/WebAssembly and the build runs in any modern browser.

### One-time: install export templates

```bash
# Download the templates matching your Godot version (~1.2 GB):
curl -L -o /tmp/godot_templates.tpz \
  https://github.com/godotengine/godot/releases/download/4.6.2-stable/Godot_v4.6.2-stable_export_templates.tpz
cd /tmp && unzip -o godot_templates.tpz
mkdir -p ~/Library/Application\ Support/Godot/export_templates/4.6.2.stable
cp /tmp/templates/* ~/Library/Application\ Support/Godot/export_templates/4.6.2.stable/
```

### Build

```bash
godot --headless --path godot --export-release "Web" build/web/index.html
```

Output lands in `godot/build/web/` (gitignored). Serve it with any static
server — the preset uses `thread_support=false` so no COOP/COEP headers are
needed:

```bash
cd godot/build/web && python3 -m http.server 8099
# open http://127.0.0.1:8099/index.html
```

### Web export size — read this before shipping

The preset (`godot/export_presets.cfg`) uses `export_filter="scenes"` +
`export_files` + an `include_filter` whitelist of exactly the GLBs the scene
uses. **This matters:** the symlinked `models/` directory has 189 GLBs; a
naive `all_resources` export packs all of them and the build balloons to
**~617 MB**. The curated build is ~37.5 MB:

| Part | Size | Note |
|---|---|---|
| `index.wasm` | 36 MB | Godot runtime — **fixed, irreducible** |
| `index.pck` | 1.1 MB | our assets (8 whitelisted GLBs + scenes) |
| `index.js` | 0.3 MB | loader glue |

When you add a GLB the scene uses, add its path to `include_filter` in
`export_presets.cfg` or it won't be in the web build. Also: `godot/build/`
has a `.gdignore` so Godot doesn't scan its own export output.

The 36 MB WASM floor is the main cost of Godot-for-web vs. three.js
(~600 KB engine). Fine for a downloadable-feeling game; a real consideration
for a "click the link, instant play" cozy game.

## Typed-room contracts (spec 29)

Every dungeon is guaranteed to contain one of each non-combat role: an entrance
antechamber, a boss arena, a **rest** room with an interactable Hearth (heal +
checkpoint), a **treasure** room with an interactable Chest (rolls 2 items
via `Drops.roll_drop("treasure", depth)`), and a **shrine** room with an
interactable Shrine (3-buff choice modal seeded from `(dungeon_seed XOR
room_id)` so the same dungeon offers the same buffs at a given shrine).

Detection follows the spec 27b ItemPickup pattern: each interactable sits on
`INTERACT_LAYER (32)`; the player's `InteractScanner` Area3D (radius 1.5m)
detects them and the nearest live one shows a floating `[E] Open` / `[E] Pray`
/ `[E] Rest` prompt. E triggers `interact(self)`.

Shrine buffs sum into `player.shrine_buffs` and stack additively on top of
equipment via the spec 27e `_derive_stats` pipeline. The Hearth writes a
single-slot in-memory `Checkpoint` autoload; death respawns the player at the
checkpoint (or the dungeon entry if no hearth was visited).

Files: `scripts/chest.gd`, `scripts/shrine.gd`, `scripts/shrine_choice_modal.gd`,
`scripts/hearth.gd`, `scripts/checkpoint.gd`, `scenes/{Chest,Shrine,
ShrineChoiceModal,Hearth}.tscn`. Eval harness: `test_typed_rooms.gd` (5/5).
Full design in [`docs/specs/29-typed-room-contracts.md`](specs/29-typed-room-contracts.md).

## Skill system (spec 30)

4-skill hotbar on keys 1–4 (replaces the spec 26 variant cycling on the same
keys; BasicShot also stays on F). Slot 1 is the existing free + cooldown
BasicShot; slots 2–4 cost **Focus** (single regenerating pool, 50 cap,
10/sec out of combat / 3/sec in combat) and have per-skill cooldowns.

| Slot | Skill | Cost | Base CD | Effect |
|---|---|---|---|---|
| 1 | BasicShot | 0 | 0.28s (scales with `fire_rate`) | Existing gold arrow |
| 2 | PowerShot | 20 | 1.5s | 2.5× damage, visually larger projectile |
| 3 | MultiShot | 25 | 2.0s | 3 arrows in a ±20° cone |
| 4 | Bramble Snare | 30 | 4.0s | 2.5m AoE root for 2s, no DoT |

Skills 2–4 scale their cooldowns with the new **`cooldown_reduction`** affix
(suffix `of_swiftness`, capped at 0.80 — D3 model). The `damage` affix scales
all skills. No Focus-related affixes in v1.

UI: Focus bar under the HP bar (golden-amber fill); skill bar bottom-center,
4 slots showing keybind + name + cost + a cooldown-overlay sweep + grey-out
when unusable. Both built in script over minimal scenes (`PlayerHUD.tscn`,
`SkillBar.tscn`).

Bramble Snare's "rooted" status is a one-off on `Combatant` — `apply_root(d)`
sets `_root_t`, the AI short-circuits velocity to zero while > 0; knockback
still applies. A proper status framework (burn/freeze/poison/bleed + DoT ticks)
lands in spec 31. Files: `scripts/player_controller.gd`, `scripts/arrow.gd`,
`scripts/combatant.gd`, `scripts/skill_bar.gd`, `data/affixes.gd`. Eval
harness: `test_skills.gd` (6/6). Full design in
[`docs/specs/30-skills-and-cooldowns.md`](specs/30-skills-and-cooldowns.md);
genre research in [`30-skills-and-cooldowns-research.md`](specs/30-skills-and-cooldowns-research.md).

## Status framework + AoE helpers (spec 31)

Generalises spec 30's one-off Bramble Snare root into a unified status
system. **`StatusEffect`** (RefCounted) holds kind / time_left / tick_interval /
damage_per_tick / slow_factor + owned visual node; **`Combatant._statuses`**
dict keyed by kind, ticked in `_physics_process` at fixed intervals (never
`delta`-scaled, per the genre research's cardinal DoT rule).

Ships 4 statuses:

| Status | Trigger | Duration | Tick / Effect |
|---|---|---|---|
| **Root** | Bramble Snare (existing) | 2.0s | Immobilise; no DoT |
| **Burn** | PowerShot hit | 3.0s | 1 dmg / 0.5s (6 ticks total ~40% of PowerShot) |
| **Bleed** | Any crit hit | 4.0s | ~6.25% of crit dmg / 1.0s (4 ticks total ~25%) |
| **Snared** | MultiShot hit | 1.5s | 50% movement slow; no DoT |

Stacking is **highest-wins, refresh duration** (D3 model) for all four.
Slow factors multiply, capped at 0.25× minimum.

**Boss immunity table** on `boss.gd`: Hedgemother is fully immune to lock-down
statuses (root, snared) and takes damaging statuses (burn, bleed) at **50%
reduced duration**. " — Unyielding" appended to the boss-bar name signals
this visibly without a hidden DR meter.

**AoE query helpers** (`scripts/aoe_query.gd`, static): `query_circle` (used
by Snare today), `query_cone` + `query_nova` (sketched for future skills).
**No spatial damage falloff** — full inside, zero outside (all 3 reference
games agree).

Visuals: per-status particle (GPUParticles3D) above head, capped at 2
concurrent per enemy; emerald disc at feet for root (existing); apply-text
floater ("singed!" / "snared!" / "bleeding!" / "rooted!") once on apply,
not per tick.

Files: `scripts/status_effect.gd`, `scripts/aoe_query.gd`, modifications to
`combatant.gd` (the `_root_t` migration), `boss.gd` (immunity override),
`arrow.gd` (skill-type→status dispatch), `player_controller.gd` (Snare
refactored onto query_circle), `damage_number.gd` (`setup_apply` variant),
`boss_bar.gd` (Unyielding suffix). Eval harness: `test_statuses.gd` (7/7).
Full design in [`docs/specs/31-status-and-aoe.md`](specs/31-status-and-aoe.md);
genre research in [`31-status-and-aoe-research.md`](specs/31-status-and-aoe-research.md).

## Loot pipe (spec 32a)

The full ground-loot flow lives behind one deep `ItemPickup` module:
`ItemPickup.spawn(host, item, position)` owns instantiate + setup + visuals;
`ItemPickup.try_take(player)` owns the full take transaction (find_first_fit
+ try_place + Sfx + log + VFX). Callers (`combatant._spawn_one_pickup`,
`chest.interact`, `player._try_grab`) collapsed to 1–8 lines each. Pure
refactor with no gameplay change. The first deepening from the spec-32
pre-arc; see `docs/specs/32a-pickup-deepening.md`.

## Skill module (spec 32b)

The 4-skill hotbar lives behind `scripts/skills/skill.gd` (RefCounted base)
and a `ProjectileSkill` subclass with a data-driven default `fire(player)`.
Concrete skills (`BasicShot`, `PowerShot`, `MultiShot`) just set data fields;
`BrambleSnare` extends `Skill` directly with its own AoE fire(). On-hit
consequences are `SkillEffect` data carried by the spawned arrow (read at
impact, no more `skill_type` string-match). Player holds the loadout as
`var skills: Array` instantiated in `_ready()`. See
`docs/specs/32b-skill-module.md`.

## Hit feedback (spec 32c)

The 6 channels of impact feedback (flash, knockback, hitstop, hit-spark,
camera shake, SFX) flow through one `HitFeedback` static module
(`scripts/hit_feedback.gd`). Two entry points: `play_hit(target, tier,
from_dir)` for arrow impacts and `tick_pulse(target, status_kind)` for
status DoT ticks (closes the spec 31 deferred mesh-tint-pulse followup).
Tier-keyed tunables live as const dicts on the module — single source of
truth. Combatant exposes `apply_flash(duration, color)` and
`apply_knockback(dir, strength)` as the seam HitFeedback uses. See
`docs/specs/32c-hit-feedback.md`.

## Interactable base (spec 32d)

`scripts/interactable.gd` (`class_name Interactable extends Area3D`) is the
named seam for "anything press-E-able." Owns the common setup (INTERACT_LAYER
+ "interactable" group + CollisionShape3D + PromptLabel3D) so Chest /
Shrine / Hearth shrink to ~30–75 lines each. Subclasses override five
virtual hooks: `interact(player)`, `is_used()`, `get_prompt_text()`,
`get_prompt_color()`, `_ready_interactable()`. The press-E contract is
now documented in code, not by example. See
`docs/specs/32d-interactable-base.md`.

## Pack scaling + elites (spec 32)

Combat rooms now hold 4–10 trash (formula `4 + clampi(depth/2, 0, 6)`).
Roughly 1 in every 8 spawns gets promoted to an Elite via the
`Combatant.apply_elite(modifier)` method — bumps HP/scale, applies a
persistent golden material tint (survives hit flashes via the spec 32c
`_saved` restoration path), spawns a GPUParticles3D feet-ring, and wires
in modifier-specific behaviour from `data/elites.gd`. Elites travel with
2–3 same-kind trash as retinue. Boss room stays elite-free.

Four modifiers ship in v1: **Brambled** (death-nova Bleed), **Swift**
(+50% move, +20% atk speed), **Sunlit** (+3 melee damage to the player
on hit as the v1 burn-stand-in), **Briarbound** (4s CC-immune after the
first root/snared). New `"elite"` role in `data/drops.gd` (chance 1.0,
tier_bias 1). See `docs/specs/32-pack-scaling.md`.

## Player status system (spec 33a)

The player can be Burn / Bleed / Snared / Root'd via the same `apply_status`
interface enemies use (spec 31). `player_controller.gd` carries its own
`_statuses: Dictionary` + `_tick_statuses` ported from Combatant; movement
speed multiplies by the slow product (capped at 0.25×); root immobilizes
entirely. HP bar gains a text suffix (`"HP 25/30 — burning · snared"`).
Sunlit elite (spec 32) now applies real Burn DoT instead of the +3
immediate stand-in. See `docs/specs/33a-player-status.md`.

## Decision: which engine wins?

Open question. Both projects are kept side-by-side until the comparison is
concrete enough to call. Concrete data so far:
- **Asset pipeline**: identical GLBs work in both, zero friction.
- **Web bundle**: three.js wins hard on initial load (~0.6 MB vs ~37 MB).
- **Editor / tooling**: Godot wins — visual scene editor, real debugger.
- **Procgen / logic**: comparable; GDScript port of the dungeon generator
  was quick.

## References

- Spec: [`docs/specs/07-godot-evaluation.md`](specs/07-godot-evaluation.md)
- Notes: [`docs/specs/07-godot-evaluation-notes.md`](specs/07-godot-evaluation-notes.md)
- Godot download: <https://godotengine.org/download/macos/>
- MCP server: <https://github.com/Coding-Solo/godot-mcp>
