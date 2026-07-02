class_name Chest
extends Interactable

# Spec 29/32d — interactable chest for treasure rooms. Common setup
# (Area3D + collision + Label3D prompt) lives on the Interactable base;
# Chest just declares the GLB and the interact-on-press-E behaviour.
# interact() rolls two treasure drops biased by the room's BFS depth and
# spawns them as ItemPickups (spec 32a). After one use the chest sinks
# and stops detecting; `is_used()` gates the prompt.

const CHEST_GLB := preload("res://models/dungeon_crypt_chest_v1.glb")
const Drops := preload("res://data/drops.gd")

# Set by layout_loader from the host room's BFS depth so deep-dungeon chests
# bias their drops up the rarity ladder.
var depth: int = 5

var _opened := false
var _glb: Node3D

# ---- Interactable hooks ----
func get_prompt_text() -> String:
	return "[E] Open"

func get_prompt_color() -> Color:
	return Color(1.0, 0.95, 0.65)        # warm gold

func _ready_interactable() -> void:
	_glb = CHEST_GLB.instantiate()
	_glb.position = Vector3(0.0, 0.05, 0.0)
	add_child(_glb)
	GlbFit.add_ink_outline(_glb)

func is_used() -> bool:
	return _opened

# Open the chest. Returns the rolled pile (test seam). Spawns the pickups
# beside us via the spec 32a pipe.
func interact(_player: Node) -> Array:
	if _opened:
		return []
	_opened = true
	var pile: Array = []
	# Two rolls — treasure role guarantees chance 1.00 + tier_bias 2.
	# Two items per chest beats a normal mob drop and matches the spec.
	pile.append_array(Drops.roll_drop("treasure", depth))
	pile.append_array(Drops.roll_drop("treasure", depth))
	var host := get_parent()
	if host == null:
		host = get_tree().root
	for it in pile:
		ItemPickup.spawn_scattered(host, it,
			global_position + Vector3(0.0, 0.1, 0.0), 0.6, 1.2)
	# Hide the prompt + sink the chest visual.
	var lbl := get_node_or_null("PromptLabel") as Label3D
	if lbl != null:
		lbl.visible = false
	if _glb != null:
		var t := create_tween()
		t.tween_property(_glb, "position:y", -0.20, 0.35)
	collision_layer = 0          # stop the scanner from re-detecting us
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("chest_open")
	return pile
