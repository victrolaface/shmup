class_name BossAnimationComponent
extends Component

const ATTACK_ANIMATIONS := ["attack_homing_cone", "attack_horizontal_line", "attack_surround_stream"]
const SHOOTER_ANIMATIONS := {
	ShooterComponent.Mode.RADIAL: "attack_radial",
	ShooterComponent.Mode.FAN_LEFT: "attack_horizontal_line",
	ShooterComponent.Mode.CURTAIN: "attack_homing_cone",
}

var animation_player: AnimationPlayer
var dying: bool = false

func _ready() -> void:
	animation_player = Component.of(entity, "AnimationPlayer") as AnimationPlayer
	animation_player.animation_finished.connect(_on_animation_finished)

	var attacks := Component.of(entity, "BossAttackComponent") as BossAttackComponent
	if attacks != null:
		attacks.attack_started.connect(_on_attack_started)

	for child in entity.get_children():
		var shooter := child as ShooterComponent
		if shooter == null:
			continue
		var animation: String = shooter.animation_name if shooter.animation_name != "" else SHOOTER_ANIMATIONS.get(shooter.mode, "")
		if animation != "":
			shooter.burst_started.connect(_on_burst_started.bind(animation))

	var health := HealthComponent.find(entity)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

	animation_player.play("idle")

func _on_attack_started(attack: int) -> void:
	if not dying:
		animation_player.play(ATTACK_ANIMATIONS[attack])

func _on_burst_started(animation_name: String) -> void:
	if not dying:
		animation_player.play(animation_name)

func _on_damaged(_amount: int) -> void:
	if not dying and animation_player.current_animation == "idle":
		animation_player.play("hit")

func _on_died() -> void:
	dying = true
	for child in entity.get_children():
		if child is Component and child != self:
			child.process_mode = Node.PROCESS_MODE_DISABLED
	entity.set_deferred("monitorable", false)
	entity.set_deferred("monitoring", false)
	entity.remove_from_group("enemies")
	animation_player.play("death")

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"death":
		entity.queue_free()
	elif not dying:
		animation_player.play("idle")
