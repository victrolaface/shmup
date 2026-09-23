extends Node

signal tick(step: int, bar: int)
signal beat(beat_in_bar: int, bar: int)
signal bar_started(bar: int)
signal section_changed(new_intensity: int)

const TRACKS := {
	1: {"song": "res://audio/voide - robin.mp3", "map": "res://audio/voide_robin_map.json"},
	2: {"song": "res://audio/Databend - Energetic Jungle Breakbeat Drum & Bass.mp3", "map": "res://audio/databend_map.json"},
}
const FALLBACK_BPM := 113.5
const METRONOME_BEATS := 4000
const SPAWN_SCALE := [1.9, 1.3, 0.95]
const OBSTRUCTION_SCALE := [1.6, 1.3, 1.0]
const BULLET_DENSITY := [0.55, 0.8, 1.1]

var running: bool = false
var has_song: bool = false
var muted: bool = false
var music_volume_db: float = -6.0
var visual_offset: float = 0.0
var time: float = 0.0
var loops: int = 0
var intensity: int = 1
var beats: Array[float] = []
var downbeat_phase: int = 0
var sections: Array = []
var player: AudioStreamPlayer
var current_track: int = 1

var use_audio: bool = true
var _quitting: bool = false
var _tick_cursor: int = 0
var _gate_frame: int = -1
var _gate_beat: int = 0

func _ready() -> void:
	use_audio = DisplayServer.get_name() != "headless"
	get_tree().auto_accept_quit = false
	player = AudioStreamPlayer.new()
	player.volume_db = music_volume_db
	add_child(player)
	_load_song(current_track)
	if not has_song:
		_build_metronome()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func quit_game() -> void:
	if _quitting:
		return
	_quitting = true
	running = false
	player.stop()
	await get_tree().create_timer(0.25, true, false, true).timeout
	player.stream = null
	get_tree().quit()

func use_track(stage: int) -> void:
	if not TRACKS.has(stage) or stage == current_track:
		return
	current_track = stage
	has_song = false
	beats.clear()
	downbeat_phase = 0
	sections = []
	_load_song(stage)
	if not has_song:
		_build_metronome()

func _load_song(stage: int) -> void:
	var paths: Dictionary = TRACKS.get(stage, {})
	var song_path: String = paths.get("song", "")
	var map_path: String = paths.get("map", "")
	if song_path == "" or not ResourceLoader.exists(song_path) or not ResourceLoader.exists(map_path):
		return
	var stream := load(song_path) as AudioStreamMP3
	var map_resource := load(map_path) as JSON
	if stream == null or map_resource == null:
		return
	var map: Dictionary = map_resource.data
	for value in map["beats"]:
		beats.append(float(value))
	downbeat_phase = int(map["downbeat_phase"])
	sections = map["sections"]
	stream.loop = true
	player.stream = stream
	has_song = true

func _build_metronome() -> void:
	beats.clear()
	downbeat_phase = 0
	sections = []
	for i in METRONOME_BEATS:
		beats.append(float(i) * 60.0 / FALLBACK_BPM)

func start_song() -> void:
	time = 0.0
	loops = 0
	_tick_cursor = 0
	intensity = 1
	if has_song and use_audio:
		player.stop()
		player.play(0.0)
	running = true

func stop_song() -> void:
	running = false
	player.stop()

func seek(seconds: float) -> void:
	if has_song and use_audio:
		player.seek(seconds)
	time = seconds
	_tick_cursor = 0
	while _tick_time(_tick_cursor) < seconds:
		_tick_cursor += 1
	_update_intensity()

func beat_length() -> float:
	var index := clampi(_tick_cursor >> 2, 0, beats.size() - 2)
	return beats[index + 1] - beats[index]

func gate(every_beats: int) -> bool:
	if not running:
		return true
	if _gate_frame != Engine.get_physics_frames():
		return false
	return every_beats <= 1 or posmod(_gate_beat, every_beats) == 0

func spawn_scale() -> float:
	return SPAWN_SCALE[intensity] if running else 1.0

func obstruction_scale() -> float:
	return OBSTRUCTION_SCALE[intensity] if running else 1.0

func bullet_density() -> float:
	return BULLET_DENSITY[intensity] if running else 1.0

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_M:
		muted = not muted
		player.volume_db = -80.0 if muted else music_volume_db

func _physics_process(delta: float) -> void:
	if not running:
		return
	if has_song and use_audio:
		var position := player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() + visual_offset
		if position < time - 1.0:
			loops += 1
			_tick_cursor = 0
			time = position
		time = maxf(time, position)
	else:
		time += delta
		if has_song and time >= beats[beats.size() - 1] + 1.0:
			loops += 1
			_tick_cursor = 0
			time = 0.0

	while true:
		var tick_at := _tick_time(_tick_cursor)
		if tick_at > time:
			break
		if tick_at >= time - 0.5:
			_emit_tick(_tick_cursor)
		_tick_cursor += 1
	_update_intensity()

func _tick_time(index: int) -> float:
	var beat_index := index >> 2
	if beat_index + 1 >= beats.size():
		return INF
	return lerpf(beats[beat_index], beats[beat_index + 1], float(index & 3) / 4.0)

func _emit_tick(index: int) -> void:
	var beat_index := index >> 2
	var sub := index & 3
	var relative := beat_index - downbeat_phase
	var beat_in_bar := posmod(relative, 4)
	var bar := maxi(floori(float(relative) / 4.0), 0)
	var step := beat_in_bar * 4 + sub
	if sub == 0:
		_gate_frame = Engine.get_physics_frames()
		_gate_beat = relative
	if step == 0:
		bar_started.emit(bar)
	if sub == 0:
		beat.emit(beat_in_bar, bar)
	tick.emit(step, bar)

func _update_intensity() -> void:
	var level := 1
	for section in sections:
		if time >= float(section["start"]) and time < float(section["end"]):
			level = ["quiet", "medium", "intense"].find(section["intensity"])
			break
	if level != intensity:
		intensity = level
		section_changed.emit(level)
