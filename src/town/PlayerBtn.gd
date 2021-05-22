extends Button
class_name PlayerBtn

onready var sprite = $Sprite

func setup(player: Player) -> void:
	if player != null:
		text = player.name
		sprite.show()
		sprite.frame = player.frame
	else:
		text = "[Empty]"
		sprite.hide()
