class_name Player
extends CharacterBody3D

var is_alive: bool = true

var rng = RandomNumberGenerator.new()

var speed: float = 2.0  # speed in meters/sec

var run_multiplier: float = 1.1
var is_running: bool = false
@onready var movement_timer: Timer = $MovementTimer

var max_stamina: float = 100.0
var current_stamina: float
var stamina_lost_while_running_per_sec: float = 15.0
var stamina_regen_while_standing_still: float = 3.0

var nutrition: float = 100.0
var current_nutrition: float

var pain: float
var current_pain: float = 0.0

# Slots that the player can equip items into, i.e. left hand and right hand
var held_item_slots: Array[EquippedItem]
var stats: Dictionary = {}
var skills: Dictionary = {}
# Dictionary that holds instances of PlayerAttribute. For example food, water, mood
var attributes: Dictionary = {}

var time_since_ready: float = 0.0
var delay_before_movement: float = 2.0  # 2 second delay

# Variable to track the stun amount
var stun_amount: float = 0.0
var stun_depletion_rate: float = 10.0  # Amount to reduce per second

# Variables to handle knockback
var knockback_active: bool = false
var knockback_velocity: Vector3 = Vector3.ZERO
var knockback_distance_remaining: float = 0.0

var move_input: Vector2 = Vector2.ZERO

@export var sprite: Sprite3D
@export var collision_detector: Area3D  # Used for detecting collision with furniture
@export var testing: bool = false  # Used to test in the test_environment
@export var interact_range: float = 10
@export var camera_3d: Camera3D = null
var my_viewport: Viewport

#@export var progress_bar : NodePath
#@export var progress_bar_filling : NodePath
#@export var progress_bar_timer : NodePath

# Variables for furniture pushing
var pushing_furniture: bool = false
var furniture_body: RID
# Store the last known player Y level for comparison
var last_y_level: float = 0.0
# ✅ Timer to check player Y level every 0.1 seconds
var y_level_timer: Timer
#var progress_bar_timer_max_time : float

#var is_progress_bar_active = false


func _init():
	_connect_signals()


func _ready():
	my_viewport = get_viewport()
	connect_held_item_slots()
	initialize_condition()
	initialize_attributes()
	initialize_stats_and_skills()
	Helper.save_helper.load_player_state(self)
	Helper.save_helper.load_quest_state()
	collision_detector.body_shape_entered.connect(_on_body_entered)
	collision_detector.body_shape_exited.connect(_on_body_exited)

	# ✅ Set up the timer to check Y level frequently
	y_level_timer = Timer.new()
	y_level_timer.wait_time = 0.1
	y_level_timer.autostart = true
	y_level_timer.timeout.connect(_update_player_y_level)
	add_child(y_level_timer)

	if not testing and Helper.test_map_name == "":
		Helper.signal_broker.player_spawned.emit(self)


# Connect necessary signals for interaction and updates
func _connect_signals():
	Helper.signal_broker.food_item_used.connect(_on_food_item_used)
	Helper.signal_broker.medical_item_used.connect(_on_medical_item_used)
	ItemManager.craft_successful.connect(_on_craft_successful)
	Helper.signal_broker.wearable_was_equipped.connect(_on_wearable_was_equipped)
	Helper.signal_broker.wearable_was_unequipped.connect(_on_wearable_was_unequipped)
	PlayerInputSignalBroker.run_toggled().connect(_on_run_toggled)
	PlayerInputSignalBroker.interact().connect(_on_interact)
	PlayerInputSignalBroker.movement_vector().connect(_on_movement_vector)


func connect_held_item_slots():
	held_item_slots = [$Sprite3D2/EquippedLeft, $Sprite3D2/EquippedRight]
	for i in range(0, len(held_item_slots)):
		PlayerInputSignalBroker.try_activate_equipped_item(i).connect(
			held_item_slots[i].try_activate_equipped_item
		)
		Helper.signal_broker.item_was_equipped_to_slot(i).connect(
			held_item_slots[i]._on_hud_item_was_equipped
		)
		Helper.signal_broker.item_was_unequipped_from_slot(i).connect(
			held_item_slots[i]._on_hud_item_equipment_slot_was_cleared
		)


