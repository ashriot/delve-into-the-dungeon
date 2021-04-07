extends KinematicBody2D

var tile_size = 8
var turn = false
var move_speed = 0.3

var lt = 0
var rt = 0
var up = 0
var dn = 0

func _physics_process(delta: float) -> void:
	if turn:
		if lt <= 0 and rt <= 0 and dn <= 0 and up <= 0:
			turn = false

	if up > 0:
		global_position.y -= move_speed
		up -= move_speed
	if lt > 0:
		global_position.x -= move_speed
		lt -= move_speed
	if dn > 0:
		global_position.y += move_speed
		dn -= move_speed
	if rt > 0:
		global_position.x += move_speed
		rt -= move_speed

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("ui_up") and !$U.is_colliding() and !turn:
		$AnimationPlayer.play("Walk")
		turn = true
		up = tile_size
	if Input.is_action_pressed("ui_left") and !$L.is_colliding() and !turn:
		$AnimationPlayer.play("Walk")
		turn = true
		lt = tile_size
	if Input.is_action_pressed("ui_down") and !$D.is_colliding() and !turn:
		$AnimationPlayer.play("Walk")
		turn = true
		dn = tile_size
	if Input.is_action_pressed("ui_right") and !$R.is_colliding() and !turn:
		$AnimationPlayer.play("Walk")
		turn = true
		rt = tile_size
