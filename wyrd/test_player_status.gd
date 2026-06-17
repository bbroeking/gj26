extends SceneTree

# Spec 33a — player-side status framework evals.
#   godot --headless --path godot --script res://test_player_status.gd
#
# P1 — apply_status("burn") on the player adds the status; 6 ticks drain HP by 6.
# P2 — apply_status("snared") sets slow_product to 0.5.
# P3 — apply_status("bleed") ticks 4× over 4s = 4 total damage.
# P4 — Sunlit elite hitting the player applies Burn end-to-end.

const PlayerScene := preload("res://scenes/Player.tscn")
const CombatantScript := preload("res://scripts/combatant.gd")
const HitstopScript := preload("res://scripts/hitstop.gd")
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
	print("--- spec 33a player status evals ---")
	_install_autoloads()
	await _p1_burn_applies_and_ticks()
	await _p2_snared_slows_player()
	await _p3_bleed_total_damage()
	await _p4_sunlit_burns_player()
	await _p5_pip_list()
	await _p6_marked_suffix()
	await _p7_cleanse()
	print("--- player status evals: %d PASS, %d FAIL ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _install_autoloads() -> void:
	var hs: Node = HitstopScript.new()
	hs.name = "Hitstop"
	root.add_child(hs)
	var sx: Node = SfxScript.new()
	sx.name = "Sfx"
	root.add_child(sx)

func _make_player(host: Node) -> Node:
	var p: Node = PlayerScene.instantiate()
	host.add_child(p)
	return p

# ---- P1 — burn applies + ticks ----
func _p1_burn_applies_and_ticks() -> void:
	var host := Node3D.new()
	host.name = "P1Host"
	root.add_child(host)
	var p: Node = _make_player(host)
	await physics_frame
	await physics_frame
	var hp_before: int = p.hp
	p.apply_status("burn", 3.0, 1, 1.0, 0.5)
	var has_after_apply: bool = p.has_status("burn")
	# Fire 6 fixed-interval ticks manually so we don't wait 3 seconds of frames.
	for i in 6:
		p._tick_statuses(0.5)
	var hp_after: int = p.hp
	var lost: int = hp_before - hp_after
	_check("P1", has_after_apply and lost == 6 and not p.has_status("burn"),
		"hp %d → %d (lost %d, expect 6); status expired=%s"
		% [hp_before, hp_after, lost, str(not p.has_status("burn"))])

# ---- P2 — snared sets slow_product to 0.5 ----
func _p2_snared_slows_player() -> void:
	var host := Node3D.new()
	host.name = "P2Host"
	root.add_child(host)
	var p: Node = _make_player(host)
	await physics_frame
	await physics_frame
	var slow_before: float = p._status_slow_product()
	p.apply_status("snared", 1.5, 0, 0.5, 0.0)
	var slow_during: float = p._status_slow_product()
	_check("P2",
		absf(slow_before - 1.0) < 0.001 and absf(slow_during - 0.5) < 0.001,
		"slow_product unaffected=%.2f → snared=%.2f" % [slow_before, slow_during])

# ---- P3 — bleed: 4 ticks, 4 damage ----
func _p3_bleed_total_damage() -> void:
	var host := Node3D.new()
	host.name = "P3Host"
	root.add_child(host)
	var p: Node = _make_player(host)
	await physics_frame
	await physics_frame
	var hp_before: int = p.hp
	p.apply_status("bleed", 4.0, 1, 1.0, 1.0)
	for i in 4:
		p._tick_statuses(1.0)
	var lost: int = hp_before - p.hp
	_check("P3", lost == 4 and not p.has_status("bleed"),
		"hp -%d (expect 4); bleed expired=%s" % [lost, str(not p.has_status("bleed"))])

# ---- P4 — Sunlit elite hitting player applies Burn end-to-end ----
func _p4_sunlit_burns_player() -> void:
	var host := Node3D.new()
	host.name = "P4Host"
	root.add_child(host)
	var p: Node = _make_player(host)
	await physics_frame
	await physics_frame
	# Build a Sunlit elite right on top of the player so the melee distance
	# check (≤2.5m) passes.
	var elite: Node = CombatantScript.new()
	host.add_child(elite)
	elite.global_position = p.global_position
	elite.add_to_group("enemy")
	elite.cache_meshes()
	elite.setup(20, 0.4, 1.4)
	elite.apply_elite("sunlit")
	# Bypass the telegraph + AI state machine — trigger the burn pulse directly.
	# This is the same path the AI calls after take_damage lands on the player.
	elite._player = p
	elite._trigger_burn_pulse()
	_check("P4", p.has_status("burn"),
		"player has burn after Sunlit melee=%s" % str(p.has_status("burn")))

# ---- P7 — cleanse_status removes a movement lock (Quickroot Tonic path) ----
func _p7_cleanse() -> void:
	var host := Node3D.new()
	host.name = "P7Host"
	root.add_child(host)
	var p: Node = _make_player(host)
	await physics_frame
	await physics_frame
	p.apply_status("root", 3.0, 0, 0.0, 0.0)
	var had: bool = p.has_status("root")
	p.cleanse_status("root")
	_check("P7", had and not p.has_status("root"),
		"root applied=%s, cleansed=%s" % [str(had), str(not p.has_status("root"))])

# ---- P5 — pip list reflects active statuses + stores duration + drains ----
func _p5_pip_list() -> void:
	var host := Node3D.new()
	host.name = "P5Host"
	root.add_child(host)
	var p: Node = _make_player(host)
	await physics_frame
	await physics_frame
	p.apply_status("burn", 4.0, 1, 1.0, 0.5)
	var s = p.get_status("burn")
	var pips: Array = p._build_pip_list()
	var start_ok: bool = s != null and absf(float(s.duration) - 4.0) < 0.001 \
		and pips.size() == 1 and String(pips[0]["kind"]) == "burn" \
		and absf(float(pips[0]["frac"]) - 1.0) < 0.05
	p._tick_statuses(0.5)
	p._tick_statuses(0.5)
	var drained: Array = p._build_pip_list()
	var drain_ok: bool = drained.size() == 1 and float(drained[0]["frac"]) < 0.95
	_check("P5", start_ok and drain_ok,
		"pip start_ok=%s, drained frac<0.95=%s" % [str(start_ok), str(drain_ok)])

# ---- P6 — marked appears in the HP-bar suffix ----
func _p6_marked_suffix() -> void:
	var host := Node3D.new()
	host.name = "P6Host"
	root.add_child(host)
	var p: Node = _make_player(host)
	await physics_frame
	await physics_frame
	p.apply_status("marked", 5.0, 0, 1.0, 0.0)
	var suffix: String = p._status_suffix()
	_check("P6", "marked" in suffix, "suffix='%s' (expect contains 'marked')" % suffix)
