extends RefCounted
class_name BattleParticipant

var party: Array[TecmonInstance] = []
var current_mon: TecmonInstance
var is_player_side: bool = false
var all_fainted: bool = false

var stat_stages: Dictionary = {
	Enums.TecmonStat.ATTACK: 0,
	Enums.TecmonStat.DEFENSE: 0,
	Enums.TecmonStat.SPECIAL_ATTACK: 0,
	Enums.TecmonStat.SPECIAL_DEFENSE: 0,
	Enums.TecmonStat.SPEED: 0,
	Enums.TecmonStat.ACCURACY: 0,
	Enums.TecmonStat.EVASION: 0,
}

var is_protected: bool = false
var trapped: bool = false

static func create(p: Array[TecmonInstance], player_side: bool) -> BattleParticipant:
	var bp := BattleParticipant.new()
	bp.party = p
	for mon in p:
		if not mon.is_fainted():
			bp.current_mon = mon
			break
			
	bp.is_player_side = player_side
	return bp

func switch_to(index: int) -> bool:
	if index < 0 or index >= party.size():
		return false
	if party[index].is_fainted():
		return false
	current_mon = party[index]
	reset_stages()
	return true

func next_living() -> TecmonInstance:
	for mon in party:
		if not mon.is_fainted():
			return mon
	return null

func effective_stat(stat: Enums.TecmonStat) -> float:
	var base: float
	match stat:
		Enums.TecmonStat.ATTACK: base = current_mon.attack
		Enums.TecmonStat.DEFENSE: base = current_mon.defense
		Enums.TecmonStat.SPECIAL_ATTACK: base = current_mon.special_attack
		Enums.TecmonStat.SPECIAL_DEFENSE: base = current_mon.special_defense
		Enums.TecmonStat.SPEED: base = current_mon.speed
		_: base = 1.0
	return base * _stage_multiplier(stat)

func _stage_multiplier(stat: Enums.TecmonStat) -> float:
	var stage: int = stat_stages.get(stat, 0)
	if stat in [Enums.TecmonStat.ACCURACY, Enums.TecmonStat.EVASION]:
		return (3.0 + stage) / 3.0 if stage >= 0 else 3.0 / (3.0 - stage)
	else:
		return (2.0 + stage) / 2.0 if stage >= 0 else 2.0 / (2.0 - stage)

func modify_stage(stat: Enums.TecmonStat, delta: int) -> int:
	var current: int = stat_stages.get(stat, 0)
	var new_stage: int = clamp(current + delta, -6, 6)
	stat_stages[stat] = new_stage
	return new_stage - current

func reset_stages() -> void:
	for stat in stat_stages:
		stat_stages[stat] = 0

func is_fainted() -> bool:
	return current_mon.is_fainted()

func display_name() -> String:
	return current_mon.display_name()

func hp_percent() -> float:
	return current_mon.hp_percent()

func current_hp() -> int:
	return roundi(current_mon.current_hp)

func max_hp() -> int:
	return roundi(current_mon.max_hp)

func take_damage(amount: float) -> void:
	current_mon.take_damage(amount)

func tick_ailments() -> Array:
	var events: Array = []
	var to_clear: Array[Enums.TecmonAilment] = []

	for a: ActiveAilment in current_mon.ailments:
		match a.type:
			Enums.TecmonAilment.BURN:
				var dmg := current_mon.max_hp / 16.0
				current_mon.take_damage(dmg)
				events.append([a.type, dmg])
			Enums.TecmonAilment.POISON:
				var dmg := current_mon.max_hp / 8.0
				current_mon.take_damage(dmg)
				events.append([a.type, dmg])
			Enums.TecmonAilment.TOXIC:
				a.toxic_counter += 1
				var dmg := current_mon.max_hp * (a.toxic_counter / 16.0)
				current_mon.take_damage(dmg)
				events.append([a.type, dmg])
			Enums.TecmonAilment.SLEEP:
				a.turns_remaining -= 1
				events.append([a.type, 0.0])
				if a.turns_remaining <= 0:
					to_clear.append(a.type)
			Enums.TecmonAilment.FREEZE:
				if randf() < 0.2:
					to_clear.append(a.type)
					events.append([Enums.TecmonAilment.FREEZE, -1.0])
				else:
					events.append([a.type, 0.0])
			Enums.TecmonAilment.CONFUSION:
				a.turns_remaining -= 1
				if a.turns_remaining <= 0:
					to_clear.append(a.type)
					events.append([Enums.TecmonAilment.CONFUSION, -1.0])

	for t in to_clear:
		current_mon.clear_ailment(t)

	return events

func pre_move_ailment_check() -> Enums.TecmonAilment:
	if current_mon.has_ailment(Enums.TecmonAilment.SLEEP):
		return Enums.TecmonAilment.SLEEP
	if current_mon.has_ailment(Enums.TecmonAilment.FREEZE):
		return Enums.TecmonAilment.FREEZE
	if current_mon.has_ailment(Enums.TecmonAilment.PARALYSIS):
		if randf() < 0.25:
			return Enums.TecmonAilment.PARALYSIS
	if current_mon.has_ailment(Enums.TecmonAilment.CONFUSION):
		var conf := current_mon.get_ailment(Enums.TecmonAilment.CONFUSION)
		if conf and randf() < 0.333:
			return Enums.TecmonAilment.CONFUSION
	return Enums.TecmonAilment.NONE

func reset_battle_state() -> void:
	reset_stages()
	is_protected = false
	trapped = false
	current_mon.clear_ailment(Enums.TecmonAilment.CONFUSION)
