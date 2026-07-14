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
	# Storybook header: lantern crest on the left + flourish rule at y=88.
	# Rendered first so title and buttons sit on top.
	var hdr := _LanternHeader.new()
	hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.anchor_right = 1.0
	hdr.offset_bottom = 92.0
	_panel.add_child(hdr)
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


# ---- storybook header decoration ----
# A hand-drawn lantern icon on the left + a ── ◆ ── flourish rule at the
# bottom of the header zone. Purely decorative — mouse_filter IGNORE so it
# can't steal clicks from the buttons beneath.
#
# Lantern form: iron-frame glass body (panes) with a warm amber flame,
# trapezoidal cap, flat base plate, and a side handle loop. A soft gold glow
# halo behind it evokes the "Light a fire" invite text above.
class _LanternHeader extends Control:
	func _draw() -> void:
		var cx := 28.0
		var cy := 44.0
		var h  := 58.0
		var w  := h * 0.58   # ≈ 33.6

		# Warm glow halo — ambient light spilling onto the parchment.
		draw_circle(Vector2(cx, cy + h * 0.06), h * 0.54, Color(WyrdUi.GOLD, 0.09))
		draw_circle(Vector2(cx, cy + h * 0.06), h * 0.32, Color(WyrdUi.GOLD, 0.06))

		# Hanging ring at top.
		var ring_c := Vector2(cx, cy - h * 0.44)
		draw_arc(ring_c, h * 0.09, PI * 1.12, PI * 1.88, 10,
			WyrdUi.KIT_EDGE, 1.5, false)
		draw_line(ring_c + Vector2(0, h * 0.09), ring_c + Vector2(0, h * 0.15),
			WyrdUi.KIT_EDGE, 1.5)

		# Trapezoidal iron cap (roof of the lamp chamber).
		var cap_base_y := cy - h * 0.26
		var cap_top_y  := cy - h * 0.40
		var cap := PackedVector2Array([
			Vector2(cx - w * 0.60, cap_base_y),
			Vector2(cx + w * 0.60, cap_base_y),
			Vector2(cx + w * 0.30, cap_top_y),
			Vector2(cx - w * 0.30, cap_top_y),
		])
		draw_colored_polygon(cap, Color(0.32, 0.24, 0.15))
		draw_polyline(PackedVector2Array([cap[0], cap[1], cap[2], cap[3], cap[0]]),
			WyrdUi.KIT_EDGE, 1.2)

		# Glass body — amber-tinted warm parchment panels.
		var body := Rect2(Vector2(cx - w * 0.5, cy - h * 0.26),
			Vector2(w, h * 0.48))
		draw_rect(body, Color(0.97, 0.90, 0.70, 0.80))
		# Iron pane dividers: two vertical + one horizontal mid bar.
		var bx := body.position.x
		var by := body.position.y
		var bw := body.size.x
		var bh := body.size.y
		draw_line(Vector2(bx + bw * 0.33, by), Vector2(bx + bw * 0.33, by + bh),
			Color(WyrdUi.KIT_EDGE, 0.55), 1.2)
		draw_line(Vector2(bx + bw * 0.67, by), Vector2(bx + bw * 0.67, by + bh),
			Color(WyrdUi.KIT_EDGE, 0.55), 1.2)
		draw_line(Vector2(bx, by + bh * 0.5), Vector2(bx + bw, by + bh * 0.5),
			Color(WyrdUi.KIT_EDGE, 0.45), 1.2)
		draw_rect(body, WyrdUi.KIT_EDGE, false, 1.5)

		# Flame — outer amber-orange shell, inner warm-yellow core.
		var fc := body.get_center() - Vector2(0, bh * 0.08)
		var fp := PackedVector2Array([
			fc + Vector2(0,        -h * 0.18),
			fc + Vector2(-w * 0.15, -h * 0.05),
			fc + Vector2(-w * 0.12,  h * 0.10),
			fc + Vector2(0,          h * 0.08),
			fc + Vector2( w * 0.12,  h * 0.10),
			fc + Vector2( w * 0.15, -h * 0.05),
		])
		draw_colored_polygon(fp, Color(0.94, 0.56, 0.12, 0.90))
		var ip := PackedVector2Array([
			fc + Vector2(0,        -h * 0.10),
			fc + Vector2(-w * 0.07, h * 0.01),
			fc + Vector2(-w * 0.05, h * 0.06),
			fc + Vector2(0,         h * 0.04),
			fc + Vector2( w * 0.05, h * 0.06),
			fc + Vector2( w * 0.07, h * 0.01),
		])
		draw_colored_polygon(ip, Color(0.99, 0.87, 0.52, 0.92))

		# Flat iron base plate.
		var base := Rect2(Vector2(cx - w * 0.60, cy - h * 0.26 + h * 0.48),
			Vector2(w * 1.20, h * 0.09))
		draw_rect(base, Color(0.32, 0.24, 0.15))
		draw_rect(base, WyrdUi.KIT_EDGE, false, 1.2)

		# Side handle loop — an open arc on the right.
		draw_arc(Vector2(cx + w * 0.60 + h * 0.12, cy), h * 0.14,
			-PI * 0.52, PI * 0.52, 10, WyrdUi.KIT_EDGE, 1.3, false)

		# Flourish rule — ── ◆ ── centred at the bottom of the header zone.
		WyrdUi.draw_flourish(self, Vector2(size.x * 0.5, 86.0), size.x - 120.0)
