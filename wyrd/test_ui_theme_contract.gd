extends SceneTree

# Spec 59 Slice 1 — semantic color roles must never regress into the old
# cream-on-cream Maple/Enamel seam. This is intentionally small and headless;
# visual layout/focus contracts arrive with the component lab.

const Ui = preload("res://scripts/ui/wyrd_ui.gd")
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


func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 \
		else pow((value + 0.055) / 1.055, 2.4)


func _luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) \
		+ 0.7152 * _linear_channel(color.g) \
		+ 0.0722 * _linear_channel(color.b)


func _contrast(a: Color, b: Color) -> float:
	var lighter := maxf(_luminance(a), _luminance(b))
	var darker := minf(_luminance(a), _luminance(b))
	return (lighter + 0.05) / (darker + 0.05)


func _run() -> void:
	_check(Ui.TEXT_ON_PAPER != Ui.TEXT_ON_DARK,
		"paper and dark surfaces have distinct text roles")
	_check(Ui.INK == Ui.TEXT_ON_PAPER,
		"legacy INK resolves to the paper role while legacy modals use paper")
	_check(Ui.PARCHMENT == Ui.TEXT_ON_PAPER,
		"parchment alias cannot regress to cream-on-cream")
	_check(_contrast(Ui.TEXT_ON_PAPER, Ui.MAPLE_CREAM) >= 4.5,
		"primary paper text meets 4.5:1 against the live Maple paper")
	_check(_contrast(Ui.TEXT_ON_PAPER_DIM, Ui.MAPLE_CREAM) >= 4.5,
		"secondary paper text meets 4.5:1 against the live Maple paper")
	_check(_contrast(Ui.TEXT_ON_DARK, Ui.KIT_PLATE) >= 4.5,
		"primary dark-surface text meets 4.5:1 against the moss/enamel face")
	_check(_contrast(Ui.TEXT_ON_DARK_DIM, Ui.KIT_PLATE) >= 4.5,
		"secondary dark-surface text meets 4.5:1 against the moss/enamel face")
	_check(Tokens.TYPE_BODY >= 16 and Tokens.TYPE_DIALOGUE >= 18,
		"Field Journal body and dialogue type floors are explicit")
	_check(Tokens.HIT_TARGET >= 48,
		"Field Journal minimum interactive target is at least 48px")

	var theme := load("res://themes/wayfinder_theme.tres") as Theme
	_check(theme != null, "Wayfinder Theme resource loads")
	if theme != null:
		for type_name in ["Display", "PageTitle", "SectionTitle", "Body",
				"Caption", "DialogueBody", "RowTitle", "RowSubtitle", "RowTrailing",
				"PaperSurface", "WalnutFrame",
				"JournalFrame", "JournalFrameContainer", "MossWell", "ItemWell",
				"CharmSocketButton",
				"PrimaryButton", "SecondaryButton", "QuietButton", "TabButton",
				"JournalRowButton", "ChoiceCardButton", "JournalRowSelected", "DestructiveButton",
				"SystemCheckBox", "SystemSlider"]:
			_check(theme.get_type_list().has(type_name),
				"Wayfinder Theme defines %s variation" % type_name)
		_check(theme.get_stylebox("panel", "JournalFrameContainer") is StyleBoxTexture,
			"JournalFrameContainer owns painterly nine-slice chrome")
		_check(theme.get_stylebox("pressed", "TabButton") is StyleBoxTexture,
			"selected tabs own a painterly state plate")
		_check(theme.get_stylebox("normal", "QuietButton") is StyleBoxTexture,
			"quiet actions own a reusable painterly plate")
		_check(theme.get_stylebox("panel", "ItemWell") is StyleBoxTexture,
			"item wells own reusable painterly nine-slice furniture")
		_check(theme.get_stylebox("normal", "CharmSocketButton") is StyleBoxTexture,
			"charm sockets reuse the painterly item-well furniture")
		_check(theme.get_stylebox("normal", "JournalRowButton") != null,
			"journal rows own shared normal/hover/focus furniture")
		_check(theme.get_stylebox("slider", "SystemSlider") != null \
				and theme.get_stylebox("grabber_area", "SystemSlider") != null,
			"system volume owns a readable Field Journal track and fill")
		_check(_contrast(theme.get_color("font_focus_color", "SystemCheckBox"),
				Tokens.PAPER_RAISED) >= 4.5,
			"focused system checks keep dark text on paper")
		var row_disabled := theme.get_stylebox("disabled", "JournalRowButton") \
			as StyleBoxFlat
		_check(row_disabled != null and _contrast(Tokens.TEXT_ON_PAPER,
				row_disabled.bg_color) >= 4.5,
			"disabled journal rows preserve readable paper-text contrast")
		_check(theme.get_font_size("font_size", "Body") >= 16,
			"Theme Body variation preserves the 16px floor")
		_check(theme.get_font_size("font_size", "DialogueBody") >= 18,
			"Theme DialogueBody variation preserves the 18px floor")

	if _failures.is_empty():
		print("UI THEME CONTRACT: PASS")
		quit(0)
	else:
		print("UI THEME CONTRACT: FAIL (%d failures)" % _failures.size())
		quit(1)
