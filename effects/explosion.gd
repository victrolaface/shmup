extends Node2D

@export var min_radius: float = 40.0
@export var max_radius: float = 90.0
@export var duration: float = 0.35
@export var color: Color = Color(1, 0.6, 0.1, 1)

func _ready() -> void:
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
