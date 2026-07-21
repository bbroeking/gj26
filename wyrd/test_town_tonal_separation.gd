extends SceneTree

# Spec 76 — Town owns one cloned 3D grade, with a stronger Web brightness
# correction. The mutation seam must not create or touch Canvas UI.

const TownEnvironmentScript = preload("res://scripts/town_environment.gd")

var passed := 0
var failed := 0


func check(label: String, ok: bool, detail = "") -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s %s" % [label, str(detail)])


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- Town tonal separation ---")
	var native_env := Environment.new()
	check("native grade applies", TownEnvironmentScript.apply_tonal_grade(
		native_env, false, ""))
	check("native grade restores bounded contrast",
		is_equal_approx(native_env.adjustment_brightness,
			TownEnvironmentScript.GRADE_BRIGHTNESS_NATIVE)
		and is_equal_approx(native_env.adjustment_contrast,
			TownEnvironmentScript.GRADE_CONTRAST)
		and native_env.adjustment_brightness > 0.0
		and native_env.adjustment_brightness < 1.0)
	check("native grade retains restrained color",
		is_equal_approx(native_env.adjustment_saturation,
			TownEnvironmentScript.GRADE_SATURATION)
		and native_env.adjustment_saturation >= 1.0
		and native_env.adjustment_saturation <= 1.2)

	var web_env := Environment.new()
	check("Web grade applies", TownEnvironmentScript.apply_tonal_grade(
		web_env, true, ""))
	check("Web compresses the additional Compatibility highlight lift",
		is_equal_approx(web_env.adjustment_brightness,
			TownEnvironmentScript.GRADE_BRIGHTNESS_WEB)
		and web_env.adjustment_brightness
			< TownEnvironmentScript.GRADE_BRIGHTNESS_NATIVE
		and is_equal_approx(web_env.adjustment_contrast,
			TownEnvironmentScript.GRADE_CONTRAST))

	var forced_env := Environment.new()
	check("dev force switch exercises the Web production value",
		TownEnvironmentScript.apply_tonal_grade(forced_env, false, "1")
		and is_equal_approx(forced_env.adjustment_brightness,
			TownEnvironmentScript.GRADE_BRIGHTNESS_WEB))

	var town_scene := load("res://scenes/Town.tscn") as PackedScene
	var native_town := town_scene.instantiate()
	var reference_town := town_scene.instantiate()
	var native_we := native_town.get_node("WorldEnvironment") as WorldEnvironment
	var reference_we := reference_town.get_node("WorldEnvironment") as WorldEnvironment
	var shared_env := native_we.environment
	var child_count := native_town.get_child_count()
	check("production Town grade seam succeeds",
		native_town.call("_apply_town_tonal_grade", ""))
	check("production Town clones its scene environment",
		native_we.environment != shared_env
		and reference_we.environment == shared_env)
	check("production seam adds no Canvas overlay",
		native_town.get_child_count() == child_count)
	check("production native value matches the centralized contract",
		is_equal_approx(native_we.environment.adjustment_brightness,
			TownEnvironmentScript.GRADE_BRIGHTNESS_NATIVE))
	native_town.free()
	reference_town.free()

	print("--- Town tonal separation: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
