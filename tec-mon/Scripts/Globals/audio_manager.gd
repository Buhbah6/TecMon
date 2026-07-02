extends Node

@export var sfx_pool: Array[SoundEffect]

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var last_played: Dictionary = {}

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	for i in sfx_pool.size():
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
		
func play_music(stream: AudioStream, volume_db: float = 0.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = -30
	music_player.play()
	
func stop_music() -> void:
	music_player.stop()
	
func get_audio_stream(tag: String) -> SoundEffect:
	var matches: Array[SoundEffect] = []
	
	for sound in sfx_pool:
		if sound.tag == tag:
			matches.append(sound)
	
	if matches.is_empty():
		return null
	
	# If only one variant exists, return it
	if matches.size() == 1:
		last_played[tag] = matches[0]
		return matches[0]
	
	# If more than one variant exists, pick randomly but avoid immediate repeats
	var choice: SoundEffect
	var last_for_this_tag = last_played.get(tag, null)
	
	# Remove the last played variant from options (if it exists)
	if last_for_this_tag != null and last_for_this_tag in matches:
		var filtered_matches = matches.filter(func(s): return s != last_for_this_tag)
		# Only use filtered list if we still have options
		if not filtered_matches.is_empty():
			choice = filtered_matches.pick_random()
		else:
			# Fallback if somehow all matches are the same
			choice = matches.pick_random()
	else:
		choice = matches.pick_random()
	
	last_played[tag] = choice
	return choice
	
func play_sfx(tag: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	
	var sfx : SoundEffect = get_audio_stream(tag)
	var stream = sfx.audio_stream
	var player := _get_free_sfx_player()

	if player == null:
		return

	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	
func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	
	return sfx_players[0]
	
func set_music_volume(value: float) -> void:
	_set_bus_volume("Music", value)

func set_sfx_volume(value: float) -> void:
	_set_bus_volume("SFX", value)

func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	value = clamp(value, 0.0, 1.0)

	if value == 0.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
