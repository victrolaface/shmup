class_name InhaleComponent
extends Component

var indicator: Polygon2D
var visual: Polygon2D
@export var inhale_radius: float = 260.0
@export var swallow_distance: float = 60.0
@export var pull_speed: float = 1150.0
@export var charge_per_swallow: float = 0.125

var super_meter: SuperComponent
var base_color: Color
var pulse_time: float = 0.0
var was_inhaling: bool = false

func _ready() -> void:
	indicator = Component.of(entity, "InhaleIndicator") as Polygon2D
	visual = Component.of(entity, "Visual") as Polygon2D
	super_meter = Component.of(entity, "SuperComponent") as SuperComponent
	base_color = visual.color
	_build_indicator()
	indicator.visible = false

func _physics_process(delta: float) -> void:
	var inhaling := Input.is_action_pressed("inhale")
	indicator.visible = inhaling
	_update_pulse(inhaling, delta)

	if not inhaling:
		if was_inhaling:
			_release_all()
		was_inhaling = false
		return
	was_inhaling = true

	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var target := node as Bullet
		if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
			continue

		var offset := entity.global_position - target.global_position
		var distance := offset.length()
		if distance > inhale_radius:
			target.being_inhaled = false
		elif distance <= swallow_distance:
			target.queue_free()
			super_meter.grant_charge(charge_per_swallow)
		else:
			target.being_inhaled = true
			target.global_position += offset.normalized() * pull_speed * delta

func _release_all() -> void:
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var target := node as Bullet
		if target != null and is_instance_valid(target):
			target.being_inhaled = false

func _update_pulse(inhaling: bool, delta: float) -> void:
	if not inhaling:
		visual.color = base_color
		pulse_time = 0.0
		return

	pulse_time += delta
	var charge_ratio := float(super_meter.charge) / float(super_meter.max_charge)
	var frequency := 4.0 + charge_ratio * 8.0
	var amplitude := 0.3 + charge_ratio * 0.7
	var flash := (sin(pulse_time * frequency) * 0.5 + 0.5) * amplitude
	visual.color = base_color.lerp(Color.WHITE, flash)

func _build_indicator() -> void:
	var points := PackedVector2Array()
	var segments := 24
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * inhale_radius)
	indicator.polygon = points
	indicator.color = Color(0.6, 0.9, 1.0, 0.15)
