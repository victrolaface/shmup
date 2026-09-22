class_name DanmakuComponent
extends Component

enum Pattern { SPIRAL_BLOOM, RING_PULSE, AIMED_FANS, WALL_GAP, CROSS_SPIRALS, PETAL_BURST, SHOOTER, STARBURST_LINES, SNAKE_LINES, BRAID_LINES, GRID_LINES, POLYGON_WAVES, PINWHEEL_BLADES, COMET_RAIN, SCISSOR_CROSS, DIAMOND_LATTICE, TWIN_VORTEX }
enum Preset { BOSS_ONE, BOSS_TWO, MEDIUM, BOSS_THREE }

const BULLET_SCENE := preload("res://bullet/bullet_enemy.tscn")
const MAX_ENEMY_BULLETS := 1000
const DEFAULT_ANIMATIONS := {
	Pattern.SPIRAL_BLOOM: "attack_surround_stream",
	Pattern.CROSS_SPIRALS: "attack_surround_stream",
	Pattern.RING_PULSE: "attack_radial",
	Pattern.PETAL_BURST: "attack_radial",
	Pattern.AIMED_FANS: "attack_homing_cone",
	Pattern.WALL_GAP: "attack_horizontal_line",
	Pattern.STARBURST_LINES: "attack_radial",
	Pattern.POLYGON_WAVES: "attack_surround_stream",
	Pattern.BRAID_LINES: "attack_surround_stream",
	Pattern.SNAKE_LINES: "attack_homing_cone",
	Pattern.GRID_LINES: "attack_horizontal_line",
	Pattern.PINWHEEL_BLADES: "attack_surround_stream",
	Pattern.COMET_RAIN: "attack_horizontal_line",
	Pattern.SCISSOR_CROSS: "attack_homing_cone",
	Pattern.DIAMOND_LATTICE: "attack_horizontal_line",
	Pattern.TWIN_VORTEX: "attack_surround_stream",
}

@export var preset: Preset = Preset.BOSS_ONE
@export var density_scale: float = 1.0
@export var speed_scale: float = 1.0
@export var bullet_cap: int = 800
@export var start_on_screen: bool = false
@export var palette: PackedColorArray = PackedColorArray([Color(1.0, 0.35, 0.6, 1.0), Color(0.65, 0.5, 1.0, 1.0), Color(0.4, 0.85, 1.0, 1.0)])

var program: Array[Dictionary] = []
var active: bool = false
var phase: Dictionary = {}
var phase_index: int = -1
var phase_bars_left: int = 0
var counter: int = 0
var gap_phase: float = 0.0
var health: HealthComponent
var animation_player: AnimationPlayer

func _ready() -> void:
	health = HealthComponent.find(entity)
	animation_player = Component.of(entity, "AnimationPlayer") as AnimationPlayer
	_build_program()
	active = start_on_screen
	Conductor.bar_started.connect(_on_bar_started)
	Conductor.tick.connect(_on_tick)

func _exit_tree() -> void:
	if Conductor.bar_started.is_connected(_on_bar_started):
		Conductor.bar_started.disconnect(_on_bar_started)
	if Conductor.tick.is_connected(_on_tick):
		Conductor.tick.disconnect(_on_tick)

func begin() -> void:
	active = true

func stop() -> void:
	_leave_phase()
	active = false
	phase = {}

func _step(pattern: Pattern, bars: int) -> Dictionary:
	return {"pattern": pattern, "bars": bars}

func _combo(first: Pattern, second: Pattern, bars: int) -> Dictionary:
	return {"pattern": first, "also": second, "bars": bars}

func _shooter(node_name: String, bars: int, per_beat: int, shots: int) -> Dictionary:
	return {"pattern": Pattern.SHOOTER, "bars": bars, "shooter": node_name, "per_beat": per_beat, "shots": shots}

