extends Node

export var mute: = false setget set_mute
export var vol_bgm: = 0.0
export var vol_sfx: = 0.0

onready var bgm: = $bgm
onready var sfx1: = $sfx1
onready var sfx2: = $sfx2
onready var sfx3: = $sfx3
onready var sfx4: = $sfx4
onready var sfx5: = $sfx5

var bgm_playing: String

func _ready() -> void:
	set_bgm_volume()
	set_sfx_volume()

func play_bgm(name: String, pos: = 0) -> void:
	if name == "": return
	bgm_playing = name
	if mute: return
	bgm.stream = load("res://assets/audio/bgm/" + name + ".ogg")
	bgm.play(pos)

func stop_bgm() -> void:
	bgm.stop()

func play_sfx(name: String) -> void:
	if name == "": return
	if (!sfx1.playing):
		sfx1.stream = load("res://assets/audio/sfx/" + name + ".wav")
		sfx1.play()
	elif (!sfx2.playing):
		sfx2.stream = load("res://assets/audio/sfx/" + name + ".wav")
		sfx2.play()
	elif (!sfx3.playing):
		sfx3.stream = load("res://assets/audio/sfx/" + name + ".wav")
		sfx3.play()
	elif (!sfx4.playing):
		sfx4.stream = load("res://assets/audio/sfx/" + name + ".wav")
		sfx4.play()
	elif (!sfx5.playing):
		sfx5.stream = load("res://assets/audio/sfx/" + name + ".wav")
		sfx5.play()
	else:
		sfx1.stop()
		sfx1.stream = load("res://assets/audio/sfx/" + name + ".wav")
		sfx1.play()

func get_pos() -> int:
	if bgm.playing: return bgm.get_playback_position()
	return 0

func back() -> void:
	play_sfx("back")

func click() -> void:
	play_sfx("click")

func confirm() -> void:
	play_sfx("confirm")

func select() -> void:
	play_sfx("select")

func steps() -> void:
	play_sfx("footsteps")

func set_bgm_volume() -> void:
	vol_bgm = -5
	bgm.volume_db = vol_bgm

func set_sfx_volume() -> void:
	sfx1.volume_db = vol_sfx
	sfx2.volume_db = vol_sfx
	sfx3.volume_db = vol_sfx
	sfx4.volume_db = vol_sfx
	sfx5.volume_db = vol_sfx

func set_mute(value) -> void:
	mute = value
	if bgm == null: return
	if mute: stop_bgm()
	else: play_bgm(bgm_playing)
