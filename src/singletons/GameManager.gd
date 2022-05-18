extends Node

const VERSION = "0.6"

var profile_id: String
var path: String
var file_path: String
var save_data: SaveData

var profile1: SaveData
var profile2: SaveData
var profile3: SaveData

var loading: = false
var spd: = 1.0 setget, get_spd

var game: Game

var ui_color: Color
var gold = Color("#ffbe22")
var gray = Color("#606060")

func init() -> void:
	var profile_path = "user://profile"
	var dir = Directory.new();
	for i in range(3):
		var full_path = profile_path + str(i + 1)
		if dir.file_exists(full_path.plus_file("data.tres")):
			if i == 0: profile1 = load(full_path.plus_file("data.tres")) as SaveData
			if i == 1: profile2 = load(full_path.plus_file("data.tres")) as SaveData
			if i == 2: profile3 = load(full_path.plus_file("data.tres")) as SaveData
		else:
			dir.make_dir_recursive(full_path)

func initialize_game_data(_game):
	game = _game
	ui_color = Enums.default_color
	profile_id = str(game.profile_id)
	path = "user://profile" + profile_id;
	file_path = path.plus_file("data.tres")
	spd = game.spd
	var dir = Directory.new();
	if dir.file_exists(file_path):
		save_data = load(file_path) as SaveData
		if save_data.game_version != VERSION:
			dir.remove(file_path)
			loading = false
		else:
			loading = true
	if !loading:
		dir.make_dir_recursive(path)
		save_data = SaveData.new()
		save_data.game_version = VERSION
		loading = false

func initialize_party():
	var players = {}
	if !loading:
		save_data.bench = {}
		print('initializing save data')
		var i = 0
		for player in game.players.values():
			player.slot = i
			_on_player_changed(player)
			player.ready_equipment()
			player.heal()
			players[i] = player
			i += 1
	else:
		for player in save_data.players.values():
			var new_player = Player.new()
			new_player.name = player["name"]
			new_player.job = player["job"]
			new_player.job_tab = player["job_tab"]
			new_player.job_skill = player["job_skill"]
			new_player.slot = player["slot"]
			new_player.tab = player["tab"]
			new_player.frame = player["frame"]
			new_player.hp_max = player["stats"]["hp_max"]
			new_player.hp_cur = player["stats"]["hp_cur"]
			new_player.ap = player["stats"]["ap"]
			new_player.strength = player["stats"]["str"]
			new_player.agility = player["stats"]["agi"]
			new_player.intellect = player["stats"]["int"]
			new_player.defense = player["stats"]["def"]
			new_player.crit_chance = player["stats"]["crit_chance"]
			new_player.xp = player["xp"]
			new_player.skill = player["skill"]
			new_player.job_xp = player["job_xp"]
			new_player.job_lv = player["job_lv"]
			new_player.job_data = player["job_data"]
			new_player.items = dict_to_items(player["items"])
			new_player.perks = dict_to_perks(player["perks"])
			new_player.equipment = dict_to_equips(player["equipment"])
			new_player.ready_equipment()
			players[new_player.slot] = new_player
	game.dungeon_lvs = save_data.dungeon_lvs
#	game.unlocked_heroes = save_data.unlocked_heroes
	game.players = players
	var i = 0
	for key in players.keys():
		var player = players[key]
		player.slot = key
		player.connect("player_changed", self, "_on_player_changed")
		player.changed()
		i += 1

func items_to_dict(items: Dictionary) -> Dictionary:
	var dict = {}
	for i in range(10):
		if not items[i]: dict[i] = null
		else:
			var item = items[i] as Item
			var item_name = item.name
			if item.sub_type == Enums.SubItemType.ARCANA:
				item_name == "Arcanum"
			dict[i] = [item_name, item.uses]
	return dict

