class_name ItemPickup
extends Area3D

# Spec 27b/32a — a ground item pickup. An Area3D that hosts a glowing beacon +
# a floating rarity-coloured label. Detection is *passive* (we sit on the
# PICKUP_LAYER and the player's PickupScanner detects us).
#
# Spec 32a — the deep module owns the full loot pipe:
#   `ItemPickup.spawn(host, item, position)` — instantiates the scene, adds it
#       to `host` (with force_readable_name), positions it, runs internal
#       `_setup(item)`. Replaces the duplicated boilerplate that lived in
#       `combatant._spawn_one_pickup` and `chest.interact`.
#   `ItemPickup.try_take(player) -> bool` — owns the full take transaction:
#       find_first_fit on the player's inventory, place if it fits, fire VFX,
#       play SFX, log. Returns true on success, false if inventory full.
# `_setup` / `_grab` / `_get_item` are private — `spawn` + `try_take` are the
# only public seams.

const PICKUP_LAYER := 16
const PickupScene := preload("res://scenes/ItemPickup.tscn")

const RARITY_COLOR := {
	"normal": Color(1.00, 0.96, 0.82),
	"magic":  Color(0.42, 0.62, 1.00),
	"rare":   Color(1.00, 0.80, 0.20),
	"unique": Color(1.00, 0.55, 0.20),
}

var _item: Dictionary = {}
var _grabbed := false

# Spec 32a — single seam for spawning a ground pickup. Replaces the
# duplicated instantiate + add_child(true) + setup pattern that lived
# in combatant._spawn_one_pickup and chest.interact.
static func spawn(host: Node, item: Dictionary, position: Vector3) -> ItemPickup:
	var pk: ItemPickup = PickupScene.instantiate()
	pk.name = "ItemPickup"
	# force_readable_name=true → "ItemPickup2/3/..." on collision instead of
	# the cryptic @Area3D@N pattern (spec 27b followup).
	host.add_child(pk, true)
	pk.global_position = position
	pk._setup(item)
	return pk

# Build the Area3D's collision + visuals from the item data. Private — only
# called by `spawn`.
func _setup(item: Dictionary) -> void:
	_item = item
	collision_layer = PICKUP_LAYER
	collision_mask = 0
	# NOTE — `monitorable`/`monitoring` can't be set during a physics signal
	# callback (we're spawned from inside take_damage → _die → _spawn_drops),
	# and Area3D defaults to both = true anyway, which is what we want.
	var shape := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.7
	shape.shape = sph
	shape.position = Vector3(0, 0.5, 0)
	add_child(shape)
	_build_beacon()
	_build_label()

func _build_beacon() -> void:
	var col: Color = RARITY_COLOR.get(String(_item.rarity), Color.WHITE)
	var mi := MeshInstance3D.new()
	mi.name = "Beacon"
	var cap := CapsuleMesh.new()
	cap.height = 0.6
	cap.radius = 0.10
	mi.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.position = Vector3(0, 0.45, 0)
	add_child(mi)

func _build_label() -> void:
	var col: Color = RARITY_COLOR.get(String(_item.rarity), Color.WHITE)
	var rarity := String(_item.rarity)
	var hf := WyrdUi.font_header()
	# Parchment plate — ink border behind cream fill, both billboarded.
	# Added before the label so the painter's algorithm puts text on top.
	var has_sub := rarity != "normal"
	var plate_h := 0.36 if has_sub else 0.24
	var border := _plate_quad(Vector2(1.40, plate_h + 0.04),
		Color(0.08, 0.04, 0.02, 0.86))
	border.name = "ItemPlate"
	border.position = Vector3(0, 1.15, -0.012)
	add_child(border)
	var fill := _plate_quad(Vector2(1.33, plate_h),
		Color(0.93, 0.87, 0.70, 0.78))
	fill.position = Vector3(0, 1.15, -0.006)
	add_child(fill)
	# Item name in IM Fell SC — rarity colour on parchment.
	var lbl := Label3D.new()
	lbl.name = "Label"
	lbl.text = String(_item.name)
	lbl.modulate = col
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 56
	lbl.pixel_size = 0.0048
	lbl.outline_size = 10
	lbl.outline_modulate = Color(0.08, 0.05, 0.06, 0.92)
	if hf != null:
		lbl.font = hf
	lbl.position = Vector3(0, 1.22 if has_sub else 1.15, 0)
	add_child(lbl)
	# Rarity inscription below the name — magic+ items only.
	if has_sub:
		var sub := Label3D.new()
		sub.name = "RarityLabel"
		sub.text = rarity.capitalize()
		sub.modulate = Color(col, 0.72)
		sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sub.no_depth_test = true
		sub.font_size = 36
		sub.pixel_size = 0.0048
		sub.outline_size = 8
		sub.outline_modulate = Color(0.08, 0.05, 0.06, 0.80)
		if hf != null:
			sub.font = hf
		sub.position = Vector3(0, 1.04, 0)
		add_child(sub)

# A billboarded quad for the label's parchment plate backing.
func _plate_quad(sz: Vector2, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = sz
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.no_depth_test = true
	mi.material_override = mat
	return mi

# Spec 32a — full take transaction. Returns true on success, false if the
# player's inventory is full (pickup stays on the ground) or if we've
# already been grabbed (re-entrancy guard).
func try_take(player: Node) -> bool:
	if _grabbed:
		return false
	if player == null or not "inventory" in player:
		return false
	var inv = player.inventory
	if inv == null or not inv.has_method("find_first_fit"):
		return false
	var preview: Dictionary = _get_item()
	var fit: Dictionary = inv.find_first_fit(preview)
	if fit.is_empty():
		print("[loot] inventory full — %s left on the ground" % preview.name)
		return false
	var it: Dictionary = _grab()
	if it.is_empty():
		return false
	inv.try_place(it, fit.pos, fit.rotated)
	var rot_note := " (rotated)" if fit.rotated else ""
	print("[loot] +1 %s [%s] → %s%s" % [it.name, it.rarity, str(fit.pos), rot_note])
	var sfx := player.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("pickup")
	return true

# Preview the item without consuming. Private — only try_take needs it.
func _get_item() -> Dictionary:
	return _item

# Consume + VFX + self-free. Private — only try_take calls it. Returns the
# item dict on success, empty if already grabbed.
func _grab() -> Dictionary:
	if _grabbed:
		return {}
	_grabbed = true
	collision_layer = 0          # immediately stop the scanner from seeing us
	var it := _item
	_play_pickup_vfx()
	get_tree().create_timer(0.22).timeout.connect(queue_free)
	return it

func _play_pickup_vfx() -> void:
	var t := create_tween()
	t.set_parallel(true)
	var beacon := get_node_or_null("Beacon")
	var lbl := get_node_or_null("Label")
	var sub := get_node_or_null("RarityLabel")
	if beacon != null:
		t.tween_property(beacon, "scale", Vector3(2.0, 2.0, 2.0), 0.20)
	if lbl != null:
		t.tween_property(lbl, "position:y", 1.7, 0.20)
		t.tween_property(lbl, "modulate:a", 0.0, 0.20)
	if sub != null:
		t.tween_property(sub, "modulate:a", 0.0, 0.18)
