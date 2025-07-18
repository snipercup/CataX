extends GutTest

var item_manager: ItemManager
var player: Player
var left_slot: EquippedItem
var dummy_slot: Control
var shooter: Node


func before_all():
	var custom_mods: Array[DMod] = [Gamedata.mods.by_id("Core"), Gamedata.mods.by_id("Test")]
	Runtimedata.reconstruct(custom_mods)
	await get_tree().process_frame


func before_each():
	item_manager = preload("res://Scripts/item_manager.gd").new()
	add_child(item_manager)
	await get_tree().process_frame
	item_manager.playerInventory = item_manager.initialize_inventory()

	var PLAYER = preload("res://Scenes/player.tscn")
	player = PLAYER.instantiate()
	player.testing = true
	add_child(player)
	player.global_position = Vector3(0, 1.5, 15)
	await get_tree().process_frame

	shooter = player.get_node("Shooting")
	left_slot = player.held_item_slots[0]
	dummy_slot = Control.new()
	add_child(dummy_slot)

	General.is_mouse_outside_hud = true
	General.is_allowed_to_shoot = true


func after_each():
	if player:
		player.queue_free()
	if item_manager:
		item_manager.queue_free()
	if dummy_slot:
		dummy_slot.queue_free()
	await get_tree().process_frame


func after_all():
	Runtimedata.reset()


func _create_weapon() -> InventoryItem:
	return item_manager.playerInventory.create_and_add_item("generic_test_pistol")


func _create_magazine(ammo: int) -> InventoryItem:
	var mag: InventoryItem = item_manager.playerInventory.create_and_add_item(
		"generic_test_pistol_magazine"
	)
	var props = mag.get_property("Magazine")
	props["current_ammo"] = ammo
	mag.set_property("Magazine", props)
	return mag


func test_bullet_count_and_ammo_reduction() -> void:
	var gun = _create_weapon()
	var mag = _create_magazine(1)
	ItemManager.insert_magazine(gun, mag)
	left_slot.equip_item(gun, dummy_slot)
	shooter.call("reset_bullet_count")
	PlayerInputSignalBroker.try_activate_equipped_item(0).emit(0)
	await get_tree().process_frame
	assert_eq(shooter.call("get_bullet_count"), 1, "Expected one bullet spawned")
	var props = mag.get_property("Magazine")
	assert_eq(int(props["current_ammo"]), 0, "Ammo should decrease by one")


func test_fire_without_ammo() -> void:
	var gun = _create_weapon()
	var mag = _create_magazine(0)
	ItemManager.insert_magazine(gun, mag)
	left_slot.equip_item(gun, dummy_slot)
	shooter.call("reset_bullet_count")
	PlayerInputSignalBroker.try_activate_equipped_item(0).emit(0)
	await get_tree().process_frame
	assert_eq(shooter.call("get_bullet_count"), 0, "No bullet should spawn with empty magazine")
	var props = mag.get_property("Magazine")
	assert_eq(int(props["current_ammo"]), 0, "Ammo should remain zero")
