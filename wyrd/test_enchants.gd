extends SceneTree

# Skills-on-items (enchants) evals. Covers the whole layer end to end:
#   [shape]      make_item carries enchants[]; capacity by category.
#   [source]     common charms always bindable; rare/unique gate on discovery.
#   [stat]       a stat charm sums into derived_stats like an affix.
#   [on_hit]     an on-hit charm rides EVERY shot (cache + a real arrow).
#   [skill]      a skill-grant charm makes a skill slottable; unbinding it
#                sanitizes the loadout (the dangling-grant exploit guard).
#   [gates]      slot capacity, category, availability, dup, reagent cost.
#   [persist]    discovered charms + bound enchants survive save/load.
#
# Run: WYRD_NO_SAVE=1 godot --headless --path . --script res://test_enchants.gd

const PlayerScene := preload("res://scenes/Player.tscn")
const GameScript := preload("res://scripts/game.gd")
const ItemsData := preload("res://data/items.gd")

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _initialize() -> void:
	_run()

func _run() -> void:
	print("--- enchant (skills-on-items) check ---")
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		game = GameScript.new()
		game.name = "Game"
		root.add_child(game)
	var host := Node3D.new()
	host.name = "Host"
	root.add_child(host)
	var p: Node3D = PlayerScene.instantiate()
	host.add_child(p)
	await physics_frame
	await physics_frame
	game.persistence_enabled = false

	_test_item_shape()
	_test_availability(game)
	_test_stat_enchant(game, p)
	_test_on_hit_enchant(game, p, host)
	_test_skill_grant(game, p)
	_test_gates(game)
	_test_factory_guard(game, p)
	_test_persistence()

	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

# Null every equip slot + re-derive, so each test starts from bare gear.
func _bare(game: Node) -> void:
	for s in game.equipment.slots.keys():
		game.equipment.slots[s] = null
	game.equipment.changed.emit()

# Top up reagents so binds never fail on affordability.
func _stock(game: Node) -> void:
	for r in ["glimmerdust", "emberglass", "dewthread"]:
		game.add_material(r, 20)

# ---- [shape] ----
func _test_item_shape() -> void:
	print("[shape]")
	var bow: Dictionary = ItemsData.make_item("shortbow", "normal")
	_check("make_item carries an empty enchants array",
		bow.has("enchants") and (bow.enchants as Array).is_empty(), str(bow.get("enchants")))
	_check("weapon holds 2 charm slots", ItemsData.enchant_slots("shortbow") == 2)
	_check("armour holds 1 charm slot", ItemsData.enchant_slots("leather_helm") == 1)
	_check("ring holds 1 charm slot", ItemsData.enchant_slots("copper_ring") == 1)
	_check("trade tools hold none", ItemsData.enchant_slots("bogiron_pickaxe") == 0)

# ---- [source] ----
func _test_availability(game: Node) -> void:
	print("[source]")
	_check("a common charm is always bindable", game.enchant_available("emberbind"))
	_check("a rare charm is locked until discovered",
		not game.enchant_available("deepmark"))
	game.discover_enchant("deepmark")
	_check("discovery unlocks the rare charm", game.enchant_available("deepmark"))
	_check("discovery is idempotent",
		(game.discovered_enchants as Array).count("deepmark") == 1)
	var known: Array = game.known_enchant_ids()
	_check("known list holds commons + the discovered rare",
		known.has("emberbind") and known.has("deepmark") and not known.has("wyrdspark"),
		str(known))

