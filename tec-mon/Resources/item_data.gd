extends Resource
class_name ItemData

enum Category { HEALING, BATTLE, KEY }

enum Effect {
	NONE,
	RESTORE_HP, ## Heals a flat amount of HP.
	RESTORE_HP_FULL, ## Fully restores HP.
	RESTORE_PP, ## Restores PP of one move.
	RESTORE_PP_ALL, ## Restores PP of all moves.
	CURE_AILMENT, ## Cures a specific ailment
	CURE_ALL_AILMENTS, ## Cures every ailment.
	REVIVE, ## Revives a fainted tecmon
	REVIVE_FULL, ## Revives a fainted tecmon to full HP.
	CAPTURE, ## Capturing item
	STAT_INCREASE, ## Raises a stat
}

@export_category("Basic Info")
@export var item_name: String = ""
@export_multiline() var description: String = ""
@export var icon: Texture2D
@export var category: Category = Category.HEALING
@export var can_use_in_battle: bool = true
@export var can_use_in_field: bool = true

@export_category("Effect")
@export var effect: Effect = Effect.NONE
@export var hp_amount: float = 0.0
@export var target_ailment: Enums.TecmonAilment = Enums.TecmonAilment.NONE
@export var stat_target: Enums.TecmonStat = Enums.TecmonStat.ATTACK
@export var stat_stages: int = 1
@export var capture_rate_modifier: float = 1.0

@export_category("Shop")
@export var buy_price: int = 0
@export var sell_price: int = 0
@export var purchasable: bool = true
