extends Node3D

# Spec 07/10 — Godot evaluation.
# Builds the crypt as Node3D primitives + GLB instances, with honest
# collision (spec 10): per-tile floor, walls, boss/enemy/decor colliders,
# a kill-plane that respawns the player, and named collision layers.
#
# Layout source:
#   USE_PROCGEN = true  → fresh seeded dungeon from dungeon_gen.gd
#   USE_PROCGEN = false → static snapshot at res://data/crypt_floor1.json

const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const AnimDriverScript = preload("res://scripts/anim_driver.gd")
const CombatantScript = preload("res://scripts/combatant.gd")
const BossScript = preload("res://scripts/boss.gd")
const RatAnimScript = preload("res://scripts/rat_anim.gd")
const CreatureAnimScript = preload("res://scripts/creature_anim.gd")
const BreakableScript = preload("res://scripts/breakable.gd")
const GatherNodeScript = preload("res://scripts/gather_node.gd")
const ExitWaystoneScript = preload("res://scripts/exit_waystone.gd")
const GatherDefs = preload("res://data/gather.gd")

# (Per-kind enemy/boss HP moved into ENEMY_KINDS / BOSS_KINDS below.)

const USE_PROCGEN := true
const DEBUG_SCORE := true
const DEBUG_SHOT := false   # true → save /tmp/godot_selfshot.png 3s after load
const JSON_PATH := "res://data/crypt_floor1.json"

# Collision layers (bit values). Mirrors project.godot [layer_names].
const LAYER_WORLD := 1     # layer 1 — floor, walls, solid decor
const LAYER_ENEMIES := 4   # layer 3 — boss + enemy blockers

const KILL_PLANE_Y := -6.0

# decor.kind → GLB path under res://models/ (symlink to ../models)
const DECOR_MODEL := {
	"bones":       "res://models/dungeon_crypt_bones_v1.glb",
	"torch_wall":  "res://models/dungeon_crypt_torch-wall_v1.glb",
	"bookshelf":   "res://models/dungeon_crypt_bookshelf_v1.glb",
	"sarcophagus": "res://models/dungeon_crypt_sarcophagus_v1.glb",
	"altar":       "res://models/dungeon_crypt_altar_v1.glb",
	"brazier":     "res://models/dungeon_crypt_brazier_v1.glb",
	"chest":       "res://models/dungeon_crypt_chest_v1.glb",
	"column":      "res://models/dungeon_crypt_column_v1.glb",
	"pottery":     "res://models/dungeon_crypt_pottery_v1.glb",
	"rug":         "res://models/dungeon_crypt_rug_v1.glb",
}
# decor.kind → collider box size, or null for pass-through decor.
const DECOR_COLLIDER := {
	"bones":       Vector3(0.8, 0.4, 0.8),
	"bookshelf":   Vector3(0.9, 1.8, 0.5),
	"torch_wall":  null,                     # wall-mounted, nothing to bump
	"sarcophagus": Vector3(1.0, 0.9, 1.6),
	"altar":       Vector3(1.1, 1.1, 1.1),
	"brazier":     Vector3(0.6, 1.1, 0.6),
	"chest":       Vector3(0.9, 0.7, 0.9),
	"column":      Vector3(0.8, 2.5, 0.8),
	"pottery":     Vector3(0.5, 0.7, 0.5),
	"rug":         null,                     # flat — walk over it
}
# decor.kind → break colour for the destructible decor (spec 26 follow-up).
# Kinds in this dict get a Breakable wrapper (HP 1, shatters on hit).
const DECOR_BREAKABLE := {
	"pottery": Color(0.65, 0.45, 0.30),
	"bones": Color(0.82, 0.78, 0.65),       # cream bone shards
	"bookshelf": Color(0.34, 0.24, 0.14),   # splintered dark wood
}
# Spec 28 — orient cardinal → Y rotation. layout_loader applies this to the
# decor body (or pass-through instance). "center" leaves rotation at 0.
const ORIENT_RY := {
	"n": 0.0,            # placed on north edge → faces south (+Z)
	"e": -PI / 2.0,      # placed on east edge  → faces west  (-X)
	"s": PI,             # placed on south edge → faces north (-Z)
	"w": PI / 2.0,       # placed on west edge  → faces east  (+X)
	"center": 0.0,
}
# Per-kind GLB facing tweak (radians). Empty for v1 — extend if a kind's
# native model orientation makes it face the wrong way.
const DECOR_FACING_OFFSET := {}

# Wyrd — enemy kinds by name. `scale` = calibrated multiplier (spec 16);
# `fit_h` = GlbFit target height for kinds never calibrated. `bob` =
# procedural hop-bob params [move_bob, move_rate] for unrigged critters.
# B3 — per-kind stats: damage/speed/atk_cd make a rat read different from
# a skeleton in the hands, not just the eyes. Slow hitters hit hard; fast
# ones nip. Tier scaling multiplies HP only — speed stays honest.
#
# Slice A — ARCHETYPE COLOR-CODING. The raw Meshy GLBs ship with NO surface
# materials (Godot falls back to flat grey, so skeleton/ghost/hedge_sprite all
# read as the same grey blob). Every kind now carries a `tint` painted onto a
# material we own, so size + hue = instant ID and the ink outline (next_pass,
# below) actually renders. Hues track the kit palette family:
#   skeleton  = bone-cream high-value     rat     = INK_MID brown
#   ghost     = pale cool blue (ethereal) hedge   = SAGE green
#   bramble   = SAGE green (deeper)       skitter = TERRACOTTA
# `ethereal` adds a faint cool emission + alpha so ghosts read as spirits, not
# painted stone. Pairs with the existing scale spread for two-axis legibility.
const ENEMY_KINDS := {
	"skeleton": {"model": "res://models/enemy_skeleton_v1.glb", "scale": 1.45,
		"hp": 18, "damage": 7, "speed": 1.55, "atk_cd": 1.7,
		"tint": Color(0.86, 0.82, 0.70)},
	"rat": {"model": "res://models/enemy_rat_v1.glb", "scale": 0.55,
		"hp": 10, "damage": 2, "speed": 2.6, "atk_cd": 0.9,
		"tint": Color(0.42, 0.32, 0.24), "bob": [0.14, 13.0]},
	"ghost": {"model": "res://models/enemy_ghost_v1.glb", "scale": 2.00,
		"hp": 14, "damage": 5, "speed": 1.35, "atk_cd": 1.5,
		"tint": Color(0.66, 0.78, 0.90), "ethereal": true,
		"ranged": true, "proj_speed": 9.0, "proj_damage": 5},
	"hedge_sprite": {"model": "res://models/enemy_hedge_sprite_v1.glb", "scale": 2.00,
		"hp": 22, "damage": 6, "speed": 1.9, "atk_cd": 1.4,
		"tint": Color(0.44, 0.56, 0.27)},
	"bramble_imp": {"model": "res://models/bramble_imp_v4.glb", "fit_h": 1.05,
		"hp": 12, "damage": 4, "speed": 2.2, "atk_cd": 1.1,
		"tint": Color(0.34, 0.46, 0.22), "bob": [0.12, 10.0]},
	"skitterling": {"model": "res://models/skitterling.glb", "fit_h": 0.55,
		"hp": 7, "damage": 2, "speed": 3.0, "atk_cd": 0.8,
		"tint": Color(0.70, 0.30, 0.20), "bob": [0.10, 15.0]},
	# Support archetype — a hedge-sprite reskin that follows and HEALS its pack
	# instead of attacking; greener, slower, low HP. Kill it first or the room
	# never goes down. (combatant.gd reads `support`.)
	"warden": {"model": "res://models/enemy_hedge_sprite_v1.glb", "scale": 1.7,
		"hp": 20, "damage": 3, "speed": 1.6, "atk_cd": 2.2,
		"tint": Color(0.44, 0.72, 0.40), "support": true},
	# Bruiser archetype — a chunky bramble-imp reskin that telegraphs an
	# expanding floor ring (~0.7s) then lands a heavy AoE strike. The first
	# "get out of the circle" tell in the cast. (combatant.gd reads `bruiser`.)
	"barrow_brute": {"model": "res://models/bramble_imp_v4.glb", "fit_h": 1.7,
		"hp": 32, "damage": 14, "speed": 1.0, "atk_cd": 3.0,
		"tint": Color(0.28, 0.22, 0.18), "bruiser": true},
}

