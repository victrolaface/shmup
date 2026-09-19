extends Node2D

const SUB_BOSS_SCENE := preload("res://sub_boss/sub_boss.tscn")
const SUB_BOSS_BAR_WIDTH := 400.0
const PIP_EMPTY := Color(0.25, 0.25, 0.3, 1)
const PIP_FILLED := Color(1, 0.85, 0.2, 1)
const LEVEL_BANNER_DURATION := 2.0
const LEVEL_1_1_INTERVAL_SCALE := 2.2

@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var restart_button: Button = $UI/RestartButton
@onready var close_button: Button = $UI/CloseButton
@onready var pause_label: Label = $UI/PauseLabel
@onready var god_mode_label: Label = $UI/GodModeLabel
@onready var level_label: Label = $UI/LevelLabel
@onready var super_pips: Array[ColorRect] = [
	$UI/SuperMeter/Pip0, $UI/SuperMeter/Pip1, $UI/SuperMeter/Pip2
]
@onready var sub_boss_bar: Node2D = $UI/SubBossBar
@onready var sub_boss_bar_fill: ColorRect = $UI/SubBossBar/Fill
@onready var sub_boss_timer: Timer = $SubBossTimer
@onready var player: Player = $Entities/Player
@onready var entities: Node2D = $Entities
@onready var spawner: Spawner = $Entities/Spawner
@onready var formation_spawner: FormationSpawner = $Entities/FormationSpawner
@onready var ground_spawner: GroundSpawner = $Entities/GroundSpawner

var is_paused: bool = false
var is_game_over: bool = false
var level_major: int = 1
var level_minor: int = 1

func _ready() -> void:
	Game.score_changed.connect(_on_score_changed)
	Game.game_over.connect(_on_game_over)
	Game.reset()

	player.super_charge_changed.connect(_on_super_charge_changed)
	_on_super_charge_changed(0)

	player.god_mode_changed.connect(_on_god_mode_changed)

	sub_boss_bar.visible = false
	_show_level_banner()
	_set_spawn_interval_scale(LEVEL_1_1_INTERVAL_SCALE)

func _set_spawn_interval_scale(interval_scale: float) -> void:
	spawner.interval_scale = interval_scale
	formation_spawner.interval_scale = interval_scale
	ground_spawner.interval_scale = interval_scale

func _on_pause_input() -> void:
	if is_game_over:
		return
	_toggle_pause()

func _toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_label.visible = is_paused

func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE: %d" % new_score

func _on_god_mode_changed(active: bool) -> void:
	god_mode_label.visible = active

func _on_super_charge_changed(charge: int) -> void:
	for i in super_pips.size():
		super_pips[i].color = PIP_FILLED if i < charge else PIP_EMPTY

func _show_level_banner() -> void:
	level_label.text = "LEVEL %d-%d" % [level_major, level_minor]
	level_label.visible = true
	var tween := create_tween()
	tween.tween_interval(LEVEL_BANNER_DURATION)
	tween.tween_callback(func() -> void: level_label.visible = false)

func _on_sub_boss_timer_timeout() -> void:
	spawner.stop_spawning()
	formation_spawner.stop_spawning()
	ground_spawner.stop_spawning()

	var sub_boss := SUB_BOSS_SCENE.instantiate() as SubBoss
	sub_boss.position = Vector2(2900, 720)
	entities.add_child(sub_boss)
	sub_boss.health_changed.connect(_on_sub_boss_health_changed)
	sub_boss.defeated.connect(_on_sub_boss_defeated)

	sub_boss_bar.visible = true

func _on_sub_boss_health_changed(current: int, max_health: int) -> void:
	sub_boss_bar_fill.size.x = SUB_BOSS_BAR_WIDTH * (float(current) / float(max_health))

func _on_sub_boss_defeated() -> void:
	sub_boss_bar.visible = false

	level_minor += 1
	_show_level_banner()
	_set_spawn_interval_scale(1.0)

	spawner.resume_spawning()
	formation_spawner.resume_spawning()
	ground_spawner.resume_spawning()
	sub_boss_timer.start()

func _on_game_over() -> void:
	is_game_over = true
	game_over_label.visible = true
	restart_button.visible = true
	close_button.visible = true
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_close_pressed() -> void:
	get_tree().quit()
