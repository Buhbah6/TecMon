extends Node2D
class_name Level

@export var level_data: LevelData

func _ready() -> void:
	if level_data == null:
		return

	if level_data.bgm != null:
		AudioManager.play_music(level_data.bgm, -12)
		


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		SceneManager.go_to(level_data.connected_levels[0].level_name)
		
