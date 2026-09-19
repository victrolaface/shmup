class_name WeaponComponent
extends Component

const MUZZLE_FLASH_SCENE := preload("res://effects/muzzle_flash.tscn")
const DIAGONAL_STEP_DEGREES := 14.0
const MUZZLE_OFFSET := Vector2(45, 0)

@export var bullet_scene: PackedScene = preload("res://bullet/bullet_player.tscn")
@export var fire_interval: float = 0.12
@export var bullet_row_spacing: float = 24.0

var shot_rows: int = 2
var diagonal_level: int = 0
var cooldown: float = 0.0

func _physics_process(delta: float) -> void:
	cooldown = max(cooldown - delta, 0.0)
	if cooldown <= 0.0 and Input.is_action_pressed("shoot") and not Input.is_action_pressed("inhale"):
		_fire()

func _fire() -> void:
	cooldown = fire_interval

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
