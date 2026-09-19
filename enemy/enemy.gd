class_name Enemy
extends Area2D

enum Pattern { STRAIGHT, SINE_LIGHT, SINE_HEAVY }

const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")
const SMOKE_SCENE := preload("res://effects/smoke.tscn")
const HIT_FLASH_DURATION := 0.15
const FLASH_COLOR := Color(1, 0.15, 0.15, 1)

@export var pattern: Pattern = Pattern.STRAIGHT
@export var speed: float = 260.0
@export var sine_amplitude: float = 120.0
@export var sine_frequency: float = 1.0
@export var health: int = 3
@export var score_value: int = 10
@export var jewel_drop_chance: float = 0.25
@export var bullet_scene: PackedScene = preload("res://bullet/bullet_enemy.tscn")
@export var bullet_speed: float = 800.0
@export var fire_interval: float = 1.4
@export var contact_damage: int = 1

@onready var visual: Polygon2D = $Visual
@onready var fire_timer: Timer = $FireTimer

var max_health: int
var base_y: float
var time: float = 0.0
var base_color: Color
var flash_time: float = 0.0
var hit_flash_timer: float = 0.0
var dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	max_health = health
	base_y = position.y
	base_color = visual.color
	fire_timer.wait_time = fire_interval
	fire_timer.start()
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if dead:
		return

	time += delta
	position.x -= speed * delta
	match pattern:
		Pattern.SINE_LIGHT:
			position.y = base_y + sin(time * sine_frequency) * sine_amplitude
		Pattern.SINE_HEAVY:
			position.y = base_y + sin(time * sine_frequency) * (sine_amplitude * 1.8)
		_:
			pass

	_update_hit_flash(delta)

	if position.x < -100.0:
		queue_free()

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
		area.take_damage(contact_damage)
		take_damage(max_health)

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
	Drops.enemy_drops(get_parent(), global_position, jewel_drop_chance)
	queue_free()

func _spawn_explosion() -> void:
	var explosion := EXPLOSION_SCENE.instantiate() as Node2D
	explosion.global_position = global_position
	get_parent().add_child(explosion)

func _spawn_smoke() -> void:
	var smoke := SMOKE_SCENE.instantiate() as Node2D
	smoke.global_position = global_position
	get_parent().add_child(smoke)

func _on_fire_timer_timeout() -> void:
	if dead:
		return
	var bullet := bullet_scene.instantiate() as Bullet
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	bullet.direction = Vector2.LEFT
	bullet.speed = bullet_speed
