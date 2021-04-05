extends Node
# ItemDb

var items: = Array()
var perks: = Array()

func _ready():
	var item_files = get_dir_contents("res://resources/items")
	for f in item_files:
		items.append(load(f))
	var perk_files = get_dir_contents("res://resources/perks")
	for f in perk_files:
		perks.append(load(f))

func get_item(item_name: String) -> Item:
	for item in items:
		if item.name == item_name: return item
	return null

func get_perk(perk_name: String) -> Item:
	for perk in perks:
		if perk.name == perk_name: return perk
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
