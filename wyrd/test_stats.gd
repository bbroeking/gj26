extends SceneTree

# Spec 27e — equip → derive → consume. Verifies item stats reach the
# player's derived totals and that the combat consumers (combatant
# take_damage with a passed-in crit chance) respect them.
#   godot --headless --path godot --script res://test_stats.gd

const Items = preload("res://data/items.gd")
const CombatantScript := preload("res://scripts/combatant.gd")
const PlayerScene := preload("res://scenes/Player.tscn")
const HitstopScript := preload("res://scripts/hitstop.gd")

var _pass := 0
var _fail := 0

func _initialize() -> void:
	_run()

func _check(id: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("  PASS  %s — %s" % [id, detail])
	else:
		_fail += 1
		print("  FAIL  %s — %s" % [id, detail])

# Build a player under a host; let _ready finish.
func _make_player(host: Node3D) -> Node3D:
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	return p

# Build a custom item with the affixes we need (bypass the random roll).
func _custom_item(kind_id: String, affixes: Array, rarity := "magic") -> Dictionary:
	var it := Items.make_item(kind_id, "normal")
	it.rarity = rarity
	it.affixes = affixes
	return it

func _run() -> void:
	print("--- spec 27e stats evals ---")
	var hs: Node = HitstopScript.new()
	hs.name = "Hitstop"
	root.add_child(hs)
	var host := Node3D.new()
	root.add_child(host)
	await physics_frame
	await physics_frame

	# S1 — equip +10 HP item → hp_max rises by 10.
	var p := _make_player(host)
	await physics_frame
	await physics_frame
	var base_hp: int = p.hp_max
	var hp_item := _custom_item("leather_helm",
		[{"id": "test", "side": "prefix", "display": "Test", "stat": "hp", "value": 10.0}])
	p.equipment.equip(hp_item)
	# leather_helm's base_stat = hp, base_value = 4 → +4 also rolls in.
	var hp_expected := base_hp + 4 + 10
	_check("S1", p.hp_max == hp_expected,
		"+10 HP item (helm base +4): hp_max %d → %d (expect %d)" %
		[base_hp, p.hp_max, hp_expected])

	# S2 — ADR 0013: equip a +damage weapon → derived_stats.damage RISES.
	var base_dmg: int = int(p.derived_stats.damage)
	var dmg_item := _custom_item("shortbow",
		[{"id": "test", "side": "prefix", "display": "Test", "stat": "damage", "value": 5.0}])
	p.equipment.equip(dmg_item)
	_check("S2", int(p.derived_stats.damage) > base_dmg,
		"gear gives power: +damage weapon raises damage above %d (got %d)" %
		[base_dmg, p.derived_stats.damage])

	# S3 — ADR 0013: equip a +crit-chance ring → derived_stats.crit_chance RISES.
	var base_cc: float = p.derived_stats.crit_chance
	var ring := _custom_item("copper_ring",
		[{"id": "test", "side": "suffix", "display": "Test", "stat": "crit_chance",
			"value": 0.30}])
	p.equipment.equip(ring)
	_check("S3", p.derived_stats.crit_chance > base_cc + 0.001,
		"gear gives power: +crit ring raises crit_chance above %.3f (got %.3f)" %
		[base_cc, p.derived_stats.crit_chance])

	# S4 — unequip everything → stats revert to base.
	p.equipment.unequip("ring")
	p.equipment.unequip("weapon")
	p.equipment.unequip("helmet")
	_check("S4", p.hp_max == base_hp \
			and int(p.derived_stats.damage) == base_dmg \
			and absf(p.derived_stats.crit_chance - base_cc) < 0.001,
		"unequip everything: hp/damage/crit revert to base")

	# GF1 — ADR 0013: a rolled RARE warbow raises combat power.
	var gf_dmg: int = int(p.derived_stats.damage)
	p.equipment.equip(Items.make_item("warbow", "rare"))
	_check("GF1", int(p.derived_stats.damage) > gf_dmg,
		"rare warbow raises damage above base %d (got %d)" %
		[gf_dmg, p.derived_stats.damage])

	# GF2 — unequip the rare bow → damage drops back to base.
	p.equipment.unequip("weapon")
	_check("GF2", int(p.derived_stats.damage) == gf_dmg,
		"unequip rare warbow: damage back to base %d (got %d)" %
		[gf_dmg, p.derived_stats.damage])

	# GF3 — HP from armor still applies.
	var gf_hp: int = p.hp_max
	p.equipment.equip(Items.make_item("leather_chest", "magic"))
	_check("GF3", p.hp_max > gf_hp,
		"leather_chest raises hp_max %d → %d" % [gf_hp, p.hp_max])
	p.equipment.unequip("chest")

	# DB — ADR 0013 vertical progression. Uses the live /root/Game autoload.
	var game = root.get_node_or_null("Game")
	if game != null:
		# DB1 — leveling Wayfinding grows the player's base power.
		var lv1_dmg: int = int(p.derived_stats.damage)
		var lv1_hp: int = p.hp_max
		game.trades.wayfinding.lv = 10
		p._derive_stats()
		_check("DB1-level-scales-power",
			int(p.derived_stats.damage) > lv1_dmg and p.hp_max > lv1_hp,
			"lv10 dmg %d / hp %d > lv1 dmg %d / hp %d" %
			[p.derived_stats.damage, p.hp_max, lv1_dmg, lv1_hp])
		# DB2 — level-delta difficulty: hits-to-kill a skeleton rises with den level.
		game.trades.wayfinding.lv = 7
		p._derive_stats()
		var pdmg := float(p.derived_stats.damage)
		var lp := float(game.LEVEL_POWER)
		var ek := func(den_lv: int) -> int:
			return ceili(18.0 * pow(lp, float(den_lv - 1)) / pdmg)
		var easy: int = ek.call(5)   # delta -2
		var fair: int = ek.call(7)   # delta 0
		var hard: int = ek.call(9)   # delta +2
		_check("DB2-delta-bands-rise", easy <= fair and fair <= hard and hard > easy,
			"lv7 vs den 5/7/9 → hits-to-kill %d / %d / %d (rises with depth)" % [easy, fair, hard])
		game.trades.wayfinding.lv = 1
		p._derive_stats()

	# S5 — passing a high crit_chance to take_damage raises observed crit rate.
	CombatantScript.crit_enabled = true
	var ce: Node3D = CombatantScript.new()
	host.add_child(ce)
	ce.cache_meshes()
	ce.setup(100000, 0.4, 1.4)
	ce.role = "combat"
	var crits := 0
	for i in 200:
		var before: int = ce.hp
		ce.take_damage(6, Vector3(0, 0, 1), 0.80, 0.0)
		if before - ce.hp > 6:
			crits += 1
	CombatantScript.crit_enabled = false
	_check("S5", crits > 100,
		"200 hits at 0.80 crit_chance: %d crits (expect >>40)" % crits)

	print("--- stats evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
