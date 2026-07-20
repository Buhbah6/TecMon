extends Control


func _ready() -> void:
	hide()
	
func _pause() -> void:
	show()
	get_tree().paused = true

func _unpause() -> void:
	hide()
	get_tree().paused = false

func _on_resume_button_pressed() -> void:
	_unpause()

func _on_main_menu_button_pressed() -> void:
	_unpause()
	Global.game_manager.main_menu.show()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_options_button_pressed() -> void:
	hide()
	Global.game_manager.options_menu.show()
	Global.game_manager.options_menu.from_pause_menu = true
