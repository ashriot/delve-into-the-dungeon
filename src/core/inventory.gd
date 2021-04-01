extends Resource
class_name Inventory

signal inventory_changed

export var _items = Array() setget set_items, get_items

func set_items(new_items: Array) -> void:
	for item in new_items:
		var item_resource = ItemDb.get_item(item[0])
		if not item:
			print("ERROR: Could not find an item called: ", item[0])
			return
		item_resource.uses = item[1]
		_items.append(item_resource)

func get_items():
	return _items

func get_item(index):
	return _items[index]

func add_item(item_name):
	var item = ItemDb.get_item(item_name)
	if not item:
		print("ERROR: Could not find an item called: ", item_name)
		return
	item.uses = item.max_uses
	_items.append(item)
	emit_signal("inventory_changed", self)
