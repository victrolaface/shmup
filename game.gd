extends Node

signal score_changed(new_score: int)
signal currency_changed(new_currency: int)
signal combo_changed(combo: int, multiplier: float)
signal game_over

const COMBO_WINDOW := 12.0
const COMBO_MULTIPLIER_STEP := 0.1
const COMBO_MAX_STEPS := 20

var score: int = 0
var currency: int = 0
var combo: int = 0
var combo_timer: float = 0.0

func _process(delta: float) -> void:
	if combo_timer <= 0.0:
		return
	combo_timer -= delta
	if combo_timer <= 0.0:
		reset_combo()

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func register_kill(base_score: int) -> void:
	combo += 1
	combo_timer = COMBO_WINDOW
	var multiplier := combo_multiplier()
	add_score(roundi(float(base_score) * multiplier))
	combo_changed.emit(combo, multiplier)

func combo_multiplier() -> float:
	return 1.0 + float(mini(combo - 1, COMBO_MAX_STEPS)) * COMBO_MULTIPLIER_STEP

func reset_combo() -> void:
	combo_timer = 0.0
	if combo == 0:
		return
	combo = 0
	combo_changed.emit(0, 1.0)

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
	score_changed.emit(score)
	currency_changed.emit(currency)
	combo_changed.emit(0, 1.0)
