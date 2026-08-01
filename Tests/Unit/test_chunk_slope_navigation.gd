extends GutTest

const SLOPE_CASES := [
	{"editor_rotation": 0, "high_edge": Vector2i(0, -1)},
	{"editor_rotation": 90, "high_edge": Vector2i(1, 0)},
	{"editor_rotation": 180, "high_edge": Vector2i(0, 1)},
	{"editor_rotation": 270, "high_edge": Vector2i(-1, 0)},
]

class NavigationTestChunk extends Chunk:
	func _ready():
		pass


var test_chunk: Chunk


func before_each():
	test_chunk = NavigationTestChunk.new()
	add_child(test_chunk)
	test_chunk.source_geometry_data = NavigationMeshSourceGeometryData3D.new()
	test_chunk.setup_navigation()
	await get_tree().physics_frame


func after_each():
	if test_chunk and is_instance_valid(test_chunk):
		var navigation_map := test_chunk.navigation_map_id
		test_chunk.free()
		if navigation_map.is_valid():
			NavigationServer3D.free_rid(navigation_map)
	await get_tree().process_frame


func test_baked_navigation_connects_both_sides_of_every_slope():
	for slope_case in SLOPE_CASES:
		await _assert_baked_transition(slope_case)


func _assert_baked_transition(slope_case: Dictionary) -> void:
	test_chunk.navigation_region.set_navigation_mesh(null)
	await wait_physics_frames(2)
	test_chunk.navigation_mesh = _create_navigation_mesh()
	test_chunk.source_geometry_data = NavigationMeshSourceGeometryData3D.new()
	test_chunk.block_positions.clear()
	_build_transition_geometry(slope_case)
	var previous_iteration := NavigationServer3D.map_get_iteration_id(
		test_chunk.navigation_map_id
	)
	test_chunk.update_navigation_mesh()
	assert_true(
		await wait_for_signal(test_chunk.navigation_mesh_baked, 5),
		"Editor rotation %d should finish baking navigation." % slope_case.editor_rotation
	)
	var endpoints := _transition_endpoints(slope_case.high_edge)
	var navigation_is_synchronized = func():
		return (
			NavigationServer3D.map_get_iteration_id(test_chunk.navigation_map_id)
			> previous_iteration
			and NavigationServer3D.map_get_closest_point(
				test_chunk.navigation_map_id, endpoints.low
			)
			!= Vector3.ZERO
		)
	var synchronized: bool = await wait_until(navigation_is_synchronized, 5, 0.05)
	assert_true(
		synchronized,
		"Editor rotation %d should synchronize its baked navigation map."
		% slope_case.editor_rotation
	)
	if not synchronized:
		return
	_assert_path_connects_levels(
		endpoints.low,
		endpoints.high,
		"Editor rotation %d should navigate from low to high." % slope_case.editor_rotation
	)
	_assert_path_connects_levels(
		endpoints.high,
		endpoints.low,
		"Editor rotation %d should navigate from high to low." % slope_case.editor_rotation
	)


func _create_navigation_mesh() -> NavigationMesh:
	var result := NavigationMesh.new()
	test_chunk._configure_navigation_mesh(result)
	return result


func _build_transition_geometry(slope_case: Dictionary) -> void:
	var slope_position := Vector3(16, 1, 16)
	var high_edge: Vector2i = slope_case.high_edge
	var side := Vector2i(-high_edge.y, high_edge.x)
	var low_edge := -high_edge

	var runtime_rotation := test_chunk.get_block_rotation(
		"slope", slope_case.editor_rotation
	)
	_add_navigation_block(slope_position, runtime_rotation, "slope")
	for distance in range(1, 4):
		for side_offset in range(-1, 2):
			var high_offset := high_edge * distance + side * side_offset
			var low_offset := low_edge * distance + side * side_offset
			_add_navigation_block(
				slope_position + Vector3(high_offset.x, 0, high_offset.y), 0, "cube"
			)
			_add_navigation_block(
				slope_position + Vector3(low_offset.x, -1, low_offset.y), 0, "cube"
			)


func _add_navigation_block(position: Vector3, rotation: int, shape: String) -> void:
	var key := "%s,%s,%s" % [position.x, position.y, position.z]
	test_chunk.block_positions[key] = {"rotation": rotation, "shape": shape}
	test_chunk.add_mesh_to_navigation_data(position, rotation, shape)


func _transition_endpoints(high_edge: Vector2i) -> Dictionary:
	var slope_center := Vector3(16.5, 0, 16.5)
	var horizontal_high := Vector3(high_edge.x, 0, high_edge.y) * 2.0
	return {
		"low": slope_center - horizontal_high + Vector3(0, 1.5, 0),
		"high": slope_center + horizontal_high + Vector3(0, 2.5, 0),
	}


func _assert_path_connects_levels(start: Vector3, finish: Vector3, message: String) -> void:
	var path := NavigationServer3D.map_get_path(
		test_chunk.navigation_map_id, start, finish, true
	)
	assert_gt(path.size(), 1, message)
	if path.size() <= 1:
		return
	assert_lt(path[0].distance_to(start), 0.35, "%s Path should begin near its source." % message)
	assert_lt(
		path[path.size() - 1].distance_to(finish),
		0.35,
		"%s Path should end near its destination." % message
	)
	var minimum_y := INF
	var maximum_y := -INF
	for point in path:
		minimum_y = min(minimum_y, point.y)
		maximum_y = max(maximum_y, point.y)
	assert_lt(minimum_y, 1.6, "%s Path should include the lower surface." % message)
	assert_gt(maximum_y, 2.4, "%s Path should include the upper surface." % message)