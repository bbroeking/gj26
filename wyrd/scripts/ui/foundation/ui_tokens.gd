class_name UiTokens
extends RefCounted

# Spec 59 — semantic foundation for the Field Journal UI. Names describe the
# surface or meaning they serve; callers must not infer a text color from a
# generic "ink" token.

const PAPER := Color("e9d9b4")
const PAPER_RAISED := Color("f3e7ca")
const TEXT_ON_PAPER := Color("38281d")
const TEXT_ON_PAPER_DIM := Color("6d5945")

const WALNUT := Color("5a3824")
const WALNUT_DEEP := Color("2d1d16")
const MOSS := Color("314a2b")
const MOSS_HOVER := Color("42603a")
const MOSS_PRESSED := Color("263b22")
const TEXT_ON_DARK := Color("f4e8cb")
const TEXT_ON_DARK_DIM := Color("c8bfa8")

const SAGE := Color("6f8f57")
const TERRACOTTA := Color("b9563f")
const GOLD_MUTED := Color("b68a3a")
const SCRIM := Color(0.078, 0.063, 0.047, 0.58)

const DISABLED_SURFACE := Color("9a907b")
const DISABLED_TEXT_ON_PAPER := Color("6b6254")
const DISABLED_TEXT_ON_DARK := Color("d2c9b5")

const SPACE_1 := 4
const SPACE_2 := 8
const SPACE_3 := 12
const SPACE_4 := 16
const SPACE_5 := 24
const SPACE_6 := 32
const SPACE_7 := 48

const TYPE_DISPLAY := 32
const TYPE_PAGE_TITLE := 30
const TYPE_SECTION := 21
const TYPE_DIALOGUE := 19
const TYPE_BODY := 16
const TYPE_CAPTION := 14

const HIT_TARGET := 48
const SAFE_GUTTER := 24
const MODAL_MAX_WIDTH_RATIO := 0.88
const MODAL_MAX_HEIGHT_RATIO := 0.86

const MOTION_FAST := 0.08
const MOTION_NORMAL := 0.12
const MOTION_SLOW := 0.20


static func linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 \
		else pow((value + 0.055) / 1.055, 2.4)


static func luminance(color: Color) -> float:
	return 0.2126 * linear_channel(color.r) \
		+ 0.7152 * linear_channel(color.g) \
		+ 0.0722 * linear_channel(color.b)


static func contrast(a: Color, b: Color) -> float:
	var lighter := maxf(luminance(a), luminance(b))
	var darker := minf(luminance(a), luminance(b))
	return (lighter + 0.05) / (darker + 0.05)


static func modal_max_size(viewport_size: Vector2) -> Vector2:
	return Vector2(
		maxf(0.0, viewport_size.x - SAFE_GUTTER * 2.0) * MODAL_MAX_WIDTH_RATIO,
		maxf(0.0, viewport_size.y - SAFE_GUTTER * 2.0) * MODAL_MAX_HEIGHT_RATIO)


static func is_compact(viewport_size: Vector2) -> bool:
	return viewport_size.x < 1280.0 or viewport_size.y < 720.0
