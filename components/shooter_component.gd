class_name ShooterComponent
extends Component

enum Mode { FORWARD, AIMED, FIGURE8, SINE_PAIR }

@export var mode: Mode = Mode.FORWARD
@export var bullet_scene: PackedScene = preload("res://bullet/bullet_enemy.tscn")
@export var bullet_speed: float = 800.0
@export var interval: float = 1.4
@export var pattern_speed: float = 1.6
@export var autostart: bool = true
@export var start_on_screen: bool = false
@export var burst_count: int = 0
@export var burst_pause: float = 1.0
@export var wave_amplitude: float = 100.0
@export var wave_frequency: float = 5.0

var active: bool = false
var timer: float = 0.0
var pattern_time: float = 0.0
var shots_in_burst: int = 0
var burst_direction: Vector2 = Vector2.LEFT
var health: HealthComponent

func _ready() -> void:
	health = HealthComponent.find(entity)
	active = autostart

func start() -> void:
	active = true
	timer = 0.0

func stop() -> void:
	start_on_screen = false
	active = false

func _physics_process(delta: float) -> void:
	if not active and start_on_screen and not health.dead and entity.global_position.x <= Bullet.WORLD_WIDTH:
		start()
	if not active or health.dead:
		return
	pattern_time += delta
	timer += delta
	if timer >= interval:
		timer -= interval
		_fire()
		if burst_count > 0:
			shots_in_burst += 1
			if shots_in_burst >= burst_count:
				shots_in_burst = 0
				timer = -burst_pause

func _aim_at_player() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2.LEFT
	return (player.global_position - entity.global_position).normalized()

func _fire() -> void:
	match mode:
		Mode.AIMED:
			_spawn_bullet(_aim_at_player())
		Mode.FIGURE8:
			var t := pattern_time * pattern_speed
			_spawn_bullet(Vector2(sin(t), sin(2.0 * t)).normalized())
		Mode.SINE_PAIR:
			if shots_in_burst == 0:
				burst_direction = _aim_at_player()
			_spawn_bullet(burst_direction, wave_amplitude, wave_frequency, 0.0)
			_spawn_bullet(burst_direction, wave_amplitude, wave_frequency, PI)
		_:
			_spawn_bullet(Vector2.LEFT)

func _spawn_bullet(direction: Vector2, amplitude: float = 0.0, frequency: float = 0.0, phase: float = 0.0) -> void:
	var bullet := bullet_scene.instantiate() as Bullet
	entity.get_parent().add_child(bullet)
	bullet.global_position = entity.global_position
	bullet.direction = direction
	bullet.speed = bullet_speed
	bullet.wave_amplitude = amplitude
	bullet.wave_frequency = frequency
	bullet.wave_phase = phase
