extends CanvasLayer

func _ready() -> void:
	hide()

func _on_back_button_pressed() -> void:
	get_tree().paused = false
	hide()

func _on_visibility_changed() -> void:
	if visible:
		get_node("%TecMon")._populate()
		get_node("%Items")._populate()
