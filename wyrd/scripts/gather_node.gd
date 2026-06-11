class_name GatherNode
extends Interactable

# Wyrd — a gatherable resource node (ore rock / forage bush / log pile).
# Spawned by layout_loader from chart bias affixes, and by Town for the
# yard's herb patches. One E-press harvests: material into the Game
# satchel + skill XP. Dungeon nodes deplete for the run; town patches
# regrow after RESPAWN_SEC.

const GatherDefs = preload("res://data/gather.gd")

var kind := "forage_node"     # ore_rock | forage_node | log_pile
var item_id := "wild_herb"    # material granted
var respawns := false         # town patches regrow; dungeon nodes don't
var respawn_sec := 20.0
# A6 — ore tier ("" = untiered). Sets item/xp/channel/req from ORE_TIERS.
var ore_tier := ""
var req_lv := 0
var _tier_xp := 0
var _tier_channel := -1.0

var _depleted := false
var _body: Node3D

# ---- A4: channel-time gathering ----
# E starts a short channel; moving or taking damage cancels it. The bar is
# two billboarded quads above the node. WYRD_FAST_CHANNEL=1 (tests) makes
# channels near-instant.
var _channeling := false
var _channel_t := 0.0
var _channel_len := 1.0
var _channel_player: Node3D = null
var _channel_start_pos := Vector3.ZERO
var _channel_start_hp := 0
var _bar_root: Node3D = null
var _bar_fill: MeshInstance3D = null

func setup(p_kind: String, p_item: String, p_respawns: bool = false) -> void:
	kind = p_kind
	item_id = p_item
	respawns = p_respawns

# A6 — make this an ore vein of the given tier.
func setup_ore_tier(tier_id: String) -> void:
	var t: Dictionary = GatherDefs.ORE_TIERS.get(tier_id, {})
	if t.is_empty():
		return
	ore_tier = tier_id
	kind = "ore_rock"
	item_id = String(t.item)
	req_lv = int(t.req_lv)
	_tier_xp = int(t.xp)
	_tier_channel = float(t.channel_sec)

# A6 — is this vein still above the player's Earthcraft?
func locked(game) -> bool:
	return req_lv > 0 and game != null and game.trade_lv("earth") < req_lv

# ---- Interactable hooks ----
func get_prompt_text() -> String:
	var verb := String(GatherDefs.NODE_KINDS.get(kind, {}).get("verb", "Gather"))
	if locked(get_tree().root.get_node_or_null("Game")):
		return "%s — needs Earthcraft %d" % [GatherDefs.material_name(item_id),
			req_lv]
	return "[E] %s %s" % [verb, GatherDefs.material_name(item_id)]

func get_prompt_color() -> Color:
	if locked(get_tree().root.get_node_or_null("Game")):
		return Color(0.75, 0.68, 0.58)   # stone gray — coveted, not ready
	return Color(0.78, 0.92, 0.62)       # fresh green

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 1.3, 0.0)

func is_used() -> bool:
	return _depleted

# Concept-art props (Meshy pipeline, 2026-06-09) — fall back to the
# procedural primitives if a GLB ever goes missing.
const PROP_GLB := {
	"ore_rock":    {"path": "res://models/prop_ore_vein_v1.glb",  "fit_h": 0.75},
	"forage_node": {"path": "res://models/prop_herb_bush_v1.glb", "fit_h": 0.60},
	"log_pile":    {"path": "res://models/prop_log_pile_v1.glb",  "fit_h": 0.65},
}

func _ready_interactable() -> void:
	_body = Node3D.new()
	add_child(_body)
	var prop: Dictionary = PROP_GLB.get(kind, {})
	if not prop.is_empty() and ResourceLoader.exists(String(prop.path)):
		var packed: PackedScene = load(String(prop.path))
		if packed != null:
			var inst: Node3D = packed.instantiate()
			GlbFit.normalize_height(inst, float(prop.fit_h))
			GlbFit.unmetal(inst)
			inst.position = Vector3(0.0, 0.02, 0.0)
			_body.add_child(inst)
			if ore_tier != "" and ore_tier != "bogiron":
				_tint_tier(inst)
			return
	_build_primitive()

