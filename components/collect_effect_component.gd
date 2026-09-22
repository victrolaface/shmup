class_name CollectEffectComponent
extends Component

enum Kind { CHARGE, CURRENCY, HEAL }

@export var kind: Kind = Kind.CHARGE
@export var amount: float = 1.0
@export var full_health_score: int = 25

func _ready() -> void:
	(Component.of(entity, "MagnetComponent") as MagnetComponent).collected.connect(_apply)

func _apply(player: Player) -> void:
	match kind:
		Kind.CHARGE:
			player.super_meter.grant_charge(amount)
		Kind.CURRENCY:
			Game.add_currency(int(amount))
		Kind.HEAL:
			if player.health.health >= player.health.max_health:
				Game.add_score(full_health_score)
			else:
				player.health.heal(int(amount))
