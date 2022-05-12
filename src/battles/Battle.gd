extends Control

var DamageText = preload("res://src/battles/DamageText.tscn")
var draw_arcana = preload("res://resources/actions/skills/arcana/draw_arcana.tres")

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
onready var cp_panel = $CurrentPlayer
onready var cp_portrait = $CurrentPlayer/Portrait
onready var cp_name = $CurrentPlayer/Name
onready var cp_ap = $CurrentPlayer/ApValue
onready var cp_quick = $CurrentPlayer/QuickIcon

onready var cp_sorcery = $CurrentPlayer/Resources/Sorcery
onready var cp_sp_cur = $CurrentPlayer/Resources/Sorcery/SpCur
onready var cp_sp_max = $CurrentPlayer/Resources/Sorcery/SpMax

onready var cp_perform = $CurrentPlayer/Resources/Perform
onready var cp_bp_cur = $CurrentPlayer/Resources/Perform/BpCur
onready var cp_bp_max = $CurrentPlayer/Resources/Perform/BpMax

var cur_player: PlayerPanel
var cur_btn = null
var cur_hit_chance: int
var cur_crit_chance: int
var cur_stat_type: int
var player_targets: = [false, false, false, false]

var cur_tab: int
var default_tab_color: Color

var chose_next: bool
var battle_active: bool

var enc_lv: float
var game: Game

# warning-ignore:shadowed_variable
func init(game):
	enemy_info.hide()
	self.game = game
	battle_active = false
	battleMenu.hide()
	cp_panel.hide()
#	for child in buttons.get_children():
#		child.init(self)
	var inspect = load("res://resources/battleCommands/inspect.tres")
	var end_turn = load("res://resources/battleCommands/end_turn.tres")
	var flee = load("res://resources/battleCommands/flee.tres")
	battleMenu.get_child(0).init(self)
	battleMenu.get_child(0).setup(inspect, 0)
	battleMenu.get_child(1).init(self)
	battleMenu.get_child(1).setup(end_turn, 0)
	battleMenu.get_child(2).init(self)
	battleMenu.get_child(2).setup(flee, 0)
	player_panels.init(self)
	enemy_panels.init(self)
	for button in buttons.get_children(): button.init(self)
	tab1.connect("pressed", self, "_on_Tab_Pressed", [tab1])
	tab2.connect("pressed", self, "_on_Tab_Pressed", [tab2])
	default_tab_color = tab1.self_modulate
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

func setup_cur_player_panel() -> void:
	cp_portrait.frame = cur_player.unit.frame + 20
	cp_name.text = cur_player.unit.name
	cp_ap.bbcode_text = str(cur_player.ap)
	var quick_color = "#c32454" if !cur_player.quick_used else "#625565"
	cp_quick.modulate = quick_color
	var unit = cur_player.unit
	if unit.job == "Sorcerer":
		var sp_cur = unit.job_data["sp_cur"]
		var sp_max = unit.job_data["sp_max"]
		cp_sp_cur.rect_size.x = sp_cur * 3
		cp_sp_cur.rect_position.x = 17 - sp_max * 3
		cp_sp_max.rect_size.x = sp_max * 3
		cp_sp_max.rect_position.x = 17 - sp_max * 3
		cp_sorcery.show()
	else:
		cp_sorcery.hide()
	if unit.job == "Bard":
		var bp_cur = unit.job_data["bp_cur"]
		var bp_max = unit.job_data["bp_max"]
		cp_bp_cur.rect_size.x = (bp_cur * 2 + (1 if bp_cur > 0 else 0))
		cp_bp_cur.rect_position.x = 16 - (bp_max * 2 + 1)
		cp_bp_max.rect_size.x = (bp_max * 2 + 1)
		cp_bp_max.rect_position.x = 16 - (bp_max * 2 + 1)
		cp_perform.show()
	else:
		cp_perform.hide()
	cp_panel.show()

func setup_buttons() -> void:
	setup_cur_player_panel()
	var arcana = []
	if cur_player.unit.job == "Seer":
		arcana = ItemDb.get_five_arcana()
	cur_tab = cur_player.tab
	var i = 0
	for button in buttons.get_children():
		if i < cur_player.unit.items.size():
			if cur_player.unit.items[i] == null:
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

