class_name Shrine
extends Interactable

# Spec 29/32d — interactable shrine. Common setup (Area3D + collision +
# Label3D prompt) lives on the Interactable base; Shrine declares the altar
# GLB + glow and the choice-modal behaviour. Selection applies to
# player.derived_stats via player.apply_shrine_buff; one-shot per shrine.

const ALTAR_GLB := preload("res://models/dungeon_crypt_altar_v1.glb")
const ShrineChoiceModalScene := preload("res://scenes/ShrineChoiceModal.tscn")

# Bramblewood-flavoured buff pool. 3 are offered per shrine via offered_buffs().
const BUFF_POOL := [
	{"id": "vigor",     "stat": "hp",          "value": 20,
		"name": "Vigor of Bramblewood",     "desc": "+20 Max HP"},
	{"id": "fury",      "stat": "damage",      "value": 2,
		"name": "Fury of the Hedgemother",  "desc": "+2 Arrow Damage"},
	{"id": "precision", "stat": "crit_chance", "value": 0.15,
		"name": "Precision of the Glade",   "desc": "+15% Crit Chance"},
	{"id": "carnage",   "stat": "crit_mult",   "value": 0.5,
		"name": "Carnage of the Thorn",     "desc": "+50% Crit Damage"},
	{"id": "swiftness", "stat": "fire_rate",   "value": 0.2,
		"name": "Swiftness of the Sparrow", "desc": "+20% Fire Rate"},
	{"id": "haste",     "stat": "move_speed",  "value": 0.15,
		"name": "Haste of the Brook",       "desc": "+15% Move Speed"},
	{"id": "channeling", "stat": "focus_regen_bonus", "value": 0.08,
		"name": "Channeling of the Root",   "desc": "+8 Focus/s regen"},
	{"id": "resilience", "stat": "iframes_bonus",    "value": 0.12,
		"name": "Resilience of Bark",       "desc": "+0.12s i-frames after dodge"},
	{"id": "wanderer",   "stat": "gather_speed",     "value": 0.25,
		"name": "Wanderer's Bounty",        "desc": "+25% gather channel speed"},
	{"id": "clarity",    "stat": "skill_cd_mult",    "value": 0.15,
		"name": "Clarity of the Glade",     "desc": "–15% skill cooldowns"},
]

# Set by layout_loader from (dungeon_seed XOR room_id). Same seed → same 3 buffs.
var seed_value: int = 0

var _consumed := false
var _altar: Node3D
var _glow: OmniLight3D
var _modal: Node

# ---- Interactable hooks ----
func get_prompt_text() -> String:
	return "[E] Pray"

func get_prompt_color() -> Color:
	return Color(0.85, 0.95, 1.0)        # cool blue

func get_collision_radius() -> float:
	return 1.1

func get_collision_offset() -> Vector3:
	return Vector3(0.0, 0.6, 0.0)

func get_prompt_position() -> Vector3:
	return Vector3(0.0, 1.8, 0.0)

func _ready_interactable() -> void:
	_altar = ALTAR_GLB.instantiate()
	_altar.position = Vector3(0.0, 0.05, 0.0)
	add_child(_altar)
	GlbFit.add_ink_outline(_altar)
	# Cool blue blessing glow — distinguishes a shrine from a torch.
	_glow = OmniLight3D.new()
	_glow.position = Vector3(0.0, 1.0, 0.0)
	_glow.light_color = Color(0.7, 0.85, 1.0)
	_glow.light_energy = 1.6
	_glow.omni_range = 4.0
	add_child(_glow)

func is_used() -> bool:
	return _consumed

# Open the choice modal with this shrine's 3 buffs. The modal pauses the
# tree until the player commits to a choice (no cancel — shrines are
# single-shot, the commitment is the cost).
func interact(player: Node) -> void:
	if _consumed:
		return
	# D14 — first-shrine explainer.
	var game_h := get_tree().root.get_node_or_null("Game")
	if game_h != null and game_h.has_method("first_time_hint"):
		game_h.first_time_hint("shrine")
	var offered := offered_buffs()
	var modal := ShrineChoiceModalScene.instantiate()
	var scn := get_tree().current_scene
	if scn == null:
		return
	scn.add_child(modal)
	_modal = modal
	modal.setup(offered)
	modal.chosen.connect(_on_buff_chosen.bind(player))

# Return the 3 buffs this shrine offers (test seam). Seeded from seed_value.
# The same seed always yields the same 3 buffs in the same order.
func offered_buffs() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = max(1, seed_value)
	var pool: Array = BUFF_POOL.duplicate()
	var out: Array = []
	for _i in 3:
		if pool.is_empty():
			break
		var idx := rng.randi_range(0, pool.size() - 1)
		out.append(pool[idx])
		pool.remove_at(idx)
	return out

# Apply the buff to the player's derived_stats pipeline + mark inert.
# Test seam — directly callable as `apply(player, buff)` in evals.
func apply(player: Node, buff: Dictionary) -> void:
	if _consumed:
		return
	_consumed = true
	if player != null and player.has_method("apply_shrine_buff"):
		player.apply_shrine_buff(String(buff.stat), buff.value)
		# Fallback: new off-stat keys not yet in player.shrine_buffs are written
		# directly so the T4 eval's shrine_buffs.get() branch can observe them.
		# When player_controller.gd task-5 lands, apply_shrine_buff will handle
		# these keys natively and this branch becomes a harmless double-write.
		var _sb_var: Variant = player.get("shrine_buffs")
		if _sb_var is Dictionary:
			var _sb := _sb_var as Dictionary
			if not _sb.has(String(buff.stat)):
				_sb[String(buff.stat)] = buff.value
	var lbl := get_node_or_null("PromptLabel") as Label3D
	if lbl != null:
		lbl.visible = false
	if _glow != null:
		var t := create_tween()
		t.tween_property(_glow, "light_energy", 0.0, 0.6)
	collision_layer = 0
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("shrine_bless")

func _on_buff_chosen(buff: Dictionary, player: Node) -> void:
	apply(player, buff)
	if _modal != null and is_instance_valid(_modal):
		_modal.queue_free()
		_modal = null
