class_name SuburbLayer
extends Node2D

const TILE_WIDTH := 2560.0
const GROUND_COLOR := Color(0.4, 0.58, 0.4, 1)
const WALL_COLORS := [Color(0.84, 0.75, 0.6, 1), Color(0.72, 0.8, 0.76, 1), Color(0.82, 0.68, 0.56, 1)]
const ROOF_COLORS := [Color(0.68, 0.32, 0.28, 1), Color(0.5, 0.42, 0.52, 1), Color(0.32, 0.4, 0.48, 1)]
const TREE_COLOR := Color(0.32, 0.54, 0.32, 1)
const TRUNK_COLOR := Color(0.44, 0.3, 0.2, 1)

@export var rng_seed: int = 2
@export var ground_y: float = 1300.0
@export var house_count: int = 5
@export var tree_count: int = 6

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	var ground := Polygon2D.new()
	ground.color = GROUND_COLOR
	ground.polygon = PackedVector2Array([
		Vector2(0, ground_y), Vector2(TILE_WIDTH, ground_y),
		Vector2(TILE_WIDTH, ground_y + 200.0), Vector2(0, ground_y + 200.0),
	])
	add_child(ground)

	for i in house_count:
		var x := (TILE_WIDTH / house_count) * i + rng.randf_range(20.0, 80.0)
		add_child(_build_house(rng, x))

	for i in tree_count:
		add_child(_build_tree(rng, rng.randf_range(0.0, TILE_WIDTH)))

func _build_house(rng: RandomNumberGenerator, x: float) -> Node2D:
	var root := Node2D.new()
	root.position = Vector2(x, ground_y)
	var width := rng.randf_range(90.0, 150.0)
	var height := rng.randf_range(80.0, 130.0)

	var body := Polygon2D.new()
	body.color = WALL_COLORS[rng.randi_range(0, WALL_COLORS.size() - 1)]
	body.polygon = PackedVector2Array([
		Vector2(-width / 2.0, 0), Vector2(width / 2.0, 0),
		Vector2(width / 2.0, -height), Vector2(-width / 2.0, -height),
	])
	root.add_child(body)

	var roof := Polygon2D.new()
	roof.color = ROOF_COLORS[rng.randi_range(0, ROOF_COLORS.size() - 1)]
	roof.polygon = PackedVector2Array([
		Vector2(-width / 2.0 - 10.0, -height), Vector2(width / 2.0 + 10.0, -height), Vector2(0, -height - 60.0),
	])
	root.add_child(roof)

	if rng.randf() > 0.5:
		var chimney := Polygon2D.new()
		chimney.color = ROOF_COLORS[0]
		var cx := rng.randf_range(-width * 0.3, width * 0.1)
		chimney.polygon = PackedVector2Array([
			Vector2(cx, -height - 20.0), Vector2(cx + 18.0, -height - 20.0),
			Vector2(cx + 18.0, -height - 70.0), Vector2(cx, -height - 70.0),
		])
		root.add_child(chimney)

	return root

func _build_tree(rng: RandomNumberGenerator, x: float) -> Node2D:
	var root := Node2D.new()
	root.position = Vector2(x, ground_y)
	var trunk_height := rng.randf_range(30.0, 50.0)

	var trunk := Polygon2D.new()
	trunk.color = TRUNK_COLOR
	trunk.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(6, 0), Vector2(6, -trunk_height), Vector2(-6, -trunk_height),
	])
	root.add_child(trunk)

	var canopy_radius := rng.randf_range(28.0, 42.0)
	var canopy := Polygon2D.new()
	canopy.color = TREE_COLOR
	var points := PackedVector2Array()
	var segments := 14
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * canopy_radius + Vector2(0, -trunk_height - canopy_radius * 0.6))
	canopy.polygon = points
	root.add_child(canopy)

	return root
