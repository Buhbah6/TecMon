extends HBoxContainer
class_name InputButton

@export var input_name: String

@onready var button: Button = $Button
@onready var action_name: Label = $ActionName

var _listening: bool = false

func _ready() -> void:
	action_name.text = input_name.capitalize()
	button.pressed.connect(_on_button_pressed)
	_refresh_label()

func _refresh_label() -> void:
	var events := InputMap.action_get_events(input_name)
	if events.is_empty():
		button.text = "Unbound"
	else:
		button.text = events[0].as_text().rstrip("- Physical")

func _on_button_pressed() -> void:
	if _listening:
		return
	_listening = true
	button.text = "Listening..."

func _unhandled_input(event: InputEvent) -> void:
	if not _listening:
		return

	## Ignore mouse motion, only accept actual button/key presses.
	if event is InputEventMouseMotion:
		return

	## Require an actual press, not a release
	if event is InputEventKey and not event.pressed:
		return
	if event is InputEventMouseButton and not event.pressed:
		return
	if event is InputEventJoypadButton and not event.pressed:
		return

	## Let Escape cancel rebinding instead of binding to Escape itself
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		_listening = false
		_refresh_label()
		get_viewport().set_input_as_handled()
		return

	_rebind(event)
	get_viewport().set_input_as_handled()

func _rebind(event: InputEvent) -> void:
	InputMap.action_erase_events(input_name)
	InputMap.action_add_event(input_name, event)
	_listening = false
	_refresh_label()
