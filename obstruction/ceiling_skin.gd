class_name CeilingSkin
extends Node2D

const BODY_COLOR := Color(0.16, 0.13, 0.25, 1)
const FACET_COLOR := Color(0.22, 0.18, 0.33, 1)
const EDGE_COLOR := Color(0.45, 0.38, 0.65, 1)
const TOP_OVERSHOOT := 300.0
const EDGE_WIDTH := 6.0

var width: float = 300.0
var depth: float = 300.0
var tip_x: float = 0.0
var body: DestructibleBodyComponent
var facet_pieces: Array[PackedVector2Array] = []

func configure(new_width: float, new_depth: float, vertex_count: int) -> void:
	width = new_width
	depth = new_depth
	var half := width * 0.5
	var tip_t := randf_range(-0.4, 0.4)
	tip_x = tip_t * half

	var ts: Array[float] = []
	for i in vertex_count + 1:
		ts.append(float(i) / float(vertex_count) * 2.0 - 1.0)
	ts.append(tip_t)
	ts.sort()

	var bottom := PackedVector2Array()
	for i in ts.size():
		var t := ts[i]
		var falloff: float = 1.0 - absf(t - tip_t) / (1.0 + absf(tip_t))
		var d: float = depth * lerpf(0.18, 1.0, falloff)
		if is_equal_approx(t, tip_t):
			d = depth
		elif i > 0 and i < ts.size() - 1:
			d *= randf_range(0.8, 1.0)
		bottom.append(Vector2(t * half, d))

	var outline := PackedVector2Array([Vector2(-half, -TOP_OVERSHOOT), Vector2(half, -TOP_OVERSHOOT)])
	for i in range(bottom.size() - 1, -1, -1):
		outline.append(bottom[i])

	body = DestructibleBodyComponent.find(get_parent())
	body.changed.connect(_refresh)
	body.anchor_direction = Vector2.UP
	body.debris_colors = PackedColorArray([BODY_COLOR, FACET_COLOR, EDGE_COLOR])
	body.set_polygon(outline)

func adopt(source: CeilingSkin, fragment_pieces: Array[PackedVector2Array]) -> void:
	width = source.width
	depth = source.depth
	tip_x = source.tip_x
	body = DestructibleBodyComponent.find(get_parent())
	body.changed.connect(_refresh)
	body.debris_colors = source.body.debris_colors
	body.set_pieces(fragment_pieces)

func _refresh() -> void:
	facet_pieces.clear()
	var zone := PackedVector2Array([
		Vector2(tip_x, -TOP_OVERSHOOT - 50.0), Vector2(width, -TOP_OVERSHOOT - 50.0),
		Vector2(width, depth + 100.0), Vector2(tip_x, depth + 100.0),
	])
	for piece in body.pieces:
		facet_pieces.append_array(DestructibleBodyComponent.solid_results(Geometry2D.intersect_polygons(piece, zone)))
	queue_redraw()

func _fill(polygon: PackedVector2Array, color: Color) -> void:
	for part in DestructibleBodyComponent.convex_parts(polygon):
		draw_colored_polygon(part, color)

func _draw() -> void:
	if body == null:
		return
	for part in body.parts:
		draw_colored_polygon(part, BODY_COLOR)
	for piece in facet_pieces:
		_fill(piece, FACET_COLOR)
	for piece in body.pieces:
		var closed := piece.duplicate()
		closed.append(piece[0])
		draw_polyline(closed, EDGE_COLOR, EDGE_WIDTH)
