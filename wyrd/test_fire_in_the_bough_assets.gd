extends SceneTree

# Focused, import-level asset contract for Fire in the Bough.  Gameplay owns
# encounter behavior; this test deliberately locks only shippable model truth.

const GIANT := "res://models/boss_hearth_giant_v1.glb"
const STATIC := [
	"res://models/prop_hollow_link_chain_v1.glb",
	"res://models/prop_braided_link_chain_v1.glb",
	"res://models/prop_knot_link_chain_v1.glb",
	"res://models/building_ember_kiln_v1.glb",
	"res://models/building_threefold_loom_foundation_v1.glb",
	"res://models/biome_ashen_bough_landing_v1.glb",
	"res://models/biome_ashen_bough_roots_v1.glb",
]
const CLIPS := ["HearthGiant_Idle", "HearthGiant_Walk", "HearthGiant_Attack", "HearthGiant_Hit", "HearthGiant_HeatShield", "HearthGiant_ChainReact", "HearthGiant_Kneel"]
const ICONS := [
	"res://assets/ui/components/ash_mark.png",
	"res://assets/ui/components/cinder_waymark.png",
	"res://assets/ui/components/ember_mark.png",
	"res://assets/ui/components/furnace_mark.png",
	"res://assets/ui/components/soot_track.png",
	"res://assets/ui/components/ember_folio.png",
	"res://assets/ui/components/cinder_binding.png",
	"res://assets/ui/items/emberleaf_ink.png",
	"res://assets/ui/items/wyrm_scale.png",
	"res://assets/ui/items/starheart_alloy.png",
	"res://assets/ui/icons/skill_threadstep.png",
	"res://assets/ui/icons/pack_reader.png",
	"res://assets/ui/affixes/cinderbound.png",
	"res://assets/ui/items/ember_root_rune.png",
	"res://assets/ui/items/present_thread.png",
	"res://assets/ui/items/embersage.png",
]

var passed := 0
var failed := 0

func check(label: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		print("  ✗ %s" % label)

func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation(child)
		if found != null:
			return found
	return null

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("--- Fire in the Bough asset contract ---")
	check("all authored Fire GLBs exist", STATIC.all(func(path): return FileAccess.file_exists(path)) and FileAccess.file_exists(GIANT))
	check("all painted Fire icons exist", ICONS.all(func(path): return FileAccess.file_exists(path)))
	check("all painted Fire icons import as textures", ICONS.all(func(path): return load(path) is Texture2D))
	var packed := load(GIANT) as PackedScene
	check("Hearth Giant imports as a packed scene", packed != null)
	if packed != null:
		var instance: Node = packed.instantiate()
		var skeletons := 0
		var skinned_meshes := 0
		var stack: Array[Node] = [instance]
		while not stack.is_empty():
			var node: Node = stack.pop_back() as Node
			if node is Skeleton3D:
				skeletons += 1
			if node is MeshInstance3D and (node as MeshInstance3D).skin != null:
				skinned_meshes += 1
			for child in node.get_children():
				stack.append(child)
		var animation: AnimationPlayer = _find_animation(instance)
		check("Hearth Giant ships exactly one skeleton and skinned mesh", skeletons == 1 and skinned_meshes == 1)
		check("Hearth Giant carries every encounter clip", animation != null and CLIPS.all(func(clip): return animation.get_animation_list().has(clip)))
		instance.free()
	for path in STATIC:
		var prop := load(path) as PackedScene
		check("%s imports" % path.get_file(), prop != null)
		if prop != null:
			var inst: Node = prop.instantiate()
			check("%s is static (no accidental animation player)" % path.get_file(), _find_animation(inst) == null)
			inst.free()
	print("--- Fire assets: %d PASS, %d FAIL ---" % [passed, failed])
	quit(1 if failed > 0 else 0)
