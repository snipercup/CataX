class_name ContainerItem
extends Node3D

# This is a standalone class that you can use to make a container of a 3d node
# For example, adding this as a child to furniture will allow the player to add and remove
# items from it when it's in proximity


var inventory: Inventory
var containerpos: Vector3
var sprite_3d: Sprite3D
var containertexture: Texture # The texture set for this container
var itemgroup: String # The ID of an itemgroup that it creates loot from
var ritemgroup: RItemgroup # The ID of an itemgroup that it creates loot from


# Called when the node enters the scene tree for the first time.
func _ready():
	position = containerpos
	 # If no item was added we delete the container if it's not a child of some furniture
	_on_item_removed(null)
	if containertexture:
		set_texture(containertexture)


# Called when a function creates this class using ContainerItem.new(container_json)
# Basic setup for this container. Should be called before adding it to the scene tree
# Example item:
# {
# 	"itemgroups": ["destroyed_furniture_medium"],
# 	"global_position_x": 2,
# 	"global_position_y": 1,
# 	"global_position_z": 17
# }
func _init(item: Dictionary):
	_initialize_container(item)
	create_loot()


# Example item:
# {
# 	"itemgroups": ["destroyed_furniture_medium"],
# 	"global_position_x": 2,
# 	"global_position_y": 1,
# 	"global_position_z": 17
# }
func _initialize_container(item: Dictionary):
	containerpos = Vector3(item.global_position_x, item.global_position_y, item.global_position_z)
	add_to_group("Containers")
	_create_inventory()
	_create_area3d()

	if item.has("inventory"):
		deserialize_and_apply_items.call_deferred(item.inventory)
	# containertexture may be set when a furniture is destroyed and spawns this container
	if item.has("containertexture"):
		containertexture = item.containertexture
	create_sprite()

	# Check if the item has itemgroups, pick one at random and set the itemgroup property
	if item.has("itemgroups"):
		var itemgroups_array: Array = item.itemgroups
		if itemgroups_array.size() > 0:
			itemgroup = itemgroups_array.pick_random()
			# Attempt to retrieve the itemgroup data from Gamedata
			ritemgroup = Runtimedata.itemgroups.by_id(itemgroup)
			if ritemgroup.use_sprite:
				containertexture = ritemgroup.sprite


# Will add item to the inventory based on the assigned itemgroup
# Only new furniture will have an itemgroup assigned, not previously saved furniture.
func create_loot():
	if not itemgroup or itemgroup == "":
		return
	# A flag to track whether items were added
	var item_added: bool = false
	
	# Check if the itemgroup data exists and has items
	if ritemgroup:
		var groupmode: String = ritemgroup.mode # can be "Collection" or "Distribution".
		if groupmode == "Collection":
			item_added = _add_items_to_inventory_collection_mode(ritemgroup.items)
		elif groupmode == "Distribution":
			item_added = _add_items_to_inventory_distribution_mode(ritemgroup.items)

	# Set the texture if an item was successfully added and if it hasn't been set by set_texture
	if item_added and sprite_3d.texture == Gamedata.textures.container and not ritemgroup.use_sprite:
		set_random_inventory_item_texture()
	elif not item_added:
		 # If no item was added we delete the container if it's not a child of some furniture
		_on_item_removed(null)


# Takes a list of items and adds them to the inventory in Collection mode.
func _add_items_to_inventory_collection_mode(items: Array[RItemgroup.Item]) -> bool:
	var item_added: bool = false
	# Loop over each item object in the itemgroup's 'items' property
	for item_object: RItemgroup.Item in items:
		# Each item_object is expected to be a dictionary with id, probability, min, max
		var item_id = item_object.id
		var item_probability = item_object.probability
		if randi_range(0, 100) <= item_probability:
			item_added = true # An item is about to be added
			# Determine quantity to add based on min and max
			var quantity = randi_range(item_object.minc, item_object.maxc)
			_add_item_to_inventory(item_id, quantity)
	return item_added


