class_name Player
extends Area2D

@onready var health: HealthComponent = $HealthComponent
@onready var super_meter: SuperComponent = $SuperComponent
@onready var upgrades: UpgradeComponent = $UpgradeComponent

func _ready() -> void:
	add_to_group("player")
	health.died.connect(Game.player_died)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("god_mode"):
		health.toggle_god_mode()