func initialize_condition():
	current_stamina = max_stamina
	current_nutrition = nutrition
	current_pain = pain


# Initializes the playerattributes based on the DPlayerAttribute
# The PlayerAttribute manages the actual control of the attribute while
# DPlayerAttribute only provides the data
func initialize_attributes():
	var playerattributes: Dictionary = Runtimedata.playerattributes.get_all()
	for attribute: RPlayerAttribute in playerattributes.values():
		attributes[attribute.id] = PlayerAttribute.new(attribute, self)


# Initialize skills with level and XP
func initialize_stats_and_skills():
	# Initialize all stats with a value of 5
	for stat in Runtimedata.stats.get_all().values():
		stats[stat.id] = 5
	Helper.signal_broker.player_stat_changed.emit(self)

	# Initialize all skills with a value of level 1 and 0 XP
	for skill in Runtimedata.skills.get_all().values():
		skills[skill.id] = {"level": 1, "xp": 0}
	Helper.signal_broker.player_skill_changed.emit(self)


func _process(_delta):
	# Get the 2D screen position of the player
	var player_screen_pos = camera_3d.unproject_position(global_position)

	# Get the mouse position in 2D screen space
	var mouse_pos_2d = my_viewport.get_mouse_position()

	# Calculate the direction vector from the player to the mouse position
	var dir = (mouse_pos_2d - player_screen_pos).normalized()

	# Calculate the angle between the player and the mouse position
	# Since the sprite is rotating in the opposite direction, change the sign of the angle
	var angle = atan2(-dir.y, -dir.x)  # This negates both components of the direction vector

	sprite.rotation.y = -angle  # Inverts the angle for rotation
	$CollisionShape3D.rotation.y = -angle  # Inverts the angle for rotation

	var current_y_level = global_position.y
	RenderingServer.global_shader_parameter_set("player_y_level", current_y_level)


func _physics_process(delta: float) -> void:
	time_since_ready += delta
	if time_since_ready < delay_before_movement:
		# Skip movement updates during the delay period to prevent
		# the player from falling into the ground while the ground is spawning.
		return

	apply_gravity(delta)
	move_and_slide()

	if is_alive:
		# Handle knockback movement if active
		if knockback_active:
			# Set the knockback velocity for this frame
			velocity = knockback_velocity
			move_and_slide()  # Call without arguments

			# Update the remaining knockback distance
			knockback_distance_remaining -= knockback_velocity.length() * delta

			# Check if knockback is complete
			if knockback_distance_remaining <= 0.0:
				knockback_active = false
				velocity = Vector3.ZERO  # Reset velocity

		# Check if the player is stunned; if so, prevent control-based movement
		if is_stunned():
			deplete_stun(delta)  # Deplete stun amount
			move_and_slide()  # Keep moving with existing velocity but no input-based movement
			return  # Prevent further processing for player control

		# Player control movement
		if not knockback_active:
			var initial_stamina = current_stamina
			var direction = (transform.basis * Vector3(move_input.x, 0, move_input.y)).normalized()
			# Athletics skill level
			var athletics_level = get_skill_level("athletics")

			# Calculate run multiplier and stamina modifications
			run_multiplier = 1.1 + (athletics_level / 100.0) * (2.0 - 1.1)
			stamina_lost_while_running_per_sec = 15 - (athletics_level / 100.0) * (15 - 5)
			stamina_regen_while_standing_still = 3 + (athletics_level / 100.0) * (8 - 3)

			# Check if the player is pushing furniture
			if pushing_furniture and furniture_body:
				# Apply resistance based on the mass of the furniture collider
				var mass = PhysicsServer3D.body_get_param(
					furniture_body, PhysicsServer3D.BODY_PARAM_MASS
				)
				var resistance = 1.0 / mass
				velocity = direction * speed * resistance
			else:
				# Movement logic
				if not is_running or current_stamina <= 0:
					velocity = direction * speed
				elif is_running and current_stamina > 0:
					velocity = direction * speed * run_multiplier

					if velocity.length() > 0:
						current_stamina -= delta * stamina_lost_while_running_per_sec
						add_skill_xp("athletics", 0.01)

			# Stamina regeneration when standing still
			if velocity.length() < 0.1:
				current_stamina += delta * stamina_regen_while_standing_still
			else:
				if movement_timer.time_left <= 0:
					if not testing and Helper.test_map_name == "":
						play_tile_footstep_sound() # Only play in regular game, not testing
					if not is_running or current_stamina == 0:
						movement_timer.start(0.5)
					else:
						movement_timer.start(0.3)
			current_stamina = clamp(current_stamina, 0.0, max_stamina)

			if current_stamina != initial_stamina:
				Helper.signal_broker.player_stamina_changed.emit(self, current_stamina)
		move_and_slide()


