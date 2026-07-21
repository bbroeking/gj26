extends SceneTree

# Spec 72 — First Road support dressing stays subordinate to landmarks and
# leaves a readable arrival landing at every corridor mouth.

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
	print("--- First Hollow room breathing ---")
	var replay_a := _layout(26072026)
	var replay_b := _layout(26072026)
	check("same seed reproduces scaled support composition",
		replay_a.decor == replay_b.decor)

	var supports := 0
	var landmarks_unscaled := true
	var approaches_clear := true
	var blocked = null
	for seed in [26072026, 26072027, 26072028, 26072029, 26072030, 26072031]:
		var layout := _layout(seed)
		for decor_v in layout.decor:
			var decor: Dictionary = decor_v
			var owner: Dictionary = _room_at(layout.rooms, int(decor.x), int(decor.y))
			if owner.is_empty() or not String(owner.get("theme", "")).begins_with("first_"):
				continue
			if bool(decor.get("focal", false)):
				landmarks_unscaled = landmarks_unscaled and not decor.has("visual_scale")
			elif decor.has("visual_scale"):
				supports += 1
				if not is_equal_approx(float(decor.get("visual_scale", 1.0)), 0.62):
					approaches_clear = false
					blocked = {"reason": "support scale", "decor": decor}
				if DungeonGenScript._inside_room_approach(owner, int(decor.x),
						int(decor.y), layout.grid):
					approaches_clear = false
					blocked = {"reason": "approach", "room": owner.id, "decor": decor}
	check("sample retains restrained supporting dressing", supports >= 24, supports)
	check("forest landmarks remain full-size", landmarks_unscaled)
	check("support props are scaled and clear every room landing",
		approaches_clear, blocked)

	var other_cfg: Dictionary = (ChartsData.TEMPLATES.first_road.gen as Dictionary).duplicate(true)
	other_cfg.merge({"scope": "hollow", "template_id": "tier_1", "tier": 1}, true)
	var other := DungeonGenScript.generate(26072026, other_cfg)
	var isolated := true
	for decor_v in other.decor:
		isolated = isolated and not (decor_v as Dictionary).has("visual_scale")
	check("later biome composition does not inherit support scaling", isolated)

	print("--- First Hollow room breathing: %d PASS, %d FAIL ---" % [passed, failed])
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


func _room_at(rooms: Array, x: int, y: int) -> Dictionary:
	for room_v in rooms:
		var room: Dictionary = room_v
		if x >= int(room.x) and x < int(room.x) + int(room.w) \
				and y >= int(room.y) and y < int(room.y) + int(room.h):
			return room
	return {}
