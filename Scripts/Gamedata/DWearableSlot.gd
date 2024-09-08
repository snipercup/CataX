class_name DWearableSlot
extends RefCounted

# This class represents a wearable slot with its properties
# Example wearable slot data:
#	{
#		"description": "Holds equipment on your torso",
#		"id": "torso",
#		"name": "Torso",
#		"references": {
#			"core": {
#				"items": [
#					"jacket",
#					"tshirt",
#					"sweater"
#				]
#			}
#		},
#		"sprite": "wearableslot_torso_32.png"
#	}

# Properties defined in the wearable slot
var id: String
var name: String
var description: String
var spriteid: String
var sprite: Texture
var references: Dictionary = {}

# Constructor to initialize wearable slot properties from a dictionary
func _init(data: Dictionary):
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

# Method to save any changes to the wearable slot back to disk
func save_to_disk():
	Gamedata.wearableslots.save_wearableslots_to_disk()


# Removes the provided reference from references
func remove_reference(module: String, type: String, refid: String):
	var changes_made = Gamedata.dremove_reference(references, module, type, refid)
	if changes_made:
		Gamedata.wearableslots.save_wearableslots_to_disk()


# Adds a reference to the references list
func add_reference(module: String, type: String, refid: String):
	var changes_made = Gamedata.dadd_reference(references, module, type, refid)
	if changes_made:
		Gamedata.wearableslots.save_wearableslots_to_disk()


# Some wearableslot has been changed
# INFO if the wearableslot reference other entities, update them here
func changed(_olddata: DItemgroup):
	Gamedata.wearableslots.save_wearableslots_to_disk()


# A wearableslot is being deleted from the data
# We have to remove it from everything that references it
func delete():
	var changes: Dictionary = {"made":false}
	
	# This callable will remove this slot from items that reference this slot.
	var myfunc: Callable = func (item_id):
		var item_data: DItem = Gamedata.items.by_id(item_id)
		item_data.wearable = null
		changes.made = true
	# Pass the callable to every item in the wearableslot's references
	# It will call myfunc on every item in wearableslot_data.references.core.items
	execute_callable_on_references_of_type("core", "items", myfunc)
	
	# Save changes to the data file if any changes were made
	if changes.made:
		Gamedata.items.save_items_to_disk()
	else:
		print_debug("No changes needed for item", id)


# Executes a callable function on each reference of the given type
func execute_callable_on_references_of_type(module: String, type: String, callable: Callable):
	# Check if it contains the specified 'module' and 'type'
	if references.has(module) and references[module].has(type):
		# If the type exists, execute the callable on each ID found under this type
		for ref_id in references[module][type]:
			callable.call(ref_id)