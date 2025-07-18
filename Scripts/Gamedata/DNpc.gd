class_name DNpc
extends RefCounted

# JSON fields for an NPC:
# {
#     "id": "hank",
#     "name": "Hank",
#     "description": "Friendly wanderer",
#     "sprite": "hank.png",
#     "health": 100
# }

var id: String
var name: String
var description: String
var spriteid: String
var sprite: Texture
var health: int = 100
var parent: DNpcs
var spawn_maps: Array = []


func _init(data: Dictionary, myparent: DNpcs):
	parent = myparent
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	spriteid = data.get("sprite", "")
	health = data.get("health", 100)
	spawn_maps = data.get("spawn_maps", [])


func get_data() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"sprite": spriteid,
		"health": health,
		"spawn_maps": spawn_maps
	}


# Persist this NPC to disk through the parent container
func save_to_disk():
	parent.save_npcs_to_disk()

	# Data has changed; propagate save to parent container


func changed(_olddata: DNpc):
	parent.save_npcs_to_disk()


# Delete handler - currently no references to clean up
func delete():
	parent.save_npcs_to_disk()
