extends Button

var idx: int
signal selected(idx: int)
signal hovered(idx: int)

@onready var tecmon_hp_bar: ProgressBar = %TecmonHPBar
@onready var outline: NinePatchRect = $Outline

func _ready() -> void:
	outline.hide()

func _on_tecmon_details_pressed() -> void:
	selected.emit(idx)

func _on_mouse_entered() -> void:
	outline.show()
	hovered.emit(idx)

func _on_mouse_exited() -> void:
	outline.hide()
