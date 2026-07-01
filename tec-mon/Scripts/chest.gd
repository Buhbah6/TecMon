extends StaticBody2D
class_name Chest

@export var item: ItemData

func interact(player: Player):
	give_item(player)
	AudioManager.play_sfx("open_chest")

func give_item(player: Player):
	player.inventory.add(item)
	MessageBus.send(["You have recieved a " + item.item_name + "!"])
	Global.set_movement_blocked(false)
