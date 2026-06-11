extends SceneTree

# Spec 29 — typed-room contract evals.
#   godot --headless --path godot --script res://test_typed_rooms.gd
#
# T1 — across 10 runs, every dungeon contains 1 entrance, 1 boss, ≥1 rest,
#      ≥1 treasure, ≥1 shrine.
# T2 — the rest room is adjacent to the boss room (graph distance ≤1).
# T3 — Chest.interact() rolls ≥1 item via Drops.roll_drop and spawns pickups.
# T4 — Shrine.offered_buffs returns 3 distinct buffs; apply() writes to
#      player.derived_stats via apply_shrine_buff.
# T5 — Hearth.interact() restores HP to hp_max + Checkpoint slot has the room.

const DungeonGen := preload("res://scripts/dungeon_gen.gd")
const ChestScene := preload("res://scenes/Chest.tscn")
const ShrineScene := preload("res://scenes/Shrine.tscn")
const HearthScene := preload("res://scenes/Hearth.tscn")
const PlayerScene := preload("res://scenes/Player.tscn")
const HitstopScript := preload("res://scripts/hitstop.gd")
const CheckpointScript := preload("res://scripts/checkpoint.gd")
const SfxScript := preload("res://scripts/sfx.gd")

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

func _run() -> void:
	print("--- spec 29 typed-room contract evals ---")
	# Autoloads aren't wired in SceneTree scripts; install the ones the
	# interactables touch so play/save don't no-op into nulls.
	_install_autoloads()
	_t1_role_distribution()
	_t2_rest_adjacent_to_boss()
	await _t3_chest_drops()
	await _t4_shrine_buff()
	await _t5_hearth_heal_and_checkpoint()
	await _t6_interactable_base_contract()
	print("--- typed-room evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _install_autoloads() -> void:
	var hs: Node = HitstopScript.new()
	hs.name = "Hitstop"
	root.add_child(hs)
	var cp: Node = CheckpointScript.new()
	cp.name = "Checkpoint"
	root.add_child(cp)
	var sx: Node = SfxScript.new()
	sx.name = "Sfx"
	root.add_child(sx)

# ---- T1 — role distribution honors MIN_COMBAT_ROOMS priority ladder ----
# Every run: entrance, boss, ≥MIN_COMBAT_ROOMS combat. Typed rooms then fill
# in by priority (rest > treasure > shrine) as room count permits.
func _t1_role_distribution() -> void:
	var bad := 0
	for run in 10:
		var layout: Dictionary = DungeonGen.generate(1000 + run)
		var counts := {"entrance": 0, "boss": 0, "rest": 0,
			"treasure": 0, "shrine": 0, "combat": 0, "setpiece": 0}
		for r in layout.rooms:
			var role: String = String(r.get("role", ""))
			if counts.has(role):
				counts[role] += 1
		var total: int = (layout.rooms as Array).size()
		# fixed_count + MIN_COMBAT_ROOMS = 4 (entrance + boss + 2 combat).
		# slots_left = total - 4 → rest (≥5), treasure (≥6), shrine (≥7).
		# Setpieces eat a combat slot but the floor still holds.
		var combat_like: int = counts.combat + counts.setpiece
		var ok: bool = counts.entrance == 1 and counts.boss == 1
		if total >= 4:
			ok = ok and combat_like >= 2
		if total >= 5:
			ok = ok and counts.rest >= 1
		if total >= 6:
			ok = ok and counts.treasure >= 1
		if total >= 7:
			ok = ok and counts.shrine >= 1
		if not ok:
			bad += 1
			print("    run %d rooms=%d counts=%s" % [run, total, str(counts)])
	_check("T1", bad == 0,
		"role distribution across 10 runs (priority ladder): %d violations" % bad)

# ---- T2 — when a rest room exists, it sits next to the boss on the graph.
# Small dungeons (< 5 rooms) may not produce a rest room at all (priority
# ladder); those runs are skipped from the adjacency check.
func _t2_rest_adjacent_to_boss() -> void:
	var bad := 0
	var checked := 0
	for run in 10:
		var layout: Dictionary = DungeonGen.generate(2000 + run)
		var rooms: Array = layout.rooms
		var edges: Array = layout.get("room_edges", [])
		var boss_idx := -1
		var rest_idx := -1
		for i in rooms.size():
			match String(rooms[i].get("role", "")):
				"boss": boss_idx = i
				"rest": rest_idx = i
		if rest_idx < 0:
			continue       # no rest room this run (small dungeon) — skip
		checked += 1
		if boss_idx < 0:
			bad += 1
			continue
		var adj := false
		for e in edges:
			if (int(e[0]) == boss_idx and int(e[1]) == rest_idx) \
			or (int(e[1]) == boss_idx and int(e[0]) == rest_idx):
				adj = true
				break
		if not adj:
			bad += 1
	_check("T2", bad == 0,
		"rest adjacent to boss across 10 runs: %d/%d adjacency violations"
		% [bad, checked])

# ---- T3 — Chest.interact() drops items ----
func _t3_chest_drops() -> void:
	var host := Node3D.new()
	host.name = "T3Host"
	root.add_child(host)
	await physics_frame
	var c: Node3D = ChestScene.instantiate()
	host.add_child(c)
	c.depth = 5
	await physics_frame
	var pile: Array = c.interact(null)
	var n := _count_named(host, "ItemPickup")
	_check("T3", pile.size() >= 1 and n >= 1,
		"chest dropped %d items (pickups in scene: %d)" % [pile.size(), n])

# ---- T4 — Shrine.offered_buffs + apply() ----
func _t4_shrine_buff() -> void:
	var host := Node3D.new()
	host.name = "T4Host"
	root.add_child(host)
	await physics_frame
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	await physics_frame
	await physics_frame
	var s: Node3D = ShrineScene.instantiate()
	host.add_child(s)
	s.seed_value = 12345
	await physics_frame
	var offered: Array = s.offered_buffs()
	# Deterministic: same seed → same 3 buffs.
	var s2: Node3D = ShrineScene.instantiate()
	host.add_child(s2)
	s2.seed_value = 12345
	await physics_frame
	var offered2: Array = s2.offered_buffs()
	var deterministic := offered.size() == offered2.size()
	if deterministic:
		for i in offered.size():
			if String(offered[i].id) != String(offered2[i].id):
				deterministic = false
				break
	var distinct: bool = offered.size() == 3
	if distinct:
		var ids := {}
		for b in offered:
			if ids.has(b.id):
				distinct = false
				break
			ids[b.id] = true
	# Apply the first buff and read back the derived stat.
	var picked: Dictionary = offered[0]
	var hp_before: int = int(p.derived_stats.hp_max)
	var dmg_before: int = int(p.derived_stats.damage)
	var crit_before: float = float(p.derived_stats.crit_chance)
	s.apply(p, picked)
	await physics_frame
	var applied := false
	match String(picked.stat):
		"hp":          applied = int(p.derived_stats.hp_max) > hp_before
		"damage":      applied = int(p.derived_stats.damage) > dmg_before
		"crit_chance": applied = float(p.derived_stats.crit_chance) > crit_before
		_:             applied = p.shrine_buffs.get(picked.stat, 0) != 0
	_check("T4", distinct and deterministic and applied and s.is_used(),
		"offered 3 distinct=%s deterministic=%s applied=%s consumed=%s" % [
			str(distinct), str(deterministic), str(applied), str(s.is_used()),
		])

# ---- T5 — Hearth heals + writes checkpoint ----
func _t5_hearth_heal_and_checkpoint() -> void:
	var host := Node3D.new()
	host.name = "T5Host"
	root.add_child(host)
	await physics_frame
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	await physics_frame
	await physics_frame
	# Drain HP so the heal is observable.
	p.hp = max(1, p.hp_max - 10)
	var hp_before: int = p.hp
	var h: Node3D = HearthScene.instantiate()
	host.add_child(h)
	h.room_id = 7
	h.global_position = p.global_position + Vector3(1.0, 0.0, 0.0)
	await physics_frame
	var slot: Dictionary = h.interact(p)
	await physics_frame
	var healed: bool = p.hp == p.hp_max
	var saved: bool = not slot.is_empty() and int(slot.get("room_id", -1)) == 7
	_check("T5", healed and saved,
		"hp %d→%d (max %d) healed=%s; checkpoint room_id=%s saved=%s" % [
			hp_before, p.hp, p.hp_max, str(healed),
			str(slot.get("room_id", "(none)")), str(saved),
		])

# ---- T6 — spec 32d: Interactable base contract ----
# After the deepening, Chest/Shrine/Hearth all extend `Interactable`. The
# base owns the universal setup: INTERACT_LAYER + "interactable" group +
# CollisionShape3D child + PromptLabel Label3D child. T6 verifies each of
# the three subclasses inherits this contract.
func _t6_interactable_base_contract() -> void:
	var host := Node3D.new()
	host.name = "T6Host"
	root.add_child(host)
	await physics_frame
	var c: Node3D = ChestScene.instantiate()
	var s: Node3D = ShrineScene.instantiate()
	var h: Node3D = HearthScene.instantiate()
	host.add_child(c)
	host.add_child(s)
	host.add_child(h)
	await physics_frame
	var checks: Array = []
	for node in [c, s, h]:
		var is_interactable: bool = node is Interactable
		var in_group: bool = node.is_in_group("interactable")
		var on_layer: bool = (node as Area3D).collision_layer == Interactable.INTERACT_LAYER
		var has_prompt: bool = node.get_node_or_null("PromptLabel") != null
		# CollisionShape3D is added as a generic child (no name set in base).
		var has_collision := false
		for child in node.get_children():
			if child is CollisionShape3D:
				has_collision = true
				break
		checks.append(is_interactable and in_group and on_layer and has_prompt and has_collision)
	var all_ok: bool = checks.size() == 3 and checks[0] and checks[1] and checks[2]
	_check("T6", all_ok,
		"Chest/Shrine/Hearth all extend Interactable: %s/%s/%s"
		% [str(checks[0]), str(checks[1]), str(checks[2])])

func _count_named(host: Node, substr: String) -> int:
	var n := 0
	if String(host.name).contains(substr):
		n += 1
	for c in host.get_children():
		n += _count_named(c, substr)
	return n
