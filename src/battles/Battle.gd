extends Control

var DamageText = preload("res://src/battles/DamageText.tscn")

onready var player_panels = $PlayerPanels
onready var enemy_panels = $EnemyPanels
onready var buttons = $Buttons

export(Array, Resource) var enemies

var players: Array
var current_player = null
var cur_btn = null

func init(game):
	players = game.players
	var i = 0
	for panel in player_panels.get_children():
		if i >= players.size(): panel.hide()
		else: panel.init(self, players[i])
		i += 1

	for child in buttons.get_children():
		child.init(self)
	clear_buttons()

	i = 0
	for panel in enemy_panels.get_children():
		if i >= enemies.size(): panel.hide()
		else: panel.init(self, enemies[i])
		i += 1

	for panel in player_panels.get_children():
		panel.ready = true

	get_next_player()

func setup_buttons() -> void:
	var i = 0
	for button in buttons.get_children():
		if i < current_player.player.items.size():
			var item = current_player.player.items[i]
			button.setup(item)
			button.show()
			i += 1
		else:
			button.hide()

func clear_buttons() -> void:
	for child in buttons.get_children():
		child.hide()

func select_player(panel: PlayerPanel) -> void:
	if panel == null: return
	if !panel.ready: return
	if current_player != null: current_player.selected = false
	if cur_btn != null:
		cur_btn.selected = false
		get_tree().call_group("enemy_panels", "targetable", false)
	current_player = panel
	panel.selected = true
	setup_buttons()

func get_next_player() -> void:
	for panel in player_panels.get_children():
		if panel.enabled and panel.ready:
			select_player(panel)
			return
	end_turn()

func end_turn():
	yield(get_tree().create_timer(0.8), "timeout")
	var enemy = enemy_panels.get_child(0)
	enemy.attack()
	yield(get_tree().create_timer(0.8), "timeout")
	for panel in player_panels.get_children():
		panel.ready = true
	select_player(player_panels.get_child(0))

func _on_BattleButton_pressed(button: BattleButton) -> void:
	if button.selected:
		button.selected = false
		cur_btn = null
		get_tree().call_group("enemy_panels", "targetable", false)
		return
	button.selected = true
	if cur_btn != null: cur_btn.selected = false
	cur_btn = button
	get_tree().call_group("enemy_panels", "targetable", true)

func _on_EnemyPanel_pressed(panel: EnemyPanel) -> void:
	get_tree().call_group("enemy_panels", "targetable", false)
	if cur_btn == null: return
	clear_buttons()
	current_player.selected = false
	current_player.ready = false
	cur_btn.uses_remain -= 1
	print("clicked ", cur_btn.item.name)
	var damage_text = DamageText.instance()
	var pos = panel.rect_position
	pos.x -= 1
	pos.y += panel.rect_size.y / 2 + 4
	damage_text.rect_global_position = pos
	var item = cur_btn.item
	var stat = current_player.player.strength if item.stat_used == Enum.StatType.STR else current_player.player.intellect
	var def = panel.get_def(item.stat_vs)
	var def_mod = def * 3
	var dmg = int(stat * item.multiplier - def_mod)
	damage_text.init(self, str(dmg))
	panel.take_hit()
	panel.hp_cur -= dmg
	get_next_player()

func _on_PlayerPanel_pressed(panel: PlayerPanel) -> void:
	select_player(panel)
