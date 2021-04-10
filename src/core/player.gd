extends Unit
class_name Player

signal player_changed

var slot: int
var tab: int
export var job: String
export var job_tab: String

export(Dictionary) var items

func changed():
	emit_signal("player_changed", self)
