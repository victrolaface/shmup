extends Node2D

const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")
const GROUND_Y := 1280.0

@export var gravity: float = 2200.0
@export var hit_radius: float = 70.0
@export var blast_radius: float = 170.0
@export var damage: int = 3
@export var air_damage: int = 1

var velocity: Vector2 = Vector2(-220.0, 0.0)
var exploded: bool = false

func _physics_process(delta: float) -> void:
	if exploded:
		return

	velocity.y += gravity * delta
	position += velocity * delta

	if global_position.x < -100.0 or global_position.y >= GROUND_Y or _near_ground_enemy():
		_explode()

func _near_ground_enemy() -> bool:
	for node in get_tree().get_nodes_in_group("ground_enemies"):
		var target := node as Node2D
		if target != null and is_instance_valid(target) and global_position.distance_to(target.global_position) <= hit_radius:
			return true
	return false

func _explode() -> void:
	exploded = true
	for node in get_tree().get_nodes_in_group("enemies"):
		var target := node as Node2D
		if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
			continue
		if global_position.distance_to(target.global_position) <= blast_radius and target.has_method("take_damage"):
			target.take_damage(damage if target.is_in_group("ground_enemies") else air_damage)

	var explosion := EXPLOSION_SCENE.instantiate() as Node2D
	explosion.set("min_radius", blast_radius * 0.6)
	explosion.set("max_radius", blast_radius * 0.9)
	explosion.global_position = global_position
	get_parent().add_child(explosion)
	queue_free()
