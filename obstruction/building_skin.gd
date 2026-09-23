class_name BuildingSkin
extends Node2D

const BODY_COLOR := Color(0.82, 0.76, 0.64, 1)
const ROOF_COLOR := Color(0.58, 0.52, 0.46, 1)
const PITCHED_ROOF_COLOR := Color(0.6, 0.36, 0.32, 1)
const PITCHED_EDGE_COLOR := Color(0.68, 0.42, 0.38, 1)
const CHIMNEY_COLOR := Color(0.42, 0.36, 0.32, 1)
const WINDOW_GLASS := Color(0.62, 0.76, 0.82, 1)
const AWNING_COLORS := [Color(0.75, 0.32, 0.3, 1), Color(0.3, 0.55, 0.5, 1), Color(0.85, 0.6, 0.25, 1), Color(0.45, 0.4, 0.62, 1)]
const BASE_OVERSHOOT := 60.0
const EDGE_WIDTH := 5.0

var width: float = 300.0
var height: float = 300.0
var roof_height: float = 0.0
var body: DestructibleBodyComponent
var windows: Array[Rect2] = []
var window_color: Array[Color] = []
var visible_windows: Array[int] = []
var roof_pieces: Array[PackedVector2Array] = []
var chimney_base: Vector2 = Vector2.ZERO

func configure(new_width: float, new_height: float, new_roof_height: float = 0.0) -> void:
	width = new_width
	height = new_height
	roof_height = new_roof_height
	var half_w := width * 0.5
	var half_h := height * 0.5

	_build_windows()
	chimney_base = Vector2(width * 0.24, -half_h - roof_height * (1.0 - 0.24 / 0.5))

	var outline := PackedVector2Array([Vector2(-half_w, half_h + BASE_OVERSHOOT), Vector2(-half_w, -half_h)])
	if roof_height > 0.0:
		outline.append(Vector2(0.0, -half_h - roof_height))
	outline.append(Vector2(half_w, -half_h))
	outline.append(Vector2(half_w, half_h + BASE_OVERSHOOT))

	body = DestructibleBodyComponent.find(get_parent())
	body.changed.connect(_refresh)
	body.anchor_direction = Vector2.DOWN
	body.debris_colors = PackedColorArray([BODY_COLOR, BODY_COLOR, ROOF_COLOR, WINDOW_GLASS])
	if roof_height > 0.0:
		body.debris_colors.append_array(PackedColorArray([PITCHED_ROOF_COLOR, PITCHED_ROOF_COLOR, PITCHED_EDGE_COLOR]))
	body.set_polygon(outline)

func adopt(source: BuildingSkin, fragment_pieces: Array[PackedVector2Array]) -> void:
	width = source.width
	height = source.height
	roof_height = source.roof_height
	windows = source.windows
	window_color = source.window_color
	chimney_base = source.chimney_base
	body = DestructibleBodyComponent.find(get_parent())
	body.changed.connect(_refresh)
	body.debris_colors = source.body.debris_colors
	body.set_pieces(fragment_pieces)

func _build_windows() -> void:
	windows.clear()
	window_color.clear()
	var columns := int((width - 40.0) / 52.0)
	var rows := int((height - 60.0) / 72.0)
	if columns < 1 or rows < 1:
		return
	var x_step := (width - 40.0) / float(columns)
	for row in rows:
		for column in columns:
			windows.append(Rect2(-width * 0.5 + 20.0 + float(column) * x_step + (x_step - 26.0) * 0.5, -height * 0.5 + 34.0 + float(row) * 72.0, 26.0, 38.0))
			window_color.append(AWNING_COLORS[randi() % AWNING_COLORS.size()] if randf() < 0.4 else WINDOW_GLASS)

func _refresh() -> void:
	roof_pieces.clear()
	if roof_height > 0.0:
		var zone := PackedVector2Array([
			Vector2(-width, -height * 0.5 - roof_height - 50.0), Vector2(width, -height * 0.5 - roof_height - 50.0),
			Vector2(width, -height * 0.5), Vector2(-width, -height * 0.5),
		])
		for piece in body.pieces:
			roof_pieces.append_array(DestructibleBodyComponent.solid_results(Geometry2D.intersect_polygons(piece, zone)))
	visible_windows.clear()
	for i in windows.size():
		var rect := windows[i]
		if body.contains_local(rect.position) and body.contains_local(rect.end) \
				and body.contains_local(Vector2(rect.end.x, rect.position.y)) and body.contains_local(Vector2(rect.position.x, rect.end.y)):
			visible_windows.append(i)
	queue_redraw()

func _fill(polygon: PackedVector2Array, color: Color) -> void:
	for part in DestructibleBodyComponent.convex_parts(polygon):
		draw_colored_polygon(part, color)

func _draw() -> void:
	if body == null:
		return
	for part in body.parts:
		draw_colored_polygon(part, BODY_COLOR)
	for piece in roof_pieces:
		_fill(piece, PITCHED_ROOF_COLOR)

	if roof_height > 0.0 and body.contains_local(chimney_base + Vector2(0.0, 8.0)):
		draw_rect(Rect2(chimney_base.x - 14.0, chimney_base.y - 46.0, 28.0, 56.0), CHIMNEY_COLOR)

	for index in visible_windows:
		draw_rect(windows[index], window_color[index])

	var edge := PITCHED_EDGE_COLOR if roof_height > 0.0 else ROOF_COLOR
	for piece in body.pieces:
		var closed := piece.duplicate()
		closed.append(piece[0])
		draw_polyline(closed, edge, EDGE_WIDTH)
