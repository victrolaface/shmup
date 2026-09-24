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

@export var fall_on_death: bool = false
@export var fall_distance: float = 1700.0
@export var fall_steps: int = 8
@export var fall_linger: float = 1.1
@export var fall_rise: float = 15.0
@export var fall_jitter: float = 10.0
@export var fall_shake: float = 6.0
@export var fall_step_time: float = 0.22
@export var fall_pause_time: float = 0.12
@export var fall_sway: float = 30.0

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
	if fall_on_death:
		_fall_offscreen()

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"death" and not fall_on_death:
		entity.queue_free()
	elif not dying:
		animation_player.play("idle")

var falling: bool = false

func _process(_delta: float) -> void:
	if not falling:
		return
	var visual := entity.get_node_or_null("Visual") as Node2D
	if visual != null:
		visual.position = Vector2(randf_range(-fall_shake, fall_shake), randf_range(-fall_shake, fall_shake))

func _fall_offscreen() -> void:
	falling = true
	var tween := create_tween()
	var target := entity.position
	tween.tween_interval(fall_linger)
	for i in fall_steps:
		if randf() < 0.65:
			target += Vector2(randf_range(-fall_sway, fall_sway), -fall_rise * randf_range(0.3, 1.0))
			tween.tween_property(entity, "position", target, randf_range(0.05, 0.12)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		for j in randi_range(2, 6):
			var shake := target + Vector2(randf_range(-fall_jitter, fall_jitter), randf_range(-fall_jitter, fall_jitter))
			tween.tween_property(entity, "position", shake, randf_range(0.02, 0.05))
		target += Vector2(randf_range(-fall_sway, fall_sway) * 0.4, fall_distance / float(fall_steps) * randf_range(0.3, 1.7) + fall_rise)
		tween.tween_property(entity, "position", target, randf_range(0.1, 0.26)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if randf() < 0.55:
			tween.tween_interval(randf_range(0.03, 0.3))
	tween.tween_property(entity, "position", target + Vector2(0.0, 1000.0), 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(entity.queue_free)
