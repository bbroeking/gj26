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
	var lbl := Label3D.new()
	lbl.name = "PromptLabel"
	lbl.text = get_prompt_text()
	lbl.modulate = get_prompt_color()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 48
	lbl.pixel_size = 0.005
	lbl.outline_size = 12
	lbl.outline_modulate = Color(0.08, 0.05, 0.06, 1.0)
	lbl.position = get_prompt_position()
	lbl.visible = false
	add_child(lbl)
	# Subclass hook for unique setup (GLB + glow + other meshes).
	_ready_interactable()

# ---- Concrete: prompt visibility, gated by is_used ----
func show_prompt(on: bool) -> void:
	var lbl := get_node_or_null("PromptLabel") as Label3D
	if lbl != null:
		lbl.visible = on and not is_used()

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
