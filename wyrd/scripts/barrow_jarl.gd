class_name BarrowJarl
extends "res://scripts/boss.gd"

# The Jarl is a boss with a settlement guard, not a variant of generic death.
# The loader supplies a BarrowJarlController.  This script structurally holds
# `died` behind all three controller-confirmed reliefs.

signal relief_phase_started(phase_index: int)
signal kneeled

const RELIEF_FRACTIONS := [0.75, 0.50, 0.25]

var relief_controller: Node = null
var relief_phase := 0
var vow_shielded := false
var _kneeling := false


func set_relief_controller(controller: Node) -> void:
	relief_controller = controller


func _play_visual_clip(fragment: String) -> void:
	# State clips are visual-only.  The controller remains the authority for all
	# oath mutations, so an imported animation can never settle the encounter.
	var player := AnimDriverScript.find_anim_player(self)
	if player == null:
		return
	for clip in player.get_animation_list():
		if String(clip).to_lower().contains(fragment.to_lower()):
			if player.current_animation != String(clip):
				player.play(String(clip), 0.10)
			return


func release_vow_shield(phase_index: int) -> void:
	if phase_index == relief_phase:
		vow_shielded = false
		set_meta("pale_oath_state", "unshielded")
		_play_visual_clip("relief")


func take_damage(amount: int, from_dir: Vector3,
		crit_chance: float = -1.0, crit_mult_bonus: float = -1.0) -> void:
	if _kneeling or vow_shielded or dead:
		return
	# Clamp a burst at the next authored relief threshold.  A high-damage Skill
	# therefore cannot skip a 75/50/25 vow phase and produce a mismatched bell.
	var threshold_clamp := false
	if relief_phase < RELIEF_FRACTIONS.size():
		var threshold_hp := ceili(float(hp_max) * float(RELIEF_FRACTIONS[relief_phase]))
		if hp > threshold_hp and hp - amount < threshold_hp:
			amount = hp - threshold_hp
			threshold_clamp = true
	# Do not let a burst cross into generic `_die` before the controller says
	# every relief is complete.  The final permitted hit dispatches through our
	# `_die` override, which kneels before emitting `died`.
	if hp - amount <= 0 and not _all_reliefs_complete():
		hp = 1
		boss_hp_changed.emit(hp, hp_max)
		return
	# A critical multiplier must not pierce the clamped threshold after we have
	# made the authored phase decision. Normal Jarl damage remains crit-capable.
	var prior_crit_enabled := crit_enabled
	if threshold_clamp:
		crit_enabled = false
	super(amount, from_dir, crit_chance, crit_mult_bonus)
	crit_enabled = prior_crit_enabled
	if dead or _kneeling:
		return
	if relief_phase < RELIEF_FRACTIONS.size() \
		and float(hp) / float(maxi(1, hp_max)) <= float(RELIEF_FRACTIONS[relief_phase]):
		relief_phase += 1
		vow_shielded = true
		set_meta("pale_oath_state", "vow_shielded")
		_play_visual_clip("shield")
		relief_phase_started.emit(relief_phase)


func _all_reliefs_complete() -> bool:
	return relief_controller != null and relief_controller.has_method("all_reliefs_complete") \
		and bool(relief_controller.call("all_reliefs_complete"))


func _die() -> void:
	if dead or _kneeling:
		return
	if not _all_reliefs_complete():
		hp = 1
		boss_hp_changed.emit(hp, hp_max)
		return
	_kneeling = true
	velocity = Vector3.ZERO
	set_meta("pale_oath_state", "kneeling")
	_play_visual_clip("kneel")
	kneeled.emit()
	var t := create_tween()
	t.tween_property(self, "rotation:x", deg_to_rad(28.0), 0.55)
	t.tween_property(self, "position:y", position.y - 0.34, 0.55)
	t.tween_interval(0.30)
	t.tween_callback(_emit_canonical_death)


func _emit_canonical_death() -> void:
	# This is intentionally the only route to Combatant._die for the Jarl.
	# Generic layout/campaign callbacks remain connected to `died` and therefore
	# cannot settle a boss road while a vow shield remains.
	_play_visual_clip("defeat")
	super._die()
