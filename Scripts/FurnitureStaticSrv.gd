class_name FurnitureStaticSrv
extends Node3D # Has to be Node3D. Changing it to RefCounted doesn't work


# This is a standalone script that is not attached to any node. 
# This is the static version of furniture. There is also FurniturePhysicsSrv.gd.
# This class is instanced by FurnitureStaticSpawner.gd when a map needs static 
# furniture, like a bed or fridge.


# Variables to store furniture data
var furniture_transform: FurnitureTransform
var furniture_position: Vector3
var furniture_rotation: int
var furnitureJSON: Dictionary # The json that defines this furniture on the map
var rfurniture: RFurniture # The json that defines this furniture's basics in general
var collider: RID
var shape: RID
var mesh_instance: RID  # Variable to store the mesh instance RID
var quad_instance: RID # RID to the quadmesh that displays the sprite
var myworld3d: World3D
var spawner: FurnitureStaticSpawner # The spawner that spawned this furniture

# We have to keep a reference or it will be auto deleted
var support_mesh: PrimitiveMesh # A mesh below the sprite for 3d effect
var sprite_texture: Texture2D  # Variable to store the sprite texture
var sprite_material: ShaderMaterial # Material to display the furniture sprite
var quad_mesh: PlaneMesh # Shows the sprite of the furniture

# Variables to manage door functionality
var is_door: bool = false
var door_state: String = "Closed"  # Default state

# Variables to manage the container if this furniture is a container
var container: FurnitureContainer
var crafting_container: CraftingContainer
var consumption: Consumption # Variable to manage consumption

# Variables to manage health and damage
var current_health: float = 100.0  # Default health
var is_animating_hit: bool = false  # Flag to prevent multiple hit animations
var original_material_color: Color = Color(1, 1, 1)  # Store the original material color

signal about_to_be_destroyed(me: FurnitureStaticSrv)
signal crafting_queue_updated(current_queue: Array[QueueItem])


# Inner class to keep track of position, rotation and size and keep it central
class FurnitureTransform:
	var posx: float
	var posy: float
	var posz: float
	var rot: int
	var width: float
	var depth: float
	var height: float
	var parent_furniture: FurnitureStaticSrv

	func _init(myposition: Vector3, myrotation: int, size: Vector3):
		width = size.x
		depth = size.z
		height = size.y
		posx = myposition.x
		posy = myposition.y
		posz = myposition.z
		rot = myrotation

	func get_position() -> Vector3:
		return Vector3(posx, posy, posz)

	func set_position(new_position: Vector3):
		posx = new_position.x
		posy = new_position.y
		posz = new_position.z

	func get_rotation() -> int:
		return rot

	func set_rotation(new_rotation: int):
		rot = new_rotation

	func get_sizeV3() -> Vector3:
		return Vector3(width, height, depth)

	func get_sizeV2() -> Vector2:
		return Vector2(width, depth)

	func set_size(new_size: Vector3):
		width = new_size.x
		height = new_size.y
		depth = new_size.z

	func update_transform(new_position: Vector3, new_rotation: int, new_size: Vector3):
		set_position(new_position)
		set_rotation(new_rotation)
		set_size(new_size)
	
	# New method to create a Transform3D
	func get_sprite_transform() -> Transform3D:
		var adjusted_position = get_position() + Vector3(0, 0.5*height+0.01, 0)
		return Transform3D(Basis(Vector3(0, 1, 0), deg_to_rad(rot)), adjusted_position)
	
	func get_cylinder_shape_data() -> Dictionary:
		return {"radius": width / 4.0, "height": height}
	
	# New method to create a Transform3D for visual instances
	func get_visual_transform() -> Transform3D:
		return Transform3D(Basis(Vector3(0, 1, 0), deg_to_rad(rot)), get_position())
	
	func get_box_shape_size() -> Vector3:
		# Apply width and depth scaling from rfurniture.support_shape
		var scaled_width = width * (parent_furniture.rfurniture.support_shape.width_scale / 100.0)
		var scaled_depth = depth * (parent_furniture.rfurniture.support_shape.depth_scale / 100.0)
		return Vector3(scaled_width, height, scaled_depth)

		
	func correct_new_position():
		# We have to compensate for the fact that the physicsserver and
		# renderingserver place the furniture lower then the intended height
		posy += 0.5+(0.5*height)


