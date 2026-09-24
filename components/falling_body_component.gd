class_name FallingBodyComponent
extends Component

const SHATTER_Y := 1430.0
const MAX_SAMPLES := 24
const FRAGMENT_AREA_PER_EXPLOSION := 30000.0

@export var gravity: float = 1700.0
@export var shatter_delay: float = 0.2

var body: DestructibleBodyComponent
var pivot_local: Vector2 = Vector2.ZERO
var pivot_world: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var angle: float = 0.0
var spin: float = 0.0
var age: float = 0.0

func start(pivot: Vector2, scroll_speed: float) -> void:
	body = DestructibleBodyComponent.find(entity)
	pivot_local = pivot
	pivot_world = entity.to_global(pivot)
	angle = entity.rotation
	velocity = Vector2(-scroll_speed + randf_range(-160.0, 160.0), randf_range(-120.0, 0.0))
	spin = randf_range(-1.6, 1.6)

func _physics_process(delta: float) -> void:
	if body == null:
		return
	age += delta
	velocity.y += gravity * delta
	pivot_world += velocity * delta
	angle += spin * delta
	entity.rotation = angle
	entity.global_position = pivot_world - pivot_local.rotated(angle)
	if pivot_world.y > 2200.0:
		entity.queue_free()
	elif age >= shatter_delay and _impacting():
		_shatter()

func _sample_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	var total := 0
	for piece in body.pieces:
		total += piece.size()
	@warning_ignore("integer_division")
	var stride := maxi(1, total / MAX_SAMPLES)
	var counter := 0
	for piece in body.pieces:
		for vertex in piece:
			if counter % stride == 0:
				points.append(entity.to_global(vertex))
			counter += 1
	return points

func _impacting() -> bool:
	var solids: Array[DestructibleBodyComponent] = []
	var solid_bounds: Array[Rect2] = []
	for node in get_tree().get_nodes_in_group("obstruction"):
		var other := DestructibleBodyComponent.find(node)
		if other != null and other != body and other.anchor_direction != Vector2.ZERO:
			solids.append(other)
			solid_bounds.append(other.world_bounds())
	for point in _sample_points():
		if point.y >= SHATTER_Y:
			return true
		for i in solids.size():
			if solid_bounds[i].has_point(point) and solids[i].contains_global(point):
				return true
	return false

func _shatter() -> void:
	var parent := entity.get_parent()
	var points := _sample_points()
	points.shuffle()
	for point in points.slice(0, 6):
		Debris.burst(parent, point, Vector2.UP, body.debris_colors, 6, Vector2(200.0, 720.0), Vector2(velocity.x * 0.3, 0.0), 180.0)
	var explosions := clampi(int(body.total_area() / FRAGMENT_AREA_PER_EXPLOSION) + 1, 1, 4)
	for i in mini(explosions, points.size()):
		var explosion := DestructibleBodyComponent.EXPLOSION_SCENE.instantiate() as Node2D
		explosion.set("min_radius", body.explosion_radius_range.x)
		explosion.set("max_radius", body.explosion_radius_range.y)
		explosion.global_position = points[i]
		parent.add_child(explosion)
	entity.queue_free()