func apply_gravity(delta: float) -> void:
	# Added an arbitrary multiplier because without it, the player will fall slowly
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	velocity.y -= gravity * 12 * delta


# When a body enters the CollisionDetector area
# This will be a FurniturePhysicsSrv since it's only detecting layer 4
# Layer 4 is the moveable furniture layer
# Since FurniturePhysicsSrv is not in the scene tree, we will have an RID but no body
func _on_body_entered(body_rid: RID, body: Node3D, _body_shape_index: int, _local_shape_index: int):
	if body_rid and not body:
		pushing_furniture = true
		furniture_body = body_rid


func _on_body_exited(body_rid: RID, body: Node3D, _body_shape_index: int, _local_shape_index: int):
	if body_rid and not body:
		pushing_furniture = false


# Update running state when the run key is pressed or released
func _on_run_toggled(running: bool) -> void:
	is_running = running


# Called when the interact key is pressed
func _on_interact() -> void:
	print_block_id_under_player()
	_check_for_interaction()


func _on_movement_vector(vec: Vector2) -> void:
	move_input = vec


# Check if player can interact with an object
func _check_for_interaction() -> void:
	var layer = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 6)  # Check for layers 1, 2, 3, and 7
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var raycast: Dictionary = Helper.raycast_from_mouse(mouse_pos, layer)
	if not raycast.has("position"):
		return

	var world_mouse_position = raycast.position

	# Lower the y-value of global_position by 0.5
	# This is required to interact with short furniture
	var adjusted_global_position = global_position - Vector3(0, 0.5, 0)
	var raycast_target = (
		adjusted_global_position
		+ (
			(
				(Vector3(
					world_mouse_position.x - adjusted_global_position.x,
					0,
					world_mouse_position.z - adjusted_global_position.z
				))
				. normalized()
			)
			* interact_range
		)
	)

	var result = Helper.raycast(adjusted_global_position, raycast_target, layer, [self])

	if result:
		# Check the distance to the result position
		var distance_to_result = adjusted_global_position.distance_to(result.position)
		if distance_to_result <= 1.5:
			Helper.signal_broker.player_interacted.emit(result.position, result.rid)


# The player gets hit by an attack
# attack: a dictionary like this:
# {
# 	"attack": chosen_attack, # Exmple: {"id": "basic_melee", "damage_multiplier": 1, "type": "melee"}
# 	"mobposition": Vector3(17, 1, 219) # The global position of the mob
# }
func get_hit(attack_data: Dictionary):
	Sfx.play_generic_sfx()
	var attack: Dictionary = attack_data.get("attack", {})
	var rattack: RAttack = Runtimedata.attacks.by_id(attack.get("id", ""))
	if not rattack:
		print_debug("Invalid attack ID:", attack.get("id", ""))
		return

	# Get the attack effects with the applied damage multiplier
	var attack_effects: Dictionary = rattack.get_scaled_attack_effects(
		attack_data.get("damage_multiplier", 1.0)
	)

	# Apply damage to each affected attribute
	for attribute in attack_effects["attributes"]:
		var attribute_id: String = attribute["id"]
		var damage_value: float = attribute["damage"]

		if attributes.has(attribute_id):
			attributes[attribute_id].reduce_amount(damage_value)

	# Apply knockback if applicable
	if attack_effects["knockback"] > 0 and attack_data.has("mobposition"):
		_perform_knockback(attack_effects["knockback"], attack_data["mobposition"])


