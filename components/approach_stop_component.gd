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
@export var rise_from_below: float = 0.0
@export var entrance_tween_time: float = 0.0
@export var entrance_offset_y: float = 0.0
@export var entrance_float: float = 40.0

var entering: bool = false

var stop_x: float
var base_y: float
var time: float = 0.0
var has_arrived: bool = false
var is_leaving: bool = false

func _ready() -> void:
	stop_x = randf_range(stop_x_min, stop_x_max)
	base_y = entity.position.y
	if rise_from_below > 0.0:
		entity.position.y += rise_from_below
	if entrance_tween_time > 0.0:
		entity.position.y = base_y + entrance_offset_y
		_start_entrance_tween()

func _physics_process(delta: float) -> void:
	if entering:
		return
	if is_leaving:
		entity.position.x -= approach_speed * 2.0 * delta
		return

	if not has_arrived:
		var remaining_x := maxf(entity.position.x - stop_x, 0.001)
		if rise_from_below > 0.0:
			var rise_speed := approach_speed * (entity.position.y - base_y) / remaining_x
			entity.position.y = maxf(entity.position.y - rise_speed * delta, base_y)
		entity.position.x -= approach_speed * delta
		if entity.position.x <= stop_x:
			entity.position.x = stop_x
			entity.position.y = base_y
			has_arrived = true
			arrived.emit()
		return

	time += delta
	if hover_amplitude != 0.0:
		entity.position.y = base_y + sin(time * hover_frequency) * hover_amplitude

	if stay_duration > 0.0 and time >= stay_duration:
		is_leaving = true
		leaving.emit()

func _start_entrance_tween() -> void:
	entering = true
	var start := entity.position
	var target := Vector2(stop_x, base_y)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var eased := 1.0 - pow(1.0 - t, 3.0)
		entity.position = start.lerp(target, eased) + Vector2(0.0, sin(t * TAU * 1.5) * entrance_float * (1.0 - t)),
		0.0, 1.0, entrance_tween_time)
	tween.tween_callback(func() -> void:
		entity.position = target
		entering = false
		has_arrived = true
		arrived.emit())
