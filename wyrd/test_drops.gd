extends SceneTree

# Spec 27b — drop + pickup evals.
#   godot --headless --path godot --script res://test_drops.gd

const CombatantScript := preload("res://scripts/combatant.gd")
const HitstopScript := preload("res://scripts/hitstop.gd")
const PlayerScene := preload("res://scenes/Player.tscn")
const Items := preload("res://data/items.gd")
const Drops := preload("res://data/drops.gd")

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

func _count_named(host: Node, substr: String) -> int:
	var n := 0
	if String(host.name).contains(substr):
		n += 1
	for c in host.get_children():
		n += _count_named(c, substr)
	return n

func _kill_n(parent: Node3D, count: int, role: String) -> void:
	for i in count:
		var e: Node3D = CombatantScript.new()
		parent.add_child(e)
		(e as Node3D).global_position = Vector3(i * 2.0, 0, 0)
		e.cache_meshes()
		e.setup(5, 0.4, 1.4)
		e.role = role
		e.depth = 0
		e.take_damage(999, Vector3(0, 0, 1))

func _run() -> void:
	print("--- spec 27b drop evals ---")
	var hs: Node = HitstopScript.new()
	hs.name = "Hitstop"
	root.add_child(hs)
	var host := Node3D.new()
	root.add_child(host)
	await physics_frame
	CombatantScript.crit_enabled = false        # deterministic damage

	# D2 / Slice D2 — the First Knot reprise owns one small, deterministic
	# heirloom family. Pickup placement remains a combat/runtime concern; this
	# asserts only the pure seeded selection contract.
	var heirloom_a := Drops.select_first_knot_heirloom(44117)
	var heirloom_b := Drops.select_first_knot_heirloom(44117)
	var heirloom_ids := {}
	for seed in range(1, 65):
		var heirloom := Drops.select_first_knot_heirloom(seed)
		heirloom_ids[String(heirloom.get("kind_id", ""))] = true
	_check("D0", Drops.FIRST_KNOT_HEIRLOOM_KIND_IDS == ["shortbow", "leather_helm",
		"longbow", "leather_chest"]
		and heirloom_a == heirloom_b and String(heirloom_a.get("rarity", "")) == "unique"
		and heirloom_ids.keys().size() == 4
		and Drops.select_first_knot_heirloom(0).is_empty(),
		"reprise heirloom is seeded, unique, and constrained to its four authored bases")

	# D1 — treasure role drops ~100% of kills
	var treas := Node3D.new()
	treas.name = "TreasureHost"
	host.add_child(treas)
	_kill_n(treas, 20, "treasure")
	await physics_frame
	var n_t := _count_named(treas, "ItemPickup")
	_check("D1", n_t >= 15, "treasure: %d pickups from 20 kills (~20 expected)" % n_t)

	# D2 — shrine role drops ~25%
	var shr := Node3D.new()
	shr.name = "ShrineHost"
	host.add_child(shr)
	_kill_n(shr, 40, "shrine")
	await physics_frame
	var n_s := _count_named(shr, "ItemPickup")
	_check("D2", n_s >= 3 and n_s <= 22, "shrine: %d pickups from 40 kills (~10 expected)" % n_s)

	# D3 — Spec 32a: ItemPickup.spawn builds Beacon + Label children
	var pk: ItemPickup = ItemPickup.spawn(host,
		Items.make_item("shortbow", "magic"), Vector3.ZERO)
	var has_beacon: bool = pk.get_node_or_null("Beacon") != null
	var has_label: bool = pk.get_node_or_null("Label") != null
	_check("D3", has_beacon and has_label,
		"pickup has Beacon=%s Label=%s" % [str(has_beacon), str(has_label)])

	# D4 — Spec 32a: try_take(player) places into inventory + returns true
	var d4host := Node3D.new()
	root.add_child(d4host)
	var d4p: Node3D = PlayerScene.instantiate()
	d4host.add_child(d4p)
	await physics_frame
	await physics_frame
	var pk4: ItemPickup = ItemPickup.spawn(d4host,
		Items.make_item("leather_helm", "magic"), Vector3.ZERO)
	var took: bool = pk4.try_take(d4p)
	_check("D4", took and d4p.inventory.items.size() == 1,
		"try_take=%s inv=%d items" % [str(took), d4p.inventory.items.size()])

	# D5 — player overlaps a pickup; G adds it to inventory_stub
	# Wyrd — inventory is shared via the Game autoload across player
	# instances; reset it so D5 measures its own pickup, not D4's.
	var game_autoload: Node = root.get_node_or_null("Game")
	if game_autoload != null:
		game_autoload.inventory = Inventory.new()
	var phost := Node3D.new()
	host.add_child(phost)
	var p: Node3D = PlayerScene.instantiate()
	phost.add_child(p)
	await physics_frame
	await physics_frame                        # _ready done, scanner up
	# Spec 32a — spawn via the new seam at the player's position.
	var pk2: ItemPickup = ItemPickup.spawn(phost,
		Items.make_item("leather_helm", "rare"), p.global_position)
	for i in 6:
		await physics_frame                    # area_entered registers
	Input.action_press("grab")
	for i in 3:
		await physics_frame                # player's _physics_process consumes the press
	Input.action_release("grab")
	_check("D5", p.inventory.items.size() == 1,
		"player.inventory has %d item" % p.inventory.items.size())

	print("--- drop evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
