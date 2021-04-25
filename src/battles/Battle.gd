extends Control

var DamageText = preload("res://src/battles/DamageText.tscn")

signal enemy_done
signal battle_done

onready var player_panels = $PlayerPanels
onready var enemy_panels = $EnemyPanels
onready var buttons = $Buttons
onready var tab1 = $Tabs/Tab1
onready var tab2 = $Tabs/Tab2
onready var battleMenu = $BattleMenu
onready var enemy_info = $EnemyInfo
onready var enemy_title = $EnemyInfo/Panel/Title
onready var enemy_desc = $EnemyInfo/Panel/Desc

var cur_player = null
var cur_btn = null
var cur_hit_chance: int
var cur_crit_chance: int
var cur_stat_type: int
var player_targets: = [false, false, false, false]

var cur_tab: int

var chose_next: bool
var battle_active: bool

var enc_lv: float
var game = null

func init(game):
	enemy_info.hide()
	self.game = game
	battle_active = false
	battleMenu.hide()
#	for child in buttons.get_children():
#		child.init(self)
	var inspect = load("res://resources/battleCommands/inspect.tres")
	var end_turn = load("res://resources/battleCommands/end_turn.tres")
	var flee = load("res://resources/battleCommands/flee.tres")
	battleMenu.get_child(0).init(self)
	battleMenu.get_child(0).setup(inspect, false)
	battleMenu.get_child(1).init(self)
	battleMenu.get_child(1).setup(end_turn, false)
	battleMenu.get_child(2).init(self)
	battleMenu.get_child(2).setup(flee, false)
	player_panels.init(self)
	enemy_panels.init(self)
	for button in buttons.get_children():
		button.init(self)
	tab1.connect("pressed", self, "_on_Tab_Pressed", [tab1])
	tab2.connect("pressed", self, "_on_Tab_Pressed", [tab2])
	hide()

func start(players: Dictionary, enemies: Dictionary) -> void:
	$Victory.hide()
	enc_lv = enemy_panels.setup(enemies)
	player_panels.setup(players, enc_lv)
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
	cur_tab = cur_player.tab
	var i = 0
	for button in buttons.get_children():
		if i < cur_player.unit.items.size():
			var item = cur_player.unit.items[i]
			i += 1
			if item == null:
				button.clear()
				continue
			button.setup(item)
			button.toggle(true)
	$Tabs/Tab1/Label.text = "Actions"
	$Tabs/Tab1/ColorRect/Label.text = "Actions"
	$Tabs/Tab2/Label.text = cur_player.unit.job_tab
	$Tabs/Tab2/ColorRect/Label.text = cur_player.unit.job_tab
	display_tabs()

func display_tabs() -> void:
	tab1.show()
	tab2.show()
	var other_tab = (cur_tab + 1) % 2
	if other_tab == 0:
		$Tabs/Tab1/ColorRect.hide()
		$Tabs/Tab2/ColorRect.show()
	else:
		$Tabs/Tab1/ColorRect.show()
		$Tabs/Tab2/ColorRect.hide()

	for i in range((other_tab * 4), (other_tab * 4) + 4):
		buttons.get_child(i).toggle(false)
	for i in range((cur_tab * 4), (cur_tab * 4) + 4):
		buttons.get_child(i).toggle(true)

func toggle_tabs(value) -> void:
	if cur_btn != null:
		cur_btn.selected = false
		enemy_panels.hide_all_selectors()
		player_panels.hide_all_selectors()
	cur_tab = value
	cur_player.tab = value
	display_tabs()

func clear_buttons() -> void:
	battleMenu.hide()
	tab1.hide()
	tab2.hide()
	for child in buttons.get_children():
		child.clear()

func select_player(panel: PlayerPanel, beep = false) -> void:
	if panel == null: return
	if !panel.ready: return
	if cur_player == panel:
		cur_player.selected = false
		cur_player = null
		buttons.hide()
		tab1.hide()
		tab2.hide()
		battleMenu.show()
		AudioController.back()
		return
	if cur_player != null: cur_player.selected = false
	if cur_btn != null:
		cur_btn.selected = false
		enemy_panels.hide_all_selectors()
	if beep: AudioController.select()
	battleMenu.hide()
	buttons.show()
	cur_player = panel
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
	cur_player = null
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
	for enemy in enemy_panels.get_children():
		if enemy.enabled and enemy.alive:
			enemy_take_action(enemy)
			yield(self, "enemy_done")
			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	yield(get_tree().create_timer(0.75 * GameManager.spd), "timeout")
	for panel in player_panels.get_children():
		if panel.alive: panel.ready = true
	start_players_turns()

func enemy_take_action(panel: EnemyPanel):
	panel.decrement_hexes("Start")
	var stunned = false
	if panel.has_hex("Stun"):
		stunned = true
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	if !stunned:
		var action = panel.get_action()
		AudioController.play_sfx(action.use_fx)
		show_text(action.name, panel.pos)
		panel.anim.play("Hit")
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
		var targets = get_enemy_targets(panel, action)
		var randoms = []
		var rand_targets = false
		var hits = randi() % (1 + action.max_hits - action.min_hits) + action.min_hits
		if action.target_type == Enum.TargetType.RANDOM_ENEMY: rand_targets = true
		for hit_num in hits:
			if rand_targets:
				targets = player_panels.get_random()
				if targets == []: break
			for target in targets:
				if not target.alive: continue
				var atk = panel.get_stat(action.stat_used)
				var dmg_mod = 0
				if action.melee and panel.melee_penalty: dmg_mod -= 0.50
				var hit = Hit.new()
				var hit_chance = 100 if !panel.has_perk("Precise") else 160
				if action.item_type == Enum.ItemType.MARTIAL_SKILL or \
					action.item_type == Enum.ItemType.WEAPON:
					hit_chance = action.hit_chance * panel.get_stat(Enum.StatType.AGI)
				if panel.has_hex("Blind"): hit_chance /= 2
				hit.init(action, hit_chance, action.crit_chance, 0, dmg_mod, atk, panel)
				if action.target_type < Enum.TargetType.ONE_ENEMY:
					target.take_friendly_hit(hit)
				else: target.take_hit(hit)
			if action.target_type >= Enum.TargetType.ANY_ROW:
				AudioController.play_sfx(action.sound_fx)
			if hit_num < hits - 1:
				yield(get_tree().create_timer(0.33 * GameManager.spd), "timeout")
		for target in targets: target.gained_xp = false
	panel.decrement_hexes("End")
	emit_signal("enemy_done")

func get_enemy_targets(panel: EnemyPanel, action: EnemyAction) -> Array:
	var targets = []
	var choices = []
	var choice = 0
	if action.target_type == Enum.TargetType.MYSELF:
		return [panel]
	if action.target_type == Enum.TargetType.ONE_ENEMY:
		for i in range(player_targets.size()):
			if player_targets[i]: choices.append(i)
		choice = randi() % player_targets.size()
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
	if action.target_type == Enum.TargetType.ANY_ROW:
		var roll = randi() % 2
		if player_targets[0] or player_targets[1] and roll == 0:
			for i in range(2): if player_targets[i]: choices.append(i)
		else: for i in range(2, 4): if player_targets[i]: choices.append(i)
		for target in choices: targets.append(player_panels.get_child(target))
	if action.target_type == Enum.TargetType.RANDOM_ENEMY:
		for i in range(player_targets.size()):
			if player_targets[i]: choices.append(i)
			targets.append(player_panels.get_child(choice))

	return targets

func show_dmg_text(text: String, pos: Vector2) -> void:
	var damage_text = DamageText.instance()
	damage_text.rect_position = pos
	damage_text.init(self, text)

func show_text(text: String, pos: Vector2, display = false) -> void:
	var damage_text = DamageText.instance()
	damage_text.rect_global_position = pos
	if display: damage_text.display(self, text)
	else: damage_text.text(self, text)
	
func learned_text(text: String, pos: Vector2) -> void:
	var damage_text = DamageText.instance()
	damage_text.rect_global_position = pos
	damage_text.learned(self, text)

func _on_ItemButton_long_pressed(button: BattleButton) -> void:
	AudioController.click()
	$EnemyInfo/Panel.rect_position.y = 1
	enemy_title.text = button.item.name
	enemy_desc.text = button.item.desc
	enemy_info.show()

