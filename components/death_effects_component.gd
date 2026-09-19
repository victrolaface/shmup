class_name DeathEffectsComponent
extends Component

const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")
const SMOKE_SCENE := preload("res://effects/smoke.tscn")

@export var score_value: int = 10
@export var spawn_explosion: bool = true
@export var spawn_smoke: bool = true

func _ready() -> void:
	HealthComponent.find(entity).died.connect(_on_died)

func _on_died() -> void:
	Game.add_score(score_value)
	var parent := entity.get_parent()
	if spawn_explosion:
		var explosion := EXPLOSION_SCENE.instantiate() as Node2D
		explosion.global_position = entity.global_position
		parent.add_child(explosion)
	if spawn_smoke:
		var smoke := SMOKE_SCENE.instantiate() as Node2D
		smoke.global_position = entity.global_position
		parent.add_child(smoke)
