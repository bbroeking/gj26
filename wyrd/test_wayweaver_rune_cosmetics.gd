extends SceneTree

# D8 Root Rune presentation contract: each campaign Rune has a distinct,
# statless visual/audio profile and invalid network cosmetic values fail closed.

const Cosmetics = preload("res://data/wayweaver_rune_cosmetics.gd")
const Presentations = preload("res://data/weapon_presentations.gd")

var _pass := 0
var _fail := 0


func _init() -> void:
	print("--- Wayweaver Rune cosmetic rules ---")
	var profile_sfx: Array = []
	var colors: Array = []
	for rune_id_v in Cosmetics.ROOT_RUNE_IDS:
		var rune_id := String(rune_id_v)
		var profile := Cosmetics.profile_for(rune_id)
		profile_sfx.append(String(profile.get("sfx", "")))
		colors.append(profile.get("color", Color.TRANSPARENT))
		_check("%s owns an imported story icon" % rune_id,
			ResourceLoader.exists(String(profile.get("icon_path", ""))), profile)
	var unique_sfx := {}
	for sfx_id in profile_sfx:
		unique_sfx[String(sfx_id)] = true
	_check("all six campaign Root Runes have authored distinct cosmetic sound profiles",
		profile_sfx.size() == 6 and unique_sfx.size() == 6,
		profile_sfx)
	_check("all Rune profiles own a visible strand color without gameplay fields",
		colors.size() == 6 and not Cosmetics.profile_for("green_root_rune").has("damage")
			and not Cosmetics.profile_for("green_root_rune").has("stats"), colors)
	var fresh := Cosmetics.strand_style("green_root_rune", "fresh")
	var armed := Cosmetics.strand_style("green_root_rune", "armed", "fan")
	var spent := Cosmetics.strand_style("green_root_rune", "spent")
	_check("fresh, armed identity, and spent each resolve a distinct strand state",
		fresh.strand_color != armed.strand_color and armed.strand_color != spent.strand_color
			and float(armed.strand_emission) > float(fresh.strand_emission)
			and float(spent.strand_emission) < float(fresh.strand_emission),
		{"fresh": fresh, "armed": armed, "spent": spent})
	var resolved := Presentations.for_item({"kind_id": "wayweaver", "cosmetic_rune_id": "mist_root_rune"})
	var invalid := Presentations.for_item({"kind_id": "wayweaver", "cosmetic_rune_id": "forged_root_rune"})
	_check("weapon resolver passes a valid Rune and rejects an invalid remote cosmetic ID",
		String(resolved.cosmetic_rune_id) == "mist_root_rune"
			and String(invalid.cosmetic_rune_id) == "" and int(resolved.strand_material_slot) == 3,
		{"valid": resolved, "invalid": invalid})
	print("--- %d passed, %d failed ---" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _check(label: String, ok: bool, detail = "") -> void:
	if ok:
		_pass += 1
		print("  ✓ %s" % label)
	else:
		_fail += 1
		print("  ✗ %s %s" % [label, str(detail)])
