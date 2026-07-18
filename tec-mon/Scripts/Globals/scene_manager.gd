extends CanvasLayer

signal level_changed(level_data: LevelData)

@export var player_scene: PackedScene
@export var first_level_name: String = ""
@export var transition_shader: Shader
@export var mask_texture: Texture2D

var current_level: Level
var current_level_data: LevelData = null
var level_container: Node2D
var player: Player

var _levels: Dictionary = {}
var dir_path: String = "res://Levels/"
var _is_changing: bool = false

@onready var color_rect: ColorRect = $ColorRect
var _shader_material: ShaderMaterial

func _ready() -> void:
	_register_all()
	_shader_material = color_rect.material
	_init_player()

func _init_player() -> void:
	if player_scene == null:
		push_error("SceneManager: no player_scene assigned")
		return
	player = player_scene.instantiate() as Player
	if player == null:
		push_error("SceneManager: failed to instantiate player_scene")

func _register_all() -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.get_extension() == "tres":
			var res: LevelData = load(dir_path + file)
			if res is LevelData:
				_levels[res.level_name] = res
		file = dir.get_next()

func get_level(level_name: String) -> LevelData:
	return _levels.get(level_name, null)

func get_all() -> Dictionary:
	return _levels

func is_changing() -> bool:
	return _is_changing

func go_to(level_name: String) -> void:
	if _is_changing:
		return

	if level_container == null:
		push_error("SceneManager: level_container is not assigned yet")
		return

	var level_data := get_level(level_name)
	if level_data == null:
		push_error("SceneManager: level not found: " + level_name)
		return

	_is_changing = true
	await _transition_out()

	if current_level != null:
		current_level.free()
		current_level = null
		await get_tree().process_frame

	var packed_level: PackedScene = ResourceLoader.load(level_data.scene_path, "PackedScene") as PackedScene
	if packed_level == null:
		push_error("SceneManager: failed to load level scene: " + level_data.scene_path)
		_is_changing = false
		return

	current_level = packed_level.instantiate() as Level
	level_container.add_child(current_level)
	await get_tree().process_frame

	current_level_data = level_data
	_place_player_in_level()

	level_changed.emit(level_data)

	await _transition_in()
	_is_changing = false

func _place_player_in_level() -> void:
	if player == null or current_level == null:
		return
	current_level.add_entity(player)
	player.global_position = current_level.get_player_spawn()

func _transition_out() -> void:
	color_rect.visible = true
	var tween := create_tween()
	tween.tween_method(_set_cutoff, 1.0, 0.0, 0.5)
	await tween.finished

func _transition_in() -> void:
	var tween := create_tween()
	tween.tween_method(_set_cutoff, 0.0, 1.0, 0.5)
	await tween.finished
	color_rect.visible = false

func _set_cutoff(value: float) -> void:
	_shader_material.set_shader_parameter("luminance_cutoff", value)
