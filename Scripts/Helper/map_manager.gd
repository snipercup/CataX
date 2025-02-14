extends Node

# This script manages the tacticalmap, where the player is playing in.
# It is part of the Helper singleton and can be accessed by Helper.map_manager
# It keeps track of entities on the map
# It can add and remove entities on the map
# It can check what's around the player in terms of blocks and furniture

# We keep a reference to the level_generator, which holds the chunks
# The level generator will register itself to this variable when it's ready
var level_generator: Node = null
	
func get_chunk_from_position(position_in_3d_space: Vector3) -> Chunk:
	return level_generator.get_chunk_from_position(position_in_3d_space)

# Takes an overmap coordinate like -12,-6 or -1,-1 or 0,0 or 1,1 and
# returns the cunk at that position or null if the chunk doesn't exist
func get_chunk_from_overmap_coordinate(coordinate: Vector2) -> Chunk:
	return level_generator.get_chunk(coordinate)

# Takes an item_id (of an RItem) and a quantity and spawns it onto
# the map that the player is currently on. It will make two attempts:
# 1. spawn the item at a random static furniture on the same y level as the player
# We spawn at the same y level to increase the chance that it is reachable
# 2. Spawn the item on a free tile on the chunk as an ContainerItem
func spawn_item_at_current_player_map(item_id: String, quantity: int) -> bool:
	var player: Player = Helper.overmap_manager.player
	var player_coordinate: Vector2 = Helper.overmap_manager.player_current_cell
	var chunk: Chunk = get_chunk_from_overmap_coordinate(player_coordinate)
	var current_player_y: float = player.get_y_position(true)
	var same_y_furniture: Array[FurnitureStaticSrv] = chunk.get_furniture_at_y_level(current_player_y)
	# Filter out furniture that is not a container
	var container_furniture: Array[FurnitureStaticSrv] = same_y_furniture.filter(func(furniture): 
		return furniture.is_container()
	)

	# If there are valid container furniture options, pick one at random
	if container_furniture.size() > 0:
		var random_furniture = container_furniture.pick_random()
		return random_furniture.add_item_to_inventory(item_id, quantity)
	
	# Attempt to spawn the item on an empty tile
	return chunk.spawn_item_at_free_position(item_id,quantity,current_player_y)
	return false

# Takes an mob_id (of an RMob) and spawns it onto
# the map that is indicated by the coordinates.
# We use the same Y coordinate as the player but we can change this if it is unreliable
func spawn_mob_at_nearby_map(mob_id: String, coordinates: Vector2) -> bool:
	var player: Player = Helper.overmap_manager.player
	var chunk: Chunk = get_chunk_from_overmap_coordinate(coordinates)
	if not chunk:
		return false
	var current_player_y: float = player.get_y_position(true)
	
	# Attempt to spawn the item on an empty tile
	return chunk.spawn_mob_at_free_position(mob_id, current_player_y)
	return false
	

# Function to process area data and assign to tile
func process_area_data(area_data: Dictionary, original_tile_id: String, picked_tile: Dictionary = {}) -> Dictionary:
	var result = {}

	# Process and assign tile ID, allowing for an external picked_tile to be passed in
	_process_tile_id(area_data, original_tile_id, result, picked_tile)

	# Process entities data and add them to result
	_process_entities_data(area_data, result)

	return result


# Function to get a random rotation or return -1 if rotate_random is false
func _get_random_rotation(area_data: Dictionary) -> int:
	var rotate_random: bool = area_data.get("rotate_random", false)
	return [0, 90, 180, 270].pick_random() if rotate_random else -1


# Function to process and assign tile ID
func _process_tile_id(area_data: Dictionary, original_tile_id: String, result: Dictionary, picked_tile: Dictionary = {}) -> void:
	var tiles_data = area_data.get("tiles", [])

	# Determine rotation using the new logic
	var rotation = _get_random_rotation(area_data)
	if rotation == -1:
		rotation = area_data.get("rotation", 0)  # Use area-defined rotation if no random rotation is applied

	# Check if pick_one is set to true and a tile has already been picked for this cluster
	if picked_tile and not picked_tile.is_empty() and not picked_tile["id"] == "null":
		result["id"] = picked_tile["id"]
		result["rotation"] = rotation
		return  # Exit the function since the tile has been set

	# If no tile has been picked or pick_one is false, pick a new tile
	if not tiles_data.is_empty():
		var new_picked_tile = pick_item_based_on_count(tiles_data)
		
		# Check if the picked tile is "null"
		if new_picked_tile["id"] == "null":
			result["id"] = original_tile_id  # Keep the original tile ID
		else:
			result["id"] = new_picked_tile["id"]
			result["rotation"] = rotation  # Apply the determined rotation


