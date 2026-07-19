extends Node2D

func _ready() -> void:
	print("updating bounds")
	TilemapManager.change_bounds(get_bounds())
	
func get_bounds() -> Array[Vector2i]:
	var first := true
	var combined_rect := Rect2i()
	var reference_layer: TileMapLayer = null

	for child in get_children():
		if child is TileMapLayer:
			var rect = child.get_used_rect()

			# Skip empty layers
			if rect.size == Vector2i.ZERO:
				continue

			if first:
				combined_rect = rect
				reference_layer = child
				first = false
			else:
				combined_rect = combined_rect.merge(rect)

	if first:
		return []

	# Convert from map coordinates to world coordinates
	var top_left := reference_layer.to_global(
		reference_layer.map_to_local(combined_rect.position)
	)
	top_left = Vector2(top_left.x + 16, top_left.y + 16)

	var bottom_right := reference_layer.to_global(
		reference_layer.map_to_local(combined_rect.position + combined_rect.size)
	)
	bottom_right = Vector2(bottom_right.x - 16, bottom_right.y - 16)

	return [top_left, bottom_right]
