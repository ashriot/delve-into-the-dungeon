extends Control

func _ready() -> void:
	var anim = $AnimationPlayer
	yield(anim, "animation_finished")
	self.queue_free()

func init(parent, text) -> void:
	$Text.text = text
	parent.add_child(self)
