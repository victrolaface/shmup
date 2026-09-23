class_name BossMorphComponent
extends Component

const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")

@export var vertex_range: Vector2i = Vector2i(7, 13)
@export var radius_range: Vector2 = Vector2(230.0, 300.0)
@export var spike_chance: float = 0.5
@export var approach_speed_range: Vector2 = Vector2(190.0, 340.0)
@export var hover_amplitude_range: Vector2 = Vector2(280.0, 470.0)
@export var hover_frequency_range: Vector2 = Vector2(0.5, 1.15)
@export var bullet_speed_range: Vector2 = Vector2(0.85, 1.3)
@export var spin_range: Vector2 = Vector2(0.1, 0.5)
@export var death_explosions: int = 14
@export var hurt_box_scale: float = 0.55

var visual: Polygon2D
var spin: float = 0.0
var hue: float = 0.0

func _ready() -> void:
	visual = Component.of(entity, "Visual") as Polygon2D
	_randomize_shape()
	_randomize_movement()
	_randomize_bullets()
	_build_animations()
	HealthComponent.find(entity).died.connect(_on_died)

func _process(delta: float) -> void:
	visual.rotation += spin * delta

func _randomize_shape() -> void:
	var count := randi_range(vertex_range.x, vertex_range.y)
	var radius := randf_range(radius_range.x, radius_range.y)
	var spiky := randf() < spike_chance
	var start_angle := randf() * TAU
	var points := PackedVector2Array()
	var core_points := PackedVector2Array()
	var farthest := 0.0
	for i in count:
		var angle := start_angle + TAU * float(i) / float(count) + randf_range(-0.12, 0.12)
		var distance := radius * randf_range(0.7, 1.05)
		if spiky and i % 2 == 0:
			distance *= randf_range(1.25, 1.5)
		farthest = maxf(farthest, distance)
		points.append(Vector2.from_angle(angle) * distance)
		core_points.append(Vector2.from_angle(angle) * distance * 0.5)

	hue = randf()
	visual.polygon = points
	visual.color = Color.from_hsv(hue, 0.75, 0.6)
	var core := Polygon2D.new()
	core.polygon = core_points
	core.color = Color.from_hsv(fposmod(hue + 0.05, 1.0), 0.55, 0.95)
	visual.add_child(core)

	var hitbox := Component.of(entity, "CollisionShape2D") as CollisionShape2D
	var circle := CircleShape2D.new()
	circle.radius = farthest * 0.85
	hitbox.shape = circle

	var hurt_box := entity.get_node("HurtBox/CollisionShape2D") as CollisionShape2D
	var hurt_circle := CircleShape2D.new()
	hurt_circle.radius = circle.radius * hurt_box_scale
	hurt_box.shape = hurt_circle

	spin = randf_range(spin_range.x, spin_range.y) * (1.0 if randf() < 0.5 else -1.0)

func _randomize_movement() -> void:
	var approach := Component.of(entity, "ApproachStopComponent") as ApproachStopComponent
	if approach == null:
		return
	approach.approach_speed = randf_range(approach_speed_range.x, approach_speed_range.y)
	approach.hover_amplitude = randf_range(hover_amplitude_range.x, hover_amplitude_range.y)
	approach.hover_frequency = randf_range(hover_frequency_range.x, hover_frequency_range.y)

func _randomize_bullets() -> void:
	var danmaku := Component.of(entity, "DanmakuComponent") as DanmakuComponent
	if danmaku == null:
		return
	danmaku.speed_scale = randf_range(bullet_speed_range.x, bullet_speed_range.y)
	var bullet_hue := randf_range(0.78, 0.95)
	danmaku.palette = PackedColorArray([
		Color.from_hsv(bullet_hue, 0.95, 1.0),
		Color.from_hsv(fposmod(bullet_hue + 0.04, 1.0), 0.9, 1.0),
		Color.from_hsv(fposmod(bullet_hue - 0.04, 1.0), 0.92, 1.0),
	])

func _build_animations() -> void:
	var player := Component.of(entity, "AnimationPlayer") as AnimationPlayer
	var library := AnimationLibrary.new()
	library.add_animation("idle", _pulse_animation(2.0, 1.03, true))
	library.add_animation("hit", _pulse_animation(0.15, 1.05, false))
	library.add_animation("attack_radial", _pulse_animation(0.6, 1.15, false))
	library.add_animation("attack_surround_stream", _pulse_animation(0.6, 1.08, false))
	library.add_animation("attack_homing_cone", _pulse_animation(0.6, 1.1, false))
	library.add_animation("attack_horizontal_line", _pulse_animation(0.6, 1.1, false))
	library.add_animation("death", _death_animation())
	player.add_animation_library("", library)

func _pulse_animation(length: float, peak: float, looping: bool) -> Animation:
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath("Visual:scale"))
	animation.track_insert_key(track, 0.0, Vector2.ONE)
	animation.track_insert_key(track, length * (0.5 if looping else 0.25), Vector2.ONE * peak)
	animation.track_insert_key(track, length, Vector2.ONE)
	return animation

func _death_animation() -> Animation:
	var animation := Animation.new()
	animation.length = 1.5
	var scale_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, NodePath("Visual:scale"))
	animation.track_insert_key(scale_track, 0.0, Vector2.ONE)
	animation.track_insert_key(scale_track, 0.4, Vector2.ONE * 1.25)
	animation.track_insert_key(scale_track, 1.5, Vector2.ZERO)
	var fade_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(fade_track, NodePath("Visual:modulate"))
	animation.track_insert_key(fade_track, 0.0, Color.WHITE)
	animation.track_insert_key(fade_track, 0.6, Color.WHITE)
	animation.track_insert_key(fade_track, 1.5, Color(1, 1, 1, 0))
	return animation

func _on_died() -> void:
	var parent := entity.get_parent()
	var center := entity.global_position
	for i in death_explosions:
		get_tree().create_timer(0.09 * float(i)).timeout.connect(func() -> void:
			if not is_instance_valid(parent):
				return
			var explosion := EXPLOSION_SCENE.instantiate() as Node2D
			explosion.set("min_radius", 80.0)
			explosion.set("max_radius", 200.0)
			explosion.global_position = center + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 260.0)
			parent.add_child(explosion)
		)
