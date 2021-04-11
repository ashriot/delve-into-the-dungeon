extends Control
# PARTY MENU

onready var tooltip = $Tooltip
onready var player_panels = $PlayerPanels
onready var main_menu = $MainMenu
onready var stats_panel = $Stats
onready var items_panel = $Items
onready var tab1 = $Items/BG/HBoxContainer/Tab1
onready var tab2 = $Items/BG/HBoxContainer/Tab2
onready var item_buttons = $Items/BG/Items
onready var items_panel_popup = $Items/PopupMenu

var game
var players
var current_player: PlayerMenuPanel
var current_tab: int setget set_current_tab
var current_menu: Control

func init(_game) -> void:
	hide()
	tooltip.hide()
	items_panel.hide()
	stats_panel.hide()
	game = _game
	players = game.players
	update_menu_data()
	for child in player_panels.get_children(): child.init(self)
	for child in item_buttons.get_children(): child.init(self)

func open_menu() -> void:
	current_menu = null
	main_menu.show()
	update_menu_data()
	show()

func _on_CloseButton_pressed() -> void:
	AudioController.back()
	if current_menu != null:
		stats_panel.hide()
		current_menu.hide()
		current_menu = null
		main_menu.show()
	else: game.close_menu()

func update_menu_data() -> void:
	var i = 0
	for child in player_panels.get_children():
		if players[i] == null: continue
		child.setup(players[i])
		if current_player == null:
			current_player = child
			current_player.select(true)
		i += 1

func update_stat_data() -> void:
	stats_panel.show()
	if current_player == null:
		current_player = player_panels.get_child(0)
		current_player.select(true)
	$Stats/Sprite.frame = current_player.unit.frame + 20
	$Stats/Name.text = current_player.unit.name
	$Stats/Job.text = current_player.unit.job
	$Stats/HP.text = str(current_player.unit.hp_cur) + "\n/" + \
		str(current_player.unit.hp_max)
	$Stats/Stats/STR/Value.text = str(current_player.unit.strength)
	$Stats/Stats/AGI/Value.text = str(current_player.unit.agility)
	$Stats/Stats/INT/Value.text = str(current_player.unit.intellect)
	$Stats/Stats/DEF/Value.text = str(current_player.unit.defense)

func update_item_data():
	var i = 0
	for child in item_buttons.get_children():
		if current_player.unit.items[i] != null:
			child.setup(current_player.unit.items[i])
		else: child.equippable = true
		i += 1
	self.current_tab = current_player.tab
	$Items/BG/HBoxContainer/Tab2/Label.text = current_player.unit.job_tab
	$Items/BG/HBoxContainer/Tab2/ColorRect/Label.text = current_player.unit.job_tab

func set_current_tab(value) -> void:
	current_tab = value
	current_player.tab = value
	var other_tab = (current_tab + 1) % 2
	for j in range((other_tab * 4), (other_tab * 4) + 4):
		item_buttons.get_child(j).hide()
	for j in range((current_tab * 4), (current_tab * 4) + 4):
		item_buttons.get_child(j).show()
	if other_tab == 0:
		$Items/BG/HBoxContainer/Tab1/ColorRect.hide()
		$Items/BG/HBoxContainer/Tab2/ColorRect.show()
	else:
		$Items/BG/HBoxContainer/Tab1/ColorRect.show()
		$Items/BG/HBoxContainer/Tab2/ColorRect.hide()

func _on_Items_pressed() -> void:
	AudioController.click()
	current_menu = items_panel
	main_menu.hide()
	update_stat_data()
	update_item_data()
	items_panel_popup.hide()
	items_panel.show()

func _on_PlayerMenuPanel_pressed(panel) -> void:
	if current_player != null and current_player == panel: return
	AudioController.confirm()
	current_player.select(false)
	current_player = panel
	current_player.select(true)
	update_stat_data()
	if current_menu == items_panel: update_item_data()

func _on_ItemButton_pressed(button) -> void:
	AudioController.select()
	if button.equippable: print("Empty slot")
	else:
		print("clicked ", button.item.name)
		tooltip.setup(button.item.name, button.item.desc)

func _on_InfoButton_pressed() -> void:
	pass # Replace with function body.

func _on_Tab1_pressed() -> void:
	AudioController.confirm()
	self.current_tab = 0

func _on_Tab2_pressed() -> void:
	AudioController.confirm()
	self.current_tab = 1
