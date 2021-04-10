extends Unit
class_name Player

signal player_changed

var job: String
var slot: int

export(Array, Resource) var items

func changed():
	emit_signal("player_changed", self)
