extends GutTest

# Tests the sanitization logic in DMap.get_data() for corrupt tiles.
func test_dmap_tile_sanitization():
	var DMap = load("res://Scripts/Gamedata/DMap.gd")
	# We use null for DMap parent as it's not used by the sanitization logic being tested here
	var map = DMap.new("test_sanitization_map", "/tmp/", null)
	
	# Setup dimensions: 32x32 = 1024 tiles (as per task requirements)
	map.mapwidth = 32
	map.mapheight = 32
	
	# Level 0 will contain the test cases
	var level_0: Array = []
	
	# --- TEST CASE: VALID TILE ---
	# Should remain unchanged
	var valid_tile = {"id": "floor_wood_boards_00", "rotation": 90}
	level_0.append(valid_tile.duplicate())
	
	# --- TEST CASE: MISSING ID KEY ---
	# Should be replaced by {}
	var missing_id_tile = {"rotation": 90}
	level_0.append(missing_id_tile.duplicate())
	
	# --- TEST CASE: EMPTY STRING ID ---
	# Should be replaced by {}
	var empty_id_tile = {"id": "", "rotation": 45}
	level_0.append(empty_id_tile.duplicate())
	
	# --- TEST CASE: WHITESPACE-ONLY ID ---
	# Should be replaced by {}
	var whitespace_id_tile = {"id": "   ", "furniture": {"id": "lamp_standing"}}
	level_0.append(whitespace_id_tile.duplicate())
	
	# Fill the rest of the 1024 tiles with valid grass tiles to ensure total count remains unchanged
	var remaining_tiles = 1024 - level_0.size()
	for i in range(remaining_tiles):
		level_0.append({"id": "grass_plain_01", "rotation": 0})
		
	map.levels[0] = level_0
	
	# Perform data retrieval (triggering sanitization)
	var data = map.get_data()
	var retrieved_level = data["levels"][0]
	
	# --- ASSERTIONS ---
	
	# 1. Verify total count of tile entries remains unchanged
	assert_eq(retrieved_level.size(), 1024, "Total tile count should remain 1024")
	
	# 2. Verify valid tile remains identical
	var result_valid = retrieved_level[0]
	assert_eq(result_valid["id"], "floor_wood_boards_00", "Valid tile ID mismatch")
	assert_eq(result_valid["rotation"], 90, "Valid tile rotation mismatch")
	
	# 3. Verify missing id key is sanitized to {}
	var result_missing = retrieved_level[1]
	assert_true(result_missing.is_empty(), "Tile with missing ID should be an empty dictionary")
	
	# 4. Verify empty string id is sanitized to {}
	var result_empty = retrieved_level[2]
	assert_true(result_empty.is_empty(), "Tile with empty ID should be an empty dictionary")
	
	# 5. Verify whitespace-only id is sanitized to {}
	var result_whitespace = retrieved_level[3]
	assert_true(result_whitespace.is_empty(), "Tile with whitespace ID should be an empty dictionary")
	
	# 6. Verify a standard filled tile in the remainder works
	var result_filler = retrieved_level[4]
	assert_eq(result_filler["id"], "grass_plain_01", "Filler tile should remain unchanged")


func test_dmap_room_semantics_roundtrip_and_sanitization():
	var DMap = load("res://Scripts/Gamedata/DMap.gd")
	var map = DMap.new("test_room_semantics", "/tmp/", null)
	map.set_data({
		"name": "Room semantics",
		"description": "Preserve authored rooms.",
		"rooms": [
			{"id": "office", "kind": "enclosed"},
			{"id": "garage_bay", "kind": "covered_open"},
			{"id": "damaged_store", "kind": "ruin"},
		],
		"levels": [[
			{"id": "concrete_00", "rooms": ["garage_bay"]},
			{"id": "concrete_00", "rooms": ["missing_room"]},
		]],
	})

	var data = map.get_data()

	assert_eq(data["rooms"], [
		{"id": "office", "kind": "enclosed"},
		{"id": "garage_bay", "kind": "covered_open"},
		{"id": "damaged_store", "kind": "ruin"},
	])
	assert_eq(data["levels"][0][0]["rooms"], ["garage_bay"])
	assert_false(data["levels"][0][1].has("rooms"), "Stale room references should be removed")


