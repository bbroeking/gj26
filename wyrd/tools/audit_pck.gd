extends SceneTree

# Audit the *mounted release pack*, not export_preset strings.  Run this from
# tools/pck_audit_project so a source-tree file cannot satisfy a missing pack
# entry by accident:
# godot --headless --path tools/pck_audit_project --script /abs/.../audit_pck.gd -- /abs/index.pck

const REQUIRED_PACKED_SCENES := [
	"res://models/biome_rootroads_roots_v1.glb",
	"res://models/boss_barrow_jarl_v1.glb",
	"res://models/enemy_oathbound_v1.glb",
	"res://models/landmark_hod_oathstone_v1.glb",
	"res://models/landmark_pale_well_v1.glb",
	"res://models/landmark_rootroad_lift_wellhouse_v1.glb",
	"res://models/landmark_rootroad_stair_v1.glb",
	"res://models/prop_oath_bellpost_1_v1.glb",
	"res://models/prop_oath_bellpost_2_v1.glb",
	"res://models/prop_oath_bellpost_3_v1.glb",
	"res://models/prop_oath_rubbing_v1.glb",
	"res://models/prop_wellmoss_patch_v1.glb",
	"res://models/prop_wildgold_vein_v1.glb",
	"res://models/settlement_pale_oath_display_v1.glb",
	# Fire in the Bough's strict D7 route mounts all of these through the
	# exported World/Town scenes; audit the mounted PCK rather than trusting the
	# source tree or the include filter.
	"res://models/boss_hearth_giant_v1.glb",
	"res://models/prop_hollow_link_chain_v1.glb",
	"res://models/prop_braided_link_chain_v1.glb",
	"res://models/prop_knot_link_chain_v1.glb",
	"res://models/building_ember_kiln_v1.glb",
	"res://models/building_threefold_loom_foundation_v1.glb",
	"res://models/biome_ashen_bough_landing_v1.glb",
	"res://models/biome_ashen_bough_roots_v1.glb",
	# D8 Slice 3 legendary attachment. Its source-tree symlink must never make a
	# missing release-pack entry look healthy, so the isolated audit loads it.
	"res://models/wayweaver_v1.glb",
	# Both Town's portal and every generated exit preload the same cairn. Keep
	# this explicit because source-tree symlinks can hide a missing Web export.
	"res://models/waypoint_cairn_v2.glb",
]

const REQUIRED_TEXTURES := [
	"res://assets/ui/affixes/stonewake.png",
	"res://assets/ui/components/barrow_mark.png",
	"res://assets/ui/components/pale_wellmark.png",
	"res://assets/ui/icons/trophy_sense.png",
	"res://assets/ui/icons/skill_driving_volley.png",
	"res://assets/ui/items/oath_nail.png",
	"res://assets/ui/items/starheart_coal.png",
	"res://assets/ui/items/pale_root_rune.png",
	"res://assets/ui/items/past_thread.png",
	"res://assets/ui/items/wellmoss.png",
	"res://assets/ui/items/wellmoss_salve.png",
	"res://assets/ui/items/wellwater.png",
	"res://assets/ui/items/wellwater_philter.png",
	"res://assets/ui/items/wildgold_bar.png",
	"res://assets/ui/items/wildgold_ore.png",
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
	"res://assets/ui/items/ember_root_rune.png",
	"res://assets/ui/items/present_thread.png",
	"res://assets/ui/items/embersage.png",
	"res://assets/ui/icons/skill_threadstep.png",
	"res://assets/ui/icons/pack_reader.png",
	"res://assets/ui/affixes/cinderbound.png",
	# D8 Mastery chain, Trophy mount, and selectable Root Rune presentation.
	"res://assets/ui/items/waysteel_shard.png",
	"res://assets/ui/items/waysteel_core.png",
	"res://assets/ui/items/waysteel_frame.png",
	"res://assets/ui/items/root_sap.png",
	"res://assets/ui/items/root_sap_cord.png",
	"res://assets/ui/items/threefold_draught.png",
	"res://assets/ui/items/wayweaver_string.png",
	"res://assets/ui/items/quiet_tooth.png",
	"res://assets/ui/items/quiet_tooth_grip.png",
	"res://assets/ui/items/wayweaver.png",
	"res://assets/ui/icons/wayweaver_mount_empty.png",
	"res://assets/ui/icons/wayweaver_mount_full.png",
	"res://assets/ui/items/green_root_rune.png",
	"res://assets/ui/items/mist_root_rune.png",
	"res://assets/ui/items/fang_root_rune.png",
	"res://assets/ui/items/crown_root_rune.png",
]

const REQUIRED_AUDIO := [
	"res://audio/skill_multi.mp3",
]

