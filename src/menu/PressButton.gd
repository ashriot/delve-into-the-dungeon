extends Button
class_name PressButton

signal long_pressed

var timer = Timer.new()
var tooltip = false

func _ready():
	add_child(timer)
	timer.connect("timeout", self, "_on_Timer_timeout")

func init(menu):
	var err = connect("long_pressed", menu, "_on_ItemButton_long_pressed", [self])
	if err: print("There was an error connecting: ", err)

func _on_Button_up() -> void:
	tooltip = false
	timer.stop()

func _on_Button_down():
	timer.start(.33)

func _on_Timer_timeout() -> void:
	timer.stop()
	tooltip = true
	emit_signal("long_pressed")
