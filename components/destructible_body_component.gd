class_name DestructibleBodyComponent
extends Component

signal changed

const MIN_PIECE_AREA := 900.0
const CHUNK_VERTICES := 9
const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")
const DEBRIS_SPEED_RANGE := Vector2(300.0, 820.0)

@export var debris_colors: PackedColorArray = PackedColorArray([Color(0.3, 0.3, 0.4, 1)])
@export var explosion_area_threshold: float = 7000.0
@export var explosion_radius_range: Vector2 = Vector2(45.0, 75.0)
@export var destroyed_radius_range: Vector2 = Vector2(90.0, 130.0)
@export var anchor_direction: Vector2 = Vector2.ZERO

var damage_progress: float = 0.0
var anchor_level: float = 0.0
var pieces: Array[PackedVector2Array] = []
var parts: Array[PackedVector2Array] = []
var shape_nodes: Array[CollisionShape2D] = []
var flush_queued: bool = false

static func find(target: Node) -> DestructibleBodyComponent:
	return target.get_node_or_null("DestructibleBodyComponent") as DestructibleBodyComponent

static func signed_area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5

static func bounds_of(polygon: PackedVector2Array) -> Rect2:
	var low := polygon[0]
	var high := polygon[0]
	for point in polygon:
		low = Vector2(minf(low.x, point.x), minf(low.y, point.y))
		high = Vector2(maxf(high.x, point.x), maxf(high.y, point.y))
	return Rect2(low, high - low)

