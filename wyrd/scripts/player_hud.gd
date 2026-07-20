extends CanvasLayer

# Spec 15 — minimal player HUD: an HP bar + a full-screen damage flash.
# Spec 23 — plus a Pokémon-style death white-out.
# UI scaling is now project-level: the project uses `canvas_items` stretch +
# `expand` aspect (project.godot [display]), so the whole HUD is authored in
# the 1280×720 base coordinate space and scales uniformly to any window. The
# old Spec-35 per-CanvasLayer UI_SCALE transform is retired — it broke anchor
# resolution (pushed bars off-screen) and was applied inconsistently.

const FILL_LEFT := 2.0
const FILL_FULL_W := 216.0
# Spec 30 — Focus bar dimensions match the HP bar so the two stack cleanly.
const FOCUS_FILL_LEFT := 2.0
const FOCUS_FILL_FULL_W := 216.0
const Feel = preload("res://data/feel.gd")   # Plan.md B0 — feel tunables
const CraftingDefs = preload("res://data/crafting.gd")
const Progression = preload("res://data/progression.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")
const FIELD_THEME := preload("res://themes/wayfinder_theme.tres")

@onready var _fill: ColorRect = $HPRoot/Fill
@onready var _label: Label = $HPRoot/Label
@onready var _flash: ColorRect = $Flash
@onready var _whiteout: ColorRect = $Whiteout
@onready var _focus_fill: ColorRect = $FocusRoot/Fill
@onready var _focus_label: Label = $FocusRoot/Label

# Wyrd — quest tracker, toast stack, and the Wayfinding readout.
var _objective: Label
var _objective_hint: Label
var _quest_sub: Label         # D13 — chart sub-objective line
var _quest_plate: Panel
var _compass: CompassArrow = null      # spec 52 — points at the descent/exit
var _quest_progress: Label
var _toast_box: VBoxContainer
var _skills_lbl: Label
var _action_bar: HBoxContainer
var _action_buttons := {}
var _cluster_tray: Control = null
var _last_toast_text := ""        # toast dedup (Feel.TOAST_DEDUP_WINDOW_SEC)
var _last_toast_time := 0.0
# Spec 38 — potion globes (PoE-style): HP red bottom-left of the skill
# bar, Focus blue bottom-right. The liquid level IS the meter.
var _hp_globe: FieldMeter = null
var _focus_globe: FieldMeter = null
var _pip_row: StatusPipRow = null      # active-status drain-arc pips above HP
# Slice B — a radial hurt-vignette: transparent center darkening to a
# terracotta rim, flashed on the player taking damage (richer than the flat
# full-screen red _flash). A TextureRect fed by a radial GradientTexture2D —
# no shader, no _draw, so it's safe in this CanvasLayer.
var _vignette: TextureRect = null
var _game_ref: Node = null

func _ready() -> void:
	add_to_group("gameplay_hud")
	_game_ref = get_tree().root.get_node_or_null("Game")
	var game := _game_ref
	if game != null:
		if game.has_signal("modal_changed") and not game.modal_changed.is_connected(_on_modal_changed):
			game.modal_changed.connect(_on_modal_changed)
		_on_modal_changed(int(game.get("modal_count")) > 0)
	# Spec-35: scale up the HP + Focus bars together. Flash and Whiteout
	# need to remain viewport-sized; reset their scale parent on each
	# (they're full-screen ColorRects, anchored to all sides).
	# Wyrd UI overhaul — the tscn ColorRect bars become parchment meters.
	$HPRoot.visible = false
	$FocusRoot.visible = false
	# Spec 54 — a slim carved border framed the play window (HUD "A"). The
	# MapleStory pick (C_2) is borderless — a clean scene with a bottom cluster —
	# so the frame is dropped when the maple kit is present.
	if not WyrdUi.has_maple():
		_build_hud_frame()
	# Maple (hud2_cradle_3): ONE wide cream+wood cradle tray spanning the whole
	# bottom cluster, drawn behind the orbs + (skill_bar's) round slots so they
	# read as a single low row. Added before the orbs so they sit on top of it.
	if WyrdUi.has_maple():
		_build_cluster_tray()
	# Spec 59 — readable horizontal Field Journal meters flank the hotbar.
	_hp_globe = FieldMeter.new()
	_hp_globe.fill_color = WyrdUi.TERRACOTTA
	_hp_globe.caption = "HP"
	_place_globe(_hp_globe, -1)
	_focus_globe = FieldMeter.new()
	_focus_globe.fill_color = WyrdUi.SAGE
	_focus_globe.caption = "FOCUS"
	_place_globe(_focus_globe, 1)
	_hp_globe.update_to(1.0, "30/30", "")
	_focus_globe.update_to(1.0, "50/50", "")
	# Status pip row — drain-arc pips above the HP globe (system-status-effects).
	# Status pips ride just above the HP orb (which now flanks the hotbar cluster).
	_pip_row = StatusPipRow.new()
	_pip_row.anchor_left = 0.5
	_pip_row.anchor_right = 0.5
	_pip_row.anchor_top = 1.0
	_pip_row.anchor_bottom = 1.0
	_pip_row.offset_left = -119
	_pip_row.offset_right = -37
	_pip_row.offset_top = -116
	_pip_row.offset_bottom = -96
	_pip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pip_row)
	_build_hurt_vignette()
	_build_mute_indicator()
	_build_wyrd_overlay()
	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "HudFocusPointer"
	add_child(focus_pointer)


func _on_modal_changed(is_open: bool) -> void:
	visible = not is_open

# A globe FLANKING the bottom-centre hotbar cluster (2026-07-01 — user: "bring
# the circles in"): side -1 = left of the tray, +1 = right. One fused bottom
# cluster instead of orbs marooned in the far corners.
const GLOBE_BOX := 196.0
const METER_H := 48.0
const HOTBAR_SLOT := 56.0
const HOTBAR_GAP := 6.0
func _place_globe(g: FieldMeter, side: int) -> void:
	g.anchor_left = 0.5
	g.anchor_right = 0.5
	g.anchor_top = 1.0
	g.anchor_bottom = 1.0
	var cx := 176.0 * float(side)
	g.offset_left = cx - GLOBE_BOX * 0.5
	g.offset_right = cx + GLOBE_BOX * 0.5
	g.offset_top = -76
	g.offset_bottom = -76 + METER_H
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(g)

# HUD "A" — the slim carved border. Full-rect, behind every widget, click-through.
func _build_hud_frame() -> void:
	var frame := HudFrame.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

