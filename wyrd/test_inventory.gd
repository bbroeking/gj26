extends SceneTree

# Spec 27c — Tetris inventory data evals. Pure data; UI is hand-tested.
#   godot --headless --path godot --script res://test_inventory.gd

const Items = preload("res://data/items.gd")

var _pass := 0
var _fail := 0

func _initialize() -> void:
	print("--- spec 27c inventory evals ---")
	_t_place_empty_slot()
	_t_collision_rejects()
	_t_out_of_bounds()
	_t_rotation_swaps_axes()
	_t_find_first_fit()
	_t_no_fit_when_full()
	_t_move_then_collision_snaps_back()
	_t_remove_clears()
	print("--- inventory evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _check(id: String, ok: bool, detail: String) -> void:
	if ok:
		_pass += 1
		print("  PASS  %s — %s" % [id, detail])
	else:
		_fail += 1
		print("  FAIL  %s — %s" % [id, detail])

func _ring() -> Dictionary:
	return Items.make_item("copper_ring", "normal")           # 1×1

func _helm() -> Dictionary:
	return Items.make_item("leather_helm", "normal")          # 2×2

func _bow() -> Dictionary:
	return Items.make_item("shortbow", "normal")              # 2×4

func _t_place_empty_slot() -> void:
	var inv := Inventory.new()
	var bow := _bow()
	var ok: bool =inv.try_place(bow, Vector2i(0, 0), false)
	_check("T1", ok and inv.cells[3][1] == bow,
		"placed 2×4 at (0,0); bottom-right cell points back to it")

func _t_collision_rejects() -> void:
	var inv := Inventory.new()
	inv.try_place(_bow(), Vector2i(0, 0), false)              # fills (0,0)-(1,3)
	var ring := _ring()
	var ok: bool =inv.try_place(ring, Vector2i(1, 2), false)      # overlaps
	_check("T2", not ok and inv.cells[2][1] != ring,
		"colliding place rejected and cell unchanged")

func _t_out_of_bounds() -> void:
	var inv := Inventory.new()
	var ok: bool =inv.try_place(_bow(), Vector2i(4, 0), false)    # 4+2=6 > 5 cols
	_check("T3", not ok, "out-of-bounds place rejected")

func _t_rotation_swaps_axes() -> void:
	var inv := Inventory.new()
	var bow := _bow()
	var ok: bool =inv.try_place(bow, Vector2i(0, 0), true)        # 4×2 footprint
	_check("T4", ok and inv.cells[1][3] == bow,
		"rotated 2×4 → 4×2: cell (3,1) holds the item")

func _t_find_first_fit() -> void:
	var inv := Inventory.new()
	inv.try_place(_bow(), Vector2i(0, 0), false)              # (0,0)-(1,3)
	var helm := _helm()
	var fit := inv.find_first_fit(helm)                       # next empty 2×2
	var ok: bool =not fit.is_empty() and fit.pos == Vector2i(2, 0)
	_check("T5", ok, "first fit for 2×2 after 2×4 at (0,0) = %s" % str(fit))

func _t_no_fit_when_full() -> void:
	var inv := Inventory.new()
	for x in Inventory.COLS:
		for y in inv.rows:
			inv.try_place(_ring(), Vector2i(x, y), false)
	var fit := inv.find_first_fit(_helm())
	_check("T6", fit.is_empty(),
		"no fit reported when grid full (placed %d rings)" % inv.items.size())

func _t_move_then_collision_snaps_back() -> void:
	var inv := Inventory.new()
	var bow := _bow()
	inv.try_place(bow, Vector2i(0, 0), false)
	var blocker := _helm()
	inv.try_place(blocker, Vector2i(2, 0), false)
	# Try moving the bow on top of the blocker — must snap back to (0,0).
	var ok: bool =inv.move(Vector2i(0, 0), Vector2i(2, 0), false)
	_check("T7", not ok and bow.pos == Vector2i(0, 0) and inv.cells[0][0] == bow,
		"colliding move snaps back; bow stays at (0,0)")

func _t_remove_clears() -> void:
	var inv := Inventory.new()
	var bow := _bow()
	inv.try_place(bow, Vector2i(0, 0), false)
	inv.remove(bow)
	var any := false
	for y in inv.rows:
		for x in Inventory.COLS:
			if inv.cells[y][x] != null:
				any = true
	_check("T8", not any and inv.items.is_empty(),
		"remove cleared all bow cells and the items list")
