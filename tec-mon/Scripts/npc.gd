extends StaticBody2D
class_name NPC

enum NPCTypes{BATTLE, ITEM, DIALOG, OTHER}

@export var npc_type: NPCTypes = NPCTypes.BATTLE
@export var party_data: Array[TecmonData]
@export var tecmon_levels: Array[int]
@export_multiline() var initial_dialog: Array[String] = []
@export_multiline() var end_dialog: Array[String] = []
@export var item: ItemData
var party_instance : Array[TecmonInstance]

func _ready() -> void:
	while not party_data.is_empty():
		party_instance.append(TecmonInstance.create(party_data[0], 4, party_data[0].tecmon_name))
		party_data.pop_front()
	
func interact(player: Player) -> void:
	reset()
	if not initial_dialog.is_empty():
		MessageBus.send(initial_dialog)
	await MessageBus.message_box_closed
	Global.set_movement_blocked(true)
	match npc_type:
		NPCTypes.BATTLE:
			await start_battle(player)
		NPCTypes.ITEM:
			give_item(player)
			
	Global.set_movement_blocked(false)
	
func start_battle(player: Player) -> void:
	await SceneManager._transition_out()
	BattleSystem.start_battle(party_instance, player.tecmon_party)
	BattleSystem.stage_closed.connect(_on_battle_ended, CONNECT_ONE_SHOT)

func _on_battle_ended() -> void:
	if not end_dialog.is_empty():
		MessageBus.send(end_dialog)
		await MessageBus.message_box_closed
	Global.set_movement_blocked(false)
	
func reset() -> void:
	for mon in party_instance:
		mon.current_hp = mon.max_hp
		mon.clear_all_ailments()

func give_item(player: Player):
	player.inventory.add(item)
	if not end_dialog.is_empty():
		MessageBus.send(end_dialog)
	Global.set_movement_blocked(false)
	
