extends GutTest

var build_manager: BuildManager
var ghost: MeshInstance3D


func before_all():
	var custom_mods: Array[DMod] = [Gamedata.mods.by_id("Core"), Gamedata.mods.by_id("Test")]
	Runtimedata.reconstruct(custom_mods)
	await get_tree().process_frame


func before_each():
	build_manager = preload("res://Scripts/BuildManager.gd").new()
	ghost = preload("res://Scripts/ConstructionGhost.gd").new()
	build_manager.construction_ghost = ghost
	add_child(ghost)
	add_child(build_manager)
	await get_tree().process_frame


func after_each():
	if is_instance_valid(build_manager):
		build_manager.queue_free()
	if is_instance_valid(ghost):
		ghost.queue_free()
	await get_tree().process_frame


func test_hud_selection_starts_building() -> void:
	build_manager._on_hud_construction_chosen("furniture", "test_glass_window")
	assert_true(build_manager.is_building, "Build mode should enable after selection")
	assert_true(ghost.visible, "Ghost should be visible after selection")
