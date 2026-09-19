extends Area2D

const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")
const SMOKE_SCENE := preload("res://effects/smoke.tscn")
const CHARGE_PICKUP_SCENE := preload("res://pickup/charge_pickup.tscn")
const JEWEL_SCENE := preload("res://pickup/jewel.tscn")
const HIT_FLASH_DURATION := 0.15
const FLASH_COLOR := Color(1, 0.15, 0.15, 1)

@export var approach_speed: float = 240.0
@export var stop_x_min: float = 1200.0
@export var stop_x_max: float = 2000.0
@export var health: int = 5
@export var score_value: int = 25
@export var jewel_drop_chance: float = 0.25
@export var bullet_scene: PackedScene = preload("res://bullet/bullet_enemy.tscn")
@export var bullet_speed: float = 700.0
@export var fire_interval: float = 0.18
@export var pattern_speed: float = 1.6
@export var pattern_radius: float = 6.0

@onready var visual: Polygon2D = $Visual
@onready var fire_timer: Timer = $FireTimer

var stop_x: float
var entered: bool = false
var pattern_time: float = 0.0
var max_health: int
var base_color: Color
var flash_time: float = 0.0
var hit_flash_timer: float = 0.0
var dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	stop_x = randf_range(stop_x_min, stop_x_max)
	fire_timer.wait_time = fire_interval
	max_health = health
	base_color = visual.color
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if dead:
		return

	if not entered:
		position.x -= approach_speed * delta
		if position.x <= stop_x:
			position.x = stop_x
			entered = true
			fire_timer.start()
		if position.x < -100.0:
			queue_free()
		return

	pattern_time += delta
	_update_hit_flash(delta)

func _update_hit_flash(delta: float) -> void:
	flash_time += delta
	hit_flash_timer = max(hit_flash_timer - delta, 0.0)

	var danger: float = 1.0 - clamp(float(health) / float(max_health), 0.0, 1.0)
	var flash_frequency := 2.0 + danger * 12.0
	var ambient_flash := (sin(flash_time * flash_frequency) * 0.5 + 0.5) * danger
	var instant_flash := hit_flash_timer / HIT_FLASH_DURATION

	var flash: float = max(ambient_flash, instant_flash)
	visual.color = base_color.lerp(FLASH_COLOR, flash)

func _on_area_entered(area: Area2D) -> void:
	if dead or not is_instance_valid(area):
		return
	if area.is_in_group("player") and area.has_method("take_damage"):
		area.take_damage(1)
		take_damage(max_health)

func _on_fire_timer_timeout() -> void:
	if dead:
		return
	var t := pattern_time * pattern_speed
	var dir := Vector2(sin(t), sin(2.0 * t)).normalized()
	var bullet := bullet_scene.instantiate() as Bullet
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	bullet.direction = dir
	bullet.speed = bullet_speed

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	hit_flash_timer = HIT_FLASH_DURATION
	if health <= 0:
		_die()

func _die() -> void:
	dead = true
	Game.add_score(score_value)
	_spawn_explosion()
	_spawn_smoke()
	_spawn_charge_pickup()
	if randf() < jewel_drop_chance:
		_spawn_jewel()
	queue_free()

func _spawn_explosion() -> void:
	var explosion := EXPLOSION_SCENE.instantiate() as Node2D
	explosion.global_position = global_position
	get_parent().add_child(explosion)

func _spawn_smoke() -> void:
	var smoke := SMOKE_SCENE.instantiate() as Node2D
	smoke.global_position = global_position
	get_parent().add_child(smoke)

func _spawn_charge_pickup() -> void:
	var pickup := CHARGE_PICKUP_SCENE.instantiate() as Node2D
	pickup.global_position = global_position
	get_parent().call_deferred("add_child", pickup)

func _spawn_jewel() -> void:
	var jewel := JEWEL_SCENE.instantiate() as Node2D
	jewel.global_position = global_position
	get_parent().call_deferred("add_child", jewel)
