extends Control

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
	rect_global_position.x = clamp(rect_global_position.x, 1, \
		get_viewport_rect().size.x - rect_size.x)

func animate(dir: String, duration = 1.0) -> void:
	var anim = $AnimationPlayer
	anim.playback_speed = (1 / GameManager.spd) * 1 / float(duration)
	anim.play(dir)
	yield(anim, "animation_finished")
	self.queue_free()
