extends Node

signal score_changed(new_score: int)
signal game_over

var score: int = 0

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func player_died() -> void:
	game_over.emit()

func reset() -> void:
	score = 0
	score_changed.emit(score)
