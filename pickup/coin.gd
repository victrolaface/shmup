extends Area2D

@export var value: int = 1
@export var drift_speed: float = 60.0

var being_inhaled: bool = false
var collected: bool = false

func _ready() -> void:
	add_to_group("inhalable")
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if being_inhaled:
		return
	position.x -= drift_speed * delta
	if position.x < -100.0:
		queue_free()

func collect(_player: Node) -> void:
	if collected:
		return
	collected = true
	Game.add_currency(value)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		collect(area)
