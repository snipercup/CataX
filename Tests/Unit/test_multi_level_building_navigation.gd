extends GutTest


const MapNavigationFixture = preload("res://Tests/Unit/helpers/map_navigation_fixture.gd")


var fixture


func before_each() -> void:
	fixture = MapNavigationFixture.new(self)
	await fixture.setup()


func after_each() -> void:
	await fixture.teardown()


func test_generated_building_floor_and_authored_stair_geometry_connects_levels() -> void:
	await fixture.begin_geometry()

	# Physical geometry corresponding to the maintained Phase 6 recipe:
	# lower floor, open gap, upper floor, and an authored slope transition.
	var slope_position := Vector3(9, 1, 9)
	var high_edge := Vector2i(1, 0)
	var side := Vector2i(-high_edge.y, high_edge.x)
	fixture.add_block(slope_position, "slope", 90)
	for distance in range(1, 4):
		for side_offset in range(-1, 2):
			var high_offset := high_edge * distance + side * side_offset
			var low_offset := -high_edge * distance + side * side_offset
			fixture.add_block(slope_position + Vector3(high_offset.x, 0, high_offset.y))
			fixture.add_block(slope_position + Vector3(low_offset.x, -1, low_offset.y))

	assert_true(
		await fixture.bake(),
		"The generated building navigation should finish baking."
	)

	var lower: Vector3 = fixture.grid_to_world(7, 9, 1.5)
	var upper: Vector3 = fixture.grid_to_world(11, 9, 2.5)
	fixture.assert_path_crosses_levels(lower, upper, "The authored staircase should connect lower and upper building floors", 1.5, 2.5)