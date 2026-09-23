class_name ShooterComponent
extends Component

signal burst_started
signal burst_finished

enum Mode { FORWARD, AIMED, FIGURE8, SINE_PAIR, RANDOM, RADIAL, FAN_LEFT, CURTAIN }
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
@export var single_burst: bool = false
@export var wave_amplitude: float = 100.0
@export var wave_frequency: float = 5.0
@export var radial_spokes: int = 20
@export var radial_colors: PackedColorArray = PackedColorArray([Color(0.45, 0.65, 1.0, 1.0), Color(0.85, 0.5, 1.0, 1.0)])
@export var fan_bullets: int = 7
@export var fan_angle_degrees: float = 120.0
@export var forced_pattern: int = -1
@export var spiral_arms: int = 3
@export var ring_bullets: int = 18
@export var bullet_tint: Color = Color(0, 0, 0, 0)
@export var animation_name: String = ""
@export var curtain_colors: PackedColorArray = PackedColorArray([Color(0.98, 0.05, 1.0, 1.0), Color(0.7, 0.05, 1.0, 1.0), Color(1.0, 0.05, 0.73, 1.0), Color(0.85, 0.05, 0.95, 1.0)])
@export var curtain_spawn_offset_x: float = -100.0
@export var curtain_dot_spacing: float = 62.0
@export var curtain_wave_amplitude: float = 60.0
@export var curtain_wavelength: float = 380.0
@export var curtain_phase_step: float = 0.6
@export var curtain_gap_height: float = 380.0
@export var curtain_bob_amplitude: float = 90.0
@export var curtain_bob_frequency: float = 2.4

var active: bool = false
var timer: float = 0.0
var pattern_time: float = 0.0
var shots_in_burst: int = 0
var burst_number: int = 0
var burst_direction: Vector2 = Vector2.LEFT
var burst_size: int = 0
var shot_interval: float = 1.0
var pattern: Pattern = Pattern.FAN
var spiral_angle: float = 0.0
var curtain_gap_y: float = 720.0
var waiting_to_hand_off: bool = false
var handoff_timer: float = 0.0
var health: HealthComponent

func _ready() -> void:
	health = HealthComponent.find(entity)
	active = autostart
	burst_size = burst_count
	shot_interval = interval
	if mode == Mode.RANDOM and forced_pattern >= 0:
		_apply_pattern(Pattern.values()[forced_pattern])
	elif mode == Mode.RANDOM and pick_pattern_once:
		_apply_pattern(Pattern.values().pick_random())
	if active:
		_begin_burst()

func start() -> void:
	active = true
	waiting_to_hand_off = false
	timer = 0.0
	_begin_burst()

func stop() -> void:
	start_on_screen = false
	active = false
	waiting_to_hand_off = false

func _physics_process(delta: float) -> void:
	if not active and start_on_screen and not health.dead and entity.global_position.x <= Bullet.WORLD_WIDTH:
		start()
	if health.dead:
		return
	if waiting_to_hand_off:
		handoff_timer -= delta
		if handoff_timer <= 0.0:
			waiting_to_hand_off = false
			burst_finished.emit()
		return
	if not active:
		return
	pattern_time += delta
	timer += delta
	if timer >= shot_interval:
		timer -= shot_interval
		if burst_size > 0 and shots_in_burst == 0:
			burst_started.emit()
		_fire()
		if burst_size > 0:
			shots_in_burst += 1
			if shots_in_burst >= burst_size:
				if single_burst:
					active = false
					waiting_to_hand_off = true
					handoff_timer = burst_pause
				else:
					timer = -burst_pause
					_begin_burst()

func _begin_burst() -> void:
	shots_in_burst = 0
	burst_number += 1
	if mode == Mode.RANDOM:
		if forced_pattern >= 0 or pick_pattern_once:
			_apply_pattern(pattern)
		else:
			_apply_pattern(Pattern.values().pick_random())

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
		Mode.RADIAL:
			_fire_radial()
		Mode.FAN_LEFT:
			_fire_fan_left()
		Mode.CURTAIN:
			_fire_curtain()
		_:
			_spawn_bullet(Vector2.LEFT)

