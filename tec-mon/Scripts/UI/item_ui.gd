extends Control

signal item_used(item: ItemData, target: TecmonInstance)
signal back_pressed

@onready var detail_container: VBoxContainer = %ItemDetailContainer
@onready var swap_texture: TextureRect = %ItemSwapTexture
@onready var desc: RichTextLabel = %ItemDesc

@export var details_template: PackedScene
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(func(): back_pressed.emit())

func open() -> void:
	_populate()
	show()

func _populate() -> void:
	for child in detail_container.get_children():
		child.queue_free()

	var inventory: Inventory = Global.player.inventory
	var items := inventory.all_items()
	if items.is_empty():
		return

	for item: ItemData in items:
		var details = details_template.instantiate() as Button
		details.item = item
		details.item_amount = inventory.quantity(item)
		detail_container.add_child(details)
		details.get_node("%ItemName").text = item.item_name
		details.get_node("%ItemCount").text = "x" + str(inventory.quantity(item))
		details.unselected.connect(_on_item_unselected.bind(details))
		details.selected.connect(_on_item_selected)
		details.hovered.connect(_on_item_hovered)
		details.used.connect(_on_item_used)
	_on_item_hovered(detail_container.get_child(0).item)

func _on_item_used(item: ItemData) -> void:
	var target: TecmonInstance
	if item.effect == ItemData.Effect.CAPTURE:
		target = BattleSystem.enemy_participant.current_mon
	else:
		Global.player.tecmon_party[0]
		
	item_used.emit(item, target)

func _on_item_selected() -> void:
	for child in detail_container.get_children():
		child.disabled = true

func _on_item_hovered(item: ItemData) -> void:
	swap_texture.texture = item.icon
	desc.text = "%s\n%s" % [item.item_name, item.description]

func _on_item_unselected(_button: Button) -> void:
	for child in detail_container.get_children():
		child.disabled = false
