class_name LevelData
extends Resource

@export_category("Info")
@export var level_name: String = ""
@export var scene_path: String = ""

@export_category("Music")
@export var bgm: AudioStream

@export_category("Encounters")
@export var has_encounters: bool = false
@export var encounter_rate: float = 0.1  # chance per step (0.0 - 1.0)
@export var encounter_level_multiplier : float = 1.0
@export var grass_encounters: EncounterTable
@export var water_encounters: EncounterTable
@export var cave_encounters: EncounterTable

@export_category("Connections")
@export var connected_levels: Array[String] = []  # level_names this connects to