func test_dmap_room_connections_roundtrip_and_sanitization():
	var DMap = load("res://Scripts/Gamedata/DMap.gd")
	var map = DMap.new("test_room_connections", "/tmp/", null)
	map.set_data({
		"name": "Room connections",
		"description": "Preserve authored door links.",
		"rooms": [
			{"id": "office", "kind": "enclosed"},
			{"id": "garage_bay", "kind": "covered_open"},
		],
		"room_connections": [
			{
				"id": "office_front_door",
				"at": [11, 10],
				"z": 0,
				"from": {"kind": "room", "id": "office"},
				"to": {"kind": "exterior"},
			},
			{
				"id": "stale_link",
				"at": [12, 10],
				"z": 0,
				"from": {"kind": "room", "id": "missing_room"},
				"to": {"kind": "exterior"},
			},
		],
		"levels": [[
			{"id": "concrete_00"},
		]],
	})

	var data = map.get_data()

	assert_eq(data["room_connections"], [{
		"id": "office_front_door",
		"at": [11, 10],
		"z": 0,
		"from": {"kind": "room", "id": "office"},
		"to": {"kind": "exterior"},
	}])


func test_dmap_room_boundaries_roundtrip_and_sanitization():
	var DMap = load("res://Scripts/Gamedata/DMap.gd")
	var map = DMap.new("test_room_boundaries", "/tmp/", null)
	map.set_data({
		"name": "Room boundaries",
		"description": "Preserve authored physical references.",
		"rooms": [
			{"id": "office", "kind": "enclosed", "boundary_validation": "complete"},
		],
		"room_boundaries": [
			{
				"id": "office_north_wall",
				"room": "office",
				"at": [8, 7],
				"z": 0,
				"element": "wall_tile",
				"side": "south",
			},
			{
				"id": "stale_boundary",
				"room": "missing_room",
				"at": [12, 10],
				"z": 0,
				"element": "door_furniture",
			},
		],
		"levels": [[
			{"id": "concrete_00"},
		]],
	})

	var data = map.get_data()

	assert_eq(data["room_boundaries"], [{
		"id": "office_north_wall",
		"room": "office",
		"at": [8, 7],
		"z": 0,
		"element": "wall_tile",
		"side": "south",
	}])
	assert_eq(data["rooms"], [{"id": "office", "kind": "enclosed", "boundary_validation": "complete"}])


func test_dmap_buildings_roundtrip_and_sanitization():
	var DMap = load("res://Scripts/Gamedata/DMap.gd")
	var map = DMap.new("test_buildings", "/tmp/", null)
	map.set_data({
		"name": "Buildings",
		"description": "Preserve authored building footprints.",
		"rooms": [
			{"id": "office", "kind": "enclosed", "boundary_validation": "complete"},
			{"id": "garage_bay", "kind": "covered_open"},
		],
		"room_connections": [{
			"id": "office_front_door",
			"at": [8, 9],
			"z": 0,
			"from": {"kind": "room", "id": "office"},
			"to": {"kind": "exterior"},
		}],
		"buildings": [
			{
				"id": "office_building",
				"rooms": ["office", "garage_bay"],
				"footprint": {"x": 7, "y": 7, "width": 5, "height": 4},
				"z": 0,
				"building_levels": [{"z": 0}, {"z": 2}],
				"staircases": [{"id": "office_staircase", "lower_at": [9, 9], "upper_at": [10, 9], "rotation": 90}],
				"access_validation": "complete",
				"interior_rooms": ["office"],
				"open_space_rooms": ["garage_bay"],
				"room_partition_validation": "complete",
				"overhead_validation": "complete",
				"exterior_context": {"at": [6, 8], "z": 0},
				"exterior_access_context": {"connection": "office_front_door"},
			},
			{
				"rooms": ["office"],
			},
			{
				"id": "stale_exterior_access_building",
				"rooms": ["office"],
				"footprint": {"x": 16, "y": 7, "width": 4, "height": 4},
				"z": 0,
				"exterior_access_context": {"connection": "missing_connection"},
			},
		],
		"levels": [[
			{"id": "concrete_00"},
		]],
	})

	var data = map.get_data()

	assert_eq(data["buildings"], [{
		"id": "office_building",
		"rooms": ["office", "garage_bay"],
		"footprint": {"x": 7, "y": 7, "width": 5, "height": 4},
		"z": 0,
		"building_levels": [{"z": 0}, {"z": 2}],
		"staircases": [{"id": "office_staircase", "lower_at": [9, 9], "upper_at": [10, 9], "rotation": 90}],
		"access_validation": "complete",
		"interior_rooms": ["office"],
		"open_space_rooms": ["garage_bay"],
		"room_partition_validation": "complete",
		"overhead_validation": "complete",
		"exterior_context": {"at": [6, 8], "z": 0},
		"exterior_access_context": {"connection": "office_front_door"},
	}])


