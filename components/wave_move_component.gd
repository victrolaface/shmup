class_name WaveMoveComponent
extends Component

@export var speed: float = 260.0
@export var amplitude: float = 0.0
@export var frequency: float = 1.0

var base_y: float
var time: float = 0.0

func _ready() -> void:
	base_y = entity.position.y

func _physics_process(delta: float) -> void:
	time += delta
	entity.position.x -= speed * delta
	if amplitude != 0.0:
		entity.position.y = base_y + sin(time * frequency) * amplitude
