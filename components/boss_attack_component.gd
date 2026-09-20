class_name BossAttackComponent
extends Component

signal attack_started(attack: int)

enum Attack { HOMING_CONE, HORIZONTAL_LINE, SURROUND_STREAM }

@export var bullet_scene: PackedScene = preload("res://bullet/bullet_enemy.tscn")
@export var attack_interval: float = 2.2
@export var bullet_count: int = 60
@export var bullets_per_tick: int = 8
@export var bullet_speed: float = 900.0
@export var bullet_damage: int = 1
@export var spread_angle_degrees: float = 200.0
@export var line_cone_angle_degrees: float = 45.0
@export var line_target_y_min: float = 100.0
@export var line_target_y_max: float = 1300.0
@export var stream_arms: int = 10
@export var stream_rotation_speed: float = 1.4
@export var stream_bullet_speed: float = 600.0

var active: bool = false
var cooldown: float = 0.0
var bullets_remaining: int = 0
var active_attack: int = Attack.HOMING_CONE
var next_attack: int = Attack.HOMING_CONE
var line_center_dir: Vector2 = Vector2.LEFT
var stream_angle: float = 0.0

func start() -> void:
	active = true
	cooldown = 0.0

func _physics_process(delta: float) -> void:
	if not active:
		return

	cooldown += delta
	if cooldown >= attack_interval:
		cooldown -= attack_interval
		_begin_attack()

	if bullets_remaining > 0:
		_fire_barrage_tick(delta)

func _begin_attack() -> void:
	active_attack = next_attack
	next_attack = (next_attack + 1) % 3
	bullets_remaining = bullet_count
	attack_started.emit(active_attack)
	if active_attack == Attack.HORIZONTAL_LINE:
		var target_y := randf_range(line_target_y_min, line_target_y_max)
		line_center_dir = (Vector2(0.0, target_y) - entity.global_position).normalized()
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

func _spawn_bullet(direction: Vector2, speed: float) -> Bullet:
	var bullet := bullet_scene.instantiate() as Bullet
	entity.get_parent().add_child(bullet)
	bullet.global_position = entity.global_position
	bullet.direction = direction
	bullet.speed = speed
	bullet.damage = bullet_damage
	return bullet

func _fire_homing_cone_tick(count: int) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var half_spread := deg_to_rad(spread_angle_degrees / 2.0)
	for i in count:
		var bullet := _spawn_bullet(Vector2.LEFT.rotated(randf_range(-half_spread, half_spread)), bullet_speed)
		if player != null:
			bullet.homing_target = player

func _fire_horizontal_line_tick(count: int) -> void:
	var half_spread := deg_to_rad(line_cone_angle_degrees / 2.0)
	for i in count:
		_spawn_bullet(line_center_dir.rotated(randf_range(-half_spread, half_spread)), bullet_speed)

func _fire_surround_stream_tick(count: int, delta: float) -> void:
	for i in count:
		_spawn_bullet(Vector2.RIGHT.rotated(stream_angle + (TAU / stream_arms) * i), stream_bullet_speed)
	stream_angle += stream_rotation_speed * delta
