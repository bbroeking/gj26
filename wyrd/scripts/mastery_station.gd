class_name MasteryStation
extends Interactable

# A deliberately thin world adapter for the D8 mastery workstations.  The
# station has no opinion about requirements, inventory, campaign state, or a
# successful craft: those all remain with Game's future Wayweaver API.

const MasteryPanelScript = preload("res://scripts/ui/mastery_panel.gd")

const STATION_LABELS := {
	"hod_mastery": "Hod's Master Forge",
	"quill_mastery": "Quill's Rootwork Still",
	"awake_loom": "The Awake Loom",
	"master_hunt": "The Master Hunt",
	"master_forge": "The Master Forge",
}

# Integration deliberately sets action_id for Hod's two sequential actions.
# These defaults make each authored station useful by itself while avoiding a
# UI-side rule for which conversion should be unlocked next.
const DEFAULT_ACTIONS := {
	"hod_mastery": "waysteel_core",
	"quill_mastery": "root_sap_cord",
	"awake_loom": "wayweaver_string",
	"master_hunt": "quiet_tooth_grip",
	"master_forge": "wayweaver",
}

@export var station_id := "hod_mastery"
@export var action_id := ""


func _ready_interactable() -> void:
	add_to_group("mastery_station")
	add_to_group("mastery_station_%s" % station_id)


func get_prompt_text() -> String:
	return "[E/A] %s" % String(STATION_LABELS.get(station_id, "Study the masterwork"))


func get_prompt_color() -> Color:
	return Color(0.70, 0.56, 0.25) # muted gold: an earned, not urgent, invitation


func get_collision_radius() -> float:
	return 1.15


func get_prompt_position() -> Vector3:
	return Vector3(0.0, 1.55, 0.0)


func get_solid_radius() -> float:
	return 0.42


func get_solid_height() -> float:
	return 0.92


func resolved_action_id() -> String:
	return action_id if not action_id.is_empty() else String(DEFAULT_ACTIONS.get(station_id, ""))


func interact(_player: Node) -> void:
	var action := resolved_action_id()
	if action.is_empty():
		return
	var panel: CanvasLayer = MasteryPanelScript.new()
	panel.station_id = station_id
	panel.action_id = action
	get_tree().current_scene.add_child(panel)