# The maple cradle tray — one wide cream+wood pill spanning the bottom cluster.
func _build_cluster_tray() -> void:
	var tray := ClusterTray.new()
	tray.name = "BottomCluster"
	tray.anchor_left = 0.5
	tray.anchor_right = 0.5
	tray.anchor_top = 1.0
	tray.anchor_bottom = 1.0
	tray.offset_left = -124.0
	tray.offset_right = 36.0
	tray.offset_top = -94.0
	tray.offset_bottom = -8.0
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tray)
	_cluster_tray = tray

# Spec 38 — the mute state, by the Focus globe. F10 flips it.
func _build_mute_indicator() -> void:
	# Spec 52 (Direction A) — no always-on mute label cluttering the HUD; mute
	# is surfaced only as a transient toast when the player toggles it (F10).
	var game := get_tree().root.get_node_or_null("Game")
	if game != null and game.has_signal("mute_changed"):
		game.mute_changed.connect(func(m): show_toast("♪  Muted" if m else "♪  Sound on"))

# ---- Wyrd overlay: objective + toasts + skill levels ----
func _build_wyrd_overlay() -> void:
	# Quest tracker — a parchment scroll plate top-center, with a small-caps
	# QUEST header, the objective, and a live progress counter.
	_quest_plate = Panel.new()
	_quest_plate.name = "QuestNote"
	# Slice B — promote the quest tracker from a flat chip to a SEALED SCROLL:
	# a painted-wood 9-patch backing + a drawn parchment-grain / flourish /
	# wax-seal overlay (QuestScrollArt below). The button-plate art (144×80,
	# 18px margins) is the right scale for a ~90px banner — panel_frame's
	# ~37/40px margins would crush a plate this short — so it's the primary,
	# with the chip stylebox as the only fallback.
	# 2026-07-01 — a rounded card. MapleStory: cream with a wood frame (text goes
	# dark so it reads on cream); else the soft enamel card (cream text).
	var maple := WyrdUi.has_maple()
	var q_hdr_col: Color = WyrdUi.MAPLE_WOOD_D if maple else WyrdUi.GOLD
	var q_body_col: Color = WyrdUi.MAPLE_INK_DARK if maple else WyrdUi.TEXT_ON_DARK
	var q_prog_col: Color = Color(0.28, 0.48, 0.20) if maple else WyrdUi.SAGE
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(18)
	sb.corner_detail = 10
	sb.anti_aliasing = true
	if maple:
		sb.bg_color = WyrdUi.MAPLE_CREAM
		sb.set_border_width_all(5)
		sb.border_color = WyrdUi.MAPLE_WOOD
	else:
		sb.bg_color = Color(WyrdUi.KIT_PLATE, 0.90)
		sb.set_border_width_all(2)
		sb.border_color = Color(WyrdUi.GOLD, 0.55)
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	_quest_plate.add_theme_stylebox_override("panel", sb)
	# Spec 52 (Direction A) — a compact objective chip pinned top-LEFT, not a
	# 520px banner centred over the world. One line + an affix sub-line.
	_quest_plate.anchor_left = 0.0
	_quest_plate.anchor_right = 0.0
	_quest_plate.offset_left = 12
	_quest_plate.offset_right = 332
	_quest_plate.offset_top = 10
	_quest_plate.offset_bottom = 82
	add_child(_quest_plate)
	# Drawn scroll dressing — added first so it sits behind the text. Fills the
	# plate; redraws on resize. The _draw-on-Control pattern is proven in this
	# CanvasLayer (GlobeGauge).
	var art := QuestScrollArt.new()
	art.anchor_right = 1.0
	art.anchor_bottom = 1.0
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_plate.add_child(art)
	var qhdr := Label.new()
	qhdr.name = "QuestTitle"
	qhdr.text = "✦ Next"
	var hf := WyrdUi.font_header()
	if hf != null:
		qhdr.add_theme_font_override("font", hf)
	qhdr.add_theme_font_size_override("font_size", 14)
	qhdr.add_theme_color_override("font_color", q_hdr_col)
	qhdr.offset_left = 14
	qhdr.anchor_right = 1.0
	qhdr.offset_top = 7
	qhdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_quest_plate.add_child(qhdr)
	# Progress counter rides the top-right corner of the chip, beside the eyebrow.
	_quest_progress = Label.new()
	_quest_progress.add_theme_font_size_override("font_size", 14)
	_quest_progress.add_theme_color_override("font_color", q_prog_col)
	_quest_progress.anchor_right = 1.0
	_quest_progress.offset_left = -110
	_quest_progress.offset_right = -12
	_quest_progress.offset_top = 7
	_quest_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quest_plate.add_child(_quest_progress)
	_objective = Label.new()
	_objective.name = "Objective"
	_objective.add_theme_font_size_override("font_size", 16)
	_objective.add_theme_color_override("font_color", q_body_col)
	_objective.anchor_right = 1.0
	_objective.offset_top = 26
	_objective.offset_left = 14
	_objective.offset_right = -12
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_plate.add_child(_objective)
	_objective_hint = Label.new()
	_objective_hint.add_theme_font_size_override("font_size", 14)
	_objective_hint.add_theme_color_override("font_color", q_prog_col)
	_objective_hint.anchor_right = 1.0
	_objective_hint.anchor_top = 1.0
	_objective_hint.anchor_bottom = 1.0
	_objective_hint.offset_left = 14
	_objective_hint.offset_right = -12
	_objective_hint.offset_top = -22
	_objective_hint.offset_bottom = -6
	_objective_hint.clip_text = true
	_quest_plate.add_child(_objective_hint)
	# D13 — sub-objective: names the chart / affixes you're delving. Bottom-
	# anchored so a wrapped 2-line objective can never collide with it (spec 52).
	_quest_sub = Label.new()
	_quest_sub.add_theme_font_size_override("font_size", 14)
	_quest_sub.add_theme_color_override("font_color", q_prog_col)
	_quest_sub.anchor_right = 1.0
	_quest_sub.anchor_top = 1.0
	_quest_sub.anchor_bottom = 1.0
	_quest_sub.offset_top = -26
	_quest_sub.offset_bottom = -7
	_quest_sub.offset_left = 14
	_quest_sub.offset_right = -12
	_quest_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_quest_sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	_quest_sub.clip_text = true
	_quest_plate.add_child(_quest_sub)
	# Spec 52 — a compass arrow just right of the objective chip, pointing at the
	# descent/exit. Self-resolves its target each frame; hides in town.
	_compass = CompassArrow.new()
	_compass.anchor_left = 0.0
	_compass.anchor_top = 0.0
	_compass.offset_left = 298
	_compass.offset_top = 12
	_compass.offset_right = 338
	_compass.offset_bottom = 52
	_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_compass)
	_build_action_bar()
	_toast_box = VBoxContainer.new()
	_toast_box.anchor_left = 0.5
	_toast_box.anchor_right = 0.5
	_toast_box.anchor_top = 1.0
	_toast_box.anchor_bottom = 1.0
	_toast_box.offset_top = -112
	_toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_box.alignment = BoxContainer.ALIGNMENT_END
	add_child(_toast_box)
	# Spec 52 (Direction A) — run-meta plaque, top-RIGHT (was bottom-right).
	_skills_lbl = Label.new()
	WyrdUi.style_chip(_skills_lbl, 14)
	_skills_lbl.anchor_left = 1.0
	_skills_lbl.anchor_right = 1.0
	_skills_lbl.anchor_top = 0.0
	_skills_lbl.anchor_bottom = 0.0
	_skills_lbl.offset_left = -194
	_skills_lbl.offset_right = -12
	_skills_lbl.offset_top = 10
	_skills_lbl.offset_bottom = 36
	_skills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_skills_lbl)
	var progress_game := _game_ref
	if progress_game != null:
		progress_game.tutorial_changed.connect(_on_tutorial_changed)
		if progress_game.has_signal("onboarding_changed"):
			progress_game.onboarding_changed.connect(_on_onboarding_changed)
		progress_game.materials_changed.connect(_on_materials_changed)
		progress_game.charts_changed.connect(_refresh_objective)
		progress_game.toast.connect(show_toast)
		progress_game.xp_gained.connect(_on_xp_gained)
		progress_game.leveled_up.connect(_on_trade_leveled)
		progress_game.gold_changed.connect(_on_gold_changed)
		_refresh_objective()
		_refresh_trades()
		_apply_progressive_hud()
		# Toasts buffered across the scene change (run completion, level-ups)
		# play here, in the scene the player actually sees.
		for msg in progress_game.drain_pending_toasts():
			show_toast(msg)


