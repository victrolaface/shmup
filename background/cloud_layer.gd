class_name CloudLayer
extends Node2D

const TILE_WIDTH := 2560.0
const CLOUD_COLOR := Color(1, 1, 1, 0.85)
const PUFF_OFFSETS := [Vector2(0, 0), Vector2(38, -10), Vector2(-40, -6), Vector2(70, 4), Vector2(-72, 6)]
const PUFF_RADII := [34.0, 26.0, 24.0, 20.0, 20.0]

@export var rng_seed: int = 1
@export var cloud_count: int = 6
@export var y_range := Vector2(60.0, 420.0)
@export var puff_scale_range := Vector2(0.7, 1.3)

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i in cloud_count:
		var cloud := _build_cloud(rng)
		cloud.position = Vector2(rng.randf_range(0.0, TILE_WIDTH), rng.randf_range(y_range.x, y_range.y))
		add_child(cloud)

func _build_cloud(rng: RandomNumberGenerator) -> Node2D:
	var root := Node2D.new()
	var puff_scale := rng.randf_range(puff_scale_range.x, puff_scale_range.y)
	for j in PUFF_OFFSETS.size():
		var puff := Polygon2D.new()
		puff.polygon = _circle_points(PUFF_RADII[j] * puff_scale)
		puff.position = PUFF_OFFSETS[j] * puff_scale
		puff.color = CLOUD_COLOR
		root.add_child(puff)
	return root

func _circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 16
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
