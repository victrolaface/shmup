class_name PlayerAnimationComponent
extends Component

var animation_player: AnimationPlayer
var health: HealthComponent
var dying: bool = false

func _ready() -> void:
	animation_player = Component.of(entity, "AnimationPlayer") as AnimationPlayer
	health = HealthComponent.find(entity)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("idle")

func _on_damaged(_amount: int) -> void:
	if dying:
		return
	animation_player.play("hit")

func _on_died() -> void:
	dying = true
	animation_player.process_mode = Node.PROCESS_MODE_ALWAYS
	animation_player.play("death")

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"death":
		entity.queue_free()
	elif anim_name == &"hit" and not dying:
		animation_player.play("idle")
