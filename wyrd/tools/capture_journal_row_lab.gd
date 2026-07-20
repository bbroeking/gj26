extends SceneTree

# Deterministic Spec 59 component-lab capture for the shared row states. Run:
# WYRD_NO_SAVE=1 WYRD_CAPTURE_PATH=/tmp/wyrd_ui_component_rows.png \
#   godot --path . --resolution 1000x600 --script res://tools/capture_journal_row_lab.gd

const JournalRow = preload("res://scripts/ui/components/journal_list_row.gd")
const FocusPointer = preload("res://scripts/ui/components/focus_pointer.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("536345")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.theme = load("res://themes/wayfinder_theme.tres")
	root.add_child(backdrop)

	var shell := PanelContainer.new()
	shell.name = "JournalRowComponentLab"
	shell.theme_type_variation = &"JournalFrameContainer"
	shell.anchor_left = 0.5
	shell.anchor_top = 0.5
	shell.anchor_right = 0.5
	shell.anchor_bottom = 0.5
	shell.offset_left = -330.0
	shell.offset_top = -245.0
	shell.offset_right = 330.0
	shell.offset_bottom = 245.0
	backdrop.add_child(shell)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	shell.add_child(col)
	var title := Label.new()
	title.text = "Journal Row States"
	title.theme_type_variation = &"PageTitle"
	col.add_child(title)

	var models := [
		{
			"title": "Shortbow of Swiftness",
			"subtitle": "Rare Weapon",
			"trailing": "Equip",
			"badge": "Ready",
			"icon": load("res://assets/ui/items/shortbow.png"),
		},
		{
			"title": "Wild Herb",
			"subtitle": "In Satchel: 4",
			"trailing": "3g",
			"badge": "Buy",
			"state": JournalRow.RowState.SELECTED,
			"icon": load("res://assets/ui/field_journal/icons/wild_herb.png"),
		},
		{
			"title": "Bogiron Ore",
			"subtitle": "In Satchel: 2",
			"trailing": "7g",
			"badge": "Need 4g",
			"state": JournalRow.RowState.DISABLED,
			"icon": load("res://assets/ui/field_journal/icons/bogiron_ore.png"),
		},
		{
			"title": "Nothing to melt down",
			"subtitle": "Gear in your Pack will appear here.",
			"glyph": "⚒",
			"state": JournalRow.RowState.DISABLED,
		},
	]
	var first: Button = null
	for model in models:
		var row := JournalRow.new()
		row.setup(model)
		col.add_child(row)
		if first == null:
			first = row

	var focus_pointer := FocusPointer.new()
	focus_pointer.name = "ComponentLabFocusPointer"
	backdrop.add_child(focus_pointer)
	if first != null:
		first.grab_focus()
	for _frame in 8:
		await process_frame
	var image := root.get_texture().get_image()
	var output_path := OS.get_environment("WYRD_CAPTURE_PATH")
	if output_path == "":
		output_path = "/tmp/wyrd_ui_component_rows.png"
	var err := image.save_png(output_path)
	print("[component-lab] %s (err=%d)" % [output_path, err])
	quit(0 if err == OK else 1)
