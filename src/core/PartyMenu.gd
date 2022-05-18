extends Control
# PARTY MENU

onready var tooltip = $Tooltip
onready var player_panels = $PlayerPanels
onready var main_menu = $MainMenu
onready var stats_panel = $Stats
onready var gold_label = $Gold
onready var options = $Options
onready var opt_mute = $Options/Panel/Button
onready var actions_btn = $MainMenu/MenuButtons/ActionsBtn

onready var items_panel = $Items
onready var popup = $Items/PopupMenu
onready var tab1 = $Items/Tabs/Tab1
onready var tab2 = $Items/Tabs/Tab2
onready var item_buttons = $Items/Items

onready var equip_panel = $Equip
onready var equip_buttons = $Equip/Equips

onready var inv_panel = $Inventory
onready var inv_back = $Inventory/InvBack/Label
onready var inv_preview = $Inventory/PreviewBtn
onready var sell_panel = $Inventory/SellPanel
onready var sell_price = $Inventory/SellPanel/Price
onready var inv_filters = $Inventory/BG/Filters
onready var inv_buttons = $Inventory/BG/Items
onready var page_label = $Inventory/BG/Pages/Label

var game
var players: Dictionary
var cur_player: PlayerMenuPanel
var cur_menu: Control
var shopping: bool

var cur_page: int
var total_pages: int
var cur_tab: int setget set_cur_tab
var cur_btn: Button setget set_cur_btn

func init(_game) -> void:
	hide()
	tooltip.hide()
	items_panel.hide()
	equip_panel.hide()
	stats_panel.hide()
	inv_panel.hide()
	options.hide()
	game = _game
	players = game.players
	inv_preview.hide()
	main_menu.show()
	opt_mute.pressed = game.mute
	for child in player_panels.get_children(): child.init(self)
	for child in item_buttons.get_children(): child.init(self)
	for child in equip_buttons.get_children(): child.init(self)
	for child in inv_buttons.get_children(): child.init(self)

func open_menu() -> void:
	cur_page = 0
	cur_menu = null
	main_menu.show()
	update_menu_data()
	update_inv_data()
	sell_panel.hide()
	shopping = false
	show()
	if players.size() == 0:
		actions_btn.disabled = true
		$Recruit.show()
	else:
		actions_btn.disabled = false
		$Recruit.hide()

func swap_players(player1: Player, player2: Player) -> void:
	var key1 = player1.slot
	var key2 = player2.slot
	players[key1] = player2
	players[key2] = player1
	player1.slot = key2
	player2.slot = key1

func _on_CloseButton_pressed() -> void:
	AudioController.back()
	if shopping:
		sell_panel.hide()
		cur_menu.hide()
		cur_menu = null
		hide()
	if inv_preview.visible:
		inv_preview.hide()
		inv_panel.hide()
		return
	if cur_menu != null:
		stats_panel.hide()
		cur_menu.hide()
		cur_menu = null
		main_menu.show()
	else: game.close_menu()

func update_menu_data() -> void:
	gold_label.text = str(game.inventory.gold)
	var i = 0
	for child in player_panels.get_children():
		if players.size() <= i:
			child.hide()
			continue
		child.show()
		child.setup(players[i])
		if cur_player == null:
			cur_player = child
			cur_player.select(true)
		i += 1

func update_stat_data() -> void:
	stats_panel.show()
	if cur_player == null:
		cur_player = player_panels.get_child(0)
		cur_player.select(true)
	$Stats/Sprite.frame = cur_player.unit.frame + 20
	$Stats/Name.text = cur_player.unit.name
	$Stats/Job.text = cur_player.unit.job
	$Stats/HpLabel/HP.text = str(cur_player.unit.hp_cur) + "/" + \
		str(cur_player.unit.hp_max)
	$Stats/ApLabel/AP.text = str(cur_player.unit.ap) + "/6"
	$Stats/Stats/STR/Value.text = str(cur_player.unit.strength)
	$Stats/Stats/AGI/Value.text = str(cur_player.unit.agility)
	$Stats/Stats/INT/Value.text = str(cur_player.unit.intellect)
	$Stats/Stats/DEF/Value.text = str(cur_player.unit.defense)
	$Stats/Stats/Crit/Chance.text = str(cur_player.unit.crit_chance) + "%"
	$Stats/Stats/Crit/Power.text = "+" + str(cur_player.unit.crit_power)

