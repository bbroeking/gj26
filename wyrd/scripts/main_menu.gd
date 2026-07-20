extends Control

# B3 — the title screen / front door. This is the boot scene; it routes into
# Town. Dev/automation envs (the headless suites, WYRD_SHOT captures,
# WYRD_DEV_*) skip straight to Town so every existing flow is
# unaffected — only a plain launch shows the title.

const TOWN := "res://scenes/Town.tscn"
const SKIP_ENVS := ["WYRD_DEV_CHART", "WYRD_DEV_FIRST_ROAD", "WYRD_DEV_BOSS",
	"WYRD_DEV_LEVEL", "WYRD_SHOT", "WYRD_UI_SHOT", "WYRD_SKIP_TITLE"]
# The painted title screen (Midjourney title_3, user-picked 2026-07-01): gilded
# "Wayfinder" over a misty Bramblewood clearing with fireflies. It IS the
# backdrop; the menu buttons sit on an enamel plate in the lower-centre. Falls
# back to the code-drawn MenuBackdrop if the art is ever missing.
const TITLE_BG := "res://assets/ui/menu/title_bg.webp"
const LOADING_BG := "res://assets/ui/loading/bramblewood_panorama.png"
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")
var _town_load_requested := false
var _menu_col: VBoxContainer = null
var _loading_overlay: Control = null
var _loading_progress: ProgressBar = null
var _loading_status: Label = null

func _ready() -> void:
	for e in SKIP_ENVS:
		if OS.get_environment(e) != "":
			call_deferred("_to_town")
			return
	_build()
	# Title-only capture exits while a threaded Town preload is still resolving,
	# which can produce false missing-resource diagnostics during renderer
	# teardown. Normal play and loading-screen capture still prewarm Town.
	if OS.get_environment("WYRD_SHOT_PATH") == "":
		_prewarm_town()
	# Release Web routes must begin at the shipped front door. Notify Game only
	# after the real button tree exists so a strict route can activate the same
	# "Begin a New Journey" Control a player sees, rather than bypassing it.
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("web_smoke_scene_ready"):
		game.call_deferred("web_smoke_scene_ready", "MainMenu")

func _to_town() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if not _town_load_requested:
		_prewarm_town()
	_set_loading(true)
	await tree.process_frame
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(TOWN, progress)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var amount := float(progress[0]) if not progress.is_empty() else 0.0
		_set_load_progress(clampf(amount, 0.06, 0.92))
		await tree.process_frame
		status = ResourceLoader.load_threaded_get_status(TOWN, progress)
	await _finish_loading_presentation()
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(TOWN) as PackedScene
		if packed != null:
			tree.change_scene_to_packed(packed)
			return
	# Safe fallback if a platform refuses a threaded request.
	tree.change_scene_to_file(TOWN)

func _prewarm_town() -> void:
	if _town_load_requested:
		return
	_town_load_requested = ResourceLoader.load_threaded_request(TOWN) == OK

func _set_loading(on: bool) -> void:
	if _menu_col != null:
		for child in _menu_col.find_children("*", "Button", true, false):
			(child as Button).disabled = on
	if _loading_overlay != null:
		_loading_overlay.visible = on
	if on:
		_set_load_progress(0.06)

func _set_load_progress(amount: float) -> void:
	if _loading_progress == null:
		return
	_loading_progress.value = maxf(float(_loading_progress.value), amount * 100.0)
	if _loading_status != null:
		if amount < 0.35:
			_loading_status.text = "Opening the way…"
		elif amount < 0.75:
			_loading_status.text = "Setting the yard in order…"
		elif amount < 0.98:
			_loading_status.text = "Lighting the last lantern…"
		else:
			_loading_status.text = "The road is ready."

