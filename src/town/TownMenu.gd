extends Control

onready var blacksmith = $Blacksmith


func _ready() -> void:
	blacksmith.hide()

func _on_Blacksmith_pressed():
	AudioController.click()
	blacksmith.show()


func _on_Leave_BS_pressed():
	AudioController.back()
	blacksmith.hide()
