extends SceneTree

# Boot smoke — every GDScript under res://scripts/ must compile (load() != null)
# and the two top scenes must load. The gameplay suites never instantiate the
# Town/World scenes, so a parse error in town.gd (or any boot-path script) ships
# green while making the game unlaunchable. This is the guard for that class of
# bug. See memory feedback_godot_boot_smoke_blind_spot.
# Run: WYRD_NO_SAVE=1 godot --headless --path . --script res://test_boot_smoke.gd

var _pass := 0
var _fail := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
		print("  ✗ %s %s" % [name, detail])

func _initialize() -> void:
	print("--- boot smoke: parse every script + load top scenes ---")
	var scripts: Array = []
	_collect_gd("res://scripts", scripts)
	scripts.sort()
	for path in scripts:
		var res = load(path)
		# load() returns a NON-null GDScript even when it failed to parse (it
		# logs the error but hands back an invalid object), so != null is not
		# enough. can_instantiate() is the real signal: a compiled script reports
		# true (even autoload singletons in use), a parse-failed one reports
		# false. (reload() would false-positive on in-use autoloads → ERR_BUSY.)
		var ok: bool = res != null
		if ok and res is GDScript:
			ok = (res as GDScript).can_instantiate()
		_check(path, ok, "(failed to compile — parse/compile error)")
	# Top scenes — load + instantiate, so a broken attached script surfaces.
	for scene in ["res://scenes/Town.tscn", "res://scenes/World.tscn"]:
		if ResourceLoader.exists(scene):
			var ps = load(scene)
			_check(scene, ps != null and ps is PackedScene and ps.can_instantiate(),
				"(scene failed to load / instantiate)")
	print("--- boot smoke: %d PASS, %d FAIL (%d scripts) ---" % [
		_pass, _fail, scripts.size()])
	quit(1 if _fail > 0 else 0)

# Recursively gather every .gd path under `dir`.
func _collect_gd(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var full := dir + "/" + name
		if d.current_is_dir():
			if not name.begins_with("."):
				_collect_gd(full, out)
		elif name.ends_with(".gd"):
			out.append(full)
		name = d.get_next()
	d.list_dir_end()
