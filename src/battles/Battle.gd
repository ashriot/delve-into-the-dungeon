extends Control

var DamageText = preload("res://src/battles/DamageText.tscn")
var draw_arcana = preload("res://resources/actions/skills/arcana/draw_arcana.tres")
var step_ids = ["Blade Step", "Mystic Step", "Mana Step", "Butterfly Step", "Bee Step"]

signal enemy_done
signal battle_done
signal action_used(action, user)

onready var player_panels = $PlayerPanels
onready var enemy_panels = $EnemyPanels
onready var buttons = $Buttons
onready var tab1 = $Tabs/Tab1
onready var tab2 = $Tabs/Tab2
onready var rush := $Rush as Button
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

onready var cp_dance = $CurrentPlayer/Resources/Dance
onready var cp_step1 = $CurrentPlayer/Resources/Dance/Step1
onready var cp_step2 = $CurrentPlayer/Resources/Dance/Step2
onready var cp_step3 = $CurrentPlayer/Resources/Dance/Step3
onready var cp_step4 = $CurrentPlayer/Resources/Dance/Step4

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
	rush.hide()
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
	var unit = cur_player.unit
	cp_portrait.frame = unit.frame + 20
	cp_name.text = unit.name
	cp_ap.bbcode_text = str(cur_player.ap)
	cp_quick.modulate.a = 1.0 if cur_player.quick_actions > 0 else .1
	rush.disabled = cur_player.sp < 8
	cp_sorcery.hide()
	cp_perform.hide()
	cp_dance.hide()
	if unit.job == "Sorcerer":
		var sp_cur = unit.job_data["sp_cur"]
		var sp_max = unit.job_data["sp_max"]
		cp_sp_cur.rect_size.x = sp_cur * 3
		cp_sp_cur.rect_position.x = 17 - sp_max * 3
		cp_sp_max.rect_size.x = sp_max * 3
		cp_sp_max.rect_position.x = 17 - sp_max * 3
		cp_sorcery.show()
	if unit.job == "Bard":
		var bp_cur = unit.job_data["bp_cur"]
		var bp_max = unit.job_data["bp_max"]
		cp_bp_cur.rect_size.x = (bp_cur * 3 - (1 if bp_cur > 1 else 0))
		cp_bp_cur.rect_position.x = 16 - (bp_max * 3 - (1 if bp_max > 1 else 0))
		cp_bp_max.rect_size.x = (bp_max * 3 - (1 if bp_max > 1 else 0))
		cp_bp_max.rect_position.x = 16 - (bp_max * 3 - (1 if bp_max > 1 else 0))
		cp_perform.show()
	if unit.job == "Dancer":
		cp_dance.show()
		var steps = unit.job_data["steps"] as Array
		var max_steps = 2
		for i in range(cp_dance.get_child_count()):
			var child = cp_dance.get_child(i) as Sprite
			child.show()
			if steps.size() > i:
				child.frame = steps[i]
			else:
				if i < max_steps: child.frame = 7
				else: child.hide()
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
	rush.show()

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
	if cur_btn:
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
	if not panel: return
	if !panel.ready: return
	if cur_btn:
		cur_btn = null
		enemy_panels.hide_all_selectors()
	if cur_player == panel:
		cur_player.selected = false
		cur_player = null
		buttons.hide()
		rush.hide()
		cp_panel.hide()
		tab1.hide()
		tab2.hide()
		battleMenu.show()
		AudioController.back()
		return
	if cur_player: cur_player.selected = false
	if beep: AudioController.confirm()
	battleMenu.hide()
	cur_player = panel
	panel.selected = true
	setup_buttons()

