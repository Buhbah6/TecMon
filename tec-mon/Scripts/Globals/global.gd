extends Node

signal block_movement(blocked: bool)

var main_menu: LevelData = preload("res://Levels/MainMenu.tres")
var first_level: LevelData = preload("res://Levels/LevelOne.tres")
var shiny_odds: float = 0.00025 #Roughly 1/4096
var player: Player
var game_manager: MainGame

func register_game_manager(node: MainGame):
	game_manager = node

func register_player(node: Player):
	player = node

func set_movement_blocked(blocked: bool) -> void: #Global func to stop the players movement
	block_movement.emit(blocked)

var TYPE_MAP : Dictionary = {
	"normal": Enums.TecmonType.NORMAL,
	"fire": Enums.TecmonType.FIRE,
	"water": Enums.TecmonType.WATER,
	"grass": Enums.TecmonType.GRASS,
	"electric": Enums.TecmonType.ELECTRIC,
	"ice": Enums.TecmonType.ICE,
	"fighting": Enums.TecmonType.FIGHTING,
	"poison": Enums.TecmonType.POISON,
	"ground": Enums.TecmonType.GROUND,
	"flying": Enums.TecmonType.FLYING,
	"psychic": Enums.TecmonType.PSYCHIC,
	"bug": Enums.TecmonType.BUG,
	"rock": Enums.TecmonType.ROCK,
	"ghost": Enums.TecmonType.GHOST,
	"dragon": Enums.TecmonType.DRAGON,
	"dark": Enums.TecmonType.DARK,
	"steel": Enums.TecmonType.STEEL,
	"fairy": Enums.TecmonType.FAIRY,
}

var AILMENT_MAP := {
	"none": Enums.TecmonAilment.NONE,
	"burn": Enums.TecmonAilment.BURN,
	"freeze": Enums.TecmonAilment.FREEZE,
	"paralysis": Enums.TecmonAilment.PARALYSIS,
	"poison": Enums.TecmonAilment.POISON,
	"toxic": Enums.TecmonAilment.TOXIC,
	"sleep": Enums.TecmonAilment.SLEEP,
	"confusion": Enums.TecmonAilment.CONFUSION,
	"trap": Enums.TecmonAilment.TRAP,
	"leech-seed": Enums.TecmonAilment.LEECH_SEED,
	"disable": Enums.TecmonAilment.DISABLE,
	"unknown": Enums.TecmonAilment.UNKNOWN,
}

var STAT_MAP := {
	"hp": Enums.TecmonStat.HP,
	"attack": Enums.TecmonStat.ATTACK,
	"defense": Enums.TecmonStat.DEFENSE,
	"special-attack": Enums.TecmonStat.SPECIAL_ATTACK,
	"special-defense": Enums.TecmonStat.SPECIAL_DEFENSE,
	"speed": Enums.TecmonStat.SPEED,
	"accuracy": Enums.TecmonStat.ACCURACY,
	"evasion": Enums.TecmonStat.EVASION,
}
