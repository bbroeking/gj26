class_name HeartwoodWard
extends Skill

# B5-wave2 — bark-skin: the hunter borrows the heartwood's patience. The
# next WARD_HP damage is soaked before vigor is touched, for WARD_SEC.
# Player-side state (player.apply_ward); Huntcraft 7.

const WARD_HP := 30
const WARD_SEC := 8.0

func _init() -> void:
	name = "HeartwoodWard"
	cost = 25.0
	base_cd = 14.0

func fire(player: Node) -> void:
	if player == null or not player.has_method("apply_ward"):
		return
	player.apply_ward(WARD_HP, WARD_SEC)
	var sfx = player.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("skill_power")