func start_players_turns() -> void:
	if not battle_active: return
	var wait = true
	for panel in player_panels.get_children():
		if panel.alive: panel.ready = true
		if panel.has_perk("Healing Tune"):
			var potency = int(panel.get_stat(Enums.StatType.INT) * 0.2)
			show_text("Healing Tune", panel.pos)
			AudioController.play_sfx("perform")
			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
			heal_party(potency)
			yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
			wait = false
	if wait: yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
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
			yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
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
		panel.remove_bane(panel.get_bane("Stun"))
		yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	if panel.has_bane("Sleep"):
		var roll = randi() % 100
		if roll < 25:
			panel.remove_bane(panel.get_bane("Sleep"))
			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
		else:
			panel.trigger_bane("Sleep")
			stunned = true
	if stunned: yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	else:
		var action = panel.get_action()
		AudioController.play_sfx(action.use_fx)
		show_text(action.name, panel.pos)
		panel.anim.play("Hit")
		yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
		# TODO: Add friendly targeting.
		var targets = get_enemy_targets(panel, action)
		var randoms = [] # Fix random targeting
		var rand_targets = action.target_type == Enums.TargetType.RANDOM_ENEMY
		var hits = randi() % (1 + action.max_hits - action.min_hits) + action.min_hits
		for hit_num in hits:
			if rand_targets:
				targets = player_panels.get_random()
				if targets == []: break
			var split = targets.size()
			for target in targets:
				if not target.alive: continue
				var hit = Hit.new()
				var potency = action.multiplier
				hit.init(action, panel, split, potency, target)
				hit.targets = targets.size()
				if action.target_type < Enums.TargetType.ONE_ENEMY:
					target.take_friendly_hit(panel, action)
				else: target.take_hit(hit)
			if action.target_type >= Enums.TargetType.ANY_ROW:
				AudioController.play_sfx(action.sound_fx)
			if hit_num < hits - 1:
				yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
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

func show_dmg_text(text: String, pos: Vector2, crit: bool) -> void:
	var damage_text = DamageText.instance()
	damage_text.rect_position = pos
	damage_text.init(self, text, crit)

func show_text(text: String, pos: Vector2, display = false) -> void:
	var damage_text = DamageText.instance()
	damage_text.rect_global_position = pos
	if display: damage_text.display(self, text)
	else: damage_text.text(self, text)

func dmg_dealt(dmg: int, user: BattlePanel, action: Action, crit: bool) -> void:
	pass

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
	if button.item.name == "Inspect": return
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
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
	if "Siphon" in action.name: target_type += max((cur_player.unit.job_data["sp_cur"] - 1), 0) * 3
	if (cur_player.unit.job_tab == "Knives" and \
		action.sub_type == Enums.SubItemType.KNIFE):
			target_type = Enums.TargetType.ONE_ENEMY
			melee_penalty = false
	if target_type >= Enums.TargetType.MYSELF \
		and target_type <= Enums.TargetType.RANDOM_ALLY:
		player_panels.show_selectors(cur_player, action.target_type)
	var split = 1
	var hit = Hit.new()
	var potency = button.item.multiplier
	hit.init(button.item, cur_player, split, potency)
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
		enemy_desc.text += "\n\nSTR: " + str(panel.unit.strength) + "   AGI: " + str(panel.unit.agility)
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

func check_dance():
	var item = cur_btn.item as Item
	var user = cur_player as PlayerPanel
	var steps = user.unit.job_data["steps"] as Array
	var max_steps = 2
	if "Step" in item.name:
		if steps.size() > 0: revert_dance()
		var step_id = step_ids.find(item.name)

		var action = ItemDb.get_item(item.reverted_action_name)
		cur_player.unit.items[cur_btn.get_index()] = action
		if user.unit.job_data["steps"].size() == max_steps:
			user.unit.job_data["steps"].pop_front()
		user.unit.job_data["steps"].append(step_id)
	else:
		revert_dance()
		match (item.name):
			"Blade Dance":
				item.min_hits = steps.size()
				item.max_hits = steps.size()
			"Mystic Mambo":
				print(item.multiplier, " ", steps.size())
				item.multiplier *= steps.size()
			"Mana Mambo":
				item.multiplier *= steps.size()
	for i in range(cp_dance.get_child_count()):
		var child = cp_dance.get_child(i) as Sprite
		if steps.size() > i:
			child.show()
			child.frame = steps[i]
		else:
			if i < max_steps: child.frame = 7
			else: child.hide()

func revert_dance() -> void:
	if cur_player.unit.job_data["steps"].size() == 0: return
	var index = int(6 + ((1 + cur_player.unit.job_data["steps"].back()) / 2))
	print("Dance Index: ", index)
	var item = cur_player.unit.items[index] as Item
	var action = ItemDb.get_item(item.reverted_action_name) as Item
	cur_player.unit.items[index] = action

func check_fighter() -> void:
	var item = cur_btn.item as Item
	var user = cur_player as PlayerPanel
	if item.name == "Slash": return
	var action = ItemDb.get_item(item.reverted_action_name) as Item
	print(action.name)
	cur_player.unit.items[5] = action