func die():
	if is_alive:
		print("Player died")
		is_alive = false
		Sfx.gameplay_sfx_stop()
		Music.gameplay_music_stop()
		Music.GameOverMusic.play()
		Helper.signal_broker.player_died.emit(self)


# The player has selected one or more items in the inventory and selected
# 'use' from the context menu.
func _on_food_item_used(usedItem: InventoryItem) -> void:
	var food = RItem.Food.new(usedItem.get_property("Food"))
	var was_used: bool = false

	for attribute in food.attributes:
		attributes[attribute.id].modify_current_amount(attribute.amount)
		was_used = true

	if was_used:
		var stack_size: int = InventoryStacked.get_item_stack_size(usedItem)
		InventoryStacked.set_item_stack_size(usedItem, stack_size - 1)


# The player has selected one or more items in the inventory and selected
# 'use' from the context menu.
func _on_medical_item_used(usedItem: InventoryItem) -> void:
	var medical = RItem.Medical.new(usedItem.get_property("Medical"))
	var was_used: bool = false

	# Step 1: Apply specific amounts to each attribute
	# example of medical.attributes: [{"id":"torso","amount":10}]
	was_used = _apply_specific_attribute_amounts(medical.attributes) or was_used

	# Step 2: Apply the general medical amount from the pool
	was_used = _apply_general_medical_amount(medical) or was_used

	# If any attribute was modified, reduce the item stack size by 1
	if was_used:
		var stack_size: int = InventoryStacked.get_item_stack_size(usedItem)
		InventoryStacked.set_item_stack_size(usedItem, stack_size - 1)


# Function to apply specific amounts to each attribute
# medattributes: Attributes assigned to the medical item
# For example: [{"id":"torso","amount":10}] would add 10 to the "torso" attribute
func _apply_specific_attribute_amounts(medattributes: Array) -> bool:
	var was_used: bool = false

	for medattribute in medattributes:
		# Get the values from the current player's attribute
		var playerattribute: PlayerAttribute = attributes[medattribute.id]
		var current_amount = playerattribute.default_mode.current_amount
		var max_amount = playerattribute.default_mode.max_amount
		var min_amount = playerattribute.default_mode.min_amount

		# Make sure we don't add or subtract more then the min and max amount
		var new_amount = clamp(current_amount + medattribute.amount, min_amount, max_amount)

		# If the new amount is different from the current amount, apply the change
		if new_amount != current_amount:
			playerattribute.modify_current_amount(new_amount - current_amount)
			was_used = true

	return was_used


# Function to apply the general medical amount from the pool
# See the RItem class and its Medical subclass for the properties of RItem.Medical
func _apply_general_medical_amount(medical: RItem.Medical) -> bool:
	var was: Dictionary = {"used": false}  # Keep track of whether the item was used
	var pool = medical.amount

	# Collect the IDs from medical attributes into an array
	var med_attribute_ids = []
	for med_attr in medical.attributes:
		med_attribute_ids.append(med_attr.get("id", ""))

	# Get the matching PlayerAttributes based on the collected attribute IDs
	var matching_player_attributes = get_matching_player_attributes(med_attribute_ids)

	# Separate attributes based on depletion_effect == "death"
	var death_effect_attributes: Array[PlayerAttribute] = []
	var other_attributes: Array[PlayerAttribute] = []

	for playerattribute in matching_player_attributes:
		if playerattribute.default_mode.depletion_effect == "death":
			death_effect_attributes.append(playerattribute)
		else:
			other_attributes.append(playerattribute)

	# First, apply the pool to attributes with the death effect
	var sorted_death_attributes = _sort_player_attributes_by_order(
		death_effect_attributes, medical.order
	)
	pool = _apply_pool_to_attributes(sorted_death_attributes, pool, was)

	# Then, apply the remaining pool to the other attributes
	var sorted_other_attributes = _sort_player_attributes_by_order(other_attributes, medical.order)
	pool = _apply_pool_to_attributes(sorted_other_attributes, pool, was)

	return was.used