# ---- [stat] — sums into derived_stats like an affix ----
func _test_stat_enchant(game: Node, p: Node3D) -> void:
	print("[stat]")
	_bare(game)
	_stock(game)
	var ring: Dictionary = ItemsData.make_item("copper_ring", "normal")
	game.equipment.slots["ring"] = ring
	game.equipment.changed.emit()
	var crit_before: float = float(p.derived_stats.crit_chance)
	var dust_before: int = game.material_count("glimmerdust")
	var ok: bool = game.bind_enchant(ring, "keening")   # +0.06 crit_chance, costs glimmerdust:2
	_check("bind a stat charm onto the ring", ok)
	var crit_after: float = float(p.derived_stats.crit_chance)
	_check("Keening lifts crit by +0.06",
		absf((crit_after - crit_before) - 0.06) < 0.001,
		"%.3f → %.3f" % [crit_before, crit_after])
	_check("binding spent the reagents (glimmerdust -2)",
		game.material_count("glimmerdust") == dust_before - 2,
		"%d → %d" % [dust_before, game.material_count("glimmerdust")])

# ---- [on_hit] — rides every shot ----
func _test_on_hit_enchant(game: Node, p: Node3D, host: Node) -> void:
	print("[on_hit]")
	_bare(game)
	_stock(game)
	var bow: Dictionary = ItemsData.make_item("shortbow", "normal")
	game.equipment.slots["weapon"] = bow
	game.equipment.changed.emit()
	_check("no on-hit charms → no extra shot effects",
		(p.get_enchant_hit_effects() as Array).is_empty())
	var ok: bool = game.bind_enchant(bow, "emberbind")   # burn on hit
	_check("bind an on-hit charm onto the bow", ok)
	var fx: Array = p.get_enchant_hit_effects()
	_check("the bow now carries one on-hit effect (Burn)",
		fx.size() == 1 and String(fx[0].status_kind) == "burn", str(fx.size()))
	# Fire a real BasicShot and confirm the arrow inherited the burn.
	var pre: int = host.get_child_count()
	p.skills[0].fire(p)
	var arrow: Node = host.get_child(host.get_child_count() - 1) if host.get_child_count() > pre else null
	var carried := false
	if arrow != null and arrow.get("effects") != null:
		for e in arrow.effects:
			if String(e.status_kind) == "burn":
				carried = true
	_check("a loosed arrow carries the bound Burn", carried,
		"arrow=%s" % ("none" if arrow == null else str(arrow.get("effects"))))
	game.unbind_enchant(bow, 0)
	_check("unbinding clears the on-hit effect",
		(p.get_enchant_hit_effects() as Array).is_empty())

# ---- [skill] — grants a hotbar skill; unbinding sanitizes the loadout ----
func _test_skill_grant(game: Node, p: Node3D) -> void:
	print("[skill grant]")
	_bare(game)
	_stock(game)
	var bow: Dictionary = ItemsData.make_item("warbow", "normal")
	game.equipment.slots["weapon"] = bow
	game.equipment.changed.emit()
	game.discover_enchant("galebrand")           # rare skill-grant charm
	var ok: bool = game.bind_enchant(bow, "galebrand")
	_check("bind a skill-grant charm onto the bow", ok)
	_check("the weapon now GRANTS Galecall", game.granted_skills().has("Galecall"))
	_check("Galecall enters the slottable pool", game.available_skills().has("Galecall"))
	var slotted: bool = game.set_loadout(["Galecall", "PowerShot", "MultiShot"])
	var names: Array = []
	for s in p.skills:
		names.append(String(s.name))
	_check("Galecall slots into the hotbar", slotted and names.has("Galecall"), str(names))
	# Unbind the charm → the grant is gone → loadout must self-heal.
	game.unbind_enchant(bow, (bow.enchants as Array).find("galebrand"))
	_check("removing the charm revokes the grant",
		not game.granted_skills().has("Galecall"))
	_check("loadout self-heals — no dangling Galecall",
		not (game.loadout as Array).has("Galecall"), str(game.loadout))
	var names2: Array = []
	for s in p.skills:
		names2.append(String(s.name))
	_check("the rebuilt hotbar drops Galecall", not names2.has("Galecall"), str(names2))
	_check("the hotbar still holds 4 valid slots",
		p.skills.size() == 4 and String(p.skills[0].name) == "BasicShot", str(names2))

