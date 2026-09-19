class_name HitFlashComponent
extends Component

var visual: Polygon2D
@export var flash_color: Color = Color(1, 0.15, 0.15, 1)
@export var duration: float = 0.15

var health: HealthComponent
var base_color: Color
var flash_time: float = 0.0
var hit_timer: float = 0.0

func _ready() -> void:
	visual = Component.of(entity, "Visual") as Polygon2D
	health = HealthComponent.find(entity)
	base_color = visual.color
	health.damaged.connect(func(_amount: int) -> void: hit_timer = duration)

func _physics_process(delta: float) -> void:
	flash_time += delta
	hit_timer = max(hit_timer - delta, 0.0)

	var danger: float = 1.0 - clamp(float(health.health) / float(health.max_health), 0.0, 1.0)
	var flash_frequency := 2.0 + danger * 12.0
	var ambient_flash := (sin(flash_time * flash_frequency) * 0.5 + 0.5) * danger
	var instant_flash := hit_timer / duration

	var flash: float = max(ambient_flash, instant_flash)
	visual.color = base_color.lerp(flash_color, flash)
