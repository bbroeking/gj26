class_name HearthGiant
extends "res://scripts/boss.gd"

# Fire in the Bough's boss is deliberately not a Boss/Jarl subclass.  The
# encounter controller owns the authored chain interaction; this actor owns
# the one thing every damage path has in common: a non-terminal heat floor.

signal heat_floor_reached(phase_index: int, floor_hp: int)
signal heat_shield_released(phase_index: int, chain_id: String)
signal kneeled_and_banked

const HEAT_FRACTIONS := [0.75, 0.50, 0.25]

var heat_phase := 0 # Number of floors reached/banks required (0..3).
var heat_shielded := false
var kneeling := false
var banked_fire := false
var aggro_peer_id := 0


func _damage_floor() -> int:
	# The final floor is also non-terminal.  The controller calls
	# kneel_and_bank after Knot Link; damage can never race that transaction.
	if dead:
		return 0
	# The banked Giant is a resolved encounter actor, never a deferred corpse.
	# Keep the exact positive kneeling HP as a permanent floor so late generic
	# arrows, status ticks, and NetGame's zero-membership snapshot cannot emit
	# Combatant.died after the canonical settlement has already happened.
	if kneeling:
		return maxi(1, hp)
	# Once a heat shield has risen, it holds the floor that caused it. Without
	# this branch a second direct hit or status tick would look ahead to the
	# next fraction (75 → 50) while Hollow Link was still unbanked, permanently
	# skipping the edge that arms that authored chain.
	if heat_shielded and heat_phase >= 1 and heat_phase <= HEAT_FRACTIONS.size():
		return ceili(float(hp_max) * float(HEAT_FRACTIONS[heat_phase - 1]))
	if heat_phase < HEAT_FRACTIONS.size():
		return ceili(float(hp_max) * float(HEAT_FRACTIONS[heat_phase]))
	return 1


func _on_damage_floor_reached() -> void:
	if dead or kneeling or heat_shielded or heat_phase >= HEAT_FRACTIONS.size():
		return
	heat_phase += 1
	heat_shielded = true
	velocity = Vector3.ZERO
	set_meta("hearth_giant_state", "heat_shield_%d" % heat_phase)
	_play_visual_clip("heatshield")
	heat_floor_reached.emit(heat_phase, hp)


func release_heat_shield(chain_id: String) -> bool:
	if dead or kneeling or not heat_shielded or heat_phase < 1 or heat_phase > 3:
		return false
	heat_shielded = false
	set_meta("hearth_giant_state", "unshielded_%d" % heat_phase)
	_play_visual_clip("chainreact")
	heat_shield_released.emit(heat_phase, chain_id)
	return true


func kneel_and_bank() -> bool:
	if dead or kneeling or heat_phase != 3:
		return false
	kneeling = true
	banked_fire = true
	heat_shielded = false
	velocity = Vector3.ZERO
	set_process(false)
	set_physics_process(false)
	_set_hurtbox_enabled(false)
	set_meta("hearth_giant_state", "kneeling")
	_play_visual_clip("kneel")
	kneeled_and_banked.emit()
	return true


func reset_fight() -> void:
	super.reset_fight()
	heat_phase = 0
	heat_shielded = false
	kneeling = false
	banked_fire = false
	aggro_peer_id = 0
	set_process(true)
	set_physics_process(true)
	_set_hurtbox_enabled(true)
	set_meta("hearth_giant_state", "unshielded_0")
	AnimDriverScript.play_idle(self)


func take_damage(amount: int, from_dir: Vector3,
		crit_chance: float = -1.0, crit_mult_bonus: float = -1.0) -> void:
	var before := hp
	super(amount, from_dir, crit_chance, crit_mult_bonus)
	# The shield transition has the stronger authored read; ordinary hits still
	# play on every other successful damage path (including crit/marked damage).
	if not dead and not kneeling and not heat_shielded and hp < before:
		_play_visual_clip("hit")


func _begin_attack() -> void:
	# Boss owns attack timing and damage. This only consumes the authored visual
	# clip at the same wind-up transition, with idle as a safe no-clip fallback.
	_play_visual_clip("attack")
	super._begin_attack()


func encounter_snapshot() -> Dictionary:
	return {
		"hp": hp,
		"hp_max": hp_max,
		"aggroed": _aggroed,
		"aggro_peer_id": aggro_peer_id,
		"heat_phase": heat_phase,
		"heat_shielded": heat_shielded,
		"kneeling": kneeling,
		"banked_fire": banked_fire,
	}


# Called only by HearthGiantEncounter after it has accepted a matching,
# monotonically newer World-ready snapshot.  We set phase before hp so
# Combatant's net floor has the same protection the host used.
func apply_encounter_snapshot(payload: Dictionary) -> void:
	var was_shielded := heat_shielded
	var was_kneeling := kneeling
	var prior_hp := hp
	heat_phase = clampi(int(payload.get("heat_phase", heat_phase)), 0, 3)
	heat_shielded = bool(payload.get("heat_shielded", heat_shielded))
	kneeling = bool(payload.get("kneeling", kneeling))
	banked_fire = bool(payload.get("banked_fire", banked_fire))
	aggro_peer_id = int(payload.get("aggro_peer_id", aggro_peer_id))
	var was_aggroed := _aggroed
	_aggroed = bool(payload.get("aggroed", _aggroed))
	hp_max = maxi(1, int(payload.get("hp_max", hp_max)))
	var remote_hp := int(payload.get("hp", hp))
	# Do not call _die for a remote stale terminal packet.  The encounter's
	# floor remains active until its canonical kneel snapshot says otherwise.
	hp = maxi(_damage_floor(), remote_hp) if not kneeling else maxi(1, remote_hp)
	if kneeling:
		velocity = Vector3.ZERO
		set_process(false)
		set_physics_process(false)
		set_meta("hearth_giant_state", "kneeling")
		if not was_kneeling:
			_play_visual_clip("kneel")
	elif _aggroed and not was_aggroed:
		# A late-joining guest builds its arena gates lowered. Replaying aggro
		# through the existing Boss signal restores the same presentation without
		# granting the guest any combat authority.
		aggroed.emit()
	if not kneeling and heat_shielded and not was_shielded:
		_play_visual_clip("heatshield")
	elif not kneeling and was_shielded and not heat_shielded:
		_play_visual_clip("chainreact")
	elif not kneeling and hp < prior_hp:
		_play_visual_clip("hit")


func _play_visual_clip(fragment: String) -> bool:
	var player := AnimDriverScript.find_anim_player(self)
	if player == null:
		return false
	for raw_clip in player.get_animation_list():
		var clip := String(raw_clip)
		if clip.to_lower().contains(fragment.to_lower()):
			if player.current_animation != clip:
				player.play(clip, 0.08)
			set_meta("hearth_giant_clip", clip)
			return true
	# A placeholder or a future rig without this authored action remains safe
	# and readable instead of freezing in a previous non-looping pose.
	AnimDriverScript.play_idle(self)
	return false


func _set_hurtbox_enabled(enabled: bool) -> void:
	var hurt := get_node_or_null("Hurtbox") as Area3D
	if hurt != null:
		hurt.collision_layer = LAYER_HURTBOX if enabled else 0
