extends Control

# B3 — the title screen / front door. This is the boot scene; it routes into
# Town. ANY dev/automation env (the headless suites, WYRD_NET co-op, WYRD_SHOT
# captures, WYRD_DEV_*) skips straight to Town so every existing flow is
# unaffected — only a plain launch shows the title.

const TOWN := "res://scenes/Town.tscn"
const SKIP_ENVS := ["WYRD_NET", "WYRD_NET_RUN", "WYRD_DEV_CHART", "WYRD_DEV_BOSS",
	"WYRD_DEV_LEVEL", "WYRD_SHOT", "WYRD_UI_SHOT", "WYRD_SKIP_TITLE"]
# The painted title screen (Midjourney title_3, user-picked 2026-07-01): gilded
# "Wayfinder" over a misty Bramblewood clearing with fireflies. It IS the
# backdrop; the menu buttons sit on an enamel plate in the lower-centre. Falls
# back to the code-drawn MenuBackdrop if the art is ever missing.
const TITLE_BG := "res://assets/ui/menu/title_bg.webp"

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

	# Menu buttons ride an enamel plate in the lower-centre so they stay legible
	# over the painted clearing (and read as one deliberate object, not floating
	# labels). The plate auto-sizes to the button column and re-centres as it grows.
	var plate := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(WyrdUi.KIT_WELL, 0.62)
	psb.border_color = Color(WyrdUi.GOLD, 0.55)
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
	plate.anchor_left = 0.5; plate.anchor_right = 0.5
	# Pin the plate's TOP below the painted wordmark and grow it downward, so the
	# buttons never ride up over "Wayfinder".
	plate.anchor_top = 0.54 if has_art else 0.42
	plate.anchor_bottom = plate.anchor_top
	plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	plate.grow_vertical = Control.GROW_DIRECTION_END
	plate.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(plate)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	plate.add_child(col)

	if _has_save():
		_add_btn(col, "Continue", _on_continue)
	_add_btn(col, "New Game", _on_new_game)
	_add_btn(col, "Co-op (host / join)", _on_coop)
	_add_btn(col, "Options", _on_options)
	_add_btn(col, "Credits", func():
		add_child(load("res://scripts/ui/credits_menu.gd").new()))
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
