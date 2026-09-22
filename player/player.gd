class_name Player
extends Area2D

@onready var health: HealthComponent = $HealthComponent
@onready var super_meter: SuperComponent = $SuperComponent
@onready var upgrades: UpgradeComponent = $UpgradeComponent

func _ready() -> void:
	add_to_group("player")
	health.died.connect(Game.player_died)
	health.damaged.connect(_on_damaged)

func _on_damaged(_amount: int) -> void:
	Game.reset_combo()
