extends Control

# B3 — the title screen / front door. This is the boot scene; it routes into
# Town. ANY dev/automation env (the headless suites, WYRD_NET co-op, WYRD_SHOT
# captures, WYRD_DEV_*) skips straight to Town so every existing flow is
# unaffected — only a plain launch shows the title.

const TOWN := "res://scenes/Town.tscn"
const SKIP_ENVS := ["WYRD_NET", "WYRD_NET_RUN", "WYRD_DEV_CHART", "WYRD_DEV_BOSS",
	"WYRD_DEV_LEVEL", "WYRD_SHOT", "WYRD_UI_SHOT", "WYRD_SKIP_TITLE"]

func _ready() -> void:
	for e in SKIP_ENVS:
		if OS.get_environment(e) != "":
			call_deferred("_to_town")
			return
	_build()

func _to_town() -> void:
	get_tree().change_scene_to_file(TOWN)

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.91, 0.85, 0.69)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = "Wayfinder"
	WyrdUi.style_title(title)
	title.add_theme_font_size_override("font_size", 72)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.5; title.anchor_right = 0.5; title.anchor_top = 0.18
	title.offset_left = -360; title.offset_right = 360; title.offset_top = 0
	add_child(title)

	var tag := Label.new()
	tag.text = "a cozy fairytale of Bramblewood"
	WyrdUi.style_dim(tag, 16)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.anchor_left = 0.5; tag.anchor_right = 0.5; tag.anchor_top = 0.18
	tag.offset_left = -360; tag.offset_right = 360; tag.offset_top = 92
	add_child(tag)

	var col := VBoxContainer.new()
	col.anchor_left = 0.5; col.anchor_right = 0.5; col.anchor_top = 0.42
	col.offset_left = -150; col.offset_right = 150; col.offset_top = 0
	col.add_theme_constant_override("separation", 12)
	add_child(col)

	if _has_save():
		_add_btn(col, "Continue", _on_continue)
	_add_btn(col, "New Game", _on_new_game)
	_add_btn(col, "Co-op (host / join)", _on_coop)
	_add_btn(col, "Options", _on_options)
	_add_btn(col, "Quit", func(): get_tree().quit())

	# Dev: WYRD_SHOT_PATH captures the title then quits (automation — note this
	# is NOT in SKIP_ENVS, so the title actually renders for the shot).
	if OS.get_environment("WYRD_SHOT_PATH") != "":
		get_tree().create_timer(0.6).timeout.connect(func():
			var img := get_viewport().get_texture().get_image()
			img.save_png(OS.get_environment("WYRD_SHOT_PATH"))
			get_tree().quit())

func _has_save() -> bool:
	# SaveGame.has_save() is the source of truth; guard for headless/no-save.
	if OS.get_environment("WYRD_NO_SAVE") != "":
		return false
	return SaveGame.has_save()

func _add_btn(col: VBoxContainer, label: String, cb: Callable) -> void:
	var b := Button.new()
	WyrdUi.style_kit_button(b)
	b.text = label
	b.custom_minimum_size = Vector2(300, 46)
	b.pressed.connect(cb)
	col.add_child(b)

func _on_continue() -> void:
	_to_town()

func _on_new_game() -> void:
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("reset_to_defaults"):
		game.reset_to_defaults()
	_to_town()

func _on_coop() -> void:
	# Drop into town; the Lantern (Esc) hosts/joins from there.
	_to_town()
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("notify"):
		game._defer_toasts = true
		game.notify("Press Esc for the Lantern — light a fire or join a friend.")

func _on_options() -> void:
	var panel: CanvasLayer = load("res://scripts/ui/options_menu.gd").new()
	add_child(panel)
