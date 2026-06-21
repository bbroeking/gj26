extends SceneTree

# B5 — skill DISPATCH evals: the `_try_skill(slot)` path the three gate
# suites don't touch (the frozen-game loadout bug lived here).
# Run: WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
#
# [dispatch]  slot 1 buffers the free Bow shot; slots 2-4 pay Focus, seed
#             their cooldown slot, and no-op on cooldown / short Focus.
# [loadout]   Game.set_loadout swaps slots 2-4; rebuild_skills re-seeds
#             cooldown keys 1..N (never a bare clear), and EVERY swapped
#             slot still consumes Focus when cast — the regression.
# [gates]     set_loadout rejects bad picks + Huntcraft-gated skills.

const PlayerScene := preload("res://scenes/Player.tscn")
const GameScript := preload("res://scripts/game.gd")

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
	print("--- skill dispatch check ---")
	# Godot 4.6 loads project autoloads even in --script mode — reuse the
	# real Game autoload if it's there, else mount one (gate-suite pattern).
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
	# _ready runs when the main loop iterates; give it two frames.
	await physics_frame
	await physics_frame
	game.persistence_enabled = false   # belt + braces: never touch the save
	_test_dispatch(p)
	_test_loadout_swap(game, p)
	_test_gates(game, p)
	_test_mastery_choice(game, p)
	_test_ward(p)
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

# ---- C8 — Heartwood Ward absorb fraction (drives the hotbar arc) ----
func _test_ward(p: Node3D) -> void:
	p.apply_ward(30, 5.0)
	_check("ward applied → frac 1.0", is_equal_approx(p.get_ward_frac(), 1.0),
		str(p.get_ward_frac()))
	p.set("_iframe_t", 0.0)
	p.take_damage(10, Vector3.ZERO)        # bark soaks 10 → ward 20
	_check("ward soaks → ward_hp 20, frac ~0.67",
		p.get_ward_hp() == 20 and absf(p.get_ward_frac() - 0.667) < 0.02,
		"hp=%d frac=%.2f" % [p.get_ward_hp(), p.get_ward_frac()])
	p.set("_iframe_t", 0.0)
	p.take_damage(50, Vector3.ZERO)        # blow exceeds the bark → ward breaks
	_check("ward breaks → ward_hp 0, frac 0",
		p.get_ward_hp() == 0 and p.get_ward_frac() == 0.0, "hp=%d" % p.get_ward_hp())

# ---- the _try_skill contract on the default loadout ----
func _test_dispatch(p: Node3D) -> void:
	print("[dispatch]")
	var names: Array = []
	for s in p.skills:
		names.append(String(s.name))
	_check("slot 1 is the Bow + default loadout fills 2-4",
		names.size() == 4 and names[0] == "BasicShot", str(names))
	var seeded := true
	for i in range(1, 5):
		seeded = seeded and p._skill_cooldowns.has(i) \
			and float(p._skill_cooldowns[i]) == 0.0
	_check("cooldown keys 1-4 seeded at 0", seeded, str(p._skill_cooldowns))
	var f0: float = p.focus
	p._try_skill(1)
	_check("slot 1 buffers a shot, costs nothing",
		float(p._fire_buffer) > 0.0 and float(p.focus) == f0
			and float(p._skill_cooldowns[1]) == 0.0,
		"buffer=%.2f focus %.1f→%.1f" % [float(p._fire_buffer), f0, float(p.focus)])
	var cost2: float = float(p.skills[1].cost)
	f0 = p.focus
	p._try_skill(2)
	_check("slot 2 pays Focus, seeds its CD, enters combat",
		absf((f0 - float(p.focus)) - cost2) < 0.01
			and float(p._skill_cooldowns[2]) > 0.0 and float(p._combat_t) > 0.0,
		"drop=%.1f vs cost %.1f cd=%.2f" % [f0 - float(p.focus), cost2,
			float(p._skill_cooldowns[2])])
	f0 = p.focus
	p._try_skill(2)
	_check("recast on cooldown is a no-op", float(p.focus) == f0,
		"focus %.1f→%.1f" % [f0, float(p.focus)])
	p.focus = 5.0
	p._try_skill(4)
	_check("short Focus is a no-op",
		float(p.focus) == 5.0 and float(p._skill_cooldowns[4]) == 0.0,
		"focus=%.1f cd=%.2f" % [float(p.focus), float(p._skill_cooldowns[4])])

