class_name GroundSpawner
extends Node2D

@export var figure8_scene: PackedScene = preload("res://enemy/enemy_ground_figure8.tscn")
@export var sniper_scene: PackedScene = preload("res://enemy/enemy_ground_sniper.tscn")
@export var spawn_interval_start: float = 4.0
@export var spawn_interval_min: float = 2.0
@export var ramp_duration: float = 90.0
var interval_scale: float = 1.0
@export var spawn_x: float = 2650.0
@export var ground_y: float = 1280.0

var spawning: bool = true
var elapsed: float = 0.0
var time_since_spawn: float = 0.0

func _physics_process(delta: float) -> void:
	if not spawning:
		return

	elapsed += delta
	time_since_spawn += delta

	var ramp_t: float = clamp(elapsed / ramp_duration, 0.0, 1.0)
	var current_interval: float = lerp(spawn_interval_start, spawn_interval_min, ramp_t) * interval_scale

	if time_since_spawn >= current_interval:
		time_since_spawn = 0.0
		_spawn_enemy()

func _spawn_enemy() -> void:
	var scene: PackedScene = figure8_scene if randf() < 0.5 else sniper_scene
	var enemy := scene.instantiate() as Node2D
	enemy.position = Vector2(spawn_x, ground_y)
	get_parent().add_child(enemy)

func stop_spawning() -> void:
	spawning = false

func resume_spawning() -> void:
	spawning = true
	time_since_spawn = 0.0