# Inner Container Class
class FurnitureContainer:
	var inventory: Inventory
	var itemgroup: String # The ID of an itemgroup that it creates loot from
	var sprite_mesh: PlaneMesh
	var sprite_instance: RID # RID to the quadmesh that displays the containersprite
	var material: ShaderMaterial
	var furniture_transform: FurnitureTransform
	var parent_furniture: FurnitureStaticSrv
	var world3d: World3D

	# Regeneration-related variables
	var regeneration_interval: float = -1.0  # Default to -1 (no regeneration)
	var last_time_checked: float = 0.0  # Tracks the last time regeneration was checked

	func _init(myparent_furniture: FurnitureStaticSrv):
		parent_furniture = myparent_furniture
		furniture_transform = parent_furniture.furniture_transform
		world3d = parent_furniture.myworld3d
		_initialize_inventory()

	func _initialize_inventory():
		inventory = ItemManager.initialize_inventory()
		inventory.item_removed.connect(_on_item_removed)
		inventory.item_added.connect(_on_item_added)
	
	func get_inventory() -> Inventory:
		return inventory

	# Function to create an additional sprite to represent the container
	func create_container_sprite_instance():
		# Calculate the size for the container sprite
		var furniture_size_v2 = furniture_transform.get_sizeV2()
		var smallest_dimension = min(furniture_size_v2.x, furniture_size_v2.y)
		var container_sprite_size = Vector2(smallest_dimension, smallest_dimension) * 0.8

		sprite_mesh = PlaneMesh.new()
		sprite_mesh.size = container_sprite_size

		sprite_mesh.material = material

		sprite_instance = RenderingServer.instance_create()
		RenderingServer.instance_set_base(sprite_instance, sprite_mesh)
		RenderingServer.instance_set_scenario(sprite_instance, world3d.scenario)

		# Position the container sprite slightly above the main sprite
		var container_sprite_transform = furniture_transform.get_sprite_transform()
		container_sprite_transform.origin.y += 0.2  # Adjust height as needed
		RenderingServer.instance_set_transform(sprite_instance, container_sprite_transform)

	# Sets the sprite_3d texture to a texture of a random item in the container's inventory
	func set_random_inventory_item_texture():
		if parent_furniture.rfurniture.function.container_sprite_mode == "Hide":
			return # We don't want a sprite visible when it's set to hide
		var items: Array[InventoryItem] = inventory.get_items()
		if items.size() == 0:
			sprite_mesh.material = Gamedata.materials.container # set empty container
			return
		
		# Pick a random item from the inventory
		var random_item: InventoryItem = items.pick_random()
		var item_id = random_item.get_prototype().get_id()
		
		# Get the ShaderMaterial for the item
		material = Runtimedata.items.get_shader_material_by_id(item_id)
		sprite_mesh.material = material  # Update the mesh material

	# Takes an item_id and quantity and adds it to the inventory
	func add_item_to_inventory(item_id: String, quantity: int):
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

	func insert_item(item: InventoryItem) -> bool:
		var iteminv: Inventory = item.get_inventory()
		if iteminv == inventory:
			return false # Can't insert into itself
		if not inventory.add_item_autosplitmerge(item):
			print_debug("Failed to transfer item: " + str(item))
		return true

	func _on_item_added(_item: InventoryItem):
		set_random_inventory_item_texture() # Update to a new sprite

	func _on_item_removed(_item: InventoryItem):
		set_random_inventory_item_texture() # Update to a new sprite

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
				add_item_to_inventory(item_id, quantity)
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
				add_item_to_inventory(item_id, quantity)
				return true  # One item is added, return immediately

		return false  # In case no item is added, though this is highly unlikely

	# Add this function to handle inventory reset and item regeneration
	func _reset_inventory_and_regenerate_items():
		if not itemgroup or itemgroup == "":
			return  # Do nothing if no itemgroup is present

		# Clear existing inventory
		inventory.clear()

		# Populate inventory with items from the itemgroup
		var ritemgroup: RItemgroup = Runtimedata.itemgroups.by_id(itemgroup)
		if ritemgroup:
			var group_mode: String = ritemgroup.mode  # can be "Collection" or "Distribution"
			if group_mode == "Collection":
				_add_items_to_inventory_collection_mode(ritemgroup.items)
			elif group_mode == "Distribution":
				_add_items_to_inventory_distribution_mode(ritemgroup.items)

		# Update container visuals
		set_random_inventory_item_texture()

	func check_regeneration_functionality(furnitureJSON: Dictionary, rfurniture: RFurniture, is_new_furniture: bool):
		if rfurniture.function.container_regeneration_time:
			regeneration_interval = rfurniture.function.container_regeneration_time

		if not is_new_furniture:
			# Ensure the last_time_checked and itemgroup are properly set
			if furnitureJSON.has("Function") and furnitureJSON["Function"].has("container"):
				if furnitureJSON.Function.container.has("container_last_time_checked"):
					last_time_checked = furnitureJSON.Function.container.container_last_time_checked
				if furnitureJSON.Function.container.has("container_itemgroup"):
					itemgroup = furnitureJSON.Function.container.container_itemgroup
			else:
				last_time_checked = 0.0  # Default if not found in saved data

	func regenerate():
		# Check if the container regenerates
		if regeneration_interval <= -1:
			return

		# Get the total days passed and calculate the days since last check
		var total_days_passed: float = Helper.time_helper.get_days_since_start()
		var days_passed: float = total_days_passed - last_time_checked

		# Check if enough days have passed to regenerate
		if days_passed >= regeneration_interval:
			# Update the last time checked
			last_time_checked = total_days_passed

			# Regenerate items
			_reset_inventory_and_regenerate_items()


	# Will add item to the inventory based on the assigned itemgroup
	# Only new furniture will have an itemgroup assigned, not previously saved furniture.
	func create_loot(furnitureJSON: Dictionary, rfurniture: RFurniture):
		itemgroup = populate_container_from_itemgroup(furnitureJSON, rfurniture)
		if not itemgroup or itemgroup == "":
			return

		# Attempt to retrieve the itemgroup data from Gamedata
		var ritemgroup: RItemgroup = Runtimedata.itemgroups.by_id(itemgroup)

		if ritemgroup:
			var groupmode: String = ritemgroup.mode  # Can be "Collection" or "Distribution".
			if groupmode == "Collection":
				_add_items_to_inventory_collection_mode(ritemgroup.items)
			elif groupmode == "Distribution":
				_add_items_to_inventory_distribution_mode(ritemgroup.items)

	# If there is an itemgroup assigned to the furniture, it will be added to the container.
	# It will check both furnitureJSON and dfurniture for itemgroup information.
	# The function will return the id of the itemgroup so that the container may use it
	func populate_container_from_itemgroup(furnitureJSON: Dictionary, rfurniture: RFurniture) -> String:
		# Check if furnitureJSON contains an itemgroups array
		if furnitureJSON.has("itemgroups"):
			var itemgroups_array = furnitureJSON["itemgroups"]
			if itemgroups_array.size() > 0:
				return itemgroups_array.pick_random()
		
		# Fallback to using itemgroup from furnitureJSONData if furnitureJSON.itemgroups does not exist
		var myitemgroup = rfurniture.function.container_group
		if myitemgroup:
			return myitemgroup
		return ""

	# Deserialize container data if available
	func deserialize_container_data(container_json: Dictionary):
		if not container_json.has("Function"):
			return
		if not container_json.Function.has("container"):
			return
		if "items" in container_json["Function"]["container"]:
			inventory.deserialize(container_json["Function"]["container"]["items"])
		# Update the sprite behavior after deserialization
		update_container_sprite_behavior()
	
	# Serialize the container data for saving
	func serialize() -> Dictionary:
		var container_data: Dictionary = {}
		var container_inventory_data = inventory.serialize()

		# Only include inventory data if it has items
		if not container_inventory_data.is_empty():
			container_data["items"] = container_inventory_data

		# Add other container-specific fields
		container_data["container_last_time_checked"] = last_time_checked
		container_data["container_itemgroup"] = itemgroup

		return container_data

	# Function to handle container sprite behavior based on the container_sprite_mode
	func update_container_sprite_behavior():
		var rfurniture: RFurniture = parent_furniture.rfurniture
		# Read the container sprite mode from rfurniture
		var sprite_mode: String = rfurniture.function.container_sprite_mode

		# Check the sprite mode and execute the corresponding behavior
		match sprite_mode:
			"Random":
				# Call the function to set a random inventory item texture
				set_random_inventory_item_texture()
			"Hide":
				# Hide the sprite_mesh by making it invisible
				if sprite_mesh:
					var empty_material = StandardMaterial3D.new()
					empty_material.albedo_color = Color(1, 1, 1, 0)  # Fully transparent color
					empty_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA  # Enable alpha transparency
					empty_material.flags_transparent = true  # Mark the material as transparent
					sprite_mesh.material = empty_material
			"Default":
				# Handle the default case (no special behavior)
				if sprite_mesh:
					# Check if the container is empty before setting material
					if inventory.get_item_count() <= 0:
						sprite_mesh.material = Gamedata.materials.container  # Empty container material
					else:
						sprite_mesh.material = Gamedata.materials.container_filled  # Filled container material


