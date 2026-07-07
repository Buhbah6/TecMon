class_name player_camera extends Camera2D

func _ready() -> void:
	TilemapManager.on_bounds_changed.connect(update_limits)
	update_limits(TilemapManager.current_bounds)
	pass
	
func update_limits(bounds: Array[Vector2]) -> void:
	if bounds.is_empty():
		return
	limit_left = bounds[0].x
	limit_top = bounds[0].y
	limit_right = bounds[1].x
	limit_bottom = bounds[1].y
