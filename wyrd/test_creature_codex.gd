extends SceneTree

const CreatureCodexData = preload("res://data/creature_codex.gd")
const LayoutLoader = preload("res://scripts/layout_loader.gd")
const EnemyProjectile = preload("res://scripts/enemy_projectile.gd")
const ChestScript = preload("res://scripts/chest.gd")
const Tokens = preload("res://scripts/ui/foundation/ui_tokens.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _frames(count := 4) -> void:
	for _index in count:
		await process_frame

func _run() -> void:
	var enemy_ids: Array = LayoutLoader.ENEMY_KINDS.keys()
	var boss_ids: Array = LayoutLoader.BOSS_KINDS.keys()
	_check(CreatureCodexData.missing_ids(enemy_ids).is_empty(),
		"every standard creature has a Codex page")
	_check(CreatureCodexData.missing_ids(boss_ids).is_empty(),
		"every named creature has a Codex page")
	_check(CreatureCodexData.ORDER.size() == CreatureCodexData.ENTRIES.size(),
		"Codex order contains every page exactly once")
	for row_v in CreatureCodexData.ordered_entries():
		var row: Dictionary = row_v
		_check(not String(row.get("role", "")).is_empty() \
				and not String(row.get("region", "")).is_empty() \
				and not String(row.get("projectile", "")).is_empty() \
				and not String(row.get("quote", "")).is_empty(),
			"%s has complete Nature, Roads, Battle sign, and lore" % String(row.id))
	var color_families := {}
	for kind_v in enemy_ids:
		var def: Dictionary = LayoutLoader.ENEMY_KINDS[kind_v]
		var color_v = def.get("projectile_color")
		_check(color_v is Color and (color_v as Color).a > 0.99,
			"%s owns an explicit opaque projectile color" % String(kind_v))
		if color_v is Color:
			color_families[(color_v as Color).to_html(false)] = true
		_check(float(def.get("proj_speed", 0.0)) > 0.0 \
				and int(def.get("proj_damage", 0)) > 0 \
				and float(def.get("projectile_telegraph", 0.0)) >= 0.6,
			"%s owns a fair explicit projectile profile" % String(kind_v))
	_check(color_families.size() >= 6,
		"the common cast spans at least six projectile color families")
	_check(bool(LayoutLoader.ENEMY_KINDS.ghost.get("ranged", false)) \
			and bool(LayoutLoader.ENEMY_KINDS.bog_wisp.get("ranged", false)),
		"ghosts and Bog Wisps keep their kiting identity")
	_check(bool(LayoutLoader.ENEMY_KINDS.warden.get("support", false)),
		"Wardens keep their pack-healing identity")
	_check(bool(LayoutLoader.ENEMY_KINDS.barrow_brute.get("bruiser", false)),
		"Barrow Brutes keep their heavy ring identity")
	for kind_v in boss_ids:
		var page: Dictionary = CreatureCodexData.entry(String(kind_v))
		_check(not String(page.get("role", "")).is_empty() \
				and not String(page.get("region", "")).is_empty() \
				and not String(page.get("projectile", "")).is_empty() \
				and not String(page.get("quote", "")).is_empty(),
			"%s has a complete named-creature page" % String(kind_v))
	_check(int(LayoutLoader.BOSS_KINDS.burrow_boar.get("projectile_every", -1)) == 0 \
			and int(LayoutLoader.BOSS_KINDS.wolf_alpha.get("projectile_every", -1)) == 0 \
			and int(LayoutLoader.BOSS_KINDS.knot_eater.get("projectile_every", -1)) == 0,
		"Boar, Wolf, and Knot-Eater preserve signature-only attack cadence")
	for kind_v in ["hedgemother", "hedgemother_queen", "barrow_jarl", "hearth_giant"]:
		var def: Dictionary = LayoutLoader.BOSS_KINDS[kind_v]
		_check(int(def.get("projectile_every", 0)) >= 3 \
				and def.get("projectile_color") is Color,
			"%s explicitly opts into a periodic colored cast" % String(kind_v))
	var tint := Color(0.21, 0.73, 0.38)
	var projectile := EnemyProjectile.new()
	projectile.setup(Vector3.ZERO, Vector3.FORWARD, 8.0, 3, tint)
	projectile.call("_ready")
	var orb := projectile.get_child(1) as MeshInstance3D
	var orb_mat := orb.material_override as StandardMaterial3D
	_check(orb_mat != null and orb_mat.albedo_color.is_equal_approx(tint),
		"projectile skin is applied before the orb enters the scene")
	projectile.free()

	var chest := ChestScript.new()
	root.add_child(chest)
	await _frames(2)
	_check(ChestScript.CHEST_GLB.resource_path.ends_with("prop_wayfinder_chest_v1.glb") \
			and chest.get_child_count() >= 5,
		"production Chest instantiates the authored Wayfinder prop")
	var scanner_shape := chest.get_child(0) as CollisionShape3D
	var scanner_sphere := scanner_shape.shape as SphereShape3D \
		if scanner_shape != null else null
	var solid := chest.get_node_or_null("Solid") as StaticBody3D
	var solid_shape := solid.get_child(0) as CollisionShape3D if solid != null else null
	var solid_cylinder := solid_shape.shape as CylinderShape3D \
		if solid_shape != null else null
	var prompt := chest.get_node_or_null("PromptLabel") as Label3D
	_check(scanner_sphere != null and solid_cylinder != null \
			and solid_cylinder.radius < scanner_sphere.radius,
		"Wayfinder chest solid footprint stays inside its scanner reach")
	_check(prompt != null and prompt.position.y > solid_cylinder.height,
		"Wayfinder chest prompt sits clearly above the lid")
	var pile: Array = chest.interact(null)
	_check(pile.size() == 2 and chest.is_used(),
		"Wayfinder chest opens once and yields its two treasure rolls")
	_check((chest.interact(null) as Array).is_empty(),
		"an opened Wayfinder chest cannot pay twice")
	chest.queue_free()
	for child in root.get_children():
		if child is ItemPickup:
			child.queue_free()
	await _frames(2)

	root.size = Vector2i(1280, 720)
	var pause: CanvasLayer = load("res://scripts/ui/pause_menu.gd").new()
	root.add_child(pause)
	await _frames()
	var codex_button: Button = null
	for candidate in pause.find_children("*", "Button", true, false):
		if (candidate as Button).text == "Creature Codex":
			codex_button = candidate as Button
			break
	_check(codex_button != null, "Pause exposes the Creature Codex as a semantic Button")
	if codex_button != null:
		codex_button.pressed.emit()
	await _frames()
	var panel := pause.get_node_or_null("CreatureCodexPanel") as CanvasLayer
	_check(panel != null and paused, "Pause opens one Codex layer without resuming the road")
	var shell := panel.find_child("SystemShell", true, false) as Control if panel != null else null
	if shell != null:
		var rect := shell.get_global_rect()
		_check(rect.position.x >= 24.0 and rect.position.y >= 24.0 \
				and rect.end.x <= 1256.0 and rect.end.y <= 696.0,
			"Creature Codex stays inside the 1280x720 safe frame")
	else:
		_check(false, "Creature Codex uses the shared SystemFolio shell")
	var detail := panel.find_child("CreatureCodexDetail", true, false) as RichTextLabel \
		if panel != null else null
	_check(detail != null and detail.text.contains("Barrow Skeleton"),
		"Creature Codex opens on its first readable page")
	_check(detail != null and Tokens.contrast(
			detail.get_theme_color("default_color"), Tokens.PAPER_RAISED) >= 7.0,
		"Creature Codex detail uses high-contrast ink on paper")
	var wisp_page := panel.find_child("CreaturePage_bog_wisp", true, false) as Button \
		if panel != null else null
	if wisp_page != null:
		wisp_page.pressed.emit()
	await _frames(2)
	_check(detail != null and detail.text.contains("Bog Wisp") \
			and detail.text.contains("marsh-green"),
		"choosing a creature changes the visible Battle sign")
	_check(root.gui_get_focus_owner() != null \
			and panel != null and panel.is_ancestor_of(root.gui_get_focus_owner()),
		"Creature Codex assigns keyboard/controller focus inside its folio")
	var close_button := panel.find_child("CloseButton", true, false) as Button \
		if panel != null else null
	if close_button != null:
		close_button.pressed.emit()
	await _frames()
	_check(not is_instance_valid(panel) and is_instance_valid(pause) and paused,
		"closing Creature Codex returns one layer to the still-paused folio")
	pause.call("_close")
	await _frames(2)
	_check(not paused, "closing Pause after the Codex resumes the road")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("shutdown"):
		sfx.shutdown()
	await _frames(2)
	print("test_creature_codex: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	if ok:
		print("  PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
