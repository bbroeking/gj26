extends CanvasLayer

# Spec 46 Phase A — the Lantern: Esc opens it when nothing else is. Host a
# fire, join a friend's by IP, see who's in the yard, leave. Offline it
# pauses like every modal; in a session the world keeps breathing.

var _game: Node
var _panel: Panel
var _status: Label
var _ip_edit: LineEdit
var _roster: Label

# Drawn header art: a warm amber wash + parchment grain + a hanging lantern
# glyph (glass body, candle flame, chain) in the space between the title and
# the Esc hint. Draws behind all children via PRESET_FULL_RECT + draw order.
class _LanternHeaderArt extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var zone := Rect2(Vector2.ZERO, Vector2(size.x, 88.0))
		# Warm amber wash — the lantern's candlelight bleeding into the parchment.
		draw_rect(zone, Color(0.98, 0.80, 0.44, 0.20))
		WyrdUi.draw_parchment_grain(self, zone, 53)
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 88.0), size.x * 0.80)
		_draw_lantern(Vector2(size.x * 0.60, 44.0))

	func _draw_lantern(ctr: Vector2) -> void:
		# Outer halo — candle glow warming the parchment around the lantern.
		draw_circle(ctr, 32.0, Color(0.99, 0.84, 0.44, 0.09))
		draw_circle(ctr, 20.0, Color(0.99, 0.84, 0.44, 0.07))
		# Hanging chain + hook bar.
		draw_line(ctr + Vector2(0.0, -36.0), ctr + Vector2(0.0, -26.0),
			WyrdUi.KIT_EDGE, 1.5)
		draw_line(ctr + Vector2(-5.0, -36.0), ctr + Vector2(5.0, -36.0),
			WyrdUi.KIT_EDGE, 1.5)
		# Top wooden cap.
		var cap_t := Rect2(ctr + Vector2(-10.0, -26.0), Vector2(20.0, 7.0))
		draw_rect(cap_t, Color(0.56, 0.42, 0.24))
		draw_rect(cap_t, WyrdUi.KIT_EDGE, false, 1.0)
		# Glass body — amber translucent face.
		var body := Rect2(ctr + Vector2(-13.0, -19.0), Vector2(26.0, 38.0))
		draw_rect(body, Color(0.96, 0.82, 0.50, 0.66))
		# Vertical frame bars: two outer edges + two inner pane dividers.
		for ox in [-13.0, -4.0, 4.0, 13.0]:
			var full_edge := absf(ox) == 13.0
			draw_line(Vector2(ctr.x + ox, body.position.y),
				Vector2(ctr.x + ox, body.position.y + 38.0),
				Color(WyrdUi.KIT_EDGE, 0.90 if full_edge else 0.38),
				1.5 if full_edge else 1.0)
		# Horizontal mid-rail.
		draw_line(body.position + Vector2(0.0, 15.0),
			body.position + Vector2(26.0, 15.0),
			Color(WyrdUi.KIT_EDGE, 0.50), 1.0)
		# Flame — wide amber base tapering to a cream tip.
		draw_circle(ctr + Vector2(0.0, 10.0), 5.5, Color(0.96, 0.52, 0.18))
		draw_circle(ctr + Vector2(0.0,  6.0), 3.5, Color(0.98, 0.76, 0.36))
		draw_circle(ctr + Vector2(0.0,  3.0), 2.0, Color(0.99, 0.96, 0.80))
		# Body border (drawn last so it sits cleanly over the fill and bars).
		draw_rect(body, WyrdUi.KIT_EDGE, false, 1.5)
		# Bottom wooden cap.
		var cap_b := Rect2(ctr + Vector2(-10.0, 19.0), Vector2(20.0, 7.0))
		draw_rect(cap_b, Color(0.56, 0.42, 0.24))
		draw_rect(cap_b, WyrdUi.KIT_EDGE, false, 1.0)

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
	# Header art first — draws behind the title, hint, and content children.
	var art := _LanternHeaderArt.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(art)
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
	var col := VBoxContainer.new()
	col.anchor_right = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = 56
	col.offset_top = 92
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
