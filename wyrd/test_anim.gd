extends SceneTree

# Spec 11 — probe the rigged GLBs for AnimationPlayer + clip names.
# Run: godot --headless --path godot --script res://test_anim.gd

const RIGGED := [
	"res://models/enemy_skeleton_v1_rigged.glb",
	"res://models/enemy_ghost_v1_rigged.glb",
	"res://models/enemy_hedge_sprite_v1_rigged.glb",
	"res://models/hedgemother_v2_rigged.glb",
]

func _init() -> void:
	for path in RIGGED:
		var packed: PackedScene = load(path)
		if packed == null:
			print("%s — FAILED to load" % path)
			continue
		var inst: Node = packed.instantiate()
		var ap := _find_anim_player(inst)
		if ap == null:
			print("%s — no AnimationPlayer" % path.get_file())
		else:
			print("%s — clips: %s" % [path.get_file(), str(ap.get_animation_list())])
		inst.free()
	quit()

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var found := _find_anim_player(c)
		if found != null:
			return found
	return null
