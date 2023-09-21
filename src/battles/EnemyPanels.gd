extends Control
class_name EnemyPanels

onready var front_row = $FrontRow
onready var back_row = $BackRow
onready var all_select = $AllSelect
onready var front_select = $FrontSelect
onready var back_select = $BackSelect

var projected_hit: Hit
var hit_stat: int

func init(ui) -> void:
	for panel in front_row.get_children():
		panel.init(ui)
	for panel in back_row.get_children():
		panel.init(ui)
	hide_all_selectors()

func setup(enemies: Dictionary) -> void:
	var i = 0
	for panel in front_row.get_children():
		var enemy = enemies.get(i)
		if enemy:
			panel.setup(enemy)
		else:
			panel.clear()
		i += 1
	i = 3
	for panel in back_row.get_children():
		var enemy = enemies.get(i)
		if enemy:
			panel.setup(enemy)
		else:
			panel.clear()
		i += 1

func get_row(panel: EnemyPanel) -> Array:
	var row = []
	for enemy in panel.get_parent().get_children():
		if enemy.enabled and enemy.alive: row.append(enemy)
	return row

func get_all() -> Array:
	var all = []
	for enemy in front_row.get_children():
		if enemy.enabled and enemy.alive: all.append(enemy)
	for enemy in back_row.get_children():
		if enemy.enabled and enemy.alive: all.append(enemy)
	return all

func get_random() -> Array:
	var array = get_all()
	if array == []: return []
	return [array[randi() % array.size()]]

func get_children():
	return front_row.get_children() + back_row.get_children()

func front_row_dead() -> bool:
	for child in front_row.get_children():
		if child.alive: return false
	return true

func back_row_active() -> bool:
	for child in back_row.get_children():
		if child.alive or child.enabled:
			return true
	return false

func get_front_count() -> int:
	var count = 0
	for child in front_row.get_children():
		if child.alive: count += 1
	return count

func get_back_count() -> int:
	var count = 0
	for child in back_row.get_children():
		if child.alive: count += 1
	return count

func show_selectors(target_type):
	if target_type == Enums.TargetType.ONE_ENEMY:
		show_front_row_selectors()
		show_back_row_selectors()
	elif target_type == Enums.TargetType.ONE_FRONT:
		show_front_row_selectors()
	elif target_type == Enums.TargetType.ONE_BACK:
		show_back_row_selectors()
	elif target_type == Enums.TargetType.ANY_ROW:
		show_front_row_selector()
		show_back_row_selector()
	elif target_type == Enums.TargetType.FRONT_ROW:
		show_front_row_selector()
	elif target_type == Enums.TargetType.BACK_ROW:
		show_back_row_selector()
	elif target_type == Enums.TargetType.ALL_ENEMIES:
		show_all_selector()
	elif target_type == Enums.TargetType.RANDOM_ENEMY:
		show_all_selector()

func show_front_row_selector():
	if front_row_dead():
		show_back_row_selector()
		return
	front_select.show()
	if projected_hit.action.split:
		projected_hit.split = get_front_count()
	for child in front_row.get_children():
		child.update_hit_chance(projected_hit)
		child.targetable(true, false)

func show_back_row_selector():
	if !back_row_active(): return
	back_select.show()
	if projected_hit.action.split:
		projected_hit.split = get_back_count()
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
	if !back_row_active(): return
	for child in back_row.get_children():
		child.update_hit_chance(projected_hit)
		child.targetable(true)

func show_all_selector():
	all_select.show()
	if projected_hit.action.split:
		projected_hit.split = get_front_count() + get_back_count()
	for child in front_row.get_children():
		child.update_hit_chance(projected_hit)
		child.targetable(true, false)
	if !back_row_active(): return
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

func update_item_stats(hit) -> void:
	projected_hit = hit
	hit_stat = hit.action.stat_hit
