class_name SfxComponent
extends Component

@export var stream: AudioStream
@export var voices: int = 6
@export var volume_db: float = -10.0
@export var pitch_variance: float = 0.08

var players: Array[AudioStreamPlayer] = []
var next_index: int = 0

func _ready() -> void:
	for i in voices:
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.volume_db = volume_db
		add_child(player)
		players.append(player)

func play() -> void:
	if players.is_empty():
		return
	var player := players[next_index]
	next_index = (next_index + 1) % players.size()
	player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	player.play()
