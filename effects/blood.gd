class_name Blood
extends Polygon2D

const MAX_ACTIVE := 700
const GRAVITY := 1500.0
const WORLD_WIDTH := 2560.0
const WORLD_HEIGHT := 1440.0
const OFFSCREEN_MARGIN := 100.0
const DEFAULT_COLOR := Color(0.6, 0.03, 0.03)

static var active_count: int = 0

var velocity: Vector2 = Vector2.ZERO
var spin: float = 0.0
var drop_radius: float = 6.0

## Spawns one droplet. Returns false (and spawns nothing) once the global cap
## of live droplets is reached.
static func spawn_drop(parent: Node, at: Vector2, drop_velocity: Vector2, radius: float, blood_color: Color = DEFAULT_COLOR) -> bool:
	if active_count >= MAX_ACTIVE:
		return false
	var drop := Blood.new()
	drop.drop_radius = radius
	var points := PackedVector2Array()
	var segments := 10
	for s in segments:
		var angle := TAU * float(s) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	drop.polygon = points
	drop.color = blood_color
	drop.velocity = drop_velocity
	drop.spin = randf_range(-9.0, 9.0)
	drop.z_as_relative = false
	drop.z_index = 50
	drop.add_to_group("blood")
	parent.add_child(drop)
	drop.global_position = at
	return true

static func burst(parent: Node, at: Vector2, direction: Vector2, count: int, speed_range: Vector2, inherited: Vector2, spread_degrees: float, blood_color: Color = DEFAULT_COLOR) -> void:
	for i in count:
		var drop_velocity := direction.rotated(deg_to_rad(randf_range(-spread_degrees, spread_degrees))) * randf_range(speed_range.x, speed_range.y) + inherited
		var start := at + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 14.0)
		if not spawn_drop(parent, start, drop_velocity, randf_range(4.0, 11.0), blood_color):
			return

func _enter_tree() -> void:
	active_count += 1

func _exit_tree() -> void:
	active_count -= 1

func _process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	global_position += velocity * delta
	rotation += spin * delta

	# Liquid-style streaking: elongate the droplet along its direction of
	# travel so it reads as a falling/splattering fluid blob rather than a
	# rigid chip, then relax back toward round as it slows.
	var speed := velocity.length()
	var stretch := clampf(speed / 1100.0, 0.0, 1.5)
	scale = Vector2(1.0 - stretch * 0.35, 1.0 + stretch * 0.6)
	if speed > 15.0:
		rotation = velocity.angle() + PI / 2.0

	if global_position.x < -OFFSCREEN_MARGIN or global_position.x > WORLD_WIDTH + OFFSCREEN_MARGIN \
			or global_position.y > WORLD_HEIGHT + OFFSCREEN_MARGIN:
		queue_free()
