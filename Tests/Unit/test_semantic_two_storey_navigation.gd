extends GutTest


const MapNavigationFixture = preload("res://Tests/Unit/helpers/map_navigation_fixture.gd")


var fixture


func before_each() -> void:
	fixture = MapNavigationFixture.new(self)
	await fixture.setup()


func after_each() -> void:
	await fixture.teardown()


func test_generated_semantic_two_storey_building_connects_exterior_ground_and_upper_loft() -> void:
	await fixture.begin_geometry()
	# Ground floor (cubes at y0): the whole 6x6 footprint plus a west approach.
	for x in range(4, 13):
		for z in range(7, 13):
			fixture.add_block(Vector3(x, 0, z))
	# Lower walls at y1 with the west door gap at (7, 9).
	for x in range(7, 13):
		fixture.add_block(Vector3(x, 1, 7))
		fixture.add_block(Vector3(x, 1, 12))
	for z in range(8, 12):
		fixture.add_block(Vector3(7, 1, z))
		fixture.add_block(Vector3(12, 1, z))
	# Upper floor at y1: 6x6 slab minus the stairwell hole above the lower slope.
	for x in range(7, 13):
		for z in range(7, 13):
			if Vector2i(x, z) == Vector2i(10, 10):
				continue
			fixture.add_block(Vector3(x, 1, z))
	# Slopes: lower ramp up at (10, 1, 10), upper slope inside the loft at (10, 2, 9).
	# Editor rotation 0 raises the north edge, so travel runs south->north.
	fixture.add_block(Vector3(10, 1, 10), "slope", 0)
	fixture.add_block(Vector3(10, 2, 9), "slope", 0)
	# Upper-floor approach blocks flanking the upper slope at loft level (walk y2.5),
	# plus ground floors beside the lower slope.
	fixture.add_block(Vector3(9, 1, 10))
	fixture.add_block(Vector3(11, 1, 10))
	fixture.add_block(Vector3(10, 1, 11))
	fixture.add_block(Vector3(10, 2, 8), "cube")
	fixture.add_block(Vector3(10, 2, 8), "cube")
	# Stairwell wall ring at y2 so the upper floor reads as an enclosed storey.
	for x in range(7, 13):
		fixture.add_block(Vector3(x, 2, 7))
		fixture.add_block(Vector3(x, 2, 12))
	for z in range(8, 12):
		fixture.add_block(Vector3(7, 2, z))
		fixture.add_block(Vector3(12, 2, z))
	# Roof at y3.
	for x in range(7, 13):
		for z in range(7, 13):
			fixture.add_block(Vector3(x, 3, z))

	assert_true(await fixture.bake(), "The two-storey navigation should finish baking.")

	var exterior: Vector3 = fixture.grid_to_world(5, 9, 1.5)
	var ground_room: Vector3 = fixture.grid_to_world(8, 9, 1.5)
	var stairwell_floor: Vector3 = fixture.grid_to_world(10, 11, 1.5)
	var upper_loft: Vector3 = fixture.grid_to_world(10, 9, 3.5)
	fixture.assert_path_connects(exterior, ground_room, "Exterior to ground room")
	fixture.assert_path_connects(ground_room, exterior, "Ground room to exterior")
	fixture.assert_path_crosses_levels(
		stairwell_floor, upper_loft, "Ground to upper loft", 1.5, 3.1
	)
	fixture.assert_path_crosses_levels(
		upper_loft, stairwell_floor, "Upper loft to ground", 1.5, 3.1
	)