extends Node
class_name BattleFlow

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

var current_state: int

func start() -> void:
	change_state(BattleStates.BATTLE_START)

func change_state(new_state: int) -> void:
	var old_state = current_state
	current_state = new_state
	state_functions[current_state].call_func()


# State Functions

func _battle_start() -> void:
	emit_signal("battle_start")

func _state_player_start() -> void:
	pass

func _state_player_phase() -> void:
	pass

func _state_player_end() -> void:
	pass

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