func display_tabs() -> void:
	tab1.show()
	tab2.show()
	var other_tab = (cur_tab + 1) % 2
	if other_tab != 0: # Tab 1
		$Tabs/Tab1.self_modulate = Enums.yellow_color
		$Tabs/Tab2.self_modulate = default_tab_color
	else:				# Tab 2
		$Tabs/Tab1.self_modulate = default_tab_color
		$Tabs/Tab2.self_modulate = Enums.yellow_color

	for i in range((other_tab * 5), (other_tab * 5) + 5):
		buttons.get_child(i).toggle(false)
	for i in range((cur_tab * 5), (cur_tab * 5) + 5):
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
	cp_panel.hide()
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
		cp_panel.hide()
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
	cur_player = panel
	panel.selected = true
	setup_buttons()

func start_players_turns() -> void:
	if not battle_active: return
	for panel in player_panels.get_children():
		if panel.alive: panel.ready = true
		panel.ap += 1
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
	yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	for panel in player_panels.get_children():
		panel.decrement_boons("End")
		panel.decrement_banes("End")
	yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	enemy_turns()

func enemy_turns():
	for enemy in enemy_panels.get_children():
		if enemy.enabled and enemy.alive:
			if enemy.blocking > 0: enemy.blocking = 0
			enemy_take_action(enemy)
			yield(self, "enemy_done")
			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	yield(get_tree().create_timer(1 * GameManager.spd), "timeout")
	if not battle_active: return
	start_players_turns()

func enemy_take_action(panel: EnemyPanel):
	if panel.banes.size() > 0:
		panel.decrement_banes("Start")
		yield(panel, "done")
	if not panel.alive:
		call_deferred("emit_signal", "enemy_done")
		return
	var stunned = false
	if panel.has_bane("Stun"):
		stunned = true
	if panel.has_bane("Sleep"):
		var roll = randi() % 100
		if roll < 25:
			panel.remove_bane(panel.get_bane("Sleep"))
			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
		else:
			panel.trigger_bane("Sleep")
			stunned = true
	if stunned: yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	else:
		var action = panel.get_action()
		AudioController.play_sfx(action.use_fx)
		show_text(action.name, panel.pos)
		panel.anim.play("Hit")
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
		# TODO: Add friendly targeting.
		var targets = get_enemy_targets(panel, action)
		var randoms = [] # Fix random targeting
		var rand_targets = false
		var hits = randi() % (1 + action.max_hits - action.min_hits) + action.min_hits
		if action.target_type == Enums.TargetType.RANDOM_ENEMY: rand_targets = true
		for hit_num in hits:
			if rand_targets:
				targets = player_panels.get_random()
				if targets == []: break
			for target in targets:
				if not target.alive: continue
				var atk = panel.get_stat(action.stat_used)
				var dmg_mod = 0
				if action.melee and panel.melee_penalty: dmg_mod -= 0.50
				if action.name == "Drown":
					dmg_mod += (1 - target.unit.hp_percent)
				var hit = Hit.new()
				var hit_chance = 100 if !panel.has_perk("Precise") else 150
				if (action.item_type == Enums.ItemType.MARTIAL_SKILL or \
					action.item_type == Enums.ItemType.WEAPON) and \
					not panel.has_boon("Aim"):
						hit_chance = panel.get_stat(Enums.StatType.AGI)
				hit.init(action, hit_chance, action.crit_chance, 0, dmg_mod, atk, panel)
				if panel.has_bane("Blind"):
					hit.hit_chance /= 2
					hit.item.hit_chance /= 2
					hit.crit_chance = 0
				if action.target_type < Enums.TargetType.ONE_ENEMY:
					target.take_friendly_hit(panel, action)
				else: target.take_hit(hit)
#			if action.target_type >= Enums.TargetType.ANY_ROW:
#				AudioController.play_sfx(action.sound_fx)
			if hit_num < hits - 1:
				yield(get_tree().create_timer(0.33 * GameManager.spd), "timeout")
		for target in targets:
			if target is Player:
				target.gained_xp = false
	panel.decrement_banes("End")
	emit_signal("enemy_done")

