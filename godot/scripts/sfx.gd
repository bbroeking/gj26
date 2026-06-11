extends Node

# Spec 26 — combat SFX player (autoloaded as `Sfx`). A small pool of
# AudioStreamPlayers so rapid hits don't cut each other off; per-play pitch
# jitter so repeats don't feel mechanical. Sound files (ElevenLabs-generated)
# live in res://audio/; if one is missing, play() is a graceful no-op.

const PATHS := {
	"fire":        "res://audio/fire.mp3",
	"hit":         "res://audio/hit.mp3",
	"crit":        "res://audio/crit.mp3",
	"death":       "res://audio/enemy_death.mp3",
	"pickup":      "res://audio/pickup.mp3",       # spec 27f
	"equip":       "res://audio/equip.mp3",        # spec 27f
	"inv_open":    "res://audio/inv_open.mp3",     # spec 27f
	# Spec 29 — interactable SFX. The files are deferred (the ElevenLabs
	# spend wasn't pre-approved); play() is a graceful no-op until they land.
	"chest_open":  "res://audio/chest_open.mp3",
	"shrine_bless": "res://audio/shrine_bless.mp3",
	"hearth_rest": "res://audio/hearth_rest.mp3",
	# Spec 30 — skill SFX. Files deferred (~$0.30 ElevenLabs spend pending).
	"skill_power": "res://audio/skill_power.mp3",
	"skill_multi": "res://audio/skill_multi.mp3",
	"skill_snare": "res://audio/skill_snare.mp3",
}
const POOL := 8

var _streams := {}
var _players: Array = []
var _next := 0

func _ready() -> void:
	for key in PATHS:
		if ResourceLoader.exists(PATHS[key]):
			_streams[key] = load(PATHS[key])
	for _i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func play(name: String, pitch_var := 0.07) -> void:
	if not _streams.has(name) or _players.is_empty():
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()