# Helper function to apply the pool to a given array of PlayerAttributes
func _apply_pool_to_attributes(
	myattributes: Array[PlayerAttribute], pool: float, was: Dictionary
) -> float:
	for playerattribute in myattributes:
		var current_amount = playerattribute.default_mode.current_amount
		var max_amount = playerattribute.default_mode.max_amount
		var min_amount = playerattribute.default_mode.min_amount

		# Calculate how much can actually be added from the pool
		var additional_amount = min(pool, max_amount - current_amount)

		# Make sure that amount is not more or less than the min and max amount for the attribute
		var new_amount = clamp(current_amount + additional_amount, min_amount, max_amount)

		# Update the pool after applying the additional amount
		pool -= (new_amount - current_amount)

		# If the new amount is different from the current amount, apply the change
		if not new_amount == current_amount:
			playerattribute.modify_current_amount(new_amount - current_amount)
			was.used = true

		# If the pool is exhausted, break out of the loop
		if pool <= 0:
			break

	return pool


# Sort PlayerAttributes based on the specified order
func _sort_player_attributes_by_order(
	myattributes: Array[PlayerAttribute], order: String
) -> Array[PlayerAttribute]:
	match order:
		"Ascending":
			# Reverse the array and return it
			myattributes.reverse()
			return myattributes
		"Descending":
			# Use the original order of medical.attributes
			return myattributes
		"Lowest first":
			myattributes.sort_custom(_compare_player_attributes_by_current_amount_ascending)
		"Highest first":
			myattributes.sort_custom(_compare_player_attributes_by_current_amount_descending)
		"Random":
			myattributes.shuffle()
		_:
			# Default to no sorting if an invalid order is provided
			pass
	return myattributes


# Custom sorting functions for PlayerAttributes
func _compare_player_attributes_by_current_amount_ascending(
	a: PlayerAttribute, b: PlayerAttribute
) -> bool:
	return a.default_mode.current_amount < b.default_mode.current_amount


func _compare_player_attributes_by_current_amount_descending(
	a: PlayerAttribute, b: PlayerAttribute
) -> bool:
	return a.default_mode.current_amount > b.default_mode.current_amount


# Function to retrieve PlayerAttributes that match the provided IDs in the array
func get_matching_player_attributes(attribute_ids: Array) -> Array[PlayerAttribute]:
	var matching_attributes: Array[PlayerAttribute] = []

	# Loop over each attribute ID provided
	for attr_id in attribute_ids:
		# Check if the player has an attribute with the same ID
		if attributes.has(attr_id):
			# Add the corresponding PlayerAttribute to the array
			matching_attributes.append(attributes[attr_id])

	return matching_attributes


# Method to get the current level of a skill
func get_skill_level(skill_id: String) -> int:
	if skills.has(skill_id):
		return skills[skill_id]["level"]
	else:
		push_error("Skill ID not found: %s" % skill_id)
		return 0  # Return 0 or an appropriate default value if the skill is not found


# Method to get the current amount of XP for a skill
func get_skill_xp(skill_id: String) -> int:
	if skills.has(skill_id):
		return skills[skill_id]["xp"]
	else:
		push_error("Skill ID not found: %s" % skill_id)
		return 0  # Return 0 or an appropriate default value if the skill is not found


# Method to set the level of a skill
func set_skill_level(skill_id: String, level: int) -> void:
	if skills.has(skill_id):
		skills[skill_id]["level"] = level
		Helper.signal_broker.player_skill_changed.emit(self)
	else:
		push_error("Skill ID not found: %s" % skill_id)


# Method to set the amount of XP for a skill
func set_skill_xp(skill_id: String, xp: int) -> void:
	if skills.has(skill_id):
		skills[skill_id]["xp"] = xp
		Helper.signal_broker.player_skill_changed.emit(self)
	else:
		push_error("Skill ID not found: %s" % skill_id)


# Method to add an amount of levels to a skill
func add_skill_level(skill_id: String, levels: int) -> void:
	if skills.has(skill_id):
		skills[skill_id]["level"] += levels
		Helper.signal_broker.player_skill_changed.emit(self)
	else:
		push_error("Skill ID not found: %s" % skill_id)