func _exit_tree() -> void:
	# Game is an autoload; the HUD is not. Named connections make teardown
	# deterministic even when a pause-immune toast tween briefly outlives the
	# scene that created it during a Web transition.
	var game := _game_ref
	if game == null or not is_instance_valid(game):
		_game_ref = null
		return
	var connections := [
		[game.modal_changed, _on_modal_changed],
		[game.tutorial_changed, _on_tutorial_changed],
		[game.onboarding_changed, _on_onboarding_changed],
		[game.materials_changed, _on_materials_changed],
		[game.charts_changed, _refresh_objective],
		[game.toast, show_toast],
		[game.xp_gained, _on_xp_gained],
		[game.leveled_up, _on_trade_leveled],
		[game.gold_changed, _on_gold_changed],
	]
	for pair in connections:
		var game_signal: Signal = pair[0]
		var callback: Callable = pair[1]
		if game_signal.is_connected(callback):
			game_signal.disconnect(callback)
	_game_ref = null


func _on_tutorial_changed(_step: int) -> void:
	_refresh_progress_surfaces()


func _on_onboarding_changed() -> void:
	_refresh_progress_surfaces()


func _on_materials_changed() -> void:
	_refresh_progress_surfaces()


func _refresh_progress_surfaces() -> void:
	_refresh_objective()
	_apply_progressive_hud()


func _on_xp_gained(_trade: String, _amount: int) -> void:
	_refresh_trades()


func _on_trade_leveled(trade: String, level: int) -> void:
	_refresh_trades()
	_show_levelup_banner(trade, level)
	_flash_skills()


func _on_gold_changed(_amount: int) -> void:
	_refresh_trades()

func _refresh_objective() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	var text := String(game.objective_text())
	_quest_plate.visible = text != ""
	_objective.text = text
	if _objective_hint != null:
		_objective_hint.text = String(game.objective_hint()) \
			if game.has_method("objective_hint") else ""
		_objective_hint.visible = _objective_hint.text != ""
	var prog := String(game.objective_progress())
	_quest_progress.text = prog
	_quest_progress.visible = prog != ""
	# D13 — the chart sub-objective (delving only). Spec 52: the compact chip
	# shows just the chart NAME (the part before the "—"); the full affix list is
	# too long for one line. A diamond prefixes it to echo the affix-icon mockup.
	if _quest_sub != null:
		var sub := String(game.objective_sub())
		var short := sub.split(" — ")[0] if sub.contains(" — ") else sub
		_quest_sub.text = ("◆ " + short) if short != "" else ""
		_quest_sub.visible = short != ""
		if _objective_hint != null:
			_objective_hint.offset_top = -40 if _quest_sub.visible else -22
			_objective_hint.offset_bottom = -24 if _quest_sub.visible else -6
	# Spec 53 — content-hug: size the chip to the wrapped objective + sub instead
	# of a fixed 96px box (kills the dead-teal pool under a single-line objective).
	_fit_quest_plate()

# Resize the quest chip to its content. Deferred a frame so the objective Label
# has wrapped and get_line_count() is accurate — so it never clips the text.
func _fit_quest_plate() -> void:
	await get_tree().process_frame
	if _quest_plate == null or not is_instance_valid(_quest_plate):
		return
	var lines: int = maxi(1, _objective.get_line_count())
	var h: float = 28.0 + float(lines) * 21.0
	if _objective_hint != null and _objective_hint.visible:
		h += 20.0
	if _quest_sub.visible:
		h += 20.0
	h += 8.0
	_quest_plate.offset_bottom = _quest_plate.offset_top + h

