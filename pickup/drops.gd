class_name Drops
extends RefCounted

const CHARGE_PICKUP_SCENE := preload("res://pickup/charge_pickup.tscn")
const JEWEL_SCENE := preload("res://pickup/jewel.tscn")
const COIN_SCENE := preload("res://pickup/coin.tscn")
const HEART_SCENE := preload("res://pickup/heart.tscn")
const HEART_DROP_CHANCE := 0.06
const SCATTER := 30.0

static func spawn_at(parent: Node, pos: Vector2, scene: PackedScene, scatter: float = SCATTER) -> void:
	var pickup := scene.instantiate() as Node2D
	pickup.global_position = pos + Vector2(randf_range(-scatter, scatter), randf_range(-scatter, scatter))
	parent.call_deferred("add_child", pickup)

static func spawn_heart(parent: Node, pos: Vector2, scatter: float = SCATTER) -> void:
	var player := parent.get_tree().get_first_node_in_group("player") as Player
	if player == null or player.health >= player.max_health:
		return
	spawn_at(parent, pos, HEART_SCENE, scatter)

static func enemy_drops(parent: Node, pos: Vector2, jewel_chance: float) -> void:
	spawn_at(parent, pos, CHARGE_PICKUP_SCENE)
	spawn_at(parent, pos, COIN_SCENE)
	if randf() < jewel_chance:
		spawn_at(parent, pos, JEWEL_SCENE)
	if randf() < HEART_DROP_CHANCE:
		spawn_heart(parent, pos)
