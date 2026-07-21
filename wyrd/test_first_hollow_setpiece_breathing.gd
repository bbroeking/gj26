extends SceneTree

# Spec 73 — the authored First Road larder keeps its discovery identity without
# rebuilding a full-scale boulder barricade inside a procedural clearing.

const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const ChartsData = preload("res://data/charts.gd")

var passed := 0
var failed := 0

func check(label: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, str(detail)])

func _initialize() -> void:
	print("--- First Hollow setpiece breathing ---")
	var first := _layout(26072026)
	var replay := _layout(26072026)
	check("same seed reproduces the larder support composition", first.decor == replay.decor)
	var found := 0
	var reservations := 0
	var scaled := true
	var clear := true
	for room_v in first.rooms:
		var room: Dictionary = room_v
		if String(room.get("role", "")) != "setpiece":
			continue
		for decor_v in first.decor:
			var decor: Dictionary = decor_v
			if not bool(decor.get("setpiece_support", false)):
				continue
			if bool(decor.get("presentation_hidden", false)):
				reservations += 1
				continue
			found += 1
			scaled = scaled and is_equal_approx(float(decor.get("visual_scale", 1.0)), 0.62)
			clear = clear and not DungeonGenScript._inside_room_approach(
				room, int(decor.x), int(decor.y), first.grid)
	check("larder remains visibly dressed", found >= 4, found)
	check("hidden approach marks preserve encounter placement", reservations >= 1, reservations)
	check("larder supports use the forest support scale", scaled)
	check("larder supports clear every room landing", clear)

	var other_cfg: Dictionary = (ChartsData.TEMPLATES.first_road.gen as Dictionary).duplicate(true)
	other_cfg.merge({"scope": "hollow", "template_id": "tier_1", "tier": 1}, true)
	var other := DungeonGenScript.generate(26072026, other_cfg)
	var isolated := true
	for decor_v in other.decor:
		isolated = isolated and not (decor_v as Dictionary).has("setpiece_support")
	check("later setpieces do not inherit the First Road contract", isolated)
	print("--- First Hollow setpiece breathing: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _layout(seed: int) -> Dictionary:
	var cfg: Dictionary = (ChartsData.TEMPLATES.first_road.gen as Dictionary).duplicate(true)
	cfg.merge({"scope": "snug", "template_id": "first_road", "tier": 1,
		"affixes": [
			{"id": "tyrannical", "good": true, "resolvedId": "tyrannical"},
			{"id": "elite_signs", "good": true, "resolvedId": "elite_signs"},
			{"id": "gilded", "good": true, "resolvedId": "gilded"},
		]}, true)
	return DungeonGenScript.generate(seed, cfg)
