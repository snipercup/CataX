class_name DMap
extends RefCounted

# There's a D in front of the class name to indicate this class only handles map data, nothing more
# This script is intended to be used inside the GameData autoload singleton
# This script handles data for one map. You can access it trough Gamedata.mods.by_id("Core").maps

# Example map data:
#{
#	"areas": [
#	{
#		"id": "base_layer",
#		"rotate_random": false,
#		"spawn_chance": 100,
#		"tiles": [
#			{ "id": "grass_plain_01", "count": 100 },
#			{ "id": "grass_dirt_00", "count": 15 }
#		],
#		"entities": []
#	},
#	{
#		"id": "sparse_trees",
#		"rotate_random": true,
#		"spawn_chance": 30,
#		"tiles": [
#			{ "id": "null", "count": 1000 }
#		],
#		"entities": [
#			{ "id": "Tree_00", "type": "furniture", "count": 1 },
#			{ "id": "WillowTree_00", "type": "furniture", "count": 1 }
#		]
#	},
#	{
#		"id": "generic_field_finds",
#		"rotate_random": false,
#		"spawn_chance": 50,
#		"tiles": [
#			{ "id": "null", "count": 500 }
#		],
#		"entities": [
#			{ "id": "generic_field_finds", "type": "itemgroup", "count": 1 }
#		]
#	}
#	],
#	"categories": ["Field", "Plains"],
#	"connections": {
#	"north": "ground",
#	"south": "ground",
#	"east": "ground",
#	"west": "ground"
#	},
#	"description": "A simple and vast field covered with green grass, perfect for beginners.",
#	"id": "field_grass_basic_00",
#	"levels": [
#		[], [], [], [], [], [], [], [], [], [],
#	[
#		{
#		"id": "grass_medium_dirt_01",
#		"rotation": 180,
#		"areas": [
#			{ "id": "base_layer", "rotation": 0 },
#			{ "id": "sparse_trees", "rotation": 0 },
#			{ "id": "generic_field_finds", "rotation": 0 }
#		]
#		},
#		{
#		"id": "grass_plain_01",
#		"rotation": 90,
#		"areas": [
#			{ "id": "base_layer", "rotation": 0 },
#			{ "id": "sparse_trees", "rotation": 0 },
#			{ "id": "generic_field_finds", "rotation": 0 }
#		]
#		}
#	]
#	],
#	"mapheight": 32,
#	"mapwidth": 32,
#	"name": "Basic Grass Field"
#	"weight": 1000
#}

var id: String = "":
	set(newid):
		id = newid.replace(".json", "")  # In case the filename is passed, we remove json