# Slice A — CHUNKY INK OUTLINE. Deep-INK inverted-hull shell, attached as the
# `next_pass` of each enemy's painted material (which is why we paint EVERY kind
# above — next_pass on the materialless GLBs renders nothing). next_pass rides
# the same skinned/animated mesh, so it deforms with the limbs — no separate
# static child-shell. grow_amount is tuned for the FATE camera (zoom ~14,
# telephoto); it is the orchestrator's main tuning knob.
const OUTLINE_INK := Color(0.13, 0.09, 0.06)
const OUTLINE_GROW := 0.05   # orchestrator tuning knob (FATE zoom ~14)

# Per-scope weighted spawn tables (the three.js dungeonSpawns pattern) —
# a Briar Maze run should FEEL different from a Hollow, not just route
# differently. Weights are relative; unknown scopes fall back to crypt.
const SPAWN_TABLES := {
	"snug": [["rat", 70], ["skeleton", 30]],
	"hollow": [["skeleton", 45], ["rat", 20], ["bramble_imp", 20], ["ghost", 15], ["warden", 10]],
	"briar_maze": [["bramble_imp", 50], ["hedge_sprite", 30], ["skitterling", 20]],
	"crypt": [["skeleton", 40], ["rat", 25], ["ghost", 20], ["hedge_sprite", 15], ["warden", 10], ["barrow_brute", 8]],
}

# Boss kinds (boss-as-affix). The Hedgemother is rigged; the boar and wolf
# are quadrupeds Meshy can't rig (spec 11) — they lumber via the hop-bob.
# `trophy` is the chart-chain drop: each boss yields the key that inks the
# next den at the Inscribing Table (elites drop the first key).
const BOSS_KINDS := {
	"hedgemother": {"name": "The Hedgemother",
		"model": "res://models/hedgemother_v2.glb", "scale": 3.75,
		"hp": 60, "damage": 8, "radius": 0.9, "height": 3.0,
		"trophy": "tusker_tusk"},
	"burrow_boar": {"name": "The Burrow Boar",
		"model": "res://models/burrow_boar_v3.glb", "fit_h": 2.2,
		"hp": 80, "damage": 11, "radius": 1.0, "height": 2.2, "bob": [0.10, 6.0],
		"trophy": "wightpelt"},
	"wolf_alpha": {"name": "The Wolf Alpha",
		"model": "res://models/wolf_alpha_v2.glb", "fit_h": 1.8,
		"hp": 55, "damage": 7, "radius": 0.8, "height": 1.8, "bob": [0.13, 9.5],
		"trophy": "alpha_fang"},
	# The Summit's nest-mother — the final chart's boss. Same silhouette the
	# player learned at level 8, scaled into a monarch.
	"hedgemother_queen": {"name": "The Hedgemother Queen",
		"model": "res://models/hedgemother_v2.glb", "scale": 4.6,
		"hp": 160, "damage": 13, "radius": 1.1, "height": 3.6, "trophy": ""},
}

var _floor_mat: StandardMaterial3D
var _wall_mat: StandardMaterial3D
var _scope := "crypt"   # chart scope — recolors the biome palette + filters decor
var _rng := RandomNumberGenerator.new()
var _net_foe_idx := 0          # Phase B — deterministic enemy naming
var net_spawn := Vector3.ZERO  # Phase B — co-op entry spawn for NetGame
var _entry_pos := Vector3.ZERO          # respawn target for the kill-plane

# Wyrd — chart modifier affixes, cached from Game at build time.
# tyrannical good: enemies ×1.5 HP. Erratic (bad twin): per-enemy jitter.
# festival_pace good: ×1.5 room density. Lockstep (bad twin): ×0.75.
var _hp_mult := 1.0
var _hp_jitter := false
var _speed_mult := 1.0
var _burst_on_death := false
var _burst_hits_player := false
var _aggro_mult := 1.0
var _atk_speed_mult := 1.0
var _dmg_mult := 1.0
var _trophy_mult := 1.0
var _density_mult := 1.0

