class_name HitFlashComponent
extends Component

const FLASH_SHADER_CODE := """
shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	COLOR = vec4(flash_color.rgb, tex_color.a * flash_amount);
}
"""

static var shared_shader: Shader

## Hits flash this colour; once health is down to `critical_fraction` of its maximum
## they flash `flash_color` (red) instead. Nothing else glows.
@export var hit_color: Color = Color(1, 1, 1, 1)
@export var hit_opacity: float = 0.75
@export_range(0.0, 1.0) var critical_fraction: float = 0.15
## The hit flash plays on every Nth hit taken (4 = every fourth hit), starting with the first,
## so a stream of bullets doesn't strobe the enemy.
@export var flash_every_nth_hit: int = 4
@export var flash_color: Color = Color(1, 0.15, 0.15, 1)
@export var duration: float = 0.15

var health: HealthComponent
var flash_material: ShaderMaterial
var overlay_count: int = 0
var tinted: Array[Polygon2D] = []
var tinted_base_colors: Array[Color] = []
var hit_timer: float = 0.0
var hits_taken: int = 0

static func _get_shader() -> Shader:
	if shared_shader == null:
		shared_shader = Shader.new()
		shared_shader.code = FLASH_SHADER_CODE
	return shared_shader

func _ready() -> void:
	health = HealthComponent.find(entity)
	flash_material = ShaderMaterial.new()
	flash_material.shader = _get_shader()
	flash_material.set_shader_parameter("flash_color", flash_color)
	flash_material.set_shader_parameter("flash_amount", 0.0)

	# Sprite pieces carried by a Visual polygon each get a silhouette overlay.
	var visual := Component.of(entity, "Visual") as Polygon2D
	if visual != null:
		for child in visual.get_children():
			if child is Sprite2D:
				_add_sprite_overlay(child as Sprite2D)
	# A rig of polygons anywhere else under the entity (alongside or instead of a
	# Visual): textured pieces get an overlay, untextured ones are tinted.
	var pieces: Array[Polygon2D] = []
	_collect_polygons(entity, pieces)
	for piece in pieces:
		if piece == visual:
			continue
		if piece.texture != null:
			_add_polygon_overlay(piece)
		else:
			_track_tint(piece)
	# A plain Visual polygon with nothing else to flash is tinted itself.
	if visual != null and overlay_count == 0 and tinted.is_empty():
		_track_tint(visual)
	health.damaged.connect(_on_damaged)

func _on_damaged(_amount: int) -> void:
	if hits_taken % maxi(flash_every_nth_hit, 1) == 0:
		hit_timer = duration
	hits_taken += 1

func _collect_polygons(node: Node, into: Array[Polygon2D]) -> void:
	for child in node.get_children():
		if child is Polygon2D:
			into.append(child as Polygon2D)
		_collect_polygons(child, into)

func _track_tint(polygon: Polygon2D) -> void:
	tinted.append(polygon)
	tinted_base_colors.append(polygon.color)

# Overlays are drawn at z 100 so they sit above every piece of the rig no
# matter how the pieces are layered among themselves.
func _prepare_overlay(overlay: CanvasItem) -> void:
	overlay.material = flash_material
	overlay.z_as_relative = false
	overlay.z_index = 100
	overlay.modulate = Color.WHITE
	overlay.self_modulate = Color.WHITE
	overlay_count += 1

func _add_sprite_overlay(sprite: Sprite2D) -> void:
	var overlay := Sprite2D.new()
	overlay.texture = sprite.texture
	overlay.centered = sprite.centered
	_prepare_overlay(overlay)
	sprite.add_child(overlay)

func _add_polygon_overlay(piece: Polygon2D) -> void:
	var overlay := piece.duplicate() as Polygon2D
	overlay.position = Vector2.ZERO
	overlay.rotation = 0.0
	overlay.scale = Vector2.ONE
	overlay.skew = 0.0
	# The copy hangs one level deeper than the piece, so a relative skeleton
	# path has to step up once more for the overlay to follow the same bones.
	if not piece.skeleton.is_empty():
		overlay.skeleton = NodePath("../" + String(piece.skeleton))
	overlay.color = Color.WHITE
	_prepare_overlay(overlay)
	piece.add_child(overlay)

func _physics_process(delta: float) -> void:
	hit_timer = max(hit_timer - delta, 0.0)

	var critical := float(health.health) <= float(health.max_health) * critical_fraction
	var color := flash_color if critical else hit_color
	var flash: float = hit_timer / duration * hit_opacity
	if overlay_count > 0:
		flash_material.set_shader_parameter("flash_color", color)
		flash_material.set_shader_parameter("flash_amount", flash)
	for i in tinted.size():
		tinted[i].color = tinted_base_colors[i].lerp(color, flash)
