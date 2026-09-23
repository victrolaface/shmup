class_name WeaponComponent
extends Component

const MUZZLE_FLASH_SCENE := preload("res://effects/muzzle_flash.tscn")
const DIAGONAL_STEP_DEGREES := 14.0
const MUZZLE_OFFSET := Vector2(0, 8.75)

@export var bullet_scene: PackedScene = preload("res://bullet/bullet_player.tscn")
@export var fire_interval: float = 0.12
@export var bullet_row_spacing: float = 24.0
@export var near_distance: float = 200.0
@export var far_distance: float = 1000.0
@export var max_rate_multiplier: float = 3.0

var shot_rows: int = 2
var diagonal_level: int = 0
var cooldown: float = 0.0
var rate_multiplier: float = 1.0
var sfx: SfxComponent

func _ready() -> void:
	sfx = Component.of(entity, "ShotSfxComponent") as SfxComponent

func _physics_process(delta: float) -> void:
	rate_multiplier = _proximity_multiplier()
	cooldown = max(cooldown - delta * rate_multiplier, -delta * max_rate_multiplier)
	if cooldown <= 0.0 and Input.is_action_pressed("shoot") and not Input.is_action_pressed("inhale"):
		_fire()

func _proximity_multiplier() -> float:
	var nearest := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var edge_distance := entity.global_position.distance_to(enemy.global_position) - _enemy_radius(enemy)
		nearest = min(nearest, edge_distance)
	if nearest == INF:
		return 1.0
	var closeness: float = clamp((far_distance - nearest) / (far_distance - near_distance), 0.0, 1.0)
	return lerp(1.0, max_rate_multiplier, closeness)

func _enemy_radius(enemy: Node2D) -> float:
	var shape_node := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return 0.0
	var circle := shape_node.shape as CircleShape2D
	if circle != null:
		return circle.radius
	var rect := shape_node.shape as RectangleShape2D
	if rect != null:
		return max(rect.size.x, rect.size.y) * 0.5
	return 0.0

func _fire() -> void:
	cooldown += fire_interval
	if sfx != null:
		sfx.play()

	var flash := MUZZLE_FLASH_SCENE.instantiate() as Node2D
	flash.global_position = entity.global_position + MUZZLE_OFFSET
	entity.get_parent().add_child(flash)

	for i in shot_rows:
		var row_offset := (float(i) - float(shot_rows - 1) / 2.0) * bullet_row_spacing
		_spawn_shot(MUZZLE_OFFSET + Vector2(0, row_offset), Vector2.RIGHT)

	for level in range(1, diagonal_level + 1):
		var angle := deg_to_rad(DIAGONAL_STEP_DEGREES * level)
		_spawn_shot(MUZZLE_OFFSET, Vector2.RIGHT.rotated(-angle))
		_spawn_shot(MUZZLE_OFFSET, Vector2.RIGHT.rotated(angle))

func _spawn_shot(offset: Vector2, direction: Vector2) -> void:
	var bullet := bullet_scene.instantiate() as Bullet
	entity.get_parent().add_child(bullet)
	bullet.global_position = entity.global_position + offset
	bullet.direction = direction
