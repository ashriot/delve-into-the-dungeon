extends Control

func init(parent, text) -> void:
	$Text/TextL.text = text
	$Text/TextR.text = text
	$Text/TextU.text = text
	$Text/TextD.text = text
	$Text/Text.text = text
	parent.add_child(self)
	animate("Bounce")

func text(parent, text) -> void:
	$Text/TextL.text = text
	$Text/TextR.text = text
	$Text/TextU.text = text
	$Text/TextD.text = text
	$Text/Text.text = text
	parent.add_child(self)
	animate("Up")

func animate(dir: String) -> void:
	var anim = $AnimationPlayer
	anim.play(dir)
	yield(anim, "animation_finished")
	self.queue_free()
