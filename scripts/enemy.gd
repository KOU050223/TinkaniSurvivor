extends CharacterBody2D

const BASE_SPEED: float = 120.0
const BASE_HP: int = 30
const DAMAGE: int = 10
const XP_REWARD: int = 5

var speed: float = BASE_SPEED
var hp: int = BASE_HP
var contact_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemies")

	# 赤い円を動的生成
	var polygon = Polygon2D.new()
	polygon.color = Color(1, 0.2, 0.2)
	var points = PackedVector2Array()
	var radius = 38.0
	var num_points = 20
	for i in range(num_points):
		var angle = i * TAU / num_points
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	polygon.polygon = points
	add_child(polygon)

	# CollisionShape2D を動的生成
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 38.0
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	if contact_cooldown > 0:
		contact_cooldown -= delta

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return

	var player = players[0]
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	# プレイヤーとの接触判定
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider != null and collider.is_in_group("player"):
			_deal_damage_to_player(collider)

func _deal_damage_to_player(player: Node) -> void:
	if contact_cooldown > 0:
		return
	contact_cooldown = 1.0
	player.take_damage(DAMAGE)

func take_damage(amount: int) -> void:
	hp -= amount
	# ダメージフラッシュ
	modulate = Color(1, 1, 1, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1, 1)
	if hp <= 0:
		_die()

func _die() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		players[0].gain_xp(XP_REWARD)
	queue_free()

func apply_difficulty(wave: int) -> void:
	hp = BASE_HP + (wave - 1) * 15
	speed = BASE_SPEED + (wave - 1) * 20.0
