extends Control
class_name PlayerBench

onready var info = $Info
onready var HPCur = $Info/HPCur
onready var sprite = $Info/Sprite

func setup(player: Player) -> void:
	if player != null:
		HPCur.text = str(player.hp_max)
		sprite.frame = player.frame
		info.show()
	else:
		info.hide()
