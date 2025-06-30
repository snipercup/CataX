extends Node3D

@onready var projectiles_container : Node = $Projectiles
const POOL_SIZE: int = 100
var pool: Array[Mob] = []

func _init():
	Helper.signal_broker.projectile_spawned.connect(on_projectile_spawned)
	# Connect to the mob_spawned signal
	Helper.signal_broker.mob_spawned.connect(_on_mob_spawned)
	Helper.signal_broker.mob_killed.connect(_on_mob_killed)

func _ready():
	initialize_pool()

func on_projectile_spawned(projectile: Node, instigator: RID):
	projectiles_container.add_child(projectile)


func initialize_pool() -> void:
	if pool.size() > 0:
		return  # Pool already initialized
	var dummy_data: Dictionary = {"id": "basic_zombie_1"}  # Example mob ID for initialization
	for i in range(POOL_SIZE):
		var mob: Mob = Mob.new(Vector3.ZERO, dummy_data)
		# Add to scene and initialize physics objects
		add_child(mob)
		mob.visible = false
		mob.set_physics_process(false)
		mob.state_machine.set_physics_process(false)
		mob.detection.set_physics_process(false)
		if mob.collision_shape_3d:
			mob.collision_shape_3d.disabled = true
		pool.append(mob)  # ✅ Add to pool
	await get_tree().process_frame  # Allow deferred collisions/nav setup to complete

func spawn_mob(at_pos: Vector3, mob_json: Dictionary) -> CharacterBody3D:
	if pool.is_empty():
		push_error("Mob pool exhausted! Increase POOL_SIZE.")
		return null
	# Activate a mob from the pool
	var mob: Mob = pool.pop_back()
	# turn collisions off
	mob.collision_layer = 0
	mob.collision_mask  = 0
	mob.set_global_position.call_deferred(at_pos)
	await get_tree().physics_frame  # ← key: wait until transform is stable
	# restore colission layers
	mob.setup_collision_layers_and_masks()
	mob.apply_mob_data(mob_json)
	_reactivate_mob.call_deferred(mob)
	Helper.signal_broker.mob_spawned.emit(mob)
	return mob

func _reactivate_mob(mob):
	mob.visible = true
	mob.set_physics_process(true)
	mob.state_machine.set_physics_process(true)
	mob.detection.set_physics_process(true)
	if mob.collision_shape_3d:
		mob.collision_shape_3d.disabled = false
		
func despawn_mob(mob: CharacterBody3D) -> void:
	# Deactivate and hide the mob
	mob.visible = false
	if mob.collision_shape_3d:
		mob.collision_shape_3d.set_disabled.call_deferred(true)
	mob.set_physics_process(false)
	mob.state_machine.set_physics_process(false)
	mob.detection.set_physics_process(false)
	#mob.remove_from_group("mobs")
	# Reset any transient state (if needed)
	mob.is_blinking = false
	mob.terminated = false
	# turn collisions off
	mob.collision_layer = 0
	mob.collision_mask  = 0
	# Return to pool
	pool.append(mob)


# When a mob is spawned
func _on_mob_spawned(_mob) -> void:
	pass

# When a mob is killed, remove it
func _on_mob_killed(mob) -> void:
	despawn_mob(mob)


func get_mob_from_pool() -> Mob:
	return pool.pop_back()
