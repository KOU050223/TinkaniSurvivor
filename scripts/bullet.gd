extends Area2D

var direction: Vector2 = Vector2.RIGHT
const SPEED: float = 800.0
const DAMAGE: int = 20

func _ready() -> void:
	# 黄色の小円を動的生成
	var polygon = Polygon2D.new()
	polygon.color = Color(1, 1, 0)
	var points = PackedVector2Array()
	var radius = 8.0
	var num_points = 12
	for i in range(num_points):
		var angle = i * TAU / num_points
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	polygon.polygon = points
	add_child(polygon)

	body_entered.connect(_on_body_entered)

	# LifeTimer で自動消去
	var life_timer = $LifeTimer
	life_timer.timeout.connect(queue_free)
	life_timer.start()

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(DAMAGE)
		queue_free()