func _ready() -> void:
	# B8 — the hollows are quiet; the theme belongs to town.
	var sfx0 := get_node_or_null("/root/Sfx")
	if sfx0 != null and sfx0.has_method("stop_music"):
		sfx0.stop_music()
	# Phase B — in a chart run the spawn RNG seeds from the chart, so every
	# co-op peer builds IDENTICAL enemies (same tiles, kinds, elites, jitter)
	# and the host only has to sync state, never spawns. Dev boots without a
	# chart keep the old fully-random flavor.
	var game0 := get_tree().root.get_node_or_null("Game")
	var chart_seed := -1
	if game0 != null and not (game0.active_chart as Dictionary).is_empty():
		chart_seed = int(game0.active_chart.get("seed", -1))
	if chart_seed >= 0:
		_rng.seed = (chart_seed ^ 0x5DEECE66) & 0x7FFFFFFFFFFFFFFF
	else:
		_rng.randomize()

	# Crypt brick floor — triplanar so the per-tile planes share one continuous
	# world-projected texture (seam-free) from a single material (cheap). A gentle
	# warm wash keeps it candle-lit, not morgue-grey.
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.albedo_texture = preload(
		"res://textures/crypt/dungeon-crypt-floor-brick-v1.png")
	_floor_mat.uv1_triplanar = true
	_floor_mat.uv1_scale = Vector3(0.34, 0.34, 0.34)
	_floor_mat.albedo_color = Color(0.84, 0.77, 0.66)
	_floor_mat.roughness = 0.92

	_wall_mat = StandardMaterial3D.new()
	_wall_mat.albedo_color = Color(0.34, 0.31, 0.28)   # warm crypt stone
	_wall_mat.roughness = 0.95
	# Spec 26 follow-up — procedural noise normal map so the box walls
	# read as carved stone, not flat slabs. (The wall GLBs weren't a real
	# modular kit — wrong-sized pieces — so they're dropped for walls.)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.16
	noise.fractal_octaves = 4
	var nt := NoiseTexture2D.new()
	nt.noise = noise
	nt.as_normal_map = true
	nt.bump_strength = 5.0
	nt.width = 256
	nt.height = 256
	_wall_mat.normal_enabled = true
	_wall_mat.normal_texture = nt

	var layout: Dictionary = _get_layout()
	if layout.is_empty():
		push_error("layout_loader: no layout")
		return

	# Biome palette — recolour the walls/floor by scope so a hollow / briar
	# run reads as a different place, not just a different spawn table. Done
	# before _build_grid (which bakes these materials into the tiles).
	_scope = String(layout.get("scope", "crypt"))
	_apply_biome_palette(_scope)
	_read_chart_modifiers()
	_build_grid(layout.grid)
	_build_floor_collision(layout.grid)
	_build_navmesh(layout.grid)
	_build_kill_plane()
	# Spec 29 — _build_decor now needs the full layout dict so it can read
	# room_depths + the dungeon seed when stamping interactables.
	_build_decor(layout)
	# Wyrd — boss-as-affix: bossKind "" means no boss this run.
	if String(layout.get("bossKind", "")) != "":
		_build_boss(layout.bossRoom, layout.grid, String(layout.bossKind))
	else:
		_build_empty_throne(layout)
	var enemy_n := _build_enemies(layout)
	_build_exit_waystone(layout)
	# Phase B — co-op: one body per peer at the entry; offline keeps the
	# baked player.
	var netr := get_node_or_null("/root/NetGame")
	if netr != null and bool(netr.active):
		net_spawn = Vector3(int(layout.entry.x) + 0.5, 0.0,
			int(layout.entry.y) + 0.5)
		netr.setup_scene(self)
	else:
		_position_player(layout.entry)

	# Dev: when DEBUG_SHOT (or WYRD_SHOT=1 in the env), self-capture a
	# viewport screenshot once the scene settles — lets the camera framing
	# be reviewed without a native-window screenshot. Off by default.
	if DEBUG_SHOT or OS.get_environment("WYRD_SHOT") != "":
		get_tree().create_timer(3.0).timeout.connect(_debug_screenshot)

	var seed_str := str(layout.get("seed", "static"))
	print("[layout_loader] crypt built — %d decor, %d enemies, boss=%s, seed=%s" % [
		(layout.decor as Array).size(), enemy_n, layout.bossKind, seed_str,
	])
	if DEBUG_SCORE and layout.has("score"):
		var s: Dictionary = layout.score
		print("[layout_loader] score=%.2f (conn=%.2f path=%.2f rooms=%.2f floor=%.2f corr=%.2f deadends=%.2f) attempts=%d" % [
			s.total, s.connectivity, s.critical_path, s.room_count,
			s.floor_ratio, s.corridor_ratio, s.dead_ends,
			int(layout.get("attempts", 1)),
		])

# Wyrd — cache the active chart's combat modifiers before any spawns.
func _read_chart_modifiers() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	if game.affix_good("tyrannical"):
		_hp_mult = 1.5
	if game.affix_bad("tyrannical"):
		_hp_jitter = true
	if game.affix_good("festival_pace"):
		_density_mult = 1.5
	if game.affix_bad("festival_pace"):
		_density_mult = 0.75
	# B6 — Sprinting Things: every enemy moves a quarter faster. The bad
	# twin slows the PLAYER instead (applied on the player at spawn).
	if game.affix_good("sprinter"):
		_speed_mult = 1.25
	# B6 — Bursting: corpses pop. Good scorches kin; Volatile (bad) also
	# scorches the player.
	if game.affix_good("bursting") or game.affix_bad("bursting"):
		_burst_on_death = true
		_burst_hits_player = game.affix_bad("bursting")
	# B6 wave 2.
	if game.affix_good("fog_of_hedge"):
		_aggro_mult = 0.65
	if game.affix_bad("fog_of_hedge"):
		_aggro_mult = 1.3
	if game.affix_good("frenzied"):
		_atk_speed_mult = 1.25
	if game.affix_bad("frenzied"):
		_dmg_mult = 1.15
	if game.affix_good("marked_quarry"):
		_trophy_mult = 2.0
	if game.affix_bad("marked_quarry"):
		_trophy_mult = 0.5
	var cfg: Dictionary = game.run_cfg()
	# Template base density (snug's gentle cellar) stacks with the affix.
	_density_mult *= float(cfg.get("enemy_density", 1.0))
	# ADR 0013 — the den's level scales enemy HP and damage (symmetric with the
	# player's per-level growth, so difficulty tracks level-delta, not absolutes).
	var den_lv: int = int(cfg.get("den_level", 3))
	var den_scale: float = pow(float(game.LEVEL_POWER), float(den_lv - 1))
	_hp_mult *= den_scale
	_dmg_mult *= den_scale

# Recolour the shared wall/floor materials by chart scope so a hollow / briar
# run reads as a different place. Albedo tints only (no texture swaps — keeps
# it crash-safe with the shipped crypt textures); crypt/summit keep defaults.
func _apply_biome_palette(scope: String) -> void:
	match scope:
		"hollow", "tier_1":
			_floor_mat.albedo_color = Color(0.66, 0.70, 0.55)   # earthy moss-tan
			_wall_mat.albedo_color = Color(0.28, 0.32, 0.24)     # dark earth
		"briar_maze":
			_floor_mat.albedo_color = Color(0.40, 0.48, 0.34)    # green leaf-litter
			_wall_mat.albedo_color = Color(0.20, 0.26, 0.18)     # deep briar green
		"snug":
			_floor_mat.albedo_color = Color(0.80, 0.72, 0.58)    # cellar sandstone
			_wall_mat.albedo_color = Color(0.44, 0.38, 0.30)     # rough clay
		_:
			pass   # crypt / summit keep the warm stone defaults

func _get_layout() -> Dictionary:
	if USE_PROCGEN:
		# Wyrd — a chart run hands its gen block + seed to the generator;
		# a dev boot of World.tscn (no Game / no active chart) keeps the
		# pre-chart defaults: random seed, full 48-grid, boss included.
		var game := get_tree().root.get_node_or_null("Game")
		var cfg: Dictionary = game.run_cfg() if game != null else {}
		print("[layout_loader] chart cfg: %s" % str(cfg))
		return DungeonGenScript.generate(int(cfg.get("seed", -1)), cfg)
	var f := FileAccess.open(JSON_PATH, FileAccess.READ)
	if f == null:
		push_error("layout_loader: %s not found" % JSON_PATH)
		return {}
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed == null:
		push_error("layout_loader: JSON parse failed")
		return {}
	return parsed

# ---- grid: visual floor planes + wall blocks ----
func _build_grid(grid: Array) -> void:
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			var kind := String(row[x])
			if kind == "floor":
				_place_floor(x, y)
			elif kind == "wall":
				_place_wall(x, y, grid)

func _place_floor(x: int, y: int) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _floor_mat
	mi.position = Vector3(x + 0.5, 0.0, y + 0.5)
	add_child(mi)

# Walls (spec 24) — lowered to 2.5 m so the camera reads over them, and
# built from the modular crypt wall GLBs instead of a flat box.
const WALL_HEIGHT := 2.5

const WALL_GLB := {
	"straight":    preload("res://models/dungeon_crypt_wall-straight_v1.glb"),
	"cornerInner": preload("res://models/dungeon_crypt_wall-corner-inner_v1.glb"),
	"cornerOuter": preload("res://models/dungeon_crypt_wall-corner-outer_v1.glb"),
}
# Native GLB extents (probed) — used to scale each piece into a 1×H×1 tile.
const WALL_NATIVE := {
	"straight":    Vector3(1.90, 1.23, 0.40),
	"cornerInner": Vector3(1.51, 1.90, 1.50),
	"cornerOuter": Vector3(1.69, 1.91, 1.79),
}

