class_name ObstructionSpawner
extends Node2D

@export var building_scene: PackedScene = preload("res://obstruction/obstruction_building.tscn")
@export var sniper_scene: PackedScene = preload("res://enemy/enemy_rooftop_sniper.tscn")
@export var scroll_speed: float = 260.0
@export var spawn_edge_x: float = 2600.0
@export var ground_y: float = 1440.0
@export var wide_width_range: Vector2 = Vector2(420.0, 900.0)
@export var wide_height_range: Vector2 = Vector2(150.0, 360.0)
@export var tall_chance: float = 0.2
@export var tall_width_range: Vector2 = Vector2(220.0, 360.0)
@export var tall_height_range: Vector2 = Vector2(400.0, 620.0)
@export var pitched_roof_chance: float = 0.15
@export var pitched_roof_range: Vector2 = Vector2(70.0, 190.0)
@export var gap_range: Vector2 = Vector2(1500.0, 3600.0)
@export var sniper_chance: float = 0.5
@export var sniper_radius: float = 16.0

var interval_scale: float = 1.0
var spawning: bool = true
var next_spawn_in: float = 0.0

func _physics_process(delta: float) -> void:
	if not spawning:
		return
	next_spawn_in -= delta
	if next_spawn_in <= 0.0 and Conductor.gate(4):
		_spawn_building()

func _spawn_building() -> void:
	var is_tall := randf() < tall_chance
	var width := randf_range(tall_width_range.x, tall_width_range.y) if is_tall else randf_range(wide_width_range.x, wide_width_range.y)
	var height := randf_range(tall_height_range.x, tall_height_range.y) if is_tall else randf_range(wide_height_range.x, wide_height_range.y)
	var roof_height := 0.0
	if randf() < pitched_roof_chance:
		roof_height = clampf(width * 0.3, pitched_roof_range.x, pitched_roof_range.y)
	var gap := randf_range(gap_range.x, gap_range.y) * interval_scale * Conductor.obstruction_scale()
	next_spawn_in = (width + gap) / scroll_speed

	var center := Vector2(spawn_edge_x + width * 0.5, ground_y - height * 0.5)
	var building := building_scene.instantiate() as Node2D
	building.position = center
	(building.get_node("WaveMoveComponent") as WaveMoveComponent).speed = scroll_speed
	var skin := building.get_node("Skin") as BuildingSkin
	skin.configure(width, height, roof_height)
	get_parent().add_child(building)

	if randf() < sniper_chance:
		var count := 1
		if width > 700.0:
			count = 3 if randf() < 0.4 else 2
		elif width > 330.0 and randf() < 0.5:
			count = 2
		var spread := width * (0.5 if roof_height > 0.0 else 0.8)
		for i in count:
			var slot := (float(i) + 0.5) / float(count) - 0.5
			var sniper_x: float = center.x + clampf((slot + randf_range(-0.1, 0.1)) * spread, -width * 0.45, width * 0.45)
			var surface_y := skin.body.surface_y(sniper_x, true)
			var sniper := sniper_scene.instantiate() as Node2D
			sniper.position = Vector2(sniper_x, surface_y - sniper_radius)
			(sniper.get_node("WaveMoveComponent") as WaveMoveComponent).speed = scroll_speed
			(sniper.get_node("PerchComponent") as PerchComponent).attach(building, false)
			get_parent().add_child(sniper)

func stop_spawning() -> void:
	spawning = false

func resume_spawning() -> void:
	spawning = true
	next_spawn_in = 0.0
