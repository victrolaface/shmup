class_name DropComponent
extends Component

const CHARGE_SCENE := preload("res://pickup/charge_pickup.tscn")
const COIN_SCENE := preload("res://pickup/coin.tscn")
const HEART_SCENE := preload("res://pickup/heart.tscn")

@export var charge_count: int = 1
@export var coin_count: int = 1
@export var heart_chance: float = 0.10
@export var guaranteed_hearts: int = 0
@export var scatter: float = 30.0

func _ready() -> void:
	HealthComponent.find(entity).died.connect(_on_died)

func _on_died() -> void:
	for i in charge_count:
		_spawn(CHARGE_SCENE)
	for i in coin_count:
		_spawn(COIN_SCENE)

	var hearts := guaranteed_hearts
	if randf() < heart_chance:
		hearts += 1
	if hearts > 0 and _player_is_hurt():
		for i in hearts:
			_spawn(HEART_SCENE)

func _player_is_hurt() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player != null and player.health.health < player.health.max_health

func _spawn(scene: PackedScene) -> void:
	var pickup := scene.instantiate() as Node2D
	pickup.global_position = entity.global_position + Vector2(randf_range(-scatter, scatter), randf_range(-scatter, scatter))
	entity.get_parent().call_deferred("add_child", pickup)
