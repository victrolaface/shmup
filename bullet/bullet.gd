class_name Bullet
extends Area2D

const WORLD_WIDTH := 2560.0
const WORLD_HEIGHT := 1440.0
const OFFSCREEN_MARGIN := 100.0

@export var speed: float = 1200.0
@export var damage: int = 1
@export var turn_rate: float = 6.0
@export var enemy_owned: bool = false

var direction: Vector2 = Vector2.RIGHT
var homing_target: Node2D
var acquire_nearest_enemy: bool = false
var homing_delay: float = 0.0
var being_inhaled: bool = false
var age: float = 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if enemy_owned:
		add_to_group("inhalable")

func _physics_process(delta: float) -> void:
	if being_inhaled:
		return

	age += delta

	if homing_delay > 0.0:
		homing_delay = max(homing_delay - delta, 0.0)
	else:
		if acquire_nearest_enemy and (homing_target == null or not is_instance_valid(homing_target)):
			homing_target = _find_nearest_enemy()
		if homing_target != null and is_instance_valid(homing_target):
			var desired: Vector2 = (homing_target.global_position - global_position).normalized()
			direction = direction.slerp(desired, turn_rate * delta).normalized()

	position += direction * speed * delta

	if global_position.x < -OFFSCREEN_MARGIN or global_position.x > WORLD_WIDTH + OFFSCREEN_MARGIN \
			or global_position.y < -OFFSCREEN_MARGIN or global_position.y > WORLD_HEIGHT + OFFSCREEN_MARGIN:
		queue_free()

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist_sq := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		var target := node as Node2D
		if target == null:
			continue
		var dist_sq := global_position.distance_squared_to(target.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = target
	return nearest

func _on_area_entered(area: Area2D) -> void:
	if area == self or not is_instance_valid(area):
		return
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
