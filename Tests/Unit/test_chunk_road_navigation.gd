extends GutTest


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


func test_painted_ground_road_route_is_navigable_between_edge_endpoints():
	# The maintained Phase 7 recipe paints a one-cell route. Use a three-cell
	# navigation-source width here so the test checks route continuity without
	# depending on the navigation agent-radius margin at the road edges.
	test_chunk.navigation_region.set_navigation_mesh(null)
	await wait_physics_frames(2)
	test_chunk.navigation_mesh = NavigationMesh.new()
	test_chunk._configure_navigation_mesh(test_chunk.navigation_mesh)
	test_chunk.source_geometry_data = NavigationMeshSourceGeometryData3D.new()
	test_chunk.block_positions.clear()
	for x in range(32):
		for z in range(15, 18):
			_add_navigation_block(Vector3(x, 0, z))

	test_chunk.update_navigation_mesh()
	assert_true(
		await wait_for_signal(test_chunk.navigation_mesh_baked, 5),
		"The generated road route should finish baking navigation."
	)

	var endpoints := {
		"west": Vector3(4.5, 1.0, 16.5),
		"east": Vector3(27.5, 1.0, 16.5),
	}
	await wait_physics_frames(2)

	var path := NavigationServer3D.map_get_path(
		test_chunk.navigation_map_id, endpoints.west, endpoints.east, true
	)
	assert_gt(path.size(), 1, "A painted road route should connect its west and east endpoints.")
	if path.size() <= 1:
		return
	assert_lt(path[0].distance_to(endpoints.west), 0.6)
	assert_lt(path[path.size() - 1].distance_to(endpoints.east), 0.6)


func _add_navigation_block(position: Vector3) -> void:
	var key := "%s,%s,%s" % [position.x, position.y, position.z]
	test_chunk.block_positions[key] = {"rotation": 0, "shape": "cube"}
	test_chunk.add_mesh_to_navigation_data(position, 0, "cube")
