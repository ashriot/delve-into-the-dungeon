extends Control

var DamageText = preload("res://src/battles/DamageText.tscn")

signal enemy_done
signal battle_done

onready var player_panels = $PlayerPanels
onready var enemy_panels = $EnemyPanels
onready var buttons = $Buttons
onready var battleMenu = $BattleMenu

var current_player = null
var cur_btn = null
var cur_hit_chance: int
var cur_crit_chance: int
var cur_stat_type: int
var player_targets: = [false, false, false, false]

var chose_next: bool
var battle_active: bool

func init(game):
	battle_active = false
	battleMenu.hide()
#	for child in buttons.get_children():
#		child.init(self)
	var flee = load("res://resources/items/battleCommands/flee.tres")
	var end_turn = load("res://resources/items/battleCommands/end_turn.tres")
	battleMenu.get_child(0).init(self)
	battleMenu.get_child(0).setup(flee, false)
	battleMenu.get_child(1).init(self)
	battleMenu.get_child(1).setup(end_turn, false)
	player_panels.init(self)
	enemy_panels.init(self)
	for button in buttons.get_children():
		button.init(self)
	hide()

var gargoyle = preload("res://resources/enemies/gargoyle.tres")
var mermaid = preload("res://resources/enemies/mermaid.tres")

func start(players: Array, enemies: Dictionary) -> void:
	enemies = {
		1: [gargoyle, 1],
	}
	$Victory.hide()
	player_panels.setup(players)
	enemy_panels.setup(enemies)
	clear_buttons()
	var i = 0
	for panel in player_panels.get_children():
		if panel.enabled: player_targets[i] = true
		i += 1
	chose_next = false
	show()
	battle_active = true
	yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	start_players_turns()

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
	battleMenu.hide()
	for child in buttons.get_children():
		child.hide()

func select_player(panel: PlayerPanel, beep = false) -> void:
	if panel == null: return
	if !panel.ready: return
	if current_player == panel:
		current_player.selected = false
		current_player = null
		buttons.hide()
		battleMenu.show()
		AudioController.back()
		return
	if current_player != null: current_player.selected = false
	if cur_btn != null:
		cur_btn.selected = false
		enemy_panels.hide_all_selectors()
	if beep: AudioController.select()
	battleMenu.hide()
	buttons.show()
	current_player = panel
	panel.selected = true
	setup_buttons()

func start_players_turns() -> void:
	AudioController.play_sfx("player_turn")
	get_next_player(false)

func get_next_player(delay: = true) -> void:
	if !battle_active: return
	if chose_next: return
	if delay: yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	cur_btn = null
	current_player = null
	for panel in player_panels.get_children():
		if panel.enabled and panel.ready:
			select_player(panel)
			return
	end_turn()

func end_turn():
	chose_next = false
	yield(get_tree().create_timer(0.75 * GameManager.spd), "timeout")
	enemy_turns()

func enemy_turns():
	print("Enemy Turns")
	for enemy in enemy_panels.get_children():
		if enemy.enabled and enemy.alive():
			enemy_take_action(enemy)
			yield(self, "enemy_done")
			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	yield(get_tree().create_timer(0.75 * GameManager.spd), "timeout")
	for panel in player_panels.get_children():
		if panel.alive(): panel.ready = true
	start_players_turns()

func enemy_take_action(panel: EnemyPanel):
	if panel.enemy.actions.size() == 0:
		yield(get_tree().create_timer(0.25 * GameManager.spd, true), "timeout")
		emit_signal("enemy_done")
		return
	var text = "Attack"
	var action = panel.get_action()
	text = action.name
	AudioController.play_sfx(action.use_fx)
	show_text(text, panel.pos)
	panel.anim.play("Hit")
	yield(get_tree().create_timer(0.475 * GameManager.spd, true), "timeout")
	var targets = get_enemy_targets(panel, action)
	for target in targets:
		var hit = Hit.new()
		# item, _hit_chance, _crit_chance, _bonus_dmg, _dmg_mod, _atk
		hit.init(action, action.hit_chance, action.crit_chance, 0, 0, panel.get_stat(action.stat_used), panel.enemy.level)
		if action.target_type < Enum.TargetType.ONE_ENEMY:
			pass
#			target.take_friendly_hit(hit)
		else: target.take_hit(hit)
	print("emitting enemy done signal")
	emit_signal("enemy_done")

func get_enemy_targets(panel: EnemyPanel, action: EnemyAction) -> Array:
	var targets = []
	var choices = []
	var choice = 0
	if action.target_type == Enum.TargetType.MYSELF:
		return [panel]
	if action.target_type == Enum.TargetType.ONE_ENEMY:
		for i in range(4):
			if player_targets[i]: choices.append(i)
		choice = randi() % 4
		targets.append(player_panels.get_child(choice))
	if action.target_type == Enum.TargetType.ONE_FRONT:
		for i in range(2):
			if player_targets[i]: choices.append(i)
		if choices.size() == 2: choice = choices[0] if roll() < 51 else choices[1]
		else: choice = choices[0]
		targets.append(player_panels.get_child(choice))

	if action.target_type == Enum.TargetType.FRONT_ROW:
		if player_targets[0] or player_targets[1]:
			for i in range(2): if player_targets[i]: choices.append(i)
		else: for i in range(2, 4): if player_targets[i]: choices.append(i)
		for target in choices: targets.append(player_panels.get_child(target))

	return targets

