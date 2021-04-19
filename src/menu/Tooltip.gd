extends ColorRect

onready var header = $Container/Panel/Title
onready var label = $Container/Panel/Label

func setup(title, text) -> void:
	header.text = title
	label.text = text
	show()

func _on_CloseTooltip_pressed() -> void:
	AudioController.back()
	hide()
