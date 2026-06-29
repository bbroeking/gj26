extends GPUParticles3D

# Per-biome ambient motes (dust / embers / fireflies / snow / wisps). A single
# camera-following emitter box puts slow parallax + quiet life into the empty
# procedural floors and gives each biome a signature airborne tell. Env-quality
# pass (research: "highest atmosphere-per-byte effect"). Follows the local
# player on XZ so the box always covers the FATE view.

var _player: Node3D = null

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		var g := get_node_or_null("/root/Game")
		_player = (g.local_player() if g != null else null)
		if _player == null:
			return
	global_position = Vector3(_player.global_position.x, 3.5,
		_player.global_position.z)
