class_name PlayerMoveComponent
extends Component

@export var speed: float = 700.0
@export var min_position: Vector2 = Vector2(50, 50)
@export var max_position: Vector2 = Vector2(2510, 1390)

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var target := entity.position + direction * speed * delta
	entity.position = target.clamp(min_position, max_position)
