extends Button
class_name PressButton

signal long_pressed
signal clicked

var press_timer = Timer.new()

func _ready() -> void:
	var err = press_timer.connect("timeout", self, "_on_long_pressed")
	if err: print("There was an error connecting the long-press timer: ", err)
	add_child(press_timer)

func init(menu):
	var err = connect("long_pressed", menu, "_on_ItemButton_long_pressed", [self])
	if err: print("There was an error connecting: ", err)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if press_timer.is_stopped(): press_timer.start(0.5)
		else:
			if !press_timer.is_stopped():
				press_timer.stop()
				emit_signal("clicked")
	elif event is InputEventMouseMotion:
		press_timer.stop()

func _on_long_pressed() -> void:
	press_timer.stop()
	emit_signal("long_pressed")