func _build_program() -> void:
	match preset:
		Preset.BOSS_ONE:
			program = [
				_step(Pattern.SPIRAL_BLOOM, 4),
				_shooter("RadialShooter", 1, 4, 14),
				_step(Pattern.AIMED_FANS, 4),
				_step(Pattern.PINWHEEL_BLADES, 3),
				_shooter("FanShooter", 2, 2, 15),
				_step(Pattern.WALL_GAP, 4),
				_step(Pattern.SCISSOR_CROSS, 3),
				_step(Pattern.RING_PULSE, 3),
				_shooter("CurtainShooter", 2, 1, 7),
				_step(Pattern.CROSS_SPIRALS, 4),
				_step(Pattern.PETAL_BURST, 4),
			]
		Preset.BOSS_TWO:
			program = [
				_step(Pattern.PETAL_BURST, 4),
				_shooter("SpiralShooter", 1, 4, 14),
				_step(Pattern.CROSS_SPIRALS, 4),
				_step(Pattern.COMET_RAIN, 3),
				_shooter("FanShooter", 2, 2, 15),
				_step(Pattern.RING_PULSE, 3),
				_step(Pattern.TWIN_VORTEX, 3),
				_step(Pattern.WALL_GAP, 4),
				_shooter("RingShooter", 2, 1, 7),
				_step(Pattern.SPIRAL_BLOOM, 4),
				_step(Pattern.AIMED_FANS, 4),
			]
		Preset.MEDIUM:
			program = [_step(Pattern.RING_PULSE, 2), _step(Pattern.AIMED_FANS, 2), _step(Pattern.PINWHEEL_BLADES, 2)]
		Preset.BOSS_THREE:
			program = [
				_step(Pattern.STARBURST_LINES, 4),
				_step(Pattern.POLYGON_WAVES, 4),
				_step(Pattern.BRAID_LINES, 4),
				_step(Pattern.DIAMOND_LATTICE, 4),
				_step(Pattern.GRID_LINES, 4),
				_step(Pattern.SNAKE_LINES, 4),
				_combo(Pattern.STARBURST_LINES, Pattern.SPIRAL_BLOOM, 4),
				_step(Pattern.COMET_RAIN, 4),
				_step(Pattern.POLYGON_WAVES, 4),
				_combo(Pattern.BRAID_LINES, Pattern.GRID_LINES, 4),
				_combo(Pattern.SNAKE_LINES, Pattern.POLYGON_WAVES, 4),
				_combo(Pattern.DIAMOND_LATTICE, Pattern.TWIN_VORTEX, 4),
			]

func _can_run() -> bool:
	if not active or health.dead or not can_process():
		return false
	return not start_on_screen or entity.global_position.x <= Bullet.WORLD_WIDTH

func _density() -> float:
	var wounded := 1.0 + 0.4 * (1.0 - float(health.health) / float(health.max_health))
	return Conductor.bullet_density() * density_scale * wounded

func _on_bar_started(_bar: int) -> void:
	if not _can_run():
		return
	if phase.is_empty():
		_enter_next_phase()
		return
	phase_bars_left -= 1
	if phase_bars_left <= 0:
		_leave_phase()
		_enter_next_phase()
	else:
		_play_animation()

func _leave_phase() -> void:
	if phase.get("pattern") == Pattern.SHOOTER:
		var shooter := entity.get_node_or_null(String(phase["shooter"])) as ShooterComponent
		if shooter != null:
			shooter.stop()

func _enter_next_phase() -> void:
	phase_index = (phase_index + 1) % program.size()
	phase = program[phase_index]
	phase_bars_left = int(phase["bars"])
	counter = 0
	if phase["pattern"] == Pattern.SHOOTER:
		var shooter := entity.get_node_or_null(String(phase["shooter"])) as ShooterComponent
		if shooter != null:
			shooter.start()
			shooter.shot_interval = Conductor.beat_length() / float(phase["per_beat"])
			shooter.burst_size = int(phase["shots"])
	_play_animation()

func _play_animation() -> void:
	if animation_player == null or health.dead or phase["pattern"] == Pattern.SHOOTER:
		return
	var animation: String = DEFAULT_ANIMATIONS.get(phase["pattern"], "")
	if animation != "" and animation_player.has_animation(animation):
		animation_player.play(animation)

