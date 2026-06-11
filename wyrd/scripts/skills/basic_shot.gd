class_name BasicShot
extends ProjectileSkill

# Spec 32b — slot 1. Free + cooldown, single arrow, no on-hit status, gold
# visual. F-key also fires this via the input buffer (preserves the snappy
# spec 30 F-spam feel).

func _init() -> void:
	name = "BasicShot"
	cost = 0.0
	base_cd = 0.28
	damage_mult = 1.0
	skill_type = "basic"
	on_hit_effects = []
	recoil_amount = -0.4
	bow_pop_mult = 1.22
	sfx_key = "fire"

# BasicShot's cooldown scales with `fire_rate` (the existing spec 27e
# affix), NOT `cooldown_reduction` (which is reserved for slots 2-4). This
# preserves spec 30's split between the two affixes.
func effective_cd(player: Node) -> float:
	var ds = player.get("derived_stats")
	if ds == null:
		return base_cd
	return float(ds.get("fire_cooldown", base_cd))
