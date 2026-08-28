extends GutTest


const MapNavigationFixture = preload("res://Tests/Unit/helpers/map_navigation_fixture.gd")


var fixture


func before_each() -> void:
	fixture = MapNavigationFixture.new(self)
	await fixture.setup()


func after_each() -> void:
	await fixture.teardown()


func test_painted_ground_road_route_is_navigable_between_edge_endpoints() -> void:
	# The maintained Phase 7 recipe paints a one-cell route. Use a three-cell
	# navigation-source width here so the test checks route continuity without
	# depending on the navigation agent-radius margin at the road edges.
	await fixture.begin_geometry()
	for x in range(32):
		for z in range(15, 18):
			fixture.add_block(Vector3(x, 0, z))

	assert_true(
		await fixture.bake(),
		"The generated road route should finish baking navigation."
	)

	var west: Vector3 = fixture.grid_to_world(4, 16, 1.0)
	var east: Vector3 = fixture.grid_to_world(27, 16, 1.0)
	await gut_wait_physics_frames(2)
	fixture.assert_path_connects(west, east, "A painted road route should connect its west and east endpoints")


func gut_wait_physics_frames(frames: int) -> void:
	await get_tree().physics_frame
	if frames > 1:
		await get_tree().physics_frame