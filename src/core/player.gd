extends Unit
class_name Player

signal player_changed

var job: String
var slot: int

export(Array, Resource) var items
export(Array, Resource) var perks

func changed():
	emit_signal("player_changed", self)

func has_perk(perk_name) -> bool:
	for perk in perks:
		if perk.name == perk_name:
			return true
	return false