# Bottom-right action bar — Pack (I) and Satchel (M) as clickable parchment
# buttons, so the systems are discoverable without reading the guide.
func _build_action_bar() -> void:
	# Spec 52 (Direction A) — Gear/Satchel/Trades as compact icon buttons in the
	# Enamel kit, matching the hotbar's visual language. The word moves to the
	# tooltip; the key-hint sits top-left; the trade color rides a thin underline.
	var bar := HBoxContainer.new()
	bar.name = "ActionBar"
	_action_bar = bar
	# HUD "A" — the menu affordances group top-RIGHT under the run-meta readout,
	# so the bottom edge stays clean (orbs + centred hotbar only).
	bar.anchor_left = 1.0
	bar.anchor_right = 1.0
	bar.anchor_top = 0.0
	bar.anchor_bottom = 0.0
	# 3 × 50 + 2 × 8 sep = 166 wide, 50 tall; pinned top-right below the plaque.
	bar.offset_left = -174
	bar.offset_top = 42
	bar.offset_right = -12
	bar.offset_bottom = 94
	bar.add_theme_constant_override("separation", 6)
	add_child(bar)
	var fallback := {"gear": "⚔", "satchel": "❖", "trades": "✎"}
	for spec in [["Gear", "I", "toggle_inventory", "gear"],
			["Satchel", "M", "toggle_satchel", "satchel"],
			["Trades", "K", "toggle_trades", "trades"]]:
		var b := Button.new()
		b.name = "%sButton" % spec[0]
		b.theme = FIELD_THEME
		b.theme_type_variation = &"PrimaryButton"
		b.text = ""
		b.tooltip_text = "%s  (%s)" % [spec[0], spec[1]]
		b.custom_minimum_size = Vector2(48, 48)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Trade-color language: Gear terracotta, Satchel sage, Trades gold — now
		# carried by a thin underline tab, not the (removed) button text.
		var accent: Color = WyrdUi.TERRACOTTA
		if spec[3] == "satchel":
			accent = WyrdUi.SAGE
		elif spec[3] == "trades":
			accent = WyrdUi.GOLD
		# Icon — a child TextureRect (mirrors the hotbar slot icons exactly).
		var icon_path := "res://assets/ui/icons/%s.png" % spec[3]
		if ResourceLoader.exists(icon_path):
			var tr := TextureRect.new()
			tr.texture = load(icon_path)
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.anchor_right = 1.0
			tr.anchor_bottom = 1.0
			tr.offset_left = 6
			tr.offset_top = 6
			tr.offset_right = -6
			tr.offset_bottom = -6
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(tr)
		else:
			var gl := Label.new()
			gl.text = String(fallback.get(spec[3], "?"))
			var hdr := WyrdUi.font_header()
			if hdr != null:
				gl.add_theme_font_override("font", hdr)
			gl.add_theme_font_size_override("font_size", 22)
			gl.add_theme_color_override("font_color", WyrdUi.TEXT_ON_DARK)
			gl.anchor_right = 1.0
			gl.anchor_bottom = 1.0
			gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(gl)
		# Key-hint, top-left (neutral cream + dark outline, like the hotbar).
		var kb := Label.new()
		kb.text = spec[1]
		WyrdUi.style_keyhint(kb)   # spec 53 — same badge as the hotbar
		kb.position = Vector2(5, 2)
		kb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(kb)
		# Trade-color accent underline along the bottom edge.
		var underline := ColorRect.new()
		underline.color = accent
		underline.anchor_left = 0.0
		underline.anchor_right = 1.0
		underline.anchor_top = 1.0
		underline.anchor_bottom = 1.0
		underline.offset_left = 7
		underline.offset_right = -7
		underline.offset_top = -6
		underline.offset_bottom = -3
		underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(underline)
		var method: String = spec[2]
		b.pressed.connect(func():
			# Spec 46 — route HUD buttons to the LOCAL player in co-op.
			var game := get_tree().root.get_node_or_null("Game")
			var player: Node = game.local_player() if game != null \
				else null
			if player != null and player.has_method(method):
				player.call(method))
		bar.add_child(b)
		_action_buttons[String(spec[3])] = b

func _apply_progressive_hud() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	var slots := int(game.active_skill_slots()) \
		if game.has_method("active_skill_slots") else 4
	var combat_visible := bool(game.onboarding_surface_available("combat")) \
		if game.has_method("onboarding_surface_available") else true
	var focus_visible := bool(game.onboarding_surface_available("focus")) \
		if game.has_method("onboarding_surface_available") else slots > 1
	var has_draught := false
	for id in CraftingDefs.DRAUGHT_ORDER:
		if int(game.material_count(String(id))) > 0:
			has_draught = true
			break
	var total_slots := slots + (1 if has_draught else 0)
	var hotbar_w := float(total_slots) * HOTBAR_SLOT \
		+ float(maxi(0, total_slots - 1)) * HOTBAR_GAP
	var hp_right := -hotbar_w * 0.5 - 10.0
	var hp_left := hp_right - GLOBE_BOX
	var focus_left := hotbar_w * 0.5 + 10.0
	var focus_right := focus_left + GLOBE_BOX
	if _hp_globe != null:
		_hp_globe.visible = combat_visible
		_hp_globe.offset_left = hp_left
		_hp_globe.offset_right = hp_right
	if _focus_globe != null:
		_focus_globe.visible = combat_visible and focus_visible
		_focus_globe.offset_left = focus_left
		_focus_globe.offset_right = focus_right
	if _pip_row != null:
		_pip_row.visible = combat_visible
		_pip_row.offset_left = hp_left
		_pip_row.offset_right = hp_right
	if _cluster_tray != null:
		_cluster_tray.visible = combat_visible
		_cluster_tray.offset_left = hp_left - 8.0
		_cluster_tray.offset_right = (focus_right + 8.0) \
			if slots > 1 else hotbar_w * 0.5 + 8.0
		_cluster_tray.queue_redraw()
	var step := int(game.tutorial_step)
	if _action_buttons.has("satchel"):
		_action_buttons.satchel.visible = bool(
			game.onboarding_surface_available("satchel"))
	if _action_buttons.has("gear"):
		_action_buttons.gear.visible = bool(
			game.onboarding_surface_available("gear"))
	if _action_buttons.has("trades"):
		_action_buttons.trades.visible = bool(
			game.onboarding_surface_available("trades"))
	if _action_bar != null:
		_action_bar.visible = bool(game.onboarding_surface_available("satchel")) \
			or bool(game.onboarding_surface_available("gear")) \
			or bool(game.onboarding_surface_available("trades"))
	if _skills_lbl != null:
		_skills_lbl.visible = step >= 6 or int(game.gold) > 0

func _refresh_trades() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	_skills_lbl.text = "%dg · Wayfinding %d" % [
		int(game.gold), game.trade_lv("wayfinding")]
	_apply_progressive_hud()

func show_toast(msg: String, category: String = "info") -> void:
	# Dedup — a burst of identical chips in one window collapses to one.
	var now := float(Time.get_ticks_msec()) / 1000.0
	if msg == _last_toast_text and (now - _last_toast_time) < Feel.TOAST_DEDUP_WINDOW_SEC:
		return
	_last_toast_text = msg
	_last_toast_time = now
	var l := Label.new()
	l.text = msg
	# Spec 41 — toasts are kit parchment chips.
	WyrdUi.style_chip(l, 15)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var col: Color = WyrdUi.TEXT_ON_DARK
	if category == "levelup":
		col = WyrdUi.GOLD
	elif category == "damage":
		col = WyrdUi.TERRACOTTA
	l.add_theme_color_override("font_color", col)
	_toast_box.add_child(l)
	var hold: float = Feel.TOAST_LEVELUP_HOLD_SEC if category == "levelup" \
		else Feel.TOAST_HOLD_SEC
	var t := create_tween()
	# Pause-immune — most toasts (mix, inscribe, level-up) fire while a modal
	# has the tree paused; a pause-bound tween would freeze them into a stack.
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_interval(hold)
	t.tween_property(l, "modulate:a", 0.0, Feel.TOAST_FADE_SEC)
	t.tween_callback(l.queue_free)

