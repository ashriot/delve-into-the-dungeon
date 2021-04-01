extends Control

func _ready() -> void:
	var anim = $AnimationPlayer
	yield(anim, "animation_finished")
	self.queue_free()

func init(parent, text) -> void:
	$Text/TextL.text = text
	$Text/TextR.text = text
	$Text/TextU.text = text
	$Text/TextD.text = text
	$Text/Text.text = text
	parent.add_child(self)
