extends CanvasLayer

# Spec 46 Phase A — the Lantern: Esc opens it when nothing else is. Host a
# fire, join a friend's by IP, see who's in the yard, leave. Offline it
# pauses like every modal; in a session the world keeps breathing.
#
# Art pass: a hand-drawn lantern crest (_LanternCrest) sits in the header
# margin, warming up the plain title area the way PortraitWell does in
# dialog_panel. A flavor sub-quote and a ◆ flourish rule complete the header.

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
	# Lantern crest — a small hand-drawn lantern emblem in the header margin
	# (like PortraitWell in dialog_panel). Pure vector; no load() in _draw.
	var crest := _LanternCrest.new()
	crest.position = Vector2(10, 16)
	crest.size = Vector2(36, 46)
	_panel.add_child(crest)
	var title := Label.new()
	title.text = "The Lantern"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 36)
	_panel.add_child(title)
	var sub := Label.new()
	sub.text = "Light it and friends step in — or wander the hollows alone."
	WyrdUi.style_dim(sub, 12)
	sub.position = Vector2(54, 68)
	sub.anchor_right = 1.0
	sub.offset_right = -56
	_panel.add_child(sub)
	var rule := _HeaderRule.new()
	rule.position = Vector2(0, 88)
	rule.size = Vector2(520, 14)
	_panel.add_child(rule)
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
	col.offset_top = 110  # pushed down from 92 to clear crest + sub + rule
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


# Hand-drawn lantern crest for the panel header.
# Amber glass body with iron frame, pane dividers, warm flame, and a top
# handle — a pure-vector storybook vignette. No load() inside _draw (safe
# from the godot-draw-load-white-texture gotcha).
class _LanternCrest extends Control:
	func _draw() -> void:
		var cx := size.x * 0.5
		var h := size.y
		var w := size.x
		# Iron handle — a small arc at the top of the lantern body.
		draw_arc(Vector2(cx, h * 0.16), w * 0.17, -PI, 0.0, 12,
			WyrdUi.KIT_EDGE, 2.2, false)
		# Glass body — warm amber, slightly translucent.
		var body := Rect2(cx - w * 0.34, h * 0.22, w * 0.68, h * 0.52)
		draw_rect(body, Color(0.94, 0.79, 0.48, 0.82))
		# Glass pane dividers — a cross of faint ink lines.
		var gc := Color(WyrdUi.KIT_EDGE, 0.28)
		draw_line(Vector2(cx, body.position.y + 1.5),
			Vector2(cx, body.end.y - 1.5), gc, 1.2)
		var mid_y := body.position.y + body.size.y * 0.46
		draw_line(Vector2(body.position.x + 2.0, mid_y),
			Vector2(body.end.x - 2.0, mid_y), gc, 1.2)
		# Warm glow halo around the flame.
		var fc := Vector2(cx, body.position.y + body.size.y * 0.36)
		draw_circle(fc, w * 0.28, Color(WyrdUi.GOLD, 0.13))
		# Flame — amber core, bright hot tip.
		draw_circle(fc, w * 0.17, Color(1.0, 0.60, 0.18, 0.88))
		draw_circle(fc - Vector2(0.0, w * 0.07), w * 0.09,
			Color(1.0, 0.96, 0.68, 0.92))
		# Body ink border.
		draw_rect(body, WyrdUi.KIT_EDGE, false, 2.0)
		# Iron cap above the body.
		var cap := Rect2(cx - w * 0.32, body.position.y - h * 0.08,
			w * 0.64, h * 0.09)
		draw_rect(cap, Color(0.30, 0.22, 0.14))
		draw_rect(cap, WyrdUi.KIT_EDGE, false, 1.5)
		# Iron base below the body.
		var base_r := Rect2(cx - w * 0.28, body.end.y,
			w * 0.56, h * 0.08)
		draw_rect(base_r, Color(0.30, 0.22, 0.14))
		draw_rect(base_r, WyrdUi.KIT_EDGE, false, 1.5)


# Thin ◆ flourish rule drawn between the header text and the panel content.
class _HeaderRule extends Control:
	func _draw() -> void:
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, size.y * 0.5),
			size.x * 0.82)
