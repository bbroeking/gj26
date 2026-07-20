extends SceneTree

const Rules := preload("res://scripts/wayweaver_thread_rules.gd")

var _pass := 0
var _fail := 0

func _initialize() -> void:
	print("--- Wayweaver thread rules check ---")
	_test_mapping()
	_test_state_machine()
	_test_invalidations()
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)

func _presence(room_id: String = "7", eligible: bool = true, layer: int = 1) -> Dictionary:
	return {"run_epoch": 4, "layer": layer, "room_id": room_id, "eligible": eligible}

func _test_mapping() -> void:
	var expected := {
		"PowerShot": "pierce", "PiercingBolt": "pierce", "MercyShot": "pierce", "Wyrdvolley": "pierce",
		"MultiShot": "fan", "RainOfThorns": "fan", "DrivingVolley": "fan", "Galecall": "fan",
		"BrambleSnare": "root", "Thornburst": "root", "HeartwoodWard": "ward",
		"HuntersMark": "mark", "Threadstep": "mark", "WayfindersMark": "mark",
	}
	var complete := true
	for skill_id in expected:
		complete = complete and Rules.identity_for_skill(skill_id) == expected[skill_id]
	_check("all locked Skills map to their identity", complete)
	_check("unmapped Skill cannot arm", Rules.identity_for_skill("BasicShot") == "")
	var fan := Rules.effect_for_identity("fan")
	_check("fan descriptor is nonrecursive and strips inherited combat modifiers",
		int(fan.arrow_count) == 2 and fan.angles_degrees == [-12.0, 12.0]
		and is_equal_approx(float(fan.damage_multiplier), 0.25) and not bool(fan.can_crit)
		and not bool(fan.can_pierce) and not bool(fan.can_execute) and not bool(fan.carry_effects)
		and not bool(fan.carry_enchants) and not bool(fan.can_recurse), str(fan))
	var root := Rules.effect_for_identity("root")
	var ward := Rules.effect_for_identity("ward")
	var mark := Rules.effect_for_identity("mark")
	_check("root ward and mark descriptors preserve their locked timing/immunity contract",
		is_equal_approx(float(root.duration_seconds), 0.75) and bool(root.first_hit_only)
		and bool(root.respects_boss_immunity) and bool(root.respects_elite_immunity)
		and int(ward.amount) == 8 and is_equal_approx(float(ward.duration_seconds), 4.0)
		and bool(ward.max_preserving) and is_equal_approx(float(mark.duration_seconds), 2.0)
		and bool(mark.after_basic_damage), str({"root": root, "ward": ward, "mark": mark}))

func _test_state_machine() -> void:
	var rules := Rules.new()
	var room := _presence()
	_check("failed Focus never arms", not bool(rules.arm_after_focus(room, "PowerShot", false, true).ok)
		and rules.state_for(room).state == Rules.FRESH)
	_check("wrong room cannot arm", not bool(rules.arm_after_focus(_presence("", false), "PowerShot", true, true).ok))
	_check("weapon must be equipped to arm", not bool(rules.arm_after_focus(room, "PowerShot", true, false).ok))
	var armed := rules.arm_after_focus(room, "PowerShot", true, true)
	_check("first successful Focus arms exact identity", bool(armed.ok) and armed.state == Rules.ARMED
		and armed.identity == "pierce", str(armed))
	_check("later Focus cannot overwrite armed identity", not bool(rules.arm_after_focus(
		room, "MultiShot", true, true).ok) and rules.state_for(room).identity == "pierce")
	_check("non-release inputs do not spend", not bool(rules.consume_basic_release(room, false, true).ok)
		and rules.state_for(room).state == Rules.ARMED)
	var echo := rules.consume_basic_release(room, true, true)
	_check("real Basic release emits echo and spends even before any hit report", bool(echo.ok)
		and echo.identity == "pierce" and int((echo.effect as Dictionary).additional_pierces) == 1
		and rules.state_for(room).state == Rules.SPENT, str(echo))
	_check("spent room cannot rearm or recurse", not bool(rules.arm_after_focus(room, "MultiShot", true, true).ok)
		and not bool(rules.consume_basic_release(room, true, true).ok))
	var missing_at_release := Rules.new()
	missing_at_release.arm_after_focus(room, "HeartwoodWard", true, true)
	_check("weapon loss at release burns without an echo", not bool(missing_at_release.consume_basic_release(
		room, true, false).ok) and missing_at_release.state_for(room).state == Rules.SPENT)
	var host_gated := Rules.new()
	_check("host-accepted Skills do not arm before their matching acceptance", not bool(host_gated.arm_after_focus(
		room, "Threadstep", true, true, false).ok) and bool(host_gated.arm_after_focus(
		room, "Threadstep", true, true, true).ok))

func _test_invalidations() -> void:
	var rules := Rules.new()
	var a := _presence("1")
	var b := _presence("2")
	rules.arm_after_focus(a, "BrambleSnare", true, true)
	rules.observe_presence(b)
	_check("room exit burns armed room", rules.state_for(a).state == Rules.SPENT)
	rules.arm_after_focus(b, "HuntersMark", true, true)
	_check("weapon-loss notification burns armed thread", bool(rules.on_weapon_lost().ok)
		and rules.state_for(b).state == Rules.SPENT)
	var reset := Rules.new()
	reset.arm_after_focus(a, "MercyShot", true, true)
	var invalidated := reset.invalidate("reconnect")
	_check("reconnect/death style invalidation burns then clears transient memory",
		int(invalidated.burned) == 1 and reset.state_for(a).state == Rules.FRESH)
	var layer_change := Rules.new()
	layer_change.arm_after_focus(a, "MercyShot", true, true)
	layer_change.observe_presence(_presence("1", true, 2))
	_check("layer changes burn prior armed state", layer_change.state_for(a).state == Rules.SPENT)

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % name)
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])
