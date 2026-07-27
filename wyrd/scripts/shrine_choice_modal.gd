extends CanvasLayer

# Spec 29 — the 3-buff choice modal a Shrine opens. The whole UI is built in
# script so the .tscn stays a minimal CanvasLayer + script binding. Pauses
# the tree while open so the player can't escape with a movement key; emits
# `chosen(buff)` when the player picks one of the three cards.
#
# Art pass — plain Button cards replaced with _BoonCard inner class: a
# kit parchment face, a hand-drawn stat glyph for each buff type, and the
# boon name + description typeset on cream. Glyphs are stat-coded so the
# player reads the card at a glance before reading the text.

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
	# Panel — kit wooden frame so the modal reads as a carved altar tablet.
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.custom_minimum_size = Vector2(680, 340)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -340
	_panel.offset_top = -170
	_panel.offset_right = 340
	_panel.offset_bottom = 170
	add_child(_panel)
	# Title — IM Fell Small Caps in terracotta, like every other panel header.
	var title := Label.new()
	title.text = "An Old Altar Stirs"
	WyrdUi.style_title(title)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 16
	title.offset_bottom = 56
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)
	# HBox for the 3 boon cards.
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 18)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.anchor_left = 0.0
	_hbox.anchor_right = 1.0
	_hbox.anchor_bottom = 1.0
	_hbox.offset_top = 72
	_hbox.offset_bottom = -20
	_hbox.offset_left = 20
	_hbox.offset_right = -20
	_panel.add_child(_hbox)

# Populate the modal with the 3 offered buffs and pause the world.
func setup(buffs: Array) -> void:
	_buffs = buffs
	for c in _hbox.get_children():
		c.queue_free()
	for b in _buffs:
		var card := _BoonCard.new()
		card.setup(b)
		card.pressed.connect(_on_pressed.bind(b))
		_hbox.add_child(card)
	get_node("/root/Game").modal_opened()

func _on_pressed(buff: Dictionary) -> void:
	get_node("/root/Game").modal_closed()
	chosen.emit(buff)
	queue_free()


# ---- hand-drawn boon card ----
# A 180×200 clickable parchment card: kit list-row plate + a stat glyph at
# the top (heart/arrow/diamond/leaf, coded per buff.stat) + name in IM Fell
# + description in body ink. Hover brightens; click emits pressed.
class _BoonCard extends Control:
	var _buff: Dictionary = {}
	var _hover := false

	signal pressed

	func _init() -> void:
		custom_minimum_size = Vector2(180, 200)
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP

	func setup(buff: Dictionary) -> void:
		_buff = buff
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hover = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hover = false
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Parchment card face — same kit language as vendor/loadout rows.
		WyrdUi.draw_list_row(self, r, WyrdUi.SAGE)
		WyrdUi.draw_parchment_grain(self, r.grow(-4.0), _buff.get("id", "x").hash())
		if _hover:
			draw_rect(r.grow(-2.0), Color(1.0, 1.0, 0.90, 0.12))
		# Glyph area at the top — a recessed well centred in a cream disc.
		var gc := Vector2(size.x * 0.5, 52.0)
		var gr := 28.0
		draw_circle(gc, gr + 3.0, Color(WyrdUi.KIT_WELL, 0.9))
		draw_arc(gc, gr + 3.0, 0, TAU, 40, WyrdUi.KIT_EDGE, 1.5, true)
		_draw_stat_glyph(gc, gr, String(_buff.get("stat", "")))
		# Name — IM Fell header font, terracotta.
		var hf := WyrdUi.font_header()
		var name_str := String(_buff.get("name", "Blessing"))
		var font := hf if hf != null else get_theme_default_font()
		var y := gc.y + gr + 14.0
		draw_string(font, Vector2(8.0, y), name_str,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 16.0, 14, WyrdUi.TERRACOTTA)
		y += 18.0
		# Thin flourish under the name.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, y), size.x * 0.55)
		y += 14.0
		# Description — body font, ink.
		var bf := WyrdUi.font_body()
		var dfont := bf if bf != null else get_theme_default_font()
		var desc_str := String(_buff.get("desc", ""))
		draw_string(dfont, Vector2(10.0, y), desc_str,
			HORIZONTAL_ALIGNMENT_CENTER, size.x - 20.0, 13, WyrdUi.INK)

	# Stat-coded glyph drawn in the disc well. Each stat gets a distinct
	# vector shape so the boon reads before the player reads the name.
	#   hp        → red heart (two lobes + point)
	#   damage    → terracotta arrow-head (upward triangle + shaft)
	#   crit_chance / crit_mult → gold diamond ◆
	#   fire_rate → sage double-chevron (speed streaks)
	#   move_speed → sage leaf (elongated oval + vein line)
	func _draw_stat_glyph(c: Vector2, r: float, stat: String) -> void:
		match stat:
			"hp":
				# Heart: two lobes (arcs) meeting at a point below.
				var col := Color(0.78, 0.20, 0.18)
				var lobe_r := r * 0.38
				draw_circle(c + Vector2(-lobe_r * 0.7, -lobe_r * 0.2), lobe_r, col)
				draw_circle(c + Vector2( lobe_r * 0.7, -lobe_r * 0.2), lobe_r, col)
				var pts := PackedVector2Array([
					c + Vector2(-r * 0.72, -lobe_r * 0.05),
					c + Vector2( r * 0.72, -lobe_r * 0.05),
					c + Vector2(0.0, r * 0.70),
				])
				draw_colored_polygon(pts, col)
				# Specular catch-light on the left lobe.
				draw_circle(c + Vector2(-lobe_r * 0.9, -lobe_r * 0.55),
					lobe_r * 0.28, Color(1.0, 0.85, 0.85, 0.55))
			"damage":
				# Arrow-head pointing up: filled triangle + a thin shaft.
				var col2 := WyrdUi.TERRACOTTA
				var tip := c + Vector2(0.0, -r * 0.72)
				var bl  := c + Vector2(-r * 0.44, r * 0.12)
				var br  := c + Vector2( r * 0.44, r * 0.12)
				var pts2 := PackedVector2Array([tip, bl, br])
				draw_colored_polygon(pts2, col2)
				draw_line(c + Vector2(0.0, r * 0.12), c + Vector2(0.0, r * 0.66),
					col2, 4.0)
				# Nock notch at the base.
				draw_line(c + Vector2(-r * 0.2, r * 0.66),
					c + Vector2( r * 0.2, r * 0.66), col2, 3.0)
			"crit_chance", "crit_mult":
				# Gold diamond ◆ — same shape as draw_flourish's pip, scaled up.
				var col3 := WyrdUi.GOLD
				var hw := r * 0.60
				var pts3 := PackedVector2Array([
					c + Vector2(0, -hw * 1.1),
					c + Vector2(hw, 0),
					c + Vector2(0, hw * 1.1),
					c + Vector2(-hw, 0),
				])
				draw_colored_polygon(pts3, col3)
				# Inner highlight facet.
				var hw2 := hw * 0.45
				var pts4 := PackedVector2Array([
					c + Vector2(0, -hw2 * 1.6),
					c + Vector2(hw2, -hw2 * 0.1),
					c + Vector2(0, hw2 * 0.8),
					c + Vector2(-hw2, -hw2 * 0.1),
				])
				draw_colored_polygon(pts4, Color(1.0, 0.95, 0.65, 0.45))
				draw_arc(c, hw * 0.96, 0, TAU, 32,
					Color(WyrdUi.KIT_EDGE, 0.60), 1.5, true)
			"fire_rate":
				# Two sage chevrons pointing right (speed streaks).
				var col5 := WyrdUi.SAGE
				for offset in [-r * 0.22, r * 0.18]:
					var ox := offset
					var pts5 := PackedVector2Array([
						c + Vector2(ox - r * 0.28, -r * 0.50),
						c + Vector2(ox + r * 0.28, 0.0),
						c + Vector2(ox - r * 0.28,  r * 0.50),
						c + Vector2(ox + r * 0.10,  r * 0.50),
						c + Vector2(ox + r * 0.55,  0.0),
						c + Vector2(ox + r * 0.10, -r * 0.50),
					])
					draw_colored_polygon(pts5, Color(col5, 0.80))
			"move_speed":
				# Sage leaf: elongated ellipse + midrib line.
				var col6 := WyrdUi.SAGE
				var tip_t := c + Vector2(0.0, -r * 0.74)
				var tip_b := c + Vector2(0.0,  r * 0.74)
				var ctrl  := Vector2(r * 0.52, 0.0)
				var steps := 28
				var pts6 := PackedVector2Array()
				for i in steps + 1:
					var t_val := float(i) / float(steps)
					var lp: Vector2 = tip_t.lerp(tip_b, t_val) + ctrl * sin(t_val * PI)
					pts6.append(lp)
				var pts7 := PackedVector2Array()
				for i in steps + 1:
					var t_val := float(i) / float(steps)
					var lp: Vector2 = tip_b.lerp(tip_t, t_val) - ctrl * sin(t_val * PI)
					pts7.append(lp)
				pts6.append_array(pts7)
				draw_colored_polygon(pts6, Color(col6, 0.82))
				# Midrib vein.
				draw_line(tip_t, tip_b, Color(WyrdUi.KIT_EDGE, 0.35), 1.5)
			_:
				# Fallback: a plain sage disc for unknown stats.
				draw_circle(c, r * 0.55, Color(WyrdUi.SAGE, 0.70))
