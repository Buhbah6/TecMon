extends CanvasLayer

@onready var enemy_sprite:  TextureRect = $Control/EnemyTecmon
@onready var player_sprite: TextureRect = $Control/PlayerTecmon

@onready var enemy_name_label: Label = %EnemyName
@onready var enemy_hp_bar: ProgressBar = %EnemyHPBar
@onready var player_name_label: Label = %PlayerName
@onready var player_hp_bar: ProgressBar = %PlayerHPBar
@onready var enemy_hp_label: Label = %EnemyHPLabel
@onready var player_hp_label: Label = %PlayerHPLabel

@onready var move_container: VBoxContainer = %MoveContainer
@onready var move_one: Button = %MoveOne
@onready var move_two: Button = %MoveTwo
@onready var move_three: Button = %MoveThree
@onready var move_four: Button = %MoveFour

var can_input: bool = false
var buttons: Array[Button]

func _ready() -> void:
	EncounterManager.encounter_started.connect(_on_encounter_started)
	BattleSystem.battle_started.connect(_on_battle_started)
	BattleSystem.battle_ended.connect(_on_battle_ended)
	BattleSystem.turn_ended.connect(_on_turn_ended)
	BattleSystem.move_executed.connect(_on_move_executed)
	
	buttons = [move_one, move_two, move_three, move_four]
	
	move_one.pressed.connect(_on_move_button_pressed.bind(0))
	move_two.pressed.connect(_on_move_button_pressed.bind(1))
	move_three.pressed.connect(_on_move_button_pressed.bind(2))
	move_four.pressed.connect(_on_move_button_pressed.bind(3))
	hide()

func _on_encounter_started(enemy_instance: TecmonInstance) -> void:
	## Block movement and show the encounter message. BattleSystem hasn't
	## started yet so we handle this message ourselves.
	MessageBus.send(["You encountered a " + enemy_instance.display_name() + "!"])
	MessageBus.switch_message_box_mode(true)
	await MessageBus.message_box_closed

	await SceneManager._transition_out()
	AudioManager.play_music(preload("res://Assets/Sounds/Music/battle_theme.wav"))
	var party: Array[TecmonInstance] = [
		TecmonInstance.create(
			get_tree().get_first_node_in_group("Player").starter_tecmon, 4, false
		)
	]
	party.get(0).nickname = "Saint"
	_refresh_hp_bars()
	BattleSystem.start_battle(enemy_instance, party)
	show()
	await SceneManager._transition_in()
	
func _on_battle_started() -> void:
	_refresh_hp_bars()
	new_turn()

func _set_battle_buttons_enabled(enabled: bool) -> void:
	can_input = enabled

	for button in buttons:
		button.disabled = not enabled

func _on_turn_ended() -> void:
	## HP bars were already updated after each move_executed signal.
	## Just show the action prompt and menu again.
	new_turn()

func new_turn() -> void:
	_set_battle_buttons_enabled(true)
	move_container.hide()
	MessageBus.send_passive(
		"What will " + BattleSystem.player_participant.display_name() + " do?"
	)

func _refresh_hp_bars() -> void:
	var enemy  : BattleParticipant = BattleSystem.enemy_participant
	var player : BattleParticipant = BattleSystem.player_participant
	
	if enemy:
		enemy_sprite.texture = enemy.instance.get_front_sprite()
		enemy_name_label.text = enemy.display_name() + " Lv." + str(enemy.instance.level)
		enemy_hp_bar.value = enemy.hp_percent() * 100.0
		enemy_hp_label.text = (str(enemy.current_hp()) + "/ " + str(enemy.max_hp()))
		
	if player:
		var player_tecmon : TecmonInstance = player.instance
		player_sprite.texture = player_tecmon.get_back_sprite()
		player_name_label.text = player.display_name() + " Lv." + str(player_tecmon.level)
		player_hp_bar.value = player.hp_percent() * 100.0
		player_hp_label.text = (str(player.current_hp()) + "/ " + str(player.max_hp()))

func _on_move_executed(_user: BattleParticipant, _target: BattleParticipant,
		_move: MoveInstance, _result: MoveResult) -> void:
	_refresh_hp_bars()
	## TODO: play damage animation / screen shake here before _say() fires.

#Action menu buttons

func _on_fight_pressed() -> void:
	if not can_input:
		return
	
	move_container.show()
	AudioManager.play_sfx("select")
	MessageBus._message_box._clear_passive()
	var inst: TecmonInstance = BattleSystem.player_participant.instance
	var buttons := [move_one, move_two, move_three, move_four]
	for i in 4:
		var btn: Button = buttons[i]
		if i < inst.moves.size():
			var mi: MoveInstance = inst.moves[i]
			btn.text = mi.move.move_name + "  " + str(mi.current_pp) + "/" + str(mi.move.max_pp)
			btn.show()
		else:
			btn.hide()

func _on_move_button_pressed(index: int) -> void:
	var inst: TecmonInstance = BattleSystem.player_participant.instance
	var move: MoveInstance = inst.moves.get(index)
	if move == null:
		return
		
	_set_battle_buttons_enabled(false)
	move_container.hide()
	AudioManager.play_sfx("select")
	BattleSystem.queue_move(move)

func _on_items_pressed() -> void:
	if not can_input:
		return
		
	AudioManager.play_sfx("select")
	pass  ## TODO

func _on_tecmons_pressed() -> void:
	if not can_input:
		return
		
	AudioManager.play_sfx("select")
	pass  ## TODO

func _on_escape_pressed() -> void:
	if not can_input:
		return
		
	AudioManager.play_sfx("select")
	BattleSystem.queue_flee()

func _on_battle_ended(outcome: BattleSystem.BattleOutcome) -> void:
	## BattleSystem already sent all result messages and awaited them.
	## Just do the transition back to the overworld.
	var msg: String
	match outcome:
		BattleSystem.BattleOutcome.PLAYER_WIN:  msg = "You won!"
		BattleSystem.BattleOutcome.PLAYER_FLED: msg = "Got away safely!"
		BattleSystem.BattleOutcome.PLAYER_LOST: msg = "You blacked out..."
	MessageBus.send([msg], 30)
	MessageBus.switch_message_box_mode(false)
	await MessageBus.message_box_closed
	MessageBus._message_box.switch_mode()
	await SceneManager._transition_out()
	hide()
	AudioManager.play_music(SceneManager.current_level.bgm)
	await SceneManager._transition_in()