func _on_tick(step: int, bar: int) -> void:
	if phase.is_empty() or not _can_run():
		return
	if get_tree().get_nodes_in_group("enemy_bullets").size() > bullet_cap:
		return
	_run_pattern(phase["pattern"], step, bar)
	if phase.has("also"):
		_run_pattern(phase["also"], step, bar)
	counter += 1

func _run_pattern(pattern: int, step: int, bar: int) -> void:
	match pattern:
		Pattern.SPIRAL_BLOOM:
			_spiral_bloom(step, bar)
		Pattern.RING_PULSE:
			_ring_pulse(step, bar)
		Pattern.AIMED_FANS:
			_aimed_fans(step)
		Pattern.WALL_GAP:
			_wall_gap(step)
		Pattern.CROSS_SPIRALS:
			_cross_spirals(step)
		Pattern.PETAL_BURST:
			_petal_burst(step, bar)
		Pattern.STARBURST_LINES:
			_starburst_lines(step, bar)
		Pattern.SNAKE_LINES:
			_snake_lines()
		Pattern.BRAID_LINES:
			_braid_lines(bar)
		Pattern.GRID_LINES:
			_grid_lines(step)
		Pattern.POLYGON_WAVES:
			_polygon_waves(step, bar)
		Pattern.PINWHEEL_BLADES:
			_pinwheel_blades(step, bar)
		Pattern.COMET_RAIN:
			_comet_rain(step, bar)
		Pattern.SCISSOR_CROSS:
			_scissor_cross(step)
		Pattern.DIAMOND_LATTICE:
			_diamond_lattice(step)
		Pattern.TWIN_VORTEX:
			_twin_vortex(step, bar)

func _aim() -> Vector2:
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		return Vector2.LEFT
	return (target.global_position - entity.global_position).normalized()

func _tint(index: int) -> Color:
	return palette[index % palette.size()]

func _fire(direction: Vector2, speed: float, tint: Color, dot_scale: float = 1.0, at: Vector2 = Vector2.INF, wave_amplitude: float = 0.0, wave_frequency: float = 0.0, wave_phase: float = 0.0) -> void:
	var bullet := BULLET_SCENE.instantiate() as Bullet
	entity.get_parent().add_child(bullet)
	bullet.global_position = entity.global_position if at == Vector2.INF else at
	bullet.direction = direction
	bullet.speed = speed * speed_scale
	bullet.wave_amplitude = wave_amplitude
	bullet.wave_frequency = wave_frequency
	bullet.wave_phase = wave_phase
	(bullet.get_node("Visual") as Polygon2D).color = tint
	if dot_scale != 1.0:
		bullet.scale = Vector2.ONE * dot_scale

func _spiral_bloom(step: int, bar: int) -> void:
	var arms := clampi(roundi(4.0 * _density()), 3, 9)
	var direction := 1.0 if bar % 2 == 0 else -1.0
	var angle := float(counter) * 0.21 * direction
	for arm in arms:
		var arm_angle := angle + TAU * float(arm) / float(arms)
		_fire(Vector2.from_angle(arm_angle), 340.0, _tint(arm), 1.5 if step % 4 == 0 else 1.0)

func _ring_pulse(step: int, bar: int) -> void:
	if step % 4 != 0:
		return
	var beat_number := step >> 2
	var count := roundi(26.0 * _density())
	var offset := (TAU / float(count)) * 0.5 * float((beat_number + bar) % 2) + float(counter) * 0.01
	for i in count:
		_fire(Vector2.from_angle(offset + TAU * float(i) / float(count)), 300.0, _tint(beat_number))
	if step == 8:
		var outer := count * 2
		for i in outer:
			_fire(Vector2.from_angle(TAU * float(i) / float(outer)), 190.0, _tint(2), 1.3)

func _aimed_fans(step: int) -> void:
	var aim := _aim()
	var density := _density()
	if step == 0 or step == 8:
		var count := clampi(roundi(9.0 * density), 5, 21)
		count += 1 - count % 2
		for layer in 3:
			for k in count:
				var offset := 1.0 * (float(k) / float(count - 1) - 0.5)
				_fire(aim.rotated(offset), 420.0 - 75.0 * float(layer), _tint(layer))
	elif step == 4 or step == 12:
		var count := clampi(roundi(5.0 * density), 3, 11)
		count += 1 - count % 2
		for layer in 2:
			for k in count:
				var offset := 0.5 * (float(k) / float(count - 1) - 0.5)
				_fire(aim.rotated(offset), 470.0 - 90.0 * float(layer), _tint(layer + 1), 1.2)

