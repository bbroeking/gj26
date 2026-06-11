class_name Skill
extends RefCounted

# Spec 32b — abstract base for a player-usable ability. Subclasses (BasicShot,
# PowerShot, MultiShot, BrambleSnare, future Ranger paths…) override `fire()`
# or inherit ProjectileSkill's data-driven default. Skill instances live on
# `player.skills` and are dispatched by `player._try_skill(slot)`.

const CDR_CAP := 0.80

var name: String = ""
var cost: float = 0.0
var base_cd: float = 0.0

# Compute the effective cooldown using `player.derived_stats.cooldown_reduction`,
# capped at CDR_CAP (D3 model). Slot 1 BasicShot overrides this to scale with
# `fire_rate` via `derived_stats.fire_cooldown` instead (preserves spec 30's
# split: fire_rate scales the basic shot, cooldown_reduction scales 2-4).
func effective_cd(player: Node) -> float:
	var ds = player.get("derived_stats")
	if ds == null:
		return base_cd
	var cdr: float = clampf(float(ds.get("cooldown_reduction", 0.0)), 0.0, CDR_CAP)
	return base_cd / (1.0 + cdr)

# Abstract — every concrete skill overrides this. The base implementation
# raises an error so a forgotten override doesn't silently no-op.
func fire(_player: Node) -> void:
	push_error("Skill.fire() not implemented for %s" % name)
