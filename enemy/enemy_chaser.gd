extends Area2D

const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")
const SMOKE_SCENE := preload("res://effects/smoke.tscn")
const CHARGE_PICKUP_SCENE := preload("res://pickup/charge_pickup.tscn")
const JEWEL_SCENE := preload("res://pickup/jewel.tscn")
const HIT_FLASH_DURATION := 0.15
const FLASH_COLOR := Color(1, 0.15, 0.15, 1)

@export var speed: float = 320.0
@export var turn_rate: float = 2.2
@export var health: int = 3
@export var score_value: int = 15
@export var jewel_drop_chance: float = 0.25
@export var contact_damage: int = 1

@onready var visual: Polygon2D = $Visual

var direction: Vector2 = Vector2.LEFT
var max_health: int
var base_color: Color
var flash_time: float = 0.0
var hit_flash_timer: float = 0.0
var dead: bool = false

func _ready() -> void:
	add_to_group("enemies")
	max_health = health
	base_color = visual.color
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if dead:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		var desired: Vector2 = (player.global_position - global_position).normalized()
		direction = direction.slerp(desired, turn_rate * delta).normalized()

	position += direction * speed * delta
	_update_hit_flash(delta)

	if position.x < -100.0:
		queue_free()

func _update_hit_flash(delta: float) -> void:
	flash_time += delta
	hit_flash_timer = max(hit_flash_timer - delta, 0.0)

	var danger: float = 1.0 - clamp(float(health) / float(max_health), 0.0, 1.0)
	var flash_frequency := 2.0 + danger * 12.0
	var ambient_flash := (sin(flash_time * flash_frequency) * 0.5 + 0.5) * danger
	var instant_flash := hit_flash_timer / HIT_FLASH_DURATION

	var flash: float = max(ambient_flash, instant_flash)
	visual.color = base_color.lerp(FLASH_COLOR, flash)

func _on_area_entered(area: Area2D) -> void:
	if dead or not is_instance_valid(area):
		return
	if area.is_in_group("player") and area.has_method("take_damage"):
		area.take_damage(contact_damage)
		take_damage(max_health)

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	hit_flash_timer = HIT_FLASH_DURATION
	if health <= 0:
		_die()

func _die() -> void:
	dead = true
	Game.add_score(score_value)
	_spawn_explosion()
	_spawn_smoke()
	_spawn_charge_pickup()
	if randf() < jewel_drop_chance:
		_spawn_jewel()
	queue_free()

func _spawn_explosion() -> void:
	var explosion := EXPLOSION_SCENE.instantiate() as Node2D
	explosion.global_position = global_position
	get_parent().add_child(explosion)

func _spawn_smoke() -> void:
	var smoke := SMOKE_SCENE.instantiate() as Node2D
	smoke.global_position = global_position
	get_parent().add_child(smoke)

func _spawn_charge_pickup() -> void:
	var pickup := CHARGE_PICKUP_SCENE.instantiate() as Node2D
	pickup.global_position = global_position
	get_parent().call_deferred("add_child", pickup)

func _spawn_jewel() -> void:
	var jewel := JEWEL_SCENE.instantiate() as Node2D
	jewel.global_position = global_position
	get_parent().call_deferred("add_child", jewel)
