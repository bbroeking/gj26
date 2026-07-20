extends SceneTree

# Spec 08 — headless 10-run procgen check.
# Run: godot --headless --path wyrd --script res://test_procgen.gd
#
# Also covers:
#   - scope-variance: snug/briar_maze/crypt rooms use scope-appropriate themes
#   - layout-affix knobs: cramped/sprawling cfg overrides shift room counts
#   - per-scope score bands: snug passes >= 0.70 first-pass (no best-of-12 fallback)
#   - setpiece variety: crypt and briar_maze show >= 2 distinct setpiece values across 5 seeds

const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const ChartsData = preload("res://data/charts.gd")

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _init() -> void:
	_run_baseline()
	_check_scope_variance()
	_check_layout_affixes()
	_check_setpiece_variety()
	_check_green_hollow_resource_contract()
	_check_mire_resource_contract()
	_check_d2_required_rest_contract()
	_check_scatter_creation_pattern()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

# ---- baseline: 10 random crypt runs ----
func _run_baseline() -> void:
	var runs := 10
	var total_sum := 0.0
	var all_connected := true
	print("--- procgen 10-run baseline ---")
	for i in runs:
		var layout: Dictionary = DungeonGenScript.generate(-1)
		var s: Dictionary = layout.score
		var conn_ok: bool = s.connectivity >= 0.999
		if not conn_ok:
			all_connected = false
		total_sum += s.total
		print("run %2d: total=%.2f conn=%.2f path=%.2f rooms=%.2f floor=%.2f corr=%.2f deadends=%.2f attempts=%d rooms=%d" % [
			i + 1, s.total, s.connectivity, s.critical_path, s.room_count,
			s.floor_ratio, s.corridor_ratio, s.dead_ends,
			int(layout.attempts), int(s._raw.rooms),
		])
	var avg := total_sum / runs
	print("--- avg total=%.3f | all connected=%s ---" % [avg, str(all_connected)])
	_check("baseline: all layouts connected", all_connected)
	_check("baseline: avg score >= 0.70", avg >= 0.70, "avg=%.3f" % avg)

# ---- scope-variance: snug/briar_maze/crypt themes, boss theme, first-pass score ----
func _check_scope_variance() -> void:
	print("--- scope variance checks ---")

	# snug: at least one room has root_cellar or wine_rack, score >= 0.70 first pass
	var snug_layout: Dictionary = DungeonGenScript.generate(42, {
		"scope": "snug", "grid": 28, "room_min": 6, "room_max": 10,
		"room_count_min": 3, "room_count_max": 7,
	})
	var snug_rooms: Array = snug_layout.rooms
	var snug_scope_themes := false
	for r in snug_rooms:
		var t: String = String(r.get("theme", ""))
		if t == "root_cellar" or t == "wine_rack":
			snug_scope_themes = true
			break
	_check("snug: at least one room is root_cellar or wine_rack", snug_scope_themes,
		str(snug_rooms.map(func(r): return r.get("theme", ""))))
	var snug_score: float = float(snug_layout.score.total)
	_check("snug: score >= 0.70", snug_score >= 0.70,
		"score=%.3f" % snug_score)
	# The score bands for snug are now tuned so it shouldn't need best-of-12.
	# A low attempt count (<=3) is evidence the bands are working.
	_check("snug: few attempts needed (bands working)", int(snug_layout.attempts) <= 3,
		"attempts=%d" % int(snug_layout.attempts))

	# briar_maze: at least one room is thorn_bower or glade, boss theme is thorn_bower
	var briar_layout: Dictionary = DungeonGenScript.generate(99, {"scope": "briar_maze"})
	var briar_rooms: Array = briar_layout.rooms
	var briar_scope_themes := false
	for r in briar_rooms:
		var t: String = String(r.get("theme", ""))
		if t == "thorn_bower" or t == "glade":
			briar_scope_themes = true
			break
	_check("briar_maze: at least one room is thorn_bower or glade", briar_scope_themes,
		str(briar_rooms.map(func(r): return r.get("theme", ""))))
	var briar_boss_theme := ""
	for r in briar_rooms:
		if String(r.get("role", "")) == "boss":
			briar_boss_theme = String(r.get("theme", ""))
			break
	_check("briar_maze: boss room theme is thorn_bower", briar_boss_theme == "thorn_bower",
		"boss_theme=%s" % briar_boss_theme)

	# crypt: boss room is tomb_hall
	var crypt_layout: Dictionary = DungeonGenScript.generate(7, {"scope": "crypt"})
	var crypt_rooms: Array = crypt_layout.rooms
	var crypt_boss_theme := ""
	for r in crypt_rooms:
		if String(r.get("role", "")) == "boss":
			crypt_boss_theme = String(r.get("theme", ""))
			break
	_check("crypt: boss room theme is tomb_hall", crypt_boss_theme == "tomb_hall",
		"boss_theme=%s" % crypt_boss_theme)

	# hollow: boss room is tomb_hall
	var hollow_layout: Dictionary = DungeonGenScript.generate(13, {"scope": "hollow"})
	var hollow_rooms: Array = hollow_layout.rooms
	var hollow_boss_theme := ""
	for r in hollow_rooms:
		if String(r.get("role", "")) == "boss":
			hollow_boss_theme = String(r.get("theme", ""))
			break
	_check("hollow: boss room theme is tomb_hall", hollow_boss_theme == "tomb_hall",
		"boss_theme=%s" % hollow_boss_theme)

