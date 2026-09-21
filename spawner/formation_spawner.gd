class_name FormationSpawner
extends Node2D

@export var unit_scene: PackedScene = preload("res://enemy/enemy_formation_unit.tscn")
@export var squad_interval_start: float = 6.0
@export var squad_interval_min: float = 3.5
@export var ramp_duration: float = 150.0
var interval_scale: float = 1.0
@export var squad_size: int = 5
@export var stagger_delay: float = 0.12
@export var spawn_x: float = 2650.0

var spawning: bool = true
var elapsed: float = 0.0
var time_since_squad: float = 0.0

func _physics_process(delta: float) -> void:
	if not spawning:
		return

	elapsed += delta
	time_since_squad += delta

	var ramp_t: float = clamp(elapsed / ramp_duration, 0.0, 1.0)
	var current_interval: float = lerp(squad_interval_start, squad_interval_min, ramp_t) * interval_scale * Conductor.spawn_scale()

	if time_since_squad >= current_interval and Conductor.gate(4):
		time_since_squad = 0.0
		_spawn_squad()

func _spawn_squad() -> void:
	var entry_y := randf_range(150.0, 500.0)
	var swoop_down := randf() < 0.5
	var mid_y: float = clamp(entry_y + (600.0 if swoop_down else -600.0), 100.0, 1340.0)
	var exit_y := randf_range(150.0, 1290.0)

	var p0 := Vector2(spawn_x, entry_y)
	var p1 := Vector2(spawn_x * 0.6, mid_y)
	var p2 := Vector2(spawn_x * 0.25, mid_y)
	var p3 := Vector2(-150.0, exit_y)

	for i in squad_size:
		var unit := unit_scene.instantiate() as Node2D
		(unit.get_node("BezierPathComponent") as BezierPathComponent).setup(p0, p1, p2, p3, float(i) * stagger_delay)
		get_parent().add_child(unit)

func stop_spawning() -> void:
	spawning = false

func resume_spawning() -> void:
	spawning = true
	time_since_squad = 0.0