# Method to add an amount of XP to a skill
# This also increases the skill level when the XP reaches 100
func add_skill_xp(skill_id: String, xp: float) -> void:
	if skills.has(skill_id):
		var current_xp = skills[skill_id]["xp"]
		var current_level = skills[skill_id]["level"]
		current_xp += xp

		# Check if XP exceeds 100 and handle level up
		while current_xp >= 100:
			current_xp -= 100
			current_level += 1

		skills[skill_id]["xp"] = current_xp
		skills[skill_id]["level"] = current_level
		Helper.signal_broker.player_skill_changed.emit(self)
	else:
		push_error("Skill ID not found: %s" % skill_id)


# -----------------------
#      STAT HELPERS
# -----------------------


# Returns the current value of a stat or 0 if it doesn't exist
func get_stat(stat_id: String) -> int:
	if stats.has(stat_id):
		return stats[stat_id]
	return 0


# Sets the value for a stat and emits the change signal
func set_stat(stat_id: String, value: int) -> void:
	stats[stat_id] = value
	Helper.signal_broker.player_stat_changed.emit(self)


# Adds an amount to a stat value and emits the change signal
func add_stat(stat_id: String, amount: int) -> void:
	set_stat(stat_id, get_stat(stat_id) + amount)


# The player has succesfully crafted an item. Get the skill id and xp from
# the recipe and add it to the player's skill xp
func _on_craft_successful(_item: RItem, recipe: RItem.CraftRecipe):
	if recipe.skill_progression:
		add_skill_xp(recipe.skill_progression.id, recipe.skill_progression.xp)


# Method to retrieve the current state of the player as a dictionary
func get_state() -> Dictionary:
	var attribute_data = {}
	for attribute_id in attributes.keys():
		attribute_data[attribute_id] = attributes[attribute_id].get_data()

	return {
		"is_alive": is_alive,
		"stamina": current_stamina,
		"nutrition": current_nutrition,
		"pain": current_pain,
		"skills": skills,
		"attributes": attribute_data,  # Include the attributes data
		"global_position_x": global_transform.origin.x,
		"global_position_y": global_transform.origin.y,
		"global_position_z": global_transform.origin.z
	}


# Method to set the player's state from a dictionary
func set_state(state: Dictionary) -> void:
	is_alive = state.get("is_alive", is_alive)
	current_stamina = state.get("stamina", current_stamina)
	current_nutrition = state.get("nutrition", current_nutrition)
	current_pain = state.get("pain", current_pain)
	skills = state.get("skills", skills)

	# Set the attributes data. Assumes the attributes
	# have already been initialized in initialize_attributes
	var attribute_data = state.get("attributes", {})
	for attribute_id in attribute_data.keys():
		if attributes.has(attribute_id):
			attributes[attribute_id].set_data(attribute_data[attribute_id])

	global_transform.origin.x = state.get("global_position_x", global_transform.origin.x)
	global_transform.origin.y = state.get("global_position_y", global_transform.origin.y)
	global_transform.origin.z = state.get("global_position_z", global_transform.origin.z)

	# Emit signals to update the HUD
	Helper.signal_broker.player_stamina_changed.emit(self, current_stamina)


# Function to handle adding or subtracting player attribute amounts when equipping/unequipping
# When fixed_mode.amount is updated, it will send it's own signal for further processing
func _modify_player_attribute_on_equip(wearableItem: InventoryItem, is_equipping: bool):
	# Check if the wearable item has a Wearable property
	if not wearableItem or not wearableItem.get_property("Wearable"):
		return

	# Get the Wearable data from the item
	var dwearable: RItem.Wearable = RItem.Wearable.new(wearableItem.get_property("Wearable"))

	# Get the list of player attributes from the wearable
	var myattributes: Array = dwearable.player_attributes

	# Loop over each player attribute in the wearable
	for attribute in myattributes:
		var attribute_id: String = attribute.get("id", "")
		var amount: float = attribute.get("value", 0)

		# Check if the global attributes dictionary has the attribute id
		if attribute_id in attributes:
			var player_attribute: PlayerAttribute = attributes[attribute_id]
			# If equipping, add the amount; if unequipping, subtract the amount
			if is_equipping:
				player_attribute.modify_temp_amount(amount)
			else:
				player_attribute.modify_temp_amount(-amount)