func _finish_loading_presentation() -> void:
	if _loading_progress == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: float) -> void:
		_set_load_progress(value),
		float(_loading_progress.value) / 100.0, 1.0, 0.65)
	await tween.finished

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = FIELD_THEME
	var has_art := ResourceLoader.exists(TITLE_BG)
	if has_art:
		# Painted title screen fills the whole frame (keep-aspect-covered so any
		# window size crops rather than letterboxes).
		var art := TextureRect.new()
		art.texture = load(TITLE_BG)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
	else:
		# Fallback: code-drawn enamel backdrop (MENU_STYLE selects a direction).
		var bg := MenuBackdrop.new()
		var ms := OS.get_environment("MENU_STYLE")
		bg.style = int(ms) if ms != "" else 1
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		# The art carries the wordmark; the fallback needs its own title.
		var title := Label.new()
		title.text = "Wayfinder"
		WyrdUi.style_title(title)
		title.add_theme_font_size_override("font_size", 72)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.anchor_left = 0.5; title.anchor_right = 0.5; title.anchor_top = 0.16
		title.offset_left = -360; title.offset_right = 360; title.offset_top = 0
		add_child(title)
		var tag := Label.new()
		tag.text = "a cozy fairytale of Bramblewood"
		WyrdUi.style_dim(tag, 16)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.anchor_left = 0.5; tag.anchor_right = 0.5; tag.anchor_top = 0.16
		tag.offset_left = -360; tag.offset_right = 360; tag.offset_top = 92
		add_child(tag)

	_build_loading_screen()

	# The journey actions stay full-width; secondary tasks share a compact 2×2
	# grid. The plate grows upward from a safe bottom gutter, so the saved-game
	# state remains wholly visible at the 1280×720 minimum.
	var plate := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(Tokens.WALNUT_DEEP, 0.88)
	psb.border_color = Color(Tokens.GOLD_MUTED, 0.75)
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(26)     # 2026-07-01 — softer, pudgier plate
	psb.corner_detail = 10
	psb.anti_aliasing = true
	psb.shadow_color = Color(0, 0, 0, 0.35)
	psb.shadow_size = 12
	psb.content_margin_left = 26.0
	psb.content_margin_right = 26.0
	psb.content_margin_top = 20.0
	psb.content_margin_bottom = 20.0
	plate.add_theme_stylebox_override("panel", psb)
	plate.name = "TitleActionPlate"
	plate.custom_minimum_size.x = 620.0
	plate.anchor_left = 0.5; plate.anchor_right = 0.5
	plate.anchor_top = 1.0
	plate.anchor_bottom = 1.0
	plate.offset_bottom = -20.0
	plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
	plate.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(plate)

	var col := VBoxContainer.new()
	_menu_col = col
	col.add_theme_constant_override("separation", 8)
	plate.add_child(col)
	var invitation := Label.new()
	invitation.text = "Gather · inscribe · delve · return"
	invitation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	invitation.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	invitation.add_theme_font_size_override("font_size", 16)
	col.add_child(invitation)
	var game := get_node_or_null("/root/Game")
	if game != null and not bool(game.persistence_available):
		var warning := Label.new()
		warning.text = String(game.persistence_warning)
		warning.custom_minimum_size = Vector2(300, 0)
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		WyrdUi.style_dim(warning, 16)
		warning.modulate = Color("f2c27d")
		col.add_child(warning)

	var has_save := _has_save()
	var initial_action: Button = null
	if has_save:
		initial_action = _add_btn(col, "Continue", _on_continue)
	var begin := _add_btn(col, "Begin a New Journey", _on_new_game)
	if not has_save:
		initial_action = begin
		_schedule_begin_emphasis(begin)
	initial_action.grab_focus.call_deferred()
	var secondary := GridContainer.new()
	secondary.name = "SecondaryActions"
	secondary.columns = 2
	secondary.add_theme_constant_override("h_separation", 8)
	secondary.add_theme_constant_override("v_separation", 8)
	col.add_child(secondary)
	_add_btn(secondary, "Options", _on_options)
	_add_btn(secondary, "Credits", func():
		add_child(load("res://scripts/ui/credits_menu.gd").new()))
	_add_btn(col, "Share Feedback", _on_feedback)
	_add_btn(col, "Quit", func(): get_tree().quit())
	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "MenuFocusPointer"
	add_child(focus_pointer)

	# Dev: WYRD_SHOT_PATH captures the title then quits (automation — note this
	# is NOT in SKIP_ENVS, so the title actually renders for the shot).
	if OS.get_environment("WYRD_SHOT_PATH") != "":
		get_tree().create_timer(0.6).timeout.connect(func():
			var img := get_viewport().get_texture().get_image()
			img.save_png(OS.get_environment("WYRD_SHOT_PATH"))
			get_tree().quit())
	elif OS.get_environment("WYRD_SHOT_LOADING_PATH") != "":
		_set_loading(true)
		_set_load_progress(0.68)
		get_tree().create_timer(0.6).timeout.connect(func():
			var img := get_viewport().get_texture().get_image()
			img.save_png(OS.get_environment("WYRD_SHOT_LOADING_PATH"))
			get_tree().quit())

