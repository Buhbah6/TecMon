extends Control

signal tecmon_selected(index: int)
signal back_pressed

@onready var detail_container: VBoxContainer = %TecmonDetailContainer
@onready var swap_texture: TextureRect = %TecmonSwapTexture
@onready var desc: RichTextLabel = %TecmonDesc
@onready var back_button: Button = %BackButton

@export var details_template: PackedScene

var force_switch: bool = false

func _ready() -> void:
	back_button.pressed.connect(func(): back_pressed.emit())

func open(is_force_switch: bool = false) -> void:
	force_switch = is_force_switch
	back_button.disabled = is_force_switch
	back_button.visible = not is_force_switch
	_populate()
	show()

func _populate() -> void:
	for child in detail_container.get_children():
		child.queue_free()

	for tecmon: TecmonInstance in Global.player.tecmon_party:
		var idx := Global.player.tecmon_party.find(tecmon)
		var details = details_template.instantiate()
		details.idx = idx
		detail_container.add_child(details)
		details.get_node("%MiniTecmon").texture = tecmon.data.mini_sprite
		details.get_node("%TecmonName").text = tecmon.display_name()
		details.get_node("%TecmonLvl").text = "Lv." + str(tecmon.level)
		details.get_node("%TecmonHP").text = "HP: " + str(roundi(tecmon.current_hp)) + "/ " + str(roundi(tecmon.max_hp))
		details.tecmon_hp_bar.value = tecmon.hp_percent() * 100
		details.disabled = tecmon.current_hp <= 0
		details.selected.connect(_on_tecmon_selected)
		details.hovered.connect(_on_tecmon_hovered)

	_on_tecmon_hovered(0)

func _on_tecmon_selected(idx: int) -> void:
	tecmon_selected.emit(idx)

func _on_tecmon_hovered(idx: int) -> void:
	var tecmon := Global.player.tecmon_party[idx]
	swap_texture.texture = tecmon.data.front_sprite

	var ailment_text := "None"
	if tecmon.ailments.size() > 0:
		ailment_text = Global.AILMENT_MAP.get(tecmon.ailments[0].type, "Unknown")

	desc.text = "%s\n[%s/%s]\nHP: %d/%d\nAilment: %s" % [
		tecmon.data.tecmon_name,
		Enums.TecmonType.keys()[tecmon.data.type_one],
		Enums.TecmonType.keys()[tecmon.data.type_two],
		roundi(tecmon.current_hp),
		roundi(tecmon.max_hp),
		ailment_text
	]
