class_name SkillEffect
extends RefCounted

# Spec 32b — the on-hit consequence of a Skill. Carried by the projectile
# (arrow) and applied to the hit target on impact. v1 effects all apply
# statuses via Combatant.apply_status; future effect kinds (knockback-on-hit,
# summon-on-kill) can subclass SkillEffect later if needed.

var status_kind: String = ""
var duration: float = 0.0
var damage_per_tick: int = 0
var slow_factor: float = 1.0
var tick_interval: float = 0.0

# Apply this effect to the hit target. Duck-typed on `apply_status` so the
# effect is safe to apply to anything (no-op if the target isn't a Combatant).
func apply(target: Node) -> void:
	if target == null or not target.has_method("apply_status"):
		return
	target.apply_status(status_kind, duration, damage_per_tick,
		slow_factor, tick_interval)

# ---- Static factories (ergonomics) ----
static func burn(dur: float, dpt: int, interval: float) -> SkillEffect:
	var e := SkillEffect.new()
	e.status_kind = "burn"
	e.duration = dur
	e.damage_per_tick = dpt
	e.tick_interval = interval
	return e

static func snared(dur: float, slow: float) -> SkillEffect:
	var e := SkillEffect.new()
	e.status_kind = "snared"
	e.duration = dur
	e.slow_factor = slow
	return e

static func bleed(dur: float, dpt: int, interval: float) -> SkillEffect:
	var e := SkillEffect.new()
	e.status_kind = "bleed"
	e.duration = dur
	e.damage_per_tick = dpt
	e.tick_interval = interval
	return e

# B5-wave2 — Hunter's Mark: no ticks, no slow; combatant.take_damage reads
# the status and amplifies every hit while it holds.
static func marked(dur: float) -> SkillEffect:
	var e := SkillEffect.new()
	e.status_kind = "marked"
	e.duration = dur
	return e