func dict_to_items(dict: Dictionary) -> Dictionary:
	var items = {}
	for i in range(10):
		if not dict[i]: items[i] = null
		else:
			var item = ItemDb.get_item(dict[i][0]) as Item
			assert(item, dict[i][0] + " is missing!")
			items[i] = item
			item.uses = dict[i][1]
	return items

func perks_to_dict(perks: Dictionary) -> Dictionary:
	var dict = {}
	for i in range(5):
		if not perks[i]: dict[i] = null
		else:
			dict[i] = [perks[i].name, perks[i].rank]
	return dict

func equips_to_dict(equips: Dictionary) -> Dictionary:
	var dict = {}
	for i in range(5):
		if equips[i] == null: dict[i] = null
		else:
			dict[i] = equips[i].name
	return dict

func dict_to_perks(dict: Dictionary) -> Dictionary:
	var perks = {}
	for i in range(5):
			if not dict[i]: perks[i] = null
			else:
				var perk = ItemDb.get_perk(dict[i][0]) as Perk
				perks[i] = perk
				perk.rank = dict[i][1]
	return perks

func dict_to_equips(dict: Dictionary) -> Dictionary:
	var equips = {}
	for i in range(5):
			if dict[i] == null: equips[i] = null
			else:
				var equip = ItemDb.get_equip(dict[i])
				equips[i] = equip
	return equips

func _on_player_changed(player: Player):
	var new_player = {}
	new_player["stats"] = {}
	new_player["name"] = player.name
	new_player["job"] = player.job
	new_player["job_tab"] = player.job_tab
	new_player["job_skill"] = player.job_skill
	new_player["slot"] = player.slot
	new_player["tab"] = player.tab
	new_player["frame"] = player.frame
	new_player["stats"]["hp_max"] = player.base_hp_max()
	new_player["stats"]["hp_cur"] = player.hp_cur
	new_player["stats"]["ap"] = player.ap
	new_player["stats"]["str"] = player.base_str()
	new_player["stats"]["agi"] = player.base_agi()
	new_player["stats"]["int"] = player.base_int()
	new_player["stats"]["def"] = player.base_def()
	new_player["stats"]["crit_chance"] = player.get_base_stat(Enums.StatType.CRIT)
	new_player["xp"] = player.xp
	new_player["skill"] = player.skill
	new_player["job_xp"] = player.job_xp
	new_player["job_lv"] = player.job_lv
	new_player["job_data"] = player.job_data
	new_player["items"] = items_to_dict(player.items)
	new_player["perks"] = perks_to_dict(player.perks)
	new_player["equipment"] = equips_to_dict(player.equipment)
	save_data.players[player.slot] = new_player
	var error = ResourceSaver.save(file_path, save_data)
	check_error(error)

func _on_level_changed() -> void:
	save_data.dungeon_lvs = game.dungeon_lvs
	var error = ResourceSaver.save(file_path, save_data)
	check_error(error)

func initialize_inventory():
	game.inventory.connect("inventory_changed", self, "_on_inventory_changed")
	game.inventory.connect("gold_changed", self, "_on_gold_changed")
	var inv = [ ["Potion", 5], ["Potion", 5], ["Potion", 5] ]
	var gold = 100
	if loading:
		inv = save_data.inventory.duplicate()
		gold = save_data.gold
	game.inventory.set_items(inv)
	game.inventory.gold = gold

func _on_inventory_changed(inventory):
	print("Inventory Changed")
	var item_list = []
	for item in inventory.get_items():
		item_list.append([item.name, item.uses])
	save_data.inventory = item_list
	var error = ResourceSaver.save(file_path, save_data)
	check_error(error)

func _on_gold_changed(gold):
	print("Gold changed")
	save_data.gold = gold
	var error = ResourceSaver.save(file_path, save_data)

func check_error(error):
	if error != OK:
		print("There was an error writing the save %s to %s -> %s" % [save_data.profile_name, file_path, error])

func get_spd() -> float:
	return 1 / spd