# Class representing a queued item for the CraftingContainer
class QueueItem:
	var id: String
	var quantity: int = 1  # Optional if you want to handle multiple items per queue entry
	var additional_data: Dictionary = {}  # For any extra metadata if needed
	var time_remaining: float = 0.0  # Time remaining to craft this item

	func _init(myid: String, myquantity: int = 1, myadditional_data: Dictionary = {}):
		self.id = myid
		self.quantity = myquantity
		self.additional_data = myadditional_data
		self.time_remaining = 0.0  # Will be set based on recipe during crafting queue processing


class CraftingContainer:
	var inventory: Inventory
	var crafting_queue: Array[QueueItem] = []  # Queue of QueueItem instances
	# Variables to manage crafting
	var last_update_time: float = 0.0  # Last time the crafting queue was updated
	var crafting_time_per_item: float = 10.0  # Time (in seconds) to craft one item
	var is_active: bool = false  # Whether the crafting queue is actively processing
	var furniturecontainer: FurnitureContainer
	var furniture_parent: FurnitureStaticSrv
	signal crafting_queue_updated(current_queue: Array[String])


	func _init():
		_initialize_inventory()
		furniture_parent = null

	# Initializes the inventory with default capacity and item prototypes
	func _initialize_inventory():
		inventory = ItemManager.initialize_inventory()

	# Retrieves the inventory instance
	func get_inventory() -> Inventory:
		return inventory

	# Adds an item ID to the crafting queue
	func add_to_crafting_queue(item_id: String, quantity: int = 1):
		var recipe: RItem.CraftRecipe = Runtimedata.items.get_first_recipe_by_id(item_id)
		if not recipe:
			print_debug("Error: No recipe found for item: ", item_id)
			return

		var new_item = QueueItem.new(item_id, quantity)
		new_item.time_remaining = recipe.craft_time  # Initialize time_remaining with the craft time
		crafting_queue.append(new_item)
		crafting_queue_updated.emit(crafting_queue)  # Emit signal after updating the queue

	# Removes an item from the crafting queue
	func remove_from_crafting_queue(queue_item: QueueItem):
		if crafting_queue.has(queue_item):
			crafting_queue.erase(queue_item)  # Remove the specific instance
			transfer_all_items_to_furniture()  # Clear crafting inventory if applicable
			crafting_queue_updated.emit(crafting_queue)  # Emit signal after updating the queue
		else:
			print_debug("Error: Queue item not found.")

	# Serializes the inventory, crafting queue, and time-related variables for saving
	func serialize() -> Dictionary:
		var crafting_data: Dictionary = {}
		
		# Serialize the inventory if it contains items
		var inventory_data = inventory.serialize()
		if not inventory_data.is_empty():
			crafting_data["items"] = inventory_data

		# Serialize the crafting queue
		crafting_data["crafting_queue"] = crafting_queue

		# Serialize time-related variables
		crafting_data["last_update_time"] = last_update_time
		crafting_data["is_active"] = is_active

		return crafting_data

	# Deserializes and restores the inventory, crafting queue, and time-related variables from saved data
	func deserialize(data: Dictionary):
		# Deserialize the inventory if present
		if data.has("items"):
			inventory.deserialize(data["items"])

		# Deserialize the crafting queue
		if data.has("crafting_queue"):
			crafting_queue = data["crafting_queue"]

		# Deserialize time-related variables
		last_update_time = data.get("last_update_time", 0.0)  # Default to 0 if not present
		is_active = data.get("is_active", false)  # Default to inactive if not present


	# Transfers all items to the given FurnitureContainer
	func transfer_all_items_to_furniture() -> void:
		
		# Retrieve all items from the crafting container inventory
		var items = inventory.get_items()
		
		# Get the inventory of the target furniture container
		var furniture_inventory = furniturecontainer.get_inventory()

		# Loop through each item and transfer it
		for item in items.duplicate():  # Duplicate the list to avoid modification during iteration
			inventory.transfer_automerge(item, furniture_inventory)

	
	# Activates the crafting queue for real-time updates
	func activate_crafting():
		is_active = true
		#last_update_time = Helper.time_helper.get_elapsed_time()

	# Deactivates the crafting queue
	func deactivate_crafting():
		is_active = false

	# Processes the crafting queue in real-time (active mode)
	func process_active_crafting():
		if not is_active:
			return

		var current_time = Helper.time_helper.get_elapsed_time()
		var elapsed_time = current_time - last_update_time
		last_update_time = current_time
		_process_crafting_queue(elapsed_time)

	# Processes the crafting queue during passive mode
	func _process_passive_crafting():
		var elapsed_time = Helper.time_helper.get_time_difference(last_update_time)
		last_update_time = Helper.time_helper.get_elapsed_time()
		_process_crafting_queue(elapsed_time)

	# Core logic to process the crafting queue
	func _process_crafting_queue(elapsed_time: float):
		while elapsed_time > 0 and not crafting_queue.is_empty():
			
			# Get the first item in the queue
			var queue_item: QueueItem = crafting_queue[0]
			
			# Retrieve the recipe for the current item
			var recipe: RItem.CraftRecipe = Runtimedata.items.get_first_recipe_by_id(queue_item.id)
			if not recipe:
				print_debug("No recipe found for item: ", queue_item.id, " | Skipping...")
				crafting_queue.pop_front()  # Remove invalid item from queue
				continue

			# Check and request missing ingredients
			if not are_all_ingredients_available(recipe):
				if not request_missing_ingredients(recipe):
					# Exit the loop early to wait for the next update
					return

			# Subtract elapsed time from the current item's remaining time
			if elapsed_time >= queue_item.time_remaining:
				elapsed_time -= queue_item.time_remaining  # Carry over excess time
				_craft_next_item()  # Finalize crafting and move to the next item
			else:
				queue_item.time_remaining -= elapsed_time
				elapsed_time = 0  # No more time left to process in this frame

	# Crafts the next item in the queue and adds it to the FurnitureContainer's inventory
	func _craft_next_item():
		if crafting_queue.is_empty():
			return  # Exit if the crafting queue is empty

		var queue_item: QueueItem = crafting_queue.pop_front()  # Get the first item in the queue
		crafting_queue_updated.emit(crafting_queue)  # Emit signal after updating the queue

		if queue_item:
			if furniturecontainer:  # Ensure the FurnitureContainer exists
				inventory.clear()  # Clear the crafting inventory after crafting the item
				furniturecontainer.add_item_to_inventory(queue_item.id, queue_item.quantity)  # Add crafted item
			else:
				print_debug("Error: FurnitureContainer not initialized. Cannot add crafted item.")
		else:
			print_debug("Error: Failed to craft item. queue_item is invalid.")

	# Retrieves the crafting time for a specific item by its ID
	func _get_craft_time_by_id(item_id: String) -> float:
		var first_recipe: RItem.CraftRecipe = Runtimedata.items.get_first_recipe_by_id(item_id)
		return first_recipe.craft_time if first_recipe else 10  # Default to 10 seconds

	# Requests missing ingredients from the parent FurnitureStaticSrv
	func request_missing_ingredients(recipe: RItem.CraftRecipe) -> bool:
		if not recipe:
			print_debug("Error: Recipe not provided.")
			return false

		var all_present = true
		for ingredient in recipe.required_resources:
			var missing_amount = ingredient.amount - get_available_ingredient_amount(ingredient.id)
			if missing_amount > 0:
				all_present = false
				if furniture_parent:
					furniture_parent.transfer_item_between_containers(furniturecontainer, ingredient.id, missing_amount)
				else:
					print_debug("Error: Parent FurnitureStaticSrv is not set.")
					return false
		return all_present

	# Get the available amount of the ingredient in the FurnitureContainer inventory.
	func get_available_ingredient_amount(ingredient_id: String) -> int:
		var available_amount: int = 0
		
		if inventory.has_item_with_prototype_id(ingredient_id):
			var items: Array = inventory.get_items_with_prototype_id(ingredient_id)
			
			for item: InventoryItem in items:
				var stack_size = item.get_stack_size()
				available_amount += stack_size
		return available_amount

	func are_all_ingredients_available(recipe: RItem.CraftRecipe) -> bool:
		for ingredient in recipe.required_resources:
			var available = get_available_ingredient_amount(ingredient.id)
			if available < ingredient.amount:
				return false
		return true

