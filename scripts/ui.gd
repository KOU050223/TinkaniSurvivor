extends CanvasLayer

@onready var hp_bar: ProgressBar = $VBoxContainer/HBoxContainer/HPBar
@onready var xp_bar: ProgressBar = $VBoxContainer/HBoxContainer2/XPBar
@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var time_label: Label = $TimeLabel
@onready var wave_label: Label = $WaveLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var time_result_label: Label = $GameOverPanel/VBoxContainer/TimeResultLabel
@onready var retry_button: Button = $GameOverPanel/VBoxContainer/RetryButton

var game_manager: Node = null
var player: Node = null

func _ready() -> void:
	game_over_panel.visible = false
	wave_label.visible = false
	retry_button.pressed.connect(_on_retry_button_pressed)

	await get_tree().process_frame
	_find_nodes()

func _find_nodes() -> void:
	var gm_nodes = get_tree().get_nodes_in_group("game_manager")
	if not gm_nodes.is_empty():
		game_manager = gm_nodes[0]
		game_manager.game_over.connect(_on_game_over)
		game_manager.wave_changed.connect(_on_wave_changed)

	var player_nodes = get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		player = player_nodes[0]

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	# HP バー更新
	hp_bar.max_value = player.MAX_HP
	hp_bar.value = player.hp

	# XP バー更新
	var xp_needed = player.level * player.XP_PER_LEVEL
	xp_bar.max_value = xp_needed
	xp_bar.value = player.xp

	# レベル表示
	level_label.text = "Lv: %d" % player.level

	# 時間表示
	if game_manager != null and is_instance_valid(game_manager):
		var t: int = int(game_manager.get_elapsed_time())
		var t_min: int = t / 60
		var t_sec: int = t % 60
		time_label.text = "%02d:%02d" % [t_min, t_sec]

func _on_game_over(survival_time: float) -> void:
	var total_sec: int = int(survival_time)
	var minutes: int = total_sec / 60
	var seconds: int = total_sec % 60
	time_result_label.text = "生存時間: %02d:%02d" % [minutes, seconds]
	game_over_panel.visible = true

func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Wave %d" % wave
	wave_label.visible = true
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(wave_label):
		wave_label.visible = false

func _on_retry_button_pressed() -> void:
	get_tree().reload_current_scene()
