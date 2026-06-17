class_name Hearth
extends Interactable

# Spec 29/32d — interactable hearth. Common setup (Area3D + collision +
# Label3D prompt) lives on the Interactable base; Hearth declares the
# brazier GLB + warm glow and the heal+checkpoint behaviour. Multi-use:
# revisiting re-heals + re-saves (single slot — each save overwrites).
# v1 reuses the brazier GLB; a proper hearth GLB is still a followup.

const BRAZIER_GLB := preload("res://models/dungeon_crypt_brazier_v1.glb")
const LoadoutPanelScript := preload("res://scripts/ui/loadout_panel.gd")

# Set by layout_loader from the room's id so the checkpoint slot knows which
# room it belongs to (handy for debugging + the eval that verifies save).
var room_id: int = -1

var _brazier: Node3D
var _glow: OmniLight3D

# ---- Interactable hooks ----
func get_prompt_text() -> String:
	return "[E] Rest"

func get_prompt_color() -> Color:
	return Color(1.0, 0.85, 0.7)         # warm amber

func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.6, 0.0)

func _ready_interactable() -> void:
	_brazier = BRAZIER_GLB.instantiate()
	_brazier.position = Vector3(0.0, 0.05, 0.0)
	add_child(_brazier)
	GlbFit.add_ink_outline(_brazier)
	# Warm hearth pool — visually distinct from a shrine's cold blue.
	_glow = OmniLight3D.new()
	_glow.position = Vector3(0.0, 1.1, 0.0)
	_glow.light_color = Color(1.0, 0.7, 0.42)
	_glow.light_energy = 2.4
	_glow.omni_range = 6.0
	add_child(_glow)

# Multi-use — a player can come back to top up + re-save. (Default is_used
# from Interactable returns false; no override needed.)

# Heal the player to full and write a checkpoint. Returns the saved slot
# (test seam — `test_typed_rooms` asserts on the dict).
func interact(player: Node) -> Dictionary:
	if player == null:
		return {}
	if player.has_method("heal_to_full"):
		player.heal_to_full()
	var cp := get_node_or_null("/root/Checkpoint")
	if cp != null:
		cp.save(player, room_id)
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("hearth_rest")
	# B5 — resting is the kit-swap moment (FATE checkpoint convention).
	var lp: CanvasLayer = LoadoutPanelScript.new()
	get_tree().current_scene.add_child(lp)
	if cp != null and cp.has_method("read"):
		return cp.read()
	return {}
