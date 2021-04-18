extends Unit
class_name Player

signal player_changed

var slot: int
var tab: int
export var job: String
export var job_tab: String
export(Enum.SubItemType) var job_skill

export(Array) var xp = [0.0, 0.0, 0.0, 0.0, 0.0]
export var job_xp = 0
export var job_lv = 0
export(Array) var xp_cut = [1, 1, 1, 1, 1]
export(Array) var gains = [0, 0, 0, 0, 0]

export(Dictionary) var items

func changed():
	emit_signal("player_changed", self)

func swap_items(item1: Item, item1_slot: int, item2: Item, item2_slot: int):
	var value = items.get(item1_slot)
	items[item1_slot] = item2
	items[item2_slot] = item1
	changed()

func add_item(item: Item, slot: int):
	items[slot] = item
	changed()

func remove_item(slot_num: int) -> void:
	items[slot_num] = null
	changed()

func reset_xp() -> void:
	xp_cut = [1, 1, 1, 1, 1]
	gains = [0, 0, 0, 0, 0]
