extends Button

var idx: int
var item: ItemData
var item_amount: int

signal selected
signal used(item: ItemData)
signal unselected
signal hovered(item: ItemData)

@onready var item_options: CanvasLayer = $ItemOptions
@onready var use_button: Button = %UseButton
@onready var give_button: Button = %GiveButton
@onready var toss_button: Button = %TossButton
@onready var cancel_button: Button = %CancelButton

func _ready() -> void:
	item_options.hide()
	if item and item.effect == ItemData.Effect.CAPTURE:
		use_button.text = "Throw"

func _on_button_up() -> void:
	item_options.show()
	disabled = true
	selected.emit()

func _on_mouse_entered() -> void:
	if not disabled:
		hovered.emit(item)

func _on_use_button_pressed() -> void:
	item_options.hide()
	unselected.emit()
	used.emit(item)
func _on_cancel_button_pressed() -> void:
	item_options.hide()
	disabled = false
	unselected.emit()

func _on_toss_button_pressed() -> void:
	Global.player.inventory.remove(item, 1)
	item_options.hide()
	unselected.emit()

func _on_give_button_pressed() -> void:
	pass