# Inner class for managing consumption mechanics
class Consumption:
	var current_pool: float = 0  # Default value for the consumption pool
	var parent_furniture: FurnitureStaticSrv
	signal current_pool_changed(new_value: float)

	func _init(myparent_furniture: FurnitureStaticSrv):
		parent_furniture = myparent_furniture
		# A pool value may have transferred over from the furniture it was before
		# This happens when a furniture transforms_into
		if parent_furniture.furnitureJSON.has("pool"):
			current_pool = parent_furniture.furnitureJSON.get("pool", 0)
		consume_items()

	# Getter for `current_pool`
	func get_current_pool() -> float:
		return current_pool

	# Setter for `current_pool`
	func set_current_pool(value: float) -> void:
		# Get the maximum pool size from rfurniture.consumption.pool
		var pool_size: float = parent_furniture.rfurniture.consumption.pool
		
		# Clamp the value to ensure current_pool is within the valid range [0, pool_size]
		current_pool = clamp(value, 0, pool_size)
		current_pool_changed.emit(current_pool)
		
		# Get the drain_rate per in-game hour from the parent furniture
		var drain_rate: float = parent_furniture.rfurniture.consumption.drain_rate
		
		# Only consider transforming automatically if pool and drain_rate are valid
		if pool_size <= 0 or drain_rate <= 0:
			return
		
		# Trigger transformation logic if the pool is depleted
		if current_pool <= 0:
			parent_furniture.transform_into()

	# Function to compare the current pool with the maximum pool capacity
	func get_available_pool_capacity() -> float:
		# Get the maximum capacity of the pool from parent_furniture.rfurniture.consumption.pool
		var max_pool: float = parent_furniture.rfurniture.consumption.pool
		
		# Calculate and return the difference
		return max_pool - current_pool

	# Update the function to handle the granular logic
	func on_minute_passed(_current_time: String):
		# Get the drain_rate per in-game hour from the parent furniture
		var pool_size: float = parent_furniture.rfurniture.consumption.pool
		var drain_rate: float = parent_furniture.rfurniture.consumption.drain_rate
		# We only consider consuming items if there is a pool defined with a size larger then 0
		if pool_size <= 0 or drain_rate <= 0:
			return
		
		# Calculate the per in-game minute drain amount (granular drain)
		var drain_per_minute: float = drain_rate / 60.0
		
		# Subtract the per-minute drain from the current_pool
		set_current_pool(get_current_pool() - drain_per_minute)
		consume_items()

	# Function to consume items from the container
	func consume_items():
		if not parent_furniture.rfurniture:
			return
		
		# Get the dictionary of items from parent_furniture
		var items_dict: Dictionary = parent_furniture.rfurniture.consumption.items
		
		# Check if the parent furniture has a container
		if not parent_furniture.container:
			return
		
		# Get the container inventory
		var container_inventory: Inventory = parent_furniture.container.get_inventory()
		
		# Keep consuming items as long as there is room in the pool
		while get_available_pool_capacity() > 0:
			var consumed_item = false  # Track if we consumed an item this iteration
			
			# Iterate over each item in the items dictionary
			for item_id in items_dict.keys():
				var item_value: float = items_dict[item_id]
				
				# Skip the item if its value is larger than the available capacity
				if item_value > get_available_pool_capacity():
					continue
				
				# Check if the inventory contains an item with the prototype_id matching the item_id
				if container_inventory.has_item_with_prototype_id(item_id):
					# Get the first item matching the item_id
					var items: Array[InventoryItem] = container_inventory.get_items_with_prototype_id(item_id)
					if items.size() > 0:
						var item_to_consume: InventoryItem = items[0]  # Get the first item
						var current_stack_size: int = item_to_consume.get_stack_size()
						
						# Attempt to subtract 1 from the current stack size
						if item_to_consume.set_stack_size(current_stack_size - 1):
							# If successful, add the item's value to the current_pool
							set_current_pool(get_current_pool() + item_value)
							
							# Log the successful consumption
							print("Consumed 1 unit of item: ", item_id, ". Remaining stack size: ", current_stack_size - 1)
							print("Added ", item_value, " to current pool. New pool value: ", get_current_pool())
							
							consumed_item = true  # Mark that we consumed an item
							break  # Break out of the loop to re-check the pool capacity
						else:
							print("Failed to consume item: ", item_id, ". Could not reduce stack size.")
					else:
						print("No items available to consume for item_id: ", item_id)
			
			# If no items were consumed, exit the loop
			if not consumed_item:
				break



	# Serialize the data
	func serialize() -> Dictionary:
		var data: Dictionary = {}
		data["current_pool"] = current_pool  # Save the current pool value
		return data

	# Deserialize the Consumption class
	func deserialize(data: Dictionary) -> void:
		# Check if the data contains "current_pool" and set it
		if data.has("current_pool"):
			current_pool = data["current_pool"]


