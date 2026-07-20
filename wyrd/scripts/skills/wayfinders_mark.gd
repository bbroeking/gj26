class_name WayfindersMark
extends Skill

# D8 — a ritual intent rather than Hunter's Mark's projectile.  PlayerController
# reserves owner-local Focus before this fires; KnotEaterEncounter owns every
# target/phase/range/line-of-sight decision and returns the stable receipt.

func _init() -> void:
	name = "WayfindersMark"
	cost = 35.0
	base_cd = 14.0


func fire(player: Node) -> void:
	if player == null or not player.has_method("cancel_wayfinders_mark"):
		return
	var tree := player.get_tree()
	var encounter := tree.get_first_node_in_group("knot_eater_encounter") if tree != null else null
	if encounter == null or not encounter.has_method("press"):
		player.cancel_wayfinders_mark("encounter_unavailable")
		return
	var receipt = encounter.call("press", &"mark", &"")
	# Production coordinators normally route the receipt to the owner themselves
	# (important for remote bodies).  Accepting a synchronous local receipt here
	# also keeps the narrow scene seam useful in offline worlds and focused tests.
	if receipt is Dictionary and not (receipt as Dictionary).is_empty() \
			and player.has_method("apply_wayfinders_mark_receipt"):
		player.apply_wayfinders_mark_receipt(receipt as Dictionary)
