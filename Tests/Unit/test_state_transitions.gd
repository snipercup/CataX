extends GutTest


func test_follow_to_idle_on_target_lost():
	var state = MobFollow.new()
	state.mob = CharacterBody3D.new()
	var transitioned: Array = []
	state.Transistioned.connect(func(_s, name): transitioned.append(name))
	state._on_detection_target_lost(null)
	assert_eq(
		transitioned[0], "mobidle", "MobFollow should transition to mobidle when target is lost"
	)


func test_attack_to_follow_on_target_lost():
	var state = MobAttack.new()
	state.mob = CharacterBody3D.new()
	state.attack_timer = Timer.new()
	var transitioned: Array = []
	state.Transistioned.connect(func(_s, name): transitioned.append(name))
	state._on_detection_target_lost(null)
	assert_eq(
		transitioned[0], "mobfollow", "MobAttack should transition to mobfollow when target is lost"
	)


func test_ranged_attack_to_follow_on_target_lost():
	var state = MobRangedAttack.new()
	state.mob = CharacterBody3D.new()
	var transitioned: Array = []
	state.Transistioned.connect(func(_s, name): transitioned.append(name))
	state._on_detection_target_lost(null)
	assert_eq(
		transitioned[0],
		"mobfollow",
		"MobRangedAttack should transition to mobfollow when target is lost"
	)
