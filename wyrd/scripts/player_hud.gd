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

@onready var _fill: ColorRect = $HPRoot/Fill
@onready var _label: Label = $HPRoot/Label
@onready var _flash: ColorRect = $Flash
@onready var _whiteout: ColorRect = $Whiteout
@onready var _focus_fill: ColorRect = $FocusRoot/Fill
@onready var _focus_label: Label = $FocusRoot/Label

# Wyrd — quest tracker, toast stack, and the Wayfinding readout.
var _objective: Label
var _quest_sub: Label         # D13 — chart sub-objective line
var _quest_plate: Panel
var _compass: CompassArrow = null      # spec 52 — points at the descent/exit
var _quest_progress: Label
var _toast_box: VBoxContainer
var _skills_lbl: Label
var _last_toast_text := ""        # toast dedup (Feel.TOAST_DEDUP_WINDOW_SEC)
var _last_toast_time := 0.0
# Spec 38 — potion globes (PoE-style): HP red bottom-left of the skill
# bar, Focus blue bottom-right. The liquid level IS the meter.
var _hp_globe: GlobeGauge = null
var _focus_globe: GlobeGauge = null
var _pip_row: StatusPipRow = null      # active-status drain-arc pips above HP
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
	_place_globe(_hp_globe, -258.0)
	_focus_globe = GlobeGauge.new()
	_focus_globe.liquid = WyrdUi.FOCUS   # spec 53 — on-palette teal-cyan, not mana-blue
	_place_globe(_focus_globe, 258.0)
	_hp_globe.update_to(1.0, "30/30", "")
	_focus_globe.update_to(1.0, "50/50", "")
	# Status pip row — drain-arc pips above the HP globe (system-status-effects).
	_pip_row = StatusPipRow.new()
	_pip_row.anchor_left = 0.5
	_pip_row.anchor_right = 0.5
	_pip_row.anchor_top = 1.0
	_pip_row.anchor_bottom = 1.0
	_pip_row.offset_left = -324
	_pip_row.offset_right = -192
	_pip_row.offset_top = -176
	_pip_row.offset_bottom = -154
	_pip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pip_row)
	_build_hurt_vignette()
	_build_mute_indicator()
	_build_wyrd_overlay()
	_build_coop_hud()

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
		sb.modulate_color = WyrdUi.PANEL_MOD   # spec 51 — darken to match the skin
		_quest_plate.add_theme_stylebox_override("panel", sb)
	else:
		_quest_plate.add_theme_stylebox_override("panel", WyrdUi.chip_stylebox())
	# Spec 52 (Direction A) — a compact objective chip pinned top-LEFT, not a
	# 520px banner centred over the world. One line + an affix sub-line.
	_quest_plate.anchor_left = 0.0
	_quest_plate.anchor_right = 0.0
	_quest_plate.offset_left = 16
	_quest_plate.offset_right = 360
	_quest_plate.offset_top = 12
	_quest_plate.offset_bottom = 108
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
	qhdr.add_theme_font_size_override("font_size", 11)
	qhdr.add_theme_color_override("font_color", WyrdUi.GOLD)
	qhdr.offset_left = 16
	qhdr.anchor_right = 1.0
	qhdr.offset_top = 9
	qhdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_quest_plate.add_child(qhdr)
	# Progress counter rides the top-right corner of the chip, beside the eyebrow.
	_quest_progress = Label.new()
	_quest_progress.add_theme_font_size_override("font_size", 12)
	_quest_progress.add_theme_color_override("font_color", WyrdUi.SAGE)
	_quest_progress.anchor_right = 1.0
	_quest_progress.offset_left = -110
	_quest_progress.offset_right = -14
	_quest_progress.offset_top = 9
	_quest_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quest_plate.add_child(_quest_progress)
	_objective = Label.new()
	_objective.add_theme_font_size_override("font_size", 14)
	_objective.add_theme_color_override("font_color", WyrdUi.INK)
	_objective.anchor_right = 1.0
	_objective.offset_top = 26
	_objective.offset_left = 16
	_objective.offset_right = -14
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_plate.add_child(_objective)
	# D13 — sub-objective: names the chart / affixes you're delving. Bottom-
	# anchored so a wrapped 2-line objective can never collide with it (spec 52).
	_quest_sub = Label.new()
	_quest_sub.add_theme_font_size_override("font_size", 11)
	_quest_sub.add_theme_color_override("font_color", WyrdUi.SAGE.darkened(0.05))
	_quest_sub.anchor_right = 1.0
	_quest_sub.anchor_top = 1.0
	_quest_sub.anchor_bottom = 1.0
	_quest_sub.offset_top = -26
	_quest_sub.offset_bottom = -7
	_quest_sub.offset_left = 16
	_quest_sub.offset_right = -14
	_quest_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_quest_sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	_quest_sub.clip_text = true
	_quest_plate.add_child(_quest_sub)
	# Spec 52 — a compass arrow just right of the objective chip, pointing at the
	# descent/exit. Self-resolves its target each frame; hides in town.
	_compass = CompassArrow.new()
	_compass.anchor_left = 0.0
	_compass.anchor_top = 0.0
	_compass.offset_left = 368
	_compass.offset_top = 14
	_compass.offset_right = 368 + 48
	_compass.offset_bottom = 14 + 48
	_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_compass)
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
	# Spec 52 (Direction A) — run-meta plaque, top-RIGHT (was bottom-right).
	_skills_lbl = Label.new()
	WyrdUi.style_chip(_skills_lbl, 13)
	_skills_lbl.anchor_left = 1.0
	_skills_lbl.anchor_right = 1.0
	_skills_lbl.anchor_top = 0.0
	_skills_lbl.anchor_bottom = 0.0
	_skills_lbl.offset_left = -260
	_skills_lbl.offset_right = -16
	_skills_lbl.offset_top = 12
	_skills_lbl.offset_bottom = 42
	_skills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_skills_lbl)
	var game := get_tree().root.get_node_or_null("Game")
	if game != null:
		game.tutorial_changed.connect(func(_s): _refresh_objective())
		game.materials_changed.connect(_refresh_objective)
		game.charts_changed.connect(_refresh_objective)
		game.toast.connect(show_toast)
		game.xp_gained.connect(func(_k, _a): _refresh_trades())
		game.leveled_up.connect(func(k: String, l: int):
			_refresh_trades()
			_show_levelup_banner(k, l)   # Plan.md B3 — the level-up moment
			_flash_skills())
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
	# D13 — the chart sub-objective (delving only). Spec 52: the compact chip
	# shows just the chart NAME (the part before the "—"); the full affix list is
	# too long for one line. A diamond prefixes it to echo the affix-icon mockup.
	if _quest_sub != null:
		var sub := String(game.objective_sub())
		var short := sub.split(" — ")[0] if sub.contains(" — ") else sub
		_quest_sub.text = ("◆ " + short) if short != "" else ""
		_quest_sub.visible = short != ""