# Plan.md B3 — the level-up "moment": a gold perk banner naming the unlock.
func _show_levelup_banner(trade: String, lv: int) -> void:
	var trade_name := String(Progression.TRADE_NAMES.get(trade, trade))
	var unlock := Progression.unlock_for_trade_level(trade, lv)
	var unlock_name := String(unlock.get("label", "%s %d" % [trade_name, lv]))
	show_toast("✦ %s %d — %s" % [trade_name, lv, unlock_name], "levelup")

# Gold glow + scale-punch on the Wayfinding readout when a level lands.
func _flash_skills() -> void:
	if _skills_lbl == null:
		return
	var base_col: Color = _skills_lbl.get_theme_color("font_color")
	_skills_lbl.pivot_offset = _skills_lbl.size * 0.5
	_skills_lbl.add_theme_color_override("font_color", WyrdUi.GOLD)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_skills_lbl, "scale",
		Vector2(Feel.LEVELUP_PUNCH_SCALE, Feel.LEVELUP_PUNCH_SCALE),
		Feel.LEVELUP_PUNCH_UP_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_skills_lbl, "scale", Vector2.ONE, Feel.LEVELUP_PUNCH_DOWN_SEC)
	tw.tween_interval(Feel.LEVELUP_FLASH_SEC)
	tw.tween_callback(func(): _skills_lbl.add_theme_color_override("font_color", base_col))

# ---- Phase 4: co-op party HUD (HP frame + reconnect/exit banner) -------------
var _party_panel: PanelContainer
var _party_box: VBoxContainer
var _coop_banner: Label
var _ending_left := 0.0

func _build_coop_hud() -> void:
	# Party HP frame — top-left, one row per peer. Shown only in co-op.
	_party_panel = PanelContainer.new()
	# PanelContainer auto-sizes to the VBox; style it with a parchment box
	# (WyrdUi.style_panel only accepts a plain Panel).
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.075, 0.231, 0.212, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = WyrdUi.GOLD
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(8)
	_party_panel.add_theme_stylebox_override("panel", sb)
	_party_panel.anchor_left = 0.0
	_party_panel.anchor_top = 0.0
	_party_panel.offset_left = 16.0
	_party_panel.offset_top = 16.0
	_party_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_panel.visible = false
	_party_box = VBoxContainer.new()
	_party_box.add_theme_constant_override("separation", 3)
	_party_panel.add_child(_party_box)
	add_child(_party_panel)
	# Prominent center-top banner for reconnect / exit-countdown events.
	_coop_banner = Label.new()
	WyrdUi.style_title(_coop_banner)
	_coop_banner.anchor_left = 0.5
	_coop_banner.anchor_right = 0.5
	_coop_banner.anchor_top = 0.0
	_coop_banner.offset_left = -280.0
	_coop_banner.offset_right = 280.0
	_coop_banner.offset_top = 78.0
	_coop_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coop_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coop_banner.visible = false
	add_child(_coop_banner)
	# One slow timer drives the party frame + the exit countdown.
	var t := Timer.new()
	t.wait_time = 0.25
	t.autostart = true
	t.timeout.connect(_coop_tick)
	add_child(t)
	# NetGame is an autoload — connecting offline is harmless (events never fire).
	NetGame.reconnecting.connect(func(a: int, m: int):
		_banner("Lost the host — reconnecting (%d/%d)…" % [a, m]))
	NetGame.roster_changed.connect(func():
		if _ending_left <= 0.0:
			_clear_banner())     # a settled roster means we're (re)connected
	NetGame.run_ending.connect(_on_run_ending)

func _banner(text: String) -> void:
	if _coop_banner == null:
		return
	_coop_banner.text = text
	_coop_banner.visible = true

func _clear_banner() -> void:
	if _coop_banner != null:
		_coop_banner.visible = false

func _on_run_ending(who: String, secs: float) -> void:
	_ending_left = secs
	_banner("%s steps through — returning in %d…" % [who, int(ceil(secs))])

func _coop_tick() -> void:
	_refresh_party()
	if _ending_left > 0.0:
		_ending_left -= 0.25
		if _ending_left <= 0.0:
			_clear_banner()
		else:
			_banner("Returning to town in %d…" % int(ceil(_ending_left)))

func _refresh_party() -> void:
	if _party_panel == null:
		return
	if not NetGame.active:
		if _party_panel.visible:
			_party_panel.visible = false
		return
	_party_panel.visible = true
	for c in _party_box.get_children():
		_party_box.remove_child(c)
		c.free()
	for p in get_tree().get_nodes_in_group("player"):
		var node := p as Node
		if node == null:
			continue
		var nm := NetGame.peer_name((node as Node).get_multiplayer_authority())
		var cur := int(node.get("hp"))
		var mx := maxi(1, int(node.get("hp_max")))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var lbl := Label.new()
		lbl.text = nm
		WyrdUi.style_body(lbl, 16)
		lbl.custom_minimum_size = Vector2(96, 0)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = mx
		bar.value = clampi(cur, 0, mx)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(86, 12)
		bar.modulate = Color(0.82, 0.26, 0.20) if cur > 0 else Color(0.45, 0.45, 0.45)
		row.add_child(lbl)
		row.add_child(bar)
		_party_box.add_child(row)

func set_hp(cur: int, mx: int, status_suffix: String = "") -> void:
	var f := clampf(float(cur) / float(max(1, mx)), 0.0, 1.0)
	if _hp_globe != null:
		_hp_globe.update_to(f, "%d/%d" % [max(0, cur), mx],
			status_suffix.strip_edges())

# Spec 30 — Focus is a float (regen is fractional) but displays as int.
func set_focus(cur: float, mx: float) -> void:
	var f := clampf(cur / max(1.0, mx), 0.0, 1.0)
	if _focus_globe != null:
		_focus_globe.update_to(f, "%d/%d" % [int(cur), int(mx)], "")

# A red screen pulse on taking a hit.
func flash() -> void:
	_flash.modulate.a = 0.5
	var t := create_tween()
	t.tween_property(_flash, "modulate:a", 0.0, 0.35)

