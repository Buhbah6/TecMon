extends Control

@onready var tec_mon: Control = %TecMon
@onready var items: Control = %Items

func _ready() -> void:
	hide()

func _on_back_button_pressed() -> void:
	get_tree().paused = false
	hide()

func _on_visibility_changed() -> void:
	if visible:
		tec_mon._populate()
		items._populate()