# Bottom-right action bar — Pack (I) and Satchel (M) as clickable parchment
# buttons, so the systems are discoverable without reading the guide.
func _build_action_bar() -> void:
	# Spec 52 (Direction A) — Gear/Satchel/Trades as compact icon buttons in the
	# Enamel kit, matching the hotbar's visual language. The word moves to the
	# tooltip; the key-hint sits top-left; the trade color rides a thin underline.
	var bar := HBoxContainer.new()
	bar.anchor_left = 1.0
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	# 3 × 50 + 2 × 8 sep = 166 wide, 50 tall; pinned bottom-right.
	bar.offset_left = -182
	bar.offset_top = -110
	bar.offset_right = -16
	bar.offset_bottom = -60
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)
	var fallback := {"gear": "⚔", "satchel": "❖", "trades": "✎"}
	for spec in [["Gear", "I", "toggle_inventory", "gear"],
			["Satchel", "M", "toggle_satchel", "satchel"],
			["Trades", "K", "toggle_trades", "trades"]]:
		var b := Button.new()
		WyrdUi.style_kit_button(b)
		b.text = ""
		b.tooltip_text = "%s  (%s)" % [spec[0], spec[1]]
		b.custom_minimum_size = Vector2(50, 50)
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
			tr.offset_left = 8
			tr.offset_top = 8
			tr.offset_right = -8
			tr.offset_bottom = -8
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(tr)
		else:
			var gl := Label.new()
			gl.text = String(fallback.get(spec[3], "?"))
			var hdr := WyrdUi.font_header()
			if hdr != null:
				gl.add_theme_font_override("font", hdr)
			gl.add_theme_font_size_override("font_size", 22)
			gl.add_theme_color_override("font_color", WyrdUi.INK)
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

func _refresh_trades() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game == null:
		return
	_skills_lbl.text = "%dg · Wayfinding %d" % [
		int(game.gold), game.trade_lv("wayfinding")]

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
	var col: Color = WyrdUi.INK
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
	var game := get_tree().root.get_node_or_null("Game")
	var perk_name := "Wayfinding %d" % lv
	if game != null:
		for p in Array(game.PERKS.get(trade, [])):
			if int(p.lv) == lv:
				perk_name = String(p.name)
				break
	show_toast("✦ %s" % perk_name, "levelup")

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
		WyrdUi.style_body(lbl, 12)
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
		# --- slim enamel bezel (spec 52 Dir-A): teal rim + gold pinstripe,
		#     no thick wood ring, no bramble pegs ---
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
	const PIP_COLOR := {
		"burn":   Color(1.00, 0.55, 0.18), "bleed":  Color(0.85, 0.20, 0.20),
		"snared": Color(0.45, 0.65, 0.30), "root":   Color(0.30, 0.65, 0.25),
		"marked": Color(1.00, 0.82, 0.30),
	}
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
			var col: Color = PIP_COLOR.get(String(p.get("kind", "")), Color(0.7, 0.7, 0.7))
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
