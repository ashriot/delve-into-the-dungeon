extends Control

var DamageText = preload("res://src/battles/DamageText.tscn")

onready var player_panels = $PlayerPanels
onready var enemy_panels = $EnemyPanels
onready var buttons = $Buttons

export(Array, Resource) var enemies

var players: Array
var current_player = null
var cur_btn = null
var cur_hit_chance: int
var cur_crit_chance: int
var cur_stat_type: int

func init(game):
	players = game.players

	player_panels.init(self)

	for child in buttons.get_children():
		child.init(self)
	clear_buttons()

	enemy_panels.init(self, enemies)

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
		enemy_panels.hide_all_selectors()
	current_player = panel
	panel.selected = true
	setup_buttons()

func get_next_player() -> void:
	yield(get_tree().create_timer(0.5), "timeout")
	cur_btn = null
	for panel in player_panels.get_children():
		if panel.enabled and panel.ready:
			select_player(panel)
			return
	end_turn()

func end_turn():
	yield(get_tree().create_timer(0.8), "timeout")
	enemy_turns()

func enemy_turns():
	for enemy in enemy_panels.get_children():
		if enemy.enabled and enemy.alive():
			enemy.attack()
			yield(get_tree().create_timer(0.8), "timeout")
	# ENEMY TURNS DONE
	for panel in player_panels.get_children():
		panel.ready = true
	select_player(player_panels.get_children()[0])

func show_dmg_text(text: String, pos: Vector2) -> void:
	var damage_text = DamageText.instance()
	damage_text.rect_global_position = pos
	damage_text.init(self, text)

func _on_BattleButton_pressed(button: BattleButton) -> void:
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
	if button.selected:
		button.selected = false
		cur_btn = null
		return
	if cur_btn != null: cur_btn.selected = false
	cur_btn = button
	cur_btn.selected = true
	if button.item.target_type >= Enum.TargetType.MYSELF \
		and button.item.target_type <= Enum.TargetType.RANDOM_ALLY:
		player_panels.show_selectors(current_player, button.item.target_type)
	else:
		if button.item.damage_type == Enum.DamageType.MARTIAL:
			cur_hit_chance = cur_btn.item.hit_chance \
				+ (current_player.get_stat(Enum.StatType.AGI) * 5)
			cur_stat_type = Enum.StatType.AGI
# warning-ignore:integer_division
			cur_crit_chance = cur_btn.item.crit_chance + (cur_hit_chance - 60) / 2
		else:
			cur_hit_chance = 100
			cur_crit_chance = 0
			cur_stat_type = Enum.StatType.NA
		enemy_panels.update_item_stats(cur_hit_chance, cur_stat_type)
		var atk = current_player.get_stat(button.item.stat_used)
		var hit = Hit.new()
		hit.init(button.item, cur_hit_chance, cur_crit_chance, 0, 0, atk)
		enemy_panels.show_selectors(cur_btn.item.target_type, hit, atk)

func _on_EnemyPanel_pressed(panel: EnemyPanel) -> void:
	print(panel.enemy.name, "\nHP: ", panel.hp_cur, "/", panel.hp_max, \
		"\nSTR: ", panel.enemy.strength, "\nAGI: ", panel.enemy.agility, \
		"\nINT: ", panel.enemy.intellect, "\nDEF: ", panel.enemy.defense)
	if not panel.valid_target: return
	execute_vs_enemy(panel)

func _on_PlayerPanel_pressed(panel: PlayerPanel) -> void:
	if cur_btn:
		if cur_btn.item.target_type <= Enum.TargetType.RANDOM_ALLY:
			if not panel.valid_target: return
			execute_vs_player(panel)
	select_player(panel)

func execute_vs_enemy(panel) -> void:
	clear_selections()
	var item = cur_btn.item as Item
	var targets = [panel]
	if item.target_type >= Enum.TargetType.ANY_ROW \
		and item.target_type <= Enum.TargetType.BACK_ROW:
		targets = enemy_panels.get_row(panel)
	for hit_num in item.hits:
		for target in targets:
			if not target.alive(): continue
			var atk = current_player.get_stat(item.stat_used)
			var hit = Hit.new()
			hit.init(item, cur_hit_chance, cur_crit_chance, 0, 0, atk)
			target.take_hit(hit, cur_stat_type)
			if hit_num < item.hits - 1:
				yield(get_tree().create_timer(0.5), "timeout")
	current_player.player.changed()
	get_next_player()

func execute_vs_player(panel) -> void:
	clear_selections()
	var item = cur_btn.item as Item
	var targets = [panel]
	if item.target_type == Enum.TargetType.ALL_ALLIES:
		targets = player_panels.get_children()
	for hit_num in item.hits:
		for target in targets:
			if not target.alive(): continue
			target.take_friendly_hit(current_player, item)
			if hit_num < item.hits - 1:
				yield(get_tree().create_timer(0.5), "timeout")
	current_player.player.changed()
	get_next_player()

func clear_selections() -> void:
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
	if cur_btn == null: return
	cur_btn.uses_remain -= 1
	clear_buttons()
	current_player.selected = false
	current_player.ready = false
	print("clicked ", cur_btn.item.name)
