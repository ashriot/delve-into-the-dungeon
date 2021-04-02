extends Control

onready var panels = $Panels
onready var all_selector = $AllSelector

func init(battle) -> void:
	var i = 0
	for panel in panels.get_children():
		if i >= battle.players.size(): panel.hide()
		else: panel.init(battle, battle.players[i])
		i += 1
	hide_all_selectors()

func get_children():
	return panels.get_children()

func show_selectors(player: PlayerPanel, target_type):
	if target_type == Enum.TargetType.MYSELF:
		player.targetable(true, true)
	elif target_type == Enum.TargetType.ANY_ALLY:
		show_all_selectors()
	elif target_type == Enum.TargetType.OTHER_ALLIES_ONLY:
		show_all_selectors()
	elif target_type == Enum.TargetType.OTHER_ALLY:
		show_all_selectors()
	elif target_type == Enum.TargetType.ALL_ALLIES:
		show_all_selectors()
	elif target_type == Enum.TargetType.RANDOM_ALLY:
		show_all_selectors()

func show_all_selectors():
	for child in panels.get_children():
		child.targetable(true, true)

func show_all_selector():
	all_selector.show()
	for child in panels.get_children():
		child.targetable(true, false)

func hide_all_selectors():
	for child in panels.get_children():
		child.targetable(false)
