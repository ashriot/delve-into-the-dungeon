extends Control

onready var txt = $Text/Text

func init(parent, text) -> void:
	execute(parent, text)
	animate("Bounce")

func text(parent, text) -> void:
	execute(parent, text)
	animate("Up")

func display(parent, text) -> void:
	execute(parent, text)
	animate("Display")

func execute(parent, text) -> void:
	$Text/TextL.text = text
	$Text/TextR.text = text
	$Text/TextU.text = text
	$Text/TextD.text = text
	$Text/Text.text = text
	parent.add_child(self)
	var size = txt.rect_size.x
	rect_global_position.x = clamp(rect_global_position.x, \
		-31 + size / 2, (get_viewport_rect().size.x - size) / 2 + 3)
	print("viewport max: ", get_viewport_rect().size.x)
	print("x pos: ", rect_global_position.x, " size: ", size)

func animate(dir: String, duration = 1.0) -> void:
	var anim = $AnimationPlayer
	anim.playback_speed = (1 / GameManager.spd) * 1 / float(duration)
	anim.play(dir)
	yield(anim, "animation_finished")
	self.queue_free()