# Slice B — build the radial hurt-vignette once: a full-screen TextureRect
# stretched over a radial GradientTexture2D (clear center → terracotta rim).
# Kept at modulate.a = 0 until a hit flashes it via hurt_vignette().
func _build_hurt_vignette() -> void:
	var grad := Gradient.new()
	# Center clear, holds clear through the middle, then ramps to a heavy
	# terracotta rim so the edges darken without obscuring the action.
	# Replace the default 2-point ramp wholesale (offsets + colors arrays so
	# point indices don't shift under us).
	grad.offsets = PackedFloat32Array([0.0, 0.55, 0.80, 1.0])
	grad.colors = PackedColorArray([
		Color(WyrdUi.TERRACOTTA, 0.0),
		Color(WyrdUi.TERRACOTTA, 0.0),
		Color(WyrdUi.TERRACOTTA, 0.45),
		Color(WyrdUi.TERRACOTTA.darkened(0.1), 0.85),
	])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 256
	gt.height = 256
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)        # radius reaches the horizontal edge
	_vignette = TextureRect.new()
	_vignette.texture = gt
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.anchor_right = 1.0
	_vignette.anchor_bottom = 1.0
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	add_child(_vignette)

# Slice B — flash the hurt-vignette: snap to full, fade out over ~0.25s.
# The player's take_damage hook calls this (orchestrator wires the one call
# site if it lives outside this file — see notes).
func hurt_vignette() -> void:
	if _vignette == null:
		return
	_vignette.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(_vignette, "modulate:a", 0.0, 0.25)

# Death white-out (spec 23) — the screen fades to white, the respawn
# happens unseen under it, then it fades back.
func whiteout_in() -> void:
	var t := create_tween()
	t.tween_property(_whiteout, "modulate:a", 1.0, 0.5)

func whiteout_out() -> void:
	var t := create_tween()
	t.tween_property(_whiteout, "modulate:a", 0.0, 0.5)

# Push the active-status list to the pip row (system-status-effects).
# pips: Array of {"kind": String, "frac": float}.
func update_pips(pips: Array) -> void:
	if _pip_row != null:
		_pip_row.set_statuses(pips)


# Spec 59 — compact, readable vital state. This is visualization-only (not an
# interaction), so a custom draw remains appropriate while ordinary buttons and
# rows migrate to semantic Controls.
class FieldMeter extends Control:
	var ratio := 1.0
	var value_text := ""
	var status_text := ""
	var caption := ""
	var fill_color := Tokens.SAGE

	func _ready() -> void:
		name = "Vital%s" % caption.capitalize()

	func update_to(next_ratio: float, next_text: String, next_status: String) -> void:
		ratio = clampf(next_ratio, 0.0, 1.0)
		value_text = next_text
		status_text = next_status
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var shell := StyleBoxFlat.new()
		shell.bg_color = Tokens.WALNUT
		shell.set_corner_radius_all(12)
		shell.set_border_width_all(2)
		shell.border_color = Tokens.WALNUT_DEEP
		draw_style_box(shell, rect)
		var well := rect.grow(-6.0)
		var well_box := StyleBoxFlat.new()
		well_box.bg_color = Tokens.MOSS
		well_box.set_corner_radius_all(7)
		draw_style_box(well_box, well)
		var fill := Rect2(well.position + Vector2(3, well.size.y - 13),
			Vector2(maxf(0.0, (well.size.x - 6.0) * ratio), 10.0))
		draw_rect(fill, fill_color)
		var font := WyrdUi.font_body()
		if font != null:
			draw_string(font, well.position + Vector2(7, 18), caption,
				HORIZONTAL_ALIGNMENT_LEFT, well.size.x * 0.42, 14, Tokens.TEXT_ON_DARK_DIM)
			draw_string(font, well.position + Vector2(well.size.x * 0.42, 18), value_text,
				HORIZONTAL_ALIGNMENT_RIGHT, well.size.x * 0.53 - 7, 16, Tokens.TEXT_ON_DARK)
			if status_text != "":
				draw_string(font, well.position + Vector2(7, 34), status_text,
					HORIZONTAL_ALIGNMENT_LEFT, well.size.x - 14, 14, Tokens.TEXT_ON_DARK_DIM)


# The maple cradle tray (hud2_cradle_3) — one wide cream pill with a chunky
# wood-brown frame + gold seam, its round ends cradling the HP/Focus orbs while
# the round skill slots sit along its belly. Pure StyleBoxFlat draws; sits behind
# the orbs (added first) and under skill_bar's slots (higher layer).
class ClusterTray extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var rad := 14
		# soft drop shadow
		var sh := StyleBoxFlat.new()
		sh.bg_color = Color(0, 0, 0, 0.22)
		sh.set_corner_radius_all(rad)
		sh.anti_aliasing = true
		draw_style_box(sh, Rect2(r.position + Vector2(0, 6), r.size))
		# Field Journal: walnut shell with a moss control recess.
		var pill := StyleBoxFlat.new()
		pill.bg_color = Tokens.WALNUT
		pill.set_corner_radius_all(rad)
		pill.corner_detail = 12
		pill.anti_aliasing = true
		pill.set_border_width_all(2)
		pill.border_color = Tokens.WALNUT_DEEP
		draw_style_box(pill, r)
		var recess := StyleBoxFlat.new()
		recess.bg_color = Color(Tokens.MOSS, 0.72)
		recess.set_corner_radius_all(10)
		recess.set_border_width_all(1)
		recess.border_color = Color(Tokens.GOLD_MUTED, 0.45)
		draw_style_box(recess, r.grow(-5.0))


