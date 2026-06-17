---
title: Biomes, Decor & Breakables
domain: Wayfinding & Dungeons
type: system
status: partial
effort: L
tags: [wayfinder, plan]
---

# Biomes, Decor & Breakables

> Crypt dressing is feature-complete (10 GLBs, 7 room themes, cardinal orient, pottery breakable) — the next priority is routing the `briar_maze` / `hollow` / `snug` scopes to distinct decor themes so each chart template reads as a different place.

## Current state

The crypt biome is solid. `layout_loader.gd` defines `DECOR_MODEL` (10 kinds: bones, torch_wall, bookshelf, sarcophagus, altar, brazier, chest, column, pottery, rug — lines 37–48), `DECOR_COLLIDER` for each (line 50–61), `DECOR_BREAKABLE` for pottery only (terracotta Color, line 64–66), and `ORIENT_RY` + an empty `DECOR_FACING_OFFSET` (lines 69–78). `dungeon_gen.gd` provides 7 room themes (`tomb_hall`, `ossuary`, `archive`, `shrine`, `vault`, `antechamber`, `hearthroom` — lines 49–102) and `COMBAT_THEMES := ["tomb_hall", "ossuary", "archive"]` (line 103), all crypt-only vocabulary. `breakable.gd` implements a one-shot `take_damage` interface matching Combatant's duck-type contract; shattering spawns a `GPUParticles3D` burst of box shards in the break color (lines 49–82) — no visual shader, plain particles.

Three GLBs exist in `models/` (`dungeon_crypt_archway_v1.glb`, `dungeon_crypt_stairs_v1.glb`, `dungeon_crypt_door-wood_v1.glb`) that are NOT in `DECOR_MODEL` and are never placed. The `DECOR_FACING_OFFSET` dict is empty — no per-kind GLB rotation tweak is in use. Scope-routing already works for enemy spawns (`SPAWN_TABLES` in `layout_loader.gd` line 131) but `DECOR_MODEL`, `DECOR_COLLIDER`, `DECOR_BREAKABLE`, and `ROOM_THEMES` in `dungeon_gen.gd` have no per-scope branching — every chart template uses crypt stonework regardless of scope.

## Gaps — what needs fleshing out

1. **[BLOCKER] No per-biome decor routing** — `briar_maze`, `hollow`, `snug`, and `summit` all place crypt sarcophagi and torches. The scope string reaches `_build_decor` via `layout.get("scope")` but is never used for decor selection. Requires: a scope → theme-set mapping in `dungeon_gen.gd` and a scope → model/collider/breakable table in `layout_loader.gd`.
2. **Three unused GLBs** — `dungeon_crypt_archway_v1.glb`, `dungeon_crypt_stairs_v1.glb`, `dungeon_crypt_door-wood_v1.glb` sit in `models/` but are absent from `DECOR_MODEL`. Archway could gate corridor entries; stairs could mark descent rooms; door could be a one-use puzzle blocker.
3. **Shatter shader deferred** — `breakable.gd`'s burst is a color-tinted particle dump; a material-aware geometry shader (explode faces in the break direction) was noted in `system-combat-juice-vfx.md` as the visual upgrade. Treat as Phase 3 polish.
4. **`DECOR_FACING_OFFSET` is unused** — all kinds default to 0. The bookshelf and sarcophagus GLBs may need a half-turn tweak once placed against briar/hollow walls. Currently harmless, but flagged for the per-biome pass.
5. **Single breakable kind** — only `pottery` is in `DECOR_BREAKABLE`. `bones` (small scatter, low HP) and `bookshelf` (medium, yields lore scraps in a future pass) are natural candidates for the crypt. Hollow/briar scopes would need their own breakables (hollow barrel, briar thorn-bundle).
6. **Decor density affix gap** — `festival_pace` scales *enemy* density (`_density_mult`) but does not scale decor count. A dense-room affix should simultaneously thicken both.
7. **Biome-per-chart-template not designed** — the art direction for forest / underdark biomes (model palette, floor texture, wall material, room themes) has no spec. This is the main design gate before Phase 2 work.

## Plan

