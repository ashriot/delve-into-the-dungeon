extends Control
class_name BattleUI

var DamageText = preload("res://src/battles/DamageText.tscn")

onready var enemy_panels = $EnemyPanels as EnemyPanels
onready var player_panels = $PlayerPanels as PlayerPanels
onready var cp_panel = $CurrentPlayer as CurrentPlayerPanel
onready var battle_menu = $BattleMenu as VBoxContainer
onready var buttons = $Buttons as VBoxContainer
onready var enemy_info = $EnemyInfo
onready var enemy_title = $EnemyInfo/Panel/Title
onready var enemy_desc = $EnemyInfo/Panel/Desc

onready var tab1 = $Tabs/Tab1
onready var tab2 = $Tabs/Tab2

signal action_used
signal enemy_pressed
signal player_pressed

var cur_btn
var cur_player
var cur_tab
var ui_disabled: = true

# Called when the node enters the scene tree for the first time.
func _ready():
	ui_disabled = true

func init() -> void:
	for button in buttons.get_children(): button.init(self)
	enemy_info.hide()
	player_panels.init(self)
	enemy_panels.init(self)
	tab1.connect("pressed", self, "_on_Tab_Pressed", [tab1])
	tab2.connect("pressed", self, "_on_Tab_Pressed", [tab2])

func _on_player_start():
	print("set process true")
	ui_disabled = false


func setup_enemy_panels(enemies: Dictionary) -> void:
	enemy_panels.setup(enemies)

func setup_hero_panels(players: Dictionary, enc_lv: int) -> void:
	player_panels.setup(players, enc_lv)


func select_player(panel: PlayerPanel, beep = false) -> void:
	if not panel: return
	if !panel.ready: return
	if cur_btn:
		cur_btn = null
		enemy_panels.hide_all_selectors()
	if cur_player == panel:
		panel.selected = false
		clear_buttons()
		battle_menu.show()
		AudioController.back()
		cur_player = null
		return
	if cur_player: cur_player.selected = false
	if beep: AudioController.confirm()
	battle_menu.hide()
	cur_player = panel
	panel.selected = true
	setup_buttons()


func _on_PlayerPanel_pressed(panel: PlayerPanel) -> void:
	if ui_disabled: return
	if cur_btn and cur_btn.item.target_type <= Enums.TargetType.RANDOM_ALLY:
		if not panel.valid_target: return
		emit_signal("player_pressed", panel)
	else:
		select_player(panel, true)


func _on_EnemyPanel_pressed(panel: EnemyPanel) -> void:
	if ui_disabled: return
	if panel.valid_target:
		emit_signal("enemy_pressed", panel)
		return

	AudioController.click()
	$EnemyInfo/Panel.rect_position.y = 50
	enemy_info.show()
	enemy_title.text = "Lv. " + str(panel.unit.level) + " " + panel.unit.name
	enemy_desc.text = "HP: " + str(panel.hp_cur) + "/" + str(panel.hp_max)
	enemy_desc.text += "\n\nSTR: " + str(panel.unit.strength) + \
		"   AGI: " + str(panel.unit.agility)
	enemy_desc.text += "\nINT: " + str(panel.unit.intellect) + \
		"   DEF: " + str(panel.unit.defense)


func setup_buttons() -> void:
	setup_cur_player_panel()
	var arcana = []
	if cur_player.unit.job == "Seer":
		arcana = ItemDb.get_five_arcana()
	cur_tab = cur_player.tab
	var i = 0
	for button in buttons.get_children():
		if i < cur_player.unit.items.size():
			if not cur_player.unit.items[i]:
				i += 1
				button.clear()
				continue
			if cur_player.unit.items[i].name == "Arcanum":
				var arcanum = arcana.pop_front()
				cur_player.unit.items[i] = arcanum
			button.setup(cur_player.unit.items[i], i, cur_player)
			button.toggle(true)
		i += 1

	$Tabs/Tab1/Label.text = "Actions"
	$Tabs/Tab2/Label.text = cur_player.unit.job_tab
	display_tabs()
	buttons.show()


func setup_cur_player_panel() -> void:
	cp_panel.setup(cur_player)


