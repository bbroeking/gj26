extends SceneTree

# Spec 59 component contract: every screen receives the same semantic row
# hierarchy and state language instead of rebuilding or custom-drawing it.

const JournalRow = preload("res://scripts/ui/components/journal_list_row.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _run() -> void:
	var host := Control.new()
	host.theme = load("res://themes/wayfinder_theme.tres")
	root.add_child(host)

	var normal := JournalRow.new()
	normal.setup({
		"title": "Wild Herb",
		"subtitle": "In Satchel: 4",
		"detail": "Restores vigor when brewed.",
		"trailing": "3g",
		"badge": "Buy",
		"glyph": "♧",
	})
	host.add_child(normal)
	_check(normal is Button and normal.focus_mode == Control.FOCUS_ALL,
		"journal row is a native focusable Button")
	_check(normal.custom_minimum_size.y >= Tokens.HIT_TARGET,
		"journal row meets the 48px target floor")
	_check(normal.find_child("Title", true, false) is Label,
		"journal row exposes a semantic title")
	_check(normal.find_child("Subtitle", true, false) is Label,
		"journal row exposes a semantic subtitle")
	_check(normal.find_child("Detail", true, false) is Label \
			and normal.custom_minimum_size.y == 84.0,
		"journal row expands into a detail variant without a second component")
	_check(normal.find_child("Trailing", true, false) is Label,
		"journal row exposes its consequence")
	_check(normal.find_child("IconWell", true, false) is PanelContainer,
		"journal row owns the shared painted icon well")

	var selected := JournalRow.new()
	selected.setup({"title": "Selected", "state": JournalRow.RowState.SELECTED})
	host.add_child(selected)
	var selected_mark := selected.find_child("StateMark", true, false) as Label
	_check(selected.theme_type_variation == &"JournalRowSelected",
		"selected row uses the shared selected furniture")
	_check(selected_mark != null and selected_mark.visible and selected_mark.text == "✓",
		"selected row pairs sage fill with a non-color check mark")

	var unavailable := JournalRow.new()
	unavailable.setup({
		"title": "Bogiron Ore",
		"badge": "Need 4g",
		"state": JournalRow.RowState.DISABLED,
	})
	host.add_child(unavailable)
	var disabled_reason := unavailable.find_child("StateBadge", true, false) as Label
	_check(unavailable.disabled, "unavailable row uses native disabled semantics")
	_check(disabled_reason != null and disabled_reason.text == "Need 4g",
		"unavailable row states its disabled reason")

	host.queue_free()
	if _failures.is_empty():
		print("JOURNAL LIST ROW CONTRACT: PASS")
		quit(0)
	else:
		print("JOURNAL LIST ROW CONTRACT: FAIL (%d failures)" % _failures.size())
		quit(1)