# ---- the frozen-game regression: swap loadout, then cast every slot ----
func _test_loadout_swap(game: Node, p: Node3D) -> void:
	print("[loadout swap]")
	var ok: bool = game.set_loadout(["PiercingBolt", "RainOfThorns", "Thornburst"])
	var names: Array = []
	for s in p.skills:
		names.append(String(s.name))
	_check("swap to ungated wave-2 picks lands", ok and names == ["BasicShot",
		"PiercingBolt", "RainOfThorns", "Thornburst"], str(names))
	var reseeded: bool = p._skill_cooldowns.size() == 4
	for i in range(1, 5):
		reseeded = reseeded and p._skill_cooldowns.has(i) \
			and float(p._skill_cooldowns[i]) == 0.0
	_check("rebuild_skills re-seeds cooldown keys 1-4 (stale CD cleared)",
		reseeded, str(p._skill_cooldowns))
	for slot in range(2, 5):
		p.focus = p.focus_max
		var cost: float = float(p.skills[slot - 1].cost)
		var before: float = float(p.focus)
		p._try_skill(slot)
		_check("slot %d (%s) still consumes Focus after the swap"
				% [slot, String(p.skills[slot - 1].name)],
			absf((before - float(p.focus)) - cost) < 0.01
				and float(p._skill_cooldowns[slot]) > 0.0,
			"drop=%.1f vs cost %.1f cd=%.2f" % [before - float(p.focus), cost,
				float(p._skill_cooldowns[slot])])

# ---- set_loadout validation + the Huntcraft gates ----
func _test_gates(game: Node, p: Node3D) -> void:
	print("[loadout gates]")
	game.trades["wayfinding"]["lv"] = 1
	_check("rejects a gated pick at Huntcraft 1",
		not game.set_loadout(["PowerShot", "MultiShot", "HuntersMark"]))
	_check("rejects duplicates",
		not game.set_loadout(["PowerShot", "PowerShot", "MultiShot"]))
	_check("rejects a short list", not game.set_loadout(["PowerShot"]))
	_check("rejects a pick outside the pool",
		not game.set_loadout(["PowerShot", "MultiShot", "FoxFire"]))
	_check("failed swaps leave the loadout alone",
		String(p.skills[1].name) == "PiercingBolt", str(game.loadout))
	game.trades["wayfinding"]["lv"] = 9
	var ok: bool = game.set_loadout(["HuntersMark", "HeartwoodWard", "MercyShot"])
	p.focus = p.focus_max
	var before: float = float(p.focus)
	p._try_skill(2)
	_check("Huntcraft 9 opens the gated trio — and slot 2 still pays",
		ok and absf((before - float(p.focus)) - float(p.skills[1].cost)) < 0.01,
		"ok=%s drop=%.1f" % [str(ok), before - float(p.focus)])

# ---- ADR 0012 mastery: pick-one-of-N at a choice tier ----
func _test_mastery_choice(game: Node, _p: Node3D) -> void:
	print("[mastery choice]")
	game.chosen_perks = {}
	game.trades["wayfinding"]["lv"] = 4
	game.trades["wayfinding"]["xp"] = game.xp_for_level(4)
	var fired := {"lv": 0}     # dict, not bool — a lambda's captured bool won't escape
	game.mastery_choice_ready.connect(func(lv): fired.lv = lv, CONNECT_ONE_SHOT)
	game.award_xp("wayfinding", game.xp_for_level(5) - game.xp_for_level(4) + 1)
	_check("XP award crosses into level 5",
		int(game.trades["wayfinding"].lv) == 5, str(game.trades["wayfinding"]))
	_check("mastery_choice_ready fired for lv 5", int(fired.lv) == 5)
	_check("lv 5 is pending before a pick", game.pending_mastery_levels().has(5))
	_check("no lv-5 perk is active before a pick",
		not game.perk_active("", "steady_hands")
		and not game.perk_active("", "double_ore"))
	_check("choose_perk(steady_hands) takes", game.choose_perk("steady_hands"))
	_check("the chosen perk is active", game.perk_active("", "steady_hands"))
	_check("unchosen perks in the tier stay inactive",
		not game.perk_active("", "double_ore")
		and not game.perk_active("", "keen_eye")
		and not game.perk_active("", "curious_fingers"))
	_check("lv 5 no longer pending after the pick",
		not game.pending_mastery_levels().has(5))
	_check("a second pick at the same tier is rejected",
		not game.choose_perk("double_ore"))
	# Single-perk tiers (lv 12) auto-grant on threshold — no choice involved.
	game.trades["wayfinding"]["lv"] = 12
	_check("quick_nock auto-grants at lv 12", game.perk_active("", "quick_nock"))
	game.trades["wayfinding"]["lv"] = 11
	_check("quick_nock inactive at lv 11", not game.perk_active("", "quick_nock"))
