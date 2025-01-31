extends Control
class_name PlayerPanels

onready var panels = $Panels
onready var all_selector = $AllSelector

func init(battle) -> void:
	for panel in panels.get_children():
		panel.init(battle)
	hide_all_selectors()

func setup(players: Dictionary, enc_lv: int) -> void:
	var i = 0
	for panel in panels.get_children():
		if i >= players.size(): panel.clear()
		else:
			panel.enc_lv = enc_lv
			panel.setup(players[i])
		i += 1

func get_all() -> Array:
	var all = []
	for panel in panels.get_children():
		all.append(panel)
	return all

func get_random() -> Array:
	var array = get_all()
	if array == []: return []
	return [array[randi() % array.size()]]

func get_children():
	return panels.get_children()

func get_child(index: int):
	return panels.get_child(index)

func show_selectors(player: PlayerPanel, target_type):
	if target_type == Enums.TargetType.MYSELF:
		player.targetable(true, true)
	elif target_type == Enums.TargetType.ANY_ALLY:
		show_all_selectors()
	elif target_type == Enums.TargetType.OTHER_ALLIES_ONLY:
		show_all_selector()
	elif target_type == Enums.TargetType.OTHER_ALLY:
		show_all_except_self(player)
	elif target_type == Enums.TargetType.ALL_ALLIES:
		show_all_selector()
	elif target_type == Enums.TargetType.RANDOM_ALLY:
		show_all_selectors()

func show_all_except_self(hero):
	for child in panels.get_children():
		if child == hero: continue
		child.targetable(true, true)

func show_all_selectors():
	for child in panels.get_children():
		child.targetable(true, true)

func show_all_selector():
	all_selector.show()
	for child in panels.get_children():
		child.targetable(true, false)

func hide_all_selectors():
	all_selector.hide()
	for child in panels.get_children():
		child.targetable(false)
