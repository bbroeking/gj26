extends CanvasLayer

# Spec 42 — the Crafting Bench: Minecraft-style placement crafting for
# charts. Drag a chart base + inks + trophy from the satchel tray into
# bench sockets; the result slot previews the chart and its odds live;
# clicking Craft (or the result) spends materials and inscribes. The ink
# mixing pot lives on the bench too (drag herbs/ore/ink into the pot).
#
# The LOGIC LAYER IS UNCHANGED from the old inscribing panel — same
# ChartsData/Game calls in the same order (spec 42 contract). Public
# methods (place_base / socket_ink / socket_trophy / pot_add / craft)
# exist so tests drive the flow without pixel drags.

const ChartsData = preload("res://data/charts.gd")
const GatherDefs = preload("res://data/gather.gd")

var _game: Node
var _panel: Panel
var _view: Control

# ---- bench state ----
var base_id := ""                 # placed template ("" = empty socket)
var inks: Array = []              # socketed ink ids, ordered
var trophy := ""                  # socketed trophy material id
var pot: Dictionary = {}          # mixing pot claims: material id -> count

var _held: Dictionary = {}        # {"kind": base|ink|mat|trophy, "id": ...}
var _cursor := Vector2.ZERO
var _pulse := 0.0                 # tutorial highlight phase

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	_game = get_tree().root.get_node_or_null("Game")
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
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
	_panel.offset_left = -470
	_panel.offset_top = -330
	_panel.offset_right = 470
	_panel.offset_bottom = 330
	add_child(_panel)
	_view = BenchView.new()
	_view.bench = self
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(_view)
	get_node("/root/Game").modal_opened()

func _process(delta: float) -> void:
	# The tutorial highlight pulses; only redraw while one is active.
	if _tutorial_target() != "":
		_pulse += delta * 4.0
		_view.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()

func close() -> void:
	get_node("/root/Game").modal_closed()
	queue_free()

# ---- the public crafting API (UI handlers + tests both use these) ----

func place_base(template_id: String) -> bool:
	var t: Dictionary = ChartsData.TEMPLATES.get(template_id, {})
	if t.is_empty() or _carto_lv() < int(t.req_carto):
		return false
	base_id = template_id
	inks.clear()
	trophy = ""
	_view.pop("base")
	_view.queue_redraw()
	return true

func clear_base() -> void:
	base_id = ""
	inks.clear()
	trophy = ""
	_view.queue_redraw()

func socket_ink(ink_id: String, slot: int = -1) -> bool:
	if base_id == "" or not ChartsData.INKS.has(ink_id):
		return false
	if inks.size() >= ink_slots():
		return false
	if _remaining(ink_id) <= 0:
		return false
	if slot < 0 or slot >= inks.size():
		inks.append(ink_id)
	else:
		inks.insert(slot, ink_id)
	_view.pop("ink%d" % (inks.size() - 1))
	_view.queue_redraw()
	return true

func remove_ink(slot: int) -> void:
	if slot >= 0 and slot < inks.size():
		inks.remove_at(slot)
		_view.queue_redraw()

func socket_trophy(trophy_id: String) -> bool:
	if base_id == "" or affix_slots() <= 0:
		return false
	if not ChartsData.TROPHY_TO_AFFIX.has(trophy_id):
		return false
	# Spec 45-carto — the den's req_carto is a real gate now (it was dead
	# data: possession was the only check).
	var den: Dictionary = ChartsData.AFFIXES.get(
		String(ChartsData.TROPHY_TO_AFFIX[trophy_id]), {})
	if _carto_lv() < int(den.get("req_carto", 1)):
		if _game != null:
			_game.notify("This den asks for Wayfinder %d." %
				int(den.get("req_carto", 1)))
		return false
	if _remaining(trophy_id) <= 0:
		return false
	trophy = trophy_id
	_view.pop("trophy")
	_view.queue_redraw()
	return true

# Drop a material into the mixing pot. Spec 43: only DISCOVERED recipes
# stir themselves on a match — unknown combinations wait for the
# deliberate Try (pot_try), which is where discovery happens.
func pot_add(mat_id: String) -> bool:
	if _remaining(mat_id) <= 0:
		return false
	pot[mat_id] = int(pot.get(mat_id, 0)) + 1
	for ink_id in GatherDefs.INK_RECIPE_ORDER:
		var inputs: Dictionary = GatherDefs.INK_RECIPES[ink_id].inputs
		if _dict_eq(pot, inputs):
			if _game != null and bool(_game.ink_discovered(String(ink_id))) \
					and _game.mix_ink(ink_id):
				pot.clear()
				_view.bloom(Color(0.55, 0.68, 0.38))
			break
	_view.queue_redraw()
	return true

