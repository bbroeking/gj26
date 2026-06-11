class_name HitFeedback
extends RefCounted

# Spec 32c — the 6 channels of impact feedback (flash, knockback, hitstop,
# spark, shake, SFX) collapse into one static module with two entry points:
#
#   HitFeedback.play_hit(target, tier, from_dir)
#       — fires all 6 channels in concert for an arrow impact.
#   HitFeedback.tick_pulse(target, status_kind)
#       — soft mesh-tint pulse for status DoT ticks (Burn/Bleed). Closes the
#         spec 31 deferred followup ("mesh tint pulse on tick"). Suppressed
#         when a hit-flash is already active so the two systems don't fight
#         for ownership of the combatant's `_meshes` material overrides.
#
# Tier-keyed tunables live as const dicts here — single source of truth for
# the per-tier feel.

const HitSparkScript := preload("res://scripts/hit_spark.gd")

const FLASH_SEC := 0.12              # standard hit-flash duration (mirrors combatant.FLASH_SEC)
const PULSE_DURATION := 0.08         # softer pulse for status DoT ticks
const KNOCKBACK_BASE := 0.6          # base strength (matches combatant.KNOCKBACK)

const HITSTOP_BY_TIER := {
	"normal": 0.07, "crit": 0.13, "super": 0.20,
}
const SHAKE_BY_TIER := {
	"normal": 0.06, "crit": 0.15, "super": 0.30,
}
const KNOCKBACK_MULT := {
	"normal": 1.0, "crit": 1.6, "super": 1.6,
}
const SFX_BY_TIER := {
	"normal": "hit", "crit": "crit", "super": "crit",
}

# Status kinds that pulse the mesh on tick. Status kinds without an entry
# here (snared, root) tick silently — they have no damage, so no flash.
const PULSE_COLOR_BY_STATUS := {
	"burn":  Color(1.00, 0.55, 0.18, 0.35),
	"bleed": Color(0.85, 0.20, 0.20, 0.35),
}

# All 6 channels for an arrow impact. Tier ∈ {"normal", "crit", "super"}.
static func play_hit(target: Node3D, tier: String, from_dir: Vector3) -> void:
	if target == null:
		return
	# 1. Mesh flash (white, the existing hit-flash colour).
	if target.has_method("apply_flash"):
		target.apply_flash(FLASH_SEC, Color.WHITE)
	# 2. Knockback — multiplied by tier (crit + super both hit harder).
	if target.has_method("apply_knockback") and from_dir.length() > 0.001:
		var mult: float = float(KNOCKBACK_MULT.get(tier, 1.0))
		target.apply_knockback(from_dir, KNOCKBACK_BASE * mult)
	# 3. Hitstop — global freeze frame, scaled by tier.
	var hs := target.get_node_or_null("/root/Hitstop")
	if hs != null:
		hs.freeze(float(HITSTOP_BY_TIER.get(tier, 0.07)))
	# 4. Hit-spark — particle pop at chest height.
	HitSparkScript.spawn(target.get_parent(),
		target.global_position + Vector3(0, 1.0, 0), tier)
	# 5. Camera shake.
	var cr = target.get_tree().get_first_node_in_group("camera_rig")
	if cr != null and cr.has_method("shake"):
		cr.shake(float(SHAKE_BY_TIER.get(tier, 0.06)))
	# 6. SFX.
	var sfx := target.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play(String(SFX_BY_TIER.get(tier, "hit")))

# Soft mesh-tint pulse for a status DoT tick. Suppressed when a hit-flash is
# active (the two would fight for `_meshes` ownership — spec 31 followup
# concern). Status kinds without a colour entry tick silently.
static func tick_pulse(target: Node3D, status_kind: String) -> void:
	if target == null:
		return
	if not PULSE_COLOR_BY_STATUS.has(status_kind):
		return                       # snared/root tick silently (no damage anyway)
	# Skip if a hit-flash is already active (don't fight for `_meshes` ownership).
	var flash_t = target.get("_flash_t")
	if flash_t != null and float(flash_t) > 0.0:
		return
	var col: Color = PULSE_COLOR_BY_STATUS[status_kind]
	if target.has_method("apply_flash"):
		target.apply_flash(PULSE_DURATION, col)