# --------------------------------------------------------------
# Initialization
# --------------------------------------------------------------

# Function to initialize the furniture object
func _init(furniturepos: Vector3, new_furniture_json: Dictionary, world3d: World3D):
	furniture_position = furniturepos
	furnitureJSON = new_furniture_json
	myworld3d = world3d
	rfurniture = Runtimedata.furnitures.by_id(furnitureJSON.id)
	sprite_texture = rfurniture.sprite
	furniture_rotation = furnitureJSON.get("rotation", 0)

	furniture_transform = FurnitureTransform.new(
		furniturepos, furniture_rotation, calculate_furniture_size()
	)
	furniture_transform.parent_furniture = self
	
	if _is_new_furniture():
		furniture_transform.correct_new_position()
		_apply_edge_snapping_if_needed()
		set_new_rotation(furniture_rotation) # Apply rotation after setting up the shape and visual instance

	check_door_functionality()  # Check if this furniture is a door

	if rfurniture.support_shape.shape == "Box":
		create_box_shape()
		create_visual_instance("Box")
	elif rfurniture.support_shape.shape == "Cylinder":
		create_cylinder_shape()
		create_visual_instance("Cylinder")

	create_sprite_instance()
	update_door_visuals()  # Set initial door visuals based on its state
	add_container()  # Adds container if the furniture is a container
	add_crafting_container() # Adds crafting container if the furniture is a crafting station
	if rfurniture.consumption:
		consumption = Consumption.new(self)
	Helper.time_helper.minute_passed.connect.call_deferred(on_minute_passed)


# If this furniture is a container, it will add a container node to the furniture.
func add_container():
	if is_container():
		container = FurnitureContainer.new(self)
		container.create_container_sprite_instance()

		# Check if this is new furniture
		if _is_new_furniture():
			if furnitureJSON.has("items"):  # Check if the furnitureJSON has an "items" property
				# Add each item from the furnitureJSON["items"] directly to the container's inventory
				for item in furnitureJSON["items"]:
					container.insert_item(item)  # Insert the InventoryItem directly
			else:
				# If no "items" property, create loot based on default logic
				container.create_loot(furnitureJSON, rfurniture)
		else:
			# If this is not new furniture, deserialize existing container data
			container.deserialize_container_data(furnitureJSON)

		# Always update sprite behavior, even if no items were added
		container.update_container_sprite_behavior()

		# Check if this furniture regenerates items
		container.check_regeneration_functionality(furnitureJSON, rfurniture, _is_new_furniture())


func is_container() -> bool:
	return rfurniture.function.is_container

# Wether or not this furniture is a crafting station.
# Returns true if it is a container and has crafting recipes (items)
func is_crafting_station() -> bool:
	return is_container() and rfurniture.crafting.get_items().size() > 0


# Function to calculate the size of the furniture
func calculate_furniture_size() -> Vector3:
	if sprite_texture:
		var sprite_width = sprite_texture.get_width() / 100.0 # Convert pixels to meters
		var sprite_depth = sprite_texture.get_height() / 100.0 # Convert pixels to meters
		var height = rfurniture.support_shape.height
		return Vector3(sprite_width, height, sprite_depth)  # Use height from support shape
	return Vector3(0.5, rfurniture.support_shape.height, 0.5)  # Default size if texture is not set


# Function to create a BoxShape3D collider based on the given size
func create_box_shape():
	shape = PhysicsServer3D.box_shape_create()
	var shape_size: Vector3 = furniture_transform.get_box_shape_size()
	shape_size.x = shape_size.x/2
	shape_size.y = shape_size.y
	shape_size.z = shape_size.z/2
	PhysicsServer3D.shape_set_data(shape, shape_size)
	
	collider = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(collider, PhysicsServer3D.BODY_MODE_STATIC)
	# Set space, so it collides in the same space as current scene.
	PhysicsServer3D.body_set_space(collider, myworld3d.space)
	PhysicsServer3D.body_add_shape(collider, shape)

	var mytransform = furniture_transform.get_visual_transform()
	PhysicsServer3D.body_set_state(collider, PhysicsServer3D.BODY_STATE_TRANSFORM, mytransform)
	set_collision_layers_and_masks()


# Function to create a visual instance with a mesh to represent the shape
# Apply the hide_above_player_shader to the MeshInstance
func create_visual_instance(shape_type: String):
	var material: ShaderMaterial = Runtimedata.furnitures.get_shape_material_by_id(rfurniture.id)

	if shape_type == "Box":
		support_mesh = BoxMesh.new()
		(support_mesh as BoxMesh).size = furniture_transform.get_box_shape_size()
	elif shape_type == "Cylinder":
		support_mesh = CylinderMesh.new()
		(support_mesh as CylinderMesh).height = furniture_transform.height
		(support_mesh as CylinderMesh).top_radius = furniture_transform.width / 4.0
		(support_mesh as CylinderMesh).bottom_radius = furniture_transform.width / 4.0

	support_mesh.material = material  # Set the shader material

	mesh_instance = RenderingServer.instance_create()
	RenderingServer.instance_set_base(mesh_instance, support_mesh)
	RenderingServer.instance_set_scenario(mesh_instance, myworld3d.scenario)
	var mytransform = furniture_transform.get_visual_transform()
	RenderingServer.instance_set_transform(mesh_instance, mytransform)


