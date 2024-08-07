class_name DFurnitures
extends RefCounted

# There's a D in front of the class name to indicate this class only handles furniture data, nothing more
# This script is intended to be used inside the GameData autoload singleton
# This script handles the list of furnitures. You can access it trough Gamedata.furnitures


var dataPath: String = "./Mods/Core/Furniture/Furniture.json"
var spritePath: String = "./Mods/Core/Furniture/"
var furnituredict: Dictionary = {}
var sprites: Dictionary = {}


func _init():
	load_sprites()
	load_furnitures_from_disk()


# Load all furnituredata from disk into memory
func load_furnitures_from_disk() -> void:
	var furniturelist: Array = Helper.json_helper.load_json_array_file(dataPath)
	for furnitureitem in furniturelist:
		var furniture: DFurniture = DFurniture.new(furnitureitem)
		furniture.sprite = sprites[furniture.spriteid]
		furnituredict[furniture.id] = furniture


# Loads sprites and assigns them to the proper dictionary
func load_sprites() -> void:
	var png_files: Array = Helper.json_helper.file_names_in_dir(spritePath, ["png"])
	for png_file in png_files:
		# Load the .png file as a texture
		var texture := load(spritePath + png_file) 
		# Add the material to the dictionary
		sprites[png_file] = texture


func on_data_changed():
	save_furnitures_to_disk()

# Saves all furnitures to disk
func save_furnitures_to_disk() -> void:
	var save_data: Array = []
	for furniture in furnituredict.values():
		save_data.append(furniture.get_data())
	Helper.json_helper.write_json_file(dataPath, JSON.stringify(save_data, "\t"))


func get_furnitures() -> Dictionary:
	return furnituredict


func duplicate_furniture_to_disk(furnitureid: String, newfurnitureid: String) -> void:
	var furnituredata: Dictionary = furnituredict[furnitureid].get_data().duplicate(true)
	furnituredata.id = newfurnitureid
	var newfurniture: DFurniture = DFurniture.new(furnituredata)
	furnituredict[newfurnitureid] = newfurniture
	save_furnitures_to_disk()


func add_new_furniture(newid: String) -> void:
	var newfurniture: DFurniture = DFurniture.new({"id":newid})
	furnituredict[newfurniture.id] = newfurniture
	save_furnitures_to_disk()


func delete_furniture(furnitureid: String) -> void:
	furnituredict[furnitureid].delete()
	furnituredict.erase(furnitureid)
	save_furnitures_to_disk()


func by_id(furnitureid: String) -> DFurniture:
	return furnituredict[furnitureid]


# Returns the sprite of the furniture
# furnitureid: The id of the furniture to return the sprite of
func sprite_by_id(furnitureid: String) -> Texture:
	return furnituredict[furnitureid].sprite

# Returns the sprite of the furniture
# furnitureid: The id of the furniture to return the sprite of
func sprite_by_file(spritefile: String) -> Texture:
	return sprites[spritefile]


# Removes the reference from the selected furniture
func remove_reference_from_furniture(furnitureid: String, module: String, type: String, refid: String):
	var myfurniture: DFurniture = furnituredict[furnitureid]
	myfurniture.remove_reference(module, type, refid)


# Adds a reference to the references list
# For example, add "grass_field" to references.Core.maps
# furnitureid: The id of the furniture to add the reference to
# module: the mod that the entity belongs to, for example "Core"
# type: The type of entity, for example "maps"
# refid: The id of the entity to reference, for example "grass_field"
func add_reference_to_furniture(furnitureid: String, module: String, type: String, refid: String):
	var myfurniture: DFurniture = furnituredict[furnitureid]
	myfurniture.add_reference(module, type, refid)