func update_item_data():
	var i = 0
	for child in item_buttons.get_children():
		if cur_player.unit.items.has(i):
			child.setup(cur_player.unit, cur_player.unit.items[i])
		else: child.setup(cur_player.unit, null)
		i += 1
	self.cur_tab = cur_player.tab
	$Items/Tabs/Tab2/Label.text = cur_player.unit.job_tab

func update_equip_data():
	var i = 0
	for child in equip_buttons.get_children():
		if cur_player.unit.equipment.has(i):
			child.setup(cur_player.unit.equipment[i], i)
		else: child.setup(null, i)
		i += 1

func set_cur_tab(value) -> void:
	cur_tab = value
	cur_player.tab = value
	var other_tab = (cur_tab + 1) % 2
	if other_tab != 0: # Tab 1
		$Items/Tabs/Tab1.self_modulate = Enums.yellow_color
		$Items/Tabs/Tab2.self_modulate = Enums.default_color
	else:				# Tab 1
		$Items/Tabs/Tab1.self_modulate = Enums.default_color
		$Items/Tabs/Tab2.self_modulate = Enums.yellow_color

	for i in range((other_tab * 5), (other_tab * 5) + 5):
		item_buttons.get_child(i).toggle(false)
	for i in range((cur_tab * 5), (cur_tab * 5) + 5):
		item_buttons.get_child(i).toggle(true)

func _on_ActionsBtn_pressed() -> void:
	AudioController.click()
	cur_menu = items_panel
	main_menu.hide()
	popup.hide()
	update_stat_data()
	update_item_data()
	items_panel.show()

func _on_EquipBtn_pressed() -> void:
	AudioController.click()
	cur_menu = equip_panel
	main_menu.hide()
	popup.hide()
	update_stat_data()
	update_equip_data()
	equip_panel.show()

func _on_PlayerMenuPanel_pressed(panel) -> void:
	if cur_player != null and cur_player == panel: return
	AudioController.confirm()
	select_player(panel)

func select_player(panel: PlayerMenuPanel) -> void:
	cur_player.select(false)
	cur_player = panel
	cur_player.select(true)
	update_stat_data()
	if cur_menu == items_panel: update_item_data()
	if cur_menu == equip_panel: update_equip_data()

func _on_ItemButton_pressed(button) -> void:
	if button.tooltip: return
	if button.empty:
		if (button.get_index() < 4 or button.slot_type == Enums.SubItemType.NA):
			AudioController.select()
			equip_item(button)
	else:
		self.cur_btn = button

func _on_EquipButton_pressed(button) -> void:
	if button.tooltip: return
	if button.empty:
		if (button.get_index() < 4 or button.slot_type == Enums.SubItemType.NA):
			AudioController.select()
			equip_item(button)

func equip_item(button) -> void:
	cur_btn = button
	inv_preview.setup(cur_player.unit, button)
	inv_preview.selected = true
	inv_preview.show()
	inv_panel.show()

func _on_ItemButton_long_pressed(button) -> void:
	AudioController.click()
	if button.empty:
		print("Equip new item!")
	else:
		tooltip.setup(button.item.name, button.item.desc)

func _on_EquipButton_long_pressed(button: EquipBtn) -> void:
	AudioController.click()
	if not button.empty:
		tooltip.setup(button.equip.get_name(), button.equip.get_desc(), button.equip.quality)

func _on_InfoButton_pressed() -> void:
	pass # Replace with function body.

func _on_Tab1_pressed() -> void:
	AudioController.confirm()
	self.cur_tab = 0

func _on_Tab2_pressed() -> void:
	AudioController.confirm()
	self.cur_tab = 1

