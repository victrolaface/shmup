class_name ScrollingLayer
extends Node2D

@export var scroll_speed: float = 60.0
@export var tile_width: float = 2560.0

func _process(delta: float) -> void:
	position.x -= scroll_speed * delta
	if position.x <= -tile_width:
		position.x += tile_width