func _build_loading_screen() -> void:
	# Warcraft III's useful loading-screen grammar is the reference here: one
	# dominant painted place, a strong chapter plaque, and a heavy bottom loading
	# trough. Materials, typography, and copy remain Wayfinder's Field Journal.
	_loading_overlay = Control.new()
	_loading_overlay.name = "LoadingScreen"
	_loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loading_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading_overlay.z_index = 100
	_loading_overlay.visible = false
	add_child(_loading_overlay)

	var art := TextureRect.new()
	art.texture = load(LOADING_BG)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_overlay.add_child(art)

	var wash := ColorRect.new()
	wash.color = Color(0.07, 0.045, 0.025, 0.18)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_overlay.add_child(wash)

	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 18.0
	frame.offset_top = 18.0
	frame.offset_right = -18.0
	frame.offset_bottom = -18.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color.TRANSPARENT
	frame_style.border_color = Tokens.WALNUT_DEEP
	frame_style.set_border_width_all(12)
	frame_style.set_corner_radius_all(10)
	frame_style.shadow_color = Color(0.02, 0.01, 0.0, 0.8)
	frame_style.shadow_size = 16
	frame.add_theme_stylebox_override("panel", frame_style)
	_loading_overlay.add_child(frame)

	var inner_frame := Panel.new()
	inner_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_frame.offset_left = 29.0
	inner_frame.offset_top = 29.0
	inner_frame.offset_right = -29.0
	inner_frame.offset_bottom = -29.0
	inner_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color.TRANSPARENT
	inner_style.border_color = Color(Tokens.GOLD_MUTED, 0.92)
	inner_style.set_border_width_all(3)
	inner_style.set_corner_radius_all(6)
	inner_frame.add_theme_stylebox_override("panel", inner_style)
	_loading_overlay.add_child(inner_frame)

	var plaque := PanelContainer.new()
	plaque.anchor_left = 0.055
	plaque.anchor_right = 0.56
	plaque.anchor_top = 0.57
	plaque.anchor_bottom = 0.81
	plaque.offset_left = 0.0
	plaque.offset_right = 0.0
	plaque.offset_top = 0.0
	plaque.offset_bottom = 0.0
	var plaque_style := StyleBoxFlat.new()
	plaque_style.bg_color = Color(Tokens.WALNUT_DEEP, 0.92)
	plaque_style.border_color = Color(Tokens.GOLD_MUTED, 0.88)
	plaque_style.set_border_width_all(3)
	plaque_style.set_corner_radius_all(8)
	plaque_style.content_margin_left = 28.0
	plaque_style.content_margin_right = 28.0
	plaque_style.content_margin_top = 18.0
	plaque_style.content_margin_bottom = 18.0
	plaque_style.shadow_color = Color(0.02, 0.01, 0.0, 0.58)
	plaque_style.shadow_size = 12
	plaque.add_theme_stylebox_override("panel", plaque_style)
	_loading_overlay.add_child(plaque)

	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 2)
	plaque.add_child(copy)
	var eyebrow := Label.new()
	eyebrow.text = "THE CHARTMAKER'S YARD"
	eyebrow.theme_type_variation = &"Caption"
	eyebrow.add_theme_color_override("font_color", Tokens.GOLD_MUTED)
	copy.add_child(eyebrow)
	var location := Label.new()
	location.text = "Bramblewood"
	location.theme_type_variation = &"PageTitle"
	location.add_theme_font_size_override("font_size", 38)
	location.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	copy.add_child(location)
	var lore := Label.new()
	lore.text = "Where the wagon road ends, every deeper road begins."
	lore.theme_type_variation = &"Body"
	lore.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK_DIM)
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(lore)

	var loading_plate := PanelContainer.new()
	loading_plate.anchor_left = 0.055
	loading_plate.anchor_right = 0.945
	loading_plate.anchor_top = 0.84
	loading_plate.anchor_bottom = 0.955
	var loading_style := StyleBoxFlat.new()
	loading_style.bg_color = Color(Tokens.WALNUT_DEEP, 0.96)
	loading_style.border_color = Color(Tokens.GOLD_MUTED, 0.92)
	loading_style.set_border_width_all(3)
	loading_style.set_corner_radius_all(6)
	loading_style.content_margin_left = 20.0
	loading_style.content_margin_right = 20.0
	loading_style.content_margin_top = 10.0
	loading_style.content_margin_bottom = 10.0
	loading_style.shadow_color = Color(0.02, 0.01, 0.0, 0.65)
	loading_style.shadow_size = 10
	loading_plate.add_theme_stylebox_override("panel", loading_style)
	_loading_overlay.add_child(loading_plate)

	var load_col := VBoxContainer.new()
	load_col.add_theme_constant_override("separation", 5)
	loading_plate.add_child(load_col)
	_loading_status = Label.new()
	_loading_status.text = "Opening the way…"
	_loading_status.theme_type_variation = &"Body"
	_loading_status.add_theme_color_override("font_color", Tokens.TEXT_ON_DARK)
	load_col.add_child(_loading_status)
	_loading_progress = ProgressBar.new()
	_loading_progress.name = "RoadProgress"
	_loading_progress.custom_minimum_size = Vector2(0.0, 24.0)
	_loading_progress.show_percentage = false
	var trough := StyleBoxFlat.new()
	trough.bg_color = Color("17110d")
	trough.border_color = Color(Tokens.WALNUT, 1.0)
	trough.set_border_width_all(3)
	trough.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Tokens.SAGE
	fill.border_color = Tokens.GOLD_MUTED
	fill.set_border_width_all(2)
	fill.set_corner_radius_all(2)
	_loading_progress.add_theme_stylebox_override("background", trough)
	_loading_progress.add_theme_stylebox_override("fill", fill)
	load_col.add_child(_loading_progress)

