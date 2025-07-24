extends GutTest


class DummyBuildMenu:
	func is_visible() -> bool:
		return true

	func get_selected_type_and_choice() -> Dictionary:
		return {"type": "block", "choice": "dummy"}


class DummyChunk:
	extends Node3D
	var added_block_pos: Vector3
	var spawned_furniture_data: Dictionary
	var mypos: Vector3 = Vector3.ZERO
	var position: Vector3 = Vector3.ZERO

	func add_block(id: String, pos: Vector3) -> void:
		added_block_pos = pos

	func spawn_furniture(data: Dictionary) -> void:
		spawned_furniture_data = data


class DummyLevelGenerator:
	extends Node3D
	var dummy_chunk := DummyChunk.new()

	func get_chunk_from_position(pos: Vector3) -> DummyChunk:
		return dummy_chunk


class TestBuildManager:
	extends BuildManager
	var update_called := false

	func update_ghost():
		update_called = true


var build_manager: TestBuildManager
var original_item_manager


func before_each():
	build_manager = TestBuildManager.new()
	build_manager.construction_ghost = MeshInstance3D.new()
	build_manager.level_generator = DummyLevelGenerator.new()
	add_child(build_manager)
	original_item_manager = ItemManager
	ItemManager = preload("res://Scripts/item_manager.gd").new()
	ItemManager.get_accessibleitem_amount = func(id): return 10
	ItemManager.remove_resource = func(id, amt, src): return true
	ItemManager.allAccessibleItems = []


func after_each():
	if build_manager:
		build_manager.queue_free()
	ItemManager = original_item_manager


func test_update_ghost_called_on_menu_open():
	build_manager.update_called = false
	build_manager._on_build_menu_visibility_change(DummyBuildMenu.new())
	assert_true(build_manager.update_called)


func test_update_ghost_called_after_block():
	build_manager.construction_type = "block"
	build_manager.construction_choice = "dummy"
	build_manager.update_called = false
	var data = {"pos": Vector3(33, 0, 65)}
	build_manager.handle_block_construction(data, build_manager.level_generator.dummy_chunk)
	assert_true(build_manager.update_called)
	assert_eq(build_manager.level_generator.dummy_chunk.added_block_pos, Vector3(1, 0, 1))