func _wall_gap(step: int) -> void:
	if step % 4 != 0:
		return
	gap_phase += 0.55
	var gap_center := 720.0 + 470.0 * sin(gap_phase)
	var x := entity.global_position.x - 40.0
	var y := 40.0
	while y < 1420.0:
		if absf(y - gap_center) > 190.0:
			_fire(Vector2.LEFT, 300.0, _tint(step >> 2), 1.0, Vector2(x, y))
		y += 64.0

func _cross_spirals(step: int) -> void:
	if step % 2 != 0:
		return
	var arms := clampi(roundi(3.0 * _density()), 2, 6)
	var angle := float(counter) * 0.16
	for i in arms:
		_fire(Vector2.from_angle(angle + TAU * float(i) / float(arms)), 310.0, _tint(0))
		_fire(Vector2.from_angle(-angle + TAU * (float(i) + 0.5) / float(arms)), 270.0, _tint(1))

func _petal_burst(step: int, bar: int) -> void:
	if step != 0 and step != 8:
		return
	var petals := 5
	var base := float(bar) * 0.37 + (PI / float(petals) if step == 8 else 0.0)
	var streams := clampi(roundi(7.0 * _density()), 5, 11)
	for petal in petals:
		var heading := base + TAU * float(petal) / float(petals)
		for k in streams:
			var speed := 200.0 + 42.0 * float(k)
			for lateral in [-0.06, 0.0, 0.06]:
				_fire(Vector2.from_angle(heading + lateral), speed, _tint(petal))

func _starburst_lines(step: int, bar: int) -> void:
	var density := _density()
	if density < 0.9 and step % 2 != 0:
		return
	var spokes := clampi(roundi(9.0 * density), 6, 16)
	var base := float(bar) * (PI / float(spokes)) + 0.15 * sin(float(bar))
	for i in spokes:
		var heading := base + TAU * float(i) / float(spokes)
		_fire(Vector2.from_angle(heading), 330.0, _tint(i + (step >> 2)))

func _snake_lines() -> void:
	var lines := clampi(roundi(5.0 * _density()), 3, 8)
	var base := PI + 0.8 * sin(float(counter) * 0.05)
	for i in lines:
		var spread := (float(i) / float(lines - 1) - 0.5) * 1.7
		var amplitude := 85.0 * (1.0 if i % 2 == 0 else -1.0)
		_fire(Vector2.from_angle(base + spread), 300.0, _tint(i), 1.0, Vector2.INF, amplitude, 4.5, 0.0)

func _braid_lines(bar: int) -> void:
	var braids := clampi(roundi(3.0 * _density()), 2, 5)
	var base := float(bar) * 0.41
	for i in braids:
		var heading := Vector2.from_angle(base + TAU * float(i) / float(braids))
		for strand in 2:
			_fire(heading, 280.0, _tint(i + strand), 1.0, Vector2.INF, 110.0, 4.0, PI * float(strand))

func _grid_lines(step: int) -> void:
	if step % 4 != 0:
		return
	gap_phase += 0.7
	if step == 0 or step == 8:
		var from_top := step == 0
		var gap_x := 1300.0 + 850.0 * sin(gap_phase)
		var x := 200.0
		while x < 2540.0:
			if absf(x - gap_x) > 170.0:
				_fire(Vector2.DOWN if from_top else Vector2.UP, 300.0, _tint(step >> 3), 1.0, Vector2(x, -20.0 if from_top else 1460.0))
			x += 66.0
	else:
		var gap_y := 720.0 + 470.0 * sin(gap_phase * 1.3)
		var wall_x := entity.global_position.x - 40.0
		var y := 40.0
		while y < 1420.0:
			if absf(y - gap_y) > 190.0:
				_fire(Vector2.LEFT, 300.0, _tint(2), 1.0, Vector2(wall_x, y))
			y += 64.0