func test_dmap_building_levels_roundtrip_and_sanitization():
	var DMap = load("res://Scripts/Gamedata/DMap.gd")
	var map = DMap.new("test_building_levels", "/tmp/", null)
	map.set_data({
		"name": "Building levels",
		"description": "Preserve multi-level footprint metadata.",
		"rooms": [
			{"id": "office", "kind": "enclosed", "boundary_validation": "complete"},
		],
		"buildings": [
			{
				"id": "office_building",
				"rooms": ["office"],
				"footprint": {"x": 7, "y": 7, "width": 4, "height": 4},
				"z": 0,
				"building_levels": [{"z": 0}, {"z": 2}],
				"staircases": [{"id": "corner_stairs", "lower_at": [8, 9], "upper_at": [9, 8], "landing_at": [9, 9], "rotation": 90, "upper_rotation": 0}],
			},
			{
				"id": "bad_levels",
				"rooms": ["office"],
				"footprint": {"x": 16, "y": 7, "width": 4, "height": 4},
				"z": 0,
				"building_levels": [{"z": 0}, {"z": 1}],
			},
			{
				"id": "bad_staircase",
				"rooms": ["office"],
				"footprint": {"x": 7, "y": 16, "width": 4, "height": 4},
				"z": 0,
				"building_levels": [{"z": 0}, {"z": 2}],
				"staircases": [{"id": "bad_staircase", "lower_at": [8, 17], "upper_at": [10, 17], "rotation": 90}],
			},
		],
		"levels": [[
			{"id": "concrete_00"},
		]],
	})

	var data = map.get_data()

	assert_eq(data["buildings"], [{
		"id": "office_building",
		"rooms": ["office"],
		"footprint": {"x": 7, "y": 7, "width": 4, "height": 4},
		"z": 0,
		"building_levels": [{"z": 0}, {"z": 2}],
		"staircases": [{"id": "corner_stairs", "lower_at": [8, 9], "upper_at": [9, 8], "landing_at": [9, 9], "rotation": 90, "upper_rotation": 0}],
	}])


func test_dmap_building_surfaces_roundtrip_and_sanitization():
	var DMap = load("res://Scripts/Gamedata/DMap.gd")
	var map = DMap.new("test_building_surfaces", "/tmp/", null)
	map.set_data({
		"name": "Building surfaces",
		"description": "Preserve authored roof metadata.",
		"rooms": [
			{"id": "office", "kind": "enclosed", "boundary_validation": "complete"},
		],
		"buildings": [
			{
				"id": "office_building",
				"rooms": ["office"],
				"footprint": {"x": 7, "y": 7, "width": 4, "height": 4},
				"z": 0,
			},
			{
				"id": "multi_building",
				"rooms": ["office"],
				"footprint": {"x": 16, "y": 7, "width": 4, "height": 4},
				"z": 0,
				"building_levels": [{"z": 0}, {"z": 2}],
			},
		],
		"building_surfaces": [
			{"id": "office_roof", "building": "office_building", "kind": "roof", "z": 1},
			{"id": "stale_roof", "building": "missing_building", "kind": "roof", "z": 1},
			{"id": "multi_floor", "building": "multi_building", "kind": "floor", "z": 0},
			{"id": "multi_floor_upper", "building": "multi_building", "kind": "floor", "z": 2},
			{"id": "multi_ceiling", "building": "multi_building", "kind": "ceiling", "z": 2},
			{"id": "bad_floor_gap", "building": "multi_building", "kind": "floor", "z": 1},
		],
		"levels": [[
			{"id": "concrete_00"},
		]],
	})

	var data = map.get_data()

	assert_eq(data["building_surfaces"], [
		{"id": "office_roof", "building": "office_building", "kind": "roof", "z": 1},
		{"id": "multi_floor", "building": "multi_building", "kind": "floor", "z": 0},
		{"id": "multi_floor_upper", "building": "multi_building", "kind": "floor", "z": 2},
		{"id": "multi_ceiling", "building": "multi_building", "kind": "ceiling", "z": 2},
	])


func test_dmap_building_compositions_roundtrip_and_sanitization():
	var DMap = load("res://Scripts/Gamedata/DMap.gd")
	var map = DMap.new("test_building_compositions", "/tmp/", null)
	map.set_data({
		"name": "Building compositions",
		"description": "Preserve authored overhead requirements.",
		"rooms": [
			{"id": "office", "kind": "enclosed", "boundary_validation": "complete"},
		],
		"buildings": [{
			"id": "office_building",
			"rooms": ["office"],
			"footprint": {"x": 7, "y": 7, "width": 4, "height": 4},
			"z": 0,
		}],
		"building_compositions": [
			{"id": "office_complete_overhead", "building": "office_building", "required_surfaces": ["roof", "ceiling"]},
			{"id": "stale_composition", "building": "missing_building", "required_surfaces": ["roof"]},
		],
		"levels": [[
			{"id": "concrete_00"},
		]],
	})

	var data = map.get_data()

	assert_eq(data["building_compositions"], [
		{"id": "office_complete_overhead", "building": "office_building", "required_surfaces": ["roof", "ceiling"]},
	])