func _place_wall(x: int, y: int, grid: Array) -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(x + 0.5, WALL_HEIGHT * 0.5, y + 0.5)
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	body.add_to_group("wall")          # camera occlusion fades these

	# Visual — a plain BoxMesh wall with the procedural stone material.
	# Per-wall material instance so the camera-occlusion fade can fade one
	# wall without fading them all; a small HSV-value jitter so the run
	# doesn't read as one identical slab. (The crypt wall GLBs aren't a
	# modular kit; see spec-26 followup.)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, WALL_HEIGHT, 1.0)
	var mi := MeshInstance3D.new()
	mi.name = "WallMesh"
	mi.mesh = mesh
	var wmat: StandardMaterial3D = _wall_mat.duplicate()
	wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var base: Color = _wall_mat.albedo_color
	var jit := _rng.randf_range(-0.05, 0.05)
	wmat.albedo_color = Color(
		clampf(base.r + jit, 0.0, 1.0),
		clampf(base.g + jit, 0.0, 1.0),
		clampf(base.b + jit, 0.0, 1.0), 1.0)
	mi.material_override = wmat
	body.add_child(mi)

	# Collision stays a plain box — robust, and the GLB is purely visual.
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, WALL_HEIGHT, 1.0)
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)

# Port of the three.js cryptWallVariant() — picks straight / corner pieces
# + a Y rotation from which cardinal neighbours are open floor.
func _wall_variant(grid: Array, x: int, y: int) -> Dictionary:
	var n := _is_floor(grid, x, y - 1)
	var e := _is_floor(grid, x + 1, y)
	var s := _is_floor(grid, x, y + 1)
	var w := _is_floor(grid, x - 1, y)
	var count := int(n) + int(e) + int(s) + int(w)
	if count == 0 or count == 4:
		return {"kind": "straight", "ry": 0.0}
	if count == 1:
		if n: return {"kind": "straight", "ry": 0.0}
		if e: return {"kind": "straight", "ry": -PI / 2}
		if s: return {"kind": "straight", "ry": PI}
		return {"kind": "straight", "ry": PI / 2}            # w
	if count == 2:
		if n and s: return {"kind": "straight", "ry": 0.0}
		if e and w: return {"kind": "straight", "ry": PI / 2}
		if n and e: return {"kind": "cornerOuter", "ry": 0.0}
		if e and s: return {"kind": "cornerOuter", "ry": -PI / 2}
		if s and w: return {"kind": "cornerOuter", "ry": PI}
		return {"kind": "cornerOuter", "ry": PI / 2}         # w and n
	# count == 3 — one closed side, concave inner corner.
	if not n: return {"kind": "cornerInner", "ry": PI}
	if not e: return {"kind": "cornerInner", "ry": PI / 2}
	if not s: return {"kind": "cornerInner", "ry": 0.0}
	return {"kind": "cornerInner", "ry": -PI / 2}            # not w

func _is_floor(grid: Array, x: int, y: int) -> bool:
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[0].size():
		return false
	return String(grid[y][x]) == "floor"

# ---- floor collision: one thin box per floor tile, top surface at y=0 ----
func _build_floor_collision(grid: Array) -> void:
	var body := StaticBody3D.new()
	body.name = "FloorCollision"
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			if String(row[x]) != "floor":
				continue
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.0, 0.2, 1.0)
			var col := CollisionShape3D.new()
			col.shape = shape
			col.position = Vector3(x + 0.5, -0.1, y + 0.5)
			body.add_child(col)
	add_child(body)

# ---- navmesh: one quad per walkable tile, assembled into a connected
# NavigationMesh so enemies route around walls (spec 19) ----
func _build_navmesh(grid: Array) -> void:
	var verts := PackedVector3Array()
	var index := {}                      # grid-corner Vector2i → vertex idx
	var polys: Array = []
	for y in grid.size():
		var row: Array = grid[y]
		for x in row.size():
			if String(row[x]) != "floor":
				continue
			var poly := PackedInt32Array()
			# corners CCW-from-above so the polygon faces +Y
			for c in [Vector2i(x, y), Vector2i(x, y + 1),
					Vector2i(x + 1, y + 1), Vector2i(x + 1, y)]:
				if not index.has(c):
					index[c] = verts.size()
					verts.append(Vector3(c.x, 0.05, c.y))
				poly.append(index[c])
			polys.append(poly)
	var nav := NavigationMesh.new()
	nav.vertices = verts
	for p in polys:
		nav.add_polygon(p)
	var region := NavigationRegion3D.new()
	region.name = "CryptNav"
	region.navigation_mesh = nav
	add_child(region)
	print("[layout_loader] navmesh — %d tiles, %d verts" % [polys.size(), verts.size()])

# ---- kill-plane: fall off the floor → respawn at entry ----
func _build_kill_plane() -> void:
	var area := Area3D.new()
	area.name = "KillPlane"
	var shape := WorldBoundaryShape3D.new()
	shape.plane = Plane(Vector3.UP, KILL_PLANE_Y)
	var col := CollisionShape3D.new()
	col.shape = shape
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_kill_plane_entered)

func _on_kill_plane_entered(body: Node) -> void:
	if body.is_in_group("player") and body is Node3D:
		(body as Node3D).global_position = _entry_pos
		if body is CharacterBody3D:
			(body as CharacterBody3D).velocity = Vector3.ZERO

# ---- decor ----
# Spec 29 — decor entries with `interact_role` get the typed-room
# interactable scene (Chest / Shrine / Hearth) at the focal cell instead of
# the static GLB. Everything else is the spec 25/28 themed-dressing path.
const ChestScene := preload("res://scenes/Chest.tscn")
const ShrineScene := preload("res://scenes/Shrine.tscn")
const HearthScene := preload("res://scenes/Hearth.tscn")

