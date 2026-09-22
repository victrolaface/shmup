class_name UpgradeComponent
extends Component

const MAX_SHOT_ROWS := 5
const MAX_DIAGONAL_LEVEL := 3
const MAX_BOMB_LEVEL := 3
const UPGRADE_NAMES := {"row": "EXTRA ROW OF SHOT", "diagonal": "DIAGONAL SHOT", "bomb": "CARPET BOMBS"}

var weapon: WeaponComponent
var bombs: BombComponent

func _ready() -> void:
	weapon = Component.of(entity, "WeaponComponent") as WeaponComponent
	bombs = Component.of(entity, "BombComponent") as BombComponent

func can_upgrade(id: String) -> bool:
	match id:
		"row":
			return weapon.shot_rows < MAX_SHOT_ROWS
		"diagonal":
			return weapon.diagonal_level < MAX_DIAGONAL_LEVEL
		"bomb":
			return bombs.bomb_level < MAX_BOMB_LEVEL
	return false

func roll_offers(count: int) -> Array[String]:
	var options: Array[String] = []
	for id in UPGRADE_NAMES:
		if can_upgrade(id):
			options.append(id)
	options.shuffle()
	var offers: Array[String] = []
	for i in min(count, options.size()):
		offers.append(options[i])
	return offers

func apply_upgrade(id: String) -> String:
	if not can_upgrade(id):
		return ""
	match id:
		"row":
			weapon.shot_rows += 1
		"diagonal":
			weapon.diagonal_level += 1
		"bomb":
			bombs.bomb_level += 1
	return UPGRADE_NAMES[id]
