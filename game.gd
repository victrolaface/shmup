extends Node

signal score_changed(new_score: int)
signal currency_changed(new_currency: int)
signal combo_changed(combo: int, multiplier: float)
signal rank_changed(rank: float)
signal game_over

const COMBO_WINDOW := 12.0
const COMBO_MULTIPLIER_STEP := 0.1
const COMBO_MAX_STEPS := 20

## --- Rank (dynamic difficulty) ---
## The higher the combo climbs, the harder the game leans in; the lower it
## drops (or drops out entirely), the more it eases off. `rank` is a smoothed
## 0..1 value driven by `combo` so difficulty ramps/eases gradually instead
## of snapping every time the combo changes.
const RANK_MAX_COMBO := 40.0
const RANK_EASE_SPEED := 0.22
const RANK_SPAWN_INTERVAL_RANGE := Vector2(1.25, 0.82)
const RANK_DENSITY_RANGE := Vector2(0.8, 1.15)
const RANK_BULLET_SPEED_RANGE := Vector2(0.85, 1.08)

var score: int = 0
var currency: int = 0
var combo: int = 0
var combo_timer: float = 0.0
var rank: float = 0.0
var rank_target: float = 0.0

func _process(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			reset_combo()
	if not is_equal_approx(rank, rank_target):
		rank = move_toward(rank, rank_target, RANK_EASE_SPEED * delta)
		rank_changed.emit(rank)

## Enemies should spawn more often (smaller interval) the higher the rank.
func rank_spawn_interval_scale() -> float:
	return lerpf(RANK_SPAWN_INTERVAL_RANGE.x, RANK_SPAWN_INTERVAL_RANGE.y, rank)

## Bullet patterns should get denser (more spokes/streams) the higher the rank.
func rank_density_scale() -> float:
	return lerpf(RANK_DENSITY_RANGE.x, RANK_DENSITY_RANGE.y, rank)

## Enemy bullets should fly faster the higher the rank.
func rank_bullet_speed_scale() -> float:
	return lerpf(RANK_BULLET_SPEED_RANGE.x, RANK_BULLET_SPEED_RANGE.y, rank)

func _update_rank_target() -> void:
	rank_target = clampf(float(combo) / RANK_MAX_COMBO, 0.0, 1.0)

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func register_kill(base_score: int) -> void:
	combo += 1
	combo_timer = COMBO_WINDOW
	var multiplier := combo_multiplier()
	add_score(roundi(float(base_score) * multiplier))
	combo_changed.emit(combo, multiplier)
	_update_rank_target()

func combo_multiplier() -> float:
	return 1.0 + float(mini(combo - 1, COMBO_MAX_STEPS)) * COMBO_MULTIPLIER_STEP

func reset_combo() -> void:
	combo_timer = 0.0
	if combo == 0:
		return
	combo = 0
	combo_changed.emit(0, 1.0)
	_update_rank_target()

func spend_currency(amount: int) -> bool:
	if currency < amount:
		return false
	currency -= amount
	currency_changed.emit(currency)
	return true

func add_currency(amount: int) -> void:
	currency += amount
	currency_changed.emit(currency)

func player_died() -> void:
	game_over.emit()

func reset() -> void:
	score = 0
	currency = 0
	combo = 0
	combo_timer = 0.0
	rank = 0.0
	rank_target = 0.0
	score_changed.emit(score)
	currency_changed.emit(currency)
	combo_changed.emit(0, 1.0)
	rank_changed.emit(rank)
