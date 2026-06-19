extends Node

# B4 — player settings (volume, fullscreen, mute), persisted to a small config
# and applied on boot. Separate from the game SAVE (these are preferences, not
# progress). Autoload name: Settings.

const PATH := "user://wyrd_settings.cfg"

var master_volume := 1.0      # 0..1 linear, applied to the Master audio bus
var fullscreen := false
# (mute is owned by game.gd — F10 + the save — to keep one source of truth.)

func _ready() -> void:
	load_settings()
	apply_all()

func apply_all() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, clampf(master_volume, 0.0, 1.0))))
	# Headless has no real window; guard the mode change.
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED)

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, master_volume)))
	save_settings()

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if on
			else DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master_volume", master_volume))
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))

func save_settings() -> void:
	if OS.get_environment("WYRD_NO_SAVE") != "":
		return
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)
