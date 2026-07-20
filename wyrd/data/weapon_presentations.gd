class_name WeaponPresentations
extends RefCounted

const RuneCosmetics := preload("res://data/wayweaver_rune_cosmetics.gd")

# D8 Slice 3 — the one authority for the visible weapon that rides the
# existing LeftHand socket.  Gameplay reads ItemsData/Equipment; this record is
# intentionally presentation-only, so a missing model can always fall back to
# the familiar bow without changing equipment ownership.

const FALLBACK_KIND := "default_bow"

const PRESENTATIONS := {

	FALLBACK_KIND: {
		"scene_path": "res://models/prop_bow_v1.glb",
		# prop_bow is 1.902 m on its long axis. Half scale gives the chibi a
		# readable ~0.95 m shortbow instead of a weapon taller than her body.
		"scale": 0.50,
		# glTF conversion already maps the authored long axis to Godot UP. The
		# old +90 X correction laid the bow flat in the firing plane.
		"rotation_degrees": Vector3.ZERO,
		"hand_offset": Vector3(0.12, 0.06, 0.05),
		"draw_forward": 0.32,
		"tint": Color(0.40, 0.28, 0.18),
		"rune_cosmetic": "",
	},
	"wayweaver": {
		"scene_path": "res://models/wayweaver_v1.glb",
		# Wayweaver's authored long axis is 2.392 m; normalize it to the same
		# ~0.96 m held silhouette as the familiar bow.
		"scale": 0.40,
		"rotation_degrees": Vector3.ZERO,
		"hand_offset": Vector3(0.12, 0.06, 0.05),
		"draw_forward": 0.32,
		# The Blender GLB owns its dark-waysteel/root-sap palette.  Do not tint
		# it with the fallback bow's blanket brown material override.
		"tint": null,
		"rune_cosmetic": "wayweaver_bright_strand",
	},
}


static func for_item(item) -> Dictionary:
	var kind_id := ""
	if item is Dictionary:
		kind_id = String((item as Dictionary).get("kind_id", (item as Dictionary).get("kind", "")))
	var raw = PRESENTATIONS.get(kind_id, PRESENTATIONS[FALLBACK_KIND])
	var result := (raw as Dictionary).duplicate(true)
	if kind_id == "wayweaver" and item is Dictionary:
		var rune_id := String((item as Dictionary).get("cosmetic_rune_id", ""))
		# Invalid/legacy cosmetic IDs never become a second source of item truth.
		# They simply resolve to the authored neutral strand presentation.
		result["cosmetic_rune_id"] = rune_id if RuneCosmetics.is_valid_rune(rune_id) else ""
		result["strand_material_slot"] = 3 # the GLB's sole LivingStrand seam
	return result


static func is_wayweaver(item) -> bool:
	return item is Dictionary and String((item as Dictionary).get("kind_id",
		(item as Dictionary).get("kind", ""))) == "wayweaver"
