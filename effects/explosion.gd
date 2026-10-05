extends Node2D

const CRUNCH_SOUNDS: Array[AudioStream] = [
	preload("res://audio/explosionCrunch_000.ogg"),
	preload("res://audio/explosionCrunch_001.ogg"),
	preload("res://audio/explosionCrunch_002.ogg"),
	preload("res://audio/explosionCrunch_003.ogg"),
	preload("res://audio/explosionCrunch_004.ogg"),
]
const MAX_CONCURRENT_SOUNDS := 8

static var active_sounds := 0

@export var min_radius: float = 40.0
@export var max_radius: float = 90.0
@export var duration: float = 0.35
@export var color: Color = Color(1, 0.6, 0.1, 1)
@export var play_sound: bool = true
@export var sound_volume_db: float = -8.0
@export var pitch_variance: float = 0.12

func _ready() -> void:
	if play_sound:
		_play_crunch()
	var radius := randf_range(min_radius, max_radius)
	var circle := Polygon2D.new()
	var points := PackedVector2Array()
	var segments := 20
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)))
	circle.polygon = points
	circle.color = color
	circle.scale = Vector2.ZERO
	add_child(circle)

	var tween := create_tween()
	tween.tween_property(circle, "scale", Vector2(radius, radius), duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(circle, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)

func _play_crunch() -> void:
	if active_sounds >= MAX_CONCURRENT_SOUNDS:
		return
	var parent := get_parent()
	if parent == null:
		return
	active_sounds += 1
	var player := AudioStreamPlayer.new()
	player.stream = CRUNCH_SOUNDS[randi() % CRUNCH_SOUNDS.size()]
	player.volume_db = sound_volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	player.finished.connect(func() -> void:
		active_sounds -= 1
		player.queue_free())
	parent.add_child(player)
	player.play()
