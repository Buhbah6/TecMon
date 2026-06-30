extends Button

var idx : float
signal selected()

func _on_tecmon_details_pressed() -> void:
	if BattleSystem.player_participant and BattleSystem.enemy_participant:
		BattleSystem.player_participant.current_mon = BattleSystem.player_participant.party[idx]
		selected.emit()
	
