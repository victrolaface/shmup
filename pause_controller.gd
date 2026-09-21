extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_parent()._on_pause_input()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("god_mode"):
		get_parent()._on_god_mode_button_pressed()
