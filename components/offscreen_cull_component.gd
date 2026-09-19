class_name OffscreenCullComponent
extends Component

@export var margin: float = 100.0

func _physics_process(_delta: float) -> void:
	if entity.position.x < -margin:
		entity.queue_free()
