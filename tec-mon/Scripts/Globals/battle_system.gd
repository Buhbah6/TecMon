extends Node

signal battle_started
signal battle_ended(outcome: BattleOutcome)
signal turn_ended
signal switch_mon
signal stage_closed
signal move_executed(user: BattleParticipant, target: BattleParticipant, move: MoveInstance, result: MoveResult)

enum BattleOutcome { PLAYER_WIN, PLAYER_FLED, PLAYER_LOST }
enum TurnPhase { IDLE, AWAITING_INPUT, RESOLVING, ENDED }

var player_participant: BattleParticipant
var enemy_participant: BattleParticipant
var player_party: Array[TecmonInstance] = []
var phase: TurnPhase = TurnPhase.IDLE

var _queued_player_move: MoveInstance = null
var _player_is_fleeing: bool = false
var _player_skipping: bool = false

var npc_battle: bool = false
var last_outcome: BattleOutcome = BattleOutcome.PLAYER_WIN

func start_battle(enemy_party: Array[TecmonInstance], party: Array[TecmonInstance], is_npc: bool) -> void:
	player_party = party
	player_participant = BattleParticipant.create(party, true)
	enemy_participant  = BattleParticipant.create(enemy_party, false)
	phase = TurnPhase.AWAITING_INPUT
	npc_battle = is_npc
	battle_started.emit()

func queue_move(move: MoveInstance) -> void:
	if phase != TurnPhase.AWAITING_INPUT:
		return
	_queued_player_move = move
	_player_is_fleeing = false
	execute_turn()

func queue_flee() -> void:
	if phase != TurnPhase.AWAITING_INPUT:
		return
	_player_is_fleeing = true
	execute_turn()

func skip_turn() -> void:
	if phase != TurnPhase.AWAITING_INPUT:
		return
	_queued_player_move = null
	_player_is_fleeing = false
	_player_skipping = true
	execute_turn()

func execute_turn() -> void:
	if phase != TurnPhase.AWAITING_INPUT:
		return
	phase = TurnPhase.RESOLVING

	if _player_is_fleeing:
		if _can_flee():
			_end_battle(BattleOutcome.PLAYER_FLED)
			return
		await _say("You couldn't escape!")

	var enemy_move := _pick_enemy_move()
	var player_first := (
		player_participant.effective_stat(Enums.TecmonStat.SPEED) >=
		enemy_participant.effective_stat(Enums.TecmonStat.SPEED)
	)

	if player_first:
		await _resolve_move(player_participant, enemy_participant, _queued_player_move)
		if not enemy_participant.is_fainted():
			await _resolve_move(enemy_participant, player_participant, enemy_move)
	else:
		await _resolve_move(enemy_participant, player_participant, enemy_move)
		if not player_participant.is_fainted():
			await _resolve_move(player_participant, enemy_participant, _queued_player_move)

	await _resolve_end_of_turn(player_participant)
	await _resolve_end_of_turn(enemy_participant)

	if enemy_participant.is_fainted():
		await _say(enemy_participant.display_name() + " fainted!")
		var next = enemy_participant.next_living()
		if next == null:
			_end_battle(BattleOutcome.PLAYER_WIN)
			return
		enemy_participant.current_mon = next
		enemy_participant.reset_stages()
		await _say("Enemy sent out " + enemy_participant.display_name() + "!")

	if player_participant.is_fainted():
		await _say(player_participant.display_name() + " fainted!")
		var next = player_participant.next_living()
		if next == null:
			_end_battle(BattleOutcome.PLAYER_LOST)
			return
		switch_mon.emit()
		
		return

	_queued_player_move = null
	_player_is_fleeing = false
	_player_skipping = false
	phase = TurnPhase.AWAITING_INPUT
	turn_ended.emit()

