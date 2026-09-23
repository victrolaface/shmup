class_name AirshipLayer
extends Node2D

const TILE_WIDTH := 2560.0
const HULL_COLOR := Color(0.36, 0.4, 0.47, 0.62)
const FIN_COLOR := Color(0.3, 0.33, 0.4, 0.62)
const GONDOLA_COLOR := Color(0.24, 0.23, 0.26, 0.68)

@export var rng_seed: int = 11
@export var airship_count: int = 3
@export var y_range := Vector2(120.0, 550.0)
@export var length_range := Vector2(140.0, 260.0)

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i in airship_count:
		var ship := _build_airship(rng)
		ship.position = Vector2(rng.randf_range(0.0, TILE_WIDTH), rng.randf_range(y_range.x, y_range.y))
		add_child(ship)

func _build_airship(rng: RandomNumberGenerator) -> Node2D:
	var root := Node2D.new()
	var length := rng.randf_range(length_range.x, length_range.y)
	var height := length * 0.36
	var facing := 1.0 if rng.randf() < 0.5 else -1.0

	var hull := Polygon2D.new()
	hull.color = HULL_COLOR
	var points := PackedVector2Array()
	var segments := 20
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle) * length * 0.5, sin(angle) * height * 0.5))
	hull.polygon = points
	root.add_child(hull)

	var tail_x := -length * 0.5 * facing
	var fin_top := Polygon2D.new()
	fin_top.color = FIN_COLOR
	fin_top.polygon = PackedVector2Array([
		Vector2(tail_x, 0.0), Vector2(tail_x - 16.0 * facing, -height * 0.85), Vector2(tail_x + 14.0 * facing, -height * 0.1),
	])
	root.add_child(fin_top)

	var fin_bottom := Polygon2D.new()
	fin_bottom.color = FIN_COLOR
	fin_bottom.polygon = PackedVector2Array([
		Vector2(tail_x, 0.0), Vector2(tail_x - 16.0 * facing, height * 0.85), Vector2(tail_x + 14.0 * facing, height * 0.1),
	])
	root.add_child(fin_bottom)

	var gondola := Polygon2D.new()
	gondola.color = GONDOLA_COLOR
	var gondola_w := length * 0.24
	var gondola_h := height * 0.3
	gondola.polygon = PackedVector2Array([
		Vector2(-gondola_w * 0.5, height * 0.45), Vector2(gondola_w * 0.5, height * 0.45),
		Vector2(gondola_w * 0.5, height * 0.45 + gondola_h), Vector2(-gondola_w * 0.5, height * 0.45 + gondola_h),
	])
	root.add_child(gondola)

	return root
