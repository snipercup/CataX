extends GutTest


const MapNavigationFixture = preload("res://Tests/Unit/helpers/map_navigation_fixture.gd")


var fixture


func before_each() -> void:
	fixture = MapNavigationFixture.new(self)
	await fixture.setup()


func after_each() -> void:
	await fixture.teardown()


func test_generated_semantic_single_storey_building_connects_exterior_to_interior() -> void:
	await fixture.begin_geometry()
	# Ground floor (cubes at y0) under the whole 4x4 footprint plus a west approach.
	for x in range(5, 12):
		for z in range(7, 11):
			fixture.add_block(Vector3(x, 0, z))
	# Enclosing walls at y1 with the west door gap at (7, 8).
	for x in range(7, 11):
		fixture.add_block(Vector3(x, 1, 7))
		fixture.add_block(Vector3(x, 1, 10))
	for z in range(7, 11):
		if z != 8:
			fixture.add_block(Vector3(7, 1, z))
		fixture.add_block(Vector3(10, 1, z))
	# Concrete roof at y2 so the interior reads as an enclosed single-storey building.
	for x in range(7, 11):
		for z in range(7, 11):
			fixture.add_block(Vector3(x, 2, z))

	assert_true(await fixture.bake(), "The single-storey navigation should finish baking.")

	var exterior: Vector3 = fixture.grid_to_world(5, 8, 1.5)
	var interior: Vector3 = fixture.grid_to_world(9, 8, 1.5)
	fixture.assert_path_connects(exterior, interior, "Exterior to interior")
	fixture.assert_path_connects(interior, exterior, "Interior to exterior")