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

@onready var _fill: ColorRect = $HPRoot/Fill
@onready var _label: Label = $HPRoot/Label
@onready var _flash: ColorRect = $Flash
@onready var _whiteout: ColorRect = $Whiteout
@onready var _focus_fill: ColorRect = $FocusRoot/Fill
@onready var _focus_label: Label = $FocusRoot/Label

# Wyrd — quest tracker, toast stack, and the Wayfinding readout.
var _objective: Label
var _quest_plate: Panel
var _quest_progress: Label
var _toast_box: VBoxContainer
var _trades_readout: TradesReadout = null
# Spec 38 — potion globes (PoE-style): HP red bottom-left of the skill
# bar, Focus blue bottom-right. The liquid level IS the meter.
var _hp_globe: GlobeGauge = null
var _focus_globe: GlobeGauge = null
var _mute_lbl: Label = null
# Slice B — a radial hurt-vignette: transparent center darkening to a
# terracotta rim, flashed on the player taking damage (richer than the flat
# full-screen red _flash). A TextureRect fed by a radial GradientTexture2D —
# no shader, no _draw, so it's safe in this CanvasLayer.
var _vignette: TextureRect = null

func _ready() -> void:
	# Spec-35: scale up the HP + Focus bars together. Flash and Whiteout
	# need to remain viewport-sized; reset their scale parent on each
	# (they're full-screen ColorRects, anchored to all sides).
	# Wyrd UI overhaul — the tscn ColorRect bars become parchment meters.
	$HPRoot.visible = false
	$FocusRoot.visible = false
	_hp_globe = GlobeGauge.new()
	_hp_globe.liquid = Color(0.70, 0.18, 0.14)
	_place_globe(_hp_globe, -220.0)
	_focus_globe = GlobeGauge.new()
	_focus_globe.liquid = Color(0.20, 0.42, 0.62)
	_place_globe(_focus_globe, 220.0)
	_hp_globe.update_to(1.0, "30/30", "")
	_focus_globe.update_to(1.0, "50/50", "")
	_build_hurt_vignette()
	_build_draught_chip()
	_build_mute_indicator()
	_build_wyrd_overlay()

# A globe flanking the bottom-center skill bar at ±cx.
func _place_globe(g: GlobeGauge, cx: float) -> void:
	g.anchor_left = 0.5
	g.anchor_right = 0.5
	g.anchor_top = 1.0
	g.anchor_bottom = 1.0
	g.offset_left = cx - 66
	g.offset_right = cx + 66
	g.offset_top = -148
	g.offset_bottom = -16
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(g)

# Spec 38 — the mute state, by the Focus globe. F10 flips it.
func _build_mute_indicator() -> void:
	_mute_lbl = Label.new()
	_mute_lbl.anchor_left = 0.5
	_mute_lbl.anchor_right = 0.5
	_mute_lbl.anchor_top = 1.0
	_mute_lbl.anchor_bottom = 1.0
	_mute_lbl.offset_left = 140
	_mute_lbl.offset_right = 300
	_mute_lbl.offset_top = -22
	_mute_lbl.offset_bottom = -4
	_mute_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	WyrdUi.style_chip(_mute_lbl, 12)
	add_child(_mute_lbl)
	var game := get_tree().root.get_node_or_null("Game")
	if game != null and game.has_signal("mute_changed"):
		game.mute_changed.connect(func(_m): _refresh_mute())
	_refresh_mute()

func _refresh_mute() -> void:
	if _mute_lbl == null:
		return
	var game := get_tree().root.get_node_or_null("Game")
	var muted: bool = game != null and bool(game.get("muted"))
	_mute_lbl.text = "MUTED · F10" if muted else "F10 mutes"
	_mute_lbl.add_theme_color_override("font_color",
		WyrdUi.TERRACOTTA if muted else Color(0.36, 0.29, 0.22, 0.8))

# Draught counter under the meters — what Q will drink.
var _draught_lbl: Label = null

func _build_draught_chip() -> void:
	_draught_lbl = Label.new()
	_draught_lbl.anchor_left = 0.5
	_draught_lbl.anchor_right = 0.5
	_draught_lbl.anchor_top = 1.0
	_draught_lbl.anchor_bottom = 1.0
	_draught_lbl.offset_left = -300
	_draught_lbl.offset_right = -140
	_draught_lbl.offset_top = -22
	_draught_lbl.offset_bottom = -4
	_draught_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	WyrdUi.style_chip(_draught_lbl, 13)
	add_child(_draught_lbl)
	var game := get_tree().root.get_node_or_null("Game")
	if game != null:
		game.materials_changed.connect(_refresh_draughts)
	_refresh_draughts()

func _refresh_draughts() -> void:
	if _draught_lbl == null:
		return
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	var n: int = int(game.material_count("hearth_draught")) \
		+ int(game.material_count("deep_draught"))
	_draught_lbl.text = "" if n == 0 else "♨ ×%d · Q" % n

# ---- Wyrd overlay: objective + toasts + skill levels ----
func _build_wyrd_overlay() -> void:
	# Quest tracker — a parchment scroll plate top-center, with a small-caps
	# QUEST header, the objective, and a live progress counter.
	_quest_plate = Panel.new()
	# Slice B — promote the quest tracker from a flat chip to a SEALED SCROLL:
	# a painted-wood 9-patch backing + a drawn parchment-grain / flourish /
	# wax-seal overlay (QuestScrollArt below). The button-plate art (144×80,
	# 18px margins) is the right scale for a ~90px banner — panel_frame's
	# ~37/40px margins would crush a plate this short — so it's the primary,
	# with the chip stylebox as the only fallback.
	if ResourceLoader.exists(WyrdUi.BUTTON_TEX_PATH):
		var sb := StyleBoxTexture.new()
		sb.texture = load(WyrdUi.BUTTON_TEX_PATH)
		sb.texture_margin_left = WyrdUi.BUTTON_MARGIN
		sb.texture_margin_right = WyrdUi.BUTTON_MARGIN
		sb.texture_margin_top = WyrdUi.BUTTON_MARGIN
		sb.texture_margin_bottom = WyrdUi.BUTTON_MARGIN
		_quest_plate.add_theme_stylebox_override("panel", sb)
	else:
		_quest_plate.add_theme_stylebox_override("panel", WyrdUi.chip_stylebox())
	_quest_plate.anchor_left = 0.5
	_quest_plate.anchor_right = 0.5
	_quest_plate.offset_left = -260
	_quest_plate.offset_right = 260
	_quest_plate.offset_top = 10
	_quest_plate.offset_bottom = 92
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
	qhdr.text = "✦ Quest"
	var hf := WyrdUi.font_header()
	if hf != null:
		qhdr.add_theme_font_override("font", hf)
	qhdr.add_theme_font_size_override("font_size", 14)
	qhdr.add_theme_color_override("font_color", WyrdUi.TERRACOTTA)
	qhdr.anchor_right = 1.0
	qhdr.offset_top = 11
	qhdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_plate.add_child(qhdr)
	_objective = Label.new()
	_objective.add_theme_font_size_override("font_size", 16)
	_objective.add_theme_color_override("font_color", WyrdUi.INK)
	_objective.anchor_right = 1.0
	_objective.offset_top = 26
	_objective.offset_left = 16
	_objective.offset_right = -16
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_plate.add_child(_objective)
	_quest_progress = Label.new()
	_quest_progress.add_theme_font_size_override("font_size", 14)
	_quest_progress.add_theme_color_override("font_color",
		WyrdUi.SAGE.darkened(0.2))
	_quest_progress.anchor_right = 1.0
	_quest_progress.anchor_top = 1.0
	_quest_progress.anchor_bottom = 1.0
	_quest_progress.offset_top = -26
	_quest_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_plate.add_child(_quest_progress)
	_build_action_bar()
	_toast_box = VBoxContainer.new()
	_toast_box.anchor_left = 0.5
	_toast_box.anchor_right = 0.5
	_toast_box.anchor_top = 1.0
	_toast_box.anchor_bottom = 1.0
	_toast_box.offset_top = -170
	_toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_box.alignment = BoxContainer.ALIGNMENT_END
	add_child(_toast_box)
	_trades_readout = TradesReadout.new()
	_trades_readout.anchor_left = 1.0
	_trades_readout.anchor_right = 1.0
	_trades_readout.anchor_top = 1.0
	_trades_readout.anchor_bottom = 1.0
	_trades_readout.offset_left = -330
	_trades_readout.offset_right = -10
	_trades_readout.offset_top = -26
	add_child(_trades_readout)
	var game := get_tree().root.get_node_or_null("Game")
	if game != null:
		game.tutorial_changed.connect(func(_s): _refresh_objective())
		game.materials_changed.connect(_refresh_objective)
		game.charts_changed.connect(_refresh_objective)
		game.toast.connect(show_toast)
		game.xp_gained.connect(func(_k, _a): _refresh_trades())
		game.leveled_up.connect(func(_k, _l): _refresh_trades())
		game.gold_changed.connect(func(_g): _refresh_trades())
		_refresh_objective()
		_refresh_trades()
		# Toasts buffered across the scene change (run completion, level-ups)
		# play here, in the scene the player actually sees.
		for msg in game.drain_pending_toasts():
			show_toast(msg)

func _refresh_objective() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	var text := String(game.objective_text())
	_quest_plate.visible = text != ""
	_objective.text = text
	var prog := String(game.objective_progress())
	_quest_progress.text = prog
	_quest_progress.visible = prog != ""

# Bottom-right action bar — Pack (I) and Satchel (M) as clickable parchment
# buttons, so the systems are discoverable without reading the guide.
func _build_action_bar() -> void:
	var bar := HBoxContainer.new()
	bar.anchor_left = 1.0
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = -360
	bar.offset_top = -96
	bar.offset_right = -16
	bar.offset_bottom = -56
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)
	for spec in [["Gear", "I", "toggle_inventory", "gear"],
			["Satchel", "M", "toggle_satchel", "satchel"],
			["Trades", "K", "toggle_trades", "trades"]]:
		var b := Button.new()
		WyrdUi.style_kit_button(b)
		# Carry the trade-color language: Gear terracotta, Satchel sage, Trades gold.
		var accent: Color = WyrdUi.TERRACOTTA
		if spec[3] == "satchel":
			accent = WyrdUi.SAGE
		elif spec[3] == "trades":
			accent = WyrdUi.GOLD
		b.add_theme_color_override("font_color", accent.darkened(0.12))
		b.add_theme_color_override("font_hover_color", accent)
		b.text = "%s (%s)" % [spec[0], spec[1]]
		var icon_path := "res://assets/ui/icons/%s.png" % spec[3]
		if ResourceLoader.exists(icon_path):
			b.icon = load(icon_path)
			b.add_theme_constant_override("icon_max_width", 22)
			b.expand_icon = false
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var method: String = spec[2]
		b.pressed.connect(func():
			# Spec 46 — route HUD buttons to the LOCAL player in co-op.
			var game := get_tree().root.get_node_or_null("Game")
			var player: Node = game.local_player() if game != null \
				else get_tree().get_first_node_in_group("player")
			if player != null and player.has_method(method):
				player.call(method))
		bar.add_child(b)

func _refresh_trades() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	if _trades_readout != null:
		_trades_readout.update(int(game.gold), game.trade_lv("wayfinding"))

