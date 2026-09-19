class_name SuperComponent
extends Component

signal progress_changed(progress: float)

@export var bullet_scene: PackedScene = preload("res://bullet/bullet_player.tscn")
@export var max_charge: int = 3
@export var base_radius: float = 300.0
@export var radius_step: float = 200.0
@export var damage_per_charge: int = 4
@export var bullet_count: int = 500
@export var bullets_per_tick: int = 50
@export var bullet_speed: float = 1000.0
@export var expand_duration: float = 1.0
@export var single_target_turn_rate: float = 20.0

var progress: float = 0.0
var charge: int = 0
var nova_active: bool = false
var nova_elapsed: float = 0.0
var nova_bullets_remaining: int = 0
var nova_bullets_spawned: int = 0
var nova_damage: int = 0

func grant_charge(amount: float) -> void:
	progress = min(progress + amount, float(max_charge))
	charge = int(floor(progress))
	progress_changed.emit(progress)

func _physics_process(delta: float) -> void:
	if nova_active:
		nova_elapsed += delta
		if nova_bullets_remaining > 0:
			_fire_nova_tick()
		else:
			nova_active = false

	if charge > 0 and Input.is_action_just_pressed("super"):
		_unleash()

func _unleash() -> void:
	var level := charge
	charge = 0
	progress = 0.0
	progress_changed.emit(progress)

	var radius := base_radius + float(level - 1) * radius_step
	var damage := damage_per_charge * level
	_spawn_blast(radius)
	_clear_nearby(radius, damage)

	nova_damage = damage
	nova_bullets_spawned = 0
	nova_bullets_remaining = bullet_count
	nova_elapsed = 0.0
	nova_active = true

func _clear_nearby(radius: float, damage: int) -> void:
	var targets := get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("enemy_bullets")
	for node in targets:
		var target := node as Node2D
		if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
			continue
		if entity.global_position.distance_to(target.global_position) > radius:
			continue
		var health := HealthComponent.find(target)
		if health != null:
			health.take_damage(damage)
		else:
			target.queue_free()

func _fire_nova_tick() -> void:
	var single_target := get_tree().get_nodes_in_group("enemies").size() == 1
	var count: int = min(bullets_per_tick, nova_bullets_remaining)

	for i in count:
		var angle := (float(nova_bullets_spawned) / bullet_count) * TAU
		var bullet := bullet_scene.instantiate() as Bullet
		entity.get_parent().add_child(bullet)
		bullet.direction = Vector2.RIGHT.rotated(angle)
		bullet.speed = bullet_speed
		bullet.global_position = entity.global_position + bullet.direction * bullet_speed * nova_elapsed
		bullet.damage = nova_damage
		bullet.homing_delay = max(expand_duration - nova_elapsed, 0.0)
		bullet.acquire_nearest_enemy = true
		if single_target:
			bullet.turn_rate = single_target_turn_rate
		nova_bullets_spawned += 1

	nova_bullets_remaining -= count

func _spawn_blast(radius: float) -> void:
	var blast := Polygon2D.new()
	var points := PackedVector2Array()
	var segments := 32
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)))
	blast.polygon = points
	blast.color = Color(1, 0.9, 0.3, 0.6)
	blast.scale = Vector2.ZERO
	blast.global_position = entity.global_position
	entity.get_parent().add_child(blast)

	var tween := blast.create_tween()
	tween.tween_property(blast, "scale", Vector2(radius, radius), 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(blast, "modulate:a", 0.0, 0.25)
	tween.tween_callback(blast.queue_free)
