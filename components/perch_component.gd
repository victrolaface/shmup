class_name PerchComponent
extends Component

const GRIP_GAP := 8.0

@export var body_radius: float = 16.0
@export var gravity: float = 2200.0
@export var jump_speed: float = 650.0
@export var drift_speed: float = 120.0
@export var fuse_range: Vector2 = Vector2(0.45, 0.7)
@export var spin_range: Vector2 = Vector2(8.0, 30.0)
@export var blast_radius_range: Vector2 = Vector2(14.0, 65.0)
@export var blast_duration_range: Vector2 = Vector2(0.15, 0.55)
@export var blast_speed_range: Vector2 = Vector2(250.0, 1100.0)
@export var shrapnel_colors: PackedColorArray = PackedColorArray([Color(0.95, 0.6, 0.2, 1), Color(1.0, 0.85, 0.4, 1), Color(0.55, 0.32, 0.14, 1)])

var body: DestructibleBodyComponent
var hanging: bool = false
var health: HealthComponent
var falling: bool = false
var fall_velocity: Vector2 = Vector2.ZERO
var spin: float = 0.0
var fuse: float = 0.0
var fall_time: float = 0.0

func _ready() -> void:
	health = HealthComponent.find(entity)

func attach(host: Node, is_hanging: bool) -> void:
	body = DestructibleBodyComponent.find(host)
	hanging = is_hanging

func _physics_process(delta: float) -> void:
	if health.dead:
		return
	if falling:
		_fall(delta)
	elif body != null and not _has_ground():
		_lose_ground()

func _has_ground() -> bool:
	if not is_instance_valid(body) or body.pieces.is_empty():
		return false
	var surface := body.surface_y(entity.global_position.x, not hanging)
	if is_inf(surface):
		return false
	if hanging:
		return entity.global_position.y - body_radius - surface <= GRIP_GAP
	return surface - (entity.global_position.y + body_radius) <= GRIP_GAP

func _lose_ground() -> void:
	falling = true
	fuse = randf_range(fuse_range.x, fuse_range.y)
	fall_velocity = Vector2(randf_range(-drift_speed, drift_speed), 60.0 if hanging else -jump_speed)
	spin = randf_range(spin_range.x, spin_range.y) * (1.0 if randf() < 0.5 else -1.0)
	var shooter := Component.of(entity, "ShooterComponent") as ShooterComponent
	if shooter != null:
		shooter.stop()

func _fall(delta: float) -> void:
	fall_time += delta
	fall_velocity.y += gravity * delta
	entity.position += fall_velocity * delta
	entity.rotation += spin * delta
	entity.modulate = Color(1.0, 0.45, 0.35, 1.0) if int(fall_time * 24.0) % 2 == 0 else Color.WHITE
	fuse -= delta
	if fuse <= 0.0:
		_detonate()

func _detonate() -> void:
	var radius := randf_range(blast_radius_range.x, blast_radius_range.y)
	var effects := Component.of(entity, "DeathEffectsComponent") as DeathEffectsComponent
	if effects != null:
		effects.explosion_radius_range = Vector2(radius * 0.9, radius * 1.1)
		effects.explosion_duration = randf_range(blast_duration_range.x, blast_duration_range.y)
		effects.smoke_radius = radius * 0.6
	var blast_speed := randf_range(blast_speed_range.x, blast_speed_range.y)
	Debris.burst(entity.get_parent(), entity.global_position, Vector2.UP, shrapnel_colors, clampi(int(radius / 6.0), 4, 12), Vector2(blast_speed * 0.35, blast_speed), Vector2.ZERO, 180.0)
	health.take_damage(health.max_health)
