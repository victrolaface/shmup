class_name Player
extends Area2D

const MUZZLE_FLASH_SCENE := preload("res://effects/muzzle_flash.tscn")

signal super_charge_changed(charge: int)
signal god_mode_changed(active: bool)

@export var speed: float = 700.0
@export var max_health: int = 8
@export var bullet_scene: PackedScene = preload("res://bullet/bullet_player.tscn")
@export var inhale_radius: float = 260.0
@export var swallow_distance: float = 60.0
@export var pull_speed: float = 1150.0
@export var super_max_charge: int = 3
@export var charge_per_swallow: float = 0.125
@export var super_base_radius: float = 300.0
@export var super_radius_step: float = 200.0
@export var super_damage_per_charge: int = 4
@export var super_bullet_count: int = 500
@export var super_bullets_per_tick: int = 50
@export var super_bullet_speed: float = 1450.0
@export var super_expand_duration: float = 0.7
@export var single_target_turn_rate: float = 20.0
@export var invincibility_duration: float = 1.2
@export var invincibility_blink_rate: float = 24.0
@export var bullet_row_spacing: float = 24.0

@onready var fire_cooldown: Timer = $FireCooldown
@onready var inhale_indicator: Polygon2D = $InhaleIndicator
@onready var visual: Polygon2D = $Visual

var health: int
var can_fire: bool = true
var god_mode: bool = false
var super_charge: int = 0
var super_progress: float = 0.0
var base_color: Color
var pulse_time: float = 0.0
var was_inhaling: bool = false
var nova_active: bool = false
var nova_elapsed: float = 0.0
var nova_bullets_remaining: int = 0
var nova_bullets_spawned: int = 0
var nova_damage: int = 0
var invincible_time: float = 0.0

func _ready() -> void:
	health = max_health
	add_to_group("player")
	_build_inhale_indicator()
	inhale_indicator.visible = false
	base_color = visual.color

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position += direction * speed * delta
	position.x = clamp(position.x, 50.0, 2510.0)
	position.y = clamp(position.y, 50.0, 1390.0)

	if Input.is_action_just_pressed("god_mode"):
		god_mode = not god_mode
		god_mode_changed.emit(god_mode)

	_handle_inhale(delta)
	_handle_charge_pulse(delta)
	_update_invincibility(delta)

	if nova_active:
		nova_elapsed += delta
		if nova_bullets_remaining > 0:
			_fire_nova_tick()
		else:
			nova_active = false

	if can_fire and Input.is_action_pressed("shoot") and not Input.is_action_pressed("inhale"):
		_fire()

	if super_charge > 0 and Input.is_action_just_pressed("super"):
		_unleash_super()

func _handle_charge_pulse(delta: float) -> void:
	if not Input.is_action_pressed("inhale"):
		visual.color = base_color
		pulse_time = 0.0
		return

	pulse_time += delta
	var charge_ratio := float(super_charge) / float(super_max_charge)
	var frequency := 4.0 + charge_ratio * 8.0
	var amplitude := 0.3 + charge_ratio * 0.7
	var flash := (sin(pulse_time * frequency) * 0.5 + 0.5) * amplitude
	visual.color = base_color.lerp(Color.WHITE, flash)

