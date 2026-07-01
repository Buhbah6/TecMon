extends Button

var idx: float
var item: ItemData

signal selected
signal hovered

func _on_pressed() -> void:
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	hovered.emit()