func get_enemy_targets(panel: EnemyPanel, action: EnemyAction) -> Array:
	var targets = []
	var choices = []
	var choice = 0
	if action.target_type == Enums.TargetType.MYSELF:
		return [panel]
	if action.target_type == Enums.TargetType.ONE_ENEMY:
		for i in range(player_targets.size()):
			if player_targets[i]: choices.append(i)
		choice = randi() % player_targets.size()
		targets.append(player_panels.get_child(choice))
	if action.target_type == Enums.TargetType.ONE_FRONT:
		for i in range(2):
			if player_targets[i]: choices.append(i)
		if choices.size() == 2: choice = choices[0] if roll() < 51 else choices[1]
		else: choice = choices[0]
		targets.append(player_panels.get_child(choice))
	if action.target_type == Enums.TargetType.FRONT_ROW:
		if player_targets[0] or player_targets[1]:
			for i in range(2): if player_targets[i]: choices.append(i)
		else: for i in range(2, 4): if player_targets[i]: choices.append(i)
		for target in choices: targets.append(player_panels.get_child(target))
	if action.target_type == Enums.TargetType.ANY_ROW:
		var roll = randi() % 2
		if player_targets[0] or player_targets[1] and roll == 0:
			for i in range(2): if player_targets[i]: choices.append(i)
		else: for i in range(2, 4): if player_targets[i]: choices.append(i)
		for target in choices: targets.append(player_panels.get_child(target))
	if action.target_type == Enums.TargetType.RANDOM_ENEMY:
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

func _on_BattleButton_long_pressed(button: BattleButton) -> void:
	AudioController.click()
	$EnemyInfo/Panel.rect_position.y = 1
	enemy_title.text = button.item.name
	enemy_desc.text = button.item.desc
	enemy_info.show()

func _on_BattleButton_pressed(button: BattleButton) -> void:
	if cur_player:
		if not button.available: return
	if button.tooltip: return
	if !battle_active: return
	if button.item.name == "End Turn":
		AudioController.confirm()
		for panel in player_panels.get_children(): panel.ready = false
		clear_buttons()
		end_turn()
		return
	if button.item.name == "Inspect":
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
	var target_type = cur_btn.item.target_type
	var melee_penalty = button.item.melee and cur_player.melee_penalty
	if (cur_player.unit.job_tab == "Knives" and \
		cur_btn.item.sub_type == Enums.SubItemType.KNIFE):
			target_type = Enums.TargetType.ONE_ENEMY
			melee_penalty = false
	if target_type >= Enums.TargetType.MYSELF \
		and target_type <= Enums.TargetType.RANDOM_ALLY:
		player_panels.show_selectors(cur_player, button.item.target_type)
	else:
		if button.item.stat_hit == Enums.StatType.AGI and not cur_player.has_boon("Aim"):
			cur_hit_chance = int(cur_player.get_stat(Enums.StatType.AGI)) \
				 + (50 if cur_player.has_perk("Precise") else 0)
			cur_stat_type = Enums.StatType.AGI
# warning-ignore:integer_division
			cur_crit_chance = int(cur_btn.item.crit_chance)
		else:
			cur_hit_chance = 100
			cur_crit_chance = 0
			cur_stat_type = Enums.StatType.NA
		var dmg_mod = 0
		if melee_penalty: dmg_mod -= 0.50
		if cur_btn.item.sub_type == Enums.SubItemType.SORCERY:
			dmg_mod += cur_player.unit.job_data["sp_cur"] * 0.33
		var atk = cur_player.get_stat(button.item.stat_used)
		var hit = Hit.new()
		hit.init(button.item, cur_hit_chance, cur_crit_chance, 0, dmg_mod, atk, cur_player)
		enemy_panels.update_item_stats(hit)
		enemy_panels.show_selectors(target_type)

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
	if cur_btn and cur_btn.item.target_type <= Enums.TargetType.RANDOM_ALLY:
		if not panel.valid_target: return
		execute_vs_player(panel)
	else:
		chose_next = true
		select_player(panel, true)