### Phase 1 — Wire unused crypt GLBs + per-kind facing offsets
- Add `archway`, `stairs`, `door_wood` to `DECOR_MODEL` / `DECOR_COLLIDER` in `layout_loader.gd`. Archway: collider `null` (pass-through), place on corridor-mouth tiles as a room-entry frame. Stairs: collider `Vector3(1.0, 0.3, 1.0)`, place in deepest-depth rooms (depth ≥ 3) as a descent landmark. Door: collider `Vector3(1.0, 2.0, 0.3)`, initially static (not functional).
- Probe the three GLBs for native facing. Set `DECOR_FACING_OFFSET` entries if the GLB faces away from the expected cardinal.
- Extend `ROOM_THEMES` with an `"entry_arch"` satellite rule (kind=`archway`, pattern=`walls`, count [1,2]) — `_dress_rooms` would apply this to entrance-role rooms only.
- Add `bones` and `bookshelf` to `DECOR_BREAKABLE` (HP 1; `bones` color `Color(0.82, 0.78, 0.65)`, `bookshelf` color `Color(0.34, 0.24, 0.14)`).
- **DoD:** A dev boot (`WYRD_NO_SAVE=1 godot --path wyrd`) places at least one archway GLB at a room entry visible in a `WYRD_SHOT=1` screenshot; bones and bookshelves shatter on arrow hit. `test_wyrd_dungeon_scene.gd` stays green.
- **Effort:** S

### Phase 2 — Per-scope decor routing (hollow + briar_maze first)
- Design gate first: author a `BIOME_THEMES` dict in `dungeon_gen.gd` mapping scope → `COMBAT_THEMES` list. For `hollow` (open earthen rooms): themes `earth_den`, `root_hollow`, `antechamber`. For `briar_maze` (tight briared corridors): themes `thorn_passage`, `briar_shrine`. For `snug` (cozy pocket cellar): single theme `cellar`.
- Add scope-keyed `DECOR_MODEL` and `DECOR_COLLIDER` entries in `layout_loader.gd` via a helper `_models_for_scope(scope: String) -> Dictionary` that returns the crypt table as the fallback. This avoids duplicating the constant structure.
- Author hollow GLBs (earthy barrel, mossy log, hanging root cluster) in the Meshy pipeline — 3 new props. Floor texture: `dungeon-hollow-floor-mud-v1.png` (triplanar, warm brown). Wall material: raw-earth procedural noise bump, darker green-grey albedo.
- Author briar GLBs (thorn-bush cluster, knotted branch, hedge arch) — 3 props. Floor texture: `dungeon-briar-floor-leaf-v1.png`. Wall: green-black.
- Wire `layout.scope` into `_build_decor` and `dungeon_gen._dress_rooms` to select the per-scope theme set.
- Extend `SPAWN_TABLES` comment pattern: scope also selects the floor/wall material in `layout_loader._ready`.
- **DoD:** Load a `briar_maze` chart (`WYRD_DEV_CHART=briar_maze`), screenshot confirms briar props + green-black walls, no crypt sarcophagi. Load a `hollow` chart, confirms earthy palette. `test_wyrd_dungeon_scene.gd` green. Crypt scope unchanged.
- **Effort:** L (3+3 new GLBs + two new floor textures = asset-heavy; code routing is M)

### Phase 3 — Shatter shader + decor density affix
- **Shatter shader (deferred, noted in [[system-combat-juice-vfx]]):** Upgrade `breakable.gd`'s `_burst()` to a geometry-shader path that shatters the actual mesh faces outward in the hit direction rather than spawning uniform box particles. Prerequisite: per-GLB mesh surface export. Implement as a `ShaderMaterial` on a `MeshInstance3D` clone using Godot's `VERTEX` shader stage with an `explode` uniform driven by an `AnimationPlayer` tween. Keep the current GPUParticles3D burst as a fallback for non-mesh props.
- **Decor density affix:** `_density_mult` (set in `_read_chart_modifiers`, line 285–287) currently scales only enemy count. Add `_decor_density_mult` driven by the same `festival_pace` affix; pass it into `_dress_rooms` via the gen cfg dict so decor scatter counts scale proportionally. `snug` count minimum stays at 1.
- **DoD:** Breaking pottery spawns a recognizable face-shatter (not a uniform sphere burst) visible in a `WYRD_SHOT=1` screenshot. A `festival_pace`-good chart produces ≥1.4× the baseline decor count on average across 10 procedurally generated layouts (scriptable assertion in a new `test_wyrd_decor.gd` test). `test_wyrd_dungeon_scene.gd` green.
- **Effort:** M