func show_toast(msg: String) -> void:
	var l := Label.new()
	l.text = msg
	# Spec 41 — toasts are kit parchment chips.
	WyrdUi.style_chip(l, 15)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_toast_box.add_child(l)
	var t := create_tween()
	# Pause-immune — most toasts (mix, inscribe, level-up) fire while a modal
	# has the tree paused; a pause-bound tween would freeze them into a stack.
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_interval(2.4)
	t.tween_property(l, "modulate:a", 0.0, 0.6)
	t.tween_callback(l.queue_free)

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
	const R := 40.0

	const RING_WOOD := Color(0.85, 0.74, 0.52)   # pale carved honey
	const RING_EDGE := Color(0.26, 0.19, 0.13)
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
		# --- carved wood-ring (spec 41 gate: kit variant A) ---
		draw_arc(c, R + 8.0, 0, TAU, 64, RING_WOOD, 14.0, true)
		draw_arc(c, R + 15.0, 0, TAU, 64, RING_EDGE, 2.5, true)
		draw_arc(c, R + 1.5, 0, TAU, 64, RING_EDGE, 2.0, true)
		for i in 4:
			var a := PI * 0.25 + float(i) * PI * 0.5
			var np := c + Vector2(cos(a), sin(a)) * (R + 8.0)
			WyrdUi.draw_round_well(self, np, 8.0, Color(0.93, 0.88, 0.74))
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
		# Ink rim.
		draw_arc(c, R, 0, TAU, 64, Color(0.20, 0.14, 0.10), 3.5, true)
		# Low-resource danger pulse — a breathing rim in the liquid's own hue
		# so a near-empty HP/Focus globe pulls the eye.
		if frac < 0.30:
			var pulse := 0.30 + 0.40 * (0.5 + 0.5 * sin(_t * 6.5))
			draw_arc(c, R + 4.0, 0, TAU, 64,
				Color(liquid.lightened(0.15), pulse), 3.0, true)
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
class QuestScrollArt extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x < 2.0 or size.y < 2.0:
			return
		# Faint parchment grain across the inner face (inset off the wood frame).
		var inner := Rect2(Vector2(18, 16), size - Vector2(36, 32))
		WyrdUi.draw_parchment_grain(self, inner, 23)
		# Flourish centred under the QUEST header (header sits ~y 11–28).
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 30.0), 120.0)
		# A small wax seal up top-left, clear of the wood frame — the scroll's
		# signature read (same motif as WyrdUi.draw_scroll's seal).
		var sc := Vector2(28.0, 24.0)
		draw_circle(sc, 7.0, Color(0.62, 0.20, 0.16))
		draw_circle(sc, 4.2, Color(0.72, 0.28, 0.22))
		draw_arc(sc, 7.0, 0, TAU, 20, Color(0.40, 0.12, 0.10), 1.5, true)


# A hand-drawn chip for the bottom-right gold + Wayfinding readout. Replaces
# the plain chip Label so each value gets its accent colour — gold ◆ for
# coin, terracotta ✦ for the Wayfinder trade — matching the action bar buttons
# immediately above it and making the readout feel like a carved placard
# rather than a tooltip.
class TradesReadout extends Control:
	var _gold := 0
	var _wf_lv := 1

	func update(g: int, wf: int) -> void:
		_gold = g
		_wf_lv = wf
		queue_redraw()

	func _draw() -> void:
		if size.x < 4.0 or size.y < 4.0:
			return
		var r := Rect2(Vector2.ZERO, size)
		# Chip face — parchment plate + ink border, same recipe as
		# chip_stylebox() so it reads as one family with the other HUD chips.
		draw_rect(r.grow(-0.75), WyrdUi.KIT_PLATE, true)
		draw_rect(r.grow(-0.75), WyrdUi.KIT_EDGE, false, 1.5)
		# Faint parchment grain so the face breathes like real pressed paper.
		WyrdUi.draw_parchment_grain(self, r.grow(-2.0), 9)
		var f := get_theme_default_font()
		var cy := size.y * 0.5 + 5.0
		# ◆ coin glyph + amount in WyrdUi.GOLD — a small wealth flash.
		draw_string(f, Vector2(8.0, cy), "◆ %dg" % _gold,
			HORIZONTAL_ALIGNMENT_LEFT, 88.0, 13, WyrdUi.GOLD)
		# Thin ink separator between the two values.
		var sx := 100.0
		draw_line(Vector2(sx, 4.0), Vector2(sx, size.y - 4.0),
			Color(WyrdUi.KIT_EDGE, 0.40), 1.0)
		# ✦ Wayfinding level in terracotta — matches the Gear action button.
		draw_string(f, Vector2(sx + 7.0, cy), "✦ Wayfinding %d" % _wf_lv,
			HORIZONTAL_ALIGNMENT_LEFT, size.x - sx - 13.0, 13,
			WyrdUi.TERRACOTTA.darkened(0.10))
