class_name InvincibilityBlinkComponent
extends Component

var visual: Polygon2D
@export var blink_rate: float = 24.0

var health: HealthComponent

func _ready() -> void:
	visual = Component.of(entity, "Visual") as Polygon2D
	health = HealthComponent.find(entity)

func _physics_process(_delta: float) -> void:
	if health.invincible_time > 0.0:
		visual.modulate.a = 0.25 if sin(health.invincible_time * blink_rate) > 0.0 else 1.0
	elif visual.modulate.a != 1.0:
		visual.modulate.a = 1.0