# HUD "A" (user-picked, 2026-07-01) — a slim carved enamel + leaf-gold border
# hugging the viewport, with gilded brackets at the four corners, so the whole
# screen reads as one framed play window. Pure vector _draw (no textures —
# white-rect gotcha); redraws only on resize. Behind every widget, mouse-ignored,
# so it frames the play area without costing a single pixel of interaction.
class HudFrame extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 8.0 or h < 8.0:
			return
		var m := 7.0            # inset from the very edge
		var band := 10.0        # enamel band thickness
		var gold := WyrdUi.KIT_EDGE
		var teal := WyrdUi.KIT_PLATE
		var outer := Rect2(m, m, w - 2.0 * m, h - 2.0 * m)
		# A ROUNDED enamel border (soft, not a hard box). draw_center = false so
		# only the band paints and the world reads through the middle.
		var enamel := StyleBoxFlat.new()
		enamel.draw_center = false
		enamel.set_border_width_all(int(band))
		enamel.border_color = Color(teal, 0.68)
		enamel.set_corner_radius_all(30)
		enamel.corner_detail = 12
		enamel.anti_aliasing = true
		draw_style_box(enamel, outer)
		# Gold hairlines hugging the outer edge and the inner play window.
		_ring(outer, 30, Color(gold, 0.85), 1.5)
		_ring(outer.grow(-band), 22, Color(gold, 0.5), 1.0)
		# Soft fiddlehead-swirl flourishes tucked into each corner.
		_swirl(outer.position, 1.0, 1.0)
		_swirl(Vector2(outer.end.x, outer.position.y), -1.0, 1.0)
		_swirl(Vector2(outer.position.x, outer.end.y), 1.0, -1.0)
		_swirl(outer.end, -1.0, -1.0)

	# A rounded rectangular outline (hollow stylebox) — the soft frame's hairlines.
	func _ring(r: Rect2, radius: int, col: Color, width: float) -> void:
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.set_border_width_all(int(width))
		sb.border_color = col
		sb.set_corner_radius_all(radius)
		sb.corner_detail = 12
		sb.anti_aliasing = true
		draw_style_box(sb, r)

	# A gilded fiddlehead curl tucked into a corner (replaces the hard bracket).
	# Canonical shape authored for the top-left; (sx, sy) mirror it to the others.
	func _swirl(p: Vector2, sx: float, sy: float) -> void:
		var gold := WyrdUi.GOLD
		var core := p + Vector2(30.0 * sx, 30.0 * sy)   # curl eye sits inboard
		var pts := PackedVector2Array()
		var steps := 52
		for i in steps + 1:
			var t := float(i) / float(steps)            # 0 outer tail → 1 inner eye
			var ang := lerpf(-PI * 0.78, PI * 1.15, t)  # ~1.9 turns, opening at the corner
			var rad := lerpf(24.0, 2.5, t)              # spiral inward
			pts.append(core + Vector2(cos(ang) * rad * sx, sin(ang) * rad * sy))
		draw_polyline(pts, Color(gold, 0.9), 2.5, true)
		draw_circle(pts[pts.size() - 1], 2.2, Color(gold, 0.9))
		# Gentle gilded runs curving a little way along each edge from the curl.
		draw_line(p + Vector2(8.0 * sx, 0.0), p + Vector2(46.0 * sx, 0.0),
			Color(gold, 0.5), 2.0)
		draw_line(p + Vector2(0.0, 8.0 * sy), p + Vector2(0.0, 46.0 * sy),
			Color(gold, 0.5), 2.0)


# Spec 38 style pass — a potion orb in a bramble nest (Midjourney ref
# docs/ui-refs/mj_hud_bramble.png): glassy liquid with a hard specular,
# cradled by jittered twig rings with leaf + berry knots. All painted in
# _draw (no textures — see the white-texture gotcha in memory); the nest
# geometry is seeded once so it doesn't crawl between frames.
class GlobeGauge extends Control:
	var frac := 1.0
	var liquid := Color(0.70, 0.18, 0.14)
	var label := ""
	var status := ""
	const R := 36.0                                 # spec 52 — slimmer enamel gauge

	const RING_WOOD := Color(0.890, 0.722, 0.361)   # gold pinstripe
	const RING_BEZEL := Color(0.075, 0.231, 0.212)  # KIT_PLATE deep-teal enamel
	var _t := 0.0                                # animation clock (low-warn pulse)

	func update_to(p_frac: float, p_label: String, p_status: String) -> void:
		frac = clampf(p_frac, 0.0, 1.0)
		label = p_label
		status = p_status
		queue_redraw()

	# Only the low-resource danger pulse needs per-frame redraws; otherwise the
	# globe is static (redrawn on update_to).
	func _process(delta: float) -> void:
		if frac < 0.30:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		if WyrdUi.has_maple():
			# MapleStory orb: a chunky wood ring with a gold inner seam + shadow.
			draw_circle(c + Vector2(0, 3), R + 9.0, Color(0, 0, 0, 0.20))
			draw_arc(c, R + 6.0, 0, TAU, 64, WyrdUi.MAPLE_WOOD_D, 9.0, true)
			draw_arc(c, R + 5.0, 0, TAU, 64, WyrdUi.MAPLE_WOOD, 6.0, true)
			draw_arc(c, R + 1.5, 0, TAU, 64, Color(WyrdUi.GOLD, 0.85), 2.0, true)
		else:
			# --- slim enamel bezel (spec 52 Dir-A): teal rim + gold pinstripe ---
			draw_arc(c, R + 2.0, 0, TAU, 56, RING_BEZEL, 3.0, true)
			draw_arc(c, R + 4.5, 0, TAU, 56, RING_WOOD, 2.0, true)
		# --- glass orb ---
		draw_circle(c, R, Color(0.12, 0.10, 0.09))
		if frac > 0.003:
			var k := 1.0 - 2.0 * frac
			var a0 := asin(clampf(k, -1.0, 1.0))
			var pts := PackedVector2Array()
			for i in 41:
				var t := lerpf(a0, PI - a0, float(i) / 40.0)
				pts.append(c + Vector2(cos(t), sin(t)) * (R - 2.0))
			draw_colored_polygon(pts, liquid)
			# Deep-tone pool at the bottom of the liquid.
			var deep := PackedVector2Array()
			for i in 21:
				var t := lerpf(PI * 0.25, PI * 0.75, float(i) / 20.0)
				deep.append(c + Vector2(cos(t), sin(t)) * (R - 2.0))
			deep.append(c + Vector2(0, R * 0.45))
			draw_colored_polygon(deep, liquid.darkened(0.25))
			if frac < 0.997:
				var half := sqrt(maxf(0.0, 1.0 - k * k)) * (R - 2.0)
				draw_line(c + Vector2(-half, k * (R - 2.0)),
					c + Vector2(half, k * (R - 2.0)),
					liquid.lightened(0.35), 2.5)
			# Tiny bubbles riding above the deep pool.
			draw_circle(c + Vector2(-R * 0.2, R * 0.25), 2.2,
				liquid.lightened(0.4))
			draw_circle(c + Vector2(R * 0.15, R * 0.38), 1.6,
				liquid.lightened(0.45))
		# Hard storybook specular — the mock's signature read.
		draw_circle(c + Vector2(-R * 0.30, -R * 0.42), R * 0.20,
			Color(1, 1, 1, 0.55))
		draw_circle(c + Vector2(-R * 0.06, -R * 0.55), R * 0.08,
			Color(1, 1, 1, 0.40))
		# Slim ink rim, teal-tinted to belong to the enamel skin.
		draw_arc(c, R, 0, TAU, 56, Color(0.05, 0.14, 0.13), 2.0, true)
		# Low-resource danger pulse — a breathing rim in the liquid's own hue
		# so a near-empty HP/Focus globe pulls the eye.
		if frac < 0.30:
			var pulse := 0.30 + 0.40 * (0.5 + 0.5 * sin(_t * 6.5))
			draw_arc(c, R + 3.0, 0, TAU, 56,
				Color(liquid.lightened(0.15), pulse), 2.5, true)
		# --- numbers ---
		var f := get_theme_default_font()
		draw_string_outline(f, Vector2(0, c.y + 5), label,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, 5, Color(0.12, 0.09, 0.06))
		draw_string(f, Vector2(0, c.y + 5), label,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Color(0.97, 0.94, 0.86))
		if status != "":
			draw_string_outline(f, Vector2(0, c.y - 16), status,
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, 4, Color(0.12, 0.09, 0.06))
			draw_string(f, Vector2(0, c.y - 16), status,
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(0.95, 0.78, 0.5))


