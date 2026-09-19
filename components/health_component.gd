class_name HealthComponent
extends Component

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal died
signal god_mode_changed(active: bool)

@export var max_health: int = 3
@export var invincibility_duration: float = 0.0
@export var free_on_death: bool = true

var health: int
var invincible_time: float = 0.0
var god_mode: bool = false
var dead: bool = false

static func find(target: Node) -> HealthComponent:
	return target.get_node_or_null("HealthComponent") as HealthComponent

func _ready() -> void:
	health = max_health

func _physics_process(delta: float) -> void:
	if invincible_time > 0.0:
		invincible_time = max(invincible_time - delta, 0.0)

func take_damage(amount: int) -> void:
	if dead or god_mode or invincible_time > 0.0:
		return
	health -= amount
	damaged.emit(amount)
	health_changed.emit(max(health, 0), max_health)
	if health <= 0:
		dead = true
		died.emit()
		if free_on_death:
			entity.queue_free()
		return
	invincible_time = invincibility_duration

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func toggle_god_mode() -> void:
	god_mode = not god_mode
	god_mode_changed.emit(god_mode)