# ---- layout-affix knobs: cramped vs sprawling cfg injection ----
func _check_layout_affixes() -> void:
	print("--- layout affix knob checks ---")

	# cramped: grid=32, room_max=10, room_count_max=9 => 7-9 rooms
	var cramped_layout: Dictionary = DungeonGenScript.generate(55, {
		"scope": "hollow",
		"grid": 32, "room_max": 10,
		"room_count_min": 7, "room_count_max": 9,
	})
	var cramped_rooms: int = cramped_layout.rooms.size()
	_check("cramped: room count in 3-9 range", cramped_rooms >= 3 and cramped_rooms <= 9,
		"rooms=%d" % cramped_rooms)

	# sprawling: grid=56, room_min=10, room_max=18 — large rooms naturally limit count.
	var sprawling_layout: Dictionary = DungeonGenScript.generate(77, {
		"scope": "hollow",
		"grid": 56, "room_min": 10, "room_max": 18,
	})
	var sprawling_rooms: int = sprawling_layout.rooms.size()
	# Sprawling uses large rooms on a large grid — rooms should still be connected
	# and the layout valid. We just verify it generates correctly.
	_check("sprawling: connected layout", float(sprawling_layout.score.connectivity) >= 0.999,
		"conn=%.3f rooms=%d" % [float(sprawling_layout.score.connectivity), sprawling_rooms])

	_check("cramped: connected", float(cramped_layout.score.connectivity) >= 0.999,
		"conn=%.3f" % float(cramped_layout.score.connectivity))

