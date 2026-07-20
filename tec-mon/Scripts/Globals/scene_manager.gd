extends CanvasLayer

signal level_changed(level_data: LevelData)

var current_level: LevelData = null
var previous_level: LevelData = null
var _is_changing: bool = false
var color_rect: ColorRect
var game_manager: Node
var current_level_container: Node2D
var _levels: Dictionary = {}
var dir_path: String = "res://Levels/"
var transition_shader: Shader = preload("res://Shaders/transition.gdshader")
var mask_texture: Texture2D = preload("res://Assets/GreyScaleMasks/itec_logo.png")

var _shader_material: ShaderMaterial

func _ready() -> void:
	_register_all()
	layer = 100
	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.color = Color.BLACK

	_shader_material = ShaderMaterial.new()
	_shader_material.shader = transition_shader
	_shader_material.set_shader_parameter("mask_texture", mask_texture)
	_shader_material.set_shader_parameter("luminance_cutoff", 1.0)  ## fully hidden at start

	color_rect.material = _shader_material
	color_rect.visible = false
	add_child(color_rect)

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

	var level_data := get_level(level_name)
	if level_data == null:
		push_error("Level not found: " + level_name)
		return

	_is_changing = true
	await _transition_out()

	if current_level_container.get_child_count() > 0:
		current_level_container.get_child(0).queue_free()
		
	previous_level = current_level
	current_level = level_data
	var level_path: String = current_level.scene_path
	var level_scene: PackedScene = load(level_path)
	var level_node: Level = level_scene.instantiate()
	current_level_container.add_child(level_node)

	await get_tree().process_frame

	level_changed.emit(level_data)

	await _transition_in()
	_is_changing = false

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
	
	
