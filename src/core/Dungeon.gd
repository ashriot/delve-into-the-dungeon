extends Node2D

const EnemyScene = preload("res://src/dungeon/EnemyNode.tscn")

signal fade_out
signal fade_in

## ENEMY CLASS
class EnemyNode extends Reference:
	var sprite
	var tile
	var dead = false
	var dungeon

	func _init(_dungeon, enemy_type, enemy_level, x, y):
		dungeon = _dungeon
		tile = Vector2(x, y)
		sprite = EnemyScene.instance()
		sprite.frame = enemy_type + 30
		sprite.position = tile * TILE_SIZE
		dungeon.add_child(sprite)

	func remove():
		sprite.queue_free()

	func collide():
		print("Collided!")
#		dungeon.battle_start()
		if dead: return
		else:
			dead = true

	func act(game):
		if !sprite.visible: return

		var point = game.enemy_pathfinding.get_closest_point(Vector3(tile.x, tile.y, 0))
		var player_point = game.enemy_pathfinding.get_closest_point(Vector3(game.player_tile.x, game.player_tile.y, 0))
		var path = game.enemy_pathfinding.get_point_path(point, player_point)
		if path:
#			assert(path.size() > 1)
			var move_tile = Vector2(path[1].x, path[1].y)

			if move_tile == game.player_tile:
				collide()
			else:
				var blocked = false
				for enemy in game.enemies:
					if enemy.tile == move_tile:
						blocked = true
						break

				if !blocked:
					tile = move_tile

################################################

const TILE_SIZE = 8

const LEVEL_SIZES = [
	Vector2(30, 30),
	Vector2(35, 35),
	Vector2(40, 40),
	Vector2(45, 45),
	Vector2(50, 50),
]

const LEVEL_ROOM_COUNTS = [5, 7, 9, 12, 15]
const LEVEL_ENEMY_COUNTS = [6, 9, 12, 16, 20]
const MIN_ROOM_DIMENSION = 5
const MAX_ROOM_DIMENSION = 8

onready var tile_map = $TileMap
onready var visibility_map = $VisibilityMap
onready var player = $Player
onready var level = $CanvasLayer/HUD/Level
onready var hud = $CanvasLayer/HUD

enum Tile {Floor, Stone, Wall, Door, StairsDown, StairsUp}

var level_num = 0 setget set_level_num
var map = []
var rooms = []
var level_size: Vector2
var enemies = []

var game
var player_tile
var enemy_pathfinding
var active = false

func _ready() -> void:
	hud.show()
	self.level_num = 1
	build_level()

func init(_game):
	game = _game
	connect("fade_out", game, "_on_FadeOut")
	connect("fade_in", game, "_on_FadeIn")

func _input(event):
	if !active or !event.is_pressed(): return

	var dir = null
	if event is InputEventMouseButton:
		var pos = player.get_local_mouse_position()
		if pos.x < 0.0 and abs(pos.x) > abs(pos.y):
			dir = "Left"
		elif pos.x > 5.0 and abs(pos.x) > abs(pos.y):
			dir = "Right"
		elif pos.y < 0.0:
			dir = "Up"
		elif pos.y > 7.0:
			dir = "Down"
		else: dir = "Stay"

	if event.is_action("Up") or dir == "Up": try_move(0, -1)
	elif event.is_action("Down") or dir == "Down": try_move(0, 1)
	elif event.is_action("Left") or dir == "Left": try_move(-1, 0)
	elif event.is_action("Right") or dir == "Right": try_move(1, 0)
	else: try_move(0, 0)

