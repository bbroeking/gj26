extends SceneTree

const BenchScript = preload("res://scripts/ui/crafting_bench.gd")
const ChartsData = preload("res://data/charts.gd")
const CampaignData = preload("res://data/campaign.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String, detail = "") -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s — %s" % [message, str(detail)])


func _frames(count := 2) -> void:
	for _i in count:
		await process_frame


func _press_action(action: String) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	root.push_input(pressed)
	await process_frame
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	root.push_input(released)
	await process_frame


func _run() -> void:
	root.size = Vector2i(1366, 768)
	var game := root.get_node("Game")
	game.reset_to_defaults()
	game.tutorial_step = 2
	game.add_material("hedge_ink", 1)
	game.add_material("wild_herb", 1)
	game.add_material("thorn_essence", 1)
	game.add_material("alpha_fang", 1)
	game.add_material("oath_nail", 1)
	var modal_before := int(game.modal_count)
	var host := Node.new()
	root.add_child(host)
	var bench: CanvasLayer = BenchScript.new()
	host.add_child(bench)
	await _frames(4)

	var panel := bench.get_node_or_null("ChartTablePanel") as Panel
	var view := panel.get_node_or_null("ChartTableView") as Control if panel != null else null
	_check(panel != null and view != null, "physical Chart Table builds")
	if panel == null or view == null:
		_finish()
		return
	_check(panel.size == Vector2(1200, 680), "table owns the locked 1200×680 frame",
		panel.size)
	_check(panel.size.x <= 1366 and panel.size.y <= 768,
		"table fits 1366×768 without scale-down", panel.size)
	var panel_rect := panel.get_global_rect()
	_check(panel_rect.position.x >= 0.0 and panel_rect.position.y >= 0.0
		and panel_rect.end.x <= 1366.0 and panel_rect.end.y <= 768.0,
		"centered table remains wholly on-screen at 1366×768", panel_rect)
	_check(int(game.modal_count) == modal_before + 1, "table claims one modal")
	var codex_button := view.find_child("CodexButton", true, false) as Button
	_check(codex_button != null, "Mara's Codex has a stable focusable toggle")
	if codex_button != null:
		codex_button.emit_signal("pressed")
		await _frames()
	var codex_pages := view.find_children("CodexPage_*", "Button", true, false)
	var codex_pages_focusable := codex_pages.size() == ChartsData.CHART_RECIPE_ORDER.size()
	for page_v in codex_pages:
		var page := page_v as Button
		codex_pages_focusable = codex_pages_focusable \
			and page.focus_mode == Control.FOCUS_ALL \
			and page.has_meta("cursor_role")
	_check(codex_pages_focusable,
		"Codex list exposes every authored recipe as a focusable semantic page",
		{"rendered": codex_pages.size(), "authored": ChartsData.CHART_RECIPE_ORDER.size()})
	var first_codex_page := codex_pages[0] as Button if not codex_pages.is_empty() else null
	var first_page_linked := first_codex_page != null \
		and first_codex_page.focus_neighbor_top != NodePath("") \
		and first_codex_page.focus_neighbor_bottom != NodePath("")
	if first_codex_page != null:
		first_codex_page.grab_focus()
		await _press_action("ui_accept")
	_check(String((bench.call("selected_codex_page") as Dictionary)
		.get("recipe_id", "")) == "snug"
		and first_page_linked
		and root.gui_get_focus_owner() != null
		and root.gui_get_focus_owner().name == "CodexBackButton",
		"controller focus and Accept open a known Codex page")
	await _frames()
	var detail_pages := view.find_children("CodexPage_*", "Button", true, false)
	var codex_back := view.find_child("CodexBackButton", true, false) as Button
	var stage_all := view.find_child("CodexStageAllButton", true, false) as Button
	_check(detail_pages.is_empty() and codex_back != null and stage_all != null,
		"Codex shows either six page buttons or one detail with Back, never both",
		{"pages": detail_pages.size(), "back": codex_back, "stage": stage_all})
	var ghost_center: Dictionary = bench.call("slot_view_state", "c")
	var ghost_north: Dictionary = bench.call("slot_view_state", "n")
	var ghost_ink: Dictionary = bench.call("ink_view_state", 0)
	_check(bool(ghost_center.get("ghost", false))
		and bool(ghost_north.get("ghost", false))
		and bool(ghost_ink.get("ghost", false)),
		"known page paints its exact Base, Waymark, and required Ink as ghosts")
	var focused_ghost := view.find_child("ChartSlot_c", true, false) as Button
	_check(focused_ghost != null and focused_ghost.focus_mode == Control.FOCUS_ALL
		and String(focused_ghost.get_meta("cursor_role", "")) == "ghost_stage",
		"stageable ghost has keyboard focus and a semantic success cursor")
	var ghost_materials_before: Dictionary = (game.materials as Dictionary).duplicate(true)
	if focused_ghost != null:
		focused_ghost.grab_focus()
		await _press_action("ui_accept")
	_check(String((bench.get("draft") as Dictionary).grid.get("c", "")) == "practice_leaf"
		and game.materials == ghost_materials_before,
		"mouse/controller activation stages one owned ghost without spending")
	var staged_one: Dictionary = (bench.get("draft") as Dictionary).duplicate(true)
	view.call("set_source_mode", "supplies")
	await _frames()
	_check((bench.call("selected_codex_page") as Dictionary).is_empty()
		and bench.get("draft") == staged_one,
		"leaving Codex clears only virtual ghosts and preserves physical choices")
	bench.call("clear_draft")
	game.trades.wayfinding = {"xp": game.xp_for_level(2), "lv": 2}
	view.call("set_source_mode", "codex")
	bench.call("open_codex_page", "snug")
	await _frames()
	var w2_draft: Dictionary = (bench.get("draft") as Dictionary).duplicate(true)
	var w2_materials: Dictionary = (game.materials as Dictionary).duplicate(true)
	var w2_pot: Dictionary = (bench.get("pot") as Dictionary).duplicate(true)
	_check(not bool(bench.call("stage_all_known_recipe"))
		and bench.get("draft") == w2_draft and game.materials == w2_materials
		and bench.get("pot") == w2_pot,
		"Wayfinding 2 Stage All is a deep-equal no-op")
	game.trades.wayfinding = {"xp": game.xp_for_level(1), "lv": 1}
	view.call("set_source_mode", "mix")
	await _frames()
	var supplies_tab := view.find_child("SuppliesTab", true, false) as Button
	var mix_tab := view.find_child("MixTab", true, false) as Button
	_check(String(bench.call("initial_source_mode")) == "mix"
		and mix_tab != null and mix_tab.button_pressed and not mix_tab.disabled,
		"guided pot lesson opens with a focusable Mix tab on the first build")
	var mix_workspace := view.find_child("InkMixingWorkspace", true, false) as Control
	var mix_folio := view.find_child("InkRecipeFolio", true, false) as Control
	var mix_action := view.find_child("TryMixButton", true, false) as Button
	var chart_surface := view.find_child("ChartingSurfacePanel", true, false) as Control
	_check(mix_workspace != null and mix_workspace.visible
		and mix_folio != null and mix_folio.visible
		and mix_action != null and mix_action.size.y >= 48.0
		and chart_surface != null and not chart_surface.visible,
		"Mix owns a dedicated semantic pot workspace instead of an inert Chart grid")
	view.call("set_source_mode", "supplies")
	await _frames()
	supplies_tab.grab_focus()
	await _press_action("ui_right")
	_check(root.gui_get_focus_owner() == mix_tab,
		"controller Right traverses from Supplies to Mix")
	await _press_action("ui_accept")
	_check(String(bench.call("initial_source_mode")) == "mix" and mix_tab.button_pressed,
		"controller Accept activates Mix")
	var first_mix_row := view.find_child("Supply_wild_herb", true, false) as Button
	if first_mix_row != null:
		first_mix_row.grab_focus()
		await _press_action("ui_up")
	_check(first_mix_row != null and root.gui_get_focus_owner() == mix_tab,
		"first source-row Up enters the active tab instead of looping")
	var protected_ids_visible := false
	var mix_ids: Array[String] = []
	for row_v in bench.call("source_rows", "mix"):
		var row: Dictionary = row_v
		mix_ids.append(String(row.id))
		protected_ids_visible = protected_ids_visible or String(row.id) in [
			"practice_leaf", "field_parchment", "thorn_essence", "alpha_fang", "oath_nail"]
	_check(mix_ids.has("hedge_ink"),
		"Mix exposes an owned Ink when an authored recipe uses it as an ingredient")
	var component_before := int(game.material_count("practice_leaf"))
	var seal_before := int(game.material_count("thorn_essence"))
	var story_key_before := int(game.material_count("alpha_fang"))
	var oath_nail_before := int(game.material_count("oath_nail"))
	_check(not protected_ids_visible
		and not bool(bench.call("pot_add", "practice_leaf"))
		and not bool(bench.call("pot_add", "thorn_essence"))
		and not bool(bench.call("pot_add", "alpha_fang"))
		and not bool(bench.call("pot_add", "oath_nail"))
		and (bench.get("pot") as Dictionary).is_empty()
		and game.material_count("practice_leaf") == component_before
		and game.material_count("thorn_essence") == seal_before
		and game.material_count("alpha_fang") == story_key_before
		and game.material_count("oath_nail") == oath_nail_before,
		"Mix hides and rejects protected Chart supplies and story keys without loss")
	game.tutorial_step = 3
	view.call("set_source_mode", "supplies")
	await _frames()
	var story_seal_row := view.find_child("Supply_alpha_fang", true, false) as Button
	var oath_nail_row := view.find_child("Supply_oath_nail", true, false) as Button
	_check(story_seal_row != null and not story_seal_row.disabled
		and String(story_seal_row.get_meta("supply_id", "")) == "alpha_fang"
		and story_seal_row.has_meta("cursor_role")
		and oath_nail_row != null and not oath_nail_row.disabled
		and String(oath_nail_row.get_meta("supply_id", "")) == "oath_nail"
		and oath_nail_row.has_meta("cursor_role"),
		"owned Alpha Fang and Oath Nail Story Seals appear as semantic Supplies controls")
	for recipe_id in ["summit_approach", "queens_summit_boss"]:
		if not game.known_chart_recipes.has(recipe_id):
			game.known_chart_recipes.append(recipe_id)
	view.call("set_source_mode", "codex")
	await _frames()
	var approach_page := view.find_child("CodexPage_summit_approach", true, false) as Button
	var queen_page := view.find_child("CodexPage_queens_summit_boss", true, false) as Button
	_check(approach_page != null and queen_page != null
		and approach_page.focus_mode == Control.FOCUS_ALL and queen_page.focus_mode == Control.FOCUS_ALL
		and approach_page.has_meta("cursor_role") and queen_page.has_meta("cursor_role"),
		"Crownward Ascent and Queen's Summit have semantic Codex controls")
	view.call("set_source_mode", "supplies")

	var slots := view.find_children("ChartSlot_*", "Button", true, false)
	var inks := view.find_children("InkSlot*", "Button", true, false)
	_check(slots.size() == 9, "charting surface exposes nine semantic Controls",
		slots.size())
	_check(inks.size() == 4, "Ink rail exposes four semantic Controls", inks.size())
	var all_focusable := true
	var all_semantic := true
	for control_v in slots + inks:
		var control := control_v as Control
		all_focusable = all_focusable and control.focus_mode == Control.FOCUS_ALL
		all_semantic = all_semantic and control.has_meta("cursor_role")
	_check(all_focusable, "every chart socket participates in controller focus")
	_check(all_semantic, "every chart socket publishes a semantic cursor role")

	var center := view.find_child("ChartSlot_c", true, false) as Button
	var north := view.find_child("ChartSlot_n", true, false) as Button
	var west := view.find_child("ChartSlot_w", true, false) as Button
	var ink_one := view.find_child("InkSlot1", true, false) as Button
	_check(center != null and not center.disabled and north != null and not north.disabled,
		"fresh table wakes Base and first Waymark")
	_check(ink_one != null and not ink_one.disabled, "fresh table wakes first Ink pot")
	_check(west != null and west.disabled and "First Snug return" in west.text,
		"Binding remains a readable first-return silhouette", west.text if west else "")
	_check(center.focus_neighbor_left != NodePath("")
		and center.focus_neighbor_right != NodePath("")
		and center.focus_neighbor_top != NodePath("")
		and center.focus_neighbor_bottom != NodePath(""),
		"center cell has an explicit four-way focus graph")

	var before_leaf := int(game.material_count("practice_leaf"))
	var before_sprig := int(game.material_count("hedge_sprig"))
	var before_ink := int(game.material_count("hedge_ink"))
	_check(bool(bench.call("place_component", "c", "practice_leaf")),
		"click-place stages Practice Leaf")
	_check(bool(bench.call("place_component", "n", "hedge_sprig")),
		"click-place stages Hedge Sprig")
	_check(bool(bench.call("place_ink", "hedge_ink", 0)),
		"click-place stages required Hedge Ink")
	var preview: Dictionary = bench.call("current_preview")
	_check(String(preview.get("state", "")) == "known"
		and bool(preview.get("commit_ready", false)),
		"guided Base → Waymark → Hedge Ink resolves Snug", preview)
	_check(game.material_count("practice_leaf") == before_leaf
		and game.material_count("hedge_sprig") == before_sprig
		and game.material_count("hedge_ink") == before_ink,
		"staging is inventory-pure")

	var action := view.find_child("InscribeChartButton", true, false) as Button
	var net := root.get_node_or_null("NetGame")
	if net != null:
		var guest_started := bool(net.join("127.0.0.1", 19999))
		view.call("refresh")
		_check(guest_started and bool(bench.call("is_read_only")) and action.disabled,
			"guest table is inspectable but read-only",
			"active=%s game=%s table=%s action=%s" % [net.active,
				game.net_active(), bench.call("is_read_only"), action.disabled])
		# UI disablement is only the friendly guard. A guest can still forge a
		# direct call, so lock host authority at the sole Game mutation boundary.
		var guest_materials: Dictionary = (game.materials as Dictionary).duplicate(true)
		var guest_charts: Array = (game.charts as Array).duplicate(true)
		var guest_draft: Dictionary = (bench.get("draft") as Dictionary).duplicate(true)
		var guest_pot: Dictionary = (bench.get("pot") as Dictionary).duplicate(true)
		view.call("set_source_mode", "codex")
		bench.call("open_codex_page", "snug")
		await _frames()
		var guest_stage_all := view.find_child("CodexStageAllButton", true, false) as Button
		_check(guest_stage_all != null and guest_stage_all.disabled
			and not bool(bench.call("stage_codex_ghost", "grid", "c"))
			and not bool(bench.call("stage_all_known_recipe"))
			and bench.get("draft") == guest_draft and bench.get("pot") == guest_pot
			and game.materials == guest_materials and game.charts == guest_charts,
			"guest Codex is readable while one-ghost and Stage All stay deep-equal inert")
		var forged: Dictionary = game.try_inscribe_chart(
			(bench.get("draft") as Dictionary).duplicate(true),
			String(preview.get("fingerprint", "")), 777)
		_check(not bool(forged.get("ok", false))
			and game.materials == guest_materials and game.charts == guest_charts,
			"forged guest commit is rejected without mutation", forged)
		net.leave("Chart Table test complete.")
		view.call("set_source_mode", "supplies")
		view.call("refresh")
	var saved_charts: Array = (game.charts as Array).duplicate(true)
	while (game.charts as Array).size() < int(game.CHART_CASE_MAX):
		(game.charts as Array).append({"template_id": "snug", "name": "Test Chart"})
	view.call("refresh")
	_check(action.disabled and "Case is full" in String(action.tooltip_text),
		"Case-full preview disables inscription without clearing the draft",
		action.tooltip_text)
	game.charts = saved_charts
	view.call("refresh")

	var stable_draft: Dictionary = (bench.get("draft") as Dictionary).duplicate(true)
	_check(not bool(bench.call("place_component", "nw", "hedge_sprig")),
		"locked-cell placement is rejected")
	_check(bench.get("draft") == stable_draft,
		"invalid placement snaps back to the previous draft")

	center.grab_focus()
	bench.call("return_focused_item")
	_check(not (bench.get("draft") as Dictionary).grid.has("c"),
		"keyboard/controller return path removes the focused component")
	_check(bool(bench.call("place_component", "c", "practice_leaf")),
		"returned component can be staged again")

	var charts_before := (game.charts as Array).size()
	_check(bool(bench.call("craft")), "Inscribe Chart commits through Game")
	_check((game.charts as Array).size() == charts_before + 1,
		"successful commit places one Chart in the Case")
	_check(bool(bench.call("draft_is_empty")), "successful commit clears the draft")
	var stamp := view.find_child("StampOverlay", true, false) as Control
	_check(stamp != null and stamp.visible, "successful commit begins stamp/fold/string feedback")

	var first_return: Dictionary = game.grant_first_return_chart_supplies()
	bench.call("_refresh_preview")
	view.call("refresh")
	await _frames()
	var lesson_rows: Array = bench.call("source_rows", "supplies")
	var lesson_ids: Array = []
	for row_v in lesson_rows:
		lesson_ids.append(String((row_v as Dictionary).id))
	_check(not west.disabled and first_return.has("field_parchment")
		and lesson_ids.has("field_parchment") and lesson_ids.has("loop_cord")
		and not game.chart_recipe_known("green_hollow"),
		"first return exposes the owned Green Hollow lesson before discovery")
	game.add_material("hedge_ink", 2)
	bench.call("activate_supply", "field_parchment")
	bench.call("activate_supply", "hedge_sprig")
	bench.call("activate_supply", "loop_cord")
	var green_preview: Dictionary = bench.call("current_preview")
	_check(String(green_preview.get("state", "")) == "attemptable"
		and bool(green_preview.get("commit_ready", false)),
		"first-return tray arrangement resolves Green Hollow", green_preview)
	_check(bool(bench.call("craft")) and game.chart_recipe_known("green_hollow"),
		"tray-to-table Green Hollow inscription discovers its recipe")

	# Practiced Measures stages a known draft through one candidate application.
	game.trades.wayfinding = {"xp": game.xp_for_level(3), "lv": 3}
	game.add_material("field_parchment", 1)
	game.add_material("hedge_sprig", 1)
	game.add_material("loop_cord", 1)
	game.add_material("hedge_ink", 2)
	_check(bool(bench.call("place_ink", "hedge_ink", 0)),
		"player bias Ink can be chosen before Codex staging")
	view.call("set_source_mode", "codex")
	bench.call("open_codex_page", "green_hollow")
	await _frames()
	var practiced_before_materials: Dictionary = (game.materials as Dictionary).duplicate(true)
	var practiced_before_charts: Array = (game.charts as Array).duplicate(true)
	var practiced_before_pot: Dictionary = (bench.get("pot") as Dictionary).duplicate(true)
	_check(bool(bench.call("stage_all_known_recipe")),
		"Wayfinding 3 Practiced Measures stages one known candidate")
	var practiced_draft: Dictionary = bench.get("draft")
	_check(String((practiced_draft.grid as Dictionary).get("c", "")) == "field_parchment"
		and String((practiced_draft.grid as Dictionary).get("n", "")) == "hedge_sprig"
		and String((practiced_draft.grid as Dictionary).get("w", "")) == "loop_cord"
		and (practiced_draft.ink_rail as Array) == ["hedge_ink"]
		and game.materials == practiced_before_materials
		and game.charts == practiced_before_charts
		and bench.get("pot") == practiced_before_pot,
		"Stage All merges without moving the chosen Ink, spending, or inscribing",
		practiced_draft)
	view.call("set_source_mode", "supplies")
	bench.call("clear_draft")

	# WF10 opens a second Waymark cell (nw). Supply auto-placement must still
	# choose the north cell that preserves the Deep Hollow experiment.
	game.trades.wayfinding = {"xp": game.xp_for_level(10), "lv": 10}
	game.add_material("hedge_sprig", 1)
	bench.call("_refresh_preview")
	bench.call("activate_supply", "hedge_sprig")
	var wf10_waymark_draft: Dictionary = bench.get("draft")
	_check(String((wf10_waymark_draft.grid as Dictionary).get("n", "")) \
		== "hedge_sprig" and not (wf10_waymark_draft.grid as Dictionary).has("nw"),
		"WF10 supply placement preserves a viable north-waymark experiment",
		wf10_waymark_draft)
	bench.call("clear_draft")
	game.trades.wayfinding = {"xp": game.xp_for_level(3), "lv": 3}
	bench.call("_refresh_preview")

	# A missing required Ink claimed by the mixing pot blocks the entire candidate.
	bench.call("pot_add", "hedge_ink")
	view.call("set_source_mode", "codex")
	bench.call("open_codex_page", "snug")
	var pot_claim_draft: Dictionary = (bench.get("draft") as Dictionary).duplicate(true)
	var pot_claim_materials: Dictionary = (game.materials as Dictionary).duplicate(true)
	var pot_claim_pot: Dictionary = (bench.get("pot") as Dictionary).duplicate(true)
	var pot_claim_charts: Array = (game.charts as Array).duplicate(true)
	_check(not bool(bench.call("stage_all_known_recipe"))
		and bench.get("draft") == pot_claim_draft
		and game.materials == pot_claim_materials and bench.get("pot") == pot_claim_pot
		and game.charts == pot_claim_charts,
		"pot-claimed stock makes Stage All a deep-equal no-op")
	bench.call("clear_pot")
	view.call("set_source_mode", "supplies")

	# A physical choice always wins over the Codex; no slot is moved or erased.
	bench.call("place_component", "c", "practice_leaf")
	view.call("set_source_mode", "codex")
	bench.call("open_codex_page", "green_hollow")
	var conflict_draft: Dictionary = (bench.get("draft") as Dictionary).duplicate(true)
	var conflict_materials: Dictionary = (game.materials as Dictionary).duplicate(true)
	var conflict_gold := int(game.gold)
	_check(not bool(bench.call("stage_all_known_recipe"))
		and bench.get("draft") == conflict_draft and game.materials == conflict_materials
		and int(game.gold) == conflict_gold,
		"slot conflict blocks Stage All without moving a choice or auto-buying")
	view.call("set_source_mode", "supplies")
	bench.call("clear_draft")

	# A known recipe with repeated parts needs the full multiplicity and open cells.
	if not game.known_chart_recipes.has("summit_approach"):
		game.known_chart_recipes.append("summit_approach")
	game.add_material("atlas_folio", 1)
	game.add_material("cold_track", 1)
	game.add_material("climbing_cord", 1)
	view.call("set_source_mode", "codex")
	bench.call("open_codex_page", "summit_approach")
	var duplicate_draft: Dictionary = (bench.get("draft") as Dictionary).duplicate(true)
	var duplicate_materials: Dictionary = (game.materials as Dictionary).duplicate(true)
	_check(not bool(bench.call("stage_all_known_recipe"))
		and bench.get("draft") == duplicate_draft and game.materials == duplicate_materials,
		"duplicate recipe quantities are prevalidated before Stage All")
	game.add_material("cold_track", 1)
	game.add_material("climbing_cord", 1)
	var locked_draft: Dictionary = (bench.get("draft") as Dictionary).duplicate(true)
	var locked_materials: Dictionary = (game.materials as Dictionary).duplicate(true)
	_check(not bool(bench.call("stage_all_known_recipe"))
		and bench.get("draft") == locked_draft and game.materials == locked_materials,
		"locked Summit sockets reject the whole known candidate at Wayfinding 3")
	view.call("set_source_mode", "supplies")

	# Existing non-required Ink is preserved; if it exceeds a recipe's capacity,
	# preview validation rejects the candidate instead of deleting the choice.
	game.add_material("stoneground_ink", 1)
	bench.call("place_ink", "stoneground_ink", 0)
	view.call("set_source_mode", "codex")
	bench.call("open_codex_page", "snug")
	var capacity_draft: Dictionary = (bench.get("draft") as Dictionary).duplicate(true)
	var capacity_materials: Dictionary = (game.materials as Dictionary).duplicate(true)
	_check(not bool(bench.call("stage_all_known_recipe"))
		and bench.get("draft") == capacity_draft and game.materials == capacity_materials,
		"Ink-capacity failure preserves the player's existing Ink choice")
	view.call("set_source_mode", "supplies")
	bench.call("clear_draft")

	# A known high-level Green Hollow exposes the complete authored affix table.
	game.trades.wayfinding = {"xp": game.xp_for_level(23), "lv": 23}
	game.add_material("field_parchment", 1)
	game.add_material("hedge_sprig", 1)
	game.add_material("loop_cord", 1)
	game.add_material("hedge_ink", 2)
	bench.call("place_component", "c", "field_parchment")
	bench.call("place_component", "n", "hedge_sprig")
	bench.call("place_component", "w", "loop_cord")
	var known_preview: Dictionary = bench.call("current_preview")
	var preview_copy := String(view.call("_preview_copy", known_preview))
	var weights: Dictionary = known_preview.get("affix_weights", {})
	var stability: Dictionary = known_preview.get("stability", {})
	var expected_roll_ids: Array[String] = []
	for affix_id_v in ChartsData.AFFIX_ROLL_ORDER:
		var affix_id := String(affix_id_v)
		var affix: Dictionary = ChartsData.AFFIXES.get(affix_id, {})
		if bool(affix.get("chart_scoped", false)):
			continue
		if int(affix.get("req_carto", 1)) <= 23:
			expected_roll_ids.append(affix_id)
	var authored_copy_complete := true
	var previous_index := -1
	for affix_id in expected_roll_ids:
		var line := "%s — roll %d%% · good twin %d%%" % [
			bench.call("affix_name", affix_id), roundi(float(weights[affix_id])),
			int(stability.get(affix_id, 0))]
		var line_index := preview_copy.find(line)
		authored_copy_complete = authored_copy_complete \
			and line_index > previous_index
		previous_index = line_index
	var preview_body := view.find_child("PreviewBody", true, false) as RichTextLabel
	_check(String(known_preview.get("state", "")) == "known"
		and weights.size() == expected_roll_ids.size()
		and authored_copy_complete and preview_body.scroll_active,
		"known preview scrolls every affix in authored order with roll and stability",
		{"state": known_preview.get("state", ""), "weight_count": weights.size(),
			"authored_count": expected_roll_ids.size(),
			"copy_complete": authored_copy_complete, "copy": preview_copy})

	# Slice D1 — campaign Seals are an authored promise, never the old boss
	# Affix gamble. Render the exact same domain preview the commit path reads:
	# named boss, ordinary retry spend, and protected Seal return all appear in
	# text as well as the physical focusable Seal socket.
	var campaign_state: Dictionary = CampaignData.empty_state()
	var first_knot: Dictionary = campaign_state.chapters.first_knot
	first_knot.clue_count = 3
	first_knot.boss_rumoured = true
	var sealed_preview: Dictionary = ChartsData.preview_table({
		"grid": {"c": "field_parchment", "n": "hedge_sprig",
			"w": "loop_cord", "s": "thorn_essence"}, "ink_rail": ["hedge_ink"],
	}, {
		"level": 8, "first_snug_returned": true,
		"known_recipe_ids": ["snug", "green_hollow", "first_knot_boss"],
		"material_counts": {"field_parchment": 1, "hedge_sprig": 1,
			"loop_cord": 1, "thorn_essence": 1, "hedge_ink": 2},
		"campaign_state": campaign_state,
	})
	var sealed_copy := String(view.call("_preview_copy", sealed_preview))
	var guarantee: Dictionary = (sealed_preview.get("guaranteed", []) as Array)[0] \
		if not (sealed_preview.get("guaranteed", []) as Array).is_empty() else {}
	_check(bool(sealed_preview.get("commit_ready", false))
		and String(sealed_preview.get("recipe_id", "")) == "first_knot_boss"
		and String(guarantee.get("id", "")) == "hedgemother"
		and bool(sealed_preview.get("requires_seal", false))
		and (sealed_preview.get("required_inks", []) as Array) == ["hedge_ink"]
		and int((sealed_preview.get("costs", {}) as Dictionary).get("hedge_ink", 0)) == 2
		and not (sealed_preview.get("ordinary_costs", {}) as Dictionary).has("thorn_essence")
		and "Guaranteed" in sealed_copy and "The Hedgemother" in sealed_copy
		and "Seal safeguard" in sealed_copy
		and "Abandon before victory" in sealed_copy
		and "Returns: 1× Thorn Essence" in sealed_copy
		and "full-party wipe resets the fight" in sealed_copy,
		"boss preview names its guaranteed encounter, required Ink, and exact Seal safeguard", sealed_copy)
	var seal_socket := view.find_child("ChartSlot_s", true, false) as Button
	_check(seal_socket != null and seal_socket.focus_mode == Control.FOCUS_ALL
		and seal_socket.has_meta("cursor_role"),
		"Seal socket remains a focusable semantic controller target", seal_socket)

	# Slice D2 — the UI does not calculate depth. It projects the exact preview
	# contract from Charts, including the optional far-Waystone decision.
	# Staging remains a draft-only action even when the same Binding is used in
	# both physical wells.
	bench.call("clear_draft")
	view.call("set_source_mode", "supplies")
	game.trades.wayfinding = {"xp": game.xp_for_level(17), "lv": 17}
	if not game.known_chart_recipes.has("green_hollow"):
		game.known_chart_recipes.append("green_hollow")
	game.add_material("field_parchment", 1)
	game.add_material("hedge_sprig", 1)
	game.add_material("loop_cord", 2)
	var deep_loop_before := int(game.material_count("loop_cord"))
	_check(bool(bench.call("place_component", "c", "field_parchment"))
		and bool(bench.call("place_component", "n", "hedge_sprig"))
		and bool(bench.call("place_component", "w", "loop_cord")),
		"matching-Binding road stages its base route before the second cord")
	bench.call("activate_supply", "loop_cord")
	var deep_draft: Dictionary = (bench.get("draft") as Dictionary).duplicate(true)
	var deep_preview: Dictionary = bench.call("current_preview")
	var deep_copy := String(view.call("_preview_copy", deep_preview))
	var deep_contract: Dictionary = deep_preview.get("depth_contract", {})
	_check(String((deep_draft.get("grid", {}) as Dictionary).get("e", "")) == "loop_cord"
		and int(game.material_count("loop_cord")) == deep_loop_before
		and int(bench.call("_remaining", "loop_cord")) == deep_loop_before - 2
		and not (deep_contract as Dictionary).is_empty(),
		"second matching Binding click stages in east well and reserves exactly one owned cord",
		{"draft": deep_draft, "remaining": bench.call("_remaining", "loop_cord"),
			"preview": deep_preview})
	_check("2 layers — base 1, added layer 2." in deep_copy
		and "Hearth: terminal layer 2." in deep_copy
		and "Far Waystone" in deep_copy and "1 Omen" in deep_copy,
		"Deepening preview names exact layers, terminal Hearth, and far-Waystone Omen choice",
		deep_copy)

	# The threshold failure belongs to the same real preview seam: the UI simply
	# renders the domain reason and its normal no-spend invalid state.
	var below_threshold := ChartsData.preview_table(deep_draft, {
		"level": 16, "first_snug_returned": true,
		"known_recipe_ids": ["green_hollow"],
		"material_counts": {"field_parchment": 1, "hedge_sprig": 1,
			"loop_cord": 2},
	})
	var below_copy := String(view.call("_preview_copy", below_threshold))
	_check(String(below_threshold.get("state", "")) == "invalid"
		and "Wayfinding 17" in String(below_threshold.get("reason", ""))
		and "Nothing will be spent." in below_copy,
		"below-threshold doubled Binding explains the WF17 gate and spends nothing",
		below_threshold)

	var sallow_preview := ChartsData.preview_table({
		"grid": {"c": "waxed_vellum", "n": "mire_reed", "w": "sunk_knot",
			"e": "sunk_knot"}, "ink_rail": [],
	}, {
		"level": 17, "first_snug_returned": true,
		"known_recipe_ids": ["sallow_mire"],
		"material_counts": {"waxed_vellum": 1, "mire_reed": 1, "sunk_knot": 2},
	})
	var sallow_copy := String(view.call("_preview_copy", sallow_preview))
	_check("4 layers — base 3, added layer 4." in sallow_copy
		and "longer commitment" in sallow_copy,
		"four-layer Sallow preview makes its longer commitment explicit", sallow_copy)

	var approach_preview := ChartsData.preview_table({
		"grid": {"c": "atlas_folio", "nw": "cold_track", "n": "cold_track",
			"w": "climbing_cord", "e": "climbing_cord"}, "ink_rail": ["refined_ink"],
	}, {
		"level": 21, "first_snug_returned": true,
		"known_recipe_ids": ["summit_approach"],
		"material_counts": {"atlas_folio": 1, "cold_track": 2, "climbing_cord": 2,
			"refined_ink": 1, "hedge_ink": 4},
	})
	var approach_copy := String(view.call("_preview_copy", approach_preview))
	_check(String(approach_preview.get("recipe_id", "")) == "summit_approach"
		and bool(approach_preview.get("commit_ready", false))
		and (approach_preview.get("depth_contract", {}) as Dictionary).is_empty()
		and "Refined Ink" in approach_copy and "Road depth" not in approach_copy,
		"paired Crownward cords resolve the no-boss approach with visible Refined Ink, not generic Deepening",
		approach_preview)

	var reprise_state: Dictionary = CampaignData.empty_state()
	var reprise_chapter: Dictionary = reprise_state.chapters.first_knot
	reprise_chapter.cleared = true
	var reprise_preview := ChartsData.preview_table({
		"grid": {"c": "field_parchment", "n": "hedge_sprig", "w": "loop_cord",
			"e": "loop_cord", "s": "thorn_essence"}, "ink_rail": ["hedge_ink"],
	}, {
		"level": 21, "first_snug_returned": true,
		"known_recipe_ids": ["first_knot_reprise"],
		"material_counts": {"field_parchment": 1, "hedge_sprig": 1,
			"loop_cord": 2, "thorn_essence": 1, "hedge_ink": 2},
		"campaign_state": reprise_state,
	})
	var reprise_copy := String(view.call("_preview_copy", reprise_preview))
	var encounter: Dictionary = reprise_preview.get("encounter_contract", {})
	_check(String(reprise_preview.get("recipe_id", "")) == "first_knot_reprise"
		and String(encounter.get("boss_kind", "")) == "hedgemother"
		and String(encounter.get("reward_family_id", "")) == "first_knot_heirlooms"
		and "Layer 2 guarantees The Hedgemother." in reprise_copy
		and "First-Knot Heirlooms" in reprise_copy
		and "spent normally" in reprise_copy and "no story-Seal refund" in reprise_copy,
		"First Knot reprise preview names its boss, heirloom family, and normal-spend replay terms",
		{"preview": reprise_preview, "copy": reprise_copy})

	# Canonical domain entries drive all four visual states. The UI displays the
	# records but never reconstructs identity from the authored recipe registry.
	game.hear_chart_rumour("atlas_deep_hollow")
	game.add_material("waxed_vellum", 1)
	game.add_material("mire_reed", 1)
	game.add_material("sunk_knot", 1)
	var state_pages: Array = bench.call("codex_pages")
	var by_state := {}
	for page_v in state_pages:
		var page: Dictionary = page_v
		var state_name := String(page.get("state", "unknown"))
		if not by_state.has(state_name):
			by_state[state_name] = page
	_check(by_state.has("known") and by_state.has("rumoured")
		and by_state.has("attemptable") and by_state.has("unknown"),
		"Codex receives Known, Rumoured, redacted Attemptable, and Unknown pages",
		by_state.keys())
	var rumoured_page: Dictionary = by_state.get("rumoured", {})
	var attemptable_page: Dictionary = by_state.get("attemptable", {})
	var unknown_page: Dictionary = by_state.get("unknown", {})
	_check((rumoured_page.get("output", {}) as Dictionary).is_empty()
		and (rumoured_page.get("ghost_draft", {}) as Dictionary).is_empty()
		and (rumoured_page.get("pattern", {}) as Dictionary).is_empty()
		and not (rumoured_page.get("clues", []) as Array).is_empty()
		and (attemptable_page.get("output", {}) as Dictionary).is_empty()
		and (attemptable_page.get("ghost_draft", {}) as Dictionary).is_empty()
		and (attemptable_page.get("pattern", {}) as Dictionary).is_empty()
		and (attemptable_page.get("required_inks", []) as Array).is_empty()
		and String(attemptable_page.get("source", "")) == ""
		and (unknown_page.get("output", {}) as Dictionary).is_empty()
		and (unknown_page.get("ghost_draft", {}) as Dictionary).is_empty()
		and (unknown_page.get("clues", []) as Array).is_empty(),
		"non-Known pages remain redacted at the UI adapter seam")
	view.call("set_source_mode", "codex")
	bench.call("close_codex_page")
	await _frames()
	var rendered_state_text := ""
	for page_button_v in view.find_children("CodexPage_*", "", true, false):
		rendered_state_text += " " + String((page_button_v as Button).text)
	_check("Known" in rendered_state_text and "Rumoured" in rendered_state_text
		and "Attemptable" in rendered_state_text and "Unknown" in rendered_state_text,
		"Codex list visibly labels every knowledge state without colour alone",
		rendered_state_text)
	bench.call("open_codex_page", String(attemptable_page.get("recipe_id", "")))
	await _frames()
	var attemptable_detail := view.find_child("CodexDetail", true, false) as RichTextLabel
	var attemptable_copy := String(attemptable_detail.text) if attemptable_detail != null else ""
	_check(attemptable_detail != null and "Sallow" not in attemptable_copy
		and "Mire Reed" not in attemptable_copy and "Waxed" not in attemptable_copy
		and "Sunk Knot" not in attemptable_copy,
		"Attemptable detail explains readiness without leaking identity or makings",
		attemptable_copy)
	var unknown_opened := bool(bench.call("open_codex_page",
		String(unknown_page.get("recipe_id", ""))))
	await _frames()
	var unknown_detail := view.find_child("CodexDetail", true, false) as RichTextLabel
	var unknown_copy := String(unknown_detail.text) if unknown_detail != null else ""
	_check(unknown_opened and unknown_detail != null and "Briar" not in unknown_copy
		and "Thorn" not in unknown_copy and "Stitched" not in unknown_copy,
		"Unknown detail remains a blank silhouette with no recipe leaks", unknown_copy)

	bench.queue_free()
	await _frames(3)
	_check(int(game.modal_count) == modal_before,
		"external free releases modal ownership exactly once", game.modal_count)
	host.queue_free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("CHART TABLE UI: PASS")
		quit(0)
	else:
		print("CHART TABLE UI: FAIL (%d failures)" % _failures.size())
		quit(1)
