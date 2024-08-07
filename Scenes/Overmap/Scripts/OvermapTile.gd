extends Control

const defaultTileData: Dictionary = {"texture": ""}
const defaultTexture: String = "./Scenes/ContentManager/Mapeditor/Images/emptyTile.png"
var tileData: Dictionary = defaultTileData.duplicate():
	set(data):
		tileData = data
		if tileData.texture != "":
			$TextureRect.texture = load("./Mods/Core/OvermapTiles/" + tileData.texture)
		else:
			$TextureRect.texture = load(defaultTexture)
signal tile_clicked(clicked_tile: Control)

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					tile_clicked.emit(self)

func set_texture(res: Resource) -> void:
	if res:
		$TextureRect.texture = res
	else:
		$TextureRect.texture = load(defaultTexture)
		

func set_default() -> void:
	tileData = defaultTileData.duplicate()

func highlight() -> void:
	$TextureRect.modulate = Color(0.227, 0.635, 0.757)
	
func unhighlight() -> void:
	$TextureRect.modulate = Color(1,1,1)
	
func set_color(myColor: Color) -> void:
	$TextureRect.modulate = myColor
	
func set_clickable(clickable: bool):
	if !clickable:
		mouse_filter = MOUSE_FILTER_IGNORE
		$TextureRect.mouse_filter = MOUSE_FILTER_IGNORE


# Useful for alerting the player about this location by using a symbol
func set_text(newtext: String):
	$TextLabel.text = newtext
	$TextLabel.visible = true
	

# Hide or show the textlabel
func set_text_visible(isvisible: bool):
	$TextLabel.visible = isvisible


# Set the rotation of the TextureRect based on the given rotation angle
func set_texture_rotation(myrotation: int) -> void:
	# Set the rotation pivot to the center of the TextureRect
	$TextureRect.pivot_offset = size / 2
	# Set the rotation of the TextureRect based on the given rotation angle
	match myrotation:
		0:
			$TextureRect.rotation_degrees = 0
		90:
			$TextureRect.rotation_degrees = 90
		180:
			$TextureRect.rotation_degrees = 180
		270:
			$TextureRect.rotation_degrees = 270
		_:
			$TextureRect.rotation_degrees = 0  # Default to 0 if an invalid rotation is provided