func _fire_random_pattern() -> void:
	match pattern:
		Pattern.FAN:
			var aim := _aim_at_player()
			for k in range(-(FAN_BULLETS / 2), FAN_BULLETS / 2 + 1):
				_spawn_bullet(aim.rotated(deg_to_rad(FAN_STEP_DEGREES) * k))
		Pattern.RING:
			var offset := (TAU / ring_bullets) * 0.5 * float(shots_in_burst % 2)
			for i in ring_bullets:
				_spawn_bullet(Vector2.RIGHT.rotated(TAU * i / ring_bullets + offset))
		Pattern.WAVES:
			_fire_waves()
		Pattern.SPIRAL:
			for arm in spiral_arms:
				_spawn_bullet(Vector2.RIGHT.rotated(spiral_angle + TAU * arm / spiral_arms))
			spiral_angle += SPIRAL_STEP
		Pattern.STREAM:
			_spawn_bullet(_aim_at_player())

func _fire_radial() -> void:
	var spoke_offset := (TAU / float(radial_spokes)) * 0.5 * float(burst_number % 2)
	var tint := radial_colors[shots_in_burst % radial_colors.size()]
	var dot_scale := 0.75 + 0.45 * absf(sin(float(shots_in_burst) * 0.8))
	for i in radial_spokes:
		var angle := TAU * float(i) / float(radial_spokes) + spoke_offset
		_spawn_bullet(Vector2.RIGHT.rotated(angle), 0.0, 0.0, 0.0, tint, dot_scale)

func _fire_fan_left() -> void:
	var step := fan_angle_degrees / float(fan_bullets - 1)
	var shifted := shots_in_burst % 2 == 1
	var count := fan_bullets - (1 if shifted else 0)
	var first := -fan_angle_degrees * 0.5 + (step * 0.5 if shifted else 0.0)
	for i in count:
		_spawn_bullet(Vector2.LEFT.rotated(deg_to_rad(first + step * float(i))))

func _fire_curtain() -> void:
	if shots_in_burst == 0:
		curtain_gap_y = randf_range(curtain_gap_height, Bullet.WORLD_HEIGHT - curtain_gap_height)
	var tint := curtain_colors[shots_in_burst % curtain_colors.size()]
	var phase := curtain_phase_step * float(shots_in_burst)
	var y := curtain_dot_spacing * 0.5
	while y < Bullet.WORLD_HEIGHT:
		if absf(y - curtain_gap_y) > curtain_gap_height * 0.5:
			var x := entity.global_position.x + curtain_spawn_offset_x + curtain_wave_amplitude * sin(TAU * y / curtain_wavelength + phase)
			_spawn_bullet(Vector2.LEFT, curtain_bob_amplitude, curtain_bob_frequency, phase, tint, 1.0, Vector2(x, y))
		y += curtain_dot_spacing

func _fire_waves() -> void:
	if shots_in_burst == 0:
		burst_direction = _aim_at_player()
	_spawn_bullet(burst_direction, wave_amplitude, wave_frequency, 0.0)
	_spawn_bullet(burst_direction, wave_amplitude, wave_frequency, PI)

func _spawn_bullet(direction: Vector2, amplitude: float = 0.0, frequency: float = 0.0, phase: float = 0.0, tint: Color = Color(0, 0, 0, 0), dot_scale: float = 1.0, at: Vector2 = Vector2.INF) -> void:
	var bullet := bullet_scene.instantiate() as Bullet
	entity.get_parent().add_child(bullet)
	bullet.global_position = entity.global_position if at == Vector2.INF else at
	bullet.direction = direction
	bullet.speed = bullet_speed
	bullet.wave_amplitude = amplitude
	bullet.wave_frequency = frequency
	bullet.wave_phase = phase
	var final_tint := tint if tint.a > 0.0 else bullet_tint
	if final_tint.a > 0.0:
		(bullet.get_node("Visual") as Polygon2D).color = final_tint
	if dot_scale != 1.0:
		bullet.scale = Vector2.ONE * dot_scale