# Spec 43 — the experiment: attempt whatever's in the pot. Game resolves
# (discovery / mix / smudge / wild / serendipity); the pot empties either
# way and the bloom color tells the story.
func pot_try() -> Dictionary:
	if pot.is_empty() or _game == null:
		return {}
	var result: Dictionary = _game.try_pot_mix(pot)
	if result.is_empty():
		return {}
	pot.clear()
	match String(result.outcome):
		"discovery":
			_view.bloom(WyrdUi.GOLD)
		"mix":
			_view.bloom(Color(0.55, 0.68, 0.38))
		"wild":
			_view.bloom(Color(0.85, 0.65, 0.35))
		"serendipity":
			_view.bloom(Color(0.65, 0.50, 0.80))
		_:
			_view.bloom(Color(0.45, 0.42, 0.40))   # the smudge — grey puff
	_view.queue_redraw()
	return result

func pot_clear() -> void:
	pot.clear()
	_view.queue_redraw()

# The craft: same calls in the same order as the old panel. Spec 45 —
# Thrifty Quill discounts the hedge base cost; Sure Lines leans the rolls.
func _hedge_discount() -> int:
	return 1 if _game != null \
		and bool(_game.perk_active("carto", "thrifty_quill")) else 0

func _stab_perk_bonus() -> float:
	return 0.05 if _game != null \
		and bool(_game.perk_active("carto", "sure_lines")) else 0.0

func craft() -> bool:
	if base_id == "" or _game == null:
		return false
	var cost: Dictionary = ChartsData.craft_cost(base_id, inks, trophy,
		_hedge_discount())
	if not _game.can_afford(cost):
		return false
	if not _game.spend_materials(cost):
		return false
	var chart: Dictionary = ChartsData.inscribe(base_id, inks, _carto_lv(),
		trophy, _stab_perk_bonus())
	if chart.is_empty():
		return false
	_game.add_chart(chart)
	_game.notify("Inscribed: %s." % String(chart.get("name", "a chart")))
	inks.clear()
	trophy = ""
	base_id = ""
	_view.stamp()
	_view.queue_redraw()
	return true

# ---- helpers ----

func _carto_lv() -> int:
	return 1 if _game == null else _game.trade_lv("carto")

func template() -> Dictionary:
	return ChartsData.TEMPLATES.get(base_id, {})

func ink_slots() -> int:
	var n := int(template().get("ink_slots", 0))
	# Spec 45-carto — Master Wayfinder: every chart that takes ink holds
	# one more pot. Slotless charts (snug/summit) stay at zero.
	if n > 0 and _game != null \
			and bool(_game.perk_active("carto", "master_wayfinder")):
		n += 1
	return n

func affix_slots() -> int:
	return int(template().get("affix_slots", 0))

# Have-count minus everything the bench has already claimed (sockets, pot,
# and the placed base's own base_cost) — the honest remaining number.
func _remaining(id: String) -> int:
	var have: int = 0 if _game == null else _game.material_count(id)
	var claimed: int = inks.count(id) + int(pot.get(id, 0))
	if trophy == id:
		claimed += 1
	claimed += int((template().get("base_cost", {}) as Dictionary).get(id, 0))
	return have - claimed

