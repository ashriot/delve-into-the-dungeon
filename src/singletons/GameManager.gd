extends Node

var save_name = "adam"
var save_data: SaveData
var path = "user://" + save_name;
var file_path = path.plus_file("data.tres")

var loading: = false
var spd: = 1.0 setget, get_spd

var game

func initialize_game_data(_game):
	game = _game
	var dir = Directory.new();
	if dir.file_exists(file_path):
		save_data = load(file_path)
		loading = true
	else:
		dir.make_dir_recursive(path)
		save_data = SaveData.new()
		save_data.game_version = "0.1a"
		loading = false

func initialize_party():
	var players = []
	if loading:
		print("LOADING DATA")
#		for player in save_data.players.values():
#			var new_player = Player.new()
#			new_player.slot = player["slot"]
#			new_player.frame = player["frame"]
#			new_player.hp_max = player["hp_max"]
#			new_player.hp_cur = player["hp_cur"]
#			new_player.strength = player["str"]
#			new_player.agility = player["agi"]
#			new_player.intellect = player["int"]
#			new_player.defense = player["def"]
#			new_player.items = array_to_items(player["items"])
#			new_player.perks = array_to_perks(player["perks"])
#			players.insert(new_player.slot, new_player)
#		game.players = players
	players = game.players
	var i = 0
	for player in players:
		player.slot = i
		player.connect("player_changed", self, "_on_player_changed")
		player.changed()
		i += 1

func items_to_array(items: Array) -> Array:
	var array = []
	for item in items:
		array.append([item.name, item.uses])
	return array

func array_to_items(array: Array) -> Array:
	var items = []
	for entry in array:
		var item = ItemDb.get_item(entry[0])
		item.uses = entry[1]
		items.append(item)
	return items

func perks_to_array(perks: Array) -> Array:
	var array = []
	for perk in perks:
		array.append(perk.name)
	return array

func array_to_perks(array: Array) -> Array:
	var perks = []
	for entry in array:
		var perk = ItemDb.get_perk(entry)
		perks.append(perk)
	return perks

func _on_player_changed(player: Player):
	var new_player = {}
	new_player["slot"] = player.slot
	new_player["hp_max"] = player.hp_max
	new_player["hp_cur"] = player.hp_cur
	new_player["frame"] = player.frame
	new_player["str"] = player.base_str()
	new_player["agi"] = player.base_agi()
	new_player["int"] = player.base_int()
	new_player["def"] = player.base_def()
	new_player["items"] = items_to_array(player.items)
	new_player["perks"] = perks_to_array(player.perks)
	save_data.players[player.slot] = new_player
	var error = ResourceSaver.save(file_path, save_data)
	check_error(error)

func initialize_inventory():
	game.inventory.connect("inventory_changed", self, "_on_inventory_changed")
	if loading:
		var existing_inventory = save_data.inventory.duplicate()
		game.inventory.set_items(existing_inventory)
	else:
		game.inventory.add_item("Wooden Sword")

func _on_inventory_changed(inventory):
	print("Inventory Changed")
	var item_list = []
	for item in inventory.get_items():
		item_list.append([item.name, item.uses])
	for i in item_list:
		save_data.inventory.append(i)
	var error = ResourceSaver.save(file_path, save_data)
	check_error(error)


func check_error(error):
	if error != OK:
		print("There was an error writing the save %s to %s -> %s" % [save_data.profile_name, file_path, error])

func get_spd() -> float:
	return 1 / spd