func _build_primitive() -> void:
	var def: Dictionary = GatherDefs.NODE_KINDS.get(kind, {})
	var color: Color = def.get("color", Color(0.5, 0.5, 0.5))
	match String(def.get("shape", "rock")):
		"rock":
			_add_mesh(_make_rock_mesh(), color, Vector3(0.0, 0.28, 0.0))
		"bush":
			_add_mesh(_make_bush_mesh(), color, Vector3(0.0, 0.3, 0.0))
		"pile":
			# Two stacked log boxes, slightly skewed.
			_add_mesh(_make_log_mesh(), color, Vector3(0.0, 0.14, 0.0))
			var top := _add_mesh(_make_log_mesh(), color.lightened(0.1),
				Vector3(0.05, 0.42, 0.0))
			top.rotation.y = 0.4

func _make_rock_mesh() -> Mesh:
	var m := SphereMesh.new()
	m.radius = 0.38
	m.height = 0.6
	m.radial_segments = 7
	m.rings = 4
	return m

func _make_bush_mesh() -> Mesh:
	var m := SphereMesh.new()
	m.radius = 0.34
	m.height = 0.62
	m.radial_segments = 8
	m.rings = 5
	return m

func _make_log_mesh() -> Mesh:
	var m := BoxMesh.new()
	m.size = Vector3(0.85, 0.26, 0.4)
	return m

