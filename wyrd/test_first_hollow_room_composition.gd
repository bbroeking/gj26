extends SceneTree

# Spec 71 — the generated First Road graph chooses authored room archetypes,
# and those archetypes now own visible forest composition rather than inheriting
# generic crypt-era room themes.

const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const ChartsData = preload("res://data/charts.gd")

const EXPECTED_THEME := {
	"lantern_landing": "first_lantern_landing",
	"round_glade": "first_round_glade",
	"crooked_bower": "first_crooked_bower",
	"long_clearing": "first_long_clearing",
}
const EXPECTED_FOCAL := {
	"first_lantern_landing": "altar",
	"first_round_glade": "bookshelf",
	"first_crooked_bower": "column",
	"first_long_clearing": "sarcophagus",
}

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
	print("--- First Hollow room composition ---")
	var first := _layout(26072026)
	var replay := _layout(26072026)
	check("same seed reproduces rooms and decor",
		first.rooms == replay.rooms and first.decor == replay.decor)

	var found_themes := {}
	var archetypes_visible := true
	var apertures_clear := true
	for room_v in first.rooms:
		var room: Dictionary = room_v
		var role := String(room.get("role", ""))
		if role != "entrance" and role != "combat":
			continue
		var archetype := String(room.get("archetype", ""))
		var expected_theme := String(EXPECTED_THEME.get(archetype, ""))
		var actual_theme := String(room.get("theme", ""))
		archetypes_visible = archetypes_visible and expected_theme != "" \
			and actual_theme == expected_theme
		found_themes[actual_theme] = true
		var focal_kind := String(EXPECTED_FOCAL.get(actual_theme, ""))
		var has_focal := false
		for decor_v in first.decor:
			var decor: Dictionary = decor_v
			var x := int(decor.x)
			var y := int(decor.y)
			if x >= int(room.x) and x < int(room.x) + int(room.w) \
					and y >= int(room.y) and y < int(room.y) + int(room.h):
				if bool(decor.get("focal", false)) and String(decor.kind) == focal_kind:
					has_focal = true
				if role == "combat" and DungeonGenScript._inside_protected_aperture(room, x, y):
					apertures_clear = false
		archetypes_visible = archetypes_visible and has_focal
	check("arrival and combat rooms expose their authored forest theme",
		archetypes_visible, found_themes.keys())
	check("combat compositions preserve the protected aiming aperture", apertures_clear)

	var sampled_themes := {}
	for seed in [26072026, 26072027, 26072028, 26072029, 26072030, 26072031]:
		for room_v in _layout(seed).rooms:
			var room: Dictionary = room_v
			if String(room.get("theme", "")).begins_with("first_"):
				sampled_themes[String(room.theme)] = true
	check("seed sample remixes at least four authored composition kits",
		sampled_themes.size() >= 4, sampled_themes.keys())

	var other_cfg: Dictionary = (ChartsData.TEMPLATES.first_road.gen as Dictionary).duplicate(true)
	other_cfg.merge({"scope": "hollow", "template_id": "tier_1", "tier": 1}, true)
	var other := DungeonGenScript.generate(26072026, other_cfg)
	var isolated := true
	for room_v in other.rooms:
		isolated = isolated and not String((room_v as Dictionary).get("theme", "")).begins_with("first_")
	check("later biomes do not inherit the First Road composition kit", isolated)

	print("--- First Hollow room composition: %d PASS, %d FAIL ---" % [passed, failed])
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
