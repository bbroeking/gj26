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
	# Spec 46 art pass — a hand-drawn lantern crest + parchment grain + flourish
	# rule so the header reads as a crafted object, not a plain label field.
	var art := _LanternHeaderArt.new()
	art.anchor_right = 1.0
	art.offset_bottom = 84
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


# Header-band art: parchment grain, a drawn lantern crest in the left badge
# zone, and a flourish rule along the bottom edge.  Sits below the wooden
# frame ornament, left of "The Lantern" title.
class _LanternHeaderArt extends Control:
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		WyrdUi.draw_parchment_grain(self, r, 19)
		WyrdUi.draw_flourish(self, Vector2(r.size.x * 0.5, r.size.y - 5.0),
			r.size.x * 0.68)
		_draw_lantern(Vector2(28.0, r.size.y * 0.5 - 2.0), r.size.y * 0.62)

	func _draw_lantern(ctr: Vector2, h: float) -> void:
		var w := h * 0.54
		var ink := Color(WyrdUi.KIT_EDGE, 0.85)
		# Hanging loop.
		draw_arc(ctr + Vector2(0.0, -h * 0.46), h * 0.12, PI, TAU, 10, ink, 1.5)
		# Top cap.
		var cap_r := Rect2(ctr + Vector2(-w * 0.46, -h * 0.38),
			Vector2(w * 0.92, h * 0.12))
		draw_rect(cap_r, WyrdUi.KIT_PLATE)
		draw_rect(cap_r, ink, false, 1.5)
		# Glass cage body.
		var body_r := Rect2(ctr + Vector2(-w * 0.5, -h * 0.26),
			Vector2(w, h * 0.50))
		draw_rect(body_r, Color(0.90, 0.87, 0.74, 0.65))
		# Warm flame teardrop.
		var fc := ctr + Vector2(0.0, -h * 0.04)
		var fw := w * 0.36
		var fh := h * 0.28
		var flame := PackedVector2Array([
			fc + Vector2(0.0, -fh),
			fc + Vector2(fw * 0.7, -fh * 0.2),
			fc + Vector2(fw, fh * 0.5),
			fc + Vector2(0.0, fh * 0.7),
			fc + Vector2(-fw, fh * 0.5),
			fc + Vector2(-fw * 0.7, -fh * 0.2),
		])
		draw_colored_polygon(flame, Color(WyrdUi.GOLD, 0.78))
		# Horizontal cage bars.
		draw_line(Vector2(body_r.position.x + 2.0, fc.y - fh * 0.35),
			Vector2(body_r.end.x - 2.0, fc.y - fh * 0.35),
			Color(WyrdUi.KIT_EDGE, 0.30), 1.0)
		draw_line(Vector2(body_r.position.x + 2.0, fc.y + fh * 0.62),
			Vector2(body_r.end.x - 2.0, fc.y + fh * 0.62),
			Color(WyrdUi.KIT_EDGE, 0.30), 1.0)
		# Cage outline.
		draw_rect(body_r, ink, false, 1.5)
		# Bottom base plate.
		var base_y := body_r.end.y
		var base_r := Rect2(Vector2(ctr.x - w * 0.38, base_y),
			Vector2(w * 0.76, h * 0.10))
		draw_rect(base_r, WyrdUi.KIT_PLATE)
		draw_rect(base_r, ink, false, 1.5)