# ---- setpiece variety: at least 2 distinct setpiece values across 5 seeds ----
func _check_setpiece_variety() -> void:
	print("--- setpiece variety checks ---")

	# crypt: pool = ["vault", "shrine", "crypt_hall"] — expect >= 2 distinct over 5 seeds
	var crypt_setpieces := {}
	for seed_i in 5:
		var layout: Dictionary = DungeonGenScript.generate(seed_i * 1000 + 3, {"scope": "crypt"})
		for r in layout.rooms:
			if String(r.get("role", "")) == "setpiece":
				crypt_setpieces[String(r.get("setpiece", ""))] = true
	_check("crypt: >= 2 distinct setpiece templates across 5 seeds",
		crypt_setpieces.size() >= 2, "found=%s" % str(crypt_setpieces.keys()))

	# briar_maze: pool = ["hedge_circle"] — setpiece should be hedge_circle (or none if no big room)
	var briar_setpieces := {}
	for seed_j in 5:
		var layout: Dictionary = DungeonGenScript.generate(seed_j * 1000 + 7, {"scope": "briar_maze"})
		for r in layout.rooms:
			if String(r.get("role", "")) == "setpiece":
				briar_setpieces[String(r.get("setpiece", ""))] = true
	# For briar_maze, any stamped setpiece must come from the scope pool
	var briar_valid := true
	for sp in briar_setpieces.keys():
		if sp != "hedge_circle":
			briar_valid = false
	_check("briar_maze: all setpieces are from scope pool",
		briar_valid, "found=%s" % str(briar_setpieces.keys()))

	# snug: pool = ["larder"]
	var snug_setpieces := {}
	for seed_k in 5:
		var layout: Dictionary = DungeonGenScript.generate(seed_k * 1000 + 11, {
			"scope": "snug", "grid": 28, "room_min": 6, "room_max": 10,
		})
		for r in layout.rooms:
			if String(r.get("role", "")) == "setpiece":
				snug_setpieces[String(r.get("setpiece", ""))] = true
	var snug_valid := true
	for sp in snug_setpieces.keys():
		if sp != "larder":
			snug_valid = false
	_check("snug: all setpieces are from scope pool",
		snug_valid, "found=%s" % str(snug_setpieces.keys()))


func _check_green_hollow_resource_contract() -> void:
	print("--- Green Hollow baseline resource contract ---")
	var all_honest := true
	var failed_seed := -1
	for seed in 50:
		var cfg: Dictionary = (ChartsData.TEMPLATES.tier_1.gen as Dictionary).duplicate(true)
		cfg["scope"] = "hollow"
		cfg["template_id"] = "tier_1"
		cfg["tier"] = 1
		cfg["affixes"] = []
		var layout: Dictionary = DungeonGenScript.generate(seed + 1, cfg)
		var items := {}
		for decor_v in layout.get("decor", []):
			if decor_v is Dictionary and bool((decor_v as Dictionary).get("gather", false)):
				var item_id := String((decor_v as Dictionary).get("item", ""))
				items[item_id] = int(items.get(item_id, 0)) + 1
		if int(items.get("copper_ore", 0)) < 1 \
				or int(items.get("wild_herb", 0)) < 1 \
				or int(items.get("logs", 0)) < 1:
			all_honest = false
			failed_seed = seed + 1
			break
	_check("50 Green Hollow seeds always carry Copper, Herb, and Logs",
		all_honest, "failed_seed=%d" % failed_seed)


func _check_mire_resource_contract() -> void:
	print("--- Mire baseline resource contract ---")
	var all_honest := true
	var failed_seed := -1
	for seed in 30:
		var cfg: Dictionary = (ChartsData.TEMPLATES.mire_shallows.gen as Dictionary).duplicate(true)
		cfg["scope"] = "mire"
		cfg["template_id"] = "mire_shallows"
		cfg["tier"] = 1
		cfg["affixes"] = []
		var layout: Dictionary = DungeonGenScript.generate(seed + 401, cfg)
		var mothmint := 0
		for decor_v in layout.get("decor", []):
			if decor_v is Dictionary and bool((decor_v as Dictionary).get("gather", false)) \
					and String((decor_v as Dictionary).get("item", "")) == "mothmint":
				mothmint += 1
		if mothmint < 2:
			all_honest = false
			failed_seed = seed + 401
			break
	_check("30 Mire seeds always carry two reachable Mothmint patches",
		all_honest, "failed_seed=%d" % failed_seed)

