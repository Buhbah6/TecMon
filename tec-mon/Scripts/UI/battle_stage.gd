extends Control

@onready var battle_ui: Control = %BattleUI

@onready var enemy_sprite: TextureRect = %EnemyTecmon
@onready var player_sprite: TextureRect = %PlayerTecmon
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

@onready var animation_player: AnimationPlayer = $BattleUI/AnimationPlayer

@onready var fight_button: Button = %Fight
@onready var items_button: Button = %Items
@onready var tecmons_button: Button = %Tecmons
@onready var escape_button: Button = %Escape

@onready var tecmon_ui = $TecmonUI
@onready var item_ui = $ItemUI

var _bloom_material: ShaderMaterial
@export var bloom_shader: Shader

@export var battle_themes: Array[AudioStream]

var can_input: bool = false
var move_buttons: Array[Button]
var action_buttons: Array[Button]
var is_switching: bool = false
var force_switch: bool = false

func _ready() -> void:
	EncounterManager.encounter_started.connect(_on_encounter_started)
	BattleSystem.battle_started.connect(_on_battle_started)
	BattleSystem.battle_ended.connect(_on_battle_ended)
	BattleSystem.turn_ended.connect(_on_turn_ended)
	BattleSystem.move_executed.connect(_on_move_executed)
	BattleSystem.switch_mon.connect(_on_force_switch)
	BattleSystem.lock_buttons.connect(_set_battle_buttons_disabled)
	
	move_buttons = [move_one, move_two, move_three, move_four]
	action_buttons = [fight_button, items_button, tecmons_button, escape_button]
	
	move_one.pressed.connect(_on_move_button_pressed.bind(0))
	move_two.pressed.connect(_on_move_button_pressed.bind(1))
	move_three.pressed.connect(_on_move_button_pressed.bind(2))
	move_four.pressed.connect(_on_move_button_pressed.bind(3))

	## Wire sub-scene signals.
	tecmon_ui.tecmon_selected.connect(_on_tecmon_switched)
	tecmon_ui.back_pressed.connect(_close_sub_ui)
	item_ui.item_used.connect(_on_item_used)
	item_ui.back_pressed.connect(_close_sub_ui)
	
	_bloom_material = ShaderMaterial.new()
	_bloom_material.shader = bloom_shader
	player_sprite.material = _bloom_material.duplicate()
	enemy_sprite.material = _bloom_material.duplicate()
	
	hide()
	tecmon_ui.hide()
	item_ui.hide()

func _on_encounter_started(enemy_instance: TecmonInstance) -> void:
	MessageBus.send(["You encountered a " + enemy_instance.display_name() + "!"])
	MessageBus.switch_message_box_mode(true)
	await MessageBus.message_box_closed
	await SceneManager._transition_out()
	player_sprite.hide()
	BattleSystem.start_battle([enemy_instance], Global.player.tecmon_party, false)

func _on_battle_started() -> void:
	AudioManager.play_music(battle_themes.pick_random())
	_refresh_hp_bars(false)
	new_turn()
	show()
	await SceneManager._transition_in()
	animation_player.play("tecmon_chosen")
	await animation_player.animation_finished
	animation_player.play("idle")
	
func _play_chosen_flash(sprite_number: int) -> void:
	var sprite = player_sprite if sprite_number == 1 else enemy_sprite
	
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("bloomThreshold", 0.0)
	mat.set_shader_parameter("bloomIntensity", 0.0)
	
	var tween := create_tween()
	tween.tween_method(
		func(v): mat.set_shader_parameter("bloomIntensity", v),
		0.0, 40.0, 0.15
	).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(v): mat.set_shader_parameter("bloomIntensity", v),
		40.0, 0.0, 0.35
	).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): mat.set_shader_parameter("bloomThreshold", 1.0))

func _on_turn_ended() -> void:
	_refresh_hp_bars()
	new_turn()

func new_turn() -> void:
	_set_battle_buttons_disabled(false)
	move_container.hide()
	if not is_switching:
		MessageBus.send_passive(
			"What will " + BattleSystem.player_participant.display_name() + " do?"
		)

func _set_battle_buttons_disabled(enabled: bool) -> void:
	can_input = not enabled
	for button in action_buttons:
		button.disabled = enabled
		
	for button in move_buttons:
		button.disabled = enabled
		
func _animate_hp(bar: ProgressBar, label: Label, participant: BattleParticipant) -> Tween:
	var start_hp := roundi(bar.value / 100.0 * participant.max_hp())
	var target_percent := participant.hp_percent() * 100.0
	var target_hp := participant.current_hp()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bar, "value", target_percent, 0.4).set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(
		func(hp: int): label.text = str(hp) + "/ " + str(participant.max_hp()),
		start_hp, target_hp, 0.4
	).set_trans(Tween.TRANS_LINEAR)
	return tween

func _set_hp_instant(bar: ProgressBar, label: Label, participant: BattleParticipant) -> void:
	bar.value = participant.hp_percent() * 100.0
	label.text = str(participant.current_hp()) + "/ " + str(participant.max_hp())

## Refreshes and animates just the enemy side
func _refresh_enemy_hp(animated: bool = true) -> Tween:
	var enemy: BattleParticipant = BattleSystem.enemy_participant
	if not enemy:
		return null
	enemy_sprite.texture = enemy.current_mon.get_front_sprite()
	enemy_name_label.text = enemy.display_name() + " Lv." + str(enemy.current_mon.level)
	if animated:
		return _animate_hp(enemy_hp_bar, enemy_hp_label, enemy)
	_set_hp_instant(enemy_hp_bar, enemy_hp_label, enemy)
	return null

