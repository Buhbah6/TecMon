extends StaticBody2D
class_name Chest

@export var item: ItemData
@export var item_amount: int = 1

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func interact(player: Player):
	give_item(player)
	animation_player.play("open")
	AudioManager.play_sfx("open_chest")

func give_item(player: Player):
	player.inventory.add(item, item_amount)
	
	if item_amount > 0:
		MessageBus.send(["You have recieved x" + str(item_amount) + " " + item.item_name + "!"])
	else:
		MessageBus.send(["You have recieved a " + item.item_name + "!"])
		
	await MessageBus.message_box_closed
	animation_player.play("close")
	Global.set_movement_blocked(false)
