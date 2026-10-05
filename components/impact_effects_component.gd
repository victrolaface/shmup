class_name ImpactEffectsComponent
extends Component

## Cosmetic-only: on taking damage, has a random chance to spawn a small
## explosion near the hit, on top of the hit-flash. No effect
## on health/score.

const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")

@export var chance: float = 0.4
@export var explosion_radius_range: Vector2 = Vector2(14.0, 34.0)
@export var explosion_duration: float = 0.24
@export var offset_radius: float = 140.0
@export var sound_volume_db: float = -12.0

var health: HealthComponent

func _ready() -> void:
	health = HealthComponent.find(entity)
	health.damaged.connect(_on_damaged)

func _on_damaged(_amount: int) -> void:
	if health.dead or randf() >= chance:
		return
	if not is_instance_valid(entity):
		return
	var parent := entity.get_parent()
	if parent == null:
		return
	var spot := entity.global_position + Vector2.from_angle(randf() * TAU) * randf_range(0.0, offset_radius)

	var explosion := EXPLOSION_SCENE.instantiate() as Node2D
	explosion.set("min_radius", explosion_radius_range.x)
	explosion.set("max_radius", explosion_radius_range.y)
	explosion.set("duration", explosion_duration)
	explosion.set("sound_volume_db", sound_volume_db)
	explosion.global_position = spot
	parent.add_child(explosion)