# Slice B — the quest plate's scroll dressing, drawn over the painted-wood
# 9-patch backing: faint parchment grain, a flourish under the QUEST header,
# and a small wax seal up top so the banner reads as a sealed proclamation.
# Pure-vector + WyrdUi primitives (grain + flourish); the seal is lifted from
# WyrdUi.draw_scroll. _draw-on-Control is the proven pattern in this layer.
# A row of small drain-arc pips, one per active player status, above the HP
# globe. Pure _draw (no textures — white-texture gotcha). The combatant has
# tint-pulse feedback; this is the player's at-a-glance "what's on me" readout.
class StatusPipRow extends Control:
	# Pip tints share the one per-kind status palette (StatusEffect.KIND_COLOR)
	# with the world-space status VFX in combatant.gd.
	var _pips: Array = []

	func _ready() -> void:
		resized.connect(queue_redraw)

	func set_statuses(pips: Array) -> void:
		_pips = pips
		queue_redraw()

	func _draw() -> void:
		const R := 8.0
		const GAP := 22.0
		if _pips.is_empty():
			return
		var cx: float = size.x * 0.5 - float(_pips.size() - 1) * GAP * 0.5
		for p in _pips:
			var col: Color = StatusEffect.KIND_COLOR.get(String(p.get("kind", "")), Color(0.7, 0.7, 0.7))
			draw_circle(Vector2(cx, R), R, col.darkened(0.3))
			var frac: float = clampf(float(p.get("frac", 1.0)), 0.0, 1.0)
			if frac > 0.0:
				draw_arc(Vector2(cx, R), R, -PI * 0.5, -PI * 0.5 + TAU * frac, 24, col, 3.5)
			cx += GAP


class QuestScrollArt extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x < 2.0 or size.y < 2.0:
			return
		# Spec 53 — editorial restraint for the compact chip: the flourish rule
		# crossed the objective baseline and the wax seal fought the corners, so
		# both are dropped. A whisper of grain is the only dressing; the "✦ Quest"
		# eyebrow carries the mark.
		var inner := Rect2(Vector2(18, 16), size - Vector2(36, 32))
		WyrdUi.draw_parchment_grain(self, inner, 23)


# Spec 52 — a top-down compass arrow that points at the run's descent target.
# Self-contained: resolves target, player, and camera each frame in _process.
# Target = the live exit/descent waystone (not the abandon stone), else the live
# boss arena. Hidden in town and on arrival. Duck-typed (the "abandoning"
# property) so it never references the ExitWaystone class_name (headless cache).
class CompassArrow extends Control:
	const REACHED_DIST := 1.6
	var _dir := Vector2.UP

	func _process(dt: float) -> void:
		var target := _resolve_target()
		var cam := get_viewport().get_camera_3d()
		var game := get_node_or_null("/root/Game")
		var player: Node3D = game.local_player() if game != null else null
		if target == null or cam == null or player == null:
			visible = false
			return
		var d: Vector3 = target.global_position - player.global_position
		d.y = 0.0
		if d.length() < REACHED_DIST:
			visible = false
			return
		# Camera GROUND basis (pitch flattened) → a top-down compass read.
		var f: Vector3 = -cam.global_basis.z
		f.y = 0.0
		f = f.normalized()
		var r: Vector3 = cam.global_basis.x
		r.y = 0.0
		r = r.normalized()
		var want := Vector2(d.dot(r), -d.dot(f)).normalized()   # y-down screen
		_dir = _dir.slerp(want, clampf(8.0 * dt, 0.0, 1.0))
		visible = true
		queue_redraw()

	# The descent target: the live exit/descent stone, else the live boss arena.
	func _resolve_target() -> Node3D:
		var tree := get_tree()
		if tree == null:
			return null
		var game := get_node_or_null("/root/Game")
		if game != null and not bool(game.in_dungeon):
			if game.has_method("onboarding_compass_available") \
					and not bool(game.onboarding_compass_available()):
				return null
			match int(game.tutorial_step):
				0:
					return tree.get_first_node_in_group("tutorial_mara") as Node3D
				1:
					for n in tree.get_nodes_in_group("interactable"):
						if str(n.get("kind")) == "forage_node" \
								and (not n.has_method("is_used") or not n.is_used()):
							return n as Node3D
				2, 3:
					return tree.get_first_node_in_group("inscribing_table") as Node3D
				4:
					return tree.get_first_node_in_group("tutorial_waystone") as Node3D
				6:
					if not bool(game.seen_hints.get("power_shot_practiced", false)):
						return tree.get_first_node_in_group("power_shot_practice") as Node3D
					return tree.get_first_node_in_group("inscribing_table") as Node3D
				_:
					return null
		for n in tree.get_nodes_in_group("interactable"):
			var ab = n.get("abandoning")       # only the waystones carry this
			if ab != null and not bool(ab) and n.has_method("is_used") \
					and not n.is_used():
				return n
		for e in tree.get_nodes_in_group("enemy"):
			if String(e.get("role")) == "boss" and not bool(e.get("dead")):
				return e
		return null

	func _draw() -> void:
		var c := size * 0.5
		var perp := Vector2(-_dir.y, _dir.x)
		var tip := c + _dir * 18.0
		var bl := c - _dir * 9.0 + perp * 9.0
		var br := c - _dir * 9.0 - perp * 9.0
		WyrdUi.draw_round_well(self, c, 22.0, WyrdUi.KIT_PLATE)
		draw_colored_polygon(PackedVector2Array([tip, bl, br]), WyrdUi.GOLD)
		draw_polyline(PackedVector2Array([tip, bl, br, tip]),
			WyrdUi.KIT_EDGE, 1.5, true)