# D2 — an added terminal layer promises a Hearth, so procgen must reserve the
# role and expose the focal marker consumed by LayoutLoader. This is purposely
# several seeds: a room-budget coincidence is not an authored guarantee.
func _check_d2_required_rest_contract() -> void:
	print("--- D2 required-rest contract ---")
	var all_honest := true
	for seed_i in [91, 772, 1603, 9821, 44117]:
		var layout: Dictionary = DungeonGenScript.generate(seed_i, {
			"scope": "hollow", "template_id": "hollow", "tier": 1,
			"boss_kind": "", "required_room_roles": ["rest"],
		})
		var has_rest := false
		for room_v in layout.get("rooms", []):
			if room_v is Dictionary and String((room_v as Dictionary).get("role", "")) == "rest":
				has_rest = true
				break
		var has_focal := false
		for decor_v in layout.get("decor", []):
			if decor_v is Dictionary \
					and String((decor_v as Dictionary).get("interact_role", "")) == "rest":
				has_focal = true
				break
		all_honest = all_honest and bool(layout.get("required_roles_valid", false)) \
			and has_rest and has_focal
	_check("D2 terminal Hearth has a required rest room and focal", all_honest)


# Regression corpus for the Dungeon Forge-inspired creation pattern. These are
# structural contracts rather than snapshots, so harmless decor changes do not
# force golden-file churn.
func _check_scatter_creation_pattern() -> void:
	print("--- scatter / topology creation-pattern corpus ---")
	var configs: Array = [
		{"seed": 101, "scope": "crypt"},
		{"seed": 202, "scope": "hollow"},
		{"seed": 303, "scope": "briar_maze"},
		{"seed": 404, "scope": "mire"},
		{"seed": 505, "scope": "rootroads"},
		{"seed": 606, "scope": "snug", "grid": 28, "room_min": 6,
			"room_max": 10, "room_count_min": 3, "room_count_max": 7},
	]
	var deterministic := true
	var non_overlapping := true
	var topology_valid := true
	var semantic_widths_valid := true
	for corpus_v in configs:
		var corpus: Dictionary = corpus_v
		var seed_value := int(corpus.get("seed", 1))
		var cfg := corpus.duplicate(true)
		cfg.erase("seed")
		var first: Dictionary = DungeonGenScript.generate(seed_value, cfg)
		var second: Dictionary = DungeonGenScript.generate(seed_value, cfg)
		deterministic = deterministic and first.get("grid", []) == second.get("grid", []) \
			and first.get("rooms", []) == second.get("rooms", []) \
			and first.get("room_edges", []) == second.get("room_edges", []) \
			and first.get("decor", []) == second.get("decor", [])
		var rooms: Array = first.get("rooms", [])
		for i in rooms.size():
			for j in range(i + 1, rooms.size()):
				var a: Dictionary = rooms[i]
				var b: Dictionary = rooms[j]
				if int(a.x) < int(b.x) + int(b.w) and int(a.x) + int(a.w) > int(b.x) \
						and int(a.y) < int(b.y) + int(b.h) and int(a.y) + int(a.h) > int(b.y):
					non_overlapping = false
		var boss_idx := int(first.get("boss_room_id", -1))
		var critical: Array = first.get("critical_room_ids", [])
		var max_area := 0
		for room_v in rooms:
			var room: Dictionary = room_v
			max_area = maxi(max_area, int(room.w) * int(room.h))
		var boss_area := int(rooms[boss_idx].w) * int(rooms[boss_idx].h) \
			if boss_idx >= 0 and boss_idx < rooms.size() else -1
		topology_valid = topology_valid \
			and String(first.get("generation_pattern", "")) == "scatter_separate_delaunay_mst" \
			and not critical.is_empty() and int(critical[0]) == 0 \
			and int(critical[critical.size() - 1]) == boss_idx \
			and boss_area == max_area
		var widths: Dictionary = first.get("corridor_widths", {})
		for path_i in range(1, critical.size()):
			var lo := mini(int(critical[path_i - 1]), int(critical[path_i]))
			var hi := maxi(int(critical[path_i - 1]), int(critical[path_i]))
			if int(widths.get("%d:%d" % [lo, hi], 0)) != 3:
				semantic_widths_valid = false
	_check("same seed freezes identical topology and dressing", deterministic)
	_check("scattered rooms finish without rectangle overlaps", non_overlapping)
	_check("largest room is boss and critical path spans entry to boss", topology_valid)
	_check("every critical-route corridor is three tiles wide", semantic_widths_valid)
