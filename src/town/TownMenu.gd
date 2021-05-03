extends Control

signal open_inv

export(Dictionary) var locales

onready var blacksmith = $Blacksmith

onready var map = $WorldMap
onready var hidden = $WorldMap/Nav/Hidden
onready var discovered = $WorldMap/Nav/Discovered
onready var nav = $WorldMap/Nav/Sprite
onready var prev = $WorldMap/Nav/Prev
onready var next = $WorldMap/Nav/Next
onready var scout = $WorldMap/Scout

var game: Game
var map_pos: int setget set_map_pos
var map_max: int
var depth: int setget set_depth

func _ready() -> void:
	blacksmith.hide()
	map.hide()
	scout.hide()

func init(game: Game) -> void:
	self.game = game
	connect("open_inv", game, "_on_BuyBS_pressed")

func _on_Blacksmith_pressed():
	AudioController.click()
	blacksmith.show()

func _on_Leave_BS_pressed():
	AudioController.back()
	blacksmith.hide()

func _on_BuyBS_pressed():
	AudioController.click()
	emit_signal("open_inv")

func _on_SellBS_pressed():
	AudioController.click()
	emit_signal("open_inv")

func _on_TownGates_pressed():
	AudioController.click()
	map_max = game.discovered
	var x = map_max * 6 - 1
	self.map_pos = map_max
	discovered.rect_size.x = x
	if map_max == 1:
		prev.modulate.a = 0.1
		next.modulate.a = 0.1
	else:
		prev.modulate.a = 1.0
		next.modulate.a = 1.0
	if game.dungeon_lvs[map_pos - 1] == 1:
		$WorldMap/Progress/Plus.modulate.a = 0.1
		$WorldMap/Progress/Minus.modulate.a = 0.1
	else:
		$WorldMap/Progress/Plus.modulate.a = 1
		$WorldMap/Progress/Minus.modulate.a = 1
	map.show()

func _on_Back_pressed():
	AudioController.back()
	map.hide()

func set_map_pos(value) -> void:
	map_pos = value
	nav.position.x = 10 + map_pos * 6
	$WorldMap/Title.text = locales[map_pos].name
	$WorldMap/Backdrop.frame = locales[map_pos].frame
	$WorldMap/Scout/Title.text = locales[map_pos].name
	$WorldMap/Scout/ScrollContainer/Desc.text = locales[map_pos].desc
	self.depth = game.dungeon_lvs[map_pos - 1]

func set_depth(value) -> void:
	depth = value
	$WorldMap/Progress/Depth.text = "Depth: " + str(depth) + "/" + str(game.dungeon_lvs[map_pos - 1])
	var lv = locales[map_pos].enemy_lv + int(depth / 3)
	$WorldMap/Progress/Level.text = "Avg. Lv: " + str(lv)

func _on_Scout_pressed():
	AudioController.click()
	scout.show()

func _on_ScoutDone_pressed():
	AudioController.back()
	scout.hide()

func _on_Enter_pressed():
	AudioController.confirm()
	game.enter_dungeon(locales[map_pos], depth)

func _on_Prev_pressed():
	if map_max == 1: return
	AudioController.select()
	if map_pos == 1: self.map_pos = map_max
	else: self.map_pos -= 1
	if game.dungeon_lvs[map_pos - 1] == 1:
		$WorldMap/Progress/Plus.modulate.a = 0.1
		$WorldMap/Progress/Minus.modulate.a = 0.1
	else:
		$WorldMap/Progress/Plus.modulate.a = 1
		$WorldMap/Progress/Minus.modulate.a = 1

func _on_Next_pressed():
	if map_max == 1: return
	AudioController.select()
	if map_pos == map_max: self.map_pos = 1
	else: self.map_pos += 1
	if game.dungeon_lvs[map_pos - 1] == 1:
		$WorldMap/Progress/Plus.modulate.a = 0.1
		$WorldMap/Progress/Minus.modulate.a = 0.1
	else:
		$WorldMap/Progress/Plus.modulate.a = 1
		$WorldMap/Progress/Minus.modulate.a = 1

func _on_Minus_pressed():
	if game.dungeon_lvs[map_pos - 1] == 1: return
	AudioController.confirm()
	if depth == 1: self.depth = game.dungeon_lvs[map_pos - 1]
	else: self.depth -= 1

func _on_Plus_pressed():
	if game.dungeon_lvs[map_pos - 1] == 1: return
	AudioController.confirm()
	if depth == game.dungeon_lvs[map_pos - 1]: self.depth = 1
	else: self.depth += 1
