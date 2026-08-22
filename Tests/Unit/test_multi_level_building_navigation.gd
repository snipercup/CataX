extends GutTest


class BuildingNavigationTestChunk extends Chunk:
	func _ready():
		pass


var test_chunk: Chunk


func before_each():
	test_chunk = BuildingNavigationTestChunk.new()
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


func test_generated_building_floor_and_authored_stair_geometry_connects_levels():
	test_chunk.navigation_region.set_navigation_mesh(null)
	await wait_physics_frames(2)
	test_chunk.navigation_mesh = NavigationMesh.new()
	test_chunk._configure_navigation_mesh(test_chunk.navigation_mesh)
	test_chunk.source_geometry_data = NavigationMeshSourceGeometryData3D.new()
	test_chunk.block_positions.clear()

	# Physical geometry corresponding to the maintained Phase 6 recipe:
	# lower floor, open gap, upper floor, and an authored slope transition.
	var slope_position := Vector3(9, 1, 9)
	var high_edge := Vector2i(1, 0)
	var side := Vector2i(-high_edge.y, high_edge.x)
	_add_navigation_block(slope_position, test_chunk.get_block_rotation("slope", 90), "slope")
	for distance in range(1, 4):
		for side_offset in range(-1, 2):
			var high_offset := high_edge * distance + side * side_offset
			var low_offset := -high_edge * distance + side * side_offset
			_add_navigation_block(slope_position + Vector3(high_offset.x, 0, high_offset.y), 0, "cube")
			_add_navigation_block(slope_position + Vector3(low_offset.x, -1, low_offset.y), 0, "cube")

	test_chunk.update_navigation_mesh()
	assert_true(
		await wait_for_signal(test_chunk.navigation_mesh_baked, 5),
		"The generated building navigation should finish baking."
	)
	await wait_physics_frames(2)

	var lower := Vector3(7.5, 1.5, 9.5)
	var upper := Vector3(11.5, 2.5, 9.5)
	var path := NavigationServer3D.map_get_path(test_chunk.navigation_map_id, lower, upper, true)
	if path.size() <= 1:
		await wait_physics_frames(2)
		path = NavigationServer3D.map_get_path(test_chunk.navigation_map_id, lower, upper, true)
	assert_gt(path.size(), 1, "The authored staircase should connect lower and upper building floors.")
	if path.size() <= 1:
		return
	var minimum_y := INF
	var maximum_y := -INF
	for point in path:
		minimum_y = min(minimum_y, point.y)
		maximum_y = max(maximum_y, point.y)
	assert_lt(minimum_y, 1.6)
	assert_gt(maximum_y, 2.4)


func _add_navigation_block(position: Vector3, rotation: int, shape: String) -> void:
	var key := "%s,%s,%s" % [position.x, position.y, position.z]
	test_chunk.block_positions[key] = {"rotation": rotation, "shape": shape}
	test_chunk.add_mesh_to_navigation_data(position, rotation, shape)
