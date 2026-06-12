class_name ExitWaystone
extends Interactable

# Wyrd — the far waystone inside a chart dungeon. Stepping through ends the
# run: Game awards completion XP and routes back to Town. Replaces the old
# "the run just ends when you quit" non-loop. Spawned by layout_loader at
# the layout's exit tile.
#
# Spec 45-gaps — `abandoning = true` makes this the ENTRY-side return stone:
# always present, pays nothing, just carries you home. Without it an inked
# boss chart soft-locked an under-leveled player (the exit only rises when
# the boss falls and the chart is already spent).

const CAIRN_GLB := preload("res://models/waypoint_cairn.glb")

var abandoning := false
var _used := false

func get_prompt_text() -> String:
	if abandoning:
		return "[E] Abandon the run — return home"
	return "[E] Step through the waystone"

func get_prompt_color() -> Color:
	return Color(0.7, 0.85, 1.0)         # cool waystone blue

func get_collision_radius() -> float:
	return 1.4

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 2.2, 0.0)

func _ready_interactable() -> void:
	var cairn := CAIRN_GLB.instantiate()
	cairn.position = Vector3(0.0, 0.05, 0.0)
	add_child(cairn)
	GlbFit.normalize_height(cairn, 1.8)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 1.4, 0.0)
	glow.light_color = Color(0.55, 0.75, 1.0)
	glow.light_energy = 2.2
	glow.omni_range = 6.0
	add_child(glow)

func is_used() -> bool:
	return _used

func interact(player: Node) -> void:
	# Dead players can't step through — banking the run mid-white-out would
	# cancel the death penalty. (Belt to the player controller's suspenders.)
	if _used or player == null or bool(player.get("dead")):
		return
	_used = true
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("waystone")
	var game := get_tree().root.get_node_or_null("Game")
	var net := get_node_or_null("/root/NetGame")
	if net != null and bool(net.active):
		# Phase B — the stone ends the run for the whole party (host-routed).
		net.request_end(abandoning)
	elif game != null:
		game.return_to_town(player, abandoning)