# Function to process entities data and add them to result
func _process_entities_data(area_data: Dictionary, result: Dictionary) -> void:
	# Calculate the total count of tiles
	var tiles_data = area_data.get("tiles", [])
	var total_tiles_count: int = calculate_total_count(tiles_data)

	# Duplicate the entities_data and add the "None" entity
	var entities_data = area_data.get("entities", []).duplicate()
	# We add an extra item to the entities list 
	# which will affect the proportion of entities that will spawn
	# If you have an area of grass with a grass tile with a count of 100
	# and a tree furniture with a count of 1, the entities_data will contain
	# the tree furniture with a count of 1 and the "None" with a count of 100
	# This results in the tree being picked every 1 in 100 tiles.
	entities_data.append({"id": "None", "type": "None", "count": total_tiles_count})

	# Pick an entity from the duplicated entities_data
	if not entities_data.is_empty():
		var selected_entity = pick_item_based_on_count(entities_data)
		if selected_entity["type"] != "None":
			var rotation = _get_random_rotation(area_data)
			if rotation == -1:
				rotation = area_data.get("rotation", 0)

			match selected_entity["type"]:
				"furniture":
					result["furniture"] = {"id": selected_entity["id"], "rotation": rotation}
				"mob":
					result["mob"] = {"id": selected_entity["id"], "rotation": rotation}
				"mobgroup":
					result["mobgroup"] = {"id": selected_entity["id"], "rotation": rotation}
				"itemgroup":
					result["itemgroups"] = [selected_entity["id"]]


# Function to pick an item based on its count property
func pick_item_based_on_count(items: Array) -> Dictionary:
	var total_count: int = calculate_total_count(items)
	var random_pick: int = randi() % total_count
	for item in items:
		if random_pick < item["count"]:
			return item
		random_pick -= item["count"]

	return {}  # In case no item is selected, though this should not happen if the input is valid


# Function to calculate the total count of items
func calculate_total_count(items: Array) -> int:
	var total_count: int = 0
	for item in items:
		total_count += item["count"]
	return total_count


# Function to get area data by ID
func get_area_data_by_id(area_id: String, mapData: Dictionary) -> Dictionary:
	if mapData.has("areas"):
		for area in mapData["areas"]:
			if area["id"] == area_id:
				return area
	return {}


# Function to apply spawn modifications to areas in mapData
func apply_spawn_modifications(spawn_modifications: Array, mapData: Dictionary) -> void:
	for mod in spawn_modifications:
		var mod_id = mod["id"]
		var mod_chance = mod["chance"]
		# Find the area in mapData and modify its spawn_chance
		for map_area in mapData["areas"]:
			if map_area["id"] == mod_id:
				# Allow spawn_chance to go below 0 or above 100 to provide flexibility
				map_area["spawn_chance"] += mod_chance


# Function to check if mapData has areas and return their data based on spawn chance
func get_area_data_based_on_spawn_chance(mapData: Dictionary) -> Array:
	var selected_areas = []
	if mapData.has("areas"):
		for area in mapData["areas"]:
			if randi() % 100 < area.get("spawn_chance", 0):
				selected_areas.append(area)
				# Check for spawn_modifications
				if area.has("spawn_modifications"):
					apply_spawn_modifications(area["spawn_modifications"], mapData)
	return selected_areas


# Processes a map and applies areas in that map to the mapdata
# The provided dictionary will be modified by this function, so send a duplicate if you don't want changes
# If no areas exist in the mapdata, no changes are made
# Example area data:
#"areas": [
#	{
#		"id": "tree_layer",
#		"rotate_random": true,
#		"spawn_chance": 100,
#		"entities": [
#			{"id": "Tree_00", "type": "furniture", "count": 11},
#			{"id": "PineTree_00", "type": "furniture", "count": 11},
#			{"id": "WillowTree_00", "type": "furniture", "count": 11}
#		],
#		"tiles": [{"id": "null", "count": 100}]
#	},
#	{
#		"id": "forest_mobs",
#		"rotate_random": true,
#		"spawn_chance": 50,
#		"entities": [
#			{"id": "bandits", "type": "mobgroup", "count": 20},
#			{"id": "wolves", "type": "mobgroup", "count": 10},
#			{"id": "deer", "type": "mobgroup", "count": 15}
#		],
#		"tiles": [{"id": "forest_grass", "count": 100}]
#	}
#    {
#        "id": "ground_layer",
#        "rotate_random": true,
#        "spawn_chance": 100,
#        "entities": [],
#        "tiles": [
#            {"id": "forest_underbrush_03", "count": 100},
#            {"id": "forest_underbrush_04", "count": 100},
#            {"id": "forest_underbrush_05", "count": 100},
#            {"id": "dirt_light_00", "count": 2},
#            {"id": "grass_medium_dirt_00", "count": 2}
#        ]
#    },
#    {
#        "id": "generic_forest_finds",
#        "rotate_random": false,
#        "spawn_chance": 100,
#        "entities": [
#            {"id": "generic_forest_finds", "type": "itemgroup", "count": 1}
#        ],
#        "tiles": [{"id": "null", "count": 100}]
#    }
#]
func process_areas_in_map(mapdata: Dictionary):
	if not mapdata.has("areas"):
		return
	# Check and get area data in mapData based on spawn chance
	var selected_areas = get_area_data_based_on_spawn_chance(mapdata)
	apply_areas_to_tiles(selected_areas, mapdata)