# Takes a list of items and adds one to the inventory based on probabilities in Distribution mode.
func _add_items_to_inventory_distribution_mode(items: Array[RItemgroup.Item]) -> bool:
	var total_probability = 0
	# Calculate the total probability
	for item_object in items:
		total_probability += item_object.probability

	# Generate a random value between 0 and total_probability - 1
	var random_value = randi_range(0, total_probability - 1)
	var cumulative_probability = 0

	# Iterate through items to select one based on the random value
	for item_object: RItemgroup.Item in items:
		cumulative_probability += item_object.probability
		# Check if the random value falls within the current item's range
		if random_value < cumulative_probability:
			var item_id = item_object.id
			var quantity = randi_range(item_object.minc, item_object.maxc)
			_add_item_to_inventory(item_id, quantity)
			return true  # One item is added, return immediately

	return false  # In case no item is added, though this is highly unlikely


# Takes an item_id and quantity and adds it to the inventory
func _add_item_to_inventory(item_id: String, quantity: int):
	# Fetch the individual item data for verification
	var ritem: RItem = Runtimedata.items.by_id(item_id)
	# Check if the item data is valid before adding
	if ritem and quantity > 0:
		while quantity > 0:
			# Calculate the stack size for this iteration, limited by max_stack_size
			var stack_size = min(quantity, ritem.max_stack_size)
			# Create and add the item to the inventory
			var item = inventory.create_and_add_item(item_id)
			# Set the item stack size
			item.set_stack_size(stack_size)
			# Decrease the remaining quantity
			quantity -= stack_size


# Function to deserialize inventory and apply the correct sprite
func deserialize_and_apply_items(items_data: Dictionary):
	inventory.deserialize(items_data)
	
	var default_texture: Texture = Gamedata.textures.container
	
	if inventory.get_items().size() > 0:
		if sprite_3d.texture == default_texture:
			sprite_3d.texture = Gamedata.textures.container_filled
		# Else, some other texture has been set so we keep that
	else:
		sprite_3d.texture = default_texture
		_on_item_removed(null)


# Creates a new Inventory to hold items in it
func _create_inventory():
	inventory = ItemManager.initialize_inventory()
	add_child.call_deferred(inventory)
	inventory.item_removed.connect(_on_item_removed)
	inventory.item_added.connect(_on_item_added)


# Creates the sprite with some default properties
# These properties were copied from when the sprite was an actual node in the editor
func create_sprite():
	sprite_3d = Sprite3D.new()

	# Set the properties
	sprite_3d.centered = true
	sprite_3d.offset = Vector2(0, 0)
	sprite_3d.flip_h = false
	sprite_3d.flip_v = false
	sprite_3d.pixel_size = 0.01
	sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite_3d.transparent = true
	sprite_3d.shaded = true
	sprite_3d.double_sided = true
	sprite_3d.no_depth_test = false
	sprite_3d.fixed_size = false
	sprite_3d.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite_3d.alpha_scissor_threshold = 0.5
	sprite_3d.alpha_hash_scale = 1
	sprite_3d.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_OFF
	sprite_3d.alpha_antialiasing_edge = 0
	sprite_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite_3d.render_priority = 10
	set_texture(containertexture)
	#sprite_3d.texture = Gamedata.textures.container

	# Add to the scene tree
	add_child.call_deferred(sprite_3d)


# Updates the texture of this container. If no texture is provided, we use the default
func set_texture(mytex: Texture):
	if not mytex:
		sprite_3d.texture = Gamedata.textures.container
		return
	sprite_3d.texture = mytex


# This area will be used to check if the player can reach into the inventory with ItemDetector
func _create_area3d():
	var area3d = Area3D.new()
	add_child(area3d)
	area3d.collision_layer = 1 << 6  # Set to layer 7
	area3d.collision_mask = 1 << 6   # Set mask to layer 7
	area3d.owner = self
	var collisionshape3d = CollisionShape3D.new()
	var sphereshape3d = SphereShape3D.new()
	sphereshape3d.radius = 0.2
	collisionshape3d.shape = sphereshape3d
	area3d.add_child.call_deferred(collisionshape3d)


# Returns an array of InventoryItems that are in the Inventory
func get_items():
	return inventory.get_children()


