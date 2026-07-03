extends CanvasLayer

func _ready() -> void:
	hide()

func _on_back_button_pressed() -> void:
	get_tree().paused = false
	hide()
	
