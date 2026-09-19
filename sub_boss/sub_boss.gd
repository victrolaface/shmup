class_name SubBoss
extends Area2D

signal health_changed(current: int, max_health: int)
signal defeated

const CHARGE_PICKUP_SCENE := preload("res://pickup/charge_pickup.tscn")

enum Attack { HOMING_CONE, HORIZONTAL_LINE, SURROUND_STREAM }

@export var approach_speed: float = 220.0
@export var stop_x: float = 1900.0
@export var hover_amplitude: float = 220.0
@export var hover_frequency: float = 0.6
@export var max_health: int = 6000
@export var bullet_scene: PackedScene = preload("res://bullet/bullet_enemy.tscn")
@export var bullet_count: int = 80
@export var bullets_per_tick: int = 8
@export var bullet_speed: float = 1200.0
@export var bullet_damage: int = 1
@export var spread_angle_degrees: float = 200.0
@export var line_cone_angle_degrees: float = 45.0
@export var line_target_y_min: float = 100.0
@export var line_target_y_max: float = 1300.0
@export var stream_arms: int = 10
@export var stream_rotation_speed: float = 1.4
@export var stream_bullet_speed: float = 700.0
@export var attack_interval: float = 2.2
@export var score_value: int = 500
@export var hit_flash_duration: float = 0.15
@export var flash_color: Color = Color(1, 0.15, 0.15, 1)
@export var charge_pickup_count: int = 5
@export var charge_pickup_spread: float = 420.0

@onready var attack_cooldown: Timer = $AttackCooldown
@onready var visual: Polygon2D = $Visual

var health: int
var entered: bool = false
var base_y: float
var time: float = 0.0
var bullets_remaining: int = 0
var active_attack: int = Attack.HOMING_CONE
var next_attack: int = Attack.HOMING_CONE
var line_center_dir: Vector2 = Vector2.LEFT
var stream_angle: float = 0.0
var base_color: Color
var flash_time: float = 0.0
var hit_flash_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("sub_boss")
	health = max_health
	base_y = position.y
	attack_cooldown.wait_time = attack_interval
	health_changed.emit(health, max_health)
	base_color = visual.color

func _physics_process(delta: float) -> void:
	if not entered:
		position.x -= approach_speed * delta
		if position.x <= stop_x:
			position.x = stop_x
			entered = true
			attack_cooldown.start()
		return

	time += delta
	position.y = base_y + sin(time * hover_frequency) * hover_amplitude

	_update_hit_flash(delta)

	if bullets_remaining > 0:
		_fire_barrage_tick(delta)

func _update_hit_flash(delta: float) -> void:
	flash_time += delta
	hit_flash_timer = max(hit_flash_timer - delta, 0.0)

	var danger: float = 1.0 - clamp(float(health) / float(max_health), 0.0, 1.0)
	var flash_frequency := 2.0 + danger * 12.0
	var ambient_flash := (sin(flash_time * flash_frequency) * 0.5 + 0.5) * danger
	var instant_flash := hit_flash_timer / hit_flash_duration

	var flash: float = max(ambient_flash, instant_flash)
	visual.color = base_color.lerp(flash_color, flash)

func take_damage(amount: int) -> void:
	health -= amount
	hit_flash_timer = hit_flash_duration
	health_changed.emit(max(health, 0), max_health)
	if health <= 0:
		Game.add_score(score_value)
		_spawn_charge_pickups()
		defeated.emit()
		queue_free()

func _spawn_charge_pickups() -> void:
	for i in charge_pickup_count:
		var pickup := CHARGE_PICKUP_SCENE.instantiate() as Node2D
		var offset := Vector2(randf_range(-charge_pickup_spread, charge_pickup_spread), randf_range(-charge_pickup_spread, charge_pickup_spread))
		pickup.global_position = global_position + offset
		get_parent().call_deferred("add_child", pickup)

func _on_attack_cooldown_timeout() -> void:
	active_attack = next_attack
	next_attack = (next_attack + 1) % 3
	bullets_remaining = bullet_count
	if active_attack == Attack.HORIZONTAL_LINE:
		var target_y := randf_range(line_target_y_min, line_target_y_max)
		line_center_dir = (Vector2(0.0, target_y) - global_position).normalized()
	elif active_attack == Attack.SURROUND_STREAM:
		stream_angle = 0.0

func _fire_barrage_tick(delta: float) -> void:
	var per_tick := bullets_per_tick
	if active_attack == Attack.SURROUND_STREAM:
		per_tick = stream_arms
	var count: int = min(per_tick, bullets_remaining)

	match active_attack:
		Attack.HOMING_CONE:
			_fire_homing_cone_tick(count)
		Attack.HORIZONTAL_LINE:
			_fire_horizontal_line_tick(count)
		Attack.SURROUND_STREAM:
			_fire_surround_stream_tick(count, delta)

	bullets_remaining -= count

func _fire_homing_cone_tick(count: int) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var half_spread := deg_to_rad(spread_angle_degrees / 2.0)

	for i in count:
		var angle := randf_range(-half_spread, half_spread)
		var bullet := bullet_scene.instantiate() as Bullet
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.direction = Vector2.LEFT.rotated(angle)
		bullet.speed = bullet_speed
		bullet.damage = bullet_damage
		if player != null and is_instance_valid(player):
			bullet.homing_target = player

func _fire_horizontal_line_tick(count: int) -> void:
	var half_spread := deg_to_rad(line_cone_angle_degrees / 2.0)
	for i in count:
		var angle := randf_range(-half_spread, half_spread)
		var bullet := bullet_scene.instantiate() as Bullet
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.direction = line_center_dir.rotated(angle)
		bullet.speed = bullet_speed
		bullet.damage = bullet_damage

func _fire_surround_stream_tick(count: int, delta: float) -> void:
	for i in count:
		var angle := stream_angle + (TAU / stream_arms) * i
		var bullet := bullet_scene.instantiate() as Bullet
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.direction = Vector2.RIGHT.rotated(angle)
		bullet.speed = stream_bullet_speed
		bullet.damage = bullet_damage
	stream_angle += stream_rotation_speed * delta