func execute_vs_enemy(panel) -> void:
	var gained_xp = false
	var item = cur_btn.item as Item
	var user = cur_player as PlayerPanel
	var quick = item.quick and not cur_player.quick_used
	if item.max_uses > 0: cur_btn.uses_remain -= 1
	var dmg_mod = 0.0
	if item.sub_type == Enums.SubItemType.SORCERY:
		print("SP Cur: ", user.unit.job_data["sp_cur"])
		dmg_mod += user.unit.job_data["sp_cur"] * 0.33
		user.unit.job_data["sp_cur"] = 0
	var ap_cost = cur_btn.ap_cost
	if item.sub_type == Enums.SubItemType.PERFORM:
		var bp = min(user.unit.job_data["bp_cur"], ap_cost)
		user.unit.job_data["bp_cur"] -= bp
		print("BP Cur: ", user.unit.job_data["bp_cur"])
		ap_cost -= bp
		if quick: setup_cur_player_panel()
	user.ap -= ap_cost
	if cur_btn.item.sub_type == Enums.SubItemType.ARCANA:
		cur_player.unit.items[cur_btn.item_index] = draw_arcana
		cur_player.unit.job_data["arcana"] += 1
		if quick: setup_buttons()
	if user.unit.job == "Sorcerer" and item.sub_type != Enums.SubItemType.SORCERY:
		var sp_max = user.unit.job_data["sp_max"]
		user.unit.job_data["sp_cur"] = min(user.unit.job_data["sp_cur"] + 1, user.unit.job_data["sp_max"])
		if quick:
			setup_cur_player_panel()
			setup_buttons()
	if user.unit.job == "Bard" and item.sub_type != Enums.SubItemType.PERFORM:
		var bp_max = user.unit.job_data["bp_max"]
		user.unit.job_data["bp_cur"] = min(user.unit.job_data["bp_cur"] + 1, user.unit.job_data["bp_max"])
		if quick: setup_cur_player_panel()
	AudioController.play_sfx(item.use_fx)
	finish_action(!quick)
	show_text(item.name, user.pos)
	yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	user.ap += item.gain_ap
	var targets = [panel]
	var randoms = []
	var rand_targets = false
	if item.target_type >= Enums.TargetType.ANY_ROW \
		and item.target_type <= Enums.TargetType.BACK_ROW:
		targets = enemy_panels.get_row(panel)
	if item.target_type == Enums.TargetType.ALL_ENEMIES or \
		item.target_type == Enums.TargetType.RANDOM_ENEMY:
		targets = enemy_panels.get_all()
	var hits = randi() % (1 + item.max_hits - item.min_hits) + item.min_hits
	if item.target_type == Enums.TargetType.RANDOM_ENEMY: rand_targets = true
	if cur_player.has_boon("Aim"):
		cur_player.remove_boon(cur_player.get_boon("Aim"))
	for hit_num in hits:
		if rand_targets:
			targets = enemy_panels.get_random()
			if targets == []: break
		for target in targets:
			if not target.alive: continue
			var melee_penalty = item.melee and cur_player.melee_penalty
			if (cur_player.unit.job == "Thief" and item.sub_type == Enums.SubItemType.KNIFE):
				melee_penalty = false
			if melee_penalty: dmg_mod -= 0.50
			var atk = user.get_stat(item.stat_used)
			if user.has_perk("Magic Weapon") and item.sub_type != Enums.SubItemType.WAND:
				atk += int(user.unit.intellect * 0.5)
				cur_hit_chance += 25
			var hit = Hit.new()
			var split = 1
			if item.split: split = targets.size()
			print("Damage Mod: ", dmg_mod)
			hit.init(item, cur_hit_chance, cur_crit_chance, 0, dmg_mod, atk, cur_player, split)
			gained_xp = target.take_hit(hit)
			if randoms.size() > 0: if not target.alive: rand_targets.remove(hit_num)
		if item.target_type >= Enums.TargetType.ANY_ROW:
			AudioController.play_sfx(item.sound_fx)
		if hit_num < hits - 1:
			yield(get_tree().create_timer(0.33 * GameManager.spd), "timeout")
	if gained_xp: user.calc_xp(item.stat_used)
	user.calc_xp(item.stat_hit, 0.25)
	if quick:
		if user == panel:
			setup_cur_player_panel()
			get_tree().call_group("battle_btns", "update_ap_cost")
		cur_btn = null
	else: get_next_player()

