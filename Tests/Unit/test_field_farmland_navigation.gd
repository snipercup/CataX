extends GutTest


const MapNavigationFixture = preload("res://Tests/Unit/helpers/map_navigation_fixture.gd")


var fixture


func before_each() -> void:
	fixture = MapNavigationFixture.new(self)
	await fixture.setup()


func after_each() -> void:
	await fixture.teardown()


func test_generated_field_farmland_connects_exterior_rooms_and_upper_storey() -> void:
	await fixture.begin_geometry()
	_populate_farmland_geometry()
	assert_true(await fixture.bake(), "The field_farmland navigation should finish baking.")

	var exterior: Vector3 = fixture.grid_to_world(2, 24, 1.5)
	var kitchen: Vector3 = fixture.grid_to_world(5, 24, 1.5)
	var ground_room: Vector3 = fixture.grid_to_world(12, 25, 1.5)
	var upper_room: Vector3 = fixture.grid_to_world(10, 24, 3.5)
	fixture.assert_path_connects(exterior, kitchen, "Exterior to farmhouse kitchen")
	fixture.assert_path_connects(kitchen, exterior, "Farmhouse kitchen to exterior")
	fixture.assert_path_connects(kitchen, ground_room, "Kitchen to farmhouse ground room")
	fixture.assert_path_connects(ground_room, kitchen, "Farmhouse ground room to kitchen")
	fixture.assert_path_crosses_levels(
		ground_room, upper_room, "Farmhouse ground room to upper room", 1.5, 3.1
	)
	fixture.assert_path_crosses_levels(
		upper_room, ground_room, "Farmhouse upper room to ground room", 1.5, 3.1
	)


func test_generated_field_farmland_blocks_unintended_wall_crossings() -> void:
	await fixture.begin_geometry()
	_populate_farmland_geometry()
	# The south test pocket has only one possible connection to the kitchen.
	for z in range(27, 29):
		fixture.add_wall_obstacle(Vector3(3, 1, z))
		fixture.add_wall_obstacle(Vector3(7, 1, z))
	fixture.add_wall_obstacle(Vector3(4, 1, 28))
	fixture.add_wall_obstacle(Vector3(5, 1, 28))
	fixture.add_wall_obstacle(Vector3(6, 1, 28))
	# The east test pocket has only the non-door partition cell as its connection.
	for z in range(22, 25):
		fixture.add_wall_obstacle(Vector3(9, 1, z))
		if z != 23:
			fixture.add_wall_obstacle(Vector3(8, 1, z))
	fixture.add_wall_obstacle(Vector3(8, 1, 22))
	fixture.add_wall_obstacle(Vector3(8, 1, 24))
	# The two corner pockets can only be approached through their generated caps.
	for z in range(20, 22):
		fixture.add_wall_obstacle(Vector3(8, 1, z))
		fixture.add_wall_obstacle(Vector3(9, 1, z))
	fixture.add_wall_obstacle(Vector3(8, 1, 20))
	fixture.add_wall_obstacle(Vector3(9, 1, 20))
	for z in range(26, 28):
		fixture.add_wall_obstacle(Vector3(8, 1, z))
		fixture.add_wall_obstacle(Vector3(9, 1, z))
	fixture.add_wall_obstacle(Vector3(8, 1, 27))
	fixture.add_wall_obstacle(Vector3(9, 1, 27))
	assert_true(await fixture.bake(), "The field_farmland wall-blocking navigation should finish baking.")

	var kitchen: Vector3 = fixture.grid_to_world(5, 24, 1.5)
	var north_pocket: Vector3 = fixture.grid_to_world(5, 21, 1.5)
	var south_pocket: Vector3 = fixture.grid_to_world(5, 27, 1.5)
	var east_pocket: Vector3 = fixture.grid_to_world(8, 23, 1.5)
	var north_corner_pocket: Vector3 = fixture.grid_to_world(8, 21, 1.5)
	var south_corner_pocket: Vector3 = fixture.grid_to_world(8, 27, 1.5)
	fixture.assert_path_does_not_connect(kitchen, north_pocket, "Kitchen north wall crossing")
	fixture.assert_path_does_not_connect(kitchen, south_pocket, "Kitchen south wall crossing")
	fixture.assert_path_does_not_connect(east_pocket, kitchen, "Kitchen non-door east wall crossing")
	fixture.assert_path_does_not_connect(
		kitchen, north_corner_pocket, "Generated north-east kitchen corner crossing"
	)
	fixture.assert_path_does_not_connect(
		kitchen, south_corner_pocket, "Generated south-east kitchen corner crossing"
	)


func _populate_farmland_geometry() -> void:
	# Ground level: documented farmhouse footprint x3..18/y19..29 plus a west approach.
	for x in range(1, 19):
		for z in range(19, 30):
			fixture.add_block(Vector3(x, 0, z))
	# Lower outer walls, leaving the west front-door opening at (3, 24).
	for x in range(3, 19):
		fixture.add_wall_obstacle(Vector3(x, 1, 19))
		fixture.add_wall_obstacle(Vector3(x, 1, 29))
	for z in range(20, 29):
		if z != 24:
			fixture.add_wall_obstacle(Vector3(3, 1, z))
		fixture.add_wall_obstacle(Vector3(18, 1, z))
	# Automatic kitchen perimeter: corner caps plus declared west/east openings.
	for x in range(4, 7):
		fixture.add_wall_obstacle(Vector3(x, 1, 22))
		fixture.add_wall_obstacle(Vector3(x, 1, 26))
	for z in range(23, 26):
		if z != 24:
			fixture.add_wall_obstacle(Vector3(3, 1, z))
			fixture.add_wall_obstacle(Vector3(7, 1, z))
	fixture.add_wall_obstacle(Vector3(7, 1, 22))
	fixture.add_wall_obstacle(Vector3(7, 1, 26))
	# Upper floor, with the stairwell opening above the lower slope.
	for x in range(3, 19):
		for z in range(19, 30):
			if Vector2i(x, z) != Vector2i(10, 25):
				fixture.add_block(Vector3(x, 1, z))
	fixture.add_block(Vector3(10, 1, 25), "slope", 0)
	fixture.add_block(Vector3(10, 2, 24), "slope", 0)
	# Upper-storey exterior walls and roof.
	for x in range(3, 19):
		fixture.add_wall_obstacle(Vector3(x, 2, 19))
		fixture.add_wall_obstacle(Vector3(x, 2, 29))
	for z in range(20, 29):
		fixture.add_wall_obstacle(Vector3(3, 2, z))
		fixture.add_wall_obstacle(Vector3(18, 2, z))
	for x in range(3, 19):
		for z in range(19, 30):
			fixture.add_block(Vector3(x, 3, z))
