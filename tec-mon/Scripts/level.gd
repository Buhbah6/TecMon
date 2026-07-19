extends Node2D
class_name Level

@export var level_data: LevelData
var spawn_point: Marker2D
var tiles: Node2D

func _ready() -> void:
	if level_data == null:
		return
	if level_data.bgm != null:
		AudioManager.play_music(level_data.bgm, -12)
	spawn_point = get_node("SpawnPoint")
	tiles = get_node("Tiles")
	
func get_player_spawn() -> Vector2:
	if spawn_point == null:
		return Vector2.ZERO
	return spawn_point.global_position

func add_entity(entity: Node2D) -> void:
	if entity.is_inside_tree():
		return
	Global.game_manager.level_root.add_child(entity)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		if level_data.connected_levels.is_empty():
			push_warning("Level: exit triggered but level_data.connected_levels is empty")
			return
		SceneManager.go_to(level_data.connected_levels[0].level_name)
