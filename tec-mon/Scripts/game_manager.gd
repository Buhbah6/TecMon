extends Node
class_name MainGame

@onready var level_root: Node2D = %LevelRoot
@onready var hud_root: Control = %HudRoot
@onready var pause_root: Control = %PauseRoot

@onready var pause_menu: Control = %PauseMenu
@onready var options_menu: Control = %OptionsMenu
@onready var main_menu: Control = %MainMenu
@onready var bag_ui: Control = %BagUI

func _ready() -> void:
	Global.register_game_manager(self)
	main_menu.show()
	SceneManager.level_container = level_root

func start_game():
	if not level_root.get_child_count() > 0:
		await SceneManager.go_to(SceneManager.first_level_name)
	else:
		await SceneManager._transition_out()
		await SceneManager._transition_in()
		