func _polygon_waves(step: int, bar: int) -> void:
	if step != 0 and step != 8:
		return
	var center := entity.global_position
	for layer in 2:
		var sides := 3 + (bar + (step >> 3) + layer) % 4
		var skip := 2 if (bar % 2 == 1 and sides >= 5) else 1
		var spin := (float(bar) * 0.29 + float(step) * 0.05) * (1.0 if layer == 0 else -1.0)
		var radius := 120.0 - 55.0 * float(layer)
		var speed := 250.0 - 80.0 * float(layer)
		var tint := _tint(bar + (step >> 3) + layer)
		for k in sides:
			var from_vertex := Vector2.from_angle(spin + TAU * float(k) / float(sides)) * radius
			var to_vertex := Vector2.from_angle(spin + TAU * float((k + skip) % sides) / float(sides)) * radius
			for j in 10:
				var offset := from_vertex.lerp(to_vertex, float(j) / 10.0)
				_fire(offset.normalized(), speed, tint, 1.0, center + offset)

func _pinwheel_blades(step: int, bar: int) -> void:
	if step % 2 != 0:
		return
	var blades := clampi(roundi(4.0 * _density()), 3, 7)
	var blade_width := 5
	var spin := float(counter) * 0.12 + float(bar) * 0.3
	for b in blades:
		var blade_angle := spin + TAU * float(b) / float(blades)
		var tint := _tint(b)
		for k in blade_width:
			var offset := (float(k) / float(blade_width - 1) - 0.5) * 0.35
			_fire(Vector2.from_angle(blade_angle + offset), 260.0 + float(k) * 20.0, tint)

func _comet_rain(step: int, bar: int) -> void:
	if step % 4 != 0:
		return
	var columns := clampi(roundi(6.0 * _density()), 4, 10)
	var phase := float(bar) * 0.6 + float(step >> 2) * 0.4
	for c in columns:
		var x := 200.0 + 2160.0 * float(c) / float(columns - 1) + 80.0 * sin(phase + float(c) * 0.9)
		_fire(Vector2.DOWN, 260.0, _tint(c), 1.0, Vector2(x, -20.0), 40.0, 3.0, float(c) * 0.5)

func _scissor_cross(step: int) -> void:
	if step % 3 != 0:
		return
	var aim := _aim()
	var sweep := sin(float(counter) * 0.15) * 0.6
	var count := clampi(roundi(6.0 * _density()), 4, 10)
	for k in count:
		var t := float(k) / float(count - 1) - 0.5
		_fire(aim.rotated(sweep + t * 0.5), 320.0, _tint(0))
		_fire(aim.rotated(-sweep - t * 0.5), 320.0, _tint(1))

func _diamond_lattice(step: int) -> void:
	if step % 4 != 0:
		return
	gap_phase += 0.6
	var gap_pos := 720.0 + 420.0 * sin(gap_phase)
	var rising := (step >> 2) % 2 == 0
	var dir := Vector2(-1.0, 1.0).normalized() if rising else Vector2(-1.0, -1.0).normalized()
	var perpendicular := Vector2(1.0, 1.0).normalized() if rising else Vector2(1.0, -1.0).normalized()
	var count := 26
	var spacing := 66.0
	var tint := _tint(1 if rising else 2)
	for i in count:
		var offset := (float(i) - float(count - 1) * 0.5) * spacing
		var pos := Vector2(1280.0, 720.0) + perpendicular * offset
		if absf(pos.y - gap_pos) > 210.0:
			_fire(dir, 280.0, tint, 1.0, pos)

func _twin_vortex(step: int, bar: int) -> void:
	if step % 2 != 0:
		return
	var arms := clampi(roundi(3.0 * _density()), 2, 5)
	var angle := float(counter) * 0.22
	var offset := 130.0
	var centers := [entity.global_position + Vector2(0.0, -offset), entity.global_position + Vector2(0.0, offset)]
	for c in 2:
		var spin_dir := 1.0 if c == 0 else -1.0
		var tint := _tint(c)
		for i in arms:
			var a := angle * spin_dir + TAU * float(i) / float(arms)
			_fire(Vector2.from_angle(a), 280.0, tint, 1.0, centers[c])
