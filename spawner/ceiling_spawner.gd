class_name CeilingSpawner
extends Node2D

@export var ceiling_scene: PackedScene = preload("res://obstruction/obstruction_ceiling.tscn")
@export var sniper_scene: PackedScene = preload("res://enemy/enemy_rooftop_sniper.tscn")
@export var scroll_speed: float = 260.0
@export var spawn_edge_x: float = 2600.0
@export var cluster_size_range: Vector2i = Vector2i(1, 3)
@export var width_range: Vector2 = Vector2(220.0, 900.0)
@export var depth_range: Vector2 = Vector2(80.0, 260.0)
@export var vertex_range: Vector2i = Vector2i(14, 20)
@export var neighbor_offset_range: Vector2 = Vector2(-40.0, 70.0)
@export var gap_range: Vector2 = Vector2(2800.0, 6500.0)
@export var sniper_chance: float = 0.45
@export var sniper_radius: float = 16.0

var interval_scale: float = 1.0
var spawning: bool = true
var next_spawn_in: float = 8.0

func _physics_process(delta: float) -> void:
	if not spawning:
		return
	next_spawn_in -= delta
	if next_spawn_in <= 0.0 and Conductor.gate(4):
		_spawn_cluster()

func _spawn_cluster() -> void:
	var left_edge := spawn_edge_x
	var count := randi_range(cluster_size_range.x, cluster_size_range.y)
	for i in count:
		var width := randf_range(width_range.x, width_range.y)
		var depth := randf_range(depth_range.x, depth_range.y)
		_spawn_polygon(left_edge + width * 0.5, width, depth)
		left_edge += width + randf_range(neighbor_offset_range.x, neighbor_offset_range.y)
	var gap := randf_range(gap_range.x, gap_range.y) * interval_scale * Conductor.obstruction_scale()
	next_spawn_in = (left_edge - spawn_edge_x + gap) / scroll_speed

func _spawn_polygon(center_x: float, width: float, depth: float) -> void:
	var ceiling := ceiling_scene.instantiate() as Node2D
	ceiling.position = Vector2(center_x, 0.0)
	(ceiling.get_node("WaveMoveComponent") as WaveMoveComponent).speed = scroll_speed
	var skin := ceiling.get_node("Skin") as CeilingSkin
	skin.configure(width, depth, randi_range(vertex_range.x, vertex_range.y))
	get_parent().add_child(ceiling)

	if randf() >= sniper_chance:
		return
	var sniper_x := center_x + randf_range(-0.5, 0.5) * width * 0.5
	var sniper := sniper_scene.instantiate() as Node2D
	sniper.position = Vector2(sniper_x, skin.body.surface_y(sniper_x, false) + sniper_radius)
	sniper.rotation = PI
	(sniper.get_node("WaveMoveComponent") as WaveMoveComponent).speed = scroll_speed
	(sniper.get_node("PerchComponent") as PerchComponent).attach(ceiling, true)
	get_parent().add_child(sniper)

func stop_spawning() -> void:
	spawning = false

func resume_spawning() -> void:
	spawning = true
	next_spawn_in = 0.0
