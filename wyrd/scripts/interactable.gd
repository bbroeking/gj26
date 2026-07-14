class_name Interactable
extends Area3D

# Spec 32d — explicit base class for "anything press-E-able." Owns the
# common boilerplate (collision_layer + group + collision sphere + prompt
# Label3D) that Chest / Shrine / Hearth used to duplicate. Subclasses
# override virtual hooks for their flavour:
#
#   get_prompt_text() / get_prompt_color()  — the floating "[E] X" label
#   get_collision_radius() / get_collision_offset() / get_prompt_position()
#                                            — tune per-model placement
#   _ready_interactable()                    — subclass setup (GLB + glow)
#   interact(player)                         — what pressing E does (abstract)
#   is_used()                                — true → prompt gated off
#
# Player-side: InteractScanner Area3D picks us up on INTERACT_LAYER, then
# `_refresh_interact_prompt` finds the nearest and calls `show_prompt(true)`.

const INTERACT_LAYER := 32

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = INTERACT_LAYER
	collision_mask = 0
	# Detection sphere — sized + offset by subclass overrides.
	var sh := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = get_collision_radius()
	sh.shape = sp
	sh.position = get_collision_offset()
	add_child(sh)
	# Floating prompt — built by base, parameterised by subclass.
	# Wyrd — playtest: the old 48px prompt washed out against the world.
	# Bigger, heavier outline, and a soft bob so the eye finds it.
	# Slice B / art pass — a parchment plate + sepia ink border behind the
	# prompt so it reads as a hand-cut tooltip card, not a plain floating blob.
	# Frame (slightly larger ink quad) sits 2mm behind the fill quad; the
	# visible border is the ink peeking around all four edges.
	# Billboarded + no-depth like the label; both resized in _size_prompt_plate.
	var frame := MeshInstance3D.new()
	frame.name = "PromptFrame"
	var fmesh := QuadMesh.new()
	fmesh.size = Vector2(1.0, 0.34)            # provisional — resized below
	frame.mesh = fmesh
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.10, 0.07, 0.04, 0.96)   # sepia ink edge
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fmat.no_depth_test = true
	fmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	frame.material_override = fmat
	frame.position = get_prompt_position() - Vector3(0.0, 0.0, 0.002)
	frame.visible = false
	add_child(frame)
	var plate := MeshInstance3D.new()
	plate.name = "PromptPlate"
	var pmesh := QuadMesh.new()
	pmesh.size = Vector2(1.0, 0.34)            # provisional — resized to text below
	plate.mesh = pmesh
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.18, 0.13, 0.08, 0.92)   # warm amber parchment scrap
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pmat.no_depth_test = true
	pmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	plate.material_override = pmat
	plate.position = get_prompt_position() + Vector3(0.0, 0.0, 0.002)
	plate.visible = false
	add_child(plate)
	var lbl := Label3D.new()
	lbl.name = "PromptLabel"
	lbl.text = get_prompt_text()
	lbl.modulate = get_prompt_color()
	# Storybook typeface (IM Fell) so the prompt reads as the game's voice, not
	# debug text. It now sits on a parchment plate (PromptPlate above).
	var pfont := WyrdUi.font_header()
	if pfont != null:
		lbl.font = pfont
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 72
	lbl.pixel_size = 0.005
	lbl.outline_size = 22
	lbl.outline_modulate = Color(0.10, 0.07, 0.05, 1.0)
	lbl.position = get_prompt_position() + Vector3(0.0, 0.0, 0.004)
	lbl.visible = false
	add_child(lbl)
	# Size the plate to the text once the label can measure its AABB.
	_size_prompt_plate(lbl, plate)
	# A small always-on marker diamond so interactables read from across
	# the yard even before the player is in prompt range.
	var mark := Label3D.new()
	mark.name = "Marker"
	mark.text = "◆"
	mark.modulate = Color(get_prompt_color(), 0.85)
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.font_size = 40
	mark.pixel_size = 0.005
	mark.outline_size = 14
	mark.outline_modulate = Color(0.10, 0.07, 0.05, 1.0)
	mark.position = get_prompt_position() + Vector3(0.0, 0.35, 0.0)
	add_child(mark)
	var bob := create_tween().set_loops()
	bob.tween_property(mark, "position:y", mark.position.y + 0.18, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(mark, "position:y", mark.position.y, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Subclass hook for unique setup (GLB + glow + other meshes).
	_ready_interactable()

# ---- Concrete: prompt visibility, gated by is_used ----
func show_prompt(on: bool) -> void:
	var shown := on and not is_used()
	var lbl := get_node_or_null("PromptLabel") as Label3D
	if lbl != null:
		lbl.visible = shown
	# The parchment plate and its ink border frame track the label.
	var plate := get_node_or_null("PromptPlate") as MeshInstance3D
	if plate != null:
		plate.visible = shown
	var frame := get_node_or_null("PromptFrame") as MeshInstance3D
	if frame != null:
		frame.visible = shown
	# The marker hands off to the prompt up close, and dies with one-shots.
	var mark := get_node_or_null("Marker") as Label3D
	if mark != null:
		mark.visible = not on and not is_used()

# Size the parchment plate to the prompt text. Label3D reports its mesh AABB
# after a frame, so we wait one frame, then convert the AABB extents (already
# in world units via pixel_size) into the plate's QuadMesh size with padding.
func _size_prompt_plate(lbl: Label3D, plate: MeshInstance3D) -> void:
	await get_tree().process_frame
	if not is_instance_valid(lbl) or not is_instance_valid(plate):
		return
	# Label3D.get_aabb() can read ~0 before its mesh lays out, so floor the size
	# with a text-length estimate (font_size * pixel_size = char height; ~0.42 of
	# that per advance) — the plate then always spans the whole prompt.
	var char_h: float = float(lbl.font_size) * lbl.pixel_size
	var est_w: float = float(lbl.text.length()) * char_h * 0.42
	var aabb := lbl.get_aabb()
	var w: float = maxf(aabb.size.x, est_w)
	var h: float = maxf(aabb.size.y, char_h)
	var pad_x := 0.16
	var pad_y := 0.10
	var plate_size := Vector2(w + pad_x * 2.0, h + pad_y * 2.0)
	(plate.mesh as QuadMesh).size = plate_size
	# Resize the ink border frame to 6cm wider/taller than the fill plate.
	var frame := get_node_or_null("PromptFrame") as MeshInstance3D
	if is_instance_valid(frame) and frame.mesh != null:
		(frame.mesh as QuadMesh).size = plate_size + Vector2(0.06, 0.06)

# ---- Virtual hooks (override in subclasses) ----

# Press-E entry point. Abstract — subclasses MUST override.
# Return type intentionally untyped so subclasses can return their
# domain-specific test seam (Chest returns Array of dropped items;
# Hearth returns the Dictionary checkpoint slot; Shrine returns void).
func interact(_player: Node):
	push_error("Interactable.interact() not implemented for %s" % name)

# Returns true after a one-shot interactable has been used. Default = false
# (multi-use). Chest + Shrine override to track their consumed state.
func is_used() -> bool:
	return false

func get_prompt_text() -> String:
	return "[E] Interact"

func get_prompt_color() -> Color:
	return Color(1.0, 0.95, 0.65)        # warm gold default

func get_collision_radius() -> float:
	return 1.0

func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.5, 0.0)

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 1.7, 0.0)

# Called after the base _ready() finishes its common setup. Subclasses
# spawn their unique GLB + glow + other props here. Default is empty so
# tiny interactables (e.g. a future "lore note") can extend with nothing.
func _ready_interactable() -> void:
	pass
