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
@export var burst_count: int = 0
@export var burst_radius_range: Vector2 = Vector2(25.0, 170.0)
@export var burst_spread: Vector2 = Vector2(260.0, 320.0)
@export var burst_duration: float = 1.4

func _ready() -> void:
	HealthComponent.find(entity).died.connect(_on_died)

func _on_died() -> void:
	Game.register_kill(score_value)
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
	if burst_count > 0:
		_explosion_burst(parent, entity.global_position)

func _explosion_burst(parent: Node, origin: Vector2) -> void:
	var tree := get_tree()
	for i in burst_count:
		var delay := burst_duration * pow(randf(), 0.85)
		var size := lerpf(burst_radius_range.x, burst_radius_range.y, pow(randf(), 1.6))
		var offset := Vector2(randf_range(-1.0, 1.0) * burst_spread.x, randf_range(-1.0, 1.0) * burst_spread.y)
		var timer := tree.create_timer(delay)
		timer.timeout.connect(func() -> void:
			if not is_instance_valid(parent):
				return
			var explosion := EXPLOSION_SCENE.instantiate() as Node2D
			explosion.set("min_radius", size * 0.6)
			explosion.set("max_radius", size)
			explosion.set("duration", lerpf(0.3, 0.6, size / burst_radius_range.y))
			var base := entity.global_position if is_instance_valid(entity) else origin
			explosion.global_position = base + offset
			parent.add_child(explosion))