func _resolve_move(user: BattleParticipant, target: BattleParticipant, move_inst: MoveInstance) -> void:
	if move_inst == null:
		if user.is_player_side and _player_skipping:
			return
		await _say(user.display_name() + " has no moves left!")
		return

	var blocked_by := user.pre_move_ailment_check()
	if blocked_by != Enums.TecmonAilment.NONE:
		match blocked_by:
			Enums.TecmonAilment.SLEEP: await _say(user.display_name() + " is fast asleep!")
			Enums.TecmonAilment.FREEZE: await _say(user.display_name() + " is frozen solid!")
			Enums.TecmonAilment.PARALYSIS: await _say(user.display_name() + " is paralysed and can't move!")
			Enums.TecmonAilment.CONFUSION:
				await _say(user.display_name() + " is confused and hurt itself!")
				user.take_damage(_calc_confusion_damage(user))
		return

	if not _hit_check(move_inst.move, user, target):
		move_inst.use()
		await _say(user.display_name() + "'s " + move_inst.move.move_name + " missed!")
		return

	move_inst.use()
	await _say(user.display_name() + " used " + move_inst.move.move_name + "!")

	match move_inst.move.move_category:
		MoveResource.MoveCategory.PHYSICAL, MoveResource.MoveCategory.SPECIAL:
			var result := _calc_damage(user, target, move_inst.move)
			target.take_damage(roundi(result.damage))
			move_executed.emit(user, target, move_inst, result)
			if result.is_critical:
				await _say("A critical hit!")
			if result.effectiveness > 1.0:
				await _say("It's super effective!")
			elif 0.0 < result.effectiveness and result.effectiveness < 1.0:
				await _say("It's not very effective...")
		MoveResource.MoveCategory.STATUS:
			move_executed.emit(user, target, move_inst, MoveResult.new())

	await _apply_move_effects(move_inst.move, user, target)

func _apply_move_effects(move: MoveResource, user: BattleParticipant, target: BattleParticipant) -> void:
	if move.ailment != Enums.TecmonAilment.NONE:
		if randf() * 100.0 < move.ailment_chance:
			if target.current_mon.apply_ailment(move.ailment, move.ailment_turns):
				await _say(target.display_name() + " was " + _ailment_label(move.ailment) + "!")
			else:
				await _say("It didn't affect " + target.display_name() + "!")

	for change: StatChange in move.stat_changes:
		var recipient: BattleParticipant = user if change.target == StatChange.Target.SELF else target
		if randf() * 100.0 < change.chance:
			var actual := recipient.modify_stage(change.stat, change.stages)
			await _say(_stat_change_message(recipient, change.stat, actual))

func attempt_capture(item: ItemData) -> void:
	var enemy: TecmonInstance = enemy_participant.current_mon
	var catch_rate := _calc_catch_rate(enemy, item)
 
	if randf() < catch_rate:
		Global.player.tecmon_party.append(enemy)
		await _say("You caught " + enemy.display_name() + "!")
		_end_battle(BattleOutcome.PLAYER_WIN)
	else:
		await _say(enemy.display_name() + " broke free!")
		## Enemy still gets their turn after a failed capture.
		var enemy_move := _pick_enemy_move()
		await _resolve_move(enemy_participant, player_participant, enemy_move)
		await _resolve_end_of_turn(player_participant)
		await _resolve_end_of_turn(enemy_participant)
		if player_participant.is_fainted():
			await _say(player_participant.display_name() + " fainted!")
			_end_battle(BattleOutcome.PLAYER_LOST)
			return
		phase = TurnPhase.AWAITING_INPUT
		turn_ended.emit()
 
func _calc_catch_rate(target: TecmonInstance, item: ItemData) -> float:
	var base_rate: float = target.data.catch_rate / 100.0
	var hp_factor: float = (3.0 * target.max_hp - 2.0 * target.current_hp) / (3.0 * target.max_hp)
	return clamp(base_rate * hp_factor * item.capture_rate_modifier, 0.0, 1.0)

func _resolve_end_of_turn(p: BattleParticipant) -> void:
	if p.is_fainted():
		return
	var events := p.tick_ailments()
	for event in events:
		var ailment_type: Enums.TecmonAilment = event[0]
		var dmg: float = event[1]
		match ailment_type:
			Enums.TecmonAilment.BURN:
				await _say(p.display_name() + " is hurt by its burn!")
			Enums.TecmonAilment.POISON, Enums.TecmonAilment.TOXIC:
				await _say(p.display_name() + " is hurt by poison!")
			Enums.TecmonAilment.SLEEP:
				await _say(p.display_name() + " is fast asleep!")
			Enums.TecmonAilment.FREEZE:
				if dmg == -1.0:
					await _say(p.display_name() + " thawed out!")
				else:
					await _say(p.display_name() + " is frozen solid!")
			Enums.TecmonAilment.CONFUSION:
				if dmg == -1.0:
					await _say(p.display_name() + " snapped out of confusion!")

