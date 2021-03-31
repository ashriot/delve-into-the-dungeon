extends Control

var DamageText = preload("res://src/battles/DamageText.tscn")

export var player1: Resource
export var player2: Resource
export var enemy1: Resource

onready var player_panels = $PlayerPanels
onready var buttons = $Buttons

var current_player = null

func _ready():
	var panel1 = player_panels.get_child(0)
	panel1.init(self, player1)
	var panel2 = player_panels.get_child(1)
	panel2.init(self, player2)
	for child in buttons.get_children():
		child.init(self)
	clear_buttons()

func setup_buttons() -> void:
	var i = 0
	for button in buttons.get_children():
		if i < current_player.player.actions.size():
			var action = current_player.player.actions[i]
			button.setup(action)
			button.show()
			i += 1
		else:
			button.hide()

func clear_buttons() -> void:
	for child in buttons.get_children():
		child.hide()

func select_player(panel: PlayerPanel) -> void:
	if current_player != null: current_player.selected(false)
	current_player = panel
	panel.selected(true)
	setup_buttons()

func _on_BattleButton_pressed(button: BattleButton) -> void:
	button.uses_remain -= 1
	print("clicked ", button.action.name)
	var damage_text = DamageText.instance()
	damage_text.rect_global_position = Vector2(6, 12)
	var action = button.action
	var stat = current_player.player.strength if action.stat_used == Enum.StatType.STR else current_player.player.intellect
	var def = enemy1.defense if action.stat_vs == Enum.StatType.DEF else enemy1.intellect
	var rel_def = float(def - stat) / stat + 0.5
	var def_mod = 1 - rel_def if rel_def < 0 else pow(0.95, 20 * rel_def)
	var dmg = int(stat * action.multiplier * def_mod)
	damage_text.init(self, str(dmg))

func _on_PlayerPanel_pressed(panel: PlayerPanel) -> void:
	select_player(panel)
