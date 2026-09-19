class_name BombComponent
extends Component

const BOMB_SCENE := preload("res://player/bomb.tscn")
const BASE_INTERVAL := 0.7

@export var drop_offset: Vector2 = Vector2(-45, 15)

var bomb_level: int = 0
var timer: float = 0.0

func _physics_process(delta: float) -> void:
	if bomb_level <= 0:
		return
	timer -= delta
	if timer > 0.0:
		return
	timer = BASE_INTERVAL / float(bomb_level)
	var bomb := BOMB_SCENE.instantiate() as Node2D
	entity.get_parent().add_child(bomb)
	bomb.global_position = entity.global_position + drop_offset
