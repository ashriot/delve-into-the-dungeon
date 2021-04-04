extends Control

func init(parent, text) -> void:
	display(parent, text)
	animate("Bounce")

func text(parent, text) -> void:
	display(parent, text)
	animate("Up")

func display(parent, text) -> void:
	$Text/TextL.text = text
	$Text/TextR.text = text
	$Text/TextU.text = text
	$Text/TextD.text = text
	$Text/Text.text = text
	parent.add_child(self)
	rect_global_position.x = clamp(rect_global_position.x, 1, \
		get_viewport_rect().size.x - rect_size.x)

func animate(dir: String) -> void:
	var anim = $AnimationPlayer
	anim.playback_speed = 1 / GameManager.spd
	anim.play(dir)
	yield(anim, "animation_finished")
	self.queue_free()