# ---- [gates] — capacity, replace, category, availability, dup ----
func _test_gates(game: Node) -> void:
	print("[gates]")
	_bare(game)
	_stock(game)
	var bow: Dictionary = ItemsData.make_item("shortbow", "normal")
	game.equipment.slots["weapon"] = bow
	game.equipment.changed.emit()
	_check("fill slot 1", game.bind_enchant(bow, "emberbind"))
	_check("fill slot 2", game.bind_enchant(bow, "keening"))
	_check("both slots filled", (bow.enchants as Array).size() == 2, str(bow.enchants))
	var full: Dictionary = game.can_bind_enchant(bow, "snarethread")
	_check("a third bind is refused (slots full)",
		not bool(full.ok) and "slot" in String(full.reason).to_lower(), str(full))
	_check("but a SWAP into slot 1 lands",
		game.bind_enchant(bow, "snarethread", 0)
			and String((bow.enchants as Array)[0]) == "snarethread",
		str(bow.enchants))
	_check("re-binding a charm already worn is refused",
		not bool(game.can_bind_enchant(bow, "snarethread").ok))
	# Category gate — an armour charm on a weapon.
	_check("an armour charm won't take on a bow",
		not bool(game.can_bind_enchant(bow, "heartoak").ok))
	# Availability gate — an undiscovered unique on a fresh piece (free slot).
	var lb: Dictionary = ItemsData.make_item("longbow", "normal")
	var avail: Dictionary = game.can_bind_enchant(lb, "wyrdspark")
	_check("an undiscovered charm is refused",
		not bool(avail.ok) and "puzzled" in String(avail.reason).to_lower(), str(avail))

# ---- [factory guard] — a loadout pick with no SKILL_FACTORY entry must keep
# the hotbar aligned (slot N → skills[N-1]), not silently shrink it ----
func _test_factory_guard(game: Node, p: Node3D) -> void:
	print("[factory guard]")
	# Inject a bad pick directly (bypasses set_loadout validation) and rebuild.
	# rebuild_skills logs an error and falls back to a Bow for the bad slot.
	game.loadout = ["NoSuchSkill", "PowerShot", "MultiShot"]
	p.rebuild_skills()
	_check("a missing factory entry keeps the hotbar at 4 slots",
		p.skills.size() == 4, str(p.skills.size()))
	_check("the unknown pick falls back to a Bow, later slots stay aligned",
		String(p.skills[1].name) == "BasicShot"
		and String(p.skills[2].name) == "PowerShot"
		and String(p.skills[3].name) == "MultiShot",
		"%s/%s/%s" % [p.skills[1].name, p.skills[2].name, p.skills[3].name])
	game.set_loadout(["PowerShot", "MultiShot", "BrambleSnare"])   # restore sanity

# ---- [persist] — round-trip discovered charms + bound enchants ----
func _test_persistence() -> void:
	print("[persist]")
	var path := "user://wyrd_test_enchants.json"
	var g1 = GameScript.new()
	g1._ready()                       # WYRD_NO_SAVE=1 → no real save touched
	g1.discover_enchant("steadyheart")
	var bow: Dictionary = ItemsData.make_item("shortbow", "normal")
	bow.enchants = ["emberbind", "keening"]
	g1.equipment.slots["weapon"] = bow
	SaveGame.save_to(path, g1)
	var g2 = GameScript.new()
	g2._ready()
	var res = SaveGame.load_from(path, g2)
	_check("save loads back clean", res == SaveGame.LOAD_RESULT.OK, str(res))
	_check("discovered charms survive the round-trip",
		(g2.discovered_enchants as Array).has("steadyheart"), str(g2.discovered_enchants))
	var w = g2.equipment.get_slot("weapon")
	_check("bound enchants survive the round-trip",
		w != null and (w.get("enchants", []) as Array) == ["emberbind", "keening"],
		str(null if w == null else w.get("enchants")))
	# Cleanup the throwaway files.
	for sfx in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + sfx):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + sfx))
