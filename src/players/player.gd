extends Unit
class_name Player

signal player_changed

var job: String
var slot: int

export(Array, Resource) var items

func changed():
	emit_signal("player_changed", self)

func base_str() -> int:
	return strength

func base_agi() -> int:
	return agility

func base_int() -> int:
	return intellect

func base_def() -> int:
	return defense
