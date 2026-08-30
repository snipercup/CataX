extends RefCounted
class_name MapNavigationFixture

## Generic GUT helper for chunk navigation tests: chunk lifecycle, navigation
## geometry sources, async baking, and NavigationServer3D path assertions.
## It receives endpoint coordinates and labels only; it knows nothing about
## specific maps, rooms, or farmland semantics.


var gut: Node
var chunk: Chunk


func _init(gut_instance: Node) -> void:
	gut = gut_instance


class TestChunk extends Chunk:
	func _ready():
		pass


## Creates the chunk and its isolated navigation map. Must be awaited.
func setup() -> void:
	chunk = TestChunk.new()
	gut.add_child(chunk)
	chunk.source_geometry_data = NavigationMeshSourceGeometryData3D.new()
	chunk.setup_navigation()
	await gut.get_tree().physics_frame


## Frees the chunk and its navigation map. Must be awaited.
func teardown() -> void:
	if chunk and is_instance_valid(chunk):
		var navigation_map := chunk.navigation_map_id
		chunk.free()
		if navigation_map.is_valid():
			NavigationServer3D.free_rid(navigation_map)
	await gut.get_tree().process_frame


## Resets the chunk's navigation state before building a new geometry source.
func begin_geometry() -> void:
	chunk.navigation_region.set_navigation_mesh(null)
	await gut.wait_physics_frames(2)
	chunk.navigation_mesh = NavigationMesh.new()
	chunk._configure_navigation_mesh(chunk.navigation_mesh)
	chunk.source_geometry_data = NavigationMeshSourceGeometryData3D.new()
	chunk.block_positions.clear()


## Records one block into the navigation source. shape is "cube" or "slope";
## tile_rotation is the editor-facing tile rotation used for runtime conversion.
func add_block(position: Vector3, shape: String = "cube", tile_rotation: int = 0) -> void:
	var runtime_rotation := chunk.get_block_rotation(shape, tile_rotation)
	var key := "%s,%s,%s" % [position.x, position.y, position.z]
	chunk.block_positions[key] = {"rotation": runtime_rotation, "shape": shape}
	chunk.add_mesh_to_navigation_data(position, runtime_rotation, shape)


## Bakes the recorded geometry asynchronously. Must be awaited.
func bake() -> bool:
	var previous_iteration := NavigationServer3D.map_get_iteration_id(chunk.navigation_map_id)
	chunk.update_navigation_mesh()
	var baked: bool = await gut.wait_for_signal(chunk.navigation_mesh_baked, 5)
	if not baked:
		return false
	return await gut.wait_until(
		func(): return NavigationServer3D.map_get_iteration_id(chunk.navigation_map_id) > previous_iteration,
		5,
		0.05
	)


## Converts a map-grid column to the world-space walking point on top of a
## floor whose cubes sit at cube_y. grid_to_world(8, 9, 1.5) centers column
## (8, 9) with a walk height of 1.5.
func grid_to_world(grid_x: int, grid_z: int, walk_y: float) -> Vector3:
	return Vector3(grid_x + 0.5, walk_y, grid_z + 0.5)


## Asserts a navigation path exists between two world points.
func assert_path_connects(start: Vector3, finish: Vector3, label: String, tolerance: float = 0.6) -> void:
	var path := NavigationServer3D.map_get_path(chunk.navigation_map_id, start, finish, true)
	gut.assert_gt(path.size(), 1, "%s should produce a navigation path." % label)
	if path.size() <= 1:
		return
	gut.assert_lt(
		path[0].distance_to(start),
		tolerance,
		"%s path should begin near its source." % label
	)
	gut.assert_lt(
		path[path.size() - 1].distance_to(finish),
		tolerance,
		"%s path should end near its destination." % label
	)


## Asserts a navigation path exists and spans the two storey surfaces.
func assert_path_crosses_levels(
	start: Vector3, finish: Vector3, label: String, lower_walk_y: float, upper_walk_y: float
) -> void:
	var path := NavigationServer3D.map_get_path(chunk.navigation_map_id, start, finish, true)
	gut.assert_gt(path.size(), 1, "%s should produce a navigation path." % label)
	if path.size() <= 1:
		return
	var minimum_y := INF
	var maximum_y := -INF
	for point in path:
		minimum_y = min(minimum_y, point.y)
		maximum_y = max(maximum_y, point.y)
	gut.assert_lt(minimum_y, lower_walk_y + 0.1, "%s path should include the lower surface." % label)
	gut.assert_gt(maximum_y, upper_walk_y - 0.1, "%s path should include the upper surface." % label)