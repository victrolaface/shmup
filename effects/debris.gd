class_name Debris
extends Polygon2D

const MAX_ACTIVE := 220
const GRAVITY := 1500.0

var velocity: Vector2 = Vector2.ZERO
var spin: float = 0.0
var lifetime: float = 0.8
var age: float = 0.0

static func burst(parent: Node, at: Vector2, direction: Vector2, colors: PackedColorArray, count: int, speed_range: Vector2, inherited: Vector2, spread_degrees: float) -> void:
	var room := MAX_ACTIVE - parent.get_tree().get_nodes_in_group("debris").size()
	for i in mini(count, room):
		var chip := Debris.new()
		var size := randf_range(5.0, 16.0)
		var points := PackedVector2Array()
		var angle_offset := randf() * TAU
		for corner in 4:
			var angle := angle_offset + TAU * float(corner) / 4.0
			points.append(Vector2.from_angle(angle) * size * randf_range(0.5, 1.0))
		chip.polygon = points
		chip.color = colors[randi() % colors.size()].lightened(randf_range(0.0, 0.3))
		chip.velocity = direction.rotated(deg_to_rad(randf_range(-spread_degrees, spread_degrees))) * randf_range(speed_range.x, speed_range.y) + inherited
		chip.spin = randf_range(-14.0, 14.0)
		chip.lifetime = randf_range(0.6, 1.1)
		chip.add_to_group("debris")
		parent.add_child(chip)
		chip.global_position = at + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 12.0)

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation += spin * delta
	modulate.a = clampf((lifetime - age) / (lifetime * 0.4), 0.0, 1.0)