func _on_BattleButton_pressed(button: BattleButton) -> void:
	if button.tooltip: return
	if !battle_active: return
	if button.item.name == "End Turn":
		AudioController.confirm()
		for panel in player_panels.get_children(): panel.ready = false
		clear_buttons()
		end_turn()
		return
	if button.item.name == "Inspect":
		AudioController.confirm()
		enemy_panels.show_selectors(Enum.TargetType.ONE_ENEMY)
		player_panels.show_selectors(null, Enum.TargetType.ANY_ALLY)
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
		player_panels.show_selectors(cur_player, button.item.target_type)
	else:
		if button.item.stat_hit == Enum.StatType.AGI:
			cur_hit_chance = int(cur_btn.item.hit_chance \
				* cur_player.get_stat(Enum.StatType.AGI)) \
				 + (60 if cur_player.has_perk("Precise") else 0)
			cur_stat_type = Enum.StatType.AGI
# warning-ignore:integer_division
			cur_crit_chance = int(cur_btn.item.crit_chance + (cur_hit_chance - 60) / 2)
		else:
			cur_hit_chance = 100
			cur_crit_chance = 0
			cur_stat_type = Enum.StatType.NA
		var dmg_mod = 0
		if button.item.melee and cur_player.melee_penalty: dmg_mod -= 0.50
		var atk = cur_player.get_stat(button.item.stat_used)
		var hit = Hit.new()
		hit.init(button.item, cur_hit_chance, cur_crit_chance, 0, dmg_mod, atk, cur_player)
		enemy_panels.update_item_stats(hit)
		enemy_panels.show_selectors(cur_btn.item.target_type)

func _on_EnemyPanel_pressed(panel: EnemyPanel) -> void:
	if !battle_active: return
	if not panel.valid_target:
		AudioController.click()
		$EnemyInfo/Panel.rect_position.y = 50
		enemy_info.show()
		enemy_title.text = "Lv. " + str(panel.unit.level) + " " + panel.unit.name
		enemy_desc.text = "HP: " + str(panel.hp_cur) + "/" + str(panel.hp_max)
		enemy_desc.text += "\nSTR: " + str(panel.unit.strength) + "   AGI: " + str(panel.unit.agility)
		enemy_desc.text += "\nINT: " + str(panel.unit.intellect) + "   DEF: " + str(panel.unit.defense)
	else: execute_vs_enemy(panel)

func _on_PlayerPanel_pressed(panel: PlayerPanel) -> void:
	if !battle_active: return
	if cur_btn and cur_btn.item.target_type <= Enum.TargetType.RANDOM_ALLY:
		if not panel.valid_target: return
		execute_vs_player(panel)
	else:
		chose_next = true
		select_player(panel, true)

func execute_vs_enemy(panel) -> void:
	var gained_xp = false
	var item = cur_btn.item as Item
	var user = cur_player
	AudioController.play_sfx(item.use_fx)
	finish_action()
	show_text(item.name, user.pos)
	yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	var targets = [panel]
	var randoms = []
	var rand_targets = false
	if item.target_type >= Enum.TargetType.ANY_ROW \
		and item.target_type <= Enum.TargetType.BACK_ROW:
		targets = enemy_panels.get_row(panel)
	if item.target_type == Enum.TargetType.ALL_ENEMIES or \
		item.target_type == Enum.TargetType.RANDOM_ENEMY:
		targets = enemy_panels.get_all()
	var hits = randi() % (1 + item.max_hits - item.min_hits) + item.min_hits
	if item.target_type == Enum.TargetType.RANDOM_ENEMY: rand_targets = true
	for hit_num in hits:
		if rand_targets:
			targets = enemy_panels.get_random()
			if targets == []: break
		for target in targets:
			if not target.alive: continue
			var dmg_mod = 0.0
			if item.melee and cur_player.melee_penalty: dmg_mod -= 0.50
			var atk = user.get_stat(item.stat_used)
			var hit = Hit.new()
			hit.init(item, cur_hit_chance, cur_crit_chance, 0, dmg_mod, atk, cur_player)
			gained_xp = target.take_hit(hit)
			if randoms.size() > 0: if not target.alive: rand_targets.remove(hit_num)
		if item.target_type >= Enum.TargetType.ANY_ROW:
			AudioController.play_sfx(item.sound_fx)
		if hit_num < hits - 1:
			yield(get_tree().create_timer(0.33 * GameManager.spd), "timeout")
	if gained_xp: cur_player.calc_xp(item.stat_used)
	cur_player.calc_xp(item.stat_hit, 0.25)
	get_next_player()

