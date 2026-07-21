extends Node

signal message_requested(messages: Array[String], speed: int)
signal message_box_closed
signal dialogue_requested(messages: Array[String], speed: int, portrait: Texture2D)
signal dialogue_box_closed


var _message_box: Node
var _dialogue_box: Node

func register(box: Node = null, dialogue : Node = null) -> void:
	if box != null:
		_message_box = box
	if dialogue != null:
		_dialogue_box = dialogue
	

## Standard send: shows text, waits for player to press E, then closes.
func send(messages: Array[String], speed: int = 30) -> void:
	message_requested.emit(messages, speed)
	Global.set_movement_blocked(true)
	
func send_dialogue(messages: Array[String], speed: int = 30, portrait: Sprite2D = null) -> void:
	dialogue_requested.emit(messages, speed, portrait)
	Global.set_movement_blocked(true)

## Passive send: shows text in the box but doesnt wait for input and doesnt block movement
func send_passive(text: String, speed: int = 30) -> void:
	if _message_box == null:
		return
	_message_box.show_passive(text, speed)

func switch_message_box_mode(battle: bool):
	_message_box.battle_mode = battle

## Await this to pause until the player has dismissed the current message.
## Safe to call even if nothing is currently showing.
func wait_for_close() -> void:
	if not is_reading():
		return
	await message_box_closed

func is_reading(flag: bool = false) -> bool:
	if _message_box == null:
		return false
	if flag:
		return _dialogue_box.is_reading()
	return _message_box.is_reading()

func notify_closed(flag: bool = false) -> void:
	if not _message_box.battle_mode:
		Global.set_movement_blocked(false)
	if flag:
		dialogue_box_closed.emit()
	else:
		message_box_closed.emit()