func _build_decor(layout: Dictionary) -> void:
	var decor: Array = layout.get("decor", [])
	var depths: Array = layout.get("room_depths", [])
	var dungeon_seed: int = int(layout.get("seed", 0))
	for d in decor:
		# Wyrd — gather nodes (chart bias affixes) fork before everything.
		if bool(d.get("gather", false)):
			var gn: Node3D = GatherNodeScript.new()
			gn.setup(String(d.kind), String(d.get("item", "wild_herb")))
			if d.has("ore_tier"):
				gn.setup_ore_tier(String(d.ore_tier))
			elif d.has("herb_tier"):
				gn.setup_herb_tier(String(d.herb_tier))
			gn.position = Vector3(int(d.x) + 0.5, 0.0, int(d.y) + 0.5)
			add_child(gn)
			continue
		# Spec 29 — typed-room focal interactables fork before the GLB path.
		var ir := String(d.get("interact_role", ""))
		if ir != "":
			_build_interactable(ir, d, depths, dungeon_seed)
			continue
		var kind := String(d.kind)
		if not DECOR_MODEL.has(kind):
			continue
		# Biome filter — crypt sarcophagi don't belong in a hollow / briar run.
		if _scope != "crypt" and _scope != "summit" and kind == "sarcophagus":
			continue
		var packed: PackedScene = load(DECOR_MODEL[kind])
		if packed == null:
			continue
		var inst: Node3D = packed.instantiate()
		var box = DECOR_COLLIDER.get(kind, null)
		# Spec 28 — read the orient cardinal placed by dungeon_gen; rotate
		# the body (or pass-through instance) so wall-edge decor faces the
		# room interior. Symmetric kinds (column/pottery/bones) are visually
		# unaffected by Y rotation — harmless to apply uniformly.
		var orient := String(d.get("orient", "center"))
		var ry: float = ORIENT_RY.get(orient, 0.0) \
			+ float(DECOR_FACING_OFFSET.get(kind, 0.0))
		if box == null:
			# Pass-through decor — plain instance.
			inst.position = Vector3(int(d.x) + 0.5, 0.05, int(d.y) + 0.5)
			inst.rotation.y = ry
			add_child(inst)
			# Torches cast a warm pool of light (spec 16 dramatic lighting).
			if kind == "torch_wall":
				_add_torch_light(int(d.x) + 0.5, int(d.y) + 0.5)
		else:
			# Breakable decor (spec 26) — wrap in a Breakable that also has a
			# Hurtbox the player's arrows can hit. Otherwise: plain StaticBody3D.
			var breakable := DECOR_BREAKABLE.has(kind)
			var body: StaticBody3D = BreakableScript.new() if breakable else StaticBody3D.new()
			body.position = Vector3(int(d.x) + 0.5, 0.0, int(d.y) + 0.5)
			body.rotation.y = ry        # rotates the GLB AND the box collider
			body.collision_layer = LAYER_WORLD
			body.collision_mask = 0
			inst.position = Vector3(0.0, 0.05, 0.0)
			body.add_child(inst)
			var shape := BoxShape3D.new()
			shape.size = box
			var col := CollisionShape3D.new()
			col.shape = shape
			col.position = Vector3(0.0, box.y * 0.5, 0.0)
			body.add_child(col)
			add_child(body)
			if breakable:
				var bsize: Vector3 = box
				(body as Node).call("setup", 1, DECOR_BREAKABLE[kind],
					maxf(bsize.x, bsize.z) * 0.55, bsize.y)

# Spec 29 — instantiate the typed-room interactable for a focal-tagged decor
# entry. The interactable handles its own visual (it carries the GLB inside)
# + detection (Area3D on INTERACT_LAYER for the player's scanner).
func _build_interactable(role: String, d: Dictionary,
		depths: Array, dungeon_seed: int) -> void:
	var x: int = int(d.x)
	var y: int = int(d.y)
	var rid: int = int(d.get("room_id", -1))
	var depth: int = 0
	if rid >= 0 and rid < depths.size():
		depth = int(depths[rid])
	var pos := Vector3(x + 0.5, 0.0, y + 0.5)
	match role:
		"treasure":
			var c := ChestScene.instantiate()
			c.depth = depth
			add_child(c)
			c.global_position = pos
		"shrine":
			var s := ShrineScene.instantiate()
			# (dungeon_seed XOR room_id) — same dungeon seed → same 3 buffs
			# at this shrine, but a different shrine in the same dungeon
			# offers a different mix.
			s.seed_value = dungeon_seed ^ ((rid + 1) * 2654435761)
			add_child(s)
			s.global_position = pos
		"rest":
			var h := HearthScene.instantiate()
			h.room_id = rid
			add_child(h)
			h.global_position = pos

# A warm point light at a torch, ~1.6 m up the wall — pools of light in
# darkness (spec 16).
func _add_torch_light(wx: float, wz: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(wx, 1.6, wz)
	lamp.light_color = Color(1.0, 0.74, 0.42)   # warm flame
	lamp.light_energy = 2.2
	lamp.omni_range = 7.0
	lamp.omni_attenuation = 1.4
	add_child(lamp)

# Prefer the Meshy-rigged variant (<name>_rigged.glb) when it exists,
# else the static _v1 GLB (spec 11 fallback — e.g. the rat never rigged).
func _resolve_model(base_path: String) -> String:
	var rigged := base_path.trim_suffix(".glb") + "_rigged.glb"
	if ResourceLoader.exists(rigged):
		return rigged
	return base_path

# ---- boss (spec 17) ----
var _gates: Array = []                  # arena-seal wall blocks
var _boss_body: CharacterBody3D = null  # Wyrd — exit waystone waits on her death

func _build_boss(boss_room, grid: Array, boss_kind: String = "hedgemother") -> void:
	if boss_room == null:
		return
	var def: Dictionary = BOSS_KINDS.get(boss_kind, BOSS_KINDS["hedgemother"])
	var cx: int = int(boss_room.x) + int(int(boss_room.w) / 2.0)
	var cy: int = int(boss_room.y) + int(int(boss_room.h) / 2.0)
	var model := _resolve_model(String(def.model))
	var packed: PackedScene = load(model)
	if packed == null:
		return
	var inst: Node3D = packed.instantiate()
	if def.has("scale"):
		inst.scale = Vector3.ONE * float(def.scale)   # calibrated (spec 16)
	else:
		GlbFit.normalize_height(inst, float(def.fit_h))
	_unmetal(inst)
	# Slice A — keep the boss's own GLB textures but chain on the ink rim so she
	# matches the enemy silhouette language (no flat tint over her painted skin).
	_outline_only(inst)
	var boss_hp: int = int(def.hp)
	var boss := _spawn_character(inst, cx, cy, float(def.radius),
		float(def.height), boss_hp, BossScript)
	# Spec 27b — boss drops the boss loot pile.
	boss.role = "boss"
	boss.depth = 9
	boss.damage = int(def.get("damage", 8))
	boss.kind = boss_kind              # B4a — selects the moveset (boar charges)
	_boss_body = boss                  # Wyrd — exit waystone keys off her death
	# The chart chain — her death yields the trophy that inks the next den.
	var trophy := String(def.get("trophy", ""))
	if trophy != "":
		boss.died.connect(func():
			var game := get_tree().root.get_node_or_null("Game")
			if game != null:
				game.add_material(trophy, 1)
				if game.ledger != null:
					game.ledger.apply(trophy)   # ADR 0013 — trophy → permanent stat
				game.notify("Trophy claimed: %s. Slot it at the Inscribing Table." %
					GatherDefs.material_name(trophy)))
	# Every boss breathes/sways at idle and bobs when moving (Meshy can't rig
	# these). Quadrupeds pass their lumbering bob; humanoid bosses get the
	# gentle default so they're never frozen.
	var qa = CreatureAnimScript.new()
	if def.has("bob"):
		qa.setup(inst, float(def.bob[0]), float(def.bob[1]))
	else:
		qa.setup(inst)
	boss._proc_anim = qa
	AnimDriverScript.play_idle(inst)

	# Arena seal — gate blocks at the boss-room openings, raised on aggro.
	_gates = _make_arena_gates(boss_room, grid)
	boss.aggroed.connect(_raise_gates)
	boss.died.connect(_drop_gates)
	# C10 — the Queen calls a thorn-guard at phase 3.
	boss.summon_wave.connect(func(count: int): _spawn_queen_summons(cx, cy, count))

	# Wire the boss bar (spec 17).
	var bossbar := get_node_or_null("BossBar")
	if bossbar != null:
		bossbar.set_boss_name(String(def.get("name", "The Hedgemother")))   # per-kind label
		boss.aggroed.connect(bossbar.show_boss)
		boss.boss_hp_changed.connect(bossbar.set_hp)
		boss.phase_changed.connect(bossbar.set_phase)
		boss.died.connect(bossbar.hide_boss)
		bossbar.prime(boss_hp)

	# Wyrd — dying to her must not seal the run forever (the exit waystone
	# only rises on her death). Offline, any death resets the encounter; in
	# co-op only a full party wipe does (spec 46 Phase B). Deferred wiring —
	# in a session the per-peer bodies spawn after this builder runs.
	_wire_party_reset.call_deferred(boss, bossbar)

func _wire_party_reset(boss: Node, bossbar: Node) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if (p as Node).has_signal("died"):
			(p as Node).died.connect(_party_reset_check.bind(boss, bossbar))

func _party_reset_check(boss: Node, bossbar: Node) -> void:
	var net := get_node_or_null("/root/NetGame")
	if net != null and bool(net.active):
		for p in get_tree().get_nodes_in_group("player"):
			if not bool((p as Node).get("dead")):
				return   # someone still stands — the fight goes on
	_drop_gates()
	if is_instance_valid(boss) and boss.has_method("reset_fight"):
		boss.reset_fight()
	if bossbar != null and is_instance_valid(bossbar):
		bossbar.hide_boss()

# Gate blocks at every "floor" tile on the boss-room perimeter — the
# openings. Built lowered/inert; raised when the boss aggros.
func _make_arena_gates(boss_room, grid: Array) -> Array:
	var gates: Array = []
	var bx := int(boss_room.x)
	var by := int(boss_room.y)
	var bw := int(boss_room.w)
	var bh := int(boss_room.h)
	var edge: Array = []
	for x in range(bx, bx + bw):
		edge.append(Vector2i(x, by))
		edge.append(Vector2i(x, by + bh - 1))
	for y in range(by, by + bh):
		edge.append(Vector2i(bx, y))
		edge.append(Vector2i(bx + bw - 1, y))
	for t in edge:
		if t.y < 0 or t.y >= grid.size():
			continue
		var row: Array = grid[t.y]
		if t.x < 0 or t.x >= row.size():
			continue
		if String(row[t.x]) != "floor":
			continue
		gates.append(_make_gate(t.x, t.y))
	return gates

func _make_gate(x: int, y: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = Vector3(x + 0.5, WALL_HEIGHT * 0.5, y + 0.5)
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, WALL_HEIGHT, 1.0)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.22, 0.30, 0.20)   # mossy bramble gate
	mi.material_override = gmat
	body.add_child(mi)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, WALL_HEIGHT, 1.0)
	var col := CollisionShape3D.new()
	col.name = "GateCol"
	col.shape = shape
	col.disabled = true
	body.add_child(col)
	body.visible = false
	add_child(body)
	return body

