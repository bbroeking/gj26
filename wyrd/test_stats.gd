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
		# DB1 — Huntcraft, and only Huntcraft, grows the player's base power.
		var lv1_dmg: int = int(p.derived_stats.damage)
		var lv1_hp: int = p.hp_max
		game.trades.huntcraft = {"lv": 10, "xp": game.xp_for_level(10)}
		p._derive_stats()
		_check("DB1-level-scales-power",
			int(p.derived_stats.damage) > lv1_dmg and p.hp_max > lv1_hp,
			"lv10 dmg %d / hp %d > lv1 dmg %d / hp %d" %
			[p.derived_stats.damage, p.hp_max, lv1_dmg, lv1_hp])
		# DB2 — level-delta difficulty: hits-to-kill a skeleton rises with den level.
		game.trades.huntcraft = {"lv": 7, "xp": game.xp_for_level(7)}
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
		# DB3 — a level-up refreshes live stats via the leveled_up signal (no
		# manual _derive_stats), and grows current HP by the pool increase.
		game.trades.huntcraft = {"lv": 1, "xp": 0}
		p._derive_stats()
		var b_dmg: int = int(p.derived_stats.damage)
		var b_hpmax: int = p.hp_max
		p.hp = b_hpmax
		game.trades.huntcraft = {"lv": 8, "xp": game.xp_for_level(8)}
		game.leveled_up.emit("huntcraft", 8)
		_check("DB3-levelup-refreshes-live",
			int(p.derived_stats.damage) > b_dmg and p.hp_max > b_hpmax \
				and p.hp > b_hpmax,
			"lv1→8 via signal: dmg %d→%d, hp_max %d→%d, hp grew to %d" %
			[b_dmg, p.derived_stats.damage, b_hpmax, p.hp_max, p.hp])
		game.trades.huntcraft = {"lv": 1, "xp": 0}
		p._derive_stats()
		# LG — ADR 0013 source #3: boss trophies → capped ledger stat boosts.
		if game.ledger != null:
			game.ledger.slots = {}
			_check("LG0-ledger-empty", game.ledger.sum_stats().is_empty(),
				str(game.ledger.sum_stats()))
			game.ledger.apply("tusker_tusk")   # +12 hp
			_check("LG1-apply-sets-slot",
				int(game.ledger.sum_stats().get("hp", 0)) == 12,
				str(game.ledger.sum_stats()))
			var lg_pre: int = p.hp_max
			p._derive_stats()
			_check("LG2-ledger-flows-to-derived", p.hp_max == lg_pre + 12,
				"hp_max %d → %d (expect +12)" % [lg_pre, p.hp_max])
			var lg_saved: Dictionary = game.ledger.slots.duplicate(true)
			game.ledger.slots = {}
			game.ledger.load_slots(lg_saved)
			_check("LG3-ledger-persists-roundtrip",
				int(game.ledger.sum_stats().get("hp", 0)) == 12,
				str(game.ledger.sum_stats()))
			game.ledger.slots = {}
			p._derive_stats()

	# HF — Phase 1 player hit-feedback: a hit arms the micro-stun + flinch +
	# i-frame timers, and a second hit inside the i-frame window deals 0 damage.
	p.dead = false
	p.hp = p.hp_max
	p._iframe_t = 0.0
	p._stun_t = 0.0
	p._flinch_t = 0.0
	p.take_damage(5, Vector3(0.0, 0.0, 1.0))
	var hf_armed: bool = p._stun_t > 0.0 and p._flinch_t > 0.0 and p._iframe_t > 0.0
	var hf_dmg: int = p.hp_max - p.hp
	var hf_hp_after_one: int = p.hp
	p.take_damage(5, Vector3(0.0, 0.0, 1.0))   # inside i-frames → ignored
	Engine.time_scale = 1.0                      # hitstop left it low; restore
	_check("HF-hit-arms-stun-flinch-iframe", hf_armed and hf_dmg == 5,
		"hit: stun %.2f / flinch %.2f / iframe %.2f, took %d dmg" %
		[p._stun_t, p._flinch_t, p._iframe_t, hf_dmg])
	_check("HF-iframe-blocks-rehit", p.hp == hf_hp_after_one,
		"2nd hit inside i-frames: hp %d unchanged (was %d)" % [p.hp, hf_hp_after_one])

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
