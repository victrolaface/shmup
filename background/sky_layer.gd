class_name SkyLayer
extends Node2D

const TILE_WIDTH := 2560.0
const TILE_HEIGHT := 1440.0
const SKY_TOP := Color(0.26, 0.4, 0.56, 1)
const SKY_HORIZON := Color(0.58, 0.7, 0.8, 1)
const SUN_COLOR := Color(0.98, 0.88, 0.65, 1)
const WISP_COLOR := Color(1, 1, 1, 0.25)

@export var rng_seed: int = 3
@export var wisp_count: int = 4
@export var sun_position := Vector2(2150.0, 180.0)
@export var sun_radius: float = 90.0
@export var draw_sun: bool = true

func _ready() -> void:
	_build_sky_gradient()
	if draw_sun:
		_build_sun()
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i in wisp_count:
		add_child(_build_wisp(rng, rng.randf_range(0.0, TILE_WIDTH)))

func _build_sky_gradient() -> void:
	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(TILE_WIDTH, 0), Vector2(TILE_WIDTH, TILE_HEIGHT), Vector2(0, TILE_HEIGHT),
	])
	sky.vertex_colors = PackedColorArray([SKY_TOP, SKY_TOP, SKY_HORIZON, SKY_HORIZON])
	add_child(sky)

func _build_sun() -> void:
	var sun := Polygon2D.new()
	sun.color = SUN_COLOR
	sun.position = sun_position
	sun.polygon = _circle_points(sun_radius, 24)
	add_child(sun)

func _build_wisp(rng: RandomNumberGenerator, x: float) -> Node2D:
	var root := Node2D.new()
	root.position = Vector2(x, rng.randf_range(500.0, 950.0))
	var offsets := [Vector2(-90, 0), Vector2(0, -6), Vector2(90, 0), Vector2(180, 4)]
	for offset in offsets:
		var puff := Polygon2D.new()
		puff.color = WISP_COLOR
		puff.polygon = _ellipse_points(70.0, 22.0)
		puff.position = offset
		root.add_child(puff)
	return root

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _ellipse_points(radius_x: float, radius_y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 12
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
