extends SceneTree

# Spec 08 — headless 10-run procgen check.
# Run: godot --headless --path godot --script res://test_procgen.gd

const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")

func _init() -> void:
	var runs := 10
	var total_sum := 0.0
	var all_connected := true
	print("--- procgen 10-run check ---")
	for i in runs:
		var layout: Dictionary = DungeonGenScript.generate(-1)
		var s: Dictionary = layout.score
		var conn_ok: bool = s.connectivity >= 0.999
		if not conn_ok:
			all_connected = false
		total_sum += s.total
		print("run %2d: total=%.2f conn=%.2f path=%.2f rooms=%.2f floor=%.2f corr=%.2f deadends=%.2f attempts=%d rooms=%d" % [
			i + 1, s.total, s.connectivity, s.critical_path, s.room_count,
			s.floor_ratio, s.corridor_ratio, s.dead_ends,
			int(layout.attempts), int(s._raw.rooms),
		])
	print("--- avg total=%.3f | all connected=%s ---" % [
		total_sum / runs, str(all_connected),
	])
	quit()
