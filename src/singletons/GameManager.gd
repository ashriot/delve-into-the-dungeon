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
	spd = game.spd
	var dir = Directory.new();
	if dir.file_exists(file_path):
		save_data = load(file_path)
		loading = false # TRUE
	else:
		dir.make_dir_recursive(path)
		save_data = SaveData.new()
		save_data.game_version = "0.1a"
		loading = false

func initialize_party():
	var players = []
	if loading:
		print("LOADING DATA")
		for player in save_data.players.values():
			var new_player = Player.new()
			new_player.name = player["name"]
			new_player.job = player["job"]
			new_player.slot = player["slot"]
			new_player.tab = player["tab"]
			new_player.frame = player["frame"]
			new_player.hp_max = player["hp_max"]
			new_player.hp_cur = player["hp_cur"]
			new_player.strength = player["str"]
			new_player.agility = player["agi"]
			new_player.intellect = player["int"]
			new_player.defense = player["def"]
			new_player.items = dict_to_items(player["items"])
			new_player.perks = dict_to_perks(player["perks"])
			players.insert(new_player.slot, new_player)
		game.players = players
	else:
		players = game.players
		for player in players:
			player.heal()
	var i = 0
	for player in players:
		player.slot = i
		player.connect("player_changed", self, "_on_player_changed")
		player.changed()
		i += 1

func items_to_dict(items: Dictionary) -> Dictionary:
	var dict = {}
	for i in range(8):
		if items[i] == null: continue
		var item = ItemDb.get_item(items[i].name)
		dict[i] = [item.name, item.uses]
	return dict

func dict_to_items(dict: Dictionary) -> Dictionary:
	var items = {}
	for i in range(8):
		if dict[i] == null: continue
		var item = ItemDb.get_item(dict[i][0])
		item.uses = dict[i][1]
		items.append(item)
	return items

func perks_to_dict(perks: Dictionary) -> Dictionary:
	var dict = {}
	for i in range(5):
		if perks[i] == null: continue
		dict[i] = (perks[i].name)
	return dict

func dict_to_perks(dict: Dictionary) -> Dictionary:
	var perks = {}
	for i in range(8):
		if dict[i] == null: continue
		var perk = ItemDb.get_perk(dict[i])
		perks.append(perk)
	return perks

func _on_player_changed(player: Player):
	var new_player = {}
	new_player["name"] = player.name
	new_player["job"] = player.job
	new_player["slot"] = player.slot
	new_player["tab"] = player.tab
	new_player["hp_max"] = player.hp_max
	new_player["hp_cur"] = player.hp_cur
	new_player["frame"] = player.frame
	new_player["str"] = player.base_str()
	new_player["agi"] = player.base_agi()
	new_player["int"] = player.base_int()
	new_player["def"] = player.base_def()
	new_player["items"] = items_to_dict(player.items)
	new_player["perks"] = perks_to_dict(player.perks)
	save_data.players[player.slot] = new_player
	var error = ResourceSaver.save(file_path, save_data)
	check_error(error)

func initialize_inventory():
	game.inventory.connect("inventory_changed", self, "_on_inventory_changed")
	if loading:
		var existing_inventory = save_data.inventory.duplicate()
		game.inventory.set_items(existing_inventory)

func _on_inventory_changed(inventory):
	print("Inventory Changed")
	var item_list = []
	for item in inventory.get_items():
		item_list.append([item.name, item.uses])
	save_data.inventory = item_list
	var error = ResourceSaver.save(file_path, save_data)
	check_error(error)


func check_error(error):
	if error != OK:
		print("There was an error writing the save %s to %s -> %s" % [save_data.profile_name, file_path, error])

func get_spd() -> float:
	return 1 / spd
