extends Node2D

@export var radius: float = 30.0
@export var duration: float = 0.6
@export var color: Color = Color(0.5, 0.5, 0.5, 0.6)
@export var rise_distance: float = 40.0

func _ready() -> void:
	var puff := Polygon2D.new()
	var points := PackedVector2Array()
	var segments := 16
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)))
	puff.polygon = points
	puff.color = color
	puff.scale = Vector2.ZERO
	add_child(puff)

	var tween := create_tween()
	tween.tween_property(puff, "scale", Vector2(radius, radius), duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(puff, "position:y", puff.position.y - rise_distance, duration)
	tween.parallel().tween_property(puff, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)
