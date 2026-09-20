extends Node2D

const SUB_BOSS_SCENE := preload("res://sub_boss/sub_boss.tscn")
const SUB_BOSS_BAR_WIDTH := 400.0
const SUPER_BAR_WIDTH := 120.0
const LEVEL_BANNER_DURATION := 2.0
const LEVEL_1_1_INTERVAL_SCALE := 2.2
const HEART_SCALE := 1.35
const HEART_SPACING := 58.0
const HEART_FULL := Color(1, 0.25, 0.35, 1)
const HEART_EMPTY := Color(0.25, 0.2, 0.25, 1)
const SHOP_DELAY := 4.0
const UPGRADE_COST := 10
const MAX_SHOP_PURCHASES := 2

@onready var score_label: Label = $UI/ScoreLabel
@onready var health_hearts: Node2D = $UI/HealthHearts
@onready var currency_label: Label = $UI/CurrencyLabel
@onready var game_over_label: Label = $UI/GameOverLabel
@onready var restart_button: Button = $UI/RestartButton
@onready var close_button: Button = $UI/CloseButton
@onready var skip_boss_button: Button = $UI/SkipBossButton
@onready var pause_label: Label = $UI/PauseLabel
@onready var god_mode_label: Label = $UI/GodModeLabel
@onready var level_label: Label = $UI/LevelLabel
@onready var shop_menu: Control = $UI/ShopMenu
@onready var shop_coins_label: Label = $UI/ShopMenu/CoinsLabel
@onready var shop_result_label: Label = $UI/ShopMenu/ResultLabel
@onready var shop_option_buttons: Array[Button] = [
	$UI/ShopMenu/Option0, $UI/ShopMenu/Option1, $UI/ShopMenu/Option2
]
@onready var super_bar_fills: Array[ColorRect] = [
	$UI/SuperMeter/Bar0/Fill, $UI/SuperMeter/Bar1/Fill, $UI/SuperMeter/Bar2/Fill
]
@onready var sub_boss_bar: Node2D = $UI/SubBossBar
@onready var sub_boss_bar_fill: ColorRect = $UI/SubBossBar/Fill
@onready var sub_boss_timer: Timer = $SubBossTimer
@onready var player: Player = $Entities/Player
@onready var entities: Node2D = $Entities
@onready var spawner: Spawner = $Entities/Spawner
@onready var formation_spawner: FormationSpawner = $Entities/FormationSpawner
@onready var ground_spawner: GroundSpawner = $Entities/GroundSpawner
@onready var swarm_spawner: SwarmSpawner = $Entities/SwarmSpawner

var is_paused: bool = false
var is_game_over: bool = false
var shop_open: bool = false
var boss_active: bool = false
var shop_offers: Array[String] = []
var shop_purchases: int = 0
var level_major: int = 1
var level_minor: int = 1

func _ready() -> void:
	Game.score_changed.connect(_on_score_changed)
	Game.currency_changed.connect(_on_currency_changed)
	Game.game_over.connect(_on_game_over)
	Game.reset()

	player.super_meter.progress_changed.connect(_on_super_progress_changed)
	_on_super_progress_changed(0.0)

	player.health.god_mode_changed.connect(_on_god_mode_changed)
	_build_health_hearts(player.health.max_health)
	player.health.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health.health, player.health.max_health)

	sub_boss_bar.visible = false
	_show_level_banner()
	_set_spawn_interval_scale(LEVEL_1_1_INTERVAL_SCALE)

func _set_spawn_interval_scale(interval_scale: float) -> void:
	spawner.interval_scale = interval_scale
	formation_spawner.interval_scale = interval_scale
	ground_spawner.interval_scale = interval_scale
	swarm_spawner.interval_scale = interval_scale

func _on_pause_input() -> void:
	if is_game_over or shop_open:
		return
	_toggle_pause()

func _toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_label.visible = is_paused

func _on_score_changed(new_score: int) -> void:
	score_label.text = "SCORE: %d" % new_score

func _on_currency_changed(new_currency: int) -> void:
	currency_label.text = "%d" % new_currency

func _build_health_hearts(count: int) -> void:
	var points := PackedVector2Array()
	var segments := 32
	for i in segments:
		var t := TAU * float(i) / float(segments)
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(Vector2(x, y) * HEART_SCALE)
	for i in count:
		var heart := Polygon2D.new()
		heart.polygon = points
		heart.position = Vector2(float(i) * HEART_SPACING, 0.0)
		health_hearts.add_child(heart)

