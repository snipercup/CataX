extends Control

@export var npcImageDisplay: TextureRect
@export var IDTextLabel: Label
@export var PathTextLabel: Label
@export var NameTextEdit: TextEdit
@export var DescriptionTextEdit: TextEdit
@export var healthSpinBox: SpinBox
@export var npcSelector: Popup

signal data_changed()

var olddata: DNpc
var dnpc: DNpc:
	set(value):
		dnpc = value
		load_npc_data()
		npcSelector.sprites_collection = dnpc.parent.sprites
		olddata = DNpc.new(dnpc.get_data().duplicate(true), dnpc.parent)

func load_npc_data() -> void:
	if dnpc.spriteid != "":
		npcImageDisplay.texture = dnpc.sprite
		PathTextLabel.text = dnpc.spriteid
	IDTextLabel.text = str(dnpc.id)
	NameTextEdit.text = dnpc.name
	DescriptionTextEdit.text = dnpc.description
	healthSpinBox.value = dnpc.health

func _on_close_button_button_up() -> void:
	queue_free()

func _on_save_button_button_up() -> void:
	dnpc.spriteid = PathTextLabel.text
	dnpc.name = NameTextEdit.text
	dnpc.description = DescriptionTextEdit.text
	dnpc.sprite = npcImageDisplay.texture
	dnpc.health = int(healthSpinBox.value)
	dnpc.save_to_disk()
	data_changed.emit()
	olddata = DNpc.new(dnpc.get_data().duplicate(true), dnpc.parent)

func _on_npc_image_display_gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed:
		npcSelector.show()

func _on_sprite_selector_sprite_selected_ok(clicked_sprite) -> void:
	var npcTexture: Resource = clicked_sprite.get_texture()
	npcImageDisplay.texture = npcTexture
	PathTextLabel.text = npcTexture.resource_path.get_file()
