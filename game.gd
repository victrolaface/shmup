extends Node

signal score_changed(new_score: int)
signal currency_changed(new_currency: int)
signal game_over

var score: int = 0
var currency: int = 0

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

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
	score_changed.emit(score)
	currency_changed.emit(currency)
