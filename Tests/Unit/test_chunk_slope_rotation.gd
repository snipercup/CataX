extends GutTest

const SLOPE_CASES := [
	{"editor_rotation": 0, "internal_rotation": 90, "high_edge": Vector2i(0, -1)},
	{"editor_rotation": 90, "internal_rotation": 0, "high_edge": Vector2i(1, 0)},
	{"editor_rotation": 180, "internal_rotation": 270, "high_edge": Vector2i(0, 1)},
	{"editor_rotation": 270, "internal_rotation": 180, "high_edge": Vector2i(-1, 0)},
]

var test_chunk: Chunk


func before_each():
	test_chunk = Chunk.new()
	test_chunk.source_geometry_data = NavigationMeshSourceGeometryData3D.new()


func after_each():
	if test_chunk and is_instance_valid(test_chunk):
		test_chunk.free()


func test_editor_slope_rotations_convert_to_internal_rotations():
	for slope_case in SLOPE_CASES:
		assert_eq(
			test_chunk.get_block_rotation("slope", slope_case.editor_rotation),
			slope_case.internal_rotation,
			"Editor rotation %d should use internal rotation %d."
			% [slope_case.editor_rotation, slope_case.internal_rotation]
		)


func test_converted_slope_mesh_has_expected_high_edge():
	for slope_case in SLOPE_CASES:
		var vertices := test_chunk.calculate_slope_vertices(
			slope_case.internal_rotation, Vector3.ZERO
		)
		assert_eq(
			_high_edge_from_vertices(vertices.slice(0, 4), Vector2.ZERO),
			slope_case.high_edge,
			"Editor rotation %d should produce the expected mesh high edge."
			% slope_case.editor_rotation
		)


func test_converted_slope_collider_has_expected_high_edge():
	for slope_case in SLOPE_CASES:
		var collider := test_chunk._create_slope_collider(
			Vector3.ZERO, slope_case.internal_rotation
		)
		add_child(collider)
		await get_tree().process_frame

		var transformed_points := PackedVector3Array()
		for point in collider.shape.points:
			transformed_points.append(collider.transform.basis * point)
		assert_eq(
			_high_edge_from_vertices(transformed_points, Vector2.ZERO),
			slope_case.high_edge,
			"Editor rotation %d should produce the expected collider high edge."
			% slope_case.editor_rotation
		)
		collider.queue_free()
		await get_tree().process_frame


func test_converted_slope_navigation_faces_have_expected_high_edge():
	var block_position := Vector3(16, 0, 16)
	var block_center := Vector2(block_position.x + 0.5, block_position.z + 0.5)
	for slope_case in SLOPE_CASES:
		test_chunk.source_geometry_data.clear()
		test_chunk.add_mesh_to_navigation_data(
			block_position, slope_case.internal_rotation, "slope"
		)
		assert_eq(
			_high_edge_from_vertices(
				_navigation_vertices(test_chunk.source_geometry_data.get_vertices()), block_center
			),
			slope_case.high_edge,
			"Editor rotation %d should produce the expected navigation high edge."
			% slope_case.editor_rotation
		)


func _navigation_vertices(values: PackedFloat32Array) -> PackedVector3Array:
	var vertices := PackedVector3Array()
	for index in range(0, values.size(), 3):
		vertices.append(Vector3(values[index], values[index + 1], values[index + 2]))
	return vertices


func _high_edge_from_vertices(vertices: PackedVector3Array, center: Vector2) -> Vector2i:
	var highest_y := -INF
	for vertex in vertices:
		highest_y = max(highest_y, vertex.y)

	var high_center := Vector2.ZERO
	var high_count := 0
	for vertex in vertices:
		if is_equal_approx(vertex.y, highest_y):
			high_center += Vector2(vertex.x, vertex.z)
			high_count += 1
	high_center = high_center / high_count - center

	if abs(high_center.x) > abs(high_center.y):
		return Vector2i(int(sign(high_center.x)), 0)
	return Vector2i(0, int(sign(high_center.y)))
