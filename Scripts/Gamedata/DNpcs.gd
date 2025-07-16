class_name DNpcs
extends RefCounted

var npc_path: String = "./Mods/Core/Npcs/"
var npcdict: Dictionary = {}
var sprites: Dictionary = {}
var mod_id: String = "Core"

func _init(new_mod_id: String) -> void:
	mod_id = new_mod_id
	npc_path = "./Mods/" + mod_id + "/Npcs/"
	load_sprites()
	load_npcs_from_disk()

func load_sprites() -> void:
	var png_files: Array = Helper.json_helper.file_names_in_dir(npc_path, ["png"])
	for png_file in png_files:
		sprites[png_file] = load(npc_path + png_file)

func load_npcs_from_disk() -> void:
	var json_files: Array = Helper.json_helper.file_names_in_dir(npc_path, ["json"])
	for json_file in json_files:
		var npc_list: Array = Helper.json_helper.load_json_array_file(npc_path + json_file)
		for npc_data in npc_list:
			var npc: DNpc = DNpc.new(npc_data, self)
			if npc.spriteid:
				npc.sprite = sprites.get(npc.spriteid, null)
			npcdict[npc.id] = npc

func get_all() -> Dictionary:
	return npcdict

func by_id(npcid: String) -> DNpc:
	return npcdict[npcid]

func has_id(npcid: String) -> bool:
	return npcdict.has(npcid)

func sprite_by_id(npcid: String) -> Texture:
	return npcdict[npcid].sprite

func sprite_by_file(spritefile: String) -> Texture:
	return sprites.get(spritefile, null)
