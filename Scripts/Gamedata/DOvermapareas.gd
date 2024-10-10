class_name DOvermapareas
extends RefCounted

# There's a D in front of the class name to indicate this class only handles overmapareas data, nothing more
# This script is intended to be used inside the GameData autoload singleton
# This script handles the list of overmapareas. You can access it through Gamedata.overmapareas

# Paths for overmapareas data and sprites
var dataPath: String = "./Mods/Core/Overmapareas/Overmapareas.json"
var overmapareadict: Dictionary = {}

# Constructor
func _init():
	load_overmapareas_from_disk()

# Load all overmapareas data from disk into memory
func load_overmapareas_from_disk() -> void:
	var overmapareaslist: Array = Helper.json_helper.load_json_array_file(dataPath)
	for myovermaparea in overmapareaslist:
		var overmaparea: DOvermaparea = DOvermaparea.new(myovermaparea)
		overmapareadict[overmaparea.id] = overmaparea

# Called when data changes and needs to be saved
func on_data_changed():
	save_overmapareas_to_disk()

# Saves all overmapareas to disk
func save_overmapareas_to_disk() -> void:
	var save_data: Array = []
	for overmaparea in overmapareadict.values():
		save_data.append(overmaparea.get_data())
	Helper.json_helper.write_json_file(dataPath, JSON.stringify(save_data, "\t"))

# Returns the dictionary containing all overmapareas
func get_all() -> Dictionary:
	return overmapareadict

# Duplicates a overmaparea and saves it to disk with a new ID
func duplicate_to_disk(overmapareaid: String, newovermapareaid: String) -> void:
	var overmapareadata: Dictionary = by_id(overmapareaid).get_data().duplicate(true)
	# A duplicated overmaparea is brand new and can't already be referenced by something
	# So we delete the references from the duplicated data if it is present
	overmapareadata.erase("references")
	overmapareadata.id = newovermapareaid
	var newovermaparea: DOvermaparea = DOvermaparea.new(overmapareadata)
	overmapareadict[newovermapareaid] = newovermaparea
	save_overmapareas_to_disk()

# Adds a new overmaparea with a given ID
func add_new(newid: String) -> void:
	var newovermaparea: DOvermaparea = DOvermaparea.new({"id": newid})
	overmapareadict[newovermaparea.id] = newovermaparea
	save_overmapareas_to_disk()

# Deletes a overmaparea by its ID and saves changes to disk
func delete_by_id(overmapareaid: String) -> void:
	overmapareadict[overmapareaid].delete()
	overmapareadict.erase(overmapareaid)
	save_overmapareas_to_disk()

# Returns a overmaparea by its ID
func by_id(overmapareaid: String) -> DOvermaparea:
	return overmapareadict[overmapareaid]

# Checks if a overmaparea exists by its ID
func has_id(overmapareaid: String) -> bool:
	return overmapareadict.has(overmapareaid)

# Returns the sprite of the overmaparea
func sprite_by_id(overmapareaid: String) -> Texture:
	return overmapareadict[overmapareaid].sprite

# Removes a reference from the selected overmaparea
func remove_reference(overmapareaid: String, module: String, type: String, refid: String):
	var myovermaparea: DOvermaparea = overmapareadict[overmapareaid]
	myovermaparea.remove_reference(module, type, refid)

# Adds a reference to the references list in the overmaparea
func add_reference(overmapareaid: String, module: String, type: String, refid: String):
	var myovermaparea: DOvermaparea = overmapareadict[overmapareaid]
	myovermaparea.add_reference(module, type, refid)

# Helper function to update references if they have changed
func update_reference(old: String, new: String, type: String, refid: String) -> void:
	if old == new:
		return  # No change detected, exit early

	# Remove from old group if necessary
	if old != "":
		remove_reference(old, "core", type, refid)
	if new != "":
		add_reference(new, "core", type, refid)