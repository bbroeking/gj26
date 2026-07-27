extends CanvasLayer

# Spec 46 Phase A — the Lantern: Esc opens it when nothing else is. Host a
# fire, join a friend's by IP, see who's in the yard, leave. Offline it
# pauses like every modal; in a session the world keeps breathing.

var _game: Node
var _panel: Panel
var _status: Label
var _ip_edit: LineEdit
var _roster: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 96
	_game = get_tree().root.get_node_or_null("Game")
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_panel = Panel.new()
	WyrdUi.style_panel(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -260
	_panel.offset_top = -220
	_panel.offset_right = 260
	_panel.offset_bottom = 220
	add_child(_panel)
	var title := Label.new()
	title.text = "The Lantern"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 36)
	_panel.add_child(title)
	var hint := Label.new()
	hint.text = "Esc — close"
	WyrdUi.style_dim(hint)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.offset_left = -130
	hint.offset_top = 38
	_panel.add_child(hint)
	# Header crest — a drawn lantern icon centred on an ivy-leaf rule,
	# giving the Lantern panel the same ornament-on-headers treatment as
	# the other modals. Positioned in the gap between the title row and
	# the first content element.
	var crest := _LanternHeaderCrest.new()
	crest.anchor_right = 1.0
	crest.offset_top = 66
	crest.custom_minimum_size = Vector2(0, 30)
	_panel.add_child(crest)
	var col := VBoxContainer.new()
	col.anchor_right = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = 56
	col.offset_top = 104
	col.offset_right = -56
	col.offset_bottom = -48
	col.add_theme_constant_override("separation", 10)
	_panel.add_child(col)

	_status = Label.new()
	WyrdUi.style_body(_status, 14)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)

	_roster = Label.new()
	WyrdUi.style_body(_roster, 14)
	col.add_child(_roster)

	if NetGame.active:
		if NetGame.is_host():
			_build_address_invite(col)
		var leave := Button.new()
		WyrdUi.style_kit_button(leave)
		leave.text = "Leave the party"
		leave.custom_minimum_size = Vector2(0, 40)
		leave.pressed.connect(func():
			NetGame.leave()
			_close())
		col.add_child(leave)
	else:
		var host := Button.new()
		WyrdUi.style_kit_button(host)
		host.text = "Light a fire — host (port %d)" % NetGame.DEFAULT_PORT
		host.custom_minimum_size = Vector2(0, 40)
		host.pressed.connect(_on_host)
		col.add_child(host)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_ip_edit = LineEdit.new()
		_ip_edit.placeholder_text = "friend's address (IP or IP:port)"
		_ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_ip_edit.custom_minimum_size = Vector2(0, 40)
		row.add_child(_ip_edit)
		var join := Button.new()
		WyrdUi.style_kit_button(join)
		join.text = "Join"
		join.custom_minimum_size = Vector2(96, 40)
		join.pressed.connect(_on_join)
		row.add_child(join)
		col.add_child(row)
		var note := Label.new()
		note.text = "Paste your friend's address (they copy it from their Lantern). Same network or a VPN — Tailscale works well. Friends join while you keep playing."
		WyrdUi.style_dim(note, 12)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(note)

	NetGame.roster_changed.connect(_refresh)
	NetGame.reconnecting.connect(func(attempt: int, total: int):
		_status.text = "Lost the host — trying the door again (%d/%d)…" \
			% [attempt, total])
	if _game != null:
		_game.modal_opened()
	_refresh()

# Host invite: show the shareable address(es) and a one-click copy. The host
# opens the Lantern (Esc), copies, and sends it to a friend.
func _build_address_invite(col: VBoxContainer) -> void:
	var addrs: Array = NetGame.local_addresses()
	var addr_lbl := Label.new()
	WyrdUi.style_body(addr_lbl, 14)
	addr_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if addrs.is_empty():
		addr_lbl.text = "Share your address with a friend (port %d)." \
			% NetGame.DEFAULT_PORT
		col.add_child(addr_lbl)
		return
	var primary := "%s:%d" % [String(addrs[0]), NetGame.DEFAULT_PORT]
	addr_lbl.text = "Your address:  %s" % primary
	col.add_child(addr_lbl)
	var copy := Button.new()
	WyrdUi.style_kit_button(copy)
	copy.text = "Copy address"
	copy.custom_minimum_size = Vector2(0, 40)
	copy.pressed.connect(func():
		DisplayServer.clipboard_set(primary)
		_status.text = "Copied %s — send it to a friend." % primary)
	col.add_child(copy)
	if addrs.size() > 1:
		var more := Label.new()
		WyrdUi.style_dim(more, 12)
		more.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		more.text = "Other addresses: %s" % ", ".join(addrs.slice(1))
		col.add_child(more)

func _refresh() -> void:
	if NetGame.active:
		_status.text = ("You keep the fire (host). Friends join at your address, port %d."
			% NetGame.DEFAULT_PORT) if NetGame.is_host() \
			else "You're a guest at a friend's fire."
		var names: Array = []
		for id in NetGame.players:
			names.append(NetGame.peer_name(int(id)))
		_roster.text = "In the yard:  %s" % " · ".join(names)
	else:
		_status.text = "Playing alone. Light a fire and friends can step in."
		_roster.text = ""

func _on_host() -> void:
	if NetGame.host():
		if _game != null:
			_game.notify("The fire is lit — reopen the Lantern (Esc) to copy your address for a friend.")
		NetGame.setup_scene(get_tree().current_scene)
		_close()
	else:
		_status.text = "Couldn't open port %d — is another fire burning?" \
			% NetGame.DEFAULT_PORT

