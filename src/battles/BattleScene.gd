extends Control

enum BattleStates {
	BATTLE_START,
	PLAYER_PHASE_START,
	PLAYER_PHASE,
	PLAYER_PHASE_END,
	ENEMY_PHASE_START,
	ENEMY_PHASE,
	ENEMY_PHASE_END,
	WAITING,
	VICTORY,
	DEFEAT
}

var state_functions = {
	BattleStates.BATTLE_START: funcref(self, "_battle_start"),
	BattleStates.PLAYER_PHASE_START: funcref(self, "_state_player_start"),
	BattleStates.PLAYER_PHASE: funcref(self, "_state_player_phase"),
	BattleStates.PLAYER_PHASE_END: funcref(self, "_state_player_end"),
	BattleStates.ENEMY_PHASE_START: funcref(self, "_state_enemy_start"),
	BattleStates.ENEMY_PHASE: funcref(self, "_state_enemy_phase"),
	BattleStates.ENEMY_PHASE_END: funcref(self, "_state_enemy_end"),
	BattleStates.WAITING: funcref(self, "_state_waiting"),
	BattleStates.VICTORY: funcref(self, "_state_victory"),
	BattleStates.DEFEAT: funcref(self, "_state_defeat")
}

signal battle_done
signal action_used(action, user)
signal player_start

onready var ui = $BattleUI as BattleUI

var battle_active: bool
var current_state: int
var player_data: Dictionary
var enemy_data: Dictionary
var enc_lv: float

var chose_next: bool

func init():
	battle_active = false
	visible = false
	connect("player_start", ui, "_on_player_start")

func start(players: Dictionary, enemies: Dictionary) -> void:
	$Victory.hide()
	init_enemies(enemies)
	ui.setup_hero_panels(players, enc_lv)
	ui.init()
	player_data = players
	enemy_data = enemies
	change_state(BattleStates.BATTLE_START)


func init_enemies(enemies: Dictionary) -> void:
	enc_lv = 0.0
	var num_of_enemies = 0

	for key in enemies.keys():
		enc_lv += enemies[key][1]
		num_of_enemies += 1

	ui.setup_enemy_panels(enemies)
	enc_lv /= num_of_enemies * (1 + float(num_of_enemies - 1) * 0.1)


func change_state(new_state: int) -> void:
	var old_state = current_state
	current_state = new_state
	state_functions[current_state].call_func()


func get_next_player(delay: = true) -> void:
	if !battle_active: return
	if chose_next: return
	if delay: yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	ui.cur_btn = null
	ui.cur_player = null
	for panel in ui.player_panels.get_children():
		if panel.enabled and panel.ready:
			ui.select_player(panel)
			return
	# all player panels are not ready; end phase
	change_state(BattleStates.PLAYER_PHASE_END)


func execute_action_on_enemy(panel: EnemyPanel):
	ui.cur_player.crit_round = false
	var gained_xp = false
	var item = ui.cur_btn.item as Item
	var user = ui.cur_player as PlayerPanel
	var quick = (item.quick or ui.cur_player.hasted) \
		and ui.cur_player.quick_actions > 0
	if item.max_uses > 0:
		ui.cur_btn.uses_remain -= 1
	var ap_cost = ui.cur_btn.ap_cost
	var target_type = item.target_type
	if user.unit.job == "Sorcerer":
		if item.sub_type == Enums.SubItemType.SORCERY:
			var sp = ui.cur_player.unit.job_data["sp_cur"]
			user.unit.job_data["sp_cur"] = 0
			if "Siphon" in item.name: target_type += max((sp - 1), 0) * 3
			if ui.cur_btn.item.name == "Mana Darts":
				ui.cur_btn.item.min_hits = 1 + sp
				ui.cur_btn.item.max_hits = 1 + sp
		else:
			var sp_max = user.unit.job_data["sp_max"]
			user.unit.job_data["sp_cur"] = \
				min(user.unit.job_data["sp_cur"] + 1, \
					user.unit.job_data["sp_max"])
