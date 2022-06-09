extends ColorRect

onready var header = $Container/Tooltip/Title
onready var label = $Container/Tooltip/Label
onready var quality_label = $Container/Tooltip/Quality

func setup(title: String, text: String, quality := -1) -> void:
	header.text = title
	label.text = text
	get_quality(quality)
	show()

func _on_CloseTooltip_pressed() -> void:
	AudioController.back()
	hide()

func get_quality(quality: int) -> void:
	if quality == -1: quality_label.hide()
	quality_label.show()
	if quality == 0:
		quality_label.text = "Worn"
		quality_label.modulate = Enums.worn
	if quality == 1:
		quality_label.text = "Common"
		quality_label.modulate = Enums.common
	if quality == 2:
		quality_label.text = "Fine"
		quality_label.modulate = Enums.fine
	if quality == 3:
		quality_label.text = "Exquisite"
		quality_label.modulate = Enums.exquisite
	if quality == 4:
		quality_label.text = "Masterwork"
		quality_label.modulate = Enums.masterwork
	if quality == 5:
		quality_label.text = "Artifact"
		quality_label.modulate = Enums.artefact
