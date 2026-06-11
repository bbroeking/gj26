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

	# S2 — equip +damage weapon → derived_stats.damage rises.
	var base_dmg: int = int(p.derived_stats.damage)
	var dmg_item := _custom_item("shortbow",
		[{"id": "test", "side": "prefix", "display": "Test", "stat": "damage", "value": 5.0}])
	p.equipment.equip(dmg_item)
	# Note: shortbow's base_stat is "damage" base_value 6 → +6 also rolls in.
	var dmg_expected := base_dmg + 6 + 5
	_check("S2", int(p.derived_stats.damage) == dmg_expected,
		"+5 dmg weapon: damage %d → %d (expect %d)" %
		[base_dmg, p.derived_stats.damage, dmg_expected])

	# S3 — equip +crit-chance ring → derived_stats.crit_chance rises.
	var base_cc: float = p.derived_stats.crit_chance
	var ring := _custom_item("copper_ring",
		[{"id": "test", "side": "suffix", "display": "Test", "stat": "crit_chance",
			"value": 0.30}])
	p.equipment.equip(ring)
	# ring's base_stat is "crit_chance" base_value 0.04 → +0.04 + 0.30.
	var cc_expected := base_cc + 0.04 + 0.30
	_check("S3", absf(p.derived_stats.crit_chance - cc_expected) < 0.001,
		"+0.30 crit ring: cc %.3f → %.3f (expect %.3f)" %
		[base_cc, p.derived_stats.crit_chance, cc_expected])

	# S4 — unequip reverts.
	p.equipment.unequip("ring")
	p.equipment.unequip("weapon")
	p.equipment.unequip("helmet")
	_check("S4", p.hp_max == base_hp \
			and int(p.derived_stats.damage) == base_dmg \
			and absf(p.derived_stats.crit_chance - base_cc) < 0.001,
		"unequip everything: hp/damage/crit back to base")

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
