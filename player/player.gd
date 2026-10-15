class_name Player
extends Area2D

@onready var health: HealthComponent = $HealthComponent
@onready var super_meter: SuperComponent = $SuperComponent
@onready var upgrades: UpgradeComponent = $UpgradeComponent

func _ready() -> void:
	add_to_group("player")
	health.died.connect(Game.player_died)
	health.damaged.connect(_on_damaged)

## Used while the shopkeeper has the player: no flying, shooting or bombing, and no damage.
const CONTROL_COMPONENTS := ["PlayerMoveComponent", "WeaponComponent", "BombComponent", "SuperComponent", "InhaleComponent"]

func set_controls_enabled(enabled: bool) -> void:
	for component_name in CONTROL_COMPONENTS:
		var component := get_node_or_null(component_name)
		if component != null:
			component.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	health.invulnerable = not enabled

func _on_damaged(_amount: int) -> void:
	Game.reset_combo()