func execute_vs_enemy(panel) -> void:
	cur_player.crit_round = false
	var gained_xp = false
	var item = cur_btn.item as Item
	var user = cur_player as PlayerPanel
	var quick = (item.quick or cur_player.hasted) and cur_player.quick_actions > 0 or item.instant
	if item.max_uses > 0: cur_btn.uses_remain -= 1
	var target_type = item.target_type
	if item.sub_type == Enums.SubItemType.SORCERY:
		if "Siphon" in item.name: target_type += max((cur_player.unit.job_data["sp_cur"] - 1), 0) * 3
		if item.name == "Mana Darts":
			item.min_hits = 1 + cur_player.unit.job_data["sp_cur"]
			item.max_hits = 1 + cur_player.unit.job_data["sp_cur"]
	var ap_cost = cur_btn.ap_cost
	if item.sub_type == Enums.SubItemType.PERFORM:
		var bp = min(user.unit.job_data["bp_cur"], ap_cost)
		user.unit.job_data["bp_cur"] -= bp
		ap_cost -= bp
	if user.unit.job == "Dancer": check_dance()
	if user.unit.job == "Fighter": check_fighter()
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
	finish_action(!quick, item.instant)
	show_text(item.name, user.pos)
	yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	user.ap += item.gain_ap
	var hits = randi() % (1 + item.max_hits - item.min_hits) + item.min_hits
	var targets = [panel]
	var randoms = []
	var rand_targets = false
	if target_type >= Enums.TargetType.ANY_ROW \
		and target_type <= Enums.TargetType.BACK_ROW:
		targets = enemy_panels.get_row(panel)
	if target_type == Enums.TargetType.ALL_ENEMIES or \
		target_type == Enums.TargetType.RANDOM_ENEMY:
		targets = enemy_panels.get_all()
	if target_type == Enums.TargetType.RANDOM_ENEMY: rand_targets = true
	if cur_player.has_boon("Aim"):
		cur_player.remove_boon(cur_player.get_boon("Aim"))
	var all_hits = []
	var gain_block = 0
	for hit_num in hits:
		if rand_targets:
			targets = enemy_panels.get_random()
			if targets == []: break
		for target in targets:
			if not target.alive: continue
			var split = 1
			if item.split: split = targets.size()
			var hit = Hit.new()
			hit.init(item, cur_player, split, item.multiplier, target)
			hit.targets = targets.size()
			var data = target.take_hit(hit)
			if "dmg" in data: all_hits.append(data["dmg"])
			if "xp" in data: gained_xp = data["xp"]
			if item.name == "Parry":
				var dmg = all_hits.max()
				gain_block = dmg
			if randoms.size() > 0: if not target.alive: rand_targets.remove(hit_num)
		if target_type >= Enums.TargetType.ANY_ROW:
			AudioController.play_sfx(item.sound_fx)
		if hit_num < hits - 1:
			yield(get_tree().create_timer(0.33 * GameManager.spd), "timeout")
	if user.has_perk("Deflection") and item.melee:
		var dmg = all_hits.max()
		gain_block = int(dmg * user.get_perk("Deflection") * 0.05)
	if user.blocking < gain_block:
		yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
		user.blocking = gain_block
		show_dmg_text("+" + str(gain_block), user.pos, false)
	if item.damage_type >= Enums.DamageType.MARTIAL \
	and item.damage_type < Enums.DamageType.HEAL \
	and user.has_boon("Brave"):
		user.remove_boon(user.get_boon("Brave"))
	for target in targets:
		if target.has_bane("Fear"):
			target.remove_bane(target.get_bane("Fear"))
	if gained_xp: user.calc_xp(item.stat_used)
	if item.sub_type == Enums.SubItemType.SORCERY:
		user.unit.job_data["sp_cur"] = 0
		if quick:
			setup_cur_player_panel()
			setup_buttons()
	user.calc_xp(item.stat_hit, 0.25)
	if not cur_btn: return
	emit_signal("action_used", cur_btn.item, cur_player)
	if quick:
		if user == panel:
			setup_cur_player_panel()
			get_tree().call_group("battle_btns", "update_ap_cost")
		cur_btn = null
	else: get_next_player()

