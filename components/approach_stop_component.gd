class_name ApproachStopComponent
extends Component

signal arrived
signal leaving

@export var approach_speed: float = 240.0
@export var stop_x_min: float = 1200.0
@export var stop_x_max: float = 2000.0
@export var hover_amplitude: float = 0.0
@export var hover_frequency: float = 0.6
@export var stay_duration: float = 0.0

var stop_x: float
var base_y: float
var time: float = 0.0
var has_arrived: bool = false
var is_leaving: bool = false

func _ready() -> void:
	stop_x = randf_range(stop_x_min, stop_x_max)
	base_y = entity.position.y

func _physics_process(delta: float) -> void:
	if is_leaving:
		entity.position.x -= approach_speed * 2.0 * delta
		return

	if not has_arrived:
		entity.position.x -= approach_speed * delta
		if entity.position.x <= stop_x:
			entity.position.x = stop_x
			has_arrived = true
			arrived.emit()
		return

	time += delta
	if hover_amplitude != 0.0:
		entity.position.y = base_y + sin(time * hover_frequency) * hover_amplitude

	if stay_duration > 0.0 and time >= stay_duration:
		is_leaving = true
		leaving.emit()
