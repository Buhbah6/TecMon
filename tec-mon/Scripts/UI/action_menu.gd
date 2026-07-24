extends NinePatchRect

@onready var indicator: TextureRect = $Indicator
@onready var fight: Button = %Fight
@onready var items: Button = %Items
@onready var tecmons: Button = %Tecmons
@onready var escape: Button = %Escape

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fight.is_hovered()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if fight.is_hovered():
		indicator.show()
		indicator.position = Vector2i(8, 12)
	elif items.is_hovered():
		indicator.show()
		indicator.position = Vector2i(57, 12)
	elif tecmons.is_hovered():
		indicator.show()
		indicator.position = Vector2i(8, 30)
	elif escape.is_hovered():
		indicator.show()
		indicator.position = Vector2i(57, 30)
	else:
		indicator.hide()
