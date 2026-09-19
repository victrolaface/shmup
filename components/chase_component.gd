class_name ChaseComponent
extends Component

@export var speed: float = 320.0
@export var turn_rate: float = 2.2

var direction: Vector2 = Vector2.LEFT

func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var desired: Vector2 = (player.global_position - entity.global_position).normalized()
		direction = direction.slerp(desired, turn_rate * delta).normalized()
	entity.position += direction * speed * delta