# Returns a list of prototype id's from the inventory items
func get_item_ids() -> Array[String]:
	var returnarray: Array[String] = []
	for item: InventoryItem in inventory.get_items():
		var id = item.prototype_id
		returnarray.append(id)
	return returnarray


# Returns the sprite that represents this containeritem
func get_sprite():
	# If this is an orphan we return the sprite of the container
	if is_inside_tree() and get_parent() == get_tree().get_root():
		return sprite_3d.texture
	else:
		return Gamedata.textures.container


# Returns the inventorystacked that this container holds
func get_inventory() -> Inventory:
	return inventory


# Signal handler for item removed
# We don't want empty containers on the map, but we do want them as children of furniture
# So we delete empty containers if they are a child of the tree root.
func _on_item_removed(_item: InventoryItem):
	# Check if there are any items left in the inventory
	if inventory.get_items().size() == 0:
		if is_inside_tree():
			# Check if this ContainerItem is a direct child of the tree root
			if get_parent() == get_tree().get_root():
				Helper.signal_broker.container_exited_proximity.emit(self)
				queue_free.call_deferred()
	else: # There are still items in the container
		if is_inside_tree():
			set_random_inventory_item_texture() # Update to a new sprite


func _on_item_added(_item: InventoryItem):
	# Check if this ContainerItem is a direct child of the tree root
	if is_inside_tree() and not get_parent() == get_tree().get_root():
		set_random_inventory_item_texture() # Update to a new sprite


# Adds an item with a specific ID and quantity to the container's inventory
# Default quantity is 1 if not provided
func add_item(item_id: String, quantity: int = 1):
	# Fetch the individual item data for stack size verification
	var ritem: RItem = Runtimedata.items.by_id(item_id)
	if not ritem:
		push_error("Item ID %s not found in Runtimedata.items" % item_id)
		return

	# Split into stacks based on max_stack_size
	while quantity > 0:
		var stack_size = min(quantity, ritem.max_stack_size)
		var item = inventory.create_and_add_item(item_id)
		InventoryStacked.set_item_stack_size(item, stack_size)
		quantity -= stack_size


func insert_item(item: InventoryItem) -> bool:
	var iteminv: Inventory = item.get_inventory()
	if iteminv == inventory:
		return false # Can't insert into itself
	if not iteminv.transfer_autosplitmerge(item, inventory):
		print_debug("Failed to transfer item: " + str(item))
	return true


# Saves the data for this container to a JSON dictionary, 
# intended to be saved to disk
func get_data() -> Dictionary:
	var newitemData: Dictionary = {
		"global_position_x": containerpos.x, 
		"global_position_y": containerpos.y, 
		"global_position_z": containerpos.z, 
		"inventory": inventory.serialize()
	}
	# NOTE: Previously, the texture id was saved into the save data as a string
	# Since we switched over to Runtimedata, we can't rely on the id of the texture
	# Because we can't tell what mod it belongs to. We also can't save the texture
	# as a string, so we just omit it. We might come up with some other solution later.
	#if containertexture:
		#newitemData["containertexture"] = containertexture
	
	return newitemData


# Sets the sprite_3d texture to a texture of a random item in the container's inventory
func set_random_inventory_item_texture():
	var items: Array = inventory.get_items()
	if items.size() == 0:
		return
	
	# Pick a random item from the inventory
	var random_item: InventoryItem = items.pick_random()
	var item_id = random_item.get_prototype().get_id()
	
	# Set the sprite_3d texture to the item's sprite
	sprite_3d.texture = Runtimedata.items.sprite_by_id(item_id)


# Properly destroys the container and its associated resources
func destroy():
	Helper.signal_broker.container_exited_proximity.emit(self)
	# Disconnect signals to avoid issues during cleanup
	if inventory:
		inventory.item_removed.disconnect(_on_item_removed)
		inventory.item_added.disconnect(_on_item_added)

	# Free the inventory resource
	if inventory:
		inventory.queue_free()
		inventory = null

	# Free the sprite resource
	if sprite_3d:
		sprite_3d.queue_free()
		sprite_3d = null

	# Free the node itself
	queue_free()
