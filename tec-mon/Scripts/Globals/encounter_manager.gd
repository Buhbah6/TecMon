extends Node

signal encounter_started(encounter: TecmonInstance)  ## Emits a live instance, not a blueprint.

func try_encounter(zone: String = "grass", force : bool = false) -> void:
	if not Global.player.can_battle():
		return
		
	var level := SceneManager.current_level_data
	if level == null or not level.has_encounters:
		return

	if randf() > level.encounter_rate:
		return

	var table: EncounterTable = _get_table(level, zone)
	if table == null:
		return

	var instance : TecmonInstance = table._roll()
	if instance:
		encounter_started.emit(instance)

func _get_table(level: LevelData, zone: String) -> EncounterTable:
	match zone:
		"grass": return level.grass_encounters
		"water": return level.water_encounters
		"cave":  return level.cave_encounters
	return null