func try_move(dx, dy):
	var x = player_tile.x + dx
	var y = player_tile.y + dy

	var tile_type = Tile.Stone
	if x >= 0 and x < level_size.x and y >= 0 and y < level_size.y:
		tile_type = map[x][y]

	var blocked = false
	match tile_type:
		Tile.Wall: blocked = false
		Tile.Stone: blocked = false
		Tile.Floor:
			for enemy in enemies:
				if enemy.tile.x == x and enemy.tile.y == y:
					enemy.collide()
					blocked = true
					break
		Tile.Door:
			blocked = true
			set_tile(x, y, Tile.Floor)
		Tile.StairsDown:
			active = false
			emit_signal("fade_out")
			yield(game, "done_fading")
			self.level_num += 1
			if level_num < LEVEL_SIZES.size():
				build_level()
			else:
				$CanvasLayer/Win.show()

	if !blocked:
		$Player/Sprite/AnimationPlayer.play("Hop")
		player_tile = Vector2(x, y)

	for enemy in enemies:
		enemy.act(self)
		if enemy.dead:
			enemy.remove()
			enemies.erase(enemy)

	call_deferred("update_visuals")

func build_level():
	rooms.clear()
	map.clear()
	tile_map.clear()

	for enemy in enemies:
		enemy.remove()
	enemies.clear()

	enemy_pathfinding = AStar.new()

	level_size = LEVEL_SIZES[level_num]
	for x in range(level_size.x):
		map.append([])
		for y in range(level_size.y):
			map[x].append(Tile.Stone)
			tile_map.set_cell(x, y, Tile.Stone)
			visibility_map.set_cell(x, y, 0)

	var free_regions = [Rect2(Vector2(2, 2), level_size - Vector2(4, 4))]
	var num_rooms = LEVEL_ROOM_COUNTS[level_num]
	for _i in range(num_rooms):
		add_room(free_regions)
		if free_regions.empty():
			break

	connect_rooms()

	# Place Player

	yield(get_tree().create_timer(0.1, true), "timeout")

	print("Placing Player")
	var start_room = rooms.front()
	var player_x = start_room.position.x + 1 + randi() % int(start_room.size.x - 2)
	var player_y = start_room.position.y + 1 + randi() % int(start_room.size.y - 2)
	player_tile = Vector2(player_x, player_y)

	# Place Enemies

	var num_enemies = LEVEL_ENEMY_COUNTS[level_num]
	for _i in range(num_enemies):
		var room = rooms[1 + randi() % (rooms.size() - 1)]
		var x = room.position.x + 1 + randi() % int(room.size.x - 2)
		var y = room.position.y + 1 + randi() % int(room.size.y - 2)

		var blocked = false
		for enemy in enemies:
			if enemy.tile.x == x and enemy.tile.y == y:
				blocked = true
				break

		if !blocked:
			var enemy = EnemyNode.new(self, randi() % 4, level_num, x, y)
			enemies.append(enemy)

	# Place End Ladder

	var end_room = rooms.back()
	var ladder_x = end_room.position.x + 1 + randi() % int(end_room.size.x - 2)
	var ladder_y = end_room.position.y + 1 + randi() % int(end_room.size.y - 2)
	set_tile(ladder_x, ladder_y, Tile.StairsDown)

	call_deferred("update_visuals")
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("fade_in")
	yield(game, "done_fading")
	active = true

func clear_path(tile):
	var new_point = enemy_pathfinding.get_available_point_id()
	enemy_pathfinding.add_point(new_point, Vector3(tile.x, tile.y, 0))
	var points_to_connect = []

	if tile.x > 0 and map[tile.x - 1][tile.y] == Tile.Floor:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x - 1, tile.y, 0)))
	if tile.y > 0 and map[tile.x][tile.y - 1] == Tile.Floor:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x, tile.y - 1, 0)))
	if tile.x < level_size.x - 1 and map[tile.x + 1][tile.y] == Tile.Floor:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x + 1, tile.y, 0)))
	if tile.y < level_size.y - 1 and map[tile.x][tile.y + 1] == Tile.Floor:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x, tile.y + 1, 0)))

	for point in points_to_connect:
		enemy_pathfinding.connect_points(point, new_point)