### Phase 4 — Summit / future biomes
- **Summit:** `scope: "crypt"` in `charts.gd` line 63. The Summit already reads as crypt because it IS the deepest crypt. Consider stamping the Queen's antechamber with archway + column set-piece. No new GLBs needed — extend the crypt `ROOM_THEMES` with a `"throne_antechamber"` theme for the boss room.
- **Future biomes (forest / underdark — horizon):** This is a design gate, not an immediate code task. Block on world-bible sign-off for biome 3. When greenlit, Phase 2's `_models_for_scope` pattern extends cleanly — one new scope key, one new texture pair, 3–5 props. Document the extension recipe in `docs/specs/` before starting.
- **DoD:** Summit boss room has an archway + column framing visible in a screenshot. The biome registration pattern is documented in a spec file.
- **Effort:** S (Summit only); L if forest/underdark greenlit

## Dependencies & links

- [[system-dungeon-generation]] — the decor list is assembled in `dungeon_gen._dress_rooms`; scope routing lands there before `layout_loader` can select per-biome GLBs. Phase 2 here is sequenced after dungeon-gen's scope-contract is stable.
- [[system-chart-affixes]] — `festival_pace` good/bad twins drive `_density_mult` (Phase 3 decor density extension), and future biome-locked affixes (e.g. a `briar_bloom` bias that scatters thorn-bush decor) would add rows to `AFFIXES` in `charts.gd`.
- [[system-charts-wayfinding]] — chart template `scope` field is the routing key for per-biome decor; chart design determines which biomes exist at all. New biomes require a new template before decor work can start.
- [[system-combat-juice-vfx]] — Phase 3's shatter shader is noted there as a deferred decor polish item ("breakable-decor shatter shader that reads as material-aware rather than a plain particle dump"). Coordinate to avoid duplicate effort.
- [[system-interactables]] — `_build_interactable` (layout_loader line 591) places Chest/Shrine/Hearth scenes at focal cells; those scenes carry their own GLBs and are not in `DECOR_MODEL`. Biome theming does not touch interactable visuals (they are role-typed, not biome-typed) — but confirm brazier/chest GLB faces are correct per ORIENT_RY after Phase 1.
- [[system-elites]] — `system-elites.md` notes that biome tinting for elite overlay colors (bone-white crypt vs bark-brown briar) is deferred; Phase 2's scope routing would enable that pass.
- [[system-bosses]] — Phase 4 Summit antechamber set-piece complements the boss-room feel noted in `system-bosses.md` Phase 5 expansion.
- **Plan.md Part A (combat-feel, SHIPPED):** archway/stairs visuals do not interact with the combat feel layer. **Plan.md Part B (loop-feel, PLANNED):** the `festival_pace` decor density in Phase 3 is adjacent to B6 (inscribe feel) — a dense dungeon should feel intentionally authored, not accidental. Sequence Phase 3 alongside or after Plan.md B6.

## Verification

- **Phase 1:** `WYRD_NO_SAVE=1 WYRD_SHOT=1 godot --headless --path wyrd` (screenshot to `/tmp/wyrd_town.png`); inspect for archway placement. Fire an arrow at bones in a live session — confirm shatter. Run `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` — must stay green.
- **Phase 2:** `WYRD_NO_SAVE=1 WYRD_DEV_CHART=briar_maze WYRD_SHOT=1 godot --headless --path wyrd` screenshot confirms briar props; same for hollow. Headless dungeon suite green. No crypt sarcophagi in a briar run (assert in test or visual check).
- **Phase 3:** New `test_wyrd_decor.gd` — generates 10 layouts with a `festival_pace`-good chart, asserts average decor count ≥ baseline × 1.35. Run as `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_decor.gd`. Shatter shader verified by `WYRD_SHOT=1` screenshot of a broken pottery piece showing face fragments, not a uniform sphere.
- **Phase 4:** `WYRD_NO_SAVE=1 WYRD_DEV_CHART=summit WYRD_SHOT=1` screenshot shows archway + column framing in the boss room.

## Open questions

1. Should `briar_maze` decor themes use the hollow GLBs (shared earthy palette) or have entirely separate briar-specific props? The scope names suggest distinct palettes, but sharing assets saves the Meshy pipeline cost.
2. Should breakable `bookshelf` drop a lore scrap item (a small text-flavor collectible) or be purely destructive? Requires a decision on whether Wayfinder has environmental lore pickups at all.
3. The `door_wood` GLB — should it be static decor only, or should a future pass make it a one-hit obstacle (HP 2, blocks a room until broken)? Defining this now shapes whether it gets a Breakable wrapper in Phase 1 or deferred.