func _raise_gates() -> void:
	for g in _gates:
		if is_instance_valid(g):
			var body := g as StaticBody3D
			body.visible = true
			var c: Node = body.get_node_or_null("GateCol")
			if c != null:
				(c as CollisionShape3D).disabled = false

func _drop_gates() -> void:
	for g in _gates:
		if is_instance_valid(g):
			var body := g as StaticBody3D
			body.visible = false
			var c: Node = body.get_node_or_null("GateCol")
			if c != null:
				(c as CollisionShape3D).disabled = true

# ---- enemies ----
# Spec 25 Phase 5 — enemies spawn per room, by role + BFS depth: the crypt
# escalates from a calm entrance toward a dense run-up to the boss.
func _build_enemies(layout: Dictionary) -> int:
	const ElitesData = preload("res://data/elites.gd")
	var grid: Array = layout.grid
	var rooms: Array = layout.get("rooms", [])
	var depths: Array = layout.get("room_depths", [])
	var entry = layout.entry
	var exit = layout.exit
	# Wyrd — the chart's scope picks the spawn table (briar mazes crawl with
	# imps; snug cellars get rats). Unknown scopes read as crypt.
	var table: Array = SPAWN_TABLES.get(String(layout.get("scope", "crypt")),
		SPAWN_TABLES["crypt"])
	var ei := 0
	for ri in rooms.size():
		var r: Dictionary = rooms[ri]
		var role: String = r.get("role", "combat")
		# Spec 32 — boss room stays elite-free + enemy-free (the boss is the
		# whole encounter). Entrance never has enemies.
		if role == "entrance" or role == "boss":
			continue
		var depth: int = depths[ri] if ri < depths.size() else 0
		var n := 0
		match role:
			# Spec 32 — combat rooms now scale 4–10 trash per depth (was 2–5).
			"combat":   n = 4 + clampi(depth / 2, 0, 6)
			"treasure": n = 1                              # a guard
			"shrine":   n = _rng.randi_range(0, 1)
			"setpiece": n = 2
		# Wyrd — festival_pace density twins scale every populated room.
		if n > 0 and _density_mult != 1.0:
			n = maxi(1, roundi(n * _density_mult))
		var tiles := _room_floor_tiles(grid, r, entry, exit)
		if tiles.is_empty():
			continue
		# Spec 32 — elite roll. Combat rooms only; ~1 elite per 8 trash.
		# Picks which spawn index gets the elite + which modifier, then
		# adds 2–3 same-kind retinue alongside.
		var elite_idx := -1
		var elite_modifier: String = ""
		var elite_kind: String = _pick_kind(table)
		# C11 — deeper dens are eliter: the base chance rises with depth (capped).
		if role == "combat" and _rng.randf() < minf(0.6, float(n) / 8.0 + float(depth) * 0.02):
			elite_idx = _rng.randi_range(0, n - 1)
			elite_modifier = ElitesData.pick_random(_rng)
		for k in n:
			var t: Vector2i = tiles[_rng.randi_range(0, tiles.size() - 1)]
			if k == elite_idx:
				# Spawn the elite (forced to elite_kind so we can match the
				# retinue against the same enemy kind).
				var elite_body = _spawn_enemy(ei, t.x, t.y, role, depth, elite_kind)
				ei += 1
				if elite_body != null and elite_body.has_method("apply_elite"):
					elite_body.apply_elite(elite_modifier)
					# The chain's first link: the fiercer things sometimes
					# carry a thorn essence — the Hedgemother den's key.
					# B6 — marked_quarry doubles/halves the trophy odds. Roll
					# NOW off the seeded layout RNG (not a death-time randf()),
					# so every co-op peer agrees on which elites carry one — the
					# build sequence is identical across peers, runtime deaths
					# are not. (Fixes the bare-randf() co-op determinism bug.)
					var drops_trophy: bool = _rng.randf() < 0.25 * _trophy_mult
					elite_body.died.connect(func():
						if drops_trophy:
							var game := get_tree().root.get_node_or_null("Game")
							if game != null:
								game.add_material("thorn_essence", 1)
								game.notify("A thorn essence gleams in the wreckage."))
				# Retinue — 2–3 same-kind trash within ~2.5m of the elite.
				var retinue_count := _rng.randi_range(2, 2 + clampi(depth / 3, 0, 3))  # C11 — bigger packs deeper
				var elite_pos := Vector2(t.x, t.y)
				var near: Array = []
				for cand in tiles:
					if cand == t:
						continue
					if Vector2(cand.x, cand.y).distance_to(elite_pos) <= 2.5:
						near.append(cand)
				if near.is_empty():
					# Fall back: any tiles, sorted by distance to elite (nearest).
					near = tiles.duplicate()
					near.erase(t)
					near.sort_custom(func(a, b):
						return Vector2(a.x, a.y).distance_to(elite_pos) \
							< Vector2(b.x, b.y).distance_to(elite_pos))
				for ri_k in mini(retinue_count, near.size()):
					var rt: Vector2i = near[ri_k]
					_spawn_enemy(ei, rt.x, rt.y, role, depth, elite_kind)
					ei += 1
			else:
				_spawn_enemy(ei, t.x, t.y, role, depth, _pick_kind(table))
				ei += 1
	return ei

