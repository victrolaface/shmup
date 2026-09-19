class_name BezierPathComponent
extends Component

signal path_finished

@export var path_duration: float = 1.8
@export var exit_speed: float = 500.0

var p0: Vector2
var p1: Vector2
var p2: Vector2
var p3: Vector2
var t: float = 0.0
var start_delay: float = 0.0
var on_curve: bool = true
var exit_direction: Vector2 = Vector2.LEFT

func setup(start: Vector2, control_1: Vector2, control_2: Vector2, end: Vector2, delay: float = 0.0) -> void:
	p0 = start
	p1 = control_1
	p2 = control_2
	p3 = end
	start_delay = delay
	(get_parent() as Node2D).position = p0

func _physics_process(delta: float) -> void:
	if start_delay > 0.0:
		start_delay -= delta
		return

	if not on_curve:
		entity.position += exit_direction * exit_speed * delta
		return

	t += delta / path_duration
	if t >= 1.0:
		t = 1.0
		on_curve = false
		var tangent: Vector2 = p3 - p2
		if tangent.length() < 0.001:
			tangent = p3 - p0
		exit_direction = tangent.normalized()
		path_finished.emit()
	entity.position = p0.bezier_interpolate(p1, p2, p3, t)
