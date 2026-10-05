class_name BloodHose
extends Node2D

## A high-pressure jet of blood, samurai-movie style: a sustained, pulsing
## spray in one direction that arcs under gravity, whips slightly as it goes
## and tails off as the pressure drops. Drops are ordinary `Blood` droplets
## emitted fast enough that their streaks run together into one stream.

const MAX_HOSES := 8

static var active_hoses: int = 0

var direction: Vector2 = Vector2.UP
var speed: float = 1400.0
var duration: float = 1.6
var rate: float = 150.0
var spread_degrees: float = 3.0
var sweep_degrees: float = 8.0
var sweep_rate: float = 1.6
var pulse_rate: float = 4.5
var radius_range: Vector2 = Vector2(7.0, 13.0)
var follow: Node2D
var follow_offset: Vector2 = Vector2.ZERO

var age: float = 0.0
var emit_budget: float = 0.0
var sweep_phase: float = 0.0

## Starts a jet at `at`. If `follow` is given the jet stays attached to it
## (e.g. a boss that is falling away) until it is freed. Returns null when too
## many jets are already running.
static func spray(parent: Node, at: Vector2, aim: Vector2, jet_speed: float, jet_duration: float, jet_rate: float = 150.0, attach_to: Node2D = null) -> BloodHose:
	if active_hoses >= MAX_HOSES:
		return null
	var hose := BloodHose.new()
	hose.direction = aim.normalized()
	hose.speed = jet_speed
	hose.duration = jet_duration
	hose.rate = jet_rate
	hose.sweep_phase = randf() * TAU
	parent.add_child(hose)
	hose.global_position = at
	if attach_to != null:
		hose.follow = attach_to
		hose.follow_offset = at - attach_to.global_position
	return hose

func _enter_tree() -> void:
	active_hoses += 1

func _exit_tree() -> void:
	active_hoses -= 1

func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		queue_free()
		return
	if follow != null:
		if is_instance_valid(follow):
			global_position = follow.global_position + follow_offset
		else:
			follow = null

	# Pressure holds, then drains away; the heartbeat pulse makes it pump.
	var t := age / duration
	var pressure := 1.0 - t * t
	var pulse := 0.65 + 0.35 * sin(age * pulse_rate * TAU)
	var jet_speed := speed * lerpf(0.65, 1.0, pressure) * (0.93 + 0.07 * pulse)
	var aim := direction.rotated(deg_to_rad(sweep_degrees) * sin(age * sweep_rate + sweep_phase))

	emit_budget += rate * (0.35 + 0.65 * pressure) * pulse * delta
	var parent := get_parent()
	while emit_budget >= 1.0:
		emit_budget -= 1.0
		# Emit as if some moment of this frame ago, so each frame's drops are
		# spread along the jet instead of bunching at the nozzle.
		var ago := randf() * delta
		var drop_velocity := aim.rotated(deg_to_rad(randf_range(-spread_degrees, spread_degrees))) * jet_speed * randf_range(0.93, 1.07)
		var start := global_position + drop_velocity * ago + Vector2(0.0, 0.5 * Blood.GRAVITY * ago * ago)
		drop_velocity.y += Blood.GRAVITY * ago
		if not Blood.spawn_drop(parent, start, drop_velocity, randf_range(radius_range.x, radius_range.y)):
			emit_budget = 0.0
			break