# These are the executable dependencies used by the physical D6 journey.
const REQUIRED_SCRIPTS := [
	"res://data/campaign.gd",
	"res://data/charts.gd",
	"res://data/crafting.gd",
	"res://data/gather.gd",
	"res://data/progression.gd",
	"res://scripts/barrow_jarl.gd",
	"res://scripts/barrow_jarl_controller.gd",
	"res://scripts/combatant.gd",
	"res://scripts/game.gd",
	"res://scripts/hunters_lodge_lesson.gd",
	"res://scripts/layout_loader.gd",
	"res://scripts/living_atlas_panel.gd",
	"res://scripts/oath_bell.gd",
	"res://scripts/oath_rubbing.gd",
	"res://scripts/oathbound_guard.gd",
	"res://scripts/pale_stair.gd",
	"res://scripts/rootroad_gather_node.gd",
	"res://scripts/rootroad_lift.gd",
	"res://scripts/skald_archive.gd",
	"res://scripts/skills/driving_volley.gd",
	"res://scripts/skill_bar.gd",
	"res://scripts/stonewake.gd",
	"res://scripts/town.gd",
	"res://scripts/trophy_hall.gd",
	"res://scripts/ui/loadout_panel.gd",
	"res://scripts/cinderbound_vent.gd",
	"res://scripts/cinder_focus_pickup.gd",
	"res://scripts/hearth_chain.gd",
	"res://scripts/hearth_giant.gd",
	"res://scripts/hearth_giant_encounter.gd",
	"res://scripts/skills/threadstep.gd",
	"res://scripts/threadstep_authority.gd",
	"res://data/wayweaver_mastery.gd",
	"res://data/wayweaver_rune_cosmetics.gd",
	"res://data/weapon_presentations.gd",
	"res://scripts/mastery_station.gd",
	"res://scripts/player_controller.gd",
	"res://scripts/wayweaver_echo_authority.gd",
	"res://scripts/wayweaver_thread_rules.gd",
	"res://scripts/ui/mastery_panel.gd",
]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: audit_pck.gd -- <pack.pck> [limit]")
		quit(2)
		return
	var pack_path := ProjectSettings.globalize_path(args[0]) \
		if args[0].begins_with("res://") else args[0]
	if not ProjectSettings.load_resource_pack(pack_path, true):
		push_error("could not mount %s" % pack_path)
		quit(2)
		return

	var failures := _audit_required()
	if not failures.is_empty():
		for failure in failures:
			push_error(String(failure))
		quit(1)
		return

	var pack_file := FileAccess.open(pack_path, FileAccess.READ)
	var pack_bytes := pack_file.get_length() if pack_file != null else -1
	print("PCK D6-D8 audit passed: %d loaded release resources; index.pck = %d bytes" % [
		REQUIRED_PACKED_SCENES.size() + REQUIRED_TEXTURES.size() + REQUIRED_AUDIO.size() + REQUIRED_SCRIPTS.size(), pack_bytes])
	quit()

func _audit_required() -> Array[String]:
	var failures: Array[String] = []
	for path in REQUIRED_PACKED_SCENES:
		_check_resource(String(path), "PackedScene", failures)
	for path in REQUIRED_TEXTURES:
		_check_resource(String(path), "Texture2D", failures)
	for path in REQUIRED_AUDIO:
		_check_resource(String(path), "AudioStream", failures)
	for path in REQUIRED_SCRIPTS:
		_check_resource(String(path), "Script", failures)
	return failures

func _check_resource(path: String, expected_type: String, failures: Array[String]) -> void:
	# The isolated audit project has none of Wayfinder's source files.  These
	# calls can therefore succeed only through the mounted PCK.  `exists` checks
	# a script's emitted remap, while `load` follows asset import dependencies.
	if not ResourceLoader.exists(path):
		failures.append("PCK missing virtual resource: %s" % path)
		return
	# Loading a script from an isolated project would compile it without the
	# release project's autoload classes.  Existence is the meaningful PCK proof
	# for scripts; PackedScenes and textures additionally exercise their imports.
	if expected_type == "Script":
		return
	var resource := ResourceLoader.load(path)
	if resource == null:
		failures.append("PCK import failed to load: %s" % path)
		return
	if expected_type == "PackedScene" and not resource is PackedScene:
		failures.append("PCK import type mismatch (PackedScene): %s" % path)
	elif expected_type == "Texture2D" and not resource is Texture2D:
		failures.append("PCK import type mismatch (Texture2D): %s" % path)
	elif expected_type == "AudioStream" and not resource is AudioStream:
		failures.append("PCK import type mismatch (AudioStream): %s" % path)
	elif expected_type == "Script" and not resource is Script:
		failures.append("PCK import type mismatch (Script): %s" % path)