func update_visuals():
	player.position = player_tile * TILE_SIZE
	yield(get_tree().create_timer(.05), "timeout")
	var player_center = tile_to_pixel_center(player_tile.x, player_tile.y)
	var space_state = get_world_2d().direct_space_state
	for x in range(level_size.x):
		for y in range(level_size.y):
			if visibility_map.get_cell(x, y) == 0:
				var x_dir = 1 if x < player_tile.x else -1
				var y_dir = 1 if y < player_tile.y else -1
				var test_point = tile_to_pixel_center(x, y) + Vector2(x_dir, y_dir) * TILE_SIZE / 2

				var occlusion = space_state.intersect_ray(player_center, test_point)
				if !occlusion or (occlusion.position - test_point).length() < 1:
					visibility_map.set_cell(x, y, -1)

	for enemy in enemies:
		enemy.sprite.position = enemy.tile * TILE_SIZE
		if !enemy.sprite.visible:
			var enemy_center = tile_to_pixel_center(enemy.tile.x, enemy.tile.y)
			var occlusion = space_state.intersect_ray(player_center, enemy_center)
			if !occlusion:
				enemy.sprite.visible = true

func tile_to_pixel_center(x, y):
	return Vector2((x + 0.5) * TILE_SIZE, (y + 0.5) * TILE_SIZE)

func connect_rooms():
	var stone_graph = AStar.new()
	var point_id = 0
	for x in range(level_size.x):
		for y in range(level_size.y):
			if map[x][y] == Tile.Stone:
				stone_graph.add_point(point_id, Vector3(x, y, 0))

				if x > 0 && map[x-1][y] == Tile.Stone:
					var left_point = stone_graph.get_closest_point(Vector3(x - 1, y, 0))
					stone_graph.connect_points(point_id, left_point)

				if y > 0 && map[x][y-1] == Tile.Stone:
					var above_point = stone_graph.get_closest_point(Vector3(x, y - 1, 0))
					stone_graph.connect_points(point_id, above_point)

				point_id += 1

	var room_graph = AStar.new()
	point_id = 0
	for room in rooms:
		var room_center = room.position + room.size / 2
		room_graph.add_point(point_id, Vector3(room_center.x, room_center.y, 0))
		point_id += 1

	while !is_everything_connected(room_graph):
		add_random_connection(stone_graph, room_graph)

func is_everything_connected(graph):
	var points = graph.get_points()
	var start = points.pop_back()
	for point in points:
		var path = graph.get_point_path(start, point)
		if !path:
			return false
	return true

func add_random_connection(stone_graph, room_graph):
	var start_room_id = get_least_connected_point(room_graph)
	var end_room_id = get_nearest_unconnected_point(room_graph, start_room_id)

	var start_position = pick_random_door_location(rooms[start_room_id])
	var end_position = pick_random_door_location(rooms[end_room_id])

	var closest_start_point = stone_graph.get_closest_point(start_position)
	var closest_end_point = stone_graph.get_closest_point(end_position)

	var path = stone_graph.get_point_path(closest_start_point, closest_end_point)
	assert(path)

	set_tile(start_position.x, start_position.y, Tile.Door)
	set_tile(end_position.x, end_position.y, Tile.Door)

	for position in path:
		set_tile(position.x, position.y, Tile.Floor)

	room_graph.connect_points(start_room_id, end_room_id)

func get_least_connected_point(graph):
	var point_ids = graph.get_points()

	var least
	var tied_for_least = []

	for point in point_ids:
		var count = graph.get_point_connections(point).size()
		if !least or count < least:
			least = count
			tied_for_least = [point]
		elif count == least:
			tied_for_least.append(point)

	return tied_for_least[randi() % tied_for_least.size()]