#	if ui.cur_btn.item.sub_type == Enums.SubItemType.ARCANA:
#		ui.cur_player.unit.items[ui.cur_btn.item_index] = draw_arcana
#		ui.cur_player.unit.job_data["arcana"] += 1
#		if quick: setup_buttons()
	if user.unit.job == "Bard":
		if item.sub_type == Enums.SubItemType.PERFORM:
			var bp = min(user.unit.job_data["bp_cur"], ap_cost)
			user.unit.job_data["bp_cur"] -= bp
			ap_cost -= bp
		else:
			var bp_max = user.unit.job_data["bp_max"]
			user.unit.job_data["bp_cur"] = \
				min(user.unit.job_data["bp_cur"] + 1, \
					user.unit.job_data["bp_max"])
	if quick:
		ui.setup_cur_player_panel()
		ui.setup_buttons()
	user.ap -= ap_cost
	AudioController.play_sfx(item.use_fx)
	finish_action(!quick)
	ui.show_text(item.name, user.pos)
	yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	user.ap += item.gain_ap
	var targets = [panel]
	var randoms = []
	var rand_targets = false
	if target_type >= Enums.TargetType.ANY_ROW \
		and target_type <= Enums.TargetType.BACK_ROW:
		targets = ui.enemy_panels.get_row(panel)
	if target_type == Enums.TargetType.ALL_ENEMIES or \
		target_type == Enums.TargetType.RANDOM_ENEMY:
		targets = ui.enemy_panels.get_all()
	var hits = randi() % (1 + item.max_hits - item.min_hits) + item.min_hits
	if target_type == Enums.TargetType.RANDOM_ENEMY: rand_targets = true
	if ui.cur_player.has_boon("Aim"):
		ui.cur_player.remove_boon(ui.cur_player.get_boon("Aim"))
	var all_hits = []
	for hit_num in hits:
		if rand_targets:
			targets = ui.enemy_panels.get_random()
			if targets == []: break
		for target in targets:
			if not target.alive: continue
			var split = 1
			if item.split: split = targets.size()
			var hit = Hit.new()
			hit.init(item, ui.cur_player, split, target)
			hit.targets = targets.size()
			var data = target.take_hit(hit)
			if "dmg" in data: all_hits.append(data["dmg"])
			if "xp" in data: gained_xp = data["xp"]
			if randoms.size() > 0: if not target.alive: \
				rand_targets.remove(hit_num)
		if target_type >= Enums.TargetType.ANY_ROW:
			AudioController.play_sfx(item.sound_fx)
		if hit_num < hits - 1:
			yield(get_tree().create_timer(0.33 * GameManager.spd), "timeout")
	if user.has_perk("Deflection") and item.melee:
		yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
		var dmg = all_hits.max()
		var amt = int(dmg * user.get_perk("Deflection") * 0.05)
		if user.blocking < amt:
			user.blocking = amt
			ui.show_dmg_text("+" + str(amt), user.pos, false)
	if item.damage_type >= Enums.DamageType.MARTIAL \
		and item.damage_type < Enums.DamageType.HEAL \
		and user.has_boon("Brave"):
			user.remove_boon(user.get_boon("Brave"))
	for target in targets:
		if target.has_bane("Fear"):
			target.remove_bane(target.get_bane("Fear"))
	if gained_xp: user.calc_xp(item.stat_used)
	user.calc_xp(item.stat_hit, 0.25)
	if ui.cur_player:
#		emit_signal("action_used", ui.cur_btn.item, ui.cur_player)
		if quick:
			if user == panel:
				ui.setup_ui.cur_player_panel()
				get_tree().call_group("battle_btns", "update_ap_cost")
			ui.cur_btn = null
		else: get_next_player()


func execute_action_on_player(panel: PlayerPanel):
	var user = ui.cur_player
	var item = ui.cur_btn.item as Item
	var quick = (item.quick or ui.cur_player.hasted) \
		and ui.cur_player.quick_actions > 0
	if item.max_uses > 0: ui.cur_btn.uses_remain -= 1
	var ap_cost = ui.cur_btn.ap_cost
	if user.unit.job == "Sorcerer" and item.sub_type != Enums.SubItemType.SORCERY:
		user.unit.job_data["sp_cur"] = \
			min(user.unit.job_data["sp_cur"] + 1, user.unit.job_data["sp_max"])
	if item.sub_type == Enums.SubItemType.PERFORM:
		var bp = min(user.unit.job_data["bp_cur"], ap_cost)
		user.unit.job_data["bp_cur"] -= bp
		ap_cost -= bp
	user.ap -= ap_cost
