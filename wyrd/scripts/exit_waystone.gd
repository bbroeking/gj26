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
	GlbFit.add_ink_outline(cairn)
	# Wayfinding beacon — a procedural dungeon has no memorized layout, so the
	# exit must out-signal the room the instant a sightline opens. A tall emissive
	# beam blooms through the depth fog: bright cool-blue for the real exit, dim
	# neutral for the abandon/return stone so it doesn't compete for attention.
	var beacon: Color = Color(0.55, 0.78, 1.0) if not abandoning \
		else Color(0.72, 0.68, 0.58)
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.30
	cyl.height = 5.0
	beam.mesh = cyl
	beam.position = Vector3(0.0, 2.6, 0.0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(beacon.r, beacon.g, beacon.b, 0.35)
	bmat.emission_enabled = true
	bmat.emission = beacon
	bmat.emission_energy_multiplier = 2.8 if not abandoning else 1.1
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = bmat
	add_child(beam)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 1.4, 0.0)
	glow.light_color = beacon
	glow.light_energy = 2.4 if not abandoning else 1.2
	glow.omni_range = 13.0 if not abandoning else 7.0   # the exit reads across a corridor
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