# Helper function to check if a position is within bounds
func is_within_bounds(x: int, y: int, width: int, height: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height


# Function to get adjacent tile positions (up, down, left, right)
func get_adjacent_positions(pos: Vector2) -> Array:
	return [
		Vector2(pos.x - 1, pos.y),  # Left
		Vector2(pos.x + 1, pos.y),  # Right
		Vector2(pos.x, pos.y - 1),  # Up
		Vector2(pos.x, pos.y + 1)   # Down
	]


# Flood-fill function to find a cluster of tiles
func flood_fill(level: Array, area_id: String, start_pos: Vector2, visited: Dictionary, width: int, height: int) -> Array:
	var cluster = []
	var to_visit = [start_pos]

	while to_visit.size() > 0:
		var current_pos = to_visit.pop_front()
		var x = current_pos.x
		var y = current_pos.y

		if not is_within_bounds(x, y, width, height):
			continue

		# Skip if this position has already been visited
		if visited.has(current_pos):
			continue

		var index = int(y * width + x)
		var tile = level[index]

		# Check if the tile has the correct area_id
		if not tile.has("areas"):
			continue
		var has_area = false
		for area in tile["areas"]:
			if area["id"] == area_id:
				has_area = true
				break

		if not has_area:
			continue

		# Mark the tile as visited and add it to the current cluster
		visited[current_pos] = true
		cluster.append(tile)

		# Add adjacent tiles to the list of tiles to visit
		for adj_pos in get_adjacent_positions(current_pos):
			if not visited.has(adj_pos):
				to_visit.append(adj_pos)

	return cluster

# Function to find clusters of adjacent tiles with the same area_id
func find_area_clusters(level: Array, area_id: String, width: int, height: int) -> Array:
	if level.size() < 1:
		return []
	var clusters = []
	var visited = {}

	# Loop over every tile in the level
	for y in range(height):
		for x in range(width):
			var pos = Vector2(x, y)
			var index = int(y * width + x)
			var tile = level[index]

			# Check if this tile has already been visited
			if visited.has(pos):
				continue

			# Check if this tile has the correct area_id
			if not tile.has("areas"):
				continue

			var has_area = false
			for area in tile["areas"]:
				if area["id"] == area_id:
					has_area = true
					break

			if has_area:
				# Use flood fill to find a cluster starting from this tile
				var cluster = flood_fill(level, area_id, pos, visited, width, height)
				if cluster.size() > 0:
					clusters.append(cluster)

	return clusters


# Function to apply clusters of areas to tiles in a level
func apply_area_clusters_to_tiles(level: Array, area_id: String, mapData: Dictionary, width: int, height: int) -> void:
	# Find all clusters of tiles with the specified area_id
	var clusters = find_area_clusters(level, area_id, width, height)

	# Process each cluster and apply the area data to each tile in the cluster
	for cluster in clusters:
		# Fetch the area data for the current area_id from mapData
		var area_data = get_area_data_by_id(area_id, mapData)

		# Pick a new tile for this cluster
		var picked_tile = {}
		if area_data.has("pick_one") and area_data["pick_one"]:
			# Reset tile selection for each cluster
			picked_tile = pick_item_based_on_count(area_data["tiles"])

		# Loop through each tile in the cluster
		for tile in cluster:
			var original_tile_id = tile.get("id", "")
			var processed_data = process_area_data(area_data, original_tile_id, picked_tile)

			# Step 1: Get a random rotation first
			var tile_rotation = _get_random_rotation(area_data)

			# Step 2: If random rotation is -1, get rotation from the tile's area data
			if tile_rotation == -1 and tile.has("areas"):
				for area in tile["areas"]:
					if area.get("id") == area_id:
						tile_rotation = area.get("rotation", 0)  # Get rotation from the area inside tile
						break

			# Apply rotation to the processed data
			processed_data["rotation"] = tile_rotation if tile_rotation > -1 else 0

			# Remove existing entities if new entities are present in processed data
			var entities_to_check = ["mob", "furniture", "mobgroup", "itemgroups"]
			var new_has_entities = entities_to_check.any(func(entity): return processed_data.has(entity))

			if new_has_entities:
				# The processed data has an entity. Erase existing entities from the tile
				for key in entities_to_check:
					tile.erase(key)

			# Apply the processed data to the tile
			for key in processed_data.keys():
				if key in ["mob", "furniture", "mobgroup"]:
					# If key is an entity, also apply rotation
					tile[key] = {"id": processed_data[key]["id"], "rotation": tile_rotation}
				else:
					tile[key] = processed_data[key]


# Modify the existing function to integrate clusters when applying areas to tiles
func apply_areas_to_tiles(selected_areas: Array, generated_mapdata: Dictionary) -> void:
	if generated_mapdata.has("levels"):
		# Iterate through each level in the map
		for level in generated_mapdata["levels"]:
			var width = 32  # Assuming 32x32 grid
			var height = 32

			# For each selected area, find and apply clusters
			for area in selected_areas:
				if area.has("id"):
					apply_area_clusters_to_tiles(level, area["id"], generated_mapdata, width, height)
