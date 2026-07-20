extends Node2D
class_name Level

@export var level_data: LevelData
@export var spawn1 : Marker2D
@export var spawn2 : Marker2D

func _ready() -> void:
	if level_data == null:
		return
		
	if level_data.bgm != null:
		AudioManager.play_music(level_data.bgm, -12)
		
	if spawn1 and spawn2 == null:
		return
		
	if SceneManager.previous_level != null:
		if SceneManager.previous_level.level_name == level_data.connected_levels[0]:
			Global.player.position = spawn2.global_position
		else:
			Global.player.position = spawn1.global_position
		
	
		


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		SceneManager.go_to(level_data.connected_levels[0])
		
