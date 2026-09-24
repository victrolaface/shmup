class_name CeilingSkin
extends Node2D

const BODY_COLOR := Color(0.64, 0.66, 0.7, 1)
const SHADE_COLOR := Color(0.5, 0.52, 0.58, 1)
const EDGE_COLOR := Color(0.35, 0.36, 0.42, 1)
const RIB_COLOR := Color(0.3, 0.32, 0.38, 1)
const GONDOLA_COLOR := Color(0.3, 0.28, 0.3, 1)
const GONDOLA_EDGE_COLOR := Color(0.2, 0.19, 0.2, 1)
const TOP_OVERSHOOT := 300.0
const EDGE_WIDTH := 6.0
const RIB_WIDTH := 4.0
const RIB_COUNT := 7

var width: float = 300.0
var depth: float = 300.0
var body: DestructibleBodyComponent
var rib_lines: Array[PackedVector2Array] = []
var visible_ribs: Array[PackedVector2Array] = []
var has_gondola: bool = false
var gondola_rect: Rect2
var gondola_visible: bool = false
var shade_pieces: Array[PackedVector2Array] = []

func configure(new_width: float, new_depth: float, segment_count: int) -> void:
	width = new_width
	depth = minf(new_depth, new_width * 0.2)
	var half := width * 0.5
	var segments := maxi(segment_count, 10)

	var bottom := PackedVector2Array()
	for i in segments + 1:
		var t := -1.0 + 2.0 * float(i) / float(segments)
		var d: float = depth * sqrt(maxf(0.0, 1.0 - t * t))
		bottom.append(Vector2(t * half, d))

	var outline := PackedVector2Array([Vector2(-half, -TOP_OVERSHOOT), Vector2(half, -TOP_OVERSHOOT)])
	for i in range(bottom.size() - 1, -1, -1):
		outline.append(bottom[i])

	rib_lines.clear()
	for i in RIB_COUNT:
		var t := -0.85 + 1.7 * float(i) / float(RIB_COUNT - 1)
		var x := t * half
		var d: float = depth * sqrt(maxf(0.0, 1.0 - t * t))
		rib_lines.append(PackedVector2Array([Vector2(x, 0.0), Vector2(x, d)]))

	has_gondola = true
	if has_gondola:
		var gondola_t := randf_range(-0.25, 0.25)
		var gondola_x := gondola_t * half
		var gondola_d: float = depth * sqrt(maxf(0.0, 1.0 - gondola_t * gondola_t))
		var gondola_w := clampf(width * 0.16, 36.0, 100.0)
		var gondola_h := clampf(depth * 0.24, 26.0, 70.0)
		gondola_rect = Rect2(gondola_x - gondola_w * 0.5, gondola_d - 4.0, gondola_w, gondola_h)

	body = DestructibleBodyComponent.find(get_parent())
	body.changed.connect(_refresh)
	body.anchor_direction = Vector2.UP
	body.debris_colors = PackedColorArray([BODY_COLOR, SHADE_COLOR, EDGE_COLOR])
	body.set_polygon(outline)

func adopt(source: CeilingSkin, fragment_pieces: Array[PackedVector2Array]) -> void:
	width = source.width
	depth = source.depth
	rib_lines = source.rib_lines
	has_gondola = source.has_gondola
	gondola_rect = source.gondola_rect
	body = DestructibleBodyComponent.find(get_parent())
	body.changed.connect(_refresh)
	body.debris_colors = source.body.debris_colors
	body.set_pieces(fragment_pieces)

func _refresh() -> void:
	shade_pieces.clear()
	var half := width * 0.5
	var zone := PackedVector2Array([
		Vector2(-half, depth * 0.4), Vector2(half, depth * 0.4),
		Vector2(half, depth + 50.0), Vector2(-half, depth + 50.0),
	])
	for piece in body.pieces:
		shade_pieces.append_array(DestructibleBodyComponent.solid_results(Geometry2D.intersect_polygons(piece, zone)))

	visible_ribs.clear()
	for rib in rib_lines:
		if body.contains_local(rib[1]):
			visible_ribs.append(rib)

	gondola_visible = has_gondola and body.contains_local(gondola_rect.position + Vector2(gondola_rect.size.x * 0.5, 0.0))
	queue_redraw()

func _fill(polygon: PackedVector2Array, color: Color) -> void:
	for part in DestructibleBodyComponent.convex_parts(polygon):
		draw_colored_polygon(part, color)

func _draw() -> void:
	if body == null:
		return
	for part in body.parts:
		draw_colored_polygon(part, BODY_COLOR)
	for piece in shade_pieces:
		_fill(piece, SHADE_COLOR)

	for rib in visible_ribs:
		draw_line(rib[0], rib[1], RIB_COLOR, RIB_WIDTH)

	if gondola_visible:
		draw_rect(gondola_rect, GONDOLA_COLOR)
		var closed := PackedVector2Array([
			gondola_rect.position,
			Vector2(gondola_rect.position.x + gondola_rect.size.x, gondola_rect.position.y),
			gondola_rect.position + gondola_rect.size,
			Vector2(gondola_rect.position.x, gondola_rect.position.y + gondola_rect.size.y),
			gondola_rect.position,
		])
		draw_polyline(closed, GONDOLA_EDGE_COLOR, 3.0)

	for piece in body.pieces:
		var closed := piece.duplicate()
		closed.append(piece[0])
		draw_polyline(closed, EDGE_COLOR, EDGE_WIDTH)