func _handle_inhale(delta: float) -> void:
	var inhaling := Input.is_action_pressed("inhale")
	inhale_indicator.visible = inhaling

	if not inhaling:
		if was_inhaling:
			_release_all_pulled()
		was_inhaling = false
		return
	was_inhaling = true

	for node in get_tree().get_nodes_in_group("inhalable"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var target := node as Node2D
		if target == null:
			continue

		var offset := global_position - target.global_position
		var distance := offset.length()
		if distance > inhale_radius:
			target.set("being_inhaled", false)
			continue

		if distance <= swallow_distance:
			_swallow(target)
		else:
			target.set("being_inhaled", true)
			target.global_position += offset.normalized() * pull_speed * delta

func _release_all_pulled() -> void:
	for node in get_tree().get_nodes_in_group("inhalable"):
		if is_instance_valid(node):
			node.set("being_inhaled", false)

func _swallow(target: Node2D) -> void:
	var amount := charge_per_swallow
	if "charge_amount" in target:
		amount = target.get("charge_amount")
	target.queue_free()
	grant_super_charge(amount)

func grant_super_charge(amount: float) -> void:
	super_progress = min(super_progress + amount, float(super_max_charge))
	var new_charge := int(floor(super_progress))
	if new_charge != super_charge:
		super_charge = new_charge
		super_charge_changed.emit(super_charge)

func _unleash_super() -> void:
	var level := super_charge
	super_charge = 0
	super_progress = 0.0
	super_charge_changed.emit(super_charge)

	var radius := super_base_radius + float(level - 1) * super_radius_step
	var damage := super_damage_per_charge * level
	_spawn_super_blast(radius)
	_clear_nearby(radius, damage)

	nova_damage = damage
	nova_bullets_spawned = 0
	nova_bullets_remaining = super_bullet_count
	nova_elapsed = 0.0
	nova_active = true

func _clear_nearby(radius: float, damage: int) -> void:
	var targets := get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("inhalable")
	for node in targets:
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var target := node as Node2D
		if target == null:
			continue
		if global_position.distance_to(target.global_position) > radius:
			continue
		if target.has_method("take_damage"):
			target.take_damage(damage)
		elif "charge_amount" in target:
			var amount: float = target.get("charge_amount")
			target.queue_free()
			grant_super_charge(amount)
		else:
			target.queue_free()

func _fire_nova_tick() -> void:
	var single_target := get_tree().get_nodes_in_group("enemies").size() == 1
	var count: int = min(super_bullets_per_tick, nova_bullets_remaining)

	for i in count:
		var index := nova_bullets_spawned
		var angle := (float(index) / super_bullet_count) * TAU
		var bullet := bullet_scene.instantiate() as Bullet
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.direction = Vector2.RIGHT.rotated(angle)
		bullet.speed = super_bullet_speed
		bullet.damage = nova_damage
		bullet.homing_delay = max(super_expand_duration - nova_elapsed, 0.0)
		bullet.acquire_nearest_enemy = true
		if single_target:
			bullet.turn_rate = single_target_turn_rate
		nova_bullets_spawned += 1

	nova_bullets_remaining -= count

func _spawn_super_blast(radius: float) -> void:
	var blast := Polygon2D.new()
	var points := PackedVector2Array()
	var segments := 32
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)))
	blast.polygon = points
	blast.color = Color(1, 0.9, 0.3, 0.6)
	blast.scale = Vector2.ZERO
	blast.global_position = global_position
	get_parent().add_child(blast)

	var tween := blast.create_tween()
	tween.tween_property(blast, "scale", Vector2(radius, radius), 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(blast, "modulate:a", 0.0, 0.25)
	tween.tween_callback(blast.queue_free)

func _fire() -> void:
	can_fire = false
	fire_cooldown.start()

	_spawn_muzzle_flash()

	for row_offset in [-bullet_row_spacing / 2.0, bullet_row_spacing / 2.0]:
		var bullet := bullet_scene.instantiate() as Bullet
		get_parent().add_child(bullet)
		bullet.global_position = global_position + Vector2(45, row_offset)
		bullet.direction = Vector2.RIGHT

func _spawn_muzzle_flash() -> void:
	var flash := MUZZLE_FLASH_SCENE.instantiate() as Node2D
	flash.global_position = global_position + Vector2(45, 0)
	get_parent().add_child(flash)

func take_damage(amount: int) -> void:
	if god_mode or invincible_time > 0.0:
		return
	health -= amount
	if health <= 0:
		Game.player_died()
		queue_free()
		return
	invincible_time = invincibility_duration

func _update_invincibility(delta: float) -> void:
	if invincible_time <= 0.0:
		return
	invincible_time = max(invincible_time - delta, 0.0)
	if invincible_time > 0.0:
		visual.modulate.a = 0.25 if sin(invincible_time * invincibility_blink_rate) > 0.0 else 1.0
	else:
		visual.modulate.a = 1.0

func _on_fire_cooldown_timeout() -> void:
	can_fire = true

func _build_inhale_indicator() -> void:
	var points := PackedVector2Array()
	var segments := 24
	for i in segments:
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * inhale_radius)
	inhale_indicator.polygon = points
	inhale_indicator.color = Color(0.6, 0.9, 1.0, 0.15)
