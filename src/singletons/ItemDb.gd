extends Node
# ItemDb

var items: = Array()
var perks: = Array()
var equips: = Array()
var arcana: = Array()

func _ready():
	var files = get_dir_contents("res://resources/actions")
	for f in files:
		items.append(load(f))
	files = get_dir_contents("res://resources/perks")
	for f in files:
		perks.append(load(f))
	files = get_dir_contents("res://resources/equipment")
	for f in files:
		equips.append(load(f))
	files = get_dir_contents("res://resources/actions/skills/arcana")
	for f in files:
		if not "arcanum" in f and not "draw_arcana" in f:
			arcana.append(load(f))

func get_item(item_name: String) -> Item:
	for item in items:
		if item.name == item_name: return item.duplicate()
	return null

func get_perk(perk_name: String) -> Item:
	for perk in perks:
		if perk.name == perk_name: return perk.duplicate()
	return null

func get_equip(equip_name: String) -> Equipment:
	for equip in equips:
		if equip.name == equip_name: return equip.duplicate()
	return null

func get_random_arcana() -> Item:
	var rand = randi() % arcana.size()
	return arcana[rand]
	
func get_five_arcana() -> Array:
	arcana.shuffle()
	return arcana.slice(0, 4)

func get_random_item(lv: int) -> Item:
	var types = [Enums.ItemType.WEAPON, Enums.ItemType.WEAPON, Enums.ItemType.WEAPON, Enums.ItemType.TOME, Enums.ItemType.TOME]
	var type = types[randi() % types.size()]
	var rand_items = range(0, items.size())
	rand_items.shuffle()
	print("Getting an item of type: ", type, " and tier: ", lv)
	for i in rand_items:
		if items[i].item_type == type and items[i].tier <= lv \
		and !items[i].name.begins_with("Worn"):
			return items[i].duplicate()
	return null

func get_item_by_type(type: int, lv: int, excluding: Array) -> Item:
	var rand_items = range(0, items.size())
	rand_items.shuffle()
	print("Getting an item of type: ", type, " and tier: ", lv)
	for i in rand_items:
		var item = items[i]
		if item.sub_type == type and item.tier <= lv and !excluding.has(item.name):
			return items[i].duplicate()
	return null

## HELPER FUNCTIONS

func get_dir_contents(rootPath: String) -> Array:
	 var files = []
	 var directories = []
	 var dir = Directory.new()

	 if dir.open(rootPath) == OK:
		  dir.list_dir_begin(true, false)
		  _add_dir_contents(dir, files, directories)
	 else:
		  push_error("An error occurred when trying to access the path.")

	 return files

func _add_dir_contents(dir: Directory, files: Array, directories: Array):
	var file_name = dir.get_next()

	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name
		if dir.current_is_dir():
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			directories.append(path)
			_add_dir_contents(subDir, files, directories)
		else:
#			print("Found file: %s" % path)
			files.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()
