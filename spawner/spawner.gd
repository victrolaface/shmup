class_name Spawner
extends Node2D

@export var enemy_scenes: Array[PackedScene] = [
	preload("res://enemy/enemy.tscn"),
	preload("res://enemy/enemy_sine_light.tscn"),
	preload("res://enemy/enemy_sine_heavy.tscn"),
	preload("res://enemy/enemy_chaser.tscn"),
]
@export var spawn_interval_start: float = 1.8
@export var spawn_interval_min: float = 0.8
@export var ramp_duration: float = 150.0
var interval_scale: float = 1.0
@export var spawn_x: float = 2650.0
@export var spawn_y_min: float = 80.0
@export var spawn_y_max: float = 1360.0
@export var medium_scene: PackedScene = preload("res://enemy/enemy_medium.tscn")
@export var medium_chance: float = 0.08
@export var medium_random_scene: PackedScene = preload("res://enemy/enemy_medium_random.tscn")
@export var medium_random_chance: float = 0.04

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

	if time_since_spawn >= current_interval and Conductor.gate(1):
		time_since_spawn = 0.0
		_spawn_enemy()

func _spawn_enemy() -> void:
	var roll := randf()
	var scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	var is_medium := true
	if roll < medium_random_chance:
		scene = medium_random_scene
	elif roll < medium_random_chance + medium_chance:
		scene = medium_scene
	else:
		is_medium = false
	var enemy := scene.instantiate() as Node2D
	var y := randf_range(spawn_y_min, spawn_y_max)
	if is_medium:
		y = clamp(y, 250.0, 1190.0)
	enemy.position = Vector2(spawn_x, y)
	get_parent().add_child(enemy)

func stop_spawning() -> void:
	spawning = false

func resume_spawning() -> void:
	spawning = true
	time_since_spawn = 0.0
