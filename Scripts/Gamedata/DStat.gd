class_name DStat
extends RefCounted

# This class represents a stat with its properties
# Example stat data:
#	{
#		"description": "Represents the character's agility, reflexes, and balance...",
#		"id": "dexterity",
#		"name": "Dexterity",
#		"sprite": "dexterity_32.png"
#	}

# Properties defined in the stat
var id: String
var name: String
var description: String
var spriteid: String
var sprite: Texture
var references: Dictionary = {}
var parent: DStats

# Constructor to initialize stat properties from a dictionary
# data: the data as loaded from json
# myparent: The list containing all stats for this mod
func _init(data: Dictionary, myparent: DStats):
	parent = myparent
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	spriteid = data.get("sprite", "")
	references = data.get("references", {})

# Get data function to return a dictionary with all properties
func get_data() -> Dictionary:
	var data: Dictionary = {
		"id": id,
		"name": name,
		"description": description,
		"sprite": spriteid
	}
	if not references.is_empty():
		data["references"] = references
	return data

# Method to save any changes to the stat back to disk
func save_to_disk():
	parent.save_stats_to_disk()

# Some stat has been changed
# INFO if the stat references other entities, update them here
func changed(_olddata: DStat):
	parent.save_stats_to_disk()

# A stat is being deleted from the data
# We have to remove it from everything that references it
func delete():
	print_debug("No changes needed for stat", id)

# Executes a callable function on each reference of the given type
func execute_callable_on_references_of_type(module: String, type: String, callable: Callable):
	# Check if it contains the specified 'module' and 'type'
	if references.has(module) and references[module].has(type):
		# If the type exists, execute the callable on each ID found under this type
		for ref_id in references[module][type]:
			callable.call(ref_id)
