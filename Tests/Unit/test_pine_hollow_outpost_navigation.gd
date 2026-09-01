extends GutTest


const MapNavigationFixture = preload("res://Tests/Unit/helpers/map_navigation_fixture.gd")


var fixture


func before_each() -> void:
	fixture = MapNavigationFixture.new(self)
	await fixture.setup()


func after_each() -> void:
	await fixture.teardown()


func test_pine_hollow_outpost_connects_road_cabin_lean_to_and_loft() -> void:
	await fixture.begin_geometry()
	_populate_outpost_geometry()
	assert_true(await fixture.bake(), "The Pine Hollow Outpost navigation should finish baking.")

	var road: Vector3 = fixture.grid_to_world(4, 14, 1.5)
	var cabin: Vector3 = fixture.grid_to_world(14, 13, 1.5)
	var lean_to: Vector3 = fixture.grid_to_world(20, 14, 1.5)
	var loft: Vector3 = fixture.grid_to_world(15, 14, 3.5)
	fixture.assert_path_connects(road, cabin, "Outpost road to cabin")
	fixture.assert_path_connects(cabin, lean_to, "Outpost cabin to lean-to")
	fixture.assert_path_crosses_levels(cabin, loft, "Outpost cabin to loft", 1.5, 3.0)
	fixture.assert_path_crosses_levels(loft, cabin, "Outpost loft to cabin", 1.5, 3.0)


func test_pine_hollow_outpost_blocks_north_cabin_wall_crossing() -> void:
	await fixture.begin_geometry()
	_populate_outpost_geometry()
	fixture.add_wall_obstacle(Vector3(13, 1, 9))
	fixture.add_wall_obstacle(Vector3(14, 1, 8))
	fixture.add_wall_obstacle(Vector3(15, 1, 9))
	assert_true(await fixture.bake(), "The Pine Hollow Outpost wall test should finish baking.")

	var cabin: Vector3 = fixture.grid_to_world(14, 13, 1.5)
	var north_pocket: Vector3 = fixture.grid_to_world(14, 9, 1.5)
	fixture.assert_path_does_not_connect(cabin, north_pocket, "Outpost north cabin wall crossing")


func _populate_outpost_geometry() -> void:
	for x in range(0, 32):
		for z in range(0, 32):
			fixture.add_block(Vector3(x, 0, z))
	# Cabin walls around x11..18/y10..17, leaving the declared west door at (11, 14).
	for x in range(11, 19):
		fixture.add_wall_obstacle(Vector3(x, 1, 10))
		fixture.add_wall_obstacle(Vector3(x, 1, 17))
	for z in range(11, 17):
		if z != 14:
			fixture.add_wall_obstacle(Vector3(11, 1, z))
		fixture.add_wall_obstacle(Vector3(18, 1, z))
	# Upper floor, authored staircase, upper walls, and cabin roof.
	for x in range(11, 19):
		for z in range(10, 18):
			if Vector2i(x, z) != Vector2i(15, 15):
				fixture.add_block(Vector3(x, 1, z))
	fixture.add_block(Vector3(15, 1, 15), "slope", 0)
	fixture.add_block(Vector3(15, 2, 14), "slope", 0)
	# Flanking lower-floor and upper-loft approach surfaces match the authored staircase contract.
	fixture.add_block(Vector3(14, 1, 15))
	fixture.add_block(Vector3(16, 1, 15))
	fixture.add_block(Vector3(15, 1, 16))
	fixture.add_block(Vector3(15, 2, 13))
	for x in range(11, 19):
		fixture.add_wall_obstacle(Vector3(x, 2, 10))
		fixture.add_wall_obstacle(Vector3(x, 2, 17))
	for z in range(11, 17):
		fixture.add_wall_obstacle(Vector3(11, 2, z))
		fixture.add_wall_obstacle(Vector3(18, 2, z))
	for x in range(11, 19):
		for z in range(10, 18):
			fixture.add_block(Vector3(x, 3, z))
