extends SceneTree

# Regression: a used World interactable may remain a valid Object for one
# deferred frame after its scene leaves the tree. Release telemetry must not
# call tree-only path/transform accessors during that window.

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var game := root.get_node_or_null("Game")
	var detached := Node3D.new()
	detached.name = "RetiredWaystone"
	root.add_child(detached)
	root.remove_child(detached)
	var snapshot: Dictionary = game._d7_interactable_snapshot(detached) \
		if game != null else {}
	var passed := not bool(snapshot.get("valid", true)) \
		and bool(snapshot.get("detached", false)) \
		and String(snapshot.get("name", "")) == "RetiredWaystone"
	print("--- detached telemetry: %s ---" % ("1 PASS, 0 FAIL" if passed else "0 PASS, 1 FAIL"))
	detached.free()
	quit(0 if passed else 1)
