extends StaticBody2D
class_name Chest

@export var item: ItemData
@export var item_amount: int = 1
@export var infinite : bool

@export var chest_sprite : Sprite2D
@export var chest_opened_sprite : Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var interacted: bool = false

func interact(player: Player):
	if interacted:
		return
	give_item(player)
	animation_player.play("open")
	AudioManager.play_sfx("open_chest")
	if not infinite:
		interacted = true 
	

func give_item(player: Player):
	player.inventory.add(item, item_amount)
	
	if item_amount > 0:
		MessageBus.send(["You have recieved x" + str(item_amount) + " " + item.item_name + "!"])
	else:
		MessageBus.send(["You have recieved a " + item.item_name + "!"])
		
	await MessageBus.message_box_closed
	animation_player.play("close")
	Global.set_movement_blocked(false)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close" and not infinite:
		chest_sprite.hide()
		chest_opened_sprite.show()
