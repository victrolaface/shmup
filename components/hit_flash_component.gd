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

@export var flash_color: Color = Color(1, 0.15, 0.15, 1)
@export var duration: float = 0.15
@export var stage_1_opacity: float = 0.2
@export var stage_2_opacity: float = 0.4
@export var stage_3_opacity: float = 0.55

var health: HealthComponent
var flash_material: ShaderMaterial
var overlay_count: int = 0
var tinted: Array[Polygon2D] = []
var tinted_base_colors: Array[Color] = []
var flash_time: float = 0.0
var hit_timer: float = 0.0

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

	var visual := Component.of(entity, "Visual") as Polygon2D
	if visual != null:
		# A Visual polygon carrying sprite pieces: flash each sprite. Without
		# sprites, the polygon itself is tinted.
		for child in visual.get_children():
			if child is Sprite2D:
				_add_sprite_overlay(child as Sprite2D)
		if overlay_count == 0:
			_track_tint(visual)
	else:
		# A rig of polygons somewhere under the entity: textured pieces get a
		# silhouette overlay, untextured ones are tinted directly.
		var pieces: Array[Polygon2D] = []
		_collect_polygons(entity, pieces)
		for piece in pieces:
			if piece.texture != null:
				_add_polygon_overlay(piece)
			else:
				_track_tint(piece)
	health.damaged.connect(func(_amount: int) -> void: hit_timer = duration)

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
	flash_time += delta
	hit_timer = max(hit_timer - delta, 0.0)

	var danger: float = 1.0 - clamp(float(health.health) / float(health.max_health), 0.0, 1.0)
	var flash_frequency := 2.0 + danger * 12.0
	var ambient_flash := (sin(flash_time * flash_frequency) * 0.5 + 0.5) * danger
	var instant_flash := hit_timer / duration

	var peak_opacity: float
	if danger >= 2.0 / 3.0:
		peak_opacity = stage_3_opacity
	elif danger >= 1.0 / 3.0:
		peak_opacity = stage_2_opacity
	else:
		peak_opacity = stage_1_opacity
	var flash: float = max(ambient_flash, instant_flash) * peak_opacity
	if overlay_count > 0:
		flash_material.set_shader_parameter("flash_amount", flash)
	for i in tinted.size():
		tinted[i].color = tinted_base_colors[i].lerp(flash_color, flash)
