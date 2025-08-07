extends State
class_name MobAttack

var attack_timer: Timer
var mob: CharacterBody3D  # The mob that we execute the attack for

var spotted_target: CharacterBody3D  # This mob's current target for combat
var is_in_attack_mode = false


func _ready():
	name = "MobAttack"
	# Create and configure AttackCooldown Timer
	var attack_cooldown = Timer.new()
	attack_timer = attack_cooldown
	var rattack: RAttack = Runtimedata.attacks.by_id(mob.attacks["melee"][0].id)
	attack_timer.wait_time = rattack.cooldown  # Set the wait time based on mob's melee_cooldown
	add_child.call_deferred(attack_cooldown)
	attack_timer.timeout.connect(_on_attack_cooldown_timeout)

	# Connect to the mob_killed signal from the signal broker
	Helper.signal_broker.mob_killed.connect(_on_mob_killed)


func enter():
	attack_timer.start()
	print("ENTERING BATTLE MODE")


func exit():
	pass


func physics_update(_delta: float):
	if mob.terminated:
		Transistioned.emit(self, "mobterminate")
	# Rotation towards target using look_at
	if spotted_target:
		var target_position = spotted_target.global_position
		target_position.y = mob.meshInstance.global_position.y  # Align y-axis to avoid tilting
		mob.meshInstance.look_at(target_position, Vector3.UP)

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		mob.global_position, spotted_target.global_position, 3, [self]
	)
	var result = space_state.intersect_ray(query)

	if result and result.collider:
		if (
			(result.collider.is_in_group("Players") or result.collider.is_in_group("mobs"))
			and (
				Vector3(mob.global_position).distance_to(spotted_target.global_position)
				<= mob.get_melee_range()
			)
		):
			if !is_in_attack_mode:
				is_in_attack_mode = true
				try_to_attack()
		else:
			is_in_attack_mode = false
			stop_attacking()
	else:
		is_in_attack_mode = false
		stop_attacking()


func try_to_attack():
	print("Trying to attack...")
	attack_timer.start()


# The mob is going to attack.
# attack: a dictionary like this:
# {
#   "attributeid": "torso_health", # The PlayerAttribute that is targeted by this attack
#   "damage": 20, # The amount to subtract from the target attribute
#   "knockback": 2, # The number of tiles to push the player away
#   "mobposition": Vector3(17, 1, 219) # The global position of the mob
# }
func attack():
	print("Attacking!")
	# Exmple: {"id": "basic_melee", "damage_multiplier": 1, "type": "melee"}
	var chosen_attack: Dictionary = mob.get_attack_of_type("melee")
	if not chosen_attack:
		chosen_attack = {}
	_apply_attack_to_entity(chosen_attack)


# Helper function to send attack data to the entity's get_hit method
func _apply_attack_to_entity(chosen_attack: Dictionary) -> void:
	if spotted_target and spotted_target.has_method("get_hit"):
		var attack_data: Dictionary = {
			"attack": chosen_attack,
			"mobposition": mob.global_position,
			"hit_chance": 100,  # Only used when attacking another mob, not the player
			"source": mob
		}
		spotted_target.get_hit(attack_data)


func stop_attacking():
	print("I stopped attacking")
	attack_timer.stop()
	Transistioned.emit(self, "mobfollow")


func _on_detection_target_spotted(entity):
	spotted_target = entity  # Replace with function body.


func _on_detection_target_lost(_entity):
	stop_attacking()
	spotted_target = null


func _on_attack_cooldown_timeout():
	attack()


# Handle the mob_killed signal
# If the killed mob is the current `spotted_target`, reset the target
func _on_mob_killed(mob_instance: Mob, _killer) -> void:
	if spotted_target and spotted_target == mob_instance:
		# Undo any actions related to the spotted target
		stop_attacking()
		spotted_target = null  # Reset the spotted target
		print("Target reset due to mob being killed.")
