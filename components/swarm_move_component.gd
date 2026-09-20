class_name SwarmMoveComponent
extends Component

@export var move_distances: PackedFloat32Array = PackedFloat32Array([1300.0, 600.0])
@export var leg_speeds: PackedFloat32Array = PackedFloat32Array([300.0, 300.0])
@export var pause_durations: PackedFloat32Array = PackedFloat32Array([1.2, 1.2])
@export var exit_speed: float = 1100.0
@export var exit_ramp_time: float = 0.8
@export var wobble_amplitude: float = 14.0
@export var wobble_frequency: float = 3.0

var leg: int = 0
var leg_remaining: float = 0.0
var pause_left: float = 0.0
var exit_time: float = 0.0
var exiting: bool = false
var pausing: bool = false
var base_y: float
var time: float = 0.0
var wobble_phase: float = 0.0

func _ready() -> void:
	base_y = entity.position.y
	wobble_phase = randf() * TAU
	leg_remaining = move_distances[0]

func _physics_process(delta: float) -> void:
	time += delta
	entity.position.y = base_y + wobble_amplitude * sin(time * wobble_frequency + wobble_phase)

	if exiting:
		exit_time += delta
		var speed: float = lerp(200.0, exit_speed, clamp(exit_time / exit_ramp_time, 0.0, 1.0))
		entity.position.x -= speed * delta
		return

	if pausing:
		pause_left -= delta
		if pause_left <= 0.0:
			pausing = false
			leg += 1
			if leg < move_distances.size():
				leg_remaining = move_distances[leg]
			else:
				exiting = true
		return

	var step: float = min(leg_speeds[min(leg, leg_speeds.size() - 1)] * delta, leg_remaining)
	entity.position.x -= step
	leg_remaining -= step
	if leg_remaining <= 0.0:
		pausing = true
		pause_left = pause_durations[min(leg, pause_durations.size() - 1)]
