extends ColorRect

signal done

onready var anim = $AnimationPlayer

func fade_to_black():
	mouse_filter = Control.MOUSE_FILTER_STOP
	anim.play("FadeToBlack")
	yield(anim, "animation_finished")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	emit_signal("done")

func fade_from_black():
	mouse_filter = Control.MOUSE_FILTER_STOP
	anim.play("FadeFromBlack")
	yield(anim, "animation_finished")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	emit_signal("done")

func instant_show():
	get_material().set_shader_param("cutoff", 0)

func instant_hide():
	get_material().set_shader_param("cutoff", 1)