func execute_vs_player(panel) -> void:
	var user = cur_player as PlayerPanel
	var item = cur_btn.item as Item
	var quick = (item.quick or cur_player.hasted) and cur_player.quick_actions > 0 or item.instant
	if item.max_uses > 0: cur_btn.uses_remain -= 1
	var ap_cost = cur_btn.ap_cost
	if user.unit.job == "Sorcerer" and item.sub_type != Enums.SubItemType.SORCERY:
		user.unit.job_data["sp_cur"] = min(user.unit.job_data["sp_cur"] + 1, user.unit.job_data["sp_max"])
	if item.sub_type == Enums.SubItemType.PERFORM:
		var bp = min(user.unit.job_data["bp_cur"], ap_cost)
		user.unit.job_data["bp_cur"] -= bp
		ap_cost -= bp
	if quick: setup_cur_player_panel()
	if user.unit.job == "Dancer": check_dance()
	if user.unit.job == "Fighter": check_fighter()
	user.ap -= ap_cost
	if cur_btn.item.sub_type == Enums.SubItemType.ARCANA:
		if cur_btn.item.name != "Draw Arcana":
			cur_player.unit.items[cur_btn.item_index] = draw_arcana
			cur_player.unit.job_data["arcana"] += 1
			if quick: setup_buttons()
	if user.unit.job == "Bard" and item.sub_type != Enums.SubItemType.PERFORM:
		var bp_max = user.unit.job_data["bp_max"]
		user.unit.job_data["bp_cur"] = min(user.unit.job_data["bp_cur"] + 1, user.unit.job_data["bp_max"])
		if quick: setup_cur_player_panel()
	AudioController.play_sfx(item.use_fx)
	if item.sub_type == Enums.SubItemType.SHIELD:
		if user.has_perk("Quick Block"):
			quick = true
	finish_action(not quick)
	show_text(item.name, user.pos)
	yield(get_tree().create_timer(0.5 * GameManager.spd, false), "timeout")
	if item.gain_ap > 0:
		panel.ap += item.gain_ap
		var ap_text = "+" + str(item.gain_ap) + "AP"
		show_text(ap_text, user.pos)
	var targets = [panel]
	if item.target_type == Enums.TargetType.ALL_ALLIES:
		targets = player_panels.get_children()
	if item.target_type == Enums.TargetType.OTHER_ALLIES_ONLY:
		targets = player_panels.get_children()
		targets.remove(targets.find(user))
	cur_player.calc_xp(item.stat_used)
	var hits = randi() % (1 + item.max_hits - item.min_hits) + item.min_hits
	AudioController.play_sfx(item.sound_fx)
	var rand_targets = item.target_type == Enums.TargetType.RANDOM_ALLY
	for hit_num in hits:
		if rand_targets: targets = player_panels.get_random()
		if not targets: break
		for target in targets:
			if not target.alive: continue
			target.take_friendly_hit(user, item)
		if hit_num > hits - 1:
			yield(get_tree().create_timer(0.33 * GameManager.spd, false), "timeout")
	emit_signal("action_used", cur_btn.item, cur_player)
	if quick:
		if user == panel:
			setup_cur_player_panel()
			get_tree().call_group("battle_btns", "update_ap_cost")
		setup_buttons()
		cur_btn = null
	else: get_next_player()

func finish_action(spend_turn: = true, instant: = false) -> void:
	chose_next = false
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
	if not cur_btn: return
	else: cur_btn.selected = false
	if spend_turn:
		cur_player.quick_actions = 0
		cur_player.selected = false
		clear_buttons()
		cur_player.ready = false
	else:
		if not instant: cur_player.quick_actions -= 1
		setup_buttons()

func clear_selections() -> void:
	enemy_panels.hide_all_selectors()
	player_panels.hide_all_selectors()
	if cur_player:
		cur_player.selected = false
		cur_player = null
	if cur_btn:
		cur_btn.selected = false
		cur_btn = null
	cp_panel.hide()

func roll() -> int:
	return randi() % 100 + 1

func heal_party(amt) -> void:
	for panel in player_panels.get_children():
		panel.take_healing(amt)

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
			if panel.unit.job_skill == Enums.SubItemType.NA or \
				panel.unit.job_skill == Enums.SubItemType.ARCANA: break
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

func _on_Rush_pressed():
	if not cur_player: return
	if cur_player.rushing:
		AudioController.back()
		rush.self_modulate = "#f0eae3"
	else:
		AudioController.play_sfx("flame")
		rush.self_modulate = "#a884f3"
	cur_player.rushing = not cur_player.rushing
