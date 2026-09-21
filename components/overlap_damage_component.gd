class_name OverlapDamageComponent
extends Component

@export var damage: int = 1

func _physics_process(_delta: float) -> void:
	for area in (entity as Area2D).get_overlapping_areas():
		if area.is_in_group("player"):
			var health := HealthComponent.find(area)
			if health != null:
				health.take_damage(damage)
