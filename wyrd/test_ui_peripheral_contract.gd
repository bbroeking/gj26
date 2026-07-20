extends SceneTree

# Spec 59 peripheral gate: small overlays still use the Field Journal system,
# preserve domain/modal authority, and remain operable beyond the mouse.

const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

var _failures: Array[String] = []


class TestRig extends Node:
	var frame := {"focus": Vector3.ZERO, "yaw": 0.0, "pitch": 38.0, "zoom": 16.5}
	var cinematic_active := false

	func cinematic_frame() -> Dictionary:
		return frame.duplicate(true)

	func begin_cinematic() -> void:
		cinematic_active = true

	func apply_cinematic_frame(next: Dictionary) -> void:
		frame = next.duplicate(true)

	func end_cinematic() -> void:
		cinematic_active = false


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _frames(count := 4) -> void:
	for _index in count:
		await process_frame


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game := root.get_node_or_null("Game")
	if game != null:
		game.persistence_enabled = false
		game.reset_to_defaults()
	var modal_before := int(game.modal_count) if game != null else 0
	var shrine: CanvasLayer = load("res://scripts/shrine_choice_modal.gd").new()
	root.add_child(shrine)
	var offers := [
		{"id": "vigor", "name": "Vigor of Bramblewood", "desc": "+20 Max HP"},
		{"id": "precision", "name": "Precision of the Glade", "desc": "+15% Crit Chance"},
		{"id": "channeling", "name": "Channeling of the Root", "desc": "+8 Focus/s regen"},
	]
	shrine.setup(offers)
	await _frames()
	var shell := shrine.find_child("SystemShell", true, false) as Control
	var close := shrine.find_child("CloseButton", true, false) as Button
	var cards: Array[Button] = []
	for candidate in shrine.find_children("BlessingCard_*", "Button", true, false):
		cards.append(candidate as Button)
	_check(shell != null and cards.size() == 3,
		"Shrine composes exactly three semantic choices in the shared folio")
	if shell != null:
		var rect := shell.get_global_rect()
		_check(rect.position.x >= Tokens.SAFE_GUTTER and rect.position.y >= Tokens.SAFE_GUTTER \
				and rect.end.x <= 1280.0 - Tokens.SAFE_GUTTER \
				and rect.end.y <= 720.0 - Tokens.SAFE_GUTTER,
			"Shrine keeps the 24px safe gutter at the minimum resolution")
	_check(close != null and not close.visible and close.focus_mode == Control.FOCUS_NONE,
		"the one-way shrine commitment exposes no false close action")
	var cards_valid := cards.size() == 3
	for card in cards:
		var icon := card.find_child("BlessingIcon", true, false) as TextureRect
		var effect := card.find_child("BlessingEffect", true, false) as Label
		cards_valid = cards_valid and card.theme_type_variation == &"ChoiceCardButton" \
			and card.custom_minimum_size.y >= 3.0 * Tokens.HIT_TARGET \
			and icon != null and icon.texture != null \
			and effect != null and effect.text != ""
	_check(cards_valid,
		"every shrine card has painterly art, written consequence, and a large target")
	_check(not cards.is_empty() and root.gui_get_focus_owner() == cards[0],
		"Shrine initially focuses the first visible blessing")
	_check(game == null or int(game.modal_count) == modal_before + 1,
		"Shrine opens exactly one Game modal")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	shrine.call("_unhandled_input", cancel)
	await _frames(1)
	_check(is_instance_valid(shrine) and (game == null or int(game.modal_count) == modal_before + 1),
		"Cancel cannot bypass the authored one-blessing commitment")
	var selected: Array[Dictionary] = []
	shrine.chosen.connect(func(buff: Dictionary): selected.append(buff))
	if cards.size() >= 2:
		cards[1].pressed.emit()
	await _frames()
	_check(not selected.is_empty() and String(selected[0].get("id", "")) == "precision",
		"a blessing Button emits the untouched authored descriptor")
	_check(game == null or int(game.modal_count) == modal_before,
		"committing a blessing releases exactly the shrine modal")

	var rig := TestRig.new()
	root.add_child(rig)
	var vignette: CanvasLayer = load("res://scripts/ui/micro_cutscene.gd").new()
	root.add_child(vignette)
	vignette.play(rig, [{
		"focus": Vector3.ZERO, "yaw": 0.0, "pitch": 35.0, "zoom": 15.0,
		"duration": 30.0, "caption": "Bramblewood begins.",
	}])
	await _frames()
	var rail := vignette.find_child("StoryCaptionRail", true, false) as Control
	var caption := vignette.find_child("StoryCaption", true, false) as Label
	var skip := vignette.find_child("SkipLabel", true, false) as Label
	_check(rail != null and caption != null and skip != null,
		"micro-cutscene uses a named Field Journal caption rail")
	if rail != null:
		var rail_rect := rail.get_global_rect()
		_check(rail_rect.position.x >= Tokens.SAFE_GUTTER \
				and rail_rect.end.x <= 1280.0 - Tokens.SAFE_GUTTER \
				and rail_rect.end.y <= 720.0 - Tokens.SAFE_GUTTER + 0.5,
			"story caption rail remains inside the minimum-resolution safe gutter")
	_check(caption != null and caption.text == "Bramblewood begins." \
			and caption.get_theme_font_size("font_size") >= Tokens.TYPE_DIALOGUE,
		"vignette sentence uses the readable dialogue type floor")
	_check(skip != null and skip.text == "Space / Esc" \
			and skip.get_theme_font_size("font_size") >= Tokens.TYPE_BODY,
		"the required skip instruction is not demoted to caption text")
	_check(rig.cinematic_active and (game == null or int(game.modal_count) == modal_before + 1),
		"vignette still owns the camera and exactly one modal while visible")
	vignette.call("_finish", true)
	await _frames()
	_check(not rig.cinematic_active and (game == null or int(game.modal_count) == modal_before),
		"skipping the restyled vignette restores camera and modal ownership")

	if _failures.is_empty():
		print("UI PERIPHERAL CONTRACT: PASS")
		quit(0)
	else:
		print("UI PERIPHERAL CONTRACT: FAIL (%d failures)" % _failures.size())
		quit(1)