func get_nearest_unconnected_point(graph, target_point):
	var target_position = graph.get_point_position(target_point)
	var point_ids = graph.get_points()

	var nearest
	var tied_for_nearest = []

	for point in point_ids:
		if point == target_point:
			continue

		var path = graph.get_point_path(point, target_point)
		if path:
			continue

		var dist = (graph.get_point_position(point) - target_position).length()
		if !nearest or dist < nearest:
			nearest = dist
			tied_for_nearest = [point]
		elif dist == nearest:
			tied_for_nearest.append(point)

	return tied_for_nearest[randi() % tied_for_nearest.size()]

func pick_random_door_location(room):
	var options = []

	for x in range(room.position.x + 1, room.end.x - 2):
		options.append(Vector3(x, room.position.y, 0))
		options.append(Vector3(x, room.end.y - 1, 0))

	for y in range(room.position.y + 1, room.end.y - 2):
		options.append(Vector3(room.position.x, y, 0))
		options.append(Vector3(room.end.x - 1, y, 0))

	return options[randi() % options.size()]

func add_room(free_regions):
	var region = free_regions[randi() % free_regions.size()]

	var size_x = MIN_ROOM_DIMENSION
	if region.size.x > MIN_ROOM_DIMENSION:
		size_x += randi() % int(region.size.x - MIN_ROOM_DIMENSION)

	var size_y = MIN_ROOM_DIMENSION
	if region.size.y > MIN_ROOM_DIMENSION:
		size_y += randi() % int(region.size.y - MIN_ROOM_DIMENSION)

	size_x = min(size_x, MAX_ROOM_DIMENSION)
	size_y = min(size_y, MAX_ROOM_DIMENSION)

	var start_x = region.position.x
	if region.size.x > size_x:
		start_x += randi() % int(region.size.x - size_x)

	var start_y = region.position.y
	if region.size.y > size_y:
		start_y += randi() % int(region.size.y - size_y)

	var room = Rect2(start_x, start_y, size_x, size_y)
	rooms.append(room)

	for x in range(start_x, start_x + size_x):
		set_tile(x, start_y, Tile.Wall)
		set_tile(x, start_y + size_y - 1, Tile.Wall)

	for y in range(start_y + 1, start_y + size_y - 1):
		set_tile(start_x, y, Tile.Wall)
		set_tile(start_x + size_x - 1, y, Tile.Wall)

		for x in range(start_x + 1, start_x + size_x - 1):
			set_tile(x, y, Tile.Floor)

	cut_regions(free_regions, room)

func cut_regions(free_regions, region_to_remove):
	var removal_queue = []
	var addition_queue = []

	for region in free_regions:
		if region.intersects(region_to_remove):
			removal_queue.append(region)

			var leftover_left = region_to_remove.position.x - region.position.x - 1
			var leftover_right = region.end.x - region_to_remove.end.x - 1
			var leftover_above = region_to_remove.position.y - region.position.y - 1
			var leftover_below = region.end.y - region_to_remove.end.y - 1

			if leftover_left >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(region.position, Vector2(leftover_left, region.size.y)))
			if leftover_right >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(Vector2(region_to_remove.end.x + 1, region.position.y), Vector2(leftover_right, region.size.y)))
			if leftover_above >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(region.position, Vector2(region.size.x, leftover_above)))
			if leftover_below >= MIN_ROOM_DIMENSION:
				addition_queue.append(Rect2(Vector2(region.position.x, region_to_remove.end.y + 1), Vector2(region.size.x, leftover_below)))

	for region in removal_queue:
		free_regions.erase(region)

	for region in addition_queue:
		free_regions.append(region)

func set_tile(x, y, type):
	map[x][y] = type
	tile_map.set_cell(x, y, type)

	if type == Tile.Floor:
		clear_path(Vector2(x, y))

func battle_start():
	hud.hide()
	game.battle_start()

func _on_Button_pressed() -> void:
	self.level_num = 0
	build_level()
	$CanvasLayer/Win.hide()

func set_level_num(value):
	level_num = value
	$CanvasLayer/HUD/Level.text = "Lv. " + str(value)
