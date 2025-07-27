extends Node

# Existing variables
var is_mouse_outside_hud = false
var is_allowed_to_shoot = true

# For controlling the player actions
var is_action_in_progress = false
var action_timer: Timer
var action_complete_callback: Callable  # Use Callable to store the function reference
signal start_timer_progressbar(time_left: float)

# Shared shape for mobs
var shared_collision_shape = BoxShape3D.new()
var mob_mesh_cache: Dictionary = {}


## Initializes the action timer and connects signals.
func _ready():
	# Initialize the timer
	action_timer = Timer.new()
	action_timer.timeout.connect(_on_action_timer_timeout)
	add_child(action_timer)
	start_timer_progressbar.connect(Helper.signal_broker.on_start_timer_progressbar)
	shared_collision_shape.size = Vector3(0.35, 0.35, 0.35)


# Function to start an action
# Usage example:
# This example will call the 'reload_weapon" function in self after the timer is complete
# var reload_callable = Callable(self, "reload_weapon").bind(item, specific_magazine)
# General.start_action(reload_time, reload_callable)
# Usage example using an inline callable:
# This example will call the 'myfunc' callable after the start_action timer runs out
# var myfunc: Callable = func (itemgroup_id):
#	 var ditemgroup: DItemgroup = Gamedata.mods.by_id("Core").itemgroups.by_id(itemgroup_id)
#	 ditemgroup.remove_item_by_id(id)
# General.start_action(reload_time, myfunc)
func start_action(duration: float, callback: Callable):
	if not is_action_in_progress:
		is_action_in_progress = true
		action_complete_callback = callback  # Store the callback function
		action_timer.start(duration)
		start_timer_progressbar.emit(duration)
		# Other necessary code to start the action
	else:
		print_debug("Another action is currently in progress.")


## Handles the completion of a timed action.
func _on_action_timer_timeout():
	is_action_in_progress = false
	# Call the callback function if it exists
	if action_complete_callback:
		var result = action_complete_callback.call()
		if result is bool and result == false:
			print_debug("Action callback returned failure.")
	# Reset the callback function
	action_complete_callback = Callable()
	# Code to handle the completion of the action


## Converts a string in the form "(x, y)" to a Vector2. Returns Vector2.ZERO if invalid.
static func string_to_vector2(input: Variant) -> Vector2:
	# If input is already a Vector2, return it as is
	if input is Vector2:
		return input

	# If input is a String, attempt to parse it
	if input is String and input != "":
		var new_string: String = input
		new_string = new_string.erase(0, 1)
		new_string = new_string.erase(new_string.length() - 1, 1)
		var array: Array = new_string.split(", ")

		return Vector2(int(array[0]), int(array[1]))

	# If input is invalid, return Vector2.ZERO
	return Vector2.ZERO


# Returns a cached mesh for the given mob sprite. Creates and stores it if needed.
func get_mob_mesh(sprite: Texture) -> Mesh:
	var key: String = sprite.resource_path
	if mob_mesh_cache.has(key):
		return mob_mesh_cache[key]

	var quadmesh := QuadMesh.new()
	quadmesh.size = Vector2(0.5, 0.5)
	quadmesh.orientation = PlaneMesh.FACE_Y
	quadmesh.lightmap_size_hint = Vector2(7, 7)

	var material := StandardMaterial3D.new()
	material.albedo_texture = sprite
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quadmesh.surface_set_material(0, material)

	mob_mesh_cache[key] = quadmesh
	return quadmesh
