class_name SwarmSpawner
extends Node2D

@export var unit_scene: PackedScene = preload("res://enemy/enemy_swarm.tscn")
@export var spawn_interval_start: float = 12.0
@export var spawn_interval_min: float = 8.0
@export var ramp_duration: float = 150.0
@export var spawn_x: float = 2650.0
@export var unit_spacing: float = 90.0
@export var center_y_min: float = 300.0
@export var center_y_max: float = 1140.0
@export var first_leg_range: Vector2 = Vector2(900.0, 1500.0)
@export var second_leg_range: Vector2 = Vector2(350.0, 800.0)
@export var min_final_x: float = 450.0
@export var speed_range: Vector2 = Vector2(220.0, 420.0)
@export var pause_range: Vector2 = Vector2(0.6, 2.0)

var interval_scale: float = 1.0
var spawning: bool = true
var elapsed: float = 0.0
var time_since_spawn: float = 0.0

func _physics_process(delta: float) -> void:
	if not spawning:
		return

	elapsed += delta
	time_since_spawn += delta

	var ramp_t: float = clamp(elapsed / ramp_duration, 0.0, 1.0)
	var current_interval: float = lerp(spawn_interval_start, spawn_interval_min, ramp_t) * interval_scale * Conductor.spawn_scale()

	if time_since_spawn >= current_interval and Conductor.gate(4):
		time_since_spawn = 0.0
		_spawn_swarm()

func _spawn_swarm() -> void:
	var offsets := _wedge_offsets() if randf() < 0.5 else _grid_offsets()
	var center_y := randf_range(center_y_min, center_y_max)
	var first_leg := randf_range(first_leg_range.x, first_leg_range.y)
	var second_leg: float = min(randf_range(second_leg_range.x, second_leg_range.y), spawn_x - min_final_x - first_leg)
	var distances := PackedFloat32Array([first_leg, second_leg])
	var speeds := PackedFloat32Array([randf_range(speed_range.x, speed_range.y), randf_range(speed_range.x, speed_range.y)])
	var pauses := PackedFloat32Array([randf_range(pause_range.x, pause_range.y), randf_range(pause_range.x, pause_range.y)])
	for offset in offsets:
		var unit := unit_scene.instantiate() as Node2D
		unit.position = Vector2(spawn_x + offset.x, center_y + offset.y)
		var move := unit.get_node("SwarmMoveComponent") as SwarmMoveComponent
		move.move_distances = distances
		move.leg_speeds = speeds
		move.pause_durations = pauses
		get_parent().add_child(unit)

func _wedge_offsets() -> Array[Vector2]:
	var offsets: Array[Vector2] = [Vector2.ZERO]
	for i in range(1, 5):
		offsets.append(Vector2(unit_spacing * 0.8 * i, -unit_spacing * 0.7 * i))
		offsets.append(Vector2(unit_spacing * 0.8 * i, unit_spacing * 0.7 * i))
	return offsets

func _grid_offsets() -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	for column in 3:
		for row in 4:
			var y := (float(row) - 1.5) * unit_spacing + (unit_spacing * 0.5 if column % 2 == 1 else 0.0)
			offsets.append(Vector2(float(column) * unit_spacing, y))
	return offsets

func stop_spawning() -> void:
	spawning = false

func resume_spawning() -> void:
	spawning = true
	time_since_spawn = 0.0