# Function to create a QuadMesh to display the sprite texture on top of the furniture
func create_sprite_instance():
	# Create a PlaneMesh to hold the sprite
	quad_mesh = PlaneMesh.new()
	quad_mesh.size = furniture_transform.get_sizeV2()

	# Get the shader material from Runtimedata.furnitures
	sprite_material = Runtimedata.furnitures.get_shader_material_by_id(furnitureJSON.id)

	quad_mesh.material = sprite_material

	# Create the quad instance
	quad_instance = RenderingServer.instance_create()
	RenderingServer.instance_set_base(quad_instance, quad_mesh)
	RenderingServer.instance_set_scenario(quad_instance, myworld3d.scenario)

	# Set the transform for the quad instance slightly above the box mesh
	RenderingServer.instance_set_transform(quad_instance, furniture_transform.get_sprite_transform())


# Now, update methods that involve position, rotation, and size
func _apply_edge_snapping_if_needed():
	if not rfurniture.edgesnapping == "None":
		var new_position = _apply_edge_snapping(
			rfurniture.edgesnapping
		)
		furniture_transform.set_position(new_position)


# Function to create a CylinderShape3D collider based on the given size
func create_cylinder_shape():
	shape = PhysicsServer3D.cylinder_shape_create()
	PhysicsServer3D.shape_set_data(shape, furniture_transform.get_cylinder_shape_data())
	
	collider = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(collider, PhysicsServer3D.BODY_MODE_STATIC)
	# Set space, so it collides in the same space as current scene.
	PhysicsServer3D.body_set_space(collider, myworld3d.space)
	PhysicsServer3D.body_add_shape(collider, shape)
	var mytransform = furniture_transform.get_visual_transform()
	PhysicsServer3D.body_set_state(collider, PhysicsServer3D.BODY_STATE_TRANSFORM, mytransform)
	set_collision_layers_and_masks()


# Function to set collision layers and masks
func set_collision_layers_and_masks():
	# Set collision layer to layers 3 (static obstacles layer) and 7 (containers layer)
	var collision_layer = (1 << 2) | (1 << 6)  # Layer 3 is 1 << 2, Layer 7 is 1 << 6

	# Set collision mask to include layers 1, 2, 3, 4, 5, and 6
	var collision_mask = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)
	# Explanation:
	# - 1 << 0: Layer 1 (player layer)
	# - 1 << 1: Layer 2 (enemy layer)
	# - 1 << 2: Layer 3 (static obstacles layer)
	# - 1 << 3: Layer 4 (movable obstacles layer)
	# - 1 << 4: Layer 5 (friendly projectiles layer)
	# - 1 << 5: Layer 6 (enemy projectiles layer)
	
	PhysicsServer3D.body_set_collision_layer(collider, collision_layer)
	PhysicsServer3D.body_set_collision_mask(collider, collision_mask)


# If edge snapping has been set in the furniture editor, we will apply it here.
# The direction refers to the 'backside' of the furniture, which will be facing the edge of the block
# This is needed to put furniture against the wall, or get a fence at the right edge
func _apply_edge_snapping(direction: String) -> Vector3:
	# Block size, a block is 1x1 meters
	var blockSize = Vector3(1.0, 1.0, 1.0)
	var newpos = furniture_transform.get_position()
	var size: Vector3 = furniture_transform.get_sizeV3()
	
	# Adjust position based on edgesnapping direction and rotation
	match direction:
		"North":
			newpos.z -= blockSize.z / 2 - size.z / 2
		"South":
			newpos.z += blockSize.z / 2 - size.z / 2
		"East":
			newpos.x += blockSize.x / 2 - size.x / 2
		"West":
			newpos.x -= blockSize.x / 2 - size.x / 2
		# Add more cases if needed
	
	# Consider rotation if necessary
	newpos = rotate_position_around_block_center(newpos, furniture_transform.get_position())
	
	return newpos


# Called when applying edge-snapping so it's put into the right position
func rotate_position_around_block_center(newpos: Vector3, block_center: Vector3) -> Vector3:
	# Convert rotation to radians for trigonometric functions
	var radians = deg_to_rad(furniture_transform.get_rotation())
	
	# Calculate the offset from the block center
	var offset = newpos - block_center
	
	# Apply rotation matrix transformation
	var rotated_offset = Vector3(
		offset.x * cos(radians) - offset.z * sin(radians),
		offset.y,
		offset.x * sin(radians) + offset.z * cos(radians)
	)
	
	# Return the new position
	return block_center + rotated_offset


# Function to set the rotation for this furniture
func set_new_rotation(amount: int):
	var rotation_amount = amount
	if amount == 270:
		rotation_amount = amount - 180
	elif amount == 90:
		rotation_amount = amount + 180
	furniture_transform.set_rotation(rotation_amount)


# Function to get the current rotation of this furniture
func get_my_rotation() -> int:
	return furniture_transform.get_rotation()


# Helper function to determine if the furniture is new
func _is_new_furniture() -> bool:
	return not furnitureJSON.has("global_position_x")


# Function to free all resources like the RIDs
func free_resources():
	about_to_be_destroyed.emit(self)
	# Free the mesh instance RID if it exists
	RenderingServer.free_rid(mesh_instance)
	RenderingServer.free_rid(quad_instance)
	if container:
		RenderingServer.free_rid(container.sprite_instance)

	# Free the collider shape and body RIDs if they exist
	PhysicsServer3D.free_rid(shape)
	PhysicsServer3D.free_rid(collider)


# Function to check if this furniture acts as a door
func check_door_functionality():
	is_door = rfurniture.function.door != "None"
	
	# Ensure the door_state is properly set
	if furnitureJSON.has("Function") and furnitureJSON["Function"].has("door"):
		door_state = furnitureJSON["Function"]["door"]
	else:
		door_state = "Closed"  # Default if not found in saved data


# Function to interact with the furniture (e.g., toggling door state)
func interact():
	if is_door:
		toggle_door()
	else:
		Helper.signal_broker.furniture_interacted.emit(self)

# Function to toggle the door state
func toggle_door():
	door_state = "Open" if door_state == "Closed" else "Closed"
	furnitureJSON["Function"] = {"door": door_state}
	update_door_visuals()

# Update the visuals and physics of the door
func update_door_visuals():
	if not is_door:
		return

	# Adjust rotation and position based on door state
	var base_rotation = furniture_transform.get_rotation()
	var rotation_angle: int
	var position_offset: Vector3

	# Adjust rotation direction and position offset based on base_rotation
	if base_rotation == 0:
		rotation_angle = base_rotation + (-90 if door_state == "Open" else 0)
		position_offset = Vector3(0.5, 0, 0.5) if door_state == "Open" else Vector3.ZERO  # Move to the right
	elif base_rotation == 90:
		rotation_angle = base_rotation + (-90 if door_state == "Open" else 0)
		position_offset = Vector3(0.5, 0, 0.5) if door_state == "Open" else Vector3.ZERO  # Move backward
	else:
		rotation_angle = base_rotation + (90 if door_state == "Open" else 0)
		position_offset = Vector3(-0.5, 0, -0.5) if door_state == "Open" else Vector3.ZERO  # Standard offset

	apply_transform_to_instance(rotation_angle, position_offset)

# Function to apply the door's transformation
func apply_transform_to_instance(rotation_angle: int, position_offset: Vector3):
	# Apply transformation for mesh_instance (main visual mesh)
	var mesh_transform = Transform3D(
		Basis(Vector3(0, 1, 0), deg_to_rad(rotation_angle)),  # Apply rotation
		furniture_transform.get_position() + position_offset  # Apply position offset
	)
	RenderingServer.instance_set_transform(mesh_instance, mesh_transform)
	
	# Apply transformation for quad_instance (sprite) with rotation and sprite-specific offset
	var sprite_transform = Transform3D(
		Basis(Vector3(0, 1, 0), deg_to_rad(rotation_angle)),  # Apply rotation
		furniture_transform.get_sprite_transform().origin + position_offset  # Apply position and sprite offset
	)
	RenderingServer.instance_set_transform(quad_instance, sprite_transform)

	# Apply the same transform for collider if needed (only using mesh_transform logic here)
	PhysicsServer3D.body_set_state(collider, PhysicsServer3D.BODY_STATE_TRANSFORM, mesh_transform)


# Returns this furniture's data for saving, including door state, container state, and last checked time
func get_data() -> Dictionary:
	var newfurniturejson = {
		"id": furnitureJSON.id,
		"moveable": false,
		"global_position_x": furniture_transform.posx,
		"global_position_y": furniture_transform.posy,
		"global_position_z": furniture_transform.posz,
		"rotation": get_my_rotation(),
	}

	if is_door:
		newfurniturejson["Function"] = {"door": door_state}
	
	# Container functionality
	if container:
		if "Function" not in newfurniturejson:
			newfurniturejson["Function"] = {}
		newfurniturejson["Function"]["container"] = container.serialize()

	# Crafting container functionality
	if crafting_container:
		if "Function" not in newfurniturejson:
			newfurniturejson["Function"] = {}
		newfurniturejson["Function"]["crafting_container"] = crafting_container.serialize()

	return newfurniturejson


# When the furniture is destroyed, it leaves a wreck behind
func add_corpse(pos: Vector3):
	if can_be_destroyed():
		var newitemjson: Dictionary = {
			"global_position_x": pos.x,
			"global_position_y": pos.y,
			"global_position_z": pos.z
		}
		
		var myitemgroup = rfurniture.destruction.group
		if myitemgroup:
			newitemjson["itemgroups"] = [myitemgroup]
		
		var newItem: ContainerItem = ContainerItem.new(newitemjson)
		newItem.add_to_group("mapitems")
		
		var fursprite = rfurniture.destruction.sprite
		if fursprite:
			newItem.set_texture(fursprite)
		
		# Finally add the new item with possibly set loot group to the tree
		Helper.map_manager.level_generator.get_tree().get_root().add_child.call_deferred(newItem)
		
		# Check if inventory has items and insert them into the new item
		if is_container() and container.get_inventory():
			for item in container.get_inventory().get_items():
				newItem.insert_item(item)


# Check if the furniture can be destroyed
func can_be_destroyed() -> bool:
	return not rfurniture.destruction.get_data().is_empty()


# Check if the furniture can be disassembled
func can_be_disassembled() -> bool:
	return not rfurniture.disassembly.get_data().is_empty()


# Returns the inventorystacked that this container holds
func get_inventory() -> Inventory:
	return container.get_inventory()


# Returns the inventorystacked that this crafting container holds
func get_crafting_inventory() -> Inventory:
	return crafting_container.get_inventory()


func get_sprite() -> Texture:
	return rfurniture.sprite


# Replace animate_hit with show_hit_indicator
func get_hit(attack: Dictionary):
	var damage = attack.damage
	var hit_chance = attack.hit_chance

	# Calculate actual hit chance considering static furniture bonus
	var actual_hit_chance = hit_chance + 0.25  # Boost hit chance by 25%

	# Determine if the attack hits
	if randf() <= actual_hit_chance:
		# Attack hits
		if can_be_destroyed():
			current_health -= damage
			if current_health <= 0:
				_die()  # Destroy the furniture if health is depleted
			else:
				if not is_animating_hit:
					show_hit_indicator()  # Call the new hit indicator function instead of animate_hit
	else:
		# Attack misses, create a visual indicator
		show_miss_indicator()


# Function to handle furniture destruction
func _die(do_add_corpse: bool = true):
	if do_add_corpse:
		add_corpse(furniture_transform.get_position())  # Add wreck or corpse
	if is_container():
		Helper.signal_broker.container_exited_proximity.emit(self)
	Helper.time_helper.minute_passed.disconnect(on_minute_passed)
	free_resources()  # Free resources
	queue_free()  # Remove the node from the scene tree


# Generalized function to show an indicator (Hit/Miss)
func show_indicator(text: String, color: Color):
	var label = Label3D.new()
	label.text = text
	label.modulate = color
	label.font_size = 64
	Helper.map_manager.level_generator.get_tree().get_root().add_child(label)
	label.position = furniture_transform.get_position() + Vector3(0, 2, 0)  # Slightly above the furniture
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	# Animate the indicator to disappear quickly
	var tween = Helper.map_manager.level_generator.create_tween()

	tween.tween_property(label, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func():
		label.queue_free()  # Properly free the label node
	)

# Function to show a hit indicator
func show_hit_indicator():
	show_indicator("Hit!", Color(0, 1, 0))  # Green for hit


# Function to show a miss indicator
func show_miss_indicator():
	show_indicator("Miss!", Color(1, 0, 0))  # Red for miss


# Regenerate the container if the interval is more then -1
# This function is run by FurnitureStaticSpawner when the player enters proximity
func regenerate():
	if container:
		container.regenerate()