func _on_join() -> void:
	var raw := _ip_edit.text.strip_edges()
	if raw == "":
		_status.text = "Type your friend's address first."
		return
	var ip := raw
	var port := NetGame.DEFAULT_PORT
	if ":" in raw:
		var parts := raw.split(":")
		ip = parts[0]
		port = int(parts[1])
	if NetGame.join(ip, port):
		_status.text = "Knocking on %s…" % raw
		# The roster lands when the host answers; the scene re-populates then.
		NetGame.roster_changed.connect(func():
			NetGame.setup_scene(get_tree().current_scene), CONNECT_ONE_SHOT)
		_close()
	else:
		_status.text = "That address doesn't look right."

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	if _game != null:
		_game.modal_closed()
	queue_free()


# _LanternHeaderCrest — a drawn lantern icon centred on an ivy-leaf ink rule.
# Drawn entirely in code (no textures — white-rect gotcha impossible).
# The lantern motif echoes the panel's name and the fireside-gathering theme.
class _LanternHeaderCrest extends Control:
	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		var rule_col := Color(WyrdUi.KIT_EDGE, 0.38)

		# Horizontal ink rule spanning the panel width (gap for the lantern).
		draw_line(Vector2(14, cy), Vector2(cx - 20, cy), rule_col, 1.0)
		draw_line(Vector2(cx + 20, cy), Vector2(size.x - 14, cy), rule_col, 1.0)

		# Ivy-leaf clusters (two leaves each side, flanking the lantern).
		for side in [-1.0, 1.0]:
			var ox: float = side * 48.0
			var sage := Color(WyrdUi.SAGE.darkened(0.10), 0.78)
			# inner leaf — small diamond pointing outward
			var lp1 := Vector2(cx + ox, cy)
			var l1 := PackedVector2Array([
				lp1 + Vector2(0, -5), lp1 + Vector2(side * 8, 0),
				lp1 + Vector2(0, 5),  lp1 + Vector2(-side * 2, 0)
			])
			draw_colored_polygon(l1, sage)
			# outer leaf — slightly larger, offset up and out
			var lp2 := lp1 + Vector2(side * 14, -3)
			var l2 := PackedVector2Array([
				lp2 + Vector2(0, -4), lp2 + Vector2(side * 7, 2),
				lp2 + Vector2(0, 6),  lp2 + Vector2(-side * 3, 1)
			])
			draw_colored_polygon(l2, sage.darkened(0.10))
			# thin vine stem connecting the two leaves
			draw_line(lp1 + Vector2(-side * 2, 0), lp2 + Vector2(side * 7, 2),
				Color(WyrdUi.KIT_EDGE, 0.25), 1.0)

		# Centre lantern icon — hook, amber-glass body, warm flame, base plate.
		_draw_lantern(Vector2(cx, cy))

	func _draw_lantern(c: Vector2) -> void:
		var h := 22.0
		var w := h * 0.60

		# Hanging hook (a short vertical shaft above the body).
		draw_rect(Rect2(c.x - 1.0, c.y - h * 0.90, 2.0, h * 0.30), WyrdUi.KIT_EDGE)

		# Amber glass body.
		var body := Rect2(c.x - w, c.y - h * 0.50, w * 2.0, h * 0.80)
		draw_rect(body, Color(0.97, 0.85, 0.45, 0.72))

		# Glass highlight strip (catches the warm page light).
		draw_rect(Rect2(body.position + Vector2(2.0, 2.5),
			Vector2(3.5, body.size.y - 6.0)),
			Color(1.0, 1.0, 0.88, 0.32))

		# Warm flame (five-point teardrop, orange core).
		var fp := PackedVector2Array([
			c + Vector2(0, -h * 0.38),
			c + Vector2(w * 0.45, -h * 0.05),
			c + Vector2(w * 0.22, h * 0.22),
			c + Vector2(-w * 0.22, h * 0.22),
			c + Vector2(-w * 0.45, -h * 0.05),
		])
		draw_colored_polygon(fp, Color(0.94, 0.56, 0.14, 0.90))
		# Brighter inner core.
		var fc := PackedVector2Array([
			c + Vector2(0, -h * 0.22),
			c + Vector2(w * 0.22, h * 0.06),
			c + Vector2(-w * 0.22, h * 0.06),
		])
		draw_colored_polygon(fc, Color(1.0, 0.90, 0.52, 0.72))

		# Ink frame over the glass.
		draw_rect(body, WyrdUi.KIT_EDGE, false, 1.5)
		# Centre cross-bar (glass panel divider, faint).
		draw_line(Vector2(c.x, body.position.y), Vector2(c.x, body.end.y),
			Color(WyrdUi.KIT_EDGE, 0.28), 1.0)

		# Base plate (a short thick bar below the body, gold accent).
		var base_y := body.end.y - 1.0
		draw_rect(Rect2(c.x - w - 3.0, base_y, (w + 3.0) * 2.0, 4.0), WyrdUi.KIT_EDGE)
		draw_rect(Rect2(c.x - w - 3.0, base_y, (w + 3.0) * 2.0, 4.0),
			Color(WyrdUi.GOLD, 0.40), false, 1.0)

		# Gold corner dots at the four body corners.
		var gold := Color(WyrdUi.GOLD, 0.72)
		draw_circle(body.position + Vector2(1.5, 1.5), 1.8, gold)
		draw_circle(Vector2(body.end.x - 1.5, body.position.y + 1.5), 1.8, gold)
		draw_circle(Vector2(body.position.x + 1.5, body.end.y - 1.5), 1.8, gold)
		draw_circle(body.end - Vector2(1.5, 1.5), 1.8, gold)
