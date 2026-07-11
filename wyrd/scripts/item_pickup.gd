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
	# Parchment scrap plate behind the name — a handwritten slip dropped with
	# the loot, matching the interactable prompt's language (Label3D on a
	# cream QuadMesh plate, billboarded, no depth test).
	var plate := MeshInstance3D.new()
	plate.name = "LabelPlate"
	var pmesh := QuadMesh.new()
	var char_count: int = String(_item.get("name", "")).length()
	pmesh.size = Vector2(maxf(0.68, char_count * 0.034 + 0.20), 0.28)
	plate.mesh = pmesh
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.93, 0.88, 0.74, 0.88)
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pmat.no_depth_test = true
	pmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	plate.material_override = pmat
	plate.position = Vector3(0, 1.14, 0)
	add_child(plate)
	var lbl := Label3D.new()
	lbl.name = "Label"
	lbl.text = String(_item.name)
	lbl.modulate = col
	# Storybook typeface — the same IM Fell used on interactable prompts.
	var pfont := WyrdUi.font_header()
	if pfont != null:
		lbl.font = pfont
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 64
	lbl.pixel_size = 0.005
	lbl.outline_size = 18
	lbl.outline_modulate = Color(0.10, 0.07, 0.05, 1)
	lbl.position = Vector3(0, 1.15, 0.004)   # fractionally in front of plate
	add_child(lbl)

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
	var plate := get_node_or_null("LabelPlate")
	if beacon != null:
		t.tween_property(beacon, "scale", Vector3(2.0, 2.0, 2.0), 0.20)
	if lbl != null:
		t.tween_property(lbl, "position:y", 1.7, 0.20)
		t.tween_property(lbl, "modulate:a", 0.0, 0.20)
	if plate != null:
		var pm := plate.material_override as StandardMaterial3D
		if pm != null:
			t.tween_method(func(a: float): pm.albedo_color.a = a,
				0.88, 0.0, 0.18)