# When this furniture enters the item detector, it means the player is close
func on_entered_item_detector():
	regenerate()
	if crafting_container and not crafting_container.is_active:
		crafting_container.activate_crafting()  # Start active crafting

# When this furniture exits the item detector, it means the player is away
func on_exited_item_detector():
	if crafting_container and crafting_container.is_active:
		crafting_container.deactivate_crafting()  # Stop active crafting

func add_crafting_container():
	if is_crafting_station():
		crafting_container = CraftingContainer.new()
		crafting_container.furniturecontainer = container
		crafting_container.furniture_parent = self
		crafting_container.crafting_queue_updated.connect(_on_crafting_queue_updated)

func deserialize_crafting_container(data: Dictionary):
	if crafting_container:
		crafting_container.deserialize(data.get("crafting_container", {}))


# Function to transfer an item between containers dynamically
func transfer_item_between_containers(source_container: Object, item_id: String, quantity: int) -> bool:
	# Determine source and target inventories based on the source container type
	var source_inventory: Inventory
	var target_inventory: Inventory

	if source_container is FurnitureContainer and crafting_container:
		source_inventory = source_container.get_inventory()
		target_inventory = crafting_container.get_inventory()
	elif source_container is CraftingContainer and container:
		source_inventory = source_container.get_inventory()
		target_inventory = container.get_inventory()
	else:
		return false  # Either containers are not initialized or type is invalid

	# Get the items from the source inventory
	var items = source_inventory.get_items_with_prototype_id(item_id)
	if items.is_empty():
		return false  # Item not found in source

	# Transfer the items
	for item in items:
		var stack_size = item.get_stack_size()
		if stack_size > quantity:
			# Split the stack and transfer only the required quantity
			var split_item = source_inventory.split(item, quantity)
			return target_inventory.add_item_autosplitmerge(split_item)
		else:
			# Transfer the whole stack
			if target_inventory.add_item_autosplitmerge(item):
				quantity -= stack_size  # Adjust the remaining quantity to transfer
				if quantity <= 0:
					return true
	return false


# Function to check for the presence of an item in a container
func has_item_in_container(mycontainer: Object, item_id: String) -> bool:
	if mycontainer and mycontainer.has_method("get_inventory"):
		var target_inventory = mycontainer.get_inventory()
		return target_inventory.has_item_by_id(item_id) if target_inventory else false
	return false


# Function to count the amount of an item in a container
func get_item_count_in_container(mycontainer: Object, item_id: String) -> int:
	if mycontainer and mycontainer.has_method("get_inventory"):
		var target_inventory = mycontainer.get_inventory()
		if target_inventory:
			var items = target_inventory.get_items_by_id(item_id)
			var total_count = 0
			for item in items:
				total_count += item.get_stack_size()
			return total_count
	return 0


# Since this furniture node is not in the tree, we will respond to the 
# Helper.time_manager.minute_passed signal, which is connected in the 
# FurnitureStaticSpawner script.
func on_minute_passed(current_time: String):
	if crafting_container and crafting_container.is_active:
		crafting_container.process_active_crafting()
	if consumption:
		consumption.on_minute_passed(current_time)


# Add an item to the crafting queue. This might happen from a button in the furniture window
func add_to_crafting_queue(item_id: String) -> void:
	crafting_container.add_to_crafting_queue(item_id)


# Remove the first item from the crafting queue
func remove_from_crafting_queue(queue_item: QueueItem) -> void:
	crafting_container.remove_from_crafting_queue(queue_item)


# Forward the crafting_queue_updated signal
func _on_crafting_queue_updated(current_queue: Array[QueueItem]):
	crafting_queue_updated.emit(current_queue)  # Emit signal after updating the queue


func get_furniture_name() -> String:
	return rfurniture.name


# Get the available amount of the ingredient in the FurnitureContainer inventory.
func get_available_ingredient_amount(ingredient_id: String) -> int:
	var inventory = container.get_inventory()
	var available_amount: int = 0
	if inventory.get_item_with_prototype_id(ingredient_id):
		var items: Array = inventory.get_items_with_prototype_id(ingredient_id)
		for item in items:
			available_amount += item.get_stack_size()
	return available_amount


func are_all_ingredients_available(recipe: RItem.CraftRecipe) -> bool:
	for ingredient in recipe.required_resources:
		var available = get_available_ingredient_amount(ingredient.id)
		if available < ingredient.amount:
			return false
	return true


# Function to handle transformation and spawn new furniture
func transform_into():
	if not spawner or not spawner.chunk:
		print("Spawner or Spawner Chunk is null.")
		return
	var furniture_id: String = rfurniture.consumption.transform_into
	if not furniture_id:
		return
	var chunk: Chunk = spawner.chunk
	var construction_pos: Vector3 = furniture_transform.get_position()
	# Decrease y by half the height of the furniture
	construction_pos.y -= 0.5+furniture_transform.height * 0.5
	# Translate the position to negate the chunk's `mypos`
	construction_pos -= chunk.mypos

	# Prepare the "json" dictionary for the spawn_furniture call
	var furniture_json: Dictionary = {
		"id": furniture_id,
		"rotation": furniture_transform.get_rotation(),
		"pool": consumption.get_current_pool()
	}

	if rfurniture.function.is_container:
		# Prepare the "items" array from the inventory if the furniture is a container
		if get_inventory():
			var items_array: Array = []
			var items_copy = get_inventory().get_items().duplicate()
			for item in items_copy:
				items_array.append(item)  # Add each InventoryItem to the array
			furniture_json["items"] = items_array  # Include the "items" array in the json
	else:
		# If the furniture is not a container, call add_corpse
		add_corpse(Helper.overmap_manager.player.get_position())

	# Spawn the furniture instance with or without the "items" property
	chunk.spawn_furniture({
		"json": furniture_json,
		"pos": construction_pos
	})

	# Remove the instance afterwards and don't add a corpse
	_die(false)


# Takes an item_id and quantity and adds it to the inventory
func add_item_to_inventory(item_id: String, quantity: int) -> bool:
	# Check if inventory has items and insert them into the new item
	if is_container() and container.get_inventory():
		container.add_item_to_inventory(item_id, quantity)
		return true
	return false

# Returns the y position of the furniture.
# If 'snapped' is true, it returns the y position snapped to the nearest integer.
func get_y_position(is_snapped: bool = false) -> float:
	var y_pos = furniture_transform.posy
	return round(y_pos) if is_snapped else y_pos
