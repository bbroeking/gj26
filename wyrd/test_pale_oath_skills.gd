extends SceneTree

# Focused Pale Oath runtime contract. This stays independent of the campaign
# slice: it proves only the Huntcraft combat/UI seams owned by this worker.

const DrivingVolleyScript := preload("res://scripts/skills/driving_volley.gd")
const CombatantScript := preload("res://scripts/combatant.gd")
const GameScript := preload("res://scripts/game.gd")
const Progression := preload("res://data/progression.gd")

var _pass := 0
var _fail := 0


func _initialize() -> void:
	_run()


func _check(label: String, ok: bool, detail := "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, detail])


func _run() -> void:
	print("--- Pale Oath Skill runtime check ---")
	var volley = DrivingVolleyScript.new()
	_check("Driving Volley has exact Hunt-18 tuning", volley.projectile_count == 5
		and is_equal_approx(volley.spread_deg, 60.0) and is_equal_approx(volley.damage_mult, 0.4)
		and is_equal_approx(volley.cost, 26.0) and is_equal_approx(volley.base_cd, 6.0), str(volley))
	var dirs := volley._fan_directions(Vector3.FORWARD)
	_check("Driving Volley fan spans five 60-degree lanes", dirs.size() == 5
		and is_equal_approx(rad_to_deg((dirs[0] as Vector3).angle_to(dirs[4] as Vector3)), 60.0), str(dirs))
	var open_plan := DrivingVolleyScript.lesson_loadout_plan(["PowerShot"], false)
	var full_plan := DrivingVolleyScript.lesson_loadout_plan(
		["PowerShot", "MultiShot", "BrambleSnare"], false)
	_check("Lodge lesson appends only an open loadout", bool(open_plan.equip_now)
		and open_plan.loadout == ["PowerShot", "DrivingVolley"])
	_check("Lodge lesson defers without overwriting a full loadout", String(full_plan.state) == "deferred"
		and not bool(full_plan.equip_now) and full_plan.loadout == ["PowerShot", "MultiShot", "BrambleSnare"])

	var ordinary = CombatantScript.new()
	var first := ordinary.apply_driving_volley_impact(41, Vector3.FORWARD)
	var first_impulse: Vector3 = ordinary._knockback
	var second := ordinary.apply_driving_volley_impact(41, Vector3.RIGHT)
	ordinary.apply_knockback(Vector3.RIGHT, 99.0)
	_check("ordinary target receives one guarded Driving Volley shove", first and not second
		and first_impulse.length() > 0.0 and ordinary._knockback == first_impulse,
		str(ordinary._knockback))
	var shielded = CombatantScript.new()
	shielded.set_meta("vow_shielded", true)
	var pressured := shielded.apply_driving_volley_impact(42, Vector3.FORWARD)
	_check("vow-shielded target receives Poise instead of displacement", pressured
		and is_equal_approx(shielded.poise_pressure, 1.0) and shielded._knockback == Vector3.ZERO,
		"poise=%s knockback=%s" % [str(shielded.poise_pressure), str(shielded._knockback)])

	var game := root.get_node_or_null("Game")
	if game == null:
		game = GameScript.new()
		game.name = "Game"
		root.add_child(game)
	await process_frame
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.award_xp("huntcraft", Progression.xp_for_level(19))
	var elite = CombatantScript.new()
	root.add_child(elite)
	elite.is_elite = true
	elite.modifier = "thornshelled"
	elite.depth = 6
	var elite_view := elite.trophy_sense_readout()
	elite.set_seeded_trophy_sigil("Thorn Essence")
	var marked_elite_view := elite.trophy_sense_readout()
	var ordinary_view = CombatantScript.new()
	root.add_child(ordinary_view)
	ordinary_view.set_seeded_trophy_sigil("Thorn Essence")
	var sigil_view := ordinary_view.trophy_sense_readout()
	_check("Trophy Sense reads elite modifier and deterministic reward floor", elite_view
		== {"modifier": "Thornshelled", "reward_tier_floor": 6}, str(elite_view))
	_check("Trophy Sense reads a supplied ordinary sigil without creating one", sigil_view
		== {"trophy_sigil": "Thorn Essence"}, str(sigil_view))
	_check("a seeded trophy sigil remains readable alongside elite metadata", marked_elite_view
		== {"modifier": "Thornshelled", "reward_tier_floor": 6,
			"trophy_sigil": "Thorn Essence"}, str(marked_elite_view))
	ordinary.free()
	shielded.free()
	elite.queue_free()
	ordinary_view.queue_free()
	await process_frame
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