func _on_BattleButton_long_pressed(button: BattleButton) -> void:
	if ui_disabled: return
	AudioController.click()
	$EnemyInfo/Panel.rect_position.y = 1
	enemy_title.text = button.item.name
	enemy_desc.text = button.item.desc
	enemy_info.show()


func _on_BattleButton_pressed(button: BattleButton) -> void:
	if ui_disabled: return
	if cur_player:
		if not button.available: return
	if button.tooltip: return
	if button.item.name == "End Turn":
		AudioController.confirm()
		for panel in player_panels.get_children(): panel.ready = false
		clear_buttons()
#		end_turn()
		return
	if button.item.name == "Inspect": return
	hide_all_selectors()
	if button.selected:
		AudioController.back()
		button.selected = false
		cur_btn = null
		return
	if cur_btn: cur_btn.selected = false
	AudioController.click()
	cur_btn = button
	var action = cur_btn.item
	cur_btn.selected = true
	var melee_penalty = action.melee and cur_player.melee_penalty
	var target_type = action.target_type
	if "Siphon" in action.name: target_type += \
		max((cur_player.unit.job_data["sp_cur"] - 1), 0) * 3
	if (cur_player.unit.job_tab == "Knives" and \
		action.sub_type == Enums.SubItemType.KNIFE):
			target_type = Enums.TargetType.ONE_ENEMY
			melee_penalty = false
	if target_type >= Enums.TargetType.MYSELF \
		and target_type <= Enums.TargetType.RANDOM_ALLY:
		player_panels.show_selectors(cur_player, action.target_type)
	var split = 1
	var hit = Hit.new()
	hit.init(button.item, cur_player, split)
	enemy_panels.update_item_stats(hit)
	enemy_panels.show_selectors(target_type)


func display_tabs() -> void:
	tab1.show()
	tab2.show()
	var other_tab = (cur_tab + 1) % 2
	if other_tab != 0: # Tab 1
		$Tabs/Tab1.self_modulate = Enums.yellow_color
		$Tabs/Tab2.self_modulate = Enums.off_white
	else:				# Tab 2
		$Tabs/Tab1.self_modulate = Enums.off_white
		$Tabs/Tab2.self_modulate = Enums.yellow_color

	for i in range((other_tab * 5), (other_tab * 5) + 5):
		buttons.get_child(i).toggle(false)
	for i in range((cur_tab * 5), (cur_tab * 5) + 5):
		buttons.get_child(i).toggle(true)


func toggle_tabs(value) -> void:
	if ui_disabled: return
	if cur_btn:
		cur_btn.selected = false
		enemy_panels.hide_all_selectors()
		player_panels.hide_all_selectors()
	cur_tab = value
	cur_player.tab = value
	display_tabs()


func hide_all_selectors() -> void:
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()


func finish_action(spend_turn) -> void:
	hide_all_selectors()
	if not cur_btn: return
	else: cur_btn.selected = false
	if spend_turn:
		cur_player.quick_actions = 0
		cur_player.selected = false
		clear_buttons()
		cur_player.ready = false
	else:
		cur_player.quick_actions -= 1
		setup_buttons()


func update_enemy_ui(enemy_id: int, enemy_data: Array) -> void:
	var enemy = enemy_panels.get_child(enemy_id) as EnemyPanel
	enemy.update_ui()


func cleanup() -> void:
	clear_buttons()


func clear_buttons() -> void:
	cp_panel.hide()
	battle_menu.hide()
	tab1.hide()
	tab2.hide()
	for button in buttons.get_children():
		button.clear()


func show_dmg_text(text: String, pos: Vector2, crit: bool) -> void:
	var damage_text = DamageText.instance()
	damage_text.rect_position = pos
	damage_text.init(self, text, crit)


func show_text(text: String, pos: Vector2, display = false) -> void:
	var damage_text = DamageText.instance()
	damage_text.rect_global_position = pos
	if display: damage_text.display(self, text)
	else: damage_text.text(self, text)


func _on_Close_pressed():
	if ui_disabled: return
	AudioController.back()
	enemy_info.hide()


func _on_Tab_Pressed(tab) -> void:
	if ui_disabled: return
	var index = tab.get_index()
	if cur_tab == index: return

	AudioController.select()
	toggle_tabs(index)