func _calc_damage(user: BattleParticipant, target: BattleParticipant, move: MoveResource) -> MoveResult:
	var result := MoveResult.new()
	var atk: float
	var def: float
	if move.move_category == MoveResource.MoveCategory.PHYSICAL:
		atk = user.effective_stat(Enums.TecmonStat.ATTACK)
		def = target.effective_stat(Enums.TecmonStat.DEFENSE)
		if user.current_mon.has_ailment(Enums.TecmonAilment.BURN):
			atk *= 0.5
	else:
		atk = user.effective_stat(Enums.TecmonStat.SPECIAL_ATTACK)
		def = target.effective_stat(Enums.TecmonStat.SPECIAL_DEFENSE)
		
	result.is_critical = randf() < 0.0625
	result.effectiveness = _calc_effectiveness(move.move_type, target.current_mon.data)
	var level_factor := (2.0 * user.current_mon.level / 5.0) + 2.0
	var crit_mod := 1.5 if result.is_critical else 1.0
	var raw := (level_factor * move.base_power * (atk / def)) / 50.0 + 2.0
	result.damage = raw * crit_mod * result.effectiveness * randf_range(0.85, 1.0)
	return result

func _calc_effectiveness(move_type: Enums.TecmonType, target_data: TecmonData) -> float:
	var mult := TypeChart.get_multiplier(move_type, target_data.type_one)
	if target_data.type_two != Enums.TecmonType.NONE:
		mult *= TypeChart.get_multiplier(move_type, target_data.type_two)
	return mult

func _calc_confusion_damage(user: BattleParticipant) -> float:
	var level_factor := (2.0 * user.current_mon.level / 5.0) + 2.0
	return (level_factor * 40.0 * (user.current_mon.attack / user.current_mon.defense)) / 50.0 + 2.0

func _hit_check(move: MoveResource, user: BattleParticipant, target: BattleParticipant) -> bool:
	if move.accuracy <= 0:
		return true
	var acc := move.accuracy / 100.0
	acc *= user.effective_stat(Enums.TecmonStat.ACCURACY)
	acc /= target.effective_stat(Enums.TecmonStat.EVASION)
	return randf() < acc

func _can_flee() -> bool:
	if npc_battle:
		return false
	
	var p_spd := player_participant.effective_stat(Enums.TecmonStat.SPEED)
	var e_spd := enemy_participant.effective_stat(Enums.TecmonStat.SPEED)
	return p_spd >= e_spd or randf() < (p_spd * 128.0 / e_spd) / 255.0

func _pick_enemy_move() -> MoveInstance:
	var available := enemy_participant.current_mon.moves.filter(func(m): return m.has_pp())
	return available[randi() % available.size()] if not available.is_empty() else null

func _end_battle(outcome: BattleOutcome) -> void:
	last_outcome = outcome
	phase = TurnPhase.ENDED
	player_participant.reset_battle_state()
	enemy_participant.reset_battle_state()
	battle_ended.emit(outcome)

func _say(text: String) -> void:
	MessageBus.send([text])
	await MessageBus.message_box_closed

func _ailment_label(ailment: Enums.TecmonAilment) -> String:
	match ailment:
		Enums.TecmonAilment.BURN: return "burned"
		Enums.TecmonAilment.FREEZE: return "frozen"
		Enums.TecmonAilment.PARALYSIS: return "paralysed"
		Enums.TecmonAilment.POISON: return "poisoned"
		Enums.TecmonAilment.TOXIC: return "badly poisoned"
		Enums.TecmonAilment.SLEEP: return "put to sleep"
		Enums.TecmonAilment.CONFUSION: return "confused"
		_: return "afflicted"

func _stat_change_message(recipient: BattleParticipant, stat: Enums.TecmonStat, actual_delta: int) -> String:
	if actual_delta == 0:
		var limit := "lower" if actual_delta == 0 else "higher"
		return recipient.display_name() + "'s " + _stat_label(stat) + " won't go any " + limit + "!"
	var magnitude: String
	match abs(actual_delta):
		1: magnitude = ""
		2: magnitude = " sharply"
		_: magnitude = " drastically"
	var direction := ("fell" if actual_delta < 0 else "rose") + magnitude
	return recipient.display_name() + "'s " + _stat_label(stat) + " " + direction + "!"

func _stat_label(stat: Enums.TecmonStat) -> String:
	match stat:
		Enums.TecmonStat.ATTACK: return "Attack"
		Enums.TecmonStat.DEFENSE: return "Defense"
		Enums.TecmonStat.SPECIAL_ATTACK: return "Sp. Atk"
		Enums.TecmonStat.SPECIAL_DEFENSE: return "Sp. Def"
		Enums.TecmonStat.SPEED: return "Speed"
		Enums.TecmonStat.ACCURACY: return "Accuracy"
		Enums.TecmonStat.EVASION: return "Evasion"
		_: return "stat"
