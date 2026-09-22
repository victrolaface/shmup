class_name ScreenShakeCamera
extends Camera2D

@export var max_offset: float = 45.0
@export var max_rotation_degrees: float = 2.5
@export var decay: float = 3.5

var trauma: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	# Anchor to the top-left so world content lines up with the existing
	# no-camera layout (player position, spawn edges, HUD) instead of centering.
	anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT

func shake(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)

func _process(delta: float) -> void:
	if trauma <= 0.0:
		if offset != Vector2.ZERO or rotation != 0.0:
			offset = Vector2.ZERO
			rotation = 0.0
		return
	trauma = maxf(trauma - decay * delta, 0.0)
	var power := trauma * trauma
	offset = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * power * max_offset
	rotation = deg_to_rad(rng.randf_range(-1.0, 1.0) * power * max_rotation_degrees)
