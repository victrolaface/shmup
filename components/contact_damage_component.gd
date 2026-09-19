class_name ContactDamageComponent
extends Component

@export var damage: int = 1

var health: HealthComponent

func _ready() -> void:
	health = HealthComponent.find(entity)
	(entity as Area2D).area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if health.dead or not area.is_in_group("player"):
		return
	var target := HealthComponent.find(area)
	if target != null:
		target.take_damage(damage)
	health.take_damage(health.max_health)
