extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.
#
# Art pass: WyrdUi kit frame + title, and each buff card is a hand-drawn
# _ShrineBuffCard — parchment body, stat-coloured crown bar, round icon well,
# flourish rule, name in header font, world-voice desc. Godot not installed
# in the cloud; tested code-level only.

signal chosen(buff: Dictionary)

var _buffs: Array = []
var _panel: Panel
var _hbox: HBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	# Dim backdrop — also swallows mouse clicks so the player can't click
	# through the modal into the world.
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	# Panel — wooden kit frame.
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.custom_minimum_size = Vector2(660, 360)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -330
	_panel.offset_top = -180
	_panel.offset_right = 330
	_panel.offset_bottom = 180
	add_child(_panel)
	# Title — kit header font + TERRACOTTA.
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 16
	title.offset_bottom = 60
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	# Flourish under title.
	var rule := _FlourishRule.new()
	rule.anchor_left = 0.0
	rule.anchor_right = 1.0
	rule.offset_top = 62
	rule.offset_bottom = 80
	_panel.add_child(rule)
	# HBox for the 3 buff cards.
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 20)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 84
	_hbox.offset_bottom = -20
	_hbox.offset_left = 16
	_hbox.offset_right = -16
	_panel.add_child(_hbox)

# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var card := _ShrineBuffCard.new()
		card.setup(b)
		card.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# ── thin ─◆─ rule drawn inline, centred in its Control ──────────────────────
class _FlourishRule extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y * 0.5), size.x * 0.55)


# ── one drawn altar blessing card ────────────────────────────────────────────
# Parchment plate, stat-coloured crown bar, round icon socket, IM Fell name,
# flourish rule, body desc. StyleBoxEmpty suppresses default Button chrome so
# the _draw() face owns the look entirely.
class _ShrineBuffCard extends Button:
	# Single unicode glyph per stat: bold, recognisable, one character.
	const STAT_GLYPH := {
		"hp":          "❤",
		"damage":      "✦",
		"crit_chance": "◎",
		"crit_mult":   "★",
		"fire_rate":   "↯",
		"move_speed":  "⟩",
	}
	# Stat-specific accent colour for the crown bar and glyph.
	const STAT_COLOR := {
		"hp":          Color(0.70, 0.22, 0.18),
		"damage":      Color(0.78, 0.48, 0.22),
		"crit_chance": Color(0.76, 0.65, 0.18),
		"crit_mult":   Color(0.76, 0.65, 0.18),
		"fire_rate":   Color(0.32, 0.56, 0.74),
		"move_speed":  Color(0.44, 0.55, 0.25),
	}

	var _stat  := ""
	var _name  := ""
	var _desc  := ""
	var _hover := false
	var _hfont: Font = null

	func setup(buff: Dictionary) -> void:
		_stat = String(buff.get("stat", ""))
		_name = String(buff.get("name", ""))
		_desc = String(buff.get("desc", ""))
		custom_minimum_size = Vector2(180, 230)
		# Preload header font here, not inside _draw(), to avoid the
		# white-rect-in-_draw gotcha (godot-draw-load-white-texture).
		_hfont = WyrdUi.font_header()
		# Strip default Button chrome so only our _draw() face shows.
		for state in ["normal", "hover", "hover_pressed",
				"pressed", "focus", "disabled"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())
		mouse_entered.connect(func(): _hover = true;  queue_redraw())
		mouse_exited.connect( func(): _hover = false; queue_redraw())

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# ── parchment body ──
		draw_rect(r, WyrdUi.KIT_PLATE)
		# Inner highlight stripe (top).
		draw_rect(Rect2(r.position + Vector2(2.0, 2.0),
			Vector2(r.size.x - 4.0, 2.0)), Color(1.0, 0.99, 0.87, 0.55))
		# Inner shadow stripe (bottom).
		draw_rect(Rect2(Vector2(2.0, r.size.y - 4.0),
			Vector2(r.size.x - 4.0, 2.0)), Color(WyrdUi.KIT_EDGE, 0.28))
		# Outer border.
		draw_rect(r, Color(WyrdUi.KIT_EDGE, 0.60), false, 1.5)
		# Hover gold wash.
		if _hover:
			draw_rect(r.grow(-2.0), Color(WyrdUi.GOLD, 0.10))
		# Parchment fibre grain (seeded per stat so the three cards differ).
		WyrdUi.draw_parchment_grain(self,
			Rect2(Vector2(10.0, 16.0), Vector2(size.x - 20.0, size.y - 28.0)),
			abs(_stat.hash()) % 97 + 3)
		# ── stat crown bar ──
		var bar_c: Color = STAT_COLOR.get(_stat, WyrdUi.SAGE)
		draw_rect(Rect2(Vector2(2.0, 2.0), Vector2(size.x - 4.0, 10.0)), bar_c)
		# ── round icon socket ──
		var wc := Vector2(size.x * 0.5, 54.0)
		WyrdUi.draw_round_well(self, wc, 26.0, Color(0.87, 0.80, 0.65))
		# Stat glyph inside the socket.
		var gf: Font = _hfont if _hfont != null else get_theme_default_font()
		draw_string(gf, Vector2(0.0, 64.0),
			STAT_GLYPH.get(_stat, "✦"),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 22,
			Color(WyrdUi.GOLD, 0.90))
		# ── buff name (IM Fell, two lines max, TERRACOTTA) ──
		draw_multiline_string(gf, Vector2(8.0, 98.0), _name,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 16.0, 13, 2,
			WyrdUi.TERRACOTTA)
		# ── separator flourish ──
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 128.0), size.x * 0.62)
		# ── short description ──
		var bf := get_theme_default_font()
		draw_multiline_string(bf, Vector2(10.0, 144.0), _desc,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 20.0, 12, 4,
			WyrdUi.INK_MID)
