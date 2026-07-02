extends RefCounted
class_name ItemEffect

enum UseResult {
	SUCCESS,
	FAILED,
	NOT_FAINTED,
	IS_FAINTED,
	NEEDS_CAPTURE,
}

static func use_on_instance(item: ItemData, target: TecmonInstance) -> Dictionary:
	match item.effect:
		ItemData.Effect.RESTORE_HP:
			if target.is_fainted():
				return _fail(UseResult.IS_FAINTED, "A fainted Tecmon can't use this!")
			if target.current_hp >= target.max_hp:
				return _fail(UseResult.FAILED, target.display_name() + "'s HP is already full!")
			target.heal(item.hp_amount)
			return _ok(target.display_name() + "'s HP was restored.")

		ItemData.Effect.RESTORE_HP_FULL:
			if target.is_fainted():
				return _fail(UseResult.IS_FAINTED, "A fainted Tecmon can't use this!")
			if target.current_hp >= target.max_hp:
				return _fail(UseResult.FAILED, target.display_name() + "'s HP is already full!")
			target.heal(target.max_hp)
			return _ok(target.display_name() + "'s HP was fully restored.")

		ItemData.Effect.RESTORE_PP:
			return _fail(UseResult.FAILED, "Pick a move to restore.")

		ItemData.Effect.RESTORE_PP_ALL:
			if target.is_fainted():
				return _fail(UseResult.IS_FAINTED, "A fainted Tecmon can't use this!")
			for m: MoveInstance in target.moves:
				m.restore()
			return _ok("All of " + target.display_name() + "'s moves had their PP restored.")

		ItemData.Effect.CURE_AILMENT:
			if not target.has_ailment(item.target_ailment):
				return _fail(UseResult.FAILED, target.display_name() + " doesn't have that condition.")
			target.clear_ailment(item.target_ailment)
			return _ok(target.display_name() + " was cured!")

		ItemData.Effect.CURE_ALL_AILMENTS:
			if target.ailments.is_empty():
				return _fail(UseResult.FAILED, target.display_name() + " has no conditions.")
			target.clear_all_ailments()
			return _ok(target.display_name() + " was fully cured!")

		ItemData.Effect.REVIVE:
			if not target.is_fainted():
				return _fail(UseResult.NOT_FAINTED, target.display_name() + " hasn't fainted!")
			target.heal(target.max_hp * 0.5)
			return _ok(target.display_name() + " was revived!")

		ItemData.Effect.REVIVE_FULL:
			if not target.is_fainted():
				return _fail(UseResult.NOT_FAINTED, target.display_name() + " hasn't fainted!")
			target.heal(target.max_hp)
			return _ok(target.display_name() + " was fully revived!")

	return _fail(UseResult.FAILED, "Nothing happened.")

static func use_in_battle(item: ItemData, participant: BattleParticipant) -> Dictionary:
	match item.effect:
		ItemData.Effect.CAPTURE:
			return { "result": UseResult.NEEDS_CAPTURE, "message": "" }

		ItemData.Effect.STAT_INCREASE:
			var actual := participant.modify_stage(item.stat_target, item.stat_stages)
			if actual == 0:
				return _fail(UseResult.FAILED, participant.display_name() + "'s stat won't go any higher!")
			return _ok(participant.display_name() + "'s " + _stat_label(item.stat_target) + " rose!")

		_:
			return use_on_instance(item, participant.current_mon)

static func use_pp_restore(item: ItemData, target: TecmonInstance, move_slot: int) -> Dictionary:
	if move_slot < 0 or move_slot >= target.moves.size():
		return _fail(UseResult.FAILED, "No move in that slot.")
	var m: MoveInstance = target.moves[move_slot]
	if m.current_pp >= m.move.max_pp:
		return _fail(UseResult.FAILED, m.move.move_name + "'s PP is already full!")
	m.restore(int(item.hp_amount) if item.hp_amount > 0 else -1)
	return _ok(m.move.move_name + "'s PP was restored.")

static func _ok(msg: String) -> Dictionary:
	return { "result": UseResult.SUCCESS, "message": msg }

static func _fail(result: UseResult, msg: String) -> Dictionary:
	return { "result": result, "message": msg }

static func _stat_label(stat: Enums.TecmonStat) -> String:
	match stat:
		Enums.TecmonStat.ATTACK: return "Attack"
		Enums.TecmonStat.DEFENSE: return "Defense"
		Enums.TecmonStat.SPECIAL_ATTACK: return "Sp. Atk"
		Enums.TecmonStat.SPECIAL_DEFENSE: return "Sp. Def"
		Enums.TecmonStat.SPEED: return "Speed"
		_: return "stat"
