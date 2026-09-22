class_name OverlapDamageComponent
extends Component

@export var damage: int = 1

var hurt_area: Area2D

func _ready() -> void:
	hurt_area = entity.get_node_or_null("HurtBox") as Area2D
	if hurt_area == null:
		hurt_area = entity as Area2D

func _physics_process(_delta: float) -> void:
	for area in hurt_area.get_overlapping_areas():
		if area.is_in_group("player"):
			var health := HealthComponent.find(area)
			if health != null:
				health.take_damage(damage)
