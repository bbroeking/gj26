class_name StatusEffect
extends RefCounted

# Spec 31 — one ailment on one combatant. Pure data; Combatant owns the
# tick loop in `_physics_process`. Owns its visual node so the combatant
# can free it when `time_left` runs out.

# Kind keys are stable strings; `combatant.gd` dispatches on them for the
# tick-loop logic (damage vs slow vs no-op).
var kind: String = ""
var time_left: float = 0.0
var tick_interval: float = 0.0          # 0 = never ticks (Root / Snared)
var next_tick: float = 0.0
var damage_per_tick: int = 0
var slow_factor: float = 1.0            # 1.0 = no slow, 0.5 = half speed
# The GPUParticles3D / MeshInstance3D child the combatant spawned for this
# status. Combatant frees it on status expiry or death.
var visual: Node3D = null
