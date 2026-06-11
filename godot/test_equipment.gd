extends SceneTree

# Spec 27d — equipment data evals + the changed signal + a full equip-
# from-inventory swap flow. UI drag/drop is hand-tested.
#   godot --headless --path godot --script res://test_equipment.gd

const Items = preload("res://data/items.gd")

var _pass := 0
var _fail := 0

func _initialize() -> void:
	print("--- spec 27d equipment evals ---")
	_t_can_equip_matches_category()
	_t_equip_into_empty_slot()
	_t_equip_returns_previous_on_swap()
	_t_wrong_slot_does_nothing()
	_t_unequip_returns_item_and_empties_slot()
	_t_changed_signal_fires()
	_t_full_swap_flow()
	print("--- equipment evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _check(id: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("  PASS  %s — %s" % [id, detail])
	else:
		_fail += 1
		print("  FAIL  %s — %s" % [id, detail])

func _t_can_equip_matches_category() -> void:
	var eq := Equipment.new()
	var bow := Items.make_item("shortbow", "normal")
	_check("Q1", eq.can_equip(bow), "shortbow (category=weapon) → can_equip true")

func _t_equip_into_empty_slot() -> void:
	var eq := Equipment.new()
	var bow := Items.make_item("shortbow", "normal")
	var prev = eq.equip(bow)
	_check("Q2", prev == null and eq.get_slot("weapon") == bow,
		"equip into empty: prev=null, slot holds the bow")

func _t_equip_returns_previous_on_swap() -> void:
	var eq := Equipment.new()
	var bow_a := Items.make_item("shortbow", "normal")
	var bow_b := Items.make_item("longbow", "normal")
	eq.equip(bow_a)
	var prev = eq.equip(bow_b)
	_check("Q3", prev == bow_a and eq.get_slot("weapon") == bow_b,
		"equipping over weapon → prev=bow_a, slot now holds bow_b")

func _t_wrong_slot_does_nothing() -> void:
	# Force a fake item with an unknown category — should reject via can_equip.
	var eq := Equipment.new()
	var fake := {"category": "amulet", "name": "Fake"}
	_check("Q4", not eq.can_equip(fake),
		"can_equip rejects unknown category 'amulet'")

func _t_unequip_returns_item_and_empties_slot() -> void:
	var eq := Equipment.new()
	var bow := Items.make_item("shortbow", "normal")
	eq.equip(bow)
	var got = eq.unequip("weapon")
	_check("Q5", got == bow and eq.get_slot("weapon") == null,
		"unequip returned the bow and emptied the slot")

func _t_changed_signal_fires() -> void:
	var eq := Equipment.new()
	var box := {"hits": 0}
	eq.changed.connect(func(): box.hits += 1)
	eq.equip(Items.make_item("copper_ring", "normal"))
	eq.unequip("ring")
	_check("Q6", int(box.hits) == 2,
		"changed fired %d times for equip + unequip (expect 2)" % box.hits)

func _t_full_swap_flow() -> void:
	# Inventory has a bow; equip it via the full flow; verify the slot has it
	# and the inventory cell is freed.
	var inv := Inventory.new()
	var eq := Equipment.new()
	var bow := Items.make_item("shortbow", "normal")
	inv.try_place(bow, Vector2i(0, 0), false)
	# Simulate "quick-equip from grid": remove + equip + handle displaced.
	inv.remove(bow)
	var prev = eq.equip(bow)
	if prev != null:
		inv.try_place(prev, Vector2i(0, 0), false)
	_check("Q7", eq.get_slot("weapon") == bow and inv.cells[0][0] == null,
		"full flow: bow equipped, source cell freed")
