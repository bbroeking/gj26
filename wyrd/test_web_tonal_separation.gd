extends SceneTree

# Spec 67 — Compatibility rendering receives one bounded 3D environment grade;
# native remains a strict no-op and Canvas UI never enters this seam.

const LayoutLoaderScript = preload("res://scripts/layout_loader.gd")

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
	print("--- Web tonal separation ---")
	var native_env := Environment.new()
	native_env.adjustment_enabled = true
	native_env.adjustment_brightness = 1.0
	native_env.adjustment_contrast = 1.05
	var native_applied: bool = LayoutLoaderScript.apply_web_tonal_grade(
		native_env, false, "")
	check("native renderer is a strict grading no-op",
		not native_applied and is_equal_approx(native_env.adjustment_brightness, 1.0)
			and is_equal_approx(native_env.adjustment_contrast, 1.05))

	var web_env := Environment.new()
	web_env.adjustment_enabled = true
	web_env.adjustment_brightness = 1.0
	web_env.adjustment_contrast = 1.05
	var web_applied: bool = LayoutLoaderScript.apply_web_tonal_grade(
		web_env, true, "")
	check("Web renderer receives the centralized tonal grade",
		web_applied
			and is_equal_approx(web_env.adjustment_brightness,
				LayoutLoaderScript.WEB_GRADE_BRIGHTNESS)
			and is_equal_approx(web_env.adjustment_contrast,
				LayoutLoaderScript.WEB_GRADE_CONTRAST))
	check("grade compresses highlights without inversion",
		LayoutLoaderScript.WEB_GRADE_BRIGHTNESS > 0.0
			and LayoutLoaderScript.WEB_GRADE_BRIGHTNESS < 1.0
			and LayoutLoaderScript.WEB_GRADE_CONTRAST >= 1.0)

	var forced_env := Environment.new()
	var forced_applied: bool = LayoutLoaderScript.apply_web_tonal_grade(
		forced_env, false, "1")
	check("test/dev force switch exercises the production mutation seam",
		forced_applied
			and is_equal_approx(forced_env.adjustment_brightness,
				LayoutLoaderScript.WEB_GRADE_BRIGHTNESS))

	print("--- Web tonal separation: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
