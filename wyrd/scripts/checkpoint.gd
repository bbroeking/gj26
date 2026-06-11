extends Node

# Spec 29 — single-slot in-memory checkpoint, written by interactable Hearths
# in rest rooms. On death, player_controller reads the slot (if any) and
# respawns there at full HP instead of the dungeon entrance. No cross-session
# persistence in v1 — the slot lives for the lifetime of the running game.
#
# Registered as the `Checkpoint` autoload (project.godot).

var _slot: Dictionary = {}

# Write the slot. The player's current position is captured as the respawn
# point; derived_stats are deep-duplicated so later mutations don't leak in.
func save(player: Node, room_id: int) -> void:
	if player == null or not player is Node3D:
		return
	var hp_max: int = int(player.get("hp_max"))
	var ds: Dictionary = player.get("derived_stats") if player.get("derived_stats") != null else {}
	_slot = {
		"room_id": room_id,
		"hp_max": hp_max,
		"hp": hp_max,                           # restore to full on respawn
		"derived_stats": ds.duplicate(true),
		"pos": (player as Node3D).global_position,
	}
	print("[checkpoint] saved at room %d (hp_max=%d, pos=%s)" % [
		room_id, hp_max, str(_slot.pos),
	])

func has_checkpoint() -> bool:
	return not _slot.is_empty()

# Return a deep copy of the slot — callers shouldn't mutate the source.
func read() -> Dictionary:
	return _slot.duplicate(true)

func clear() -> void:
	_slot = {}
	print("[checkpoint] cleared")
