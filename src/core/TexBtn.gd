tool

extends TextureButton
class_name TexBtn

onready var label = $Label

export var text: String

func _ready():
	label.text = text
