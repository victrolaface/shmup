class_name MagnetComponent
extends Component

signal collected(player: Player)

const COLLECT_DISTANCE := 50.0

@export var drift_speed: float = 60.0
@export var magnet_radius: float = 500.0
@export var magnet_speed: float = 1500.0
@export var only_when_damaged: bool = false

var done: bool = false

func _physics_process(delta: float) -> void:
	if done:
		return

	var player := get_tree().get_first_node_in_group("player") as Player
	var wants_pickup := player != null
	if wants_pickup and only_when_damaged:
		wants_pickup = player.health.health < player.health.max_health

	if wants_pickup:
		var offset := player.global_position - entity.global_position
		var distance := offset.length()
		if distance <= COLLECT_DISTANCE:
			done = true
			collected.emit(player)
			entity.queue_free()
			return
		if distance <= magnet_radius:
			entity.global_position += offset / distance * min(magnet_speed * delta, distance)
			return

	entity.position.x -= drift_speed * delta
	if entity.position.x < -100.0:
		entity.queue_free()
