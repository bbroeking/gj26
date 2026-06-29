extends OmniLight3D

# Living firelight — a gentle energy flicker around the base value so torch
# pools breathe instead of reading as static decoration. Cosmetic only (no
# gameplay/seed dependence); a random phase keeps neighbouring torches out of
# sync. Env-quality pass (research: "static torch energy reads dead").

var _base := 2.2
var _t := 0.0
var _phase := 0.0

func _ready() -> void:
	_base = light_energy
	_phase = randf() * TAU

func _process(delta: float) -> void:
	_t += delta
	# Two summed sines → organic, non-repeating flicker at roughly +/-12%.
	var f := sin(_t * 7.0 + _phase) * 0.5 + sin(_t * 13.0 + _phase * 1.7) * 0.3
	light_energy = _base * (1.0 + f * 0.12)