## Refreshes and animates just the player side.
func _refresh_player_hp(animated: bool = true) -> Tween:
	var player: BattleParticipant = BattleSystem.player_participant
	if not player:
		return null
	player_sprite.texture = player.current_mon.get_back_sprite()
	player_name_label.text = player.display_name() + " Lv." + str(player.current_mon.level)
	if animated:
		return _animate_hp(player_hp_bar, player_hp_label, player)
	_set_hp_instant(player_hp_bar, player_hp_label, player)
	return null

##refresh both at once
func _refresh_hp_bars(animated: bool = true) -> void:
	_refresh_enemy_hp(animated)
	_refresh_player_hp(animated)
	
func _on_move_executed(_user: BattleParticipant, target: BattleParticipant, _move: MoveInstance, _result: MoveResult) -> void:
	var tween: Tween
	if target == BattleSystem.enemy_participant:
		tween = _refresh_enemy_hp()
	else:
		tween = _refresh_player_hp()

	if tween:
		await tween.finished

func _on_fight_pressed() -> void:
	if not can_input:
		return
	AudioManager.play_sfx("select")
	MessageBus._message_box._clear_passive()
	move_container.show()
	var inst: TecmonInstance = BattleSystem.player_participant.current_mon
	for i in 4:
		var btn: Button = move_buttons[i]
		if i < inst.moves.size():
			var mi: MoveInstance = inst.moves[i]
			btn.text = mi.move.move_name + "  " + str(mi.current_pp) + "/" + str(mi.move.max_pp)
			btn.show()
		else:
			btn.hide()

func _on_move_button_pressed(index: int) -> void:
	var move: MoveInstance = BattleSystem.player_participant.current_mon.moves.get(index)
	if move == null:
		return
	_set_battle_buttons_disabled(true)
	move_container.hide()
	AudioManager.play_sfx("select")
	BattleSystem.queue_move(move)

func _on_tecmons_pressed() -> void:
	if not can_input:
		return
	AudioManager.play_sfx("select")
	_open_sub_ui(tecmon_ui)
	tecmon_ui.open(false)

func _on_items_pressed() -> void:
	if not can_input:
		return
	AudioManager.play_sfx("select")
	_open_sub_ui(item_ui)
	item_ui.open()

func _on_escape_pressed() -> void:
	if not can_input:
		return
	AudioManager.play_sfx("select")
	BattleSystem.queue_flee()

func _open_sub_ui(ui: Control) -> void:
	MessageBus._message_box.hide()
	battle_ui.hide()
	ui.show()

func _close_sub_ui() -> void:
	tecmon_ui.hide()
	item_ui.hide()
	MessageBus._message_box.show()
	battle_ui.show()

func _on_tecmon_switched(index: int) -> void:
	var current_index := BattleSystem.player_participant.party.find(BattleSystem.player_participant.current_mon)
	MessageBus._message_box._clear_passive()
	if index == current_index and not force_switch:
		_close_sub_ui()
		await _say("That Tecmon is already sent out")
		return
		
	BattleSystem.player_participant.switch_to(index)
	_refresh_hp_bars()
	_close_sub_ui()
	player_sprite.hide()
	animation_player.play("tecmon_chosen")
	await _say("You sent out " + BattleSystem.player_participant.display_name() + "!")
	if animation_player.is_playing():
		await animation_player.animation_finished
	animation_player.play("idle")
	
	if not force_switch:
		print("calling skip_turn, phase = ", BattleSystem.phase)
		BattleSystem.skip_turn()
	
	is_switching = false
	force_switch = false
	MessageBus.send_passive("What will " + BattleSystem.player_participant.display_name() + " do?")

func _on_item_used(item: ItemData, _target: TecmonInstance) -> void:
	var outcome := ItemEffect.use_in_battle(item, BattleSystem.player_participant)

	match outcome["result"]:
		ItemEffect.UseResult.SUCCESS:
			Global.player.inventory.remove(item)
			_close_sub_ui()
			_refresh_hp_bars()
			await _say(outcome["message"])
			BattleSystem.skip_turn()

		ItemEffect.UseResult.NEEDS_CAPTURE:
			if BattleSystem.npc_battle:
				_close_sub_ui()
				await _say("Can't capture a Trainer's Tecmon!")
				MessageBus.send_passive("What will " + BattleSystem.player_participant.display_name() + " do?")
			else:
				Global.player.inventory.remove(item)
				_close_sub_ui()
				await BattleSystem.attempt_capture(item)

		_:
			await _say(outcome["message"])

func _say(text: String) -> void:
	MessageBus.send([text])
	_set_battle_buttons_disabled(true)
	await MessageBus.message_box_closed
	_set_battle_buttons_disabled(false)

func _on_force_switch() -> void:
	can_input = true
	_on_turn_ended()
	is_switching = true
	force_switch = true
	MessageBus._message_box._clear_passive()
	_open_sub_ui(tecmon_ui)
	tecmon_ui.open(true)

func _on_battle_ended(outcome: BattleSystem.BattleOutcome) -> void:
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
	AudioManager.play_music(SceneManager.current_level.level_data.bgm)
	await SceneManager._transition_in()
	BattleSystem.stage_closed.emit()