# Weighted pick from a [[kind, weight], ...] spawn table.
func _pick_kind(table: Array) -> String:
	var total := 0
	for row in table:
		total += int(row[1])
	var r := _rng.randi_range(1, maxi(1, total))
	for row in table:
		r -= int(row[1])
		if r <= 0:
			return String(row[0])
	return String(table[0][0])

func _room_floor_tiles(grid: Array, r: Dictionary, entry, exit) -> Array:
	var tiles: Array = []
	for yy in range(int(r.y), int(r.y) + int(r.h)):
		for xx in range(int(r.x), int(r.x) + int(r.w)):
			if yy < 0 or yy >= grid.size() or xx < 0 or xx >= grid[0].size():
				continue
			if String(grid[yy][xx]) != "floor":
				continue
			if xx == int(entry.x) and yy == int(entry.y):
				continue
			if xx == int(exit.x) and yy == int(exit.y):
				continue
			tiles.append(Vector2i(xx, yy))
	return tiles

# C10 — the Queen's phase-3 thorn-guard: a handful of skeleton adds around her.
# Host/offline only — dynamically-spawned adds don't ride the seed-build, so
# co-op guests don't see them yet (noted followup); no desync, just host-side.
func _spawn_queen_summons(cx: int, cy: int, count: int) -> void:
	var netb := get_node_or_null("/root/NetGame")
	if netb != null and bool(netb.active) and not bool(netb.is_host()):
		return
	var offsets := [Vector2i(-2, 1), Vector2i(2, 1), Vector2i(0, -2), Vector2i(-2, -1)]
	for i in mini(count, offsets.size()):
		var o: Vector2i = offsets[i]
		_spawn_enemy(900 + i, cx + o.x, cy + o.y, "combat", 9, "skeleton")

func _spawn_enemy(ei: int, tx: int, ty: int, role: String = "combat",
		depth: int = 0, forced_kind: String = "") -> CharacterBody3D:
	# Spec 32 — `forced_kind` lets the elite's retinue use the SAME kind as
	# the elite leader (Brambled skeleton → skeleton retinue).
	var kind := forced_kind if forced_kind != "" else "skeleton"
	var def: Dictionary = ENEMY_KINDS.get(kind, ENEMY_KINDS["skeleton"])
	var model: String = _resolve_model(String(def.model))
	var packed: PackedScene = load(model)
	if packed == null:
		return null
	var inst: Node3D = packed.instantiate()
	# Wyrd — tyrannical twins: good fattens every enemy ×1.5; the bad twin
	# (Erratic) rolls each enemy its own vigor — one factor drives BOTH the
	# visual scale and the HP so the variance is readable at a glance.
	var jitter := _rng.randf_range(0.7, 1.4) if _hp_jitter else 1.0
	if def.has("scale"):
		inst.scale = Vector3.ONE * float(def.scale) * jitter
	else:
		GlbFit.normalize_height(inst, float(def.fit_h) * jitter)
	_unmetal(inst)
	# Slice A — paint every kind with its archetype hue + ink outline so each
	# reads instantly (the raw GLBs are materialless grey otherwise). The elite
	# golden tint (combatant.gd) overrides on top of this — intended.
	if def.has("tint"):
		_tint(inst, def.tint, bool(def.get("ethereal", false)))
	var hp := maxi(4, roundi(int(def.hp) * _hp_mult * jitter))
	var body := _spawn_character(inst, tx, ty, 0.4, 1.4, hp)
	# B3 — per-kind feel: how hard it hits, how fast it closes, how often.
	body.damage = int(round(float(def.get("damage", 5)) * _dmg_mult))
	body.move_speed = float(def.get("speed", 1.8)) * _speed_mult
	body.attack_cooldown = float(def.get("atk_cd", 1.5)) / _atk_speed_mult
	body.aggro_radius = body.AGGRO_RADIUS * _aggro_mult
	# Phase 3 — ranged casters (the ghost lobs slow spectral orbs).
	body.is_ranged = bool(def.get("ranged", false))
	body.is_support = bool(def.get("support", false))   # warden heals its pack
	body.is_bruiser = bool(def.get("bruiser", false))   # barrow brute — AoE ring
	body.proj_speed = float(def.get("proj_speed", 9.0))
	body.proj_damage = int(def.get("proj_damage", body.damage))
	# B6 — bursting corpses.
	body.burst_on_death = _burst_on_death
	body.burst_hits_player = _burst_hits_player
	# Spec 27b — drop context (room role + BFS depth) drives the loot roll.
	body.role = role
	body.depth = depth
	# Unrigged critters scurry via the procedural hop-bob (spec 21 pattern).
	# Every enemy gets procedural life — breathing/sway at idle, a hop-bob when
	# moving — so the un-rigged cast (skeleton/ghost/hedge_sprite/Hedgemother)
	# no longer slides frozen in bind pose. Scurriers pass their own bob.
	var ra = CreatureAnimScript.new()
	if def.has("bob"):
		ra.setup(inst, float(def.bob[0]), float(def.bob[1]))
	else:
		ra.setup(inst)
	body._proc_anim = ra
	AnimDriverScript.play_idle(inst)
	return body

# Slice A — paint a kind with its archetype hue AND attach the ink outline.
# We build ONE shared painted material per call and override every mesh with
# it; the outline rides as its next_pass (so it deforms with skinned meshes).
# `ethereal` makes ghosts read as spirits: faint cool emission + light alpha.
func _tint(root: Node, color: Color, ethereal: bool = false) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	m.metallic = 0.0
	if ethereal:
		# Spirit cast — glows faintly and you can half-see through it. Kept
		# below the glow_hdr_threshold (1.0) so it shimmers without blooming out.
		m.emission_enabled = true
		m.emission = Color(0.40, 0.55, 0.78)
		m.emission_energy_multiplier = 0.45
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(color.r, color.g, color.b, 0.72)
	m.next_pass = _make_outline_pass()
	for vi in _all_visual_instances(root):
		if vi is MeshInstance3D:
			(vi as MeshInstance3D).material_override = m

# Slice A — the inverted-hull outline shell as a StandardMaterial3D, returned
# fresh so callers can attach it as `next_pass` on a material they own. Front
# faces are culled and the hull is grown along normals, so what remains is a
# dark rim hugging the silhouette. UNSHADED keeps the ink flat at any light.
func _make_outline_pass() -> StandardMaterial3D:
	var o := StandardMaterial3D.new()
	o.grow = true
	o.grow_amount = OUTLINE_GROW
	o.cull_mode = BaseMaterial3D.CULL_FRONT
	o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	o.albedo_color = OUTLINE_INK
	return o

