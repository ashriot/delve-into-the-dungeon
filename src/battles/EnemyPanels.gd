extends Control

onready var front_row = $FrontRow
onready var back_row = $BackRow
onready var all_select = $AllSelect
onready var front_select = $FrontSelect
onready var back_select = $BackSelect

var projected_hit: Hit
var hit_stat: int

func init(battle, enemies: Array) -> void:
	var i = 0
	for panel in front_row.get_children():
		if i >= enemies.size(): panel.hide()
		elif enemies[i] == null: panel.hide()
		else:
			panel.init(battle, enemies[i])
		i += 1
	i = 3
	for panel in back_row.get_children():
		if i >= enemies.size(): panel.hide()
		elif enemies[i] == null: panel.hide()
		else: panel.init(battle, enemies[i])
		i += 1
	hide_all_selectors()

func get_row(panel: EnemyPanel) -> Array:
	var row = []
	for enemy in panel.get_parent().get_children():
		if enemy.enabled and enemy.alive(): row.append(enemy)
	return row

func get_all() -> Array:
	var all = []
	for enemy in front_row.get_children():
		if enemy.enabled and enemy.alive(): all.append(enemy)
	for enemy in back_row.get_children():
		if enemy.enabled and enemy.alive(): all.append(enemy)
	return all

func get_children():
	return front_row.get_children() + back_row.get_children()

func front_row_dead() -> bool:
	for child in front_row.get_children():
		if child.alive(): return false
	return true

func show_selectors(target_type):
	if target_type == Enum.TargetType.ONE_ENEMY:
		show_front_row_selectors()
		show_back_row_selectors()
	elif target_type == Enum.TargetType.ONE_FRONT:
		show_front_row_selectors()
	elif target_type == Enum.TargetType.ONE_BACK:
		show_back_row_selectors()
	elif target_type == Enum.TargetType.ANY_ROW:
		show_front_row_selector()
		show_back_row_selector()
	elif target_type == Enum.TargetType.FRONT_ROW:
		show_front_row_selector()
	elif target_type == Enum.TargetType.BACK_ROW:
		show_back_row_selector()
	elif target_type == Enum.TargetType.ALL_ENEMIES:
		show_all_selector()

func show_front_row_selector():
	if front_row_dead():
		show_back_row_selector()
		return
	front_select.show()
	for child in front_row.get_children():
		child.update_hit_chance(projected_hit)
		child.targetable(true, false)

func show_back_row_selector():
	back_select.show()
	for child in back_row.get_children():
		child.update_hit_chance(projected_hit)
		child.targetable(true, false)

func show_front_row_selectors():
	if front_row_dead():
		show_back_row_selectors()
		return
	for child in front_row.get_children():
		child.update_hit_chance(projected_hit)
		child.targetable(true)

func show_back_row_selectors():
	for child in back_row.get_children():
		child.update_hit_chance(projected_hit)
		child.targetable(true)

func show_all_selector():
	all_select.show()
	for child in front_row.get_children():
		child.update_hit_chance(projected_hit)
		child.targetable(true, false)
	for child in back_row.get_children():
		child.update_hit_chance(projected_hit)
		child.targetable(true, false)

func hide_all_selectors():
	all_select.hide()
	front_select.hide()
	back_select.hide()
	for child in front_row.get_children():
		child.targetable(false)
	for child in back_row.get_children():
		child.targetable(false)

func update_item_stats(hit: Hit) -> void:
	projected_hit = hit
	hit_stat = hit.item.stat_hit
