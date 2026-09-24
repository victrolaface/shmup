extends Node2D

@export var radius: float = 22.0
@export var duration: float = 0.1
@export var color: Color = Color(1, 1, 1, 0.9)

func _ready() -> void:
	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	var segments := 12
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	flash.polygon = points
	flash.color = color
	add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)