func execute_vs_player(panel) -> void:
	var user = cur_player
	var item = cur_btn.item as Item
	AudioController.play_sfx(item.use_fx)
	var turn_spent = true
	if item.sub_type == Enum.SubItemType.SHIELD:
		if user.has_perk("Quick Block"):
			turn_spent = false
	finish_action(turn_spent)
	show_text(item.name, user.pos)
	yield(get_tree().create_timer(0.5 * GameManager.spd, false), "timeout")
	var targets = [panel]
	if item.target_type == Enum.TargetType.ALL_ALLIES:
		targets = player_panels.get_children()
	cur_player.calc_xp(item.stat_used)
	var hits = randi() % (1 + item.max_hits - item.min_hits) + item.min_hits
	AudioController.play_sfx(item.sound_fx)
	for hit_num in hits:
		for target in targets:
			if not target.alive: continue
			target.take_friendly_hit(user, item)
		if hit_num > hits - 1:
			yield(get_tree().create_timer(0.33 * GameManager.spd, false), "timeout")
	get_next_player()

func finish_action(spend_turn: = true) -> void:
	chose_next = false
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
	if cur_btn == null: return
	cur_btn.uses_remain -= 1
	print(cur_btn.item.name, " -> ", cur_btn.uses_remain)
	clear_buttons()
	cur_player.selected = false
	if spend_turn:
		cur_player.ready = false
		cur_player.decrement_boons("End")

func clear_selections() -> void:
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
	cur_player.selected = false
	if cur_btn != null:
		cur_btn.selected = false
		cur_btn = null

func roll() -> int:
	return randi() % 100 + 1

func _on_EnemyPanel_died(panel: EnemyPanel) -> void:
	var done = true
	for enemy in enemy_panels.get_children():
		if enemy.enabled and enemy.alive:
			done = false
	if done: battle_active = false
	yield(get_tree().create_timer(0.5 * GameManager.spd, true), "timeout")
	AudioController.play_sfx("die")
	panel.clear()
	if done: victory()

func _on_PlayerPanel_died(panel: PlayerPanel) -> void:
	pass
	
func victory() -> void:
	AudioController.bgm.stop()
	clear_selections()
	if cur_player != null:
		cur_player.selected = false
		cur_player = null
	if cur_btn != null: cur_btn = null
	clear_buttons()
	yield(get_tree().create_timer(1 * GameManager.spd, true), "timeout")
	$Victory.show()
	AudioController.play_bgm("victory")
	for panel in player_panels.get_children():
		panel.victory()
	for panel in player_panels.get_children():
		for i in range(panel.unit.gains.size()):
			if panel.unit.gains[i] > 0:
				var amt = panel.unit.gains[i]
				panel.unit.increase_base_stat(i + 1, int(amt))
				show_text(Enum.get_stat_name(i + 1) + "+" + str(amt), panel.pos)
				print(panel.unit.name, " -> ", Enum.get_stat_name(i + 1), " increased by ", amt, "!")
				AudioController.play_sfx("statup")
				yield(get_tree().create_timer(1 * GameManager.spd, true), "timeout")
		var ranks_up = panel.calc_job_xp()
		for _r in range(ranks_up):
			if panel.unit.job_skill == Enum.SubItemType.NA: break
			game.learned_skill(panel.unit)
			var skill_name = yield(game, "done_learned_skill")
			AudioController.play_sfx("skillup")
			learned_text(skill_name, panel.pos)
			yield(get_tree().create_timer(1 * GameManager.spd, true), "timeout")
		panel.unit.changed()
	yield(get_tree().create_timer(1 * GameManager.spd, true), "timeout")
	emit_signal("battle_done")

func _on_Tab_Pressed(tab) -> void:
	var index = tab.get_index()
	if cur_tab == index: return

	AudioController.select()
	toggle_tabs(index)

func _on_Close_pressed():
	print("Closing tooltip")
	AudioController.back()
	enemy_info.hide()
