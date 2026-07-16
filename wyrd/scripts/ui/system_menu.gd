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
	_panel.offset_top = -254
	_panel.offset_right = 260
	_panel.offset_bottom = 254
	add_child(_panel)
	# Drawn lantern crest + flourish separator above the title.
	var crest := LanternCrest.new()
	crest.anchor_right = 1.0
	crest.offset_top = 36.0
	crest.offset_bottom = 100.0
	_panel.add_child(crest)
	var title := Label.new()
	title.text = "The Lantern"
	WyrdUi.style_title(title)
	title.position = Vector2(54, 108)
	_panel.add_child(title)
	var hint := Label.new()
	hint.text = "Esc — close"
	WyrdUi.style_dim(hint)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.offset_left = -130
	hint.offset_top = 110
	_panel.add_child(hint)
	var col := VBoxContainer.new()
	col.anchor_right = 1.0
	col.anchor_bottom = 1.0
	col.offset_left = 56
	col.offset_top = 164
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


# Hand-drawn lantern icon centred above "The Lantern" title. A warm amber
# glass body (pane grid), a flame inside, a metal top cap with a hanging
# handle loop, a bottom cap, and a ◆ flourish separator at the foot.
class LanternCrest extends Control:
	func _draw() -> void:
		var cx := size.x * 0.5
		# Warm amber glow behind the lantern (rendered first, sits under all else).
		draw_circle(Vector2(cx, 32.0), 28.0, Color(WyrdUi.GOLD, 0.08))
		draw_circle(Vector2(cx, 32.0), 19.0, Color(WyrdUi.GOLD, 0.13))
		# Hanging handle — ∩ arch above the top cap.
		# draw_arc from PI→TAU is clockwise in Godot (y-down), tracing the upper
		# half of the circle, so the arc peaks upward = a true suspension loop.
		draw_arc(Vector2(cx, 14.0), 9.0, PI, TAU, 20, WyrdUi.KIT_EDGE, 2.2, true)
		# Top metal cap.
		var top_cap := Rect2(cx - 12.0, 14.0, 24.0, 8.0)
		draw_rect(top_cap, WyrdUi.KIT_PLATE)
		draw_rect(Rect2(top_cap.position + Vector2(2.0, 1.5), Vector2(20.0, 2.0)),
			Color(1.0, 1.0, 0.92, 0.50))  # honey bevel
		draw_rect(top_cap, WyrdUi.KIT_EDGE, false, 1.5)
		# Glass body — warm amber with a three-pane grid.
		var body := Rect2(cx - 14.0, 21.0, 28.0, 28.0)
		draw_rect(body, Color(0.91, 0.78, 0.42, 0.72))
		draw_line(Vector2(cx - 5.0, 23.0), Vector2(cx - 5.0, 47.0),
			Color(WyrdUi.KIT_EDGE, 0.28), 1.0)
		draw_line(Vector2(cx + 5.0, 23.0), Vector2(cx + 5.0, 47.0),
			Color(WyrdUi.KIT_EDGE, 0.28), 1.0)
		draw_line(Vector2(cx - 14.0, 35.0), Vector2(cx + 14.0, 35.0),
			Color(WyrdUi.KIT_EDGE, 0.28), 1.0)
		# Flame — a teardrop polygon with a bright inner core.
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx, 23.0), Vector2(cx + 5.5, 30.0),
			Vector2(cx + 3.5, 38.0), Vector2(cx, 40.0),
			Vector2(cx - 3.5, 38.0), Vector2(cx - 5.5, 30.0),
		]), Color(0.98, 0.72, 0.16, 0.88))
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx, 26.0), Vector2(cx + 3.0, 32.0),
			Vector2(cx, 37.0), Vector2(cx - 3.0, 32.0),
		]), Color(1.0, 0.94, 0.62, 0.82))
		# Body ink outline (after flame so flame reads through the glass).
		draw_rect(body, WyrdUi.KIT_EDGE, false, 1.5)
		# Bottom metal cap.
		var bot_cap := Rect2(cx - 12.0, 48.0, 24.0, 7.0)
		draw_rect(bot_cap, WyrdUi.KIT_PLATE)
		draw_rect(bot_cap, WyrdUi.KIT_EDGE, false, 1.5)
		# ◆ flourish separator — the crest's foot, centred in the panel width.
		WyrdUi.draw_flourish(self, Vector2(cx, size.y - 5.0), size.x * 0.38)