func _on_Remove_pressed():
	AudioController.confirm()
	cur_player.unit.remove_item(cur_btn.get_index())
	if cur_btn.item.uses > 0: game.inventory.add_item(cur_btn.item.name, cur_btn.item.uses)
	cur_btn.setup(cur_player.unit, null)
	cur_btn.selected = false
	cur_btn = null
	popup.hide()
	update_inv_data()

func _on_Swap_pressed() -> void:
	AudioController.confirm()
	inv_preview.setup(cur_player.unit, cur_btn.item)
	inv_preview.show()
	inv_panel.show()

#### INVENTORY ####

func open_inv() -> void:
	shopping = true
	sell_panel.hide()
	inv_back.text = "Selling"
	self.show()
	cur_menu = inv_panel
	update_inv_data()
	inv_panel.show()

func _on_InventoryBtn_pressed() -> void:
	AudioController.click()
	inv_back.text = "Inventory"
	cur_menu = inv_panel
	update_inv_data()
	inv_panel.show()

func update_inv_data():
	sell_panel.hide()
	update_page_data()
	var i = cur_page * 10
	for child in inv_buttons.get_children():
		if i < game.inventory.items.size():
			var item = game.inventory.items[i]
			child.setup(item)
		else: child.setup(null)
		i += 1
	page_label.text = str(cur_page + 1) + "/" + str(total_pages)
	if total_pages > 1:
		$Inventory/BG/Pages/Left.modulate.a = 1.0
		$Inventory/BG/Pages/Right.modulate.a = 1.0
	else:
		$Inventory/BG/Pages/Left.modulate.a = 0.3
		$Inventory/BG/Pages/Right.modulate.a = 0.3

func _on_InvButton_remove_item(item: Item) -> void:
	game.inventory.remove_item(item)

func _on_InvButton_pressed(button) -> void:
	if button.tooltip: return
	if inv_preview.visible:
		AudioController.click()
		var item = button.item
		game.inventory.remove_item(item)
		cur_player.unit.add_item(item, cur_btn.get_index())
		if !cur_btn.empty: game.inventory.add_item(cur_btn.item.name)
		cur_btn.setup(cur_player.unit, item)
		cur_btn.selected = false
		cur_btn = null
		popup.hide()
		inv_preview.hide()
		inv_panel.hide()
		update_inv_data()
	else:
		self.cur_btn = button

func update_page_data():
	var size = game.inventory.items.size()
# warning-ignore:narrowing_conversion
	total_pages = max(ceil(size / 10.0), 1)
	if cur_page < 0: cur_page = total_pages - 1
	elif cur_page >= total_pages: cur_page = 0

func set_cur_btn(value) -> void:
#	if value.get_index() > 3: return
	if value == null:
		cur_btn.selected = false
		popup.hide()
		sell_panel.hide()
		return
	if cur_btn == value:
		AudioController.back()
		cur_btn.selected = false
		cur_btn = null
		popup.hide()
		sell_panel.hide()
		return
	AudioController.select()
	if cur_btn != null: cur_btn.selected = false
	cur_btn = value
	cur_btn.selected = true
	if shopping:
		sell_price.text = "Sell for " + str(cur_btn.item.price / 2) + "?"
		sell_panel.show()
	popup.rect_global_position = cur_btn.rect_global_position + Vector2(6, popup.rect_size.y * -1 - 1)
	popup.show()

func _on_Left_pressed():
	if total_pages == 1: return
	AudioController.click()
	cur_page -= 1
	update_inv_data()

func _on_Right_pressed():
	if total_pages == 1: return
	AudioController.click()
	cur_page += 1
	update_inv_data()

func _on_OptMute_pressed():
	game.mute = !game.mute

func _on_OptionsBtn_pressed():
	AudioController.click()
	cur_menu = options
	options.show()

func _on_Sell_pressed():
	AudioController.play_sfx("sell")
	game.inventory.remove_item(cur_btn.item)
	game.inventory.gold += int(cur_btn.item.price / 2)
	gold_label.text = str(game.inventory.gold)
	cur_btn = null
	update_inv_data()
