class_name RNpc
extends RefCounted

var id: String
var name: String
var description: String
var spriteid: String
var sprite: Texture
var health: int
var parent: RNpcs

func _init(myparent: RNpcs, newid: String):
	parent = myparent
	id = newid

func overwrite_from_dnpc(dnpc: DNpc) -> void:
	if id != dnpc.id:
		print_debug("Cannot overwrite from a different id")
	name = dnpc.name
	description = dnpc.description
	spriteid = dnpc.spriteid
	sprite = dnpc.sprite
	health = dnpc.health

func get_data() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"sprite": spriteid,
		"health": health
	}
