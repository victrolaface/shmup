class_name ShooterComponent
extends Component

enum Mode { FORWARD, AIMED, FIGURE8, SINE_PAIR, RANDOM }
enum Pattern { FAN, RING, WAVES, SPIRAL, STREAM }

const PATTERN_CONFIG := {
	Pattern.FAN: {"shots": 6, "interval": 0.28},
	Pattern.RING: {"shots": 4, "interval": 0.45},
	Pattern.WAVES: {"shots": 12, "interval": 0.09},
	Pattern.SPIRAL: {"shots": 28, "interval": 0.06},
	Pattern.STREAM: {"shots": 10, "interval": 0.12},
}
const FAN_BULLETS := 5
const FAN_STEP_DEGREES := 12.5
const RING_BULLETS := 18
const SPIRAL_ARMS := 3
const SPIRAL_STEP := 0.45

@export var mode: Mode = Mode.FORWARD
@export var bullet_scene: PackedScene = preload("res://bullet/bullet_enemy.tscn")
@export var bullet_speed: float = 650.0
@export var interval: float = 1.4
@export var pattern_speed: float = 1.6
@export var autostart: bool = true
@export var start_on_screen: bool = false
@export var pick_pattern_once: bool = false
@export var burst_count: int = 0
@export var burst_pause: float = 1.0
@export var wave_amplitude: float = 100.0
@export var wave_frequency: float = 5.0

var active: bool = false
var timer: float = 0.0
var pattern_time: float = 0.0
var shots_in_burst: int = 0
var burst_direction: Vector2 = Vector2.LEFT
var burst_size: int = 0
var shot_interval: float = 1.0
var pattern: Pattern = Pattern.FAN
var spiral_angle: float = 0.0
var health: HealthComponent

func _ready() -> void:
	health = HealthComponent.find(entity)
	active = autostart
	burst_size = burst_count
	shot_interval = interval
	if mode == Mode.RANDOM and pick_pattern_once:
		_apply_pattern(Pattern.values().pick_random())
	if active:
		_begin_burst()

func start() -> void:
	active = true
	timer = 0.0
	_begin_burst()

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
	if timer >= shot_interval:
		timer -= shot_interval
		_fire()
		if burst_size > 0:
			shots_in_burst += 1
			if shots_in_burst >= burst_size:
				timer = -burst_pause
				_begin_burst()

func _begin_burst() -> void:
	shots_in_burst = 0
	if mode == Mode.RANDOM:
		_apply_pattern(pattern if pick_pattern_once else Pattern.values().pick_random())

func _apply_pattern(new_pattern: Pattern) -> void:
	pattern = new_pattern
	burst_size = PATTERN_CONFIG[pattern]["shots"]
	shot_interval = PATTERN_CONFIG[pattern]["interval"]
	spiral_angle = randf() * TAU

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
			_fire_waves()
		Mode.RANDOM:
			_fire_random_pattern()
		_:
			_spawn_bullet(Vector2.LEFT)

func _fire_random_pattern() -> void:
	match pattern:
		Pattern.FAN:
			var aim := _aim_at_player()
			for k in range(-(FAN_BULLETS / 2), FAN_BULLETS / 2 + 1):
				_spawn_bullet(aim.rotated(deg_to_rad(FAN_STEP_DEGREES) * k))
		Pattern.RING:
			var offset := (TAU / RING_BULLETS) * 0.5 * float(shots_in_burst % 2)
			for i in RING_BULLETS:
				_spawn_bullet(Vector2.RIGHT.rotated(TAU * i / RING_BULLETS + offset))
		Pattern.WAVES:
			_fire_waves()
		Pattern.SPIRAL:
			for arm in SPIRAL_ARMS:
				_spawn_bullet(Vector2.RIGHT.rotated(spiral_angle + TAU * arm / SPIRAL_ARMS))
			spiral_angle += SPIRAL_STEP
		Pattern.STREAM:
			_spawn_bullet(_aim_at_player())

func _fire_waves() -> void:
	if shots_in_burst == 0:
		burst_direction = _aim_at_player()
	_spawn_bullet(burst_direction, wave_amplitude, wave_frequency, 0.0)
	_spawn_bullet(burst_direction, wave_amplitude, wave_frequency, PI)

func _spawn_bullet(direction: Vector2, amplitude: float = 0.0, frequency: float = 0.0, phase: float = 0.0) -> void:
	var bullet := bullet_scene.instantiate() as Bullet
	entity.get_parent().add_child(bullet)
	bullet.global_position = entity.global_position
	bullet.direction = direction
	bullet.speed = bullet_speed
	bullet.wave_amplitude = amplitude
	bullet.wave_frequency = frequency
	bullet.wave_phase = phase
