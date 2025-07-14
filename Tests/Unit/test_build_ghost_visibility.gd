extends GutTest

var level_scene: PackedScene
var level_instance: Node
var build_manager: BuildManager
var building_menu: Control

func before_all():
	var custom_mods: Array[DMod] = [Gamedata.mods.by_id("Core"), Gamedata.mods.by_id("Test")]
	Runtimedata.reconstruct(custom_mods)
	await get_tree().process_frame

func before_each():
	level_scene = load("res://level_generation.tscn")
	level_instance = level_scene.instantiate()
	add_child(level_instance)
	await get_tree().process_frame
	build_manager = level_instance.get_node("TacticalMap/BuildManager")
	building_menu = level_instance.get_node("HUD/BuildingMenu")

func after_each():
	if level_instance:
		level_instance.queue_free()
	await get_tree().process_frame

func after_all():
	Runtimedata.reset()

func test_ghost_visible_on_first_menu_open():
	building_menu.show()
	await get_tree().process_frame
	assert_true(build_manager.construction_ghost.visible, "Ghost should be visible when menu opens")

func test_ghost_updates_on_selection_change():
	building_menu.show()
	await get_tree().process_frame
	var option_button: OptionButton = building_menu.get_node(building_menu.construction_option_button)
	# Ensure at least two options
	assert_true(option_button.item_count > 1, "Need second option for test")
	option_button.select(1)
	building_menu._on_construction_option_button_item_selected(1)
	await get_tree().process_frame
	var expected_choice = option_button.get_item_text(1)
	assert_eq(build_manager.construction_choice, expected_choice, "Ghost choice should update")