func show_dmg_text(text: String, pos: Vector2) -> void:
	var damage_text = DamageText.instance()
	damage_text.rect_global_position = pos
	damage_text.init(self, text)

func show_text(text: String, pos: Vector2, display = false) -> void:
	var damage_text = DamageText.instance()
	damage_text.rect_global_position = pos
	if display: damage_text.display(self, text)
	else: damage_text.text(self, text)

func _on_BattleButton_pressed(button: BattleButton) -> void:
	if !battle_active: return
	if button.item.name == "End Turn":
		AudioController.confirm()
		for panel in player_panels.get_children(): panel.ready = false
		clear_buttons()
		end_turn()
		return
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
	if button.selected:
		AudioController.back()
		button.selected = false
		cur_btn = null
		return
	if cur_btn != null: cur_btn.selected = false
	AudioController.click()
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
		var atk = current_player.get_stat(button.item.stat_used)
		var hit = Hit.new()
		hit.init(button.item, cur_hit_chance, cur_crit_chance, 0, 0, atk, -1)
		enemy_panels.update_item_stats(hit)
		enemy_panels.show_selectors(cur_btn.item.target_type)

func _on_EnemyPanel_pressed(panel: EnemyPanel) -> void:
	if !battle_active: return
	print("Lv. ", panel.enemy.level, " ", panel.enemy.name, "\tHP: ", panel.hp_cur, "/", panel.hp_max, \
		"\tSTR: ", panel.enemy.strength, "\tAGI: ", panel.enemy.agility, \
		"\tINT: ", panel.enemy.intellect, "\tDEF: ", panel.enemy.defense)
	if not panel.valid_target: return
	execute_vs_enemy(panel)

func _on_PlayerPanel_pressed(panel: PlayerPanel) -> void:
	if !battle_active: return
	if cur_btn and cur_btn.item.target_type <= Enum.TargetType.RANDOM_ALLY:
			if not panel.valid_target: return
			execute_vs_player(panel)
	else:
		chose_next = true
		select_player(panel, true)

func execute_vs_enemy(panel) -> void:
	var item = cur_btn.item as Item
	var user = current_player
	AudioController.play_sfx(item.use_fx)
	clear_selections()
	show_text(item.name, user.pos)
	yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	var targets = [panel]
	if item.target_type >= Enum.TargetType.ANY_ROW \
		and item.target_type <= Enum.TargetType.BACK_ROW:
		targets = enemy_panels.get_row(panel)
	if item.target_type == Enum.TargetType.ALL_ENEMIES:
		targets = enemy_panels.get_all()
	for hit_num in item.hits:
		for target in targets:
			if not target.alive(): continue
			var atk = user.get_stat(item.stat_used)
			var hit = Hit.new()
			hit.init(item, cur_hit_chance, cur_crit_chance, 0, 0, atk, panel.enemy.level)
			target.take_hit(hit, cur_stat_type)
		if item.target_type >= Enum.TargetType.ANY_ROW:
			print("playing sfx")
			AudioController.play_sfx(item.sound_fx)
		if hit_num < item.hits - 1:
			yield(get_tree().create_timer(0.33 * GameManager.spd), "timeout")
	user.player.changed()
	get_next_player()

func execute_vs_player(panel) -> void:
	var user = current_player
	var item = cur_btn.item as Item
	AudioController.play_sfx(item.use_fx)
	var turn_spent = true
	if item.sub_type == Enum.SubItemType.SHIELD:
		if user.has_perk("Quick Block"):
			turn_spent = false
	clear_selections(turn_spent)
	show_text(item.name, user.pos)
	yield(get_tree().create_timer(0.5 * GameManager.spd, false), "timeout")
	AudioController.play_sfx(item.sound_fx)
	var targets = [panel]
	if item.target_type == Enum.TargetType.ALL_ALLIES:
		targets = player_panels.get_children()
	for hit_num in item.hits:
		for target in targets:
			if not target.alive(): continue
			target.take_friendly_hit(user, item)
		if hit_num > item.hits - 1:
			yield(get_tree().create_timer(0.33 * GameManager.spd, false), "timeout")
	user.player.changed()
	get_next_player()

func clear_selections(spend_turn: = true) -> void:
	chose_next = false
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
	if cur_btn == null: return
	cur_btn.uses_remain -= 1
	clear_buttons()
	current_player.selected = false
	if spend_turn:
		current_player.ready = false
		current_player.decrement_boons("End")

func roll() -> int:
	return randi() % 100 + 1

func _on_EnemyPanel_died(panel: EnemyPanel) -> void:
	panel.enabled = false
	var done = true
	for enemy in enemy_panels.get_children():
		if enemy.enabled and enemy.alive():
			done = false
	if done:
		victory()

func victory() -> void:
	AudioController.bgm.stop()
	battle_active = false
	clear_selections(false)
	if current_player != null:
		current_player.selected = false
		current_player = null
	if cur_btn != null: cur_btn = null
	clear_buttons()
	yield(get_tree().create_timer(1 * GameManager.spd, true), "timeout")
	$Victory.show()
	AudioController.play_bgm("victory")
	for panel in player_panels.get_children():
		panel.victory()
	yield(get_tree().create_timer(2 * GameManager.spd, true), "timeout")
	emit_signal("battle_done")