#	if ui.cur_btn.item.sub_type == Enums.SubItemType.ARCANA:
#		if ui.cur_btn.item.name != "Draw Arcana":
#			ui.cur_player.unit.items[ui.cur_btn.item_index] = draw_arcana
#			ui.cur_player.unit.job_data["arcana"] += 1
#			if quick: setup_buttons()
	if user.unit.job == "Bard" and item.sub_type != Enums.SubItemType.PERFORM:
		var bp_max = user.unit.job_data["bp_max"]
		user.unit.job_data["bp_cur"] = \
			min(user.unit.job_data["bp_cur"] + 1, user.unit.job_data["bp_max"])
	AudioController.play_sfx(item.use_fx)
	if item.sub_type == Enums.SubItemType.SHIELD:
		if user.has_perk("Quick Block"):
			quick = true
	if quick: ui.setup_cur_player_panel()
	finish_action(not quick)
	ui.show_text(item.name, user.pos)
	yield(get_tree().create_timer(0.5 * GameManager.spd, false), "timeout")
	if item.gain_ap > 0:
		panel.ap += item.gain_ap
		var ap_text = "+" + str(item.gain_ap) + "AP"
		ui.show_text(ap_text, user.pos)
	var targets = [panel]
	if item.target_type == Enums.TargetType.ALL_ALLIES:
		targets = ui.player_panels.get_children()
	if item.target_type == Enums.TargetType.OTHER_ALLIES_ONLY:
		targets = ui.player_panels.get_children()
		targets.remove(targets.find(user))
	ui.cur_player.calc_xp(item.stat_used)
	var hits = randi() % (1 + item.max_hits - item.min_hits) + item.min_hits
	AudioController.play_sfx(item.sound_fx)
	for hit_num in hits:
		for target in targets:
			if not target.alive: continue
			target.take_friendly_hit(user, item)
		if hit_num > hits - 1:
			yield(get_tree().create_timer(0.33 * GameManager.spd, false), \
				"timeout")
	emit_signal("action_used", ui.cur_btn.item, ui.cur_player)
	if quick:
		if user == panel:
			ui.setup_cur_player_panel()
			get_tree().call_group("battle_btns", "update_ap_cost")
		ui.setup_buttons()
		ui.cur_btn = null
	else: get_next_player()


# State Functions

func _battle_start() -> void:
	battle_active = true
	visible = true
	ui.cleanup()
	chose_next = false
	yield(get_tree().create_timer(0.1 * GameManager.spd), "timeout")
	change_state(BattleStates.PLAYER_PHASE_START)

func _state_player_start() -> void:
	if not battle_active: return
	var wait = true
	for panel in ui.player_panels.get_children():
		if panel.alive: panel.ready = true
#		if panel.has_perk("Healing Tune"):
#			var potency = int(panel.get_stat(Enums.StatType.INT) * 0.2)
#			show_text("Healing Tune", panel.pos)
#			AudioController.play_sfx("perform")
#			yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
#			heal_party(potency)
#			yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
#			wait = false
	if wait: yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	AudioController.play_sfx("player_turn")
	get_next_player(false)
	emit_signal("player_start")

func _state_player_phase() -> void:
	pass

func _state_player_end() -> void:
	chose_next = false
	yield(get_tree().create_timer(0.25 * GameManager.spd), "timeout")
	for panel in ui.player_panels.get_children():
		panel.decrement_boons("End")
		panel.decrement_banes("End")
	yield(get_tree().create_timer(0.5 * GameManager.spd), "timeout")
	change_state(BattleStates.ENEMY_PHASE_START)

func _state_enemy_start() -> void:
	pass

func _state_enemy_phase() -> void:
	pass

func _state_enemy_end() -> void:
	pass

func _state_waiting() -> void:
	pass

func _state_victory() -> void:
	pass

func _state_defeat() -> void:
	pass


func _on_BattleUI_player_pressed(panel: PlayerPanel):
	execute_action_on_player(panel)


func _on_BattleUI_enemy_pressed(panel: EnemyPanel):
	if !battle_active: return
	execute_action_on_enemy(panel)


func determine_targets():
	pass


func _on_EnemyPanel_died(panel: EnemyPanel) -> void:
	var done = true
	for enemy in ui.enemy_panels.get_children():
		if enemy.enabled and enemy.alive:
			done = false
	if done: battle_active = false
	yield(get_tree().create_timer(0.25 * GameManager.spd, true), "timeout")
	AudioController.play_sfx("die")
	panel.clear()
#	if done: victory()


func finish_action(spend_turn: = true) -> void:
	chose_next = false
	ui.finish_action(spend_turn)
