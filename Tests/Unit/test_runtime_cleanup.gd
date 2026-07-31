extends GutTest


func test_runtime_reset_releases_parent_cycles() -> void:
	var custom_mods: Array[DMod] = [Gamedata.mods.by_id("Core"), Gamedata.mods.by_id("Test")]
	Runtimedata.reconstruct(custom_mods)
	var collection: RPlayerAttributes = Runtimedata.playerattributes
	var attribute: RPlayerAttribute = collection.get_all().values()[0]
	var collection_ref: WeakRef = weakref(collection)
	var attribute_ref: WeakRef = weakref(attribute)

	Runtimedata.reset()
	collection = null
	attribute = null

	assert_null(collection_ref.get_ref(), "Runtime collection should be released after reset")
	assert_null(attribute_ref.get_ref(), "Runtime entries should be released after reset")


func test_player_teardown_releases_attribute_cycles() -> void:
	var custom_mods: Array[DMod] = [Gamedata.mods.by_id("Core"), Gamedata.mods.by_id("Test")]
	Runtimedata.reconstruct(custom_mods)
	var player := preload("res://Scenes/player.tscn").instantiate() as Player
	player.testing = true
	add_child(player)
	await get_tree().process_frame
	var attribute: PlayerAttribute = player.attributes.values()[0]
	var attribute_ref: WeakRef = weakref(attribute)

	player.queue_free()
	await get_tree().process_frame
	player = null
	attribute = null

	assert_null(attribute_ref.get_ref(), "Player attributes should be released with their player")
	Runtimedata.reset()


func test_inventory_cleanup_releases_constraint_objects() -> void:
	var inventory := InventoryStacked.new()
	inventory.capacity = 1000
	var manager: RefCounted = inventory.get_constraint_manager()
	var manager_ref: WeakRef = weakref(manager)
	var weight_ref: WeakRef = weakref(manager.get_weight_constraint())
	var stacks_ref: WeakRef = weakref(manager.get_stacks_constraint())

	inventory.free()
	inventory = null
	manager = null

	assert_null(manager_ref.get_ref(), "Inventory constraint manager should be released")
	assert_null(weight_ref.get_ref(), "Inventory weight constraint should be released")
	assert_null(stacks_ref.get_ref(), "Inventory stacks constraint should be released")


func test_inventory_cleanup_is_idempotent() -> void:
	var inventory := InventoryStacked.new()
	inventory.capacity = 1000

	inventory.prepare_to_free()
	inventory.prepare_to_free()

	assert_null(inventory.get_constraint_manager(), "Repeated cleanup should remain safe")
	inventory.free()


func test_npc_collection_cleanup_releases_parent_cycles() -> void:
	var npcs := DNpcs.new("MissingTestMod")
	var npc := DNpc.new({"id": "cleanup_test"}, npcs)
	npcs.get_all()[npc.id] = npc
	var npcs_ref: WeakRef = weakref(npcs)
	var npc_ref: WeakRef = weakref(npc)

	npcs.clear()
	npcs = null
	npc = null

	assert_null(npcs_ref.get_ref(), "NPC collection should be released after cleanup")
	assert_null(npc_ref.get_ref(), "NPC entries should be released after cleanup")


func test_item_manager_teardown_releases_owned_inventory() -> void:
	var item_manager := preload("res://Scripts/item_manager.gd").new()
	var inventory: InventoryStacked = item_manager.initialize_inventory()
	var inventory_ref: WeakRef = weakref(inventory)
	item_manager.playerInventory = inventory
	add_child(item_manager)

	item_manager.queue_free()
	await get_tree().process_frame
	inventory = null
	item_manager = null

	assert_null(inventory_ref.get_ref(), "ItemManager should release inventories it owns")
