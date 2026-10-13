class_name SuperComponent
extends Component

signal progress_changed(progress: float)

@export var bullet_scene: PackedScene = preload("res://bullet/bullet_player.tscn")
@export var max_charge: int = 3
@export var base_radius: float = 300.0
@export var radius_step: float = 200.0
@export var damage_per_charge: int = 3
@export var waves_by_level: PackedInt32Array = PackedInt32Array([2, 3, 4])
@export var bullets_per_wave_by_level: PackedInt32Array = PackedInt32Array([24, 32, 40])
@export var wave_interval: float = 0.3
@export var bullet_speed: float = 1000.0
@export var bombardment_min_level: int = 3
## Kills charge the meter: the enemy's score value times this, times the combo
## multiplier, capped per kill so a boss fills at most `kill_charge_cap`.
@export var kill_charge_per_point: float = 0.004
@export var kill_charge_cap: float = 1.0
## Enemy bullets that whizz past within this distance of the player (without
## hitting) give a small trickle of charge, once per bullet.
@export var graze_radius: float = 70.0
@export var graze_charge: float = 0.01
## Screen shake when the blast goes off: base + per_level * charge level.
@export var blast_shake_base: float = 0.4
@export var blast_shake_per_level: float = 0.1

var progress: float = 0.0
var charge: int = 0
var nova_active: bool = false
var nova_elapsed: float = 0.0
var waves_spawned: int = 0
var current_wave_count: int = 0
var current_bullets_per_wave: int = 0
var nova_damage: int = 0
var bombardment: BombardmentComponent

func _ready() -> void:
	bombardment = Component.of(entity, "BombardmentComponent") as BombardmentComponent
	Game.kill_registered.connect(_on_kill_registered)

## Kills made by the super itself don't feed the next one.
func _on_kill_registered(base_score: int, multiplier: float) -> void:
	if nova_active or (bombardment != null and bombardment.active):
		return
	grant_charge(minf(float(base_score) * kill_charge_per_point * multiplier, kill_charge_cap))

func _graze() -> void:
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var bullet := node as Bullet
		if bullet == null or not is_instance_valid(bullet) or bullet.is_queued_for_deletion() or bullet.has_meta("grazed"):
			continue
		if entity.global_position.distance_to(bullet.global_position) <= graze_radius:
			bullet.set_meta("grazed", true)
			grant_charge(graze_charge)

func grant_charge(amount: float) -> void:
	progress = min(progress + amount, float(max_charge))
	charge = int(floor(progress))
	progress_changed.emit(progress)

func _physics_process(delta: float) -> void:
	_graze()
	if nova_active:
		nova_elapsed += delta
		while waves_spawned < current_wave_count and nova_elapsed >= float(waves_spawned) * wave_interval:
			_spawn_wave(waves_spawned)
			waves_spawned += 1
		if waves_spawned >= current_wave_count:
			nova_active = false

	if charge > 0 and Input.is_action_just_pressed("super"):
		_unleash()

func _unleash() -> void:
	var level := charge
	charge = 0
	progress = 0.0
	progress_changed.emit(progress)

	var tier := clampi(level, 1, waves_by_level.size()) - 1
	current_wave_count = waves_by_level[tier]
	current_bullets_per_wave = bullets_per_wave_by_level[tier]

	var radius := base_radius + float(level - 1) * radius_step
	var damage := damage_per_charge * level
	_spawn_blast(radius)
	_clear_nearby(radius, damage)
	ScreenShakeCamera.shake_view(entity, blast_shake_base + blast_shake_per_level * float(level))

	nova_damage = damage
	nova_elapsed = 0.0
	waves_spawned = 0
	nova_active = true

	if bombardment != null and level >= bombardment_min_level:
		bombardment.start(level)

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

func _spawn_wave(wave_index: int) -> void:
	var angle_offset := (TAU / float(current_bullets_per_wave)) * float(wave_index) / float(current_wave_count)

	for i in current_bullets_per_wave:
		var angle := (float(i) / float(current_bullets_per_wave)) * TAU + angle_offset
		var bullet := bullet_scene.instantiate() as Bullet
		entity.get_parent().add_child(bullet)
		bullet.direction = Vector2.RIGHT.rotated(angle)
		bullet.speed = bullet_speed
		bullet.global_position = entity.global_position
		bullet.damage = nova_damage

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
