extends SceneTree

# Spec 59 deterministic visual-QA harness. It mounts the real transaction
# panels directly, avoiding unrelated Town scene and model-import failures.

const Items = preload("res://data/items.gd")
const CampaignData = preload("res://data/campaign.gd")

const ROUTES := ["cook", "smith", "enchant", "quill", "waystone",
	"waystone_affixed", "waystone_empty", "loadout", "mastery", "mastery_tending"]

var _route := "cook"
var _capture_path := "/tmp/wyrd_ui_cook.png"


func _initialize() -> void:
	_route = OS.get_environment("WYRD_TRANSACTION_CAPTURE")
	if _route == "":
		_route = "cook"
	_capture_path = OS.get_environment("WYRD_CAPTURE_PATH")
	if _capture_path == "":
		_capture_path = "/tmp/wyrd_ui_%s.png" % _route
	call_deferred("_run")


func _run() -> void:
	if not ROUTES.has(_route):
		push_error("Unknown transaction capture route: %s" % _route)
		quit(2)
		return
	root.size = Vector2i(1366, 768)
	var game := root.get_node_or_null("Game")
	if game == null:
		push_error("Transaction capture requires the Game autoload")
		quit(2)
		return
	game.persistence_enabled = false
	game.reset_to_defaults()
	game.tutorial_step = 7
	_seed_game(game)

	var backdrop := ColorRect.new()
	backdrop.color = Color("566b42")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var panel: CanvasLayer
	if _route in ["cook", "smith"]:
		panel = load("res://scripts/ui/craft_panel.gd").new()
		panel.station_id = "cookfire" if _route == "cook" else "forge"
	elif _route == "enchant":
		panel = load("res://scripts/ui/enchant_panel.gd").new()
	elif _route == "quill":
		panel = load("res://scripts/ui/quill_panel.gd").new()
	elif _route in ["waystone", "waystone_affixed", "waystone_empty"]:
		panel = load("res://scripts/ui/waystone_panel.gd").new()
	elif _route in ["mastery", "mastery_tending"]:
		panel = load("res://scripts/ui/mastery_panel.gd").new()
		panel.station_id = "master_forge"
		panel.action_id = "wayweaver"
	else:
		panel = load("res://scripts/ui/loadout_panel.gd").new()
	root.add_child(panel)
	await _frames(8)

	var image := root.get_texture().get_image()
	var error := image.save_png(_capture_path)
	if error != OK:
		push_error("Could not save %s (error %d)" % [_capture_path, error])
		quit(2)
		return
	print("TRANSACTION CAPTURE: %s -> %s" % [_route, _capture_path])
	quit(0)


func _seed_game(game: Node) -> void:
	game.trades.wildcraft = {"xp": game.xp_for_level(12), "lv": 12}
	game.trades.earthcraft = {"xp": game.xp_for_level(12), "lv": 12}
	for material_id in ["wild_herb", "logs", "bogiron_ore", "glimmerdust",
			"emberglass", "dewthread"]:
		game.add_material(material_id, 12)
	if _route == "enchant":
		game.equipment.slots.weapon = Items.make_item("shortbow", "rare")
		game.equipment.slots.ring = Items.make_item("copper_ring", "magic")
		game.equipment.slots.weapon.enchants = ["emberbind"]
		game.discover_enchant("galebrand")
	elif _route == "quill":
		game.gold = 50
	elif _route == "waystone":
		game.charts.append({"template_id": "snug", "name": "Snug Chart",
			"tier": 1, "scope": "snug", "affixes": []})
	elif _route == "waystone_affixed":
		game.charts.append({"template_id": "snug", "name": "Briar-Twined Snug Chart",
			"tier": 1, "scope": "snug", "affixes": [
				{"id": "mineral_vein", "good": true, "resolvedId": "mineral_vein"},
				{"id": "wood_grove", "good": false, "resolvedId": "brittle_timber"},
				{"id": "bramble_bloom", "good": true, "resolvedId": "bramble_bloom"},
			]})
	elif _route == "loadout":
		game.add_material("quickroot_tonic", 3)
		game.owned_skills = ["PowerShot", "MultiShot", "BrambleSnare"]
		game.loadout = ["PowerShot"]
	elif _route in ["mastery", "mastery_tending"]:
		var campaign := CampaignData.empty_state()
		for chapter_id_value in CampaignData.CHAPTER_ORDER:
			var chapter_id := String(chapter_id_value)
			var chapter: Dictionary = campaign.chapters[chapter_id]
			chapter.cleared = true
			chapter.clue_count = int(CampaignData.CHAPTERS[chapter_id].clue_target)
			chapter.banked_chart_ids = ["capture-%s" % chapter_id]
		campaign.relics = CampaignData.ROOT_RUNE_IDS.duplicate()
		campaign.threads = ["past_thread", "present_thread", "unwritten_thread"]
		campaign.restorations = ["master_forge"]
		campaign.map_of_nine_knots = true
		campaign.road_name_id = "lantern_path"
		game.campaign_state = CampaignData.normalize_campaign_state(campaign)
		for trade_id in ["wayfinding", "earthcraft", "wildcraft", "huntcraft"]:
			game.trades[trade_id] = {"xp": game.xp_for_level(23), "lv": 23}
		for material_id in ["waysteel_frame", "wayweaver_string", "quiet_tooth_grip"]:
			game.add_material(material_id, 1)
		if _route == "mastery_tending":
			game.commit_wayweaver("master_forge", "wayweaver", "equip")


func _frames(count: int) -> void:
	for _index in count:
		await process_frame
