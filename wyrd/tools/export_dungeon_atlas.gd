extends SceneTree

# Read-only atlas exporter. It runs the production DungeonGen against stable
# representative Charts and emits a compact JSON payload for design review.
const DungeonGenScript = preload("res://scripts/dungeon_gen.gd")
const ChartsData = preload("res://data/charts.gd")

const ATLAS_TEMPLATES := [
	"snug", "tier_1", "hollow", "briar_maze", "mire", "summit",
	"pale_veins", "ashen_bough", "root_below",
]

const ATLAS_SEEDS := {
	"snug": 1101, "tier_1": 2202, "hollow": 3303,
	"briar_maze": 4404, "mire": 5505, "summit": 6606,
	"pale_veins": 7707, "ashen_bough": 8808, "root_below": 9909,
}

# Representative good Affixes make the optional gathering layer visible. They
# do not replace each biome's native guarantees.
const SHOWCASE_AFFIXES := {
	"tier_1": [{"id": "bramble_bloom", "good": true}],
	"hollow": [
		{"id": "mineral_vein", "good": true},
		{"id": "wood_grove", "good": true},
	],
	"briar_maze": [
		{"id": "bramble_bloom", "good": true},
		{"id": "mineral_vein", "good": true},
	],
	"mire": [{"id": "herbal_patch", "good": true}],
}

const SPAWN_TABLES := {
	"snug": [["rat", 70], ["skeleton", 30]],
	"hollow": [["skeleton", 45], ["rat", 20], ["bramble_imp", 20],
		["ghost", 15], ["warden", 10]],
	"briar_maze": [["bramble_imp", 50], ["hedge_sprite", 30],
		["skitterling", 20]],
	"crypt": [["skeleton", 40], ["rat", 25], ["ghost", 20],
		["hedge_sprite", 15], ["warden", 10], ["barrow_brute", 8]],
	"summit": [["skeleton", 30], ["ghost", 30], ["barrow_brute", 22],
		["warden", 18]],
	"mire": [["bog_wisp", 32], ["hedge_sprite", 26], ["bramble_imp", 24],
		["skitterling", 18]],
}


func _init() -> void:
	var maps: Array = []
	for template_id in ATLAS_TEMPLATES:
		maps.append(_export_template(template_id))
	print("ATLAS_JSON_BEGIN")
	print(JSON.stringify({
		"generated_at": "2026-07-19",
		"maps": maps,
		"pipeline": [
			"scatter", "separate", "delaunay", "mst_and_loops",
			"topology_semantics", "carve", "dress",
		],
		"ownership": {
			"space": "DungeonGen: frozen before loading",
			"gather": "DungeonGen: exact tiles and rolled tiers",
			"creatures": "LayoutLoader: room-driven packs after loading",
			"items": "Drops: rolled on kill/open; not frozen in layout",
		},
	}))
	print("ATLAS_JSON_END")
	quit()


func _export_template(template_id: String) -> Dictionary:
	var template: Dictionary = ChartsData.TEMPLATES[template_id]
	var cfg: Dictionary = (template.get("gen", {}) as Dictionary).duplicate(true)
	cfg["scope"] = String(template.get("scope", "crypt"))
	cfg["template_id"] = template_id
	cfg["tier"] = int(template.get("tier", 1))
	cfg["affixes"] = (SHOWCASE_AFFIXES.get(template_id, []) as Array).duplicate(true)
	var layout: Dictionary = DungeonGenScript.generate(int(ATLAS_SEEDS[template_id]), cfg)
	var rooms: Array = []
	var enemy_total := 0
	var density := float(cfg.get("enemy_density", 1.0))
	for room_v in layout.get("rooms", []):
		var room: Dictionary = room_v
		var role := String(room.get("role", "combat"))
		var depth := int(room.get("depth", 0))
		var pack := 0
		match role:
			"combat": pack = 4 + clampi(depth / 2, 0, 6)
			"treasure": pack = 1
			"shrine": pack = 1 # runtime rolls 0..1; atlas shows the ceiling
			"setpiece": pack = 2
		if template_id == "snug" and role == "combat":
			pack = 1
		elif pack > 0 and density != 1.0:
			pack = maxi(1, roundi(pack * density))
		enemy_total += pack
		rooms.append({
			"id": int(room.get("id", -1)), "x": int(room.x), "y": int(room.y),
			"w": int(room.w), "h": int(room.h), "role": role,
			"theme": String(room.get("theme", "")), "depth": depth,
			"difficulty": snappedf(float(room.get("difficulty", 0.0)), 0.01),
			"critical": bool(room.get("critical", false)), "pack": pack,
		})
	var content: Array = []
	var gather_counts := {"herb": 0, "ore": 0, "wood": 0}
	for decor_v in layout.get("decor", []):
		var decor: Dictionary = decor_v
		var kind := String(decor.get("kind", ""))
		var category := ""
		if kind == "forage_node":
			category = "herb"
		elif kind == "ore_rock":
			category = "ore"
		elif kind == "log_pile":
			category = "wood"
		elif kind == "chest" or String(decor.get("interact_role", "")) == "treasure":
			category = "item"
		elif String(decor.get("interact_role", "")) == "shrine":
			category = "shrine"
		if category == "":
			continue
		if gather_counts.has(category):
			gather_counts[category] = int(gather_counts[category]) + 1
		content.append({
			"category": category, "kind": kind,
			"item": String(decor.get("item", "")),
			"tier": String(decor.get("herb_tier", decor.get("ore_tier", ""))),
			"x": int(decor.x), "y": int(decor.y),
			"room_id": int(decor.get("room_id", -1)),
			"source": String(decor.get("source", "biome")),
		})
	# Horizontal floor runs preserve the exact raster while keeping the atlas
	# payload compact enough to inspect inline.
	var floor_runs: Array = []
	for y in layout.grid.size():
		var row: Array = layout.grid[y]
		var x := 0
		while x < row.size():
			if String(row[x]) != "floor":
				x += 1
				continue
			var x0 := x
			while x < row.size() and String(row[x]) == "floor":
				x += 1
			floor_runs.append([x0, x - 1, y])
	var scope := String(layout.get("scope", "crypt"))
	return {
		"id": template_id, "name": String(template.get("name", template_id)),
		"scope": scope, "tier": int(template.get("tier", 1)),
		"seed": int(ATLAS_SEEDS[template_id]), "grid": layout.grid.size(),
		"floor_runs": floor_runs, "rooms": rooms,
		"edges": layout.get("room_edges", []),
		"critical": layout.get("critical_room_ids", []),
		"corridor_widths": layout.get("corridor_widths", {}),
		"entry_room": int(layout.get("entry_room_id", 0)),
		"boss_room": int(layout.get("boss_room_id", -1)),
		"boss_kind": String(layout.get("bossKind", "")),
		"content": content, "gather_counts": gather_counts,
		"enemy_total_ceiling": enemy_total,
		"spawn_mix": SPAWN_TABLES.get(scope, SPAWN_TABLES.get("crypt", [])),
		"affixes": cfg.affixes,
		"score": snappedf(float((layout.get("score", {}) as Dictionary).get("total", 0.0)), 0.01),
	}
