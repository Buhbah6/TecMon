extends StaticBody2D

var _tecmons: Array[TecmonData]
var dir_path: String = "res://TecMons/"

@onready var button_list: VBoxContainer = %ButtonList
@onready var ui: Control = %UI
@onready var lvl_box: SpinBox = %LvlBox
@onready var nickname_box: LineEdit = %Nickname
@onready var back_button: Button = %BackButton

var buttons: Array[Button]

func _ready() -> void:
	ui.hide()
	_register_all()
	
func interact(_player: Player) -> void:
	if ui.visible:
		return
	AudioManager.play_sfx("open_chest")
	Global.set_movement_blocked(true)
	ui.show()
	populate_list()

func clear_list():
	for button in button_list.get_children():
		button.queue_free()
		buttons.erase(button)
		
func populate_list() -> void:
	clear_list()
	for tecmon in _tecmons:
		var button := Button.new()
		button.text = tecmon.tecmon_name
		button.pressed.connect(_on_button_pressed.bind(button))
		button_list.add_child(button)
		buttons.append(button)

func _on_button_pressed(button: Button):
	var tecmon: TecmonData = get_tecmon(button.text)
	var lvl: int = roundi(lvl_box.value)
	var nickname: String = nickname_box.text
	
	
	if Global.player.tecmon_party.size() == 6:
		return
		
	Global.player.tecmon_party.push_front(TecmonInstance.create(tecmon, lvl, nickname, false))
	var tecmon_instance: TecmonInstance = Global.player.tecmon_party.get(0)
	
	MessageBus.send(["Spawned lv." + str(lvl) + " " + tecmon.tecmon_name + " with nickname " + tecmon_instance.display_name()])
	
	back_button.disabled = true
	for i in buttons:
		i.disabled = true
		
	await MessageBus.message_box_closed
	
	for i in buttons:
		i.disabled = false
	back_button.disabled = false
	Global.set_movement_blocked(true)

	
func _register_all() -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.get_extension() == "tres":
			var res: TecmonData = load(dir_path + file)
			if res is TecmonData:
				_tecmons.append(res)
		file = dir.get_next()
	_tecmons.sort_custom(func(a, b): return a.id < b.id)

func get_tecmon(tecmon_name: String) -> TecmonData:
	for t in _tecmons:
		if t.tecmon_name == tecmon_name:
			return t
	return null

func get_all() -> Array:
	return _tecmons

func _on_back_button_pressed() -> void:
	ui.hide()
	Global.set_movement_blocked(false)
