extends Resource
class_name TecmonData

## Tecmon blueprint. Only one exists and is shared across all
## TecmonInstances of that species. Never stores battle state and indivdual info

@export_category("Basic Info")
@export var tecmon_name: String = ""
@export var id: int = 1
@export_multiline var description: String = ""
@export var type_one: Enums.TecmonType = Enums.TecmonType.NONE
@export var type_two: Enums.TecmonType = Enums.TecmonType.NONE

@export_category("Sprites")
@export var front_sprite: Texture2D        ## 64×64
@export var front_shiny_sprite: Texture2D
@export var back_sprite: Texture2D
@export var back_shiny_sprite: Texture2D
@export var mini_sprite: Texture2D         ## 32×32

## These are values used to for a specific instance's stats
## with TecmonInstance.compute_stats(). Do not read these directly in battle.
@export_category("Base Stats")
@export var base_hp: float = 75.0
@export var base_attack: float = 75.0
@export var base_defense: float = 75.0
@export var base_special_attack: float = 75.0
@export var base_special_defense: float = 75.0
@export var base_speed: float = 75.0
@export var base_experience: float = 65.0

## Every move this species can learn and at which level.
## Used by TecmonInstance when levelling up to offer new moves.
@export_category("Learnset")
@export var learnset: Array[LearnEntry] = []

@export_category("Evolution")
@export var evolution: TecmonData
@export var evolution_level: int = 30

## Used by EncounterTable when generating a new TecmonInstance.
@export_category("Spawn Info")
@export var min_level: int = 2
@export var max_level: int = 5
@export var weight: int = 10 ## Higher = more common in encounter tables.
@export_range(1, 100, 1) var catch_rate: float = 50.0 ## Lower = harder to catch

## Returns every move learnable at or below the given level (for starter movesets).
func moves_available_at(level: int) -> Array[MoveResource]:
	var result: Array[MoveResource] = []
	for entry in learnset:
		if entry.learn_level <= level:
			result.append(entry.move)
	return result
