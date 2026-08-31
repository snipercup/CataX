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
	# Ground level: documented farmhouse footprint x3..18/y19..29 plus a west approach.
	for x in range(1, 19):
		for z in range(19, 30):
			fixture.add_block(Vector3(x, 0, z))
	# Lower exterior walls with a west front-door gap at (3, 24).
	for x in range(3, 19):
		fixture.add_block(Vector3(x, 1, 19))
		fixture.add_block(Vector3(x, 1, 29))
	for z in range(20, 29):
		if z != 24:
			fixture.add_block(Vector3(3, 1, z))
		fixture.add_block(Vector3(18, 1, z))
	# Kitchen/ground-room partition with its interior doorway at (7, 24).
	fixture.add_block(Vector3(7, 1, 23))
	fixture.add_block(Vector3(7, 1, 25))
	# Upper floor: whole footprint except the stairwell hole above the lower slope.
	for x in range(3, 19):
		for z in range(19, 30):
			if Vector2i(x, z) == Vector2i(10, 25):
				continue
			fixture.add_block(Vector3(x, 1, z))
	# Authored z1→z2 staircase, with editor rotation 0 (south-to-north ascent).
	fixture.add_block(Vector3(10, 1, 25), "slope", 0)
	fixture.add_block(Vector3(10, 2, 24), "slope", 0)
	# Upper-storey exterior walls and roof.
	for x in range(3, 19):
		fixture.add_block(Vector3(x, 2, 19))
		fixture.add_block(Vector3(x, 2, 29))
	for z in range(20, 29):
		fixture.add_block(Vector3(3, 2, z))
		fixture.add_block(Vector3(18, 2, z))
	for x in range(3, 19):
		for z in range(19, 30):
			fixture.add_block(Vector3(x, 3, z))

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
