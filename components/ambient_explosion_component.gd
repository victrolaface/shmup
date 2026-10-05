class_name AmbientExplosionComponent
extends Component

## Cosmetic-only: occasionally puffs a small explosion somewhere on the
## entity while it's alive, purely for visual flavor (no damage, no score).

const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")

@export var min_interval: float = 1.6
@export var max_interval: float = 4.5
@export var chance: float = 0.4
@export var min_radius: float = 6.0
@export var max_radius: float = 16.0
@export var offset_radius: float = 18.0
@export var sound_volume_db: float = -16.0

var health: HealthComponent
var time_until_check: float = 0.0

func _ready() -> void:
	health = HealthComponent.find(entity)
	_reset_timer()

func _reset_timer() -> void:
	time_until_check = randf_range(min_interval, max_interval)

func _process(delta: float) -> void:
	if health != null and health.dead:
		return
	time_until_check -= delta
	if time_until_check <= 0.0:
		_reset_timer()
		if randf() < chance:
			_spawn_puff()

func _spawn_puff() -> void:
	if not is_instance_valid(entity):
		return
	var parent := entity.get_parent()
	if parent == null:
		return
	var explosion := EXPLOSION_SCENE.instantiate() as Node2D
	explosion.set("min_radius", min_radius)
	explosion.set("max_radius", max_radius)
	explosion.set("duration", 0.22)
	explosion.set("sound_volume_db", sound_volume_db)
	explosion.global_position = entity.global_position + Vector2.from_angle(randf() * TAU) * randf_range(0.0, offset_radius)
	parent.add_child(explosion)