func _add_mesh(mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	# Soft emissive shimmer so gatherables read as interactive at a glance.
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.35
	mi.material_override = mat
	mi.position = pos
	_body.add_child(mi)
	return mi

# A6 — copper/palechalk veins tint the shared ore prop so tiers read at
# a glance (bogiron keeps the GLB's native rust).
func _tint_tier(root: Node) -> void:
	var col: Color = GatherDefs.ORE_TIERS.get(ore_tier, {}).get("color",
		Color.WHITE)
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.85
	for child in root.find_children("*", "MeshInstance3D", true, false):
		(child as MeshInstance3D).material_override = m

# ---- the harvest (channelled) ----
func interact(player: Node) -> void:
	if _depleted or _channeling or player == null:
		return
	var game := get_tree().root.get_node_or_null("Game")
	if locked(game):
		if game != null:
			game.notify("This vein needs Earthcraft %d." % req_lv)
		return
	_channel_len = channel_seconds(kind, game, _tier_channel)
	if OS.get_environment("WYRD_FAST_CHANNEL") != "":
		_channel_len = 0.05
	if OS.get_environment("WYRD_DEBUG_GATHER") != "":
		print("[gather] start channel %s len=%.2f" % [kind, _channel_len])
	_channeling = true
	_channel_t = 0.0
	var sfx0 := get_node_or_null("/root/Sfx")
	if sfx0 != null:
		sfx0.play({"ore_rock": "mine", "log_pile": "chop"}.get(kind, "forage"))
	_channel_player = player as Node3D
	_channel_start_pos = _channel_player.global_position
	_channel_start_hp = int(player.get("hp")) if player.get("hp") != null else 0
	show_prompt(false)
	_show_bar()
	set_process(true)

func _process(delta: float) -> void:
	if not _channeling:
		set_process(false)
		return
	# Cancel: player gone, dead, wandered off, or got hit mid-channel.
	var pl := _channel_player
	var hp_now := 0 if pl == null else (int(pl.get("hp")) if pl.get("hp") != null else 0)
	if pl == null or not is_instance_valid(pl) \
			or bool(pl.get("dead")) \
			or pl.global_position.distance_to(_channel_start_pos) > 0.6 \
			or hp_now < _channel_start_hp:
		if OS.get_environment("WYRD_DEBUG_GATHER") != "":
			print("[gather] cancel: pl=%s dead=%s dist=%.2f hp=%d/%d" % [pl,
				bool(pl.get("dead")) if pl != null else "x",
				pl.global_position.distance_to(_channel_start_pos) if pl != null else -1.0,
				hp_now, _channel_start_hp])
		_cancel_channel()
		return
	_channel_t += delta
	_set_bar(_channel_t / _channel_len)
	if _channel_t >= _channel_len:
		var done := pl
		_end_channel()
		_harvest(done)

func _cancel_channel() -> void:
	_end_channel()
	_float_text("interrupted")

func _end_channel() -> void:
	_channeling = false
	_channel_player = null
	set_process(false)
	if _bar_root != null:
		_bar_root.queue_free()
		_bar_root = null
		_bar_fill = null

func _harvest(player: Node) -> void:
	if _depleted or player == null:
		return
	var def: Dictionary = GatherDefs.NODE_KINDS.get(kind, {})
	var got := 1
	var game := get_tree().root.get_node_or_null("Game")
	if game != null:
		got += int(game.gather_bonus(kind))   # A9 perks
		game.add_material(item_id, got)
		game.award_xp(String(def.get("trade", "wilds")),
			_tier_xp if _tier_xp > 0 else int(def.get("xp", 8)))
		game.first_time_hint(kind)   # one-time skill tutorial, saved
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("pickup")
	_float_text("+%d %s" % [got, GatherDefs.material_name(item_id)])
	_deplete()

# Channel length for one harvest of `kind` — the single source of truth.
# Spec 38: an equipped trade tool (pickaxe → mining, axe → chopping) cuts
# the channel by its gather_speed; the Earthcraft 10 perk stacks on top.
static func channel_seconds(kind: String, game, base := -1.0) -> float:
	var def: Dictionary = GatherDefs.NODE_KINDS.get(kind, {})
	var t := float(def.get("channel_sec", 1.0)) if base <= 0.0 else base
	if game == null:
		return t
	var tool_slot: String = {"ore_rock": "pickaxe", "log_pile": "axe"}.get(kind, "")
	if tool_slot != "" and game.equipment != null:
		var tool = game.equipment.get_slot(tool_slot)
		if tool != null:
			t *= 1.0 - clampf(float(tool.get("base_value", 0.0)), 0.0, 0.8)
	if kind == "ore_rock" and game.perk_active("earth", "quick_mining"):
		t *= 0.65
	return t

# ---- channel progress bar (billboarded quads) ----
func _show_bar() -> void:
	_bar_root = Node3D.new()
	_bar_root.position = Vector3(0.0, 1.15, 0.0)
	add_child(_bar_root)
	var bg := _bar_quad(Vector2(0.7, 0.1), Color(0.10, 0.08, 0.06, 0.85))
	_bar_root.add_child(bg)
	_bar_fill = _bar_quad(Vector2(0.66, 0.06), Color(0.78, 0.92, 0.62))
	_bar_fill.position.z = 0.01     # in front of the bg quad
	_bar_root.add_child(_bar_fill)
	_set_bar(0.0)

func _bar_quad(size: Vector2, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.no_depth_test = true
	mi.material_override = mat
	return mi

func _set_bar(frac: float) -> void:
	if _bar_fill != null:
		_bar_fill.scale = Vector3(clampf(frac, 0.0, 1.0), 1.0, 1.0)

func _deplete() -> void:
	_depleted = true
	show_prompt(false)
	if _body != null:
		var t := create_tween()
		t.tween_property(_body, "scale", Vector3.ONE * 0.05, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_callback(func(): _body.visible = false)
	if respawns:
		get_tree().create_timer(respawn_sec).timeout.connect(_regrow)

func _regrow() -> void:
	if not is_instance_valid(self):
		return
	_depleted = false
	if _body != null:
		_body.visible = true
		var t := create_tween()
		t.tween_property(_body, "scale", Vector3.ONE, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# A small rising "+1 X" label at the node.
func _float_text(text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 40
	lbl.pixel_size = 0.005
	lbl.outline_size = 10
	lbl.outline_modulate = Color(0.08, 0.05, 0.06, 1.0)
	lbl.modulate = Color(0.85, 0.95, 0.7)
	lbl.position = Vector3(0.0, 1.0, 0.0)
	add_child(lbl)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "position:y", 2.0, 0.9)
	t.tween_property(lbl, "modulate:a", 0.0, 0.9).set_delay(0.3)
	t.chain().tween_callback(lbl.queue_free)
