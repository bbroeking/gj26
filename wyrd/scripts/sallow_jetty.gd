class_name SallowJetty
extends Interactable

# Golden Wallow's settlement payoff and alternate Mire launch point. Campaign
# truth is injected as a read-only projection; the only gameplay mutation is
# delegated to Game.enter_dungeon, the same authority used by the Waystone.

const JETTY_GLB := preload("res://models/building_sallow_jetty_v1.glb")

var _chapter_view: Dictionary = {}
var _read_only := false
var _built := false


func set_settlement_view(view: Dictionary) -> void:
	var chapters = view.get("chapters", {})
	var raw = (chapters as Dictionary).get("golden_wallow", {}) \
		if chapters is Dictionary else view.get("golden_wallow", {})
	_chapter_view = (raw as Dictionary).duplicate(true) if raw is Dictionary else {}
	_read_only = bool(view.get("read_only", false)) or bool(view.get("guest", false))
	visible = bool(view.get("available", true)) \
		and bool(_chapter_view.get("visible", false)) \
		and bool(_chapter_view.get("restoration_visible", false))
	if is_node_ready() and visible and not _built:
		_build_jetty()


func restoration_ids() -> Dictionary:
	return {
		"restoration_id": String(_chapter_view.get("restoration_id", "")),
		"relic_id": String(_chapter_view.get("relic_id", "")),
	}


func launch_verb() -> String:
	return "Launch held Mire Chart"


func get_prompt_text() -> String:
	return "[E/A] Inspect the host's restored Jetty" if _read_only \
		else "[E/A] Launch a held Mire Chart"


func get_prompt_color() -> Color:
	return Color(0.45, 0.86, 0.72)


func get_collision_radius() -> float:
	return 2.25


func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.5, 0.7)


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.7, 0.6)


func get_solid_radius() -> float:
	return 1.45


func get_solid_height() -> float:
	return 1.1


func _ready_interactable() -> void:
	add_to_group("sallow_jetty")
	if visible:
		_build_jetty()


func _build_jetty() -> void:
	if _built:
		return
	_built = true
	var model := JETTY_GLB.instantiate()
	model.name = "SallowJettyModel"
	add_child(model)
	GlbFit.add_ink_outline(model)


func launchable_chart_indices() -> Array[int]:
	var out: Array[int] = []
	var game := _game()
	if game == null:
		return out
	var held = game.get("charts")
	if not held is Array:
		return out
	for index in (held as Array).size():
		var chart = (held as Array)[index]
		if not chart is Dictionary:
			continue
		var recipe_id := String((chart as Dictionary).get("recipe_id", ""))
		var scope := String((chart as Dictionary).get("scope", ""))
		var biome_id := String((chart as Dictionary).get("biome_id", ""))
		var template_id := String((chart as Dictionary).get("template_id", ""))
		if scope == "mire" or biome_id == "sallow_mire" \
				or template_id in ["mire", "mire_shallows"] \
				or recipe_id in ["sallow_shallows", "sallow_mire", "golden_wallow_boss"]:
			out.append(index)
	return out


func interact(player: Node) -> void:
	var game := _game()
	if game == null or not visible or not bool(_chapter_view.get("visible", false)) \
			or not bool(_chapter_view.get("restoration_visible", false)):
		return
	if _read_only:
		if game.has_method("notify"):
			game.notify("Only the fire-keeper may launch a Mire Chart from this Jetty.")
		return
	var candidates := launchable_chart_indices()
	if candidates.is_empty():
		if game.has_method("notify"):
			game.notify("The restored Jetty needs a held Mire Chart.")
		return
	var held = game.get("charts")
	var chart: Dictionary = (held as Array)[int(candidates[0])]
	# Game owns host authority, escrow, Chart removal, and scene transition.
	game.enter_dungeon(chart, player)


func _game() -> Node:
	return get_tree().root.get_node_or_null("Game") if is_inside_tree() else null