# Slice A — give the boss the same ink rim WITHOUT flattening its own GLB
# textures. We chain the outline onto each surface's real material (via a
# duplicate so we don't mutate the shared GLB resource); kinds with no surface
# material fall back to a material_override carrying the outline.
func _outline_only(root: Node) -> void:
	for vi in _all_visual_instances(root):
		if not (vi is MeshInstance3D):
			continue
		var mi := vi as MeshInstance3D
		var mesh: Mesh = mi.mesh
		var painted := false
		if mesh != null:
			for s in range(mesh.get_surface_count()):
				var base := mi.get_active_material(s)
				if base is BaseMaterial3D:
					var dup := (base as BaseMaterial3D).duplicate() as BaseMaterial3D
					dup.next_pass = _make_outline_pass()
					mi.set_surface_override_material(s, dup)
					painted = true
		if not painted:
			# Materialless surface — give it a neutral plate to host the outline.
			var fallback := StandardMaterial3D.new()
			fallback.albedo_color = Color(0.70, 0.66, 0.60)
			fallback.roughness = 0.85
			fallback.next_pass = _make_outline_pass()
			mi.material_override = fallback

# Wrap a character GLB in a Combatant (CharacterBody3D, spec 15) — a moving
# body on the ENEMIES layer + HP + hurtbox + chase/attack AI. Group "enemy".
# `char_script` lets the boss spawn as a Boss (spec 17). Returns the body.
func _spawn_character(inst: Node3D, tx: int, ty: int, radius: float, height: float, hp: int, char_script := CombatantScript) -> CharacterBody3D:
	var body: CharacterBody3D = char_script.new()
	# Phase B — deterministic names: builds are seed-identical per peer, so
	# "NetFoe<N>" is the same body everywhere; the host's state snapshots
	# address puppets by this name.
	_net_foe_idx += 1
	body.name = "NetFoe%d" % _net_foe_idx
	var netb := get_node_or_null("/root/NetGame")
	if netb != null and bool(netb.active) and not multiplayer.is_server():
		body.set("net_puppet", true)
	body.position = Vector3(tx + 0.5, 0.0, ty + 0.5)
	body.collision_layer = LAYER_ENEMIES
	# Collide with world (walls/floor) + the player; enemy↔enemy passes through.
	body.collision_mask = 1 | 2
	body.add_to_group("enemy")
	body.add_child(inst)
	# Blocking capsule (player can't walk through the body).
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(col)
	add_child(body)
	# Combatant init — caches meshes for the flash, builds the hurtbox.
	body.cache_meshes()
	body.setup(hp, radius, height)
	return body

# ---- Wyrd: the far waystone (the run's exit) ----
# No boss → it stands ready at the exit tile from the start, with a reward
# chest beside it (the chest replaces the boss as the deep room's payoff).
# With a boss, the waystone rises only when she falls — the boss loot pile
# is the reward and the arena seal owns the room until then.
func _build_exit_waystone(layout: Dictionary) -> void:
	var exit = layout.get("exit", null)
	if exit == null:
		return
	var pos := Vector3(int(exit.x) + 0.5, 0.0, int(exit.y) + 0.5)
	if String(layout.get("bossKind", "")) != "" and _boss_body != null:
		var spawn := func():
			var ws: Node3D = ExitWaystoneScript.new()
			ws.position = pos
			add_child(ws)
		_boss_body.died.connect(spawn)
	else:
		var ws: Node3D = ExitWaystoneScript.new()
		ws.position = pos
		add_child(ws)
		_build_exit_chest(layout, exit)
	# Spec 45-gaps — the way you came in always works: an abandon stone at
	# the entry pays nothing but ends the run. Without it an inked boss
	# chart soft-locked anyone who couldn't fell the boss.
	var entry = layout.get("entry", null)
	if entry != null:
		var home: Node3D = ExitWaystoneScript.new()
		home.abandoning = true
		home.position = Vector3(int(entry.x) + 0.5 + 1.6, 0.0,
			int(entry.y) + 0.5 + 1.6)
		add_child(home)

# A depth-scaled reward chest on a floor tile beside the exit waystone.
func _build_exit_chest(layout: Dictionary, exit) -> void:
	var grid: Array = layout.grid
	var depth := 0
	for d in layout.get("room_depths", []):
		depth = maxi(depth, int(d))
	for off in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
			Vector2i(1, 1), Vector2i(-1, -1)]:
		var x: int = int(exit.x) + off.x
		var y: int = int(exit.y) + off.y
		if y < 1 or y >= grid.size() - 1 or x < 1 or x >= grid[0].size() - 1:
			continue
		if String(grid[y][x]) != "floor":
			continue
		var c := ChestScene.instantiate()
		c.depth = depth
		add_child(c)
		c.global_position = Vector3(x + 0.5, 0.0, y + 0.5)
		return

# Wyrd — a boss-den's bad twin promises a visible abandoned lair (empty
# throne / fresh-dug wallow / cold roost); stamp a sarcophagus off-centre
# so the den isn't bare.
func _build_empty_throne(layout: Dictionary) -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	if not (game.affix_bad("hedgemother_den") or game.affix_bad("burrow_boar_den")
			or game.affix_bad("wolf_alpha_den")):
		return
	var boss_room = layout.get("bossRoom", null)
	if boss_room == null:
		return
	var grid: Array = layout.grid
	var cx: int = int(boss_room.x) + int(int(boss_room.w) / 2.0)
	var cy: int = int(boss_room.y) + int(int(boss_room.h) / 2.0) - 2
	if cy < 1 or cy >= grid.size() - 1 or String(grid[cy][cx]) != "floor":
		return
	var packed: PackedScene = load(DECOR_MODEL["sarcophagus"])
	if packed == null:
		return
	var inst: Node3D = packed.instantiate()
	inst.position = Vector3(cx + 0.5, 0.05, cy + 0.5)
	add_child(inst)

func _position_player(entry) -> void:
	_entry_pos = Vector3(int(entry.x) + 0.5, 0.0, int(entry.y) + 0.5)
	var game := get_node_or_null("/root/Game")
	var player: Node = game.local_player() if game != null else null
	if player != null and player is Node3D:
		(player as Node3D).position = _entry_pos
		# Hand the player its spawn so death can respawn it here (spec 15).
		if player.has_method("set_spawn"):
			player.set_spawn(_entry_pos)

func _debug_screenshot() -> void:
	await get_tree().create_timer(0.6).timeout
	var path := OS.get_environment("WYRD_SHOT_PATH")
	if path == "":
		path = "/tmp/godot_selfshot.png"
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("[layout_loader] debug screenshot → %s (err=%d)" % [path, err])

# Meshy GLB materials carry a metallic value the web Compatibility renderer
# blows out into chrome — zero it so they render matte in both renderers.
func _unmetal(root: Node) -> void:
	for vi in _all_visual_instances(root):
		if vi is MeshInstance3D:
			var m: Mesh = (vi as MeshInstance3D).mesh
			if m == null:
				continue
			for s in range(m.get_surface_count()):
				var mat := m.surface_get_material(s)
				if mat is BaseMaterial3D:
					(mat as BaseMaterial3D).metallic = 0.0
					(mat as BaseMaterial3D).metallic_specular = 0.2

func _all_visual_instances(node: Node) -> Array:
	var out := []
	if node is VisualInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_all_visual_instances(c))
	return out