var name: String = ""
var description: String = ""
var categories: Array = []  # example: "categories": ["Buildings","Urban","City"]
var weight: int = 1000
var mapwidth: int = 32
var mapheight: int = 32
var levels: Array = [
	[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []
]
var areas: Array = []
var rooms: Array = []
var room_connections: Array = []
var room_boundaries: Array = []
var buildings: Array = []
var building_surfaces: Array = []
var building_supports: Array = []
var building_compositions: Array = []
var road_endpoints: Array = []
var sprite: Texture = null
# Variable to store connections. For example: {"south": "road","west": "ground"} default to ground
var connections: Dictionary = {
	"north": "ground", "east": "ground", "south": "ground", "west": "ground"
}
var dataPath: String
var parent: DMaps


# The area that may be present on the map
# TODO: Implement this into the script
class area:
	var entities: Array = []
	var id: String = ""
	var rotate_random: bool = false
	var spawn_chance: int = 100
	var tiles: Array = []


# Definition of a tile on the map, in one of the levels
# TODO: Implement this into the script
class maptile:
	# Only a reference to an area, not an instance of an area. Can have "id" and "rotation"
	var areas: Array = []
	var id: String = ""  # The id of the tile
	var rotation: int = 0
	# Unified feature structure for this tile. Holds furniture, mobs, mobgroups
	# and itemgroups in a single dictionary.
	var feature: Dictionary = {}


func _init(newid: String, newdataPath: String, myparent: DMaps):
	id = newid
	dataPath = newdataPath
	parent = myparent


func set_data(newdata: Dictionary) -> void:
	name = newdata.get("name", "")
	description = newdata.get("description", "")
	categories = newdata.get("categories", [])
	weight = newdata.get("weight", 1000)
	mapwidth = newdata.get("mapwidth", 32)
	mapheight = newdata.get("mapheight", 32)
	# Convert legacy level data to the unified feature dictionary
	levels = _convert_levels_legacy_to_feature(
		newdata.get(
			"levels",
			[[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []]
		)
	)
	areas = newdata.get("areas", [])
	rooms = newdata.get("rooms", [])
	room_connections = newdata.get("room_connections", [])
	room_boundaries = newdata.get("room_boundaries", [])
	buildings = newdata.get("buildings", [])
	building_surfaces = newdata.get("building_surfaces", [])
	building_supports = newdata.get("building_supports", [])
	building_compositions = newdata.get("building_compositions", [])
	road_endpoints = newdata.get("road_endpoints", [])
	connections = newdata.get("connections", {})  # Set connections from data if present


func get_data() -> Dictionary:
	var mydata: Dictionary = {}
	mydata["id"] = id
	mydata["name"] = name
	mydata["description"] = description
	if not categories.is_empty():
		mydata["categories"] = categories
	mydata["weight"] = weight
	mydata["mapwidth"] = mapwidth
	mydata["mapheight"] = mapheight
	# Strip empty feature entries when saving
	mydata["levels"] = _convert_levels_feature_for_save(levels)
	if not areas.is_empty():
		mydata["areas"] = areas
	if not rooms.is_empty():
		mydata["rooms"] = rooms
	if not room_connections.is_empty():
		mydata["room_connections"] = room_connections
	if not room_boundaries.is_empty():
		mydata["room_boundaries"] = room_boundaries
	if not buildings.is_empty():
		mydata["buildings"] = buildings
	if not building_surfaces.is_empty():
		mydata["building_surfaces"] = building_surfaces
	if not building_supports.is_empty():
		mydata["building_supports"] = building_supports
	if not building_compositions.is_empty():
		mydata["building_compositions"] = building_compositions
	if not road_endpoints.is_empty():
		mydata["road_endpoints"] = road_endpoints
	if not connections.is_empty():  # Omit connections if empty
		mydata["connections"] = connections
	
	# Sanitize tile-level area references to remove stale editor artifacts
	_sanitize_area_references(mydata)
	_sanitize_room_references(mydata)
	_sanitize_room_connections(mydata)
	_sanitize_room_boundaries(mydata)
	_sanitize_buildings(mydata)
	_sanitize_building_surfaces(mydata)
	_sanitize_building_supports(mydata)
	_sanitize_building_compositions(mydata)
	_sanitize_road_endpoints(mydata)

	# NEW: Implement sanitization for corrupt tiles (missing or empty ID when metadata exists)
	_sanitize_tile_objects(mydata)
	
	return mydata

func _sanitize_tile_objects(data: Dictionary) -> void:
	if not data.has("levels") or not data["levels"] is Array:
		return
			
	for level in data["levels"]:
		if not level is Array:
			continue
		for i in range(level.size()):
			var tile = level[i]
			if tile is Dictionary and tile.size() > 0:
				# Criteria for corruption: contains metadata but no valid, non-empty ID
				if not tile.has("id") or tile["id"].is_empty() or tile["id"].strip_edges().is_empty():
					level[i] = {} # Replace with empty dictionary (air tile)


func _sanitize_area_references(data: Dictionary) -> void:
	var valid_area_ids: Array[String] = []
	if data.has("areas") and data["areas"] is Array:
		for area in data["areas"]:
			if area is Dictionary and area.has("id"):
				valid_area_ids.append(area["id"])
	
	if not data.has("levels") or not data["levels"] is Array:
		return

	var removed_count: int = 0
	for level in data["levels"]:
		if not level is Array:
			continue
		for tile in level:
			if tile is Dictionary and tile.has("areas") and tile["areas"] is Array:
				var original_count = tile["areas"].size()
				tile["areas"] = tile["areas"].filter(func(ref): 
					return ref is Dictionary and ref.has("id") and ref["id"] in valid_area_ids
				)
				if tile["areas"].size() < original_count:
					removed_count += (original_count - tile["areas"].size())
				
				if tile["areas"].is_empty():
					tile.erase("areas")
	
	if removed_count > 0:
		print("[DMap] Sanitized %d stale area references during data retrieval" % removed_count)


func _sanitize_room_references(data: Dictionary) -> void:
	var valid_room_ids: Array[String] = []
	if data.has("rooms") and data["rooms"] is Array:
		for room in data["rooms"]:
			if room is Dictionary and room.has("id"):
				valid_room_ids.append(room["id"])

	if not data.has("levels") or not data["levels"] is Array:
		return

	for level in data["levels"]:
		if not level is Array:
			continue
		for tile in level:
			if tile is Dictionary and tile.has("rooms") and tile["rooms"] is Array:
				tile["rooms"] = tile["rooms"].filter(func(room_id):
					return room_id is String and room_id in valid_room_ids
				)
				if tile["rooms"].is_empty():
					tile.erase("rooms")


func _sanitize_room_connections(data: Dictionary) -> void:
	if not data.has("room_connections") or not data["room_connections"] is Array:
		return

	var valid_room_ids: Array[String] = []
	if data.has("rooms") and data["rooms"] is Array:
		for room in data["rooms"]:
			if room is Dictionary and room.has("id") and room["id"] is String:
				valid_room_ids.append(room["id"])

	data["room_connections"] = data["room_connections"].filter(func(connection):
		if not connection is Dictionary or not connection.has("from") or not connection.has("to"):
			return false
		for endpoint in [connection["from"], connection["to"]]:
			if not endpoint is Dictionary or not endpoint.has("kind"):
				return false
			if endpoint["kind"] == "room":
				if not endpoint.has("id") or not endpoint["id"] is String or endpoint["id"] not in valid_room_ids:
					return false
			elif endpoint["kind"] != "exterior":
				return false
		return true
	)
	if data["room_connections"].is_empty():
		data.erase("room_connections")


func _sanitize_room_boundaries(data: Dictionary) -> void:
	if not data.has("room_boundaries") or not data["room_boundaries"] is Array:
		return

	var valid_room_ids: Array[String] = []
	if data.has("rooms") and data["rooms"] is Array:
		for room in data["rooms"]:
			if room is Dictionary and room.has("id") and room["id"] is String:
				valid_room_ids.append(room["id"])

	data["room_boundaries"] = data["room_boundaries"].filter(func(boundary):
		return boundary is Dictionary \
			and boundary.has("room") \
			and boundary["room"] is String \
			and boundary["room"] in valid_room_ids
	)
	if data["room_boundaries"].is_empty():
		data.erase("room_boundaries")


func _sanitize_buildings(data: Dictionary) -> void:
	if not data.has("buildings") or not data["buildings"] is Array:
		return

	var valid_room_ids: Array[String] = []
	if data.has("rooms") and data["rooms"] is Array:
		for room in data["rooms"]:
			if room is Dictionary and room.has("id") and room["id"] is String:
				valid_room_ids.append(room["id"])

	var valid_connection_ids: Array[String] = []
	if data.has("room_connections") and data["room_connections"] is Array:
		for connection in data["room_connections"]:
			if connection is Dictionary and connection.has("id") and connection["id"] is String:
				valid_connection_ids.append(connection["id"])

	data["buildings"] = data["buildings"].filter(func(building):
		if not building is Dictionary \
			or not building.has("id") \
			or not building["id"] is String \
			or building["id"].is_empty() \
			or not building.has("rooms") \
			or not building["rooms"] is Array \
			or building["rooms"].is_empty() \
			or not building.has("footprint") \
			or not building["footprint"] is Dictionary \
			or not building.has("z") \
			or not building["z"] is int:
			return false
		if building.has("building_levels"):
			if not building["building_levels"] is Array or building["building_levels"].is_empty() or building["z"] != 0:
				return false
			var previous_level_z: int = -1
			for level_definition in building["building_levels"]:
				if not level_definition is Dictionary \
				or not level_definition.has("z") \
				or not level_definition["z"] is int \
				or level_definition["z"] < 0 \
				or level_definition["z"] > 10 \
				or level_definition["z"] % 2 != 0 \
				or level_definition["z"] <= previous_level_z:
					return false
				if level_definition.keys().size() > 3 \
				or (level_definition.has("rooms") and not level_definition["rooms"] is Array) \
				or (level_definition.has("furniture_anchors") and not level_definition["furniture_anchors"] is Array):
					return false
				if level_definition.has("rooms"):
					for room_id in level_definition["rooms"]:
						if not room_id is String or room_id not in building["rooms"]:
							return false
				if level_definition.has("furniture_anchors"):
					var level_anchor_ids: Array = []
					for anchor_id in level_definition["furniture_anchors"]:
						if not anchor_id is String or anchor_id.is_empty() or anchor_id in level_anchor_ids:
							return false
						level_anchor_ids.append(anchor_id)
				previous_level_z = level_definition["z"]
			if building["building_levels"][0].get("z") != 0:
				return false
		if building.has("staircases"):
			if not building["staircases"] is Array or building["staircases"].is_empty() or not building.has("building_levels"):
				return false
			var staircase_ids: Array = []
			for staircase in building["staircases"]:
				if not staircase is Dictionary \
				or not staircase.keys().all(func(key): return key in ["id", "lower_at", "upper_at", "rotation", "upper_rotation", "landing_at"]) \
				or not staircase.has("id") \
				or not staircase["id"] is String \
				or staircase["id"].is_empty() \
				or staircase["id"] in staircase_ids \
				or not staircase.has("lower_at") \
				or not staircase["lower_at"] is Array \
				or staircase["lower_at"].size() != 2 \
				or not staircase.has("upper_at") \
				or not staircase["upper_at"] is Array \
				or staircase["upper_at"].size() != 2 \
				or not staircase.has("rotation") \
				or not staircase["rotation"] is int \
				or staircase["rotation"] not in [0, 90, 180, 270]:
					return false
				if staircase.has("upper_rotation") \
				and (not staircase["upper_rotation"] is int or staircase["upper_rotation"] not in [0, 90, 180, 270]):
					return false
				if staircase.has("landing_at") \
				and (not staircase["landing_at"] is Array or staircase["landing_at"].size() != 2):
					return false
				staircase_ids.append(staircase["id"])
			if not (0 in building["building_levels"].map(func(level): return level.get("z")) and 2 in building["building_levels"].map(func(level): return level.get("z"))):
				return false
			for staircase in building["staircases"]:
				var lower_at: Array = staircase["lower_at"]
				var upper_at: Array = staircase["upper_at"]
				if lower_at[0] == upper_at[0] and lower_at[1] == upper_at[1]:
					return false
				if lower_at[0] < building["footprint"]["x"] or lower_at[0] >= building["footprint"]["x"] + building["footprint"]["width"] \
				or lower_at[1] < building["footprint"]["y"] or lower_at[1] >= building["footprint"]["y"] + building["footprint"]["height"] \
				or upper_at[0] < building["footprint"]["x"] or upper_at[0] >= building["footprint"]["x"] + building["footprint"]["width"] \
				or upper_at[1] < building["footprint"]["y"] or upper_at[1] >= building["footprint"]["y"] + building["footprint"]["height"]:
					return false
				if staircase.has("landing_at"):
					var landing_at: Array = staircase["landing_at"]
					if landing_at[0] < building["footprint"]["x"] or landing_at[0] >= building["footprint"]["x"] + building["footprint"]["width"] \
					or landing_at[1] < building["footprint"]["y"] or landing_at[1] >= building["footprint"]["y"] + building["footprint"]["height"]:
						return false
					if abs(lower_at[0] - landing_at[0]) + abs(lower_at[1] - landing_at[1]) != 1 \
					or abs(upper_at[0] - landing_at[0]) + abs(upper_at[1] - landing_at[1]) != 1:
						return false
				elif abs(lower_at[0] - upper_at[0]) + abs(lower_at[1] - upper_at[1]) != 1:
					return false
		for room_id in building["rooms"]:
			if not room_id is String or room_id not in valid_room_ids:
				return false
		if building.has("interior_rooms"):
			if not building["interior_rooms"] is Array or building["interior_rooms"].is_empty():
				return false
			for room_id in building["interior_rooms"]:
				if not room_id is String or room_id not in valid_room_ids or room_id not in building["rooms"]:
					return false
		if building.has("open_space_rooms"):
			if not building["open_space_rooms"] is Array or building["open_space_rooms"].is_empty():
				return false
			for room_id in building["open_space_rooms"]:
				if not room_id is String or room_id not in valid_room_ids or room_id not in building["rooms"]:
					return false
		if building.has("exterior_context"):
			if not building["exterior_context"] is Dictionary \
			or not building["exterior_context"].has("at") \
			or not building["exterior_context"]["at"] is Array \
			or building["exterior_context"]["at"].size() != 2 \
			or not building["exterior_context"].has("z") \
			or not building["exterior_context"]["z"] is int:
				return false
		if building.has("exterior_access_context"):
			if not building["exterior_access_context"] is Dictionary \
			or not building["exterior_access_context"].has("connection") \
			or not building["exterior_access_context"]["connection"] is String \
			or building["exterior_access_context"]["connection"].is_empty() \
			or building["exterior_access_context"]["connection"] not in valid_connection_ids:
				return false
		if building.has("entrance"):
			if not building["entrance"] is Dictionary \
			or not building["entrance"].has("connection") \
			or not building["entrance"]["connection"] is String \
			or building["entrance"]["connection"].is_empty() \
			or building["entrance"]["connection"] not in valid_connection_ids \
			or not building["entrance"].has("facing") \
			or not building["entrance"]["facing"] is String \
			or building["entrance"]["facing"] not in ["north", "east", "south", "west"] \
			or not building.has("exterior_context"):
				return false
		if building.has("entrances"):
			if not building["entrances"] is Array \
			or building["entrances"].is_empty():
				return false
			var seen_entrance_ids: Array[String] = []
			var seen_entrance_conns: Array[String] = []
			for entrance_entry in building["entrances"]:
				if not entrance_entry is Dictionary \
				or not entrance_entry.has("id") \
				or not entrance_entry["id"] is String \
				or entrance_entry["id"].is_empty() \
				or not entrance_entry.has("connection") \
				or not entrance_entry["connection"] is String \
				or entrance_entry["connection"].is_empty() \
				or entrance_entry["connection"] not in valid_connection_ids \
				or not entrance_entry.has("facing") \
				or not entrance_entry["facing"] is String \
				or entrance_entry["facing"] not in ["north", "east", "south", "west"]:
					return false
				if entrance_entry["id"] in seen_entrance_ids:
					return false
				seen_entrance_ids.append(entrance_entry["id"])
				if entrance_entry["connection"] in seen_entrance_conns:
					return false
				seen_entrance_conns.append(entrance_entry["connection"])
			if not building.has("exterior_context"):
				return false
			if building.has("exterior_access_context") \
			and building["exterior_access_context"] is Dictionary \
			and building["exterior_access_context"].has("connection") \
			and building["exterior_access_context"]["connection"] is String \
			and building["exterior_access_context"]["connection"] not in seen_entrance_conns:
				return false
		if building.has("entrance") and building.has("entrances"):
			return false
		if building.has("entrance_validation"):
			if not building["entrance_validation"] is String \
			or building["entrance_validation"] != "complete" \
			or (not building.has("entrance") and not building.has("entrances")):
				return false
		if building.has("furniture_anchors"):
			if not building["furniture_anchors"] is Array \
			or building["furniture_anchors"].is_empty():
				return false
			var seen_anchor_ids: Array[String] = []
			for anchor in building["furniture_anchors"]:
				if not anchor is Dictionary \
				or not anchor.has("id") \
				or not anchor["id"] is String \
				or anchor["id"].is_empty() \
				or not anchor.has("at") \
				or not anchor["at"] is Array \
				or anchor["at"].size() != 2 \
				or not anchor.has("z") \
				or not anchor["z"] is int \
				or not anchor.has("kind") \
				or not anchor["kind"] is String \
				or anchor["kind"].is_empty():
					return false
				if anchor["id"] in seen_anchor_ids:
					return false
				seen_anchor_ids.append(anchor["id"])
		return true
	)
	if data["buildings"].is_empty():
		data.erase("buildings")


func _sanitize_building_surfaces(data: Dictionary) -> void:
	if not data.has("building_surfaces") or not data["building_surfaces"] is Array:
		return

	var valid_building_ids: Array[String] = []
	var building_by_id: Dictionary = {}
	if data.has("buildings") and data["buildings"] is Array:
		for building in data["buildings"]:
			if building is Dictionary and building.has("id") and building["id"] is String:
				valid_building_ids.append(building["id"])
				building_by_id[building["id"]] = building

	data["building_surfaces"] = data["building_surfaces"].filter(func(surface):
		if not (surface is Dictionary \
			and surface.has("id") \
			and surface["id"] is String \
			and not surface["id"].is_empty() \
			and surface.has("building") \
			and surface["building"] is String \
			and surface["building"] in valid_building_ids \
			and surface.has("kind") \
			and surface["kind"] is String \
			and surface["kind"] in ["roof", "ceiling", "floor"] \
			and surface.has("z") \
			and surface["z"] is int):
			return false
		var building: Dictionary = building_by_id[surface["building"]]
		if building.has("building_levels"):
			var declared_zs: Array = building["building_levels"].map(func(level): return level.get("z"))
			var highest_z: int = declared_zs.max()
			return surface["z"] in declared_zs and not (surface["kind"] == "roof" and surface["z"] != highest_z) and not (surface["kind"] == "ceiling" and surface["z"] == building["z"])
		return surface["kind"] != "floor" and surface["z"] == building["z"] + 1
	)
	if data["building_surfaces"].is_empty():
		data.erase("building_surfaces")


func _sanitize_building_supports(data: Dictionary) -> void:
	if not data.has("building_supports") or not data["building_supports"] is Array:
		return
	var building_by_id: Dictionary = {}
	if data.has("buildings") and data["buildings"] is Array:
		for building in data["buildings"]:
			if building is Dictionary and building.has("id") and building["id"] is String:
				building_by_id[building["id"]] = building
	data["building_supports"] = data["building_supports"].filter(func(support):
		if not (support is Dictionary and support.keys().size() == 6 and support.has("id") and support["id"] is String and not support["id"].is_empty() and support.has("building") and support["building"] in building_by_id and support.has("at") and support["at"] is Array and support["at"].size() == 2 and support["at"][0] is int and support["at"][1] is int and support.has("from_z") and support["from_z"] is int and support.has("to_z") and support["to_z"] is int and support.has("kind") and support["kind"] in ["column", "wall"]):
			return false
		var building: Dictionary = building_by_id[support["building"]]
		var footprint: Dictionary = building["footprint"]
		if support["at"][0] < footprint["x"] or support["at"][0] >= footprint["x"] + footprint["width"] or support["at"][1] < footprint["y"] or support["at"][1] >= footprint["y"] + footprint["height"]:
			return false
		var declared_zs: Array = building.get("building_levels", []).map(func(level): return level.get("z"))
		return support["from_z"] in declared_zs and support["to_z"] in declared_zs and support["from_z"] < support["to_z"]
	)
	if data["building_supports"].is_empty():
		data.erase("building_supports")


func _sanitize_building_compositions(data: Dictionary) -> void:
	if not data.has("building_compositions") or not data["building_compositions"] is Array:
		return

	var valid_building_ids: Array[String] = []
	if data.has("buildings") and data["buildings"] is Array:
		for building in data["buildings"]:
			if building is Dictionary and building.has("id") and building["id"] is String:
				valid_building_ids.append(building["id"])

	data["building_compositions"] = data["building_compositions"].filter(func(composition):
		return composition is Dictionary \
			and composition.has("id") \
			and composition["id"] is String \
			and not composition["id"].is_empty() \
			and composition.has("building") \
			and composition["building"] is String \
			and composition["building"] in valid_building_ids \
			and composition.has("required_surfaces") \
			and composition["required_surfaces"] is Array \
			and not composition["required_surfaces"].is_empty()
	)
	if data["building_compositions"].is_empty():
		data.erase("building_compositions")


func _sanitize_road_endpoints(data: Dictionary) -> void:
	if not data.has("road_endpoints") or not data["road_endpoints"] is Array:
		return

	var valid_directions: Array[String] = ["north", "east", "south", "west"]
	var seen_ids: Array[String] = []
	var map_connections: Dictionary = data.get("connections", {})
	data["road_endpoints"] = data["road_endpoints"].filter(func(endpoint):
		if not endpoint is Dictionary:
			return false
		if not endpoint.has("id") or not endpoint["id"] is String or endpoint["id"].is_empty():
			return false
		if endpoint["id"] in seen_ids:
			return false
		seen_ids.append(endpoint["id"])
		if not endpoint.has("direction") or not endpoint["direction"] is String:
			return false
		if endpoint["direction"] not in valid_directions:
			return false
		if map_connections.get(endpoint["direction"], "ground") != "road":
			return false
		if not endpoint.has("at") or not endpoint["at"] is Array or endpoint["at"].size() != 2:
			return false
		if not endpoint.has("z") or not endpoint["z"] is int or endpoint["z"] != 0:
			return false
		var at: Array = endpoint["at"]
		if not at[0] is int or not at[1] is int or at[0] < 0 or at[0] >= 32 or at[1] < 0 or at[1] >= 32:
			return false
		if endpoint["direction"] == "north" and at[1] != 0:
			return false
		if endpoint["direction"] == "south" and at[1] != 31:
			return false
		if endpoint["direction"] == "west" and at[0] != 0:
			return false
		if endpoint["direction"] == "east" and at[0] != 31:
			return false
		return true
	)
	if data["road_endpoints"].is_empty():
		data.erase("road_endpoints")


func load_data_from_disk():
	set_data(Helper.json_helper.load_json_dictionary_file(get_file_path()))
	sprite = load(get_sprite_path())


func save_data_to_disk() -> void:
	var map_data_json = JSON.stringify(get_data().duplicate(), "\t")
	Helper.json_helper.write_json_file(get_file_path(), map_data_json)


func get_filename() -> String:
	return id + ".json"


func get_file_path() -> String:
	return dataPath + get_filename()


func get_sprite_path() -> String:
	return get_file_path().replace(".json", ".png")


# This will remove this map from the tacticalmap in every mod that has it.
func remove_self_from_tacticalmap(tacticalmap_id: String) -> void:
	var all_results: Array = Gamedata.mods.get_all_content_by_id(
		DMod.ContentType.TACTICALMAPS, tacticalmap_id
	)
	if all_results.size() > 0:
		for result: DTacticalmap in all_results:
			result.remove_chunk_by_mapid(id)
	else:
		print("No content found.")


# A map is being deleted. Remove all references to this map
func delete_files():
	var json_file_path = get_file_path()
	var png_file_path = get_sprite_path()
	Helper.json_helper.delete_json_file(json_file_path)
	# Use DirAccess to check and delete the PNG file
	var dir = DirAccess.open(dataPath)
	if dir.file_exists(png_file_path):
		dir.remove(id + ".png")
		dir.remove(id + ".png.import")


# We remove ourselves from the filesystem and the parent maplist
# After this, the map is deleted from the current mod that the parent maplist is a part of
# If no copies of this map remain in any mod, we have to remove all references.
func delete():
	delete_files()
	parent.erase_id(id)
	# Check to see if any mod has a copy of this map. if one or more remain, we can keep references
	# Otherwise, the last copy was removed and we need to remove references
	var all_results: Array = Gamedata.mods.get_all_content_by_id(DMod.ContentType.MAPS, id)
	if all_results.size() > 0:
		return

	var myreferences: Dictionary = parent.references.get(id, {})
	# Remove this map from the tacticalmaps in this map's references
	for ref in myreferences.get("tacticalmaps", []):
		remove_self_from_tacticalmap(ref)

	# Remove this map from the overmapareas in this map's references
	for ref in myreferences.get("overmapareas", []):
		var myareas: Array = Gamedata.mods.get_all_content_by_id(DMod.ContentType.OVERMAPAREAS, ref)
		if myareas.is_empty():
			print_debug("Missing overmap area '" + ref + "' while deleting map '" + id + "'")
		for area: DOvermaparea in myareas:
			area.remove_map_from_all_regions(id)

		# Remove this map from NPC spawn lists
	for npc_id in myreferences.get("npcs", []):
		var npcs: Array = Gamedata.mods.get_all_content_by_id(DMod.ContentType.NPCS, npc_id)
		if npcs.is_empty():
			print_debug("Missing NPC '" + npc_id + "' while deleting map '" + id + "'")
		for npc: DNpc in npcs:
			npc.remove_map_from_spawn_maps(id)

	# Remove this map from quests
	for quest_id in myreferences.get("quests", []):
		var quests: Array = Gamedata.mods.get_all_content_by_id(DMod.ContentType.QUESTS, quest_id)
		if quests.is_empty():
			print_debug("Missing quest '" + quest_id + "' while deleting map '" + id + "'")
		for quest: DQuest in quests:
			quest.remove_steps_by_map(id)

	remove_my_reference_from_all_entities()

	# Remove entry from references.json and save
	parent.references.erase(id)
	Gamedata.mods.save_references(parent)


func remove_my_reference_from_all_entities() -> void:
	# Collect unique entities from mapdata
	var entities = collect_unique_entities(DMap.new(id, dataPath, parent))
	var unique_entities: Dictionary = entities["new_entities"]

	# Remove references for feature entries
	for feature in unique_entities.get("features", []):
		match feature["type"]:
			"furniture":
				Gamedata.mods.remove_reference(
					DMod.ContentType.FURNITURES, feature["id"], DMod.ContentType.MAPS, id
				)
			"mob":
				Gamedata.mods.remove_reference(
					DMod.ContentType.MOBS, feature["id"], DMod.ContentType.MAPS, id
				)
			"mobgroup":
				Gamedata.mods.remove_reference(
					DMod.ContentType.MOBGROUPS, feature["id"], DMod.ContentType.MAPS, id
				)
			"itemgroup":
				Gamedata.mods.remove_reference(
					DMod.ContentType.ITEMGROUPS, feature["id"], DMod.ContentType.MAPS, id
				)

	# Remove tile references
	for tile_id in unique_entities.get("tiles", []):
		Gamedata.mods.remove_reference(DMod.ContentType.TILES, tile_id, DMod.ContentType.MAPS, id)


# Function to update map entity references when a map's data changes
func data_changed(oldmap: DMap):
	# Collect unique entities from both new and old data
	var entities = collect_unique_entities(oldmap)
	var new_entities: Dictionary = entities["new_entities"]
	var old_entities: Dictionary = entities["old_entities"]

	# Add references for new features
	for feature in new_entities.get("features", []):
		match feature["type"]:
			"furniture":
				Gamedata.mods.add_reference(
					DMod.ContentType.FURNITURES, feature["id"], DMod.ContentType.MAPS, id
				)
			"mob":
				Gamedata.mods.add_reference(
					DMod.ContentType.MOBS, feature["id"], DMod.ContentType.MAPS, id
				)
			"mobgroup":
				Gamedata.mods.add_reference(
					DMod.ContentType.MOBGROUPS, feature["id"], DMod.ContentType.MAPS, id
				)
			"itemgroup":
				Gamedata.mods.add_reference(
					DMod.ContentType.ITEMGROUPS, feature["id"], DMod.ContentType.MAPS, id
				)

	# Add references for new tiles
	for tile_id in new_entities.get("tiles", []):
		Gamedata.mods.add_reference(DMod.ContentType.TILES, tile_id, DMod.ContentType.MAPS, id)

	# Remove references for entities not present in new data
	for feature in old_entities.get("features", []):
		if not _feature_exists(new_entities.get("features", []), feature):
			match feature["type"]:
				"furniture":
					Gamedata.mods.remove_reference(
						DMod.ContentType.FURNITURES, feature["id"], DMod.ContentType.MAPS, id
					)
				"mob":
					Gamedata.mods.remove_reference(
						DMod.ContentType.MOBS, feature["id"], DMod.ContentType.MAPS, id
					)
				"mobgroup":
					Gamedata.mods.remove_reference(
						DMod.ContentType.MOBGROUPS, feature["id"], DMod.ContentType.MAPS, id
					)
				"itemgroup":
					Gamedata.mods.remove_reference(
						DMod.ContentType.ITEMGROUPS, feature["id"], DMod.ContentType.MAPS, id
					)

	for tile_id in old_entities.get("tiles", []):
		if not new_entities.get("tiles", []).has(tile_id):
			Gamedata.mods.remove_reference(
				DMod.ContentType.TILES, tile_id, DMod.ContentType.MAPS, id
			)


# Function to collect unique entities from each level in newdata and olddata
func collect_unique_entities(oldmap: DMap) -> Dictionary:
	var new_entities = {"features": [], "tiles": []}
	var old_entities = {"features": [], "tiles": []}

	# Collect entities from newdata
	for level in levels:
		add_entities_to_set(level, new_entities)

	# Collect entities from olddata
	for level in oldmap.levels:
		add_entities_to_set(level, old_entities)

	# Collect entities from newdata
	for myarea in areas:
		add_entities_in_area_to_set(myarea, new_entities)

	# Collect entities from olddata
	for myarea in oldmap.areas:
		add_entities_in_area_to_set(myarea, old_entities)

	return {"new_entities": new_entities, "old_entities": old_entities}


# Helper function to add entities to the respective sets
func add_entities_in_area_to_set(myarea: Dictionary, entity_set: Dictionary):
	if myarea.has("entities"):
		for entity in myarea["entities"]:
			var feature_type: String = entity.get("type", "")
			match feature_type:
				"mob", "mobgroup", "furniture":
					_add_feature_to_set(entity_set, feature_type, entity.get("id", ""))
				"itemgroup":
					_add_feature_to_set(entity_set, "itemgroup", entity.get("id", ""))

	if myarea.has("tiles"):
		for tile in myarea["tiles"]:
			# The "null" tile in areas is used to control propoprtions and is not really an entity
			if not entity_set["tiles"].has(tile["id"]) and not tile["id"] == "null":
				entity_set["tiles"].append(tile["id"])


# Helper function to add entities to the respective sets
func add_entities_to_set(level: Array, entity_set: Dictionary):
	for entity in level:
		if entity.has("feature"):
			var feature: Dictionary = entity["feature"]
			var ftype: String = feature.get("type", "")
			match ftype:
				"mob", "mobgroup", "furniture":
					var fid: String = feature.get("id", "")
					if fid != "":
						_add_feature_to_set(entity_set, ftype, fid)
					if feature.has("itemgroups"):
						for itemgroup in feature["itemgroups"]:
							_add_feature_to_set(entity_set, "itemgroup", itemgroup)
				"itemgroup":
					for itemgroup in feature.get("itemgroups", []):
						_add_feature_to_set(entity_set, "itemgroup", itemgroup)


# Helper to add a feature id to the entity_set if it doesn't exist yet
func _add_feature_to_set(entity_set: Dictionary, ftype: String, fid: String) -> void:
	if fid == "":
		return
	for existing in entity_set["features"]:
		if existing["type"] == ftype and existing["id"] == fid:
			return
	entity_set["features"].append({"type": ftype, "id": fid})


# Helper to check if a feature entry exists in a list
func _feature_exists(feature_list: Array, feature: Dictionary) -> bool:
	for f in feature_list:
		if (
			f.get("type", "") == feature.get("type", "")
			and f.get("id", "") == feature.get("id", "")
		):
			return true
	return false


# Removes all instances of the provided entity from the map
# entity_type can be "tile" or a feature type ("furniture", "mob", "mobgroup", "itemgroup")
# entity_id is the id of the tile or feature
func remove_entity_from_map(entity_type: String, entity_id: String) -> void:
	# Translate the type to the actual key that we need
	if entity_type == "tile":
		entity_type = "id"
	remove_entity_from_levels(entity_type, entity_id)
	erase_entity_from_areas(entity_type, entity_id)
	save_data_to_disk()


# Removes all instances of the provided entity from the levels
# entity_type can be "tile" or a feature type ("furniture", "mob", "mobgroup", "itemgroup")
# entity_id is the id of the tile or feature
func remove_entity_from_levels(entity_type: String, entity_id: String) -> void:
	for level in levels:
		for entity_index in range(level.size()):
			var entity: Dictionary = level[entity_index]

			match entity_type:
				"id":
					if entity.get("id", "") == entity_id:
						level[entity_index] = {}
				"furniture", "mob", "mobgroup":
					if (
						entity.get("feature", {}).get("type", "") == entity_type
						and entity["feature"].get("id", "") == entity_id
					):
						entity.erase("feature")
				"itemgroup":
					if entity.has("feature"):
						var feature = entity["feature"]
						if feature.get("type", "") == "itemgroup":
							var groups: Array = feature.get("itemgroups", [])
							if groups.has(entity_id):
								groups.erase(entity_id)
								if groups.is_empty():
									entity.erase("feature")
								else:
									feature["itemgroups"] = groups
						elif feature.get("type", "") == "furniture" and feature.has("itemgroups"):
							var groups_f: Array = feature["itemgroups"]
							if groups_f.has(entity_id):
								groups_f.erase(entity_id)
								if groups_f.is_empty():
									feature.erase("itemgroups")


# Function to erase an entity from every area
func erase_entity_from_areas(entity_type: String, entity_id: String) -> void:
	for myarea in areas:
		match entity_type:
			"tile":
				if myarea.has("tiles"):
					myarea["tiles"] = myarea["tiles"].filter(
						func(tile): return tile["id"] != entity_id
					)
			"furniture", "mob", "mobgroup", "itemgroup":
				if myarea.has("entities"):
					myarea["entities"] = myarea["entities"].filter(
						func(entity):
							return not (entity["type"] == entity_type and entity["id"] == entity_id)
					)


# Function to remove a area from mapData.areas by its id
func remove_area(area_id: String) -> void:
	# Iterate through the areas array to find and remove the area by id
	for i in range(areas.size()):
		if areas[i]["id"] == area_id:
			areas.erase(areas[i])
			break


# Function to set a connection type for a specific direction
func set_connection(direction: String, value: String) -> void:
	# Ensure the connections dictionary has an entry for the specified direction (e.g., "north", "south").
	if not connections.has(direction):
		connections[direction] = "ground"  # Default to "ground" if not already set.

	# Assign the provided connection type (e.g., "road", "ground") to the specified direction.
	connections[direction] = value


# Function to get a connection type for a specific direction, returning "ground" if any key is missing
func get_connection(direction: String) -> String:
	# Return "ground" if connections dictionary is empty or the direction is not found.
	if connections.is_empty() or not connections.has(direction):
		return "ground"

	# Return the connection type for the specified direction (e.g., "road" or "ground").
	return connections[direction]


# --- Helper functions for tile feature conversion ---


# Converts legacy tile dictionaries to use the `feature` dictionary structure
# A legacy tile looks like this:
#	{
#		"areas": [
#			{
#				"id": "floor_bedroom",
#				"rotation": 0.0
#			}
#		],
#		"furniture": {
#			"id": "door_wood",
#			"rotation": 180.0
#		},
#		"id": "floor_wood_boards_05",
#		"rotation": 180.0
#	},
func _legacy_tile_to_feature(tile: Dictionary) -> Dictionary:
	if tile.has("feature"):
		return tile

	if tile.has("furniture"):
		var f = tile["furniture"]
		tile["feature"] = {
			"type": "furniture", "id": f.get("id", ""), "rotation": f.get("rotation", 0)
		}
		if f.has("itemgroups"):
			tile["feature"]["itemgroups"] = f["itemgroups"]
		tile.erase("furniture")

	elif tile.has("mob"):
		var m = tile["mob"]
		tile["feature"] = {"type": "mob", "id": m.get("id", ""), "rotation": m.get("rotation", 0)}
		tile.erase("mob")

	elif tile.has("mobgroup"):
		var mg = tile["mobgroup"]
		tile["feature"] = {
			"type": "mobgroup", "id": mg.get("id", ""), "rotation": mg.get("rotation", 0)
		}
		tile.erase("mobgroup")

	elif tile.has("itemgroups"):
		var groups = tile["itemgroups"]
		tile["feature"] = {
			"type": "itemgroup", "itemgroups": groups, "rotation": tile.get("rotation", 0)  # No per-itemgroup rotation, fallback to tile
		}
		tile.erase("itemgroups")

	return tile


# Applies legacy conversion to all tiles within all levels
func _convert_levels_legacy_to_feature(raw_levels: Array) -> Array:
	var converted: Array = []
	for level in raw_levels:
		var new_level: Array = []
		for tile in level:
			var t: Dictionary = tile.duplicate()
			new_level.append(_legacy_tile_to_feature(t))
		converted.append(new_level)
	return converted


# Prepares levels for saving by omitting empty `feature` entries
func _convert_levels_feature_for_save(in_levels: Array) -> Array:
	var result: Array = []
	for level in in_levels:
		var new_level: Array = []
		for tile in level:
			var t: Dictionary = tile.duplicate()
			if t.has("feature") and t["feature"].is_empty():
				t.erase("feature")
			new_level.append(t)
		result.append(new_level)
	return result
