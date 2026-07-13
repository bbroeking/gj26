extends Label3D

# Spec 14/26 — a floating damage number. MapleStory-style: pops in with a
# scale-punch, scatters out on an arc, fades fast. Colour + size by crit tier.

const TIER_COLOR := {
	"normal": Color(1.00, 0.96, 0.82),   # cream
	"crit":   Color(1.00, 0.80, 0.20),   # gold
	"super":  Color(0.98, 0.52, 0.18),   # ember orange — bonfire glow replaces off-palette purple
}
# Warm sepia-ink outline: hand-stamped storybook quality, consistent across tiers.
const OUTLINE_INK := Color(0.22, 0.16, 0.12)
const OUTLINE_SZ  := 14
const TIER_SCALE := {"normal": 1.0, "crit": 1.45, "super": 1.9}
const LIFETIME := 0.62

var _age := 0.0
var _vel := Vector3.ZERO
var _base := 1.0

func setup(amount: int, tier: String = "normal") -> void:
	text = str(amount)
	modulate = TIER_COLOR.get(tier, TIER_COLOR["normal"])
	_base = TIER_SCALE.get(tier, 1.0)
	outline_size = OUTLINE_SZ
	outline_color = OUTLINE_INK
	# Scatter — up hard, with a random sideways/forward kick.
	var ang := randf() * TAU
	_vel = Vector3(cos(ang) * 1.2, 3.2, sin(ang) * 1.2)
	# Pop — punch from nothing to oversize, then settle.
	scale = Vector3.ZERO
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ONE * _base * 1.35, 0.07) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector3.ONE * _base, 0.06)

# Spec 31 — apply-text variant: a small status verb ("singed!", "snared!"...)
# in the status's signature colour. Smaller scale + gentler arc than a damage
# number so it doesn't compete with the actual hit numbers. Label3D doesn't
# do italic out of the box; the smaller scale + status colour carry the
# "this is a different kind of feedback" cue.
func setup_apply(label: String, color: Color) -> void:
	text = label
	modulate = color
	_base = 0.7
	font_size = 56
	outline_size = OUTLINE_SZ
	outline_color = OUTLINE_INK
	var ang := randf() * TAU
	_vel = Vector3(cos(ang) * 0.5, 2.2, sin(ang) * 0.5)
	scale = Vector3.ZERO
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ONE * _base * 1.15, 0.05) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector3.ONE * _base, 0.05)

func _process(delta: float) -> void:
	_age += delta
	position += _vel * delta
	_vel.y -= 7.0 * delta                # gravity → an arc
	_vel.x = lerpf(_vel.x, 0.0, 3.0 * delta)
	_vel.z = lerpf(_vel.z, 0.0, 3.0 * delta)
	# Fade over the back half of the lifetime.
	var half := LIFETIME * 0.5
	if _age > half:
		modulate.a = clampf(1.0 - (_age - half) / half, 0.0, 1.0)
	if _age >= LIFETIME:
		queue_free()