static func _dict_eq(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for k in b:
		if int(a.get(k, -1)) != int(b[k]):
			return false
	return true

# Tutorial guidance: which bench element pulses right now.
func _tutorial_target() -> String:
	var step: int = 0 if _game == null else int(_game.tutorial_step)
	match step:
		2: return "pot"
		3: return "base" if base_id == "" else "result"
		6: return "ink" if (base_id != "" and inks.is_empty()) else \
			("base" if base_id == "" else "result")
	return ""

# Tutorial soft-lock: during guided steps only the taught drop lands.
func _allowed_drop(kind: String, target: String) -> bool:
	var step: int = 0 if _game == null else int(_game.tutorial_step)
	if step == 2:
		return target == "pot"
	if step == 3:
		return target == "base"
	return true

# =====================================================================
# The view: one Control that draws everything and owns the hit-testing
# (the inventory_panel pattern — rects computed per draw, stored for hits).
class BenchView extends Control:
	var bench
	var _tray_rows: Array = []      # {rect, kind, id, ok}
	var _ink_rects: Array = []      # circles as Rect2
	var _base_rect := Rect2()
	var _trophy_rect := Rect2()
	var _pot_rect := Rect2()
	var _try_rect := Rect2()        # spec 43 — the Try the Mix button
	var _result_rect := Rect2()
	var _craft_rect := Rect2()
	var _pot_bloom := Color(0.55, 0.68, 0.38)   # spec 43 — outcome color
	var _stamp_t := 0.0
	var _pops: Dictionary = {}      # rect-key -> remaining pop time
	var _tip := ""                  # hover tooltip text ("" = none)
	var _tip_at := Vector2.ZERO
	var _press_at := Vector2.ZERO   # click-to-place vs drag discrimination
	var _odds_rows: Array = []      # {rect, affix_id} for odds tooltips
	var _codex_rects: Array = []    # spec 45 — {rect, id} for known recipes

	const EDGE := Color(0.26, 0.19, 0.13)
	const WELL := Color(0.80, 0.72, 0.58)
	const PLATE := Color(0.93, 0.88, 0.74)
	const TXT := Color(0.20, 0.15, 0.11)
	const DIM := Color(0.42, 0.35, 0.28)
	# Spec 44 — each ink's bottle color (drawn bottles replace text glyphs).
	const INK_TINT := {
		"hedge_ink": Color(0.42, 0.55, 0.30),
		"stoneground_ink": Color(0.42, 0.42, 0.46),
		"refined_ink": Color(0.93, 0.88, 0.62),
		"ash_ink": Color(0.30, 0.28, 0.26),
		"chalkwash_ink": Color(0.88, 0.86, 0.80),
		"mothglow_ink": Color(0.80, 0.84, 0.90),
		"foxglove_ink": Color(0.28, 0.30, 0.52),
		"gildleaf_ink": Color(0.90, 0.78, 0.42),
	}
	const COPPER := Color(0.66, 0.40, 0.24)
	const COPPER_LIT := Color(0.85, 0.56, 0.34)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func stamp() -> void:
		_stamp_t = 0.25
		set_process(true)

	func pop(key: String) -> void:
		_pops[key] = 0.16
		set_process(true)

	# Spec 43 — a pot bloom in the outcome's color (gold discovery, sage
	# mix, grey smudge, amber wild, violet serendipity).
	func bloom(c: Color) -> void:
		_pot_bloom = c
		pop("pot")

	func _pop_scale(key: String) -> float:
		var t: float = float(_pops.get(key, 0.0))
		if t <= 0.0:
			return 1.0
		# 1.0 -> 1.12 -> 1.0 over the pop window.
		return 1.0 + 0.12 * sin((1.0 - t / 0.16) * PI)

	func _process(delta: float) -> void:
		var busy := _stamp_t > 0.0
		if _stamp_t > 0.0:
			_stamp_t -= delta
		for k in _pops.keys():
			_pops[k] = float(_pops[k]) - delta
			if float(_pops[k]) <= 0.0:
				_pops.erase(k)
			else:
				busy = true
		queue_redraw()
		if not busy:
			set_process(false)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			bench._cursor = event.position
			_update_tip(event.position)
			queue_redraw()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press(event.position)
			else:
				_release(event.position)

	func _press(p: Vector2) -> void:
		_press_at = p
		# Pick from the tray.
		for row in _tray_rows:
			if (row.rect as Rect2).has_point(p) and bool(row.ok):
				bench._held = {"kind": row.kind, "id": row.id}
				queue_redraw()
				return
		# Click socketed things to return them.
		for i in _ink_rects.size():
			if (_ink_rects[i] as Rect2).has_point(p) and i < bench.inks.size():
				bench.remove_ink(i)
				return
		if _trophy_rect.has_point(p) and bench.trophy != "":
			bench.trophy = ""
			queue_redraw()
			return
		if _base_rect.has_point(p) and bench.base_id != "":
			bench.clear_base()
			return
		if _try_rect != Rect2() and _try_rect.has_point(p) \
				and not bench.pot.is_empty():
			bench.pot_try()
			return
		# Spec 45-carto — Practiced Measures: click a known codex row and
		# the pot sets out its makings (you still need the ingredients).
		if bench._game != null \
				and bool(bench._game.perk_active("carto", "practiced_measures")):
			for row in _codex_rects:
				if (row.rect as Rect2).has_point(p):
					var inputs: Dictionary = GatherDefs.INK_RECIPES[row.id].inputs
					if bench._game.can_afford(inputs):
						bench.pot = inputs.duplicate()
						pop("pot")
						queue_redraw()
					return
		if _pot_rect.has_point(p) and not bench.pot.is_empty():
			bench.pot_clear()
			return
		if (_craft_rect.has_point(p) or _result_rect.has_point(p)) \
				and bench.base_id != "":
			bench.craft()

	func _release(p: Vector2) -> void:
		if bench._held.is_empty():
			return
		var kind := String(bench._held.kind)
		var id := String(bench._held.id)
		bench._held = {}
		# Click-to-place: a release near the press point is a click, and a
		# click on a tray row sends the thing where it obviously goes.
		if p.distance_to(_press_at) < 6.0:
			match kind:
				"base":
					if bench._allowed_drop(kind, "base"):
						bench.place_base(id)
				"ink":
					if bench._allowed_drop(kind, "ink"):
						if not bench.socket_ink(id) \
								and bench._allowed_drop(kind, "pot"):
							bench.pot_add(id)
				"mat":
					if bench._allowed_drop(kind, "pot"):
						bench.pot_add(id)
				"trophy":
					if bench._allowed_drop(kind, "trophy"):
						bench.socket_trophy(id)
			queue_redraw()
			return
		if _base_rect.has_point(p) and kind == "base" \
				and bench._allowed_drop(kind, "base"):
			bench.place_base(id)
		elif kind == "ink" and bench._allowed_drop(kind, "ink"):
			var dropped := false
			for i in _ink_rects.size():
				if (_ink_rects[i] as Rect2).has_point(p):
					bench.socket_ink(id)
					dropped = true
					break
			if not dropped and _pot_rect.has_point(p) \
					and bench._allowed_drop(kind, "pot"):
				bench.pot_add(id)
		elif _trophy_rect.has_point(p) and kind == "trophy" \
				and bench._allowed_drop(kind, "trophy"):
			bench.socket_trophy(id)
		elif _pot_rect.has_point(p) and kind == "mat" \
				and bench._allowed_drop(kind, "pot"):
			bench.pot_add(id)
		queue_redraw()

	# What the cursor is over, as a tooltip string ("" = nothing).
	func _update_tip(p: Vector2) -> void:
		_tip = ""
		_tip_at = p
		for row in _tray_rows:
			if (row.rect as Rect2).has_point(p):
				_tip = _tip_for(String(row.kind), String(row.id))
				return
		for row in _odds_rows:
			if (row.rect as Rect2).has_point(p):
				var aff: Dictionary = ChartsData.AFFIXES[row.id]
				_tip = "%s — %s\nBad twin (%s): %s" % [String(aff.name),
					String(aff.good_desc), String(aff.bad_name),
					String(aff.bad_desc)]
				return
		if _base_rect.has_point(p):
			_tip = _tip_for("base", bench.base_id) if bench.base_id != "" \
				else "Drag or click a chart base from the tray."
			return
		for i in _ink_rects.size():
			if (_ink_rects[i] as Rect2).has_point(p):
				_tip = _tip_for("ink", String(bench.inks[i])) \
					if i < bench.inks.size() \
					else "An ink socket — inks tilt the affix odds."
				return
		if _trophy_rect != Rect2() and _trophy_rect.has_point(p):
			_tip = _tip_for("trophy", bench.trophy) if bench.trophy != "" \
				else "A trophy here inks its boss den into the chart — certain."
			return
		if _try_rect != Rect2() and _try_rect.has_point(p):
			_tip = "Try whatever's in the pot. A true mix is learned for good;\na miss smudges — you keep a little, and learn that too."
			return
		if _pot_rect.has_point(p):
			_tip = "The mixing pot. Known mixes stir themselves on the match.\nUnknown ones wait for Try. Click to empty."
			return
		if _craft_rect.has_point(p) or (_result_rect.has_point(p)
				and bench.base_id != ""):
			_tip = "Craft the chart — spends the cost, the chart goes to your case."

	func _tip_for(kind: String, id: String) -> String:
		match kind:
			"base":
				var t: Dictionary = ChartsData.TEMPLATES.get(id, {})
				if t.is_empty():
					return ""
				return "%s — Tier %d · %d affix · %d ink slots\n%s" % [
					String(t.name), int(t.tier), int(t.affix_slots),
					int(t.ink_slots), String(t.get("desc", ""))]
			"ink":
				var ink: Dictionary = ChartsData.INKS.get(id, {})
				return "%s\n%s" % [String(ink.get("name", id)),
					String(ink.get("desc", ""))]
			"mat", "trophy":
				return "%s\n%s" % [GatherDefs.material_name(id),
					String(GatherDefs.MATERIALS.get(id, {}).get("desc", ""))]
		return ""

	# ---- drawing ----
	func _draw() -> void:
		var hdr: Font = WyrdUi.font_header()
		var font: Font = get_theme_default_font()
		if hdr == null:
			hdr = font
		# Spec 44 — parchment grain over the working face (vector, no tex).
		WyrdUi.draw_parchment_grain(self,
			Rect2(Vector2(46, 72), size - Vector2(92, 124)))
		draw_string(hdr, Vector2(54, 56), "The Inscribing Table",
			HORIZONTAL_ALIGNMENT_LEFT, 400, 24, WyrdUi.TERRACOTTA)
		WyrdUi.draw_flourish(self, Vector2(146, 66), 180.0)
		draw_string(font, Vector2(size.x - 180, 56), "Esc — close",
			HORIZONTAL_ALIGNMENT_RIGHT, 130, 12, DIM)
		_odds_rows.clear()
		_draw_tray(hdr, font)
		_draw_bench(hdr, font)
		_draw_result(hdr, font)
		_draw_tip(font)
		# Drag ghost (drawn over the tooltip).
		if not bench._held.is_empty():
			var r := Rect2(bench._cursor - Vector2(46, 14), Vector2(92, 28))
			draw_rect(r, Color(PLATE, 0.85))
			draw_rect(r, EDGE, false, 2.0)
			draw_string(font, r.position + Vector2(0, 19),
				_short_name(String(bench._held.id)),
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, TXT)

	func _short_name(id: String) -> String:
		if ChartsData.TEMPLATES.has(id):
			return String(ChartsData.TEMPLATES[id].name)
		return GatherDefs.material_name(id)

	func _tray_section(hdr: Font, x: float, y: float, label: String) -> float:
		draw_string(hdr, Vector2(x, y), label,
			HORIZONTAL_ALIGNMENT_LEFT, 200, 13, WyrdUi.INK)
		WyrdUi.draw_flourish(self, Vector2(x + 106.0, y + 7.0), 204.0)
		return y + 8.0

	func _tray_row(font: Font, x: float, y: float, kind: String, id: String,
			label: String, ok: bool) -> float:
		var r := Rect2(Vector2(x, y), Vector2(212, 26))
		draw_rect(r, PLATE if ok else Color(0.85, 0.79, 0.66))
		# Spec 44 — top bevel light + a painted roundel on the left.
		draw_rect(Rect2(r.position + Vector2(1.0, 1.0),
			Vector2(r.size.x - 2.0, 1.5)), Color(1, 1, 0.93, 0.4))
		draw_rect(r, EDGE if ok else Color(EDGE, 0.4), false, 1.5)
		var cc := r.position + Vector2(14.0, 13.0)
		if kind == "ink":
			WyrdUi.draw_ink_bottle(self, cc + Vector2(0, 2.0), 18.0,
				INK_TINT.get(id, Color(0.4, 0.4, 0.4)))
		elif kind == "base":
			WyrdUi.draw_scroll(self, Rect2(cc - Vector2(9.0, 7.0),
				Vector2(18.0, 14.0)), false)
		else:
			draw_circle(cc, 9.0, WELL if ok else Color(0.78, 0.72, 0.60))
			draw_arc(cc, 9.0, 0, TAU, 20, Color(EDGE, 0.6), 1.0, true)
			draw_string(font, Vector2(r.position.x + 6.0, r.position.y + 18.0),
				GatherDefs.material_icon(id), HORIZONTAL_ALIGNMENT_CENTER,
				17, 11, TXT if ok else DIM)
		draw_string(font, r.position + Vector2(28.0, 18.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 34.0, 12,
			TXT if ok else DIM)
		_tray_rows.append({"rect": r, "kind": kind, "id": id, "ok": ok})
		return y + 30.0

	func _draw_tray(hdr: Font, font: Font) -> void:
		_tray_rows.clear()
		var x := 54.0
		var y := 92.0
		y = _tray_section(hdr, x, y, "Bases") + 12.0
		for tid in ChartsData.TEMPLATE_ORDER:
			var t: Dictionary = ChartsData.TEMPLATES[tid]
			var unlocked: bool = bench._carto_lv() >= int(t.req_carto)
			var label := "%s · T%d" % [String(t.name), int(t.tier)] if unlocked \
				else "%s — Wayfinder %d" % [String(t.name), int(t.req_carto)]
			y = _tray_row(font, x, y, "base", tid, label, unlocked)
		# Spec 43: zero-count rows hide — the codex carries recipe knowledge
		# now, and the tray must stay inside the panel with 5 inks + 4 mats.
		y = _tray_section(hdr, x, y + 10.0, "Inks") + 12.0
		for ink_id in ChartsData.INKS:
			var n: int = bench._remaining(String(ink_id))
			if n <= 0:
				continue
			y = _tray_row(font, x, y, "ink", String(ink_id), "%s ×%d" % [
				GatherDefs.material_name(String(ink_id)), n], true)
		y = _tray_section(hdr, x, y + 10.0, "Materials") + 12.0
		for mid in ["wild_herb", "bittergrass", "crowsfoot", "mothmint",
				"foxglove_blue", "stonebreak", "bogiron_ore", "logs",
				"palechalk", "starsilver_ore", "hedgesteel_ore"]:
			var n2: int = bench._remaining(mid)
			if n2 <= 0:
				continue
			y = _tray_row(font, x, y, "mat", mid, "%s ×%d" % [
				GatherDefs.material_name(mid), n2], true)
		# Trophies — only rows the player owns.
		var shown := false
		for trophy_id in ChartsData.TROPHY_TO_AFFIX:
			var n3: int = bench._remaining(String(trophy_id))
			if n3 <= 0 and bench.trophy != String(trophy_id):
				continue
			if not shown:
				y = _tray_section(hdr, x, y + 10.0, "Trophies") + 12.0
				shown = true
			y = _tray_row(font, x, y, "trophy", String(trophy_id), "%s ×%d" % [
				GatherDefs.material_name(String(trophy_id)), maxi(0, n3)], n3 > 0)

	func _socket_well(r: Rect2, filled: bool) -> void:
		WyrdUi.draw_well(self, r, WELL if not filled else PLATE)

	func _highlight(r: Rect2, active: bool) -> void:
		if not active:
			return
		var a := 0.45 + 0.35 * sin(bench._pulse)
		draw_rect(r.grow(5), Color(WyrdUi.GOLD, a), false, 3.5)

	func _draw_bench(hdr: Font, font: Font) -> void:
		var target: String = bench._tutorial_target()
		var bx := 320.0
		draw_string(hdr, Vector2(bx, 92), "Bench",
			HORIZONTAL_ALIGNMENT_LEFT, 200, 14, WyrdUi.INK)
		WyrdUi.draw_flourish(self, Vector2(bx + 130.0, 88.0), 200.0)
		# Base socket.
		_base_rect = Rect2(Vector2(bx + 40, 116), Vector2(180, 96))
		var bs := _pop_scale("base")
		_socket_well(Rect2(_base_rect.get_center() - _base_rect.size * bs * 0.5,
			_base_rect.size * bs), bench.base_id != "")
		_highlight(_base_rect, target == "base")
		if bench.base_id == "":
			draw_string(font, _base_rect.position + Vector2(0, 52),
				"chart base", HORIZONTAL_ALIGNMENT_CENTER,
				_base_rect.size.x, 13, DIM)
		else:
			# Spec 44 — the placed base reads as a rolled chart, not a label.
			var t: Dictionary = bench.template()
			WyrdUi.draw_scroll(self, _base_rect.grow(-8.0), false)
			draw_string(hdr, _base_rect.position + Vector2(0, 44),
				String(t.name), HORIZONTAL_ALIGNMENT_CENTER,
				_base_rect.size.x, 17, TXT)
			draw_string(font, _base_rect.position + Vector2(0, 68),
				"Tier %d · click to clear" % int(t.tier),
				HORIZONTAL_ALIGNMENT_CENTER, _base_rect.size.x, 11, DIM)
		# Ink sockets (revealed by the base).
		_ink_rects.clear()
		var slots: int = bench.ink_slots()
		for i in slots:
			var r := Rect2(Vector2(bx + 40 + float(i) * 64.0, 236), Vector2(52, 52))
			_ink_rects.append(r)
			var c := r.get_center()
			var filled: bool = i < bench.inks.size()
			var ps := _pop_scale("ink%d" % i)
			# Spec 44 — a recessed round well; a drawn bottle when filled.
			WyrdUi.draw_round_well(self, c, 26 * ps,
				PLATE if filled else WELL)
			_highlight(r, target == "ink" and i == bench.inks.size())
			if filled:
				var tint: Color = INK_TINT.get(String(bench.inks[i]),
					Color(0.4, 0.4, 0.4))
				WyrdUi.draw_ink_bottle(self, c + Vector2(0, 4), 38.0 * ps, tint)
		if bench.base_id != "" and slots == 0:
			draw_string(font, Vector2(bx + 40, 268),
				"This chart takes no ink.", HORIZONTAL_ALIGNMENT_LEFT,
				240, 12, DIM)
		# Trophy socket (diamond) — only when affixes can roll.
		if bench.affix_slots() > 0:
			_trophy_rect = Rect2(Vector2(bx + 250, 236), Vector2(52, 52))
			var c := _trophy_rect.get_center()
			var pts := PackedVector2Array([c + Vector2(0, -30), c + Vector2(30, 0),
				c + Vector2(0, 30), c + Vector2(-30, 0)])
			draw_colored_polygon(pts, WELL if bench.trophy == "" else PLATE)
			# Spec 44 — inner shadow + pinstripe; a gold ring when charged.
			var inner := PackedVector2Array([c + Vector2(0, -24), c + Vector2(24, 0),
				c + Vector2(0, 24), c + Vector2(-24, 0)])
			draw_polyline(inner + PackedVector2Array([inner[0]]),
				Color(EDGE, 0.30), 1.0, true)
			draw_line(c + Vector2(0, -27), c + Vector2(-27, 0), Color(0, 0, 0, 0.15), 3.0)
			draw_polyline(pts + PackedVector2Array([pts[0]]), EDGE, 2.0, true)
			if bench.trophy != "":
				draw_arc(c, 21.0, 0, TAU, 32, Color(WyrdUi.GOLD, 0.85), 2.0, true)
			if bench.trophy != "":
				draw_string(font, _trophy_rect.position + Vector2(0, 32),
					GatherDefs.material_icon(bench.trophy),
					HORIZONTAL_ALIGNMENT_CENTER, _trophy_rect.size.x, 16, TXT)
			else:
				draw_string(font, Vector2(_trophy_rect.position.x - 14,
					_trophy_rect.end.y + 16), "trophy",
					HORIZONTAL_ALIGNMENT_CENTER, 80, 11, DIM)
		else:
			_trophy_rect = Rect2()
		# Mixing pot — spec 44: a proper copper belly with lit rim, side
		# handles, dark brew inside, and steam when something's in it.
		_pot_rect = Rect2(Vector2(bx + 60, 360), Vector2(140, 84))
		var pc := _pot_rect.get_center()
		var pps := _pop_scale("pot")
		var pr := 38.0 * pps
		draw_circle(pc, pr, COPPER)
		draw_arc(pc, pr - 4.0, PI * 0.85, PI * 1.85, 26, COPPER_LIT, 5.0, true)
		draw_circle(pc, pr * 0.66, Color(0.22, 0.16, 0.12))
		draw_arc(pc, pr * 0.66, 0, TAU, 36, Color(0.10, 0.07, 0.05), 2.0, true)
		for hside in [-1.0, 1.0]:
			draw_arc(pc + Vector2(hside * (pr + 5.0), 0.0), 7.0,
				PI * (0.5 - 0.5 * hside) - PI * 0.5,
				PI * (0.5 - 0.5 * hside) + PI * 0.5, 12, EDGE, 3.0, true)
		draw_arc(pc, pr, 0, TAU, 48, EDGE, 2.5, true)
		if not bench.pot.is_empty():
			# brew glint + two steam wisps
			draw_arc(pc + Vector2(-6.0, -6.0), pr * 0.3, PI * 1.1, PI * 1.6,
				10, Color(0.85, 0.80, 0.62, 0.5), 2.0, true)
			for wx in [-10.0, 8.0]:
				draw_arc(Vector2(pc.x + wx, pc.y - pr - 10.0), 7.0,
					PI * 0.2, PI * 1.0, 10, Color(0.92, 0.90, 0.84, 0.4),
					2.0, true)
		if _pops.has("pot"):
			# Mix flash — a ring blooming off the pot in the outcome color.
			var bloom_t: float = 1.0 - float(_pops.pot) / 0.16
			draw_arc(_pot_rect.get_center(), 38 + bloom_t * 26.0, 0, TAU, 48,
				Color(_pot_bloom, 1.0 - bloom_t), 3.0, true)
		_highlight(Rect2(_pot_rect.get_center() - Vector2(40, 40),
			Vector2(80, 80)), target == "pot")
		var px := _pot_rect.get_center() - Vector2(0, 6)
		var pot_label := ""
		for id in bench.pot:
			pot_label += "%s×%d " % [GatherDefs.material_icon(String(id)),
				int(bench.pot[id])]
		draw_string(font, Vector2(_pot_rect.position.x, px.y + 2.0), pot_label.strip_edges(),
			HORIZONTAL_ALIGNMENT_CENTER, _pot_rect.size.x, 17,
			Color(0.97, 0.93, 0.82))
		# Spec 43 — Try the Mix: the deliberate experiment, beside the pot.
		_try_rect = Rect2(Vector2(bx + 230, 376), Vector2(112, 40))
		var can_try: bool = not bench.pot.is_empty()
		WyrdUi.draw_carved_button(self, _try_rect, can_try)
		draw_string(hdr, _try_rect.position + Vector2(0, 26), "Try the Mix",
			HORIZONTAL_ALIGNMENT_CENTER, _try_rect.size.x, 13,
			WyrdUi.INK if can_try else DIM)
		# Spec 43 — the codex: every pot recipe, in its discovery state.
		var cy := 462.0
		draw_string(hdr, Vector2(bx, cy), "Codex", HORIZONTAL_ALIGNMENT_LEFT,
			200, 13, WyrdUi.INK)
		cy += 16.0
		_codex_rects.clear()
		for rid in GatherDefs.INK_RECIPE_ORDER:
			var rec: Dictionary = GatherDefs.INK_RECIPES[rid]
			var line := "◌ ???"
			var col := DIM
			var known := false
			# Spec 45-carto — Mara's Marginalia: every riddle, plain to read.
			var riddle_open: bool = bench._game != null \
				and (bool((bench._game.seen_hints as Dictionary)
					.get(String(rec.get("hint_key", "")), false))
				or bool(bench._game.perk_active("carto", "marginalia")))
			if bench._game != null \
					and bool(bench._game.ink_discovered(String(rid))):
				known = true
				var parts: Array = []
				for mid in rec.inputs:
					parts.append("%d× %s" % [int(rec.inputs[mid]),
						GatherDefs.material_name(String(mid))])
				line = "%s — %s" % [GatherDefs.material_name(String(rid)),
					" + ".join(parts)]
				col = TXT
			elif riddle_open:
				line = "◌ ??? — %s" % String(rec.get("riddle", ""))
			if known:
				# Spec 44 — a tiny bottle in the ink's color marks the find.
				WyrdUi.draw_ink_bottle(self, Vector2(bx + 6.0, cy + 7.0), 13.0,
					INK_TINT.get(String(rid), Color(0.4, 0.4, 0.4)))
				draw_string(font, Vector2(bx + 16.0, cy + 11.0), line,
					HORIZONTAL_ALIGNMENT_LEFT, 314, 11, col)
				# Spec 45-carto — Practiced Measures: a known row is a button.
				_codex_rects.append({"rect": Rect2(Vector2(bx, cy),
					Vector2(330.0, 15.0)), "id": String(rid)})
			else:
				draw_string(font, Vector2(bx, cy + 11.0), line,
					HORIZONTAL_ALIGNMENT_LEFT, 330, 11, col)
			cy += 15.0

	func _draw_result(hdr: Font, font: Font) -> void:
		var rx := 660.0
		draw_string(hdr, Vector2(rx, 92), "Result",
			HORIZONTAL_ALIGNMENT_LEFT, 200, 14, WyrdUi.INK)
		WyrdUi.draw_flourish(self, Vector2(rx + 130.0, 88.0), 160.0)
		_result_rect = Rect2(Vector2(rx, 116), Vector2(216, 110))
		_socket_well(_result_rect, bench.base_id != "")
		_highlight(_result_rect, bench._tutorial_target() == "result")
		if _stamp_t > 0.0:
			draw_rect(_result_rect.grow(8.0 * _stamp_t * 4.0),
				Color(WyrdUi.GOLD, _stamp_t * 2.0), false, 3.0)
		var y := 250.0
		if bench.base_id == "":
			draw_string(font, _result_rect.position + Vector2(0, 60),
				"place a base", HORIZONTAL_ALIGNMENT_CENTER,
				_result_rect.size.x, 13, DIM)
			return
		var t: Dictionary = bench.template()
		draw_string(hdr, _result_rect.position + Vector2(0, 48),
			String(t.name), HORIZONTAL_ALIGNMENT_CENTER,
			_result_rect.size.x, 20, TXT)
		draw_string(font, _result_rect.position + Vector2(0, 72),
			String(t.get("desc", "")), HORIZONTAL_ALIGNMENT_CENTER,
			_result_rect.size.x, 11, DIM)
		# Odds (same math as before: weights + stability).
		if bench.affix_slots() > 0:
			var weights: Dictionary = ChartsData.compute_weights(int(t.tier), bench.inks,
				bench._carto_lv())
			var bonus: float = ChartsData.ink_stability_bonus(bench.inks)
			var ids := weights.keys()
			ids.sort_custom(func(a, b): return weights[a] > weights[b])
			for id in ids:
				var stab: int = ChartsData.effective_stability(String(id),
					bench._carto_lv(), bonus, bench._stab_perk_bonus())
				# Carved odds chip — left stripe signals twin likelihood at a
				# glance before you read the number. Sage stripe = good twin
				# more likely (≥ 50% stability); terracotta = bad twin more likely.
				var accent: Color = WyrdUi.SAGE if stab >= 50 \
					else WyrdUi.TERRACOTTA
				var odds_r := Rect2(Vector2(rx, y - 17.0), Vector2(216, 22.0))
				WyrdUi.draw_list_row(self, odds_r, accent)
				draw_string(font, Vector2(rx + 10.0, y - 1.0),
					String(ChartsData.AFFIXES[id].name),
					HORIZONTAL_ALIGNMENT_LEFT, 136, 13, TXT)
				draw_string(font, Vector2(rx + 148.0, y - 1.0),
					"%d%% ◆%d%%" % [roundi(weights[id]), stab],
					HORIZONTAL_ALIGNMENT_RIGHT, 66.0, 11,
					WyrdUi.SAGE.darkened(0.1) if stab >= 50 else WyrdUi.TERRACOTTA)
				_odds_rows.append({"rect": odds_r, "id": String(id)})
				y += 26.0
			if bench.trophy != "":
				var den: Dictionary = ChartsData.AFFIXES[
					ChartsData.TROPHY_TO_AFFIX[bench.trophy]]
				# Trophy pin chip — gold accent marks the certain affix.
				var den_r := Rect2(Vector2(rx, y - 17.0), Vector2(216, 22.0))
				WyrdUi.draw_list_row(self, den_r, WyrdUi.GOLD)
				draw_string(font, Vector2(rx + 10.0, y - 1.0),
					"★ %s — certain" % String(den.name),
					HORIZONTAL_ALIGNMENT_LEFT, 216, 12, WyrdUi.GOLD.darkened(0.15))
				y += 26.0
		else:
			draw_string(font, Vector2(rx, y), "A clean run — no affixes.",
				HORIZONTAL_ALIGNMENT_LEFT, 220, 13, DIM)
			y += 19.0
		# Cost + craft button.
		var cost: Dictionary = ChartsData.craft_cost(bench.base_id,
			bench.inks, bench.trophy, bench._hedge_discount())
		y += 6.0
		for id in cost:
			var have: int = 0 if bench._game == null \
				else bench._game.material_count(String(id))
			var enough: bool = have >= int(cost[id])
			draw_string(font, Vector2(rx, y), "%d× %s  (have %d)" % [
				int(cost[id]), GatherDefs.material_name(String(id)), have],
				HORIZONTAL_ALIGNMENT_LEFT, 220, 13,
				TXT if enough else WyrdUi.TERRACOTTA)
			y += 18.0
		_craft_rect = Rect2(Vector2(rx, size.y - 92), Vector2(216, 40))
		var can: bool = bench._game != null and bench._game.can_afford(cost)
		WyrdUi.draw_carved_button(self, _craft_rect, can)
		draw_string(hdr, _craft_rect.position + Vector2(0, 27), "Craft",
			HORIZONTAL_ALIGNMENT_CENTER, _craft_rect.size.x, 17,
			WyrdUi.INK if can else DIM)
		# Spec 44 — a wax seal waits beside the verb when a base is set.
		if bench.base_id != "":
			var sc := Vector2(_craft_rect.end.x - 18.0,
				_craft_rect.position.y - 14.0)
			draw_circle(sc, 9.0, Color(0.62, 0.20, 0.16))
			draw_circle(sc, 5.5, Color(0.72, 0.28, 0.22))
			draw_arc(sc, 9.0, 0, TAU, 22, Color(0.40, 0.12, 0.10), 1.5, true)

	func _draw_tip(font: Font) -> void:
		if _tip == "" or not bench._held.is_empty():
			return
		var lines := _tip.split("\n")
		var w := 0.0
		for ln in lines:
			w = maxf(w, font.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT,
				-1, 13).x)
		var box := Rect2(_tip_at + Vector2(16, 12),
			Vector2(w + 20.0, 12.0 + 19.0 * lines.size()))
		# Keep it on the panel.
		box.position.x = minf(box.position.x, size.x - box.size.x - 8.0)
		box.position.y = minf(box.position.y, size.y - box.size.y - 8.0)
		draw_rect(box, Color(0.97, 0.93, 0.80, 0.97))
		draw_rect(box, EDGE, false, 2.0)
		var ty := box.position.y + 17.0
		for ln in lines:
			draw_string(font, Vector2(box.position.x + 10.0, ty), ln,
				HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 20.0, 13, TXT)
			ty += 19.0
