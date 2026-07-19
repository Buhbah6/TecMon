extends Node

var current_bounds: Array[Vector2i]
signal on_bounds_changed(bounds: Array[Vector2i])

func change_bounds(bounds: Array[Vector2i]) -> void:
	current_bounds = bounds
	on_bounds_changed.emit(bounds)
