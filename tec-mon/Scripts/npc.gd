extends CharacterBody2D
class_name NPC

enum NPCTypes{BATTLE, ITEM, DIALOG, OTHER}

const TILE_SIZE : int = 16
const MOVE_SPEED : int = 32 
const STOPPING_DISTANCE_TILES : int = 1

@export var npc_type: NPCTypes = NPCTypes.BATTLE
@export var party_data: Array[TecmonData] = []
@export var tecmon_levels: Array[int] = []
@export_multiline() var initial_dialog: Array[String] = []
@export_multiline() var end_dialog: Array[String] = []
@export_multiline() var interacted_dialog: Array[String] = []
@export var item: ItemData
@export var item_amount: int = 1
@export var animation_player : AnimationPlayer
@export var facing_direction: int = 0
@export var can_chase: bool = false

var party_instance : Array[TecmonInstance]
var interacted: bool = false
var can_interact: bool = true
var chasing_player : bool = false
var current_animation : String
var default_frame : int

var target_position: Vector2
var is_moving_tile := false

func _ready() -> void:
	default_frame = get_node("%NPC").frame
	while not party_data.is_empty():
		party_instance.append(TecmonInstance.create(party_data[0], tecmon_levels[0], party_data[0].tecmon_name))
		tecmon_levels.pop_front()
		party_data.pop_front()
	match (facing_direction):
		1:
			get_node("%Area2D").rotation_degrees = 90
			current_animation = "npc_left" 
		2:
			get_node("%Area2D").rotation_degrees = 180
			current_animation = "npc_up" 
		3:
			get_node("%Area2D").rotation_degrees = 270
			current_animation = "npc_right" 
		0:
			get_node("%Area2D").rotation_degrees = 0
			current_animation = "npc_down" 
			

func _physics_process(delta: float) -> void:
	if interacted:
		can_chase = false
		
	if chasing_player and Global.player != null:
		chase_player_tile(Global.player, delta)
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	
func interact(player: Player) -> void:
	if can_interact:
		if interacted:
			if not interacted_dialog.is_empty():
				MessageBus.send(interacted_dialog)
		else:
			interacted = true
			if not initial_dialog.is_empty():
				MessageBus.send(initial_dialog)
			await MessageBus.message_box_closed
			Global.set_movement_blocked(true)
			
			match npc_type:
				NPCTypes.BATTLE:
					start_battle(player)
				NPCTypes.ITEM:
					give_item(player)
				NPCTypes.DIALOG:
					Global.set_movement_blocked(false)
				
	
func start_battle(player: Player) -> void:
	can_interact = false
	BattleSystem.start_battle(party_instance, player.tecmon_party, true)
	BattleSystem.stage_closed.connect(_on_battle_ended, CONNECT_ONE_SHOT)
	
func _on_battle_ended() -> void:
	can_interact = true
	if not end_dialog.is_empty():
		MessageBus.send(end_dialog)
		await MessageBus.message_box_closed
	Global.set_movement_blocked(false)
	
func reset() -> void:
	for mon in party_instance:
		mon.current_hp = mon.max_hp
		mon.clear_all_ailments()

func give_item(player: Player):
	player.inventory.add(item, item_amount)
	if not end_dialog.is_empty():
		MessageBus.send(end_dialog)
	Global.set_movement_blocked(false)
	


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and can_chase:
		animation_player.play(current_animation)
		chasing_player = true
		

func chase_player_tile(player: Player, delta: float) -> void:
	Global.set_movement_blocked(true)

	var npc_tile := (global_position / TILE_SIZE).floor()
	var player_tile := (player.global_position / TILE_SIZE).floor()

	var tile_distance = abs(player_tile.x - npc_tile.x) + abs(player_tile.y - npc_tile.y)

	if tile_distance <= STOPPING_DISTANCE_TILES and not is_moving_tile:
		animation_player.stop()
		get_node("%NPC").frame = default_frame
		velocity = Vector2.ZERO
		chasing_player = false
		interact(player)
		return

	if not is_moving_tile:
		var direction := Vector2.ZERO

		var difference := player_tile - npc_tile

		if abs(difference.x) > abs(difference.y):
			direction.x = sign(difference.x)
		else:
			direction.y = sign(difference.y)

		target_position = global_position + direction * TILE_SIZE
		is_moving_tile = true

	var move_direction := global_position.direction_to(target_position)
	velocity = move_direction * MOVE_SPEED

	if global_position.distance_to(target_position) <= 1.0:
		global_position = target_position
		velocity = Vector2.ZERO
		is_moving_tile = false
	
