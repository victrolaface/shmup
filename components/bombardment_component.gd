class_name BombardmentComponent
extends Component

const EXPLOSION_SCENE := preload("res://effects/explosion.tscn")

@export var world_size: Vector2 = Vector2(2560, 1440)
@export var first_column_x: float = 100.0
@export var column_spacing: float = 200.0
@export var row_spacing: float = 180.0
@export var column_interval: float = 0.08
@export var blast_radius: float = 140.0
@export var damage_per_level: int = 4

var active: bool = false
var elapsed: float = 0.0
var next_column: int = 0
var column_count: int = 0
var level: int = 1
var row_ys: PackedFloat32Array = PackedFloat32Array()

func start(charge_level: int) -> void:
	level = charge_level
	elapsed = 0.0
	next_column = 0
	column_count = int(floor((world_size.x - first_column_x) / column_spacing)) + 1
	row_ys = PackedFloat32Array()
	var y := row_spacing * 0.5
	while y < world_size.y:
		row_ys.append(y)
		y += row_spacing
	active = true

func _physics_process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	while next_column < column_count and elapsed >= float(next_column) * column_interval:
		_detonate_column(next_column)
		next_column += 1
	if next_column >= column_count:
		active = false

func _detonate_column(index: int) -> void:
	var x := first_column_x + float(index) * column_spacing
	var parent := entity.get_parent()

	for y in row_ys:
		var explosion := EXPLOSION_SCENE.instantiate() as Node2D
		explosion.set("min_radius", blast_radius * 0.5)
		explosion.set("max_radius", blast_radius * 0.8)
		explosion.global_position = Vector2(x, y)
		parent.add_child(explosion)

	var damage := damage_per_level * level
	for node in get_tree().get_nodes_in_group("enemies"):
		var target := node as Node2D
		if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
			continue
		var health := HealthComponent.find(target)
		if health != null and _is_blasted(x, target.global_position):
			health.take_damage(damage)

	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var bullet := node as Node2D
		if bullet != null and is_instance_valid(bullet) and _is_blasted(x, bullet.global_position):
			bullet.queue_free()

func _is_blasted(column_x: float, point: Vector2) -> bool:
	var dx := absf(point.x - column_x)
	if dx > blast_radius:
		return false
	for y in row_ys:
		if Vector2(dx, point.y - y).length() <= blast_radius:
			return true
	return false
