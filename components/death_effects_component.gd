class_name DeathEffectsComponent
extends Component

const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")
const SMOKE_SCENE := preload("res://effects/smoke.tscn")

@export var score_value: int = 10
@export var spawn_explosion: bool = true
@export var spawn_smoke: bool = true
@export var explosion_radius_range: Vector2 = Vector2(40.0, 90.0)
@export var explosion_duration: float = 0.35
@export var smoke_radius: float = 30.0

func _ready() -> void:
	HealthComponent.find(entity).died.connect(_on_died)

func _on_died() -> void:
	Game.add_score(score_value)
	var parent := entity.get_parent()
	if spawn_explosion:
		var explosion := EXPLOSION_SCENE.instantiate() as Node2D
		explosion.set("min_radius", explosion_radius_range.x)
		explosion.set("max_radius", explosion_radius_range.y)
		explosion.set("duration", explosion_duration)
		explosion.global_position = entity.global_position
		parent.add_child(explosion)
	if spawn_smoke:
		var smoke := SMOKE_SCENE.instantiate() as Node2D
		smoke.set("radius", smoke_radius)
		smoke.global_position = entity.global_position
		parent.add_child(smoke)