func _has_save() -> bool:
	# SaveGame.has_save() is the source of truth; guard for headless/no-save.
	if OS.get_environment("WYRD_NO_SAVE") != "":
		return false
	var game := get_node_or_null("/root/Game")
	if game != null and not bool(game.persistence_available):
		return false
	return SaveGame.has_save()

func _add_btn(parent: Container, label: String, cb: Callable) -> Button:
	var b := Button.new()
	WyrdUi.style_kit_button(b)
	b.text = label
	b.custom_minimum_size = Vector2(280, 48)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _schedule_begin_emphasis(begin: Button) -> void:
	# One restrained idle pulse. It never loops forever or competes with another
	# menu action, and vanishes as soon as loading begins.
	get_tree().create_timer(6.0).timeout.connect(func() -> void:
		if not is_instance_valid(begin) or _town_load_requested:
			return
		var tw := create_tween()
		tw.tween_property(begin, "modulate", Color(1.0, 0.90, 0.58), 0.28)
		tw.tween_property(begin, "modulate", Color.WHITE, 0.42)
		tw.tween_property(begin, "modulate", Color(1.0, 0.90, 0.58), 0.28)
		tw.tween_property(begin, "modulate", Color.WHITE, 0.42))

func _on_continue() -> void:
	_to_town()

func _on_new_game() -> void:
	var game := get_node_or_null("/root/Game")
	if game != null and game.has_method("reset_to_defaults"):
		game.reset_to_defaults()
		game.start_first_road()
	_to_town()

func _on_options() -> void:
	var panel: CanvasLayer = load("res://scripts/ui/options_menu.gd").new()
	add_child(panel)

func _on_feedback() -> void:
	var panel: CanvasLayer = load("res://scripts/ui/feedback_menu.gd").new()
	add_child(panel)


# Storybook Enamel title backdrop. Draws an atmospheric background so the title
# stops floating on flat beige. Several directions for option review (spec 54).
class MenuBackdrop extends Control:
	const TEX_MOTE := preload("res://assets/vfx/soft_circle.png")
	var style := 1

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var r := Rect2(Vector2.ZERO, size)
		# --- base ---
		var bands := 56
		if style == 1:
			# Deep Enamel — near-solid deep teal with a faint top lift.
			var top1 := Color(0.10, 0.27, 0.25)
			var bot1 := Color(0.055, 0.16, 0.15)
			for i in bands:
				var t := float(i) / float(bands - 1)
				draw_rect(Rect2(0, t * h, w, h / bands + 1.0), top1.lerp(bot1, t))
		else:
			# Bramblewood dusk — teal sky sinking into warm forest dark.
			var top2 := Color(0.11, 0.30, 0.30)
			var mid2 := Color(0.07, 0.19, 0.17)
			var bot2 := Color(0.10, 0.12, 0.07)
			for i in bands:
				var t := float(i) / float(bands - 1)
				var c := top2.lerp(mid2, minf(1.0, t * 1.6)) if t < 0.6 \
					else mid2.lerp(bot2, (t - 0.6) / 0.4)
				draw_rect(Rect2(0, t * h, w, h / bands + 1.0), c)
		# --- drifting gold motes (fireflies) ---
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var mn := 34 if style == 2 else 16
		for i in mn:
			var p := Vector2(rng.randf() * w, rng.randf() * h)
			var s := rng.randf_range(6.0, 22.0)
			var a := rng.randf_range(0.05, 0.16) * (1.4 if style == 2 else 1.0)
			draw_texture_rect(TEX_MOTE, Rect2(p, Vector2(s, s)), false,
				Color(WyrdUi.GOLD, a))
		# --- soft corner vignette (nested translucent frames) ---
		for i in 10:
			var g := float(i) * 26.0
			draw_rect(Rect2(-g, -g, w + 2.0 * g, h + 2.0 * g),
				Color(0.02, 0.05, 0.05, 0.06), false, 30.0)
		# --- gold ornamental double frame ---
		var m := 30.0
		var fr := Rect2(m, m, w - 2.0 * m, h - 2.0 * m)
		draw_rect(fr, Color(WyrdUi.GOLD, 0.5), false, 2.0)
		draw_rect(fr.grow(7.0), Color(WyrdUi.GOLD, 0.28), false, 1.0)