# Function for handling when a wearable is equipped
func _on_wearable_was_equipped(wearableItem: InventoryItem, _wearableSlot: Control):
	_modify_player_attribute_on_equip(wearableItem, true)  # true for equipping


# Function for handling when a wearable is unequipped
func _on_wearable_was_unequipped(wearableItem: InventoryItem, _wearableSlot: Control):
	_modify_player_attribute_on_equip(wearableItem, false)  # false for unequipping


# Function to handle knockback, initializing the velocity and distance
# knockback_distance: The number of tiles (units) to push the player back
# mob_position: The global position of the mob that initiated the knockback
func _perform_knockback(knockback_distance: float, mob_position: Vector3):
	knockback_active = true
	var direction_vector = (global_position - mob_position).normalized()
	knockback_velocity = direction_vector * speed * 3.0  # Adjust this factor as needed
	knockback_distance_remaining = knockback_distance


# Function to check if the player is currently stunned
func is_stunned() -> bool:
	return stun_amount > 0.0


# Function to deplete the stun amount over time
func deplete_stun(delta: float) -> void:
	stun_amount = max(0.0, stun_amount - stun_depletion_rate * delta)


# Function to increase the stun amount
func add_stun(amount: float) -> void:
	stun_amount += amount


# Returns the y position of the player.
# If 'snapped' is true, it returns the y position snapped to the nearest integer.
func get_y_position(is_snapped: bool = false) -> float:
	var y_pos = global_transform.origin.y
	return round(y_pos) if is_snapped else y_pos


# ✅ Emit signal only if the Y level has changed
func _update_player_y_level():
	var current_y_level = global_position.y
	# Only emit the signal if the Y level has changed
	if current_y_level != last_y_level:
		last_y_level = current_y_level  # Update last known Y level


# Prints the id of the block the player is currently standing on
func print_block_id_under_player() -> void:
	var tile_id = get_tile_id_under_player()
	if tile_id:
		print("Player is standing on block id: ", tile_id)
	else:
		print("No block found under player.")


# Returns the tile ID of the block directly beneath the player, or null if not found
func get_tile_id_under_player() -> String:
	var chunk = Helper.map_manager.get_chunk_from_position(global_position)
	if chunk == null:
		return ""

	var local_x = int(global_position.x - chunk.mypos.x) % 32
	if local_x < 0:
		local_x += 32
	var local_z = int(global_position.z - chunk.mypos.z) % 32
	if local_z < 0:
		local_z += 32

	var level_index = int(floor(global_position.y - 1.0))  # slightly below player

	var block_data = chunk.get_block_at(level_index, Vector2i(local_x, local_z))
	if block_data and block_data.has("id"):
		return block_data["id"]
	return ""


# Returns a Dictionary containing the sound category and volume for the tile under the player
# If not found, returns default values: category = "default", volume = 100
func get_tile_sound_info_under_player() -> Dictionary:
	var tile_id := get_tile_id_under_player()
	if not tile_id:
		return {"sound_category": "default", "sound_volume": 100}

	var rtile := Runtimedata.tiles.by_id(tile_id)
	if not rtile:
		return {"sound_category": "default", "sound_volume": 100}

	return {"sound_category": rtile.sound_category, "sound_volume": rtile.sound_volume}


# Plays the appropriate footstep SFX based on the tile the player is standing on
func play_tile_footstep_sound():
	var sound_info = get_tile_sound_info_under_player()
	var category: String = sound_info.sound_category
	var volume: float = sound_info.sound_volume

	match category:
		"grass":
			Sfx.play_movement_sfx(Sfx.SFX.WALKING_GRASS, volume)
		"concrete":
			Sfx.play_movement_sfx(Sfx.SFX.WALKING_CONCRETE, volume)
		"wood":
			Sfx.play_movement_sfx(Sfx.SFX.WALKING_WOOD, volume)
		"metal":
			Sfx.play_movement_sfx(Sfx.SFX.WALKING_METAL, volume)
		_:
			# Default fallback to grass if unknown
			Sfx.play_movement_sfx(Sfx.SFX.WALKING_GRASS, volume)
