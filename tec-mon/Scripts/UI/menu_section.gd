extends Control

@export var background: Sprite2D
@onready var credits_layer: CanvasLayer = %CreditsLayer

@export var bg_move_amount: float = 40.0
@export var bg_scale_amount: float = 0.15
@export var bg_tween_time: float = 4.0

var _bg_start_position: Vector2
var _bg_start_scale: Vector2

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	_bg_start_position = background.position
	_bg_start_scale = background.scale
	
	_animate_background()

func _animate_background() -> void:
	var random_offset := Vector2(
		randf_range(-bg_move_amount, bg_move_amount),
		randf_range(-bg_move_amount, bg_move_amount)
	)

	var random_scale_multiplier := randf_range(1.0 - bg_scale_amount, 1.0 + bg_scale_amount)

	var target_position := _bg_start_position + random_offset
	var target_scale := _bg_start_scale * random_scale_multiplier

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(background, "position", target_position, bg_tween_time)
	tween.tween_property(background, "scale", target_scale, bg_tween_time)

	await tween.finished

	_animate_background()

func _on_start_button_pressed() -> void:
	await Global.game_manager.start_game()
	hide()

func _on_options_button_pressed() -> void:
	Global.game_manager.options_menu.show()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_button_mouse_entered() -> void:
	AudioManager.play_sfx("select")

func _on_credits_button_pressed() -> void:
	credits_layer.show()

func _on_start_button_mouse_entered() -> void:
	pass # Replace with function body.

func _on_options_button_mouse_entered() -> void:
	pass # Replace with function body.

func _on_exit_button_mouse_entered() -> void:
	pass # Replace with function body.