func _on_health_changed(current: int, _maximum: int) -> void:
	for i in health_hearts.get_child_count():
		(health_hearts.get_child(i) as Polygon2D).color = HEART_FULL if i < current else HEART_EMPTY

func _on_god_mode_changed(active: bool) -> void:
	god_mode_label.visible = active

func _on_super_progress_changed(progress: float) -> void:
	for i in super_bar_fills.size():
		var fill_ratio: float = clamp(progress - float(i), 0.0, 1.0)
		super_bar_fills[i].size.x = SUPER_BAR_WIDTH * fill_ratio

func _show_level_banner() -> void:
	level_label.text = "LEVEL %d-%d" % [level_major, level_minor]
	level_label.visible = true
	var tween := create_tween()
	tween.tween_interval(LEVEL_BANNER_DURATION)
	tween.tween_callback(func() -> void: level_label.visible = false)

func _on_skip_boss_pressed() -> void:
	if boss_active or shop_open or is_game_over:
		return
	sub_boss_timer.stop()
	_on_sub_boss_timer_timeout()

func _on_sub_boss_timer_timeout() -> void:
	boss_active = true
	skip_boss_button.visible = false
	spawner.stop_spawning()
	formation_spawner.stop_spawning()
	ground_spawner.stop_spawning()
	swarm_spawner.stop_spawning()

	var sub_boss := SUB_BOSS_SCENE.instantiate() as Node2D
	sub_boss.position = Vector2(2900, 720)
	entities.add_child(sub_boss)
	var boss_health := HealthComponent.find(sub_boss)
	boss_health.health_changed.connect(_on_sub_boss_health_changed)
	boss_health.died.connect(_on_sub_boss_defeated)
	_on_sub_boss_health_changed(boss_health.health, boss_health.max_health)

	sub_boss_bar.visible = true

func _on_sub_boss_health_changed(current: int, max_health: int) -> void:
	sub_boss_bar_fill.size.x = SUB_BOSS_BAR_WIDTH * (float(current) / float(max_health))

func _on_sub_boss_defeated() -> void:
	sub_boss_bar.visible = false
	await get_tree().create_timer(SHOP_DELAY).timeout
	if is_game_over:
		return
	_open_shop()

func _open_shop() -> void:
	shop_open = true
	get_tree().paused = true
	shop_offers = player.upgrades.roll_offers(shop_option_buttons.size())
	shop_purchases = 0
	shop_result_label.text = ""
	_refresh_shop()
	shop_menu.visible = true

func _refresh_shop() -> void:
	shop_coins_label.text = "COINS: %d    PURCHASES LEFT: %d" % [Game.currency, MAX_SHOP_PURCHASES - shop_purchases]
	var purchases_left := shop_purchases < MAX_SHOP_PURCHASES
	for i in shop_option_buttons.size():
		var button := shop_option_buttons[i]
		button.visible = i < shop_offers.size()
		if not button.visible:
			continue
		var id := shop_offers[i]
		var upgrade_name: String = UpgradeComponent.UPGRADE_NAMES[id]
		if player.upgrades.can_upgrade(id):
			button.text = "%s  (%d COINS)" % [upgrade_name, UPGRADE_COST]
			button.disabled = not purchases_left or Game.currency < UPGRADE_COST
		else:
			button.text = "%s  (MAXED)" % upgrade_name
			button.disabled = true

func _on_shop_option_pressed(index: int) -> void:
	var id := shop_offers[index]
	if shop_purchases >= MAX_SHOP_PURCHASES or not player.upgrades.can_upgrade(id) or not Game.spend_currency(UPGRADE_COST):
		return
	shop_purchases += 1
	shop_result_label.text = "GOT: " + player.upgrades.apply_upgrade(id)
	_refresh_shop()

func _on_shop_continue_pressed() -> void:
	shop_open = false
	shop_menu.visible = false
	get_tree().paused = is_paused
	_start_next_level()

func _start_next_level() -> void:
	boss_active = false
	skip_boss_button.visible = true
	level_minor += 1
	_show_level_banner()
	_set_spawn_interval_scale(1.0)

	spawner.resume_spawning()
	formation_spawner.resume_spawning()
	ground_spawner.resume_spawning()
	swarm_spawner.resume_spawning()
	sub_boss_timer.start()

func _on_game_over() -> void:
	is_game_over = true
	skip_boss_button.visible = false
	game_over_label.visible = true
	restart_button.visible = true
	close_button.visible = true
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_close_pressed() -> void:
	get_tree().quit()
