extends Node

signal game_over(survival_time: float)
signal wave_changed(wave: int)

@export var enemy_scene: PackedScene

const WAVE_DURATION: float = 30.0
const BASE_SPAWN_INTERVAL: float = 2.0

var elapsed_time: float = 0.0
var current_wave: int = 1
var is_game_over: bool = false
var spawn_timer: float = 0.0

func _ready() -> void:
	add_to_group("game_manager")
	var player_nodes = get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		player_nodes[0].died.connect(on_player_died)

func _process(delta: float) -> void:
	if is_game_over:
		return

	elapsed_time += delta

	# ウェーブ計算
	var new_wave = int(elapsed_time / WAVE_DURATION) + 1
	if new_wave != current_wave:
		current_wave = new_wave
		wave_changed.emit(current_wave)

	# 敵スポーン
	var spawn_interval = BASE_SPAWN_INTERVAL / (1.0 + (current_wave - 1) * 0.3)
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy()

func _spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var spawn_pos = _get_random_spawn_position(viewport_size)

	var enemy = enemy_scene.instantiate()
	enemy.apply_difficulty(current_wave)

	var enemy_container = get_tree().get_first_node_in_group("enemy_container")
	if enemy_container:
		enemy_container.add_child(enemy)
	else:
		get_parent().add_child(enemy)

	enemy.global_position = spawn_pos

func _get_random_spawn_position(viewport_size: Vector2) -> Vector2:
	var margin = 80.0
	var side = randi() % 4
	match side:
		0:  # 上
			return Vector2(randf_range(0, viewport_size.x), -margin)
		1:  # 下
			return Vector2(randf_range(0, viewport_size.x), viewport_size.y + margin)
		2:  # 左
			return Vector2(-margin, randf_range(0, viewport_size.y))
		3:  # 右
			return Vector2(viewport_size.x + margin, randf_range(0, viewport_size.y))
	return Vector2.ZERO

func on_player_died() -> void:
	is_game_over = true
	game_over.emit(elapsed_time)

func get_elapsed_time() -> float:
	return elapsed_time