func execute_vs_player(panel) -> void:
	var user = cur_player
	var item = cur_btn.item as Item
	var quick = item.quick and not cur_player.quick_used
	if item.max_uses > 0: cur_btn.uses_remain -= 1
	var ap_cost = cur_btn.ap_cost
	if item.sub_type == Enums.SubItemType.PERFORM:
		var bp = min(user.unit.job_data["bp_cur"], ap_cost)
		user.unit.job_data["bp_cur"] -= bp
		ap_cost -= bp
		if quick: setup_cur_player_panel()
	user.ap -= ap_cost
	if cur_btn.item.sub_type == Enums.SubItemType.ARCANA:
		if cur_btn.item.name != "Draw Arcana":
			cur_player.unit.items[cur_btn.item_index] = draw_arcana
			cur_player.unit.job_data["arcana"] += 1
			if quick: setup_buttons()
	AudioController.play_sfx(item.use_fx)
	if item.sub_type == Enums.SubItemType.SHIELD:
		if user.has_perk("Quick Block"):
			quick = true
	finish_action(not quick)
	show_text(item.name, user.pos)
	yield(get_tree().create_timer(0.5 * GameManager.spd, false), "timeout")
	panel.ap += item.gain_ap
	var targets = [panel]
	if item.target_type == Enums.TargetType.ALL_ALLIES:
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
	if quick:
		if user == panel:
			setup_cur_player_panel()
			get_tree().call_group("battle_btns", "update_ap_cost")
		if cur_btn.item.name == "Draw Arcana": setup_buttons()
		cur_btn = null
	else: get_next_player()

func finish_action(spend_turn: = true) -> void:
	chose_next = false
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
	if cur_btn == null: return
	else: cur_btn.selected = false
	if spend_turn:
		cur_player.quick_used = false
		cur_player.selected = false
		clear_buttons()
		cur_player.ready = false
	else:
		cur_player.quick_used = true
		setup_buttons()

func clear_selections() -> void:
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
	if cur_player != null:
		cur_player.selected = false
		cur_player = null
	if cur_btn != null:
		cur_btn.selected = false
		cur_btn = null
	cp_panel.hide()

func roll() -> int:
	return randi() % 100 + 1

func _on_EnemyPanel_died(panel: EnemyPanel) -> void:
	var done = true
	for enemy in enemy_panels.get_children():
		if enemy.enabled and enemy.alive:
			done = false
	if done: battle_active = false
	yield(get_tree().create_timer(0.25 * GameManager.spd, true), "timeout")
	AudioController.play_sfx("die")
	panel.clear()
	if done: victory()

func _on_PlayerPanel_died(panel: PlayerPanel) -> void:
	pass

func victory() -> void:
	print("VICTORY!!!")
	AudioController.bgm.stop()
	clear_selections()
	clear_buttons()
	yield(get_tree().create_timer(1 * GameManager.spd, true), "timeout")
	$Victory.show()
	AudioController.play_bgm("victory")
	for panel in player_panels.get_children():
		if !panel.enabled: continue
		panel.victory()
		for i in range(panel.unit.gains.size()):
			if panel.unit.gains[i] > 0:
				var amt = panel.unit.gains[i]
				panel.unit.increase_base_stat(i + 1, int(amt))
				show_text(Enums.get_stat_name(i + 1) + "+" + str(amt), panel.pos)
				print(panel.unit.name, " -> ", Enums.get_stat_name(i + 1), " increased by ", amt, "!")
				AudioController.play_sfx("statup")
				yield(get_tree().create_timer(1 * GameManager.spd, true), "timeout")
		var ranks_up = panel.calc_job_xp()
		for _r in range(ranks_up):
			if panel.unit.job_skill == Enums.SubItemType.NA: break
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
