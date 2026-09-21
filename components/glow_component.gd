class_name GlowComponent
extends Component

const TEXTURE_SIZE := 128

static var shared_texture: GradientTexture2D

@export var color: Color = Color(1.0, 0.8, 0.2, 1.0)
@export var radius: float = 46.0
@export var intensity: float = 0.55
@export var core_intensity: float = 0.2
@export var pulse_speed: float = 3.2
@export var pulse_amount: float = 0.2

var halo: Sprite2D
var core: Sprite2D
var time: float = 0.0

func _ready() -> void:
	time = randf() * TAU
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo = _make_layer(additive, radius, intensity)
	core = _make_layer(additive, radius * 0.4, core_intensity)
	_attach.call_deferred()

func _exit_tree() -> void:
	for layer in [halo, core]:
		if layer != null and is_instance_valid(layer) and layer.get_parent() == null:
			layer.free()

func _attach() -> void:
	if not is_instance_valid(entity):
		return
	entity.add_child(halo)
	entity.add_child(core)
	entity.move_child(halo, 0)
	entity.move_child(core, 1)

func _process(delta: float) -> void:
	if halo == null or not halo.is_inside_tree():
		return
	time += delta * pulse_speed
	var pulse := 1.0 + pulse_amount * sin(time)
	halo.scale = Vector2.ONE * radius * 2.0 / float(TEXTURE_SIZE) * pulse
	core.scale = Vector2.ONE * radius * 0.9 / float(TEXTURE_SIZE) * (2.0 - pulse)
	halo.modulate.a = intensity * (0.85 + 0.15 * sin(time))

func _make_layer(material: Material, layer_radius: float, layer_intensity: float) -> Sprite2D:
	var layer := Sprite2D.new()
	layer.texture = _radial_texture()
	layer.material = material
	layer.modulate = Color(color.r, color.g, color.b, layer_intensity)
	layer.scale = Vector2.ONE * layer_radius * 2.0 / float(TEXTURE_SIZE)
	return layer

static func _radial_texture() -> GradientTexture2D:
	if shared_texture != null:
		return shared_texture
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	shared_texture = GradientTexture2D.new()
	shared_texture.gradient = gradient
	shared_texture.fill = GradientTexture2D.FILL_RADIAL
	shared_texture.fill_from = Vector2(0.5, 0.5)
	shared_texture.fill_to = Vector2(1.0, 0.5)
	shared_texture.width = TEXTURE_SIZE
	shared_texture.height = TEXTURE_SIZE
	return shared_texture
