extends CharacterBody2D

signal died

@export var bullet_scene: PackedScene

const SPEED = 200.0
const MAX_HP = 100
const XP_PER_LEVEL = 50

var hp: int = MAX_HP
var xp: int = 0
var level: int = 1
var shoot_cooldown: float = 0.8
var damage_cooldown: float = 0.0

@onready var shoot_timer: Timer = $ShootTimer

func _ready() -> void:
	add_to_group("player")
	shoot_timer.wait_time = shoot_cooldown
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()

func _physics_process(delta: float) -> void:
	if damage_cooldown > 0:
		damage_cooldown -= delta

	var direction = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	velocity = direction * SPEED
	move_and_slide()

	# 画面外に出ないよう制限
	var viewport_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, viewport_size.x)
	position.y = clamp(position.y, 0, viewport_size.y)

func take_damage(amount: int) -> void:
	if damage_cooldown > 0:
		return
	damage_cooldown = 1.0
	hp -= amount
	# 赤フラッシュ
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.2).timeout
	modulate = Color(1, 1, 1)

	if hp <= 0:
		hp = 0
		died.emit()

func gain_xp(amount: int) -> void:
	xp += amount
	var xp_needed = level * XP_PER_LEVEL
	if xp >= xp_needed:
		xp -= xp_needed
		_level_up()

func _level_up() -> void:
	level += 1
	# 射撃速度アップ
	shoot_cooldown = max(0.2, shoot_cooldown - 0.05)
	shoot_timer.wait_time = shoot_cooldown
	# HP回復
	hp = min(MAX_HP, hp + 20)

func _on_shoot_timer_timeout() -> void:
	if bullet_scene == null:
		return
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	# 最近接の敵を探す
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	if nearest == null:
		return

	var direction = (nearest.global_position - global_position).normalized()
	var bullet = bullet_scene.instantiate()
	bullet.direction = direction
	bullet.global_position = global_position

	# BulletContainer に追加
	var bullet_container = get_tree().get_first_node_in_group("bullet_container")
	if bullet_container:
		bullet_container.add_child(bullet)
	else:
		get_parent().add_child(bullet)