static func solid_results(results: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var kept: Array[PackedVector2Array] = []
	if results.is_empty():
		return kept
	var largest := 0.0
	for result in results:
		if absf(signed_area(result)) > absf(largest):
			largest = signed_area(result)
	for result in results:
		var area := signed_area(result)
		if signf(area) == signf(largest) and absf(area) >= MIN_PIECE_AREA:
			kept.append(result)
	return kept

func set_polygon(polygon: PackedVector2Array) -> void:
	anchor_level = -INF
	if anchor_direction != Vector2.ZERO:
		for point in polygon:
			anchor_level = maxf(anchor_level, point.dot(anchor_direction))
	pieces = [polygon]
	_refresh()

func set_pieces(new_pieces: Array[PackedVector2Array]) -> void:
	pieces = new_pieces
	_refresh()

func world_bounds() -> Rect2:
	var result := Rect2()
	var first := true
	for piece in pieces:
		result = bounds_of(piece) if first else result.merge(bounds_of(piece))
		first = false
	result.position += entity.global_position
	return result

static func centroid_of(polygon: PackedVector2Array) -> Vector2:
	var area := signed_area(polygon)
	if absf(area) < 1.0:
		return bounds_of(polygon).get_center()
	var sum := Vector2.ZERO
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		sum += (a + b) * (a.x * b.y - b.x * a.y)
	return sum / (6.0 * area)

func _is_anchored(piece: PackedVector2Array) -> bool:
	for point in piece:
		if point.dot(anchor_direction) >= anchor_level - 1.0:
			return true
	return false

func _detach_loose(kept_pieces: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var loose: Array[PackedVector2Array] = []
	if anchor_direction == Vector2.ZERO:
		return loose
	var anchored: Array[PackedVector2Array] = []
	for piece in kept_pieces:
		if _is_anchored(piece):
			anchored.append(piece)
		else:
			loose.append(piece)
	kept_pieces.assign(anchored)
	return loose

func _spawn_fragments(loose: Array[PackedVector2Array]) -> void:
	if not is_instance_valid(entity) or not entity.is_inside_tree() or entity.scene_file_path.is_empty():
		return
	var scene := load(entity.scene_file_path) as PackedScene
	var source_skin := entity.get_node_or_null("Skin")
	var mover := Component.of(entity, "WaveMoveComponent") as WaveMoveComponent
	var scroll := mover.speed if mover != null else 0.0
	for piece in loose:
		var fragment := scene.instantiate() as Node2D
		fragment.position = entity.position
		fragment.rotation = entity.rotation
		fragment.get_node("WaveMoveComponent").free()
		var single: Array[PackedVector2Array] = [piece]
		fragment.get_node("Skin").call("adopt", source_skin, single)
		entity.get_parent().add_child(fragment)
		var falling := FallingBodyComponent.new()
		falling.name = "FallingBodyComponent"
		fragment.add_child(falling)
		falling.start(centroid_of(piece), scroll)

func total_area() -> float:
	var total := 0.0
	for piece in pieces:
		total += absf(signed_area(piece))
	return total

func carve(global_point: Vector2, radius: float, pop_direction: Vector2 = Vector2.UP) -> void:
	if pieces.is_empty():
		return
	var area_before := total_area()
	var center := entity.to_local(global_point)
	var chunk := PackedVector2Array()
	var start_angle := randf() * TAU
	for i in CHUNK_VERTICES:
		var angle := start_angle + TAU * float(i) / float(CHUNK_VERTICES)
		chunk.append(center + Vector2.from_angle(angle) * radius * randf_range(0.72, 1.12))
	var chunk_bounds := bounds_of(chunk)

	var next_pieces: Array[PackedVector2Array] = []
	var touched := false
	for piece in pieces:
		if not bounds_of(piece).intersects(chunk_bounds):
			next_pieces.append(piece)
			continue
		var clipped: Array[PackedVector2Array] = Geometry2D.clip_polygons(piece, chunk)
		if clipped.size() == 1 and is_equal_approx(absf(signed_area(clipped[0])), absf(signed_area(piece))):
			next_pieces.append(piece)
			continue
		touched = true
		next_pieces.append_array(solid_results(clipped))
	var loose: Array[PackedVector2Array] = []
	if touched:
		loose = _detach_loose(next_pieces)
		pieces = next_pieces
		_refresh()
		_pop_effects(global_point, radius, pop_direction, area_before - total_area())
		if not loose.is_empty():
			_spawn_fragments.call_deferred(loose)

func _pop_effects(global_point: Vector2, radius: float, pop_direction: Vector2, removed_area: float) -> void:
	var parent := entity.get_parent()
	var mover := Component.of(entity, "WaveMoveComponent") as WaveMoveComponent
	var inherited := Vector2(-mover.speed, 0.0) if mover != null else Vector2.ZERO
	var spread := 65.0 if radius < 60.0 else 110.0
	Debris.burst(parent, global_point, pop_direction, debris_colors, clampi(int(radius / 4.5), 5, 24), DEBRIS_SPEED_RANGE, inherited, spread)

	var destroyed := pieces.is_empty()
	damage_progress += removed_area
	if destroyed or damage_progress >= explosion_area_threshold:
		damage_progress = fmod(damage_progress, explosion_area_threshold)
		var range_used := destroyed_radius_range if destroyed else explosion_radius_range
		var explosion := EXPLOSION_SCENE.instantiate() as Node2D
		explosion.set("min_radius", range_used.x)
		explosion.set("max_radius", range_used.y)
		explosion.global_position = global_point
		parent.add_child(explosion)

func contains_global(global_point: Vector2) -> bool:
	return contains_local(entity.to_local(global_point))

func contains_local(local_point: Vector2) -> bool:
	for piece in pieces:
		if Geometry2D.is_point_in_polygon(local_point, piece):
			return true
	return false

func surface_y(global_x: float, from_above: bool) -> float:
	var local_x := global_x - entity.global_position.x
	var found := INF if from_above else -INF
	for piece in pieces:
		for i in piece.size():
			var a := piece[i]
			var b := piece[(i + 1) % piece.size()]
			if (a.x <= local_x and local_x < b.x) or (b.x <= local_x and local_x < a.x):
				var y := a.y + (b.y - a.y) * (local_x - a.x) / (b.x - a.x)
				found = minf(found, y) if from_above else maxf(found, y)
	return INF if is_inf(found) else entity.global_position.y + found

func _refresh() -> void:
	if not entity.is_inside_tree():
		_flush()
	elif not flush_queued:
		flush_queued = true
		_flush.call_deferred()

static func convex_parts(polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for part in Geometry2D.decompose_polygon_in_convex(polygon):
		result.append(part)
	return result

func _flush() -> void:
	flush_queued = false
	parts.clear()
	for piece in pieces:
		parts.append_array(convex_parts(piece))
	changed.emit()
	for node in shape_nodes:
		if is_instance_valid(node):
			node.queue_free()
	shape_nodes.clear()
	for part in parts:
		var shape := ConvexPolygonShape2D.new()
		shape.points = part
		var shape_node := CollisionShape2D.new()
		shape_node.shape = shape
		entity.add_child(shape_node)
		shape_nodes.append(shape_node)
	if pieces.is_empty():
		entity.queue_free()
