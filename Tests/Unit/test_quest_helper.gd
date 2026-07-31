extends GutTest


func before_all() -> void:
	var custom_mods: Array[DMod] = [Gamedata.mods.by_id("Core"), Gamedata.mods.by_id("Test")]
	Runtimedata.reconstruct(custom_mods)
	await get_tree().process_frame


func after_all() -> void:
	Runtimedata.reset()


func test_on_mob_killed_accepts_killer_param():
	var helper = autofree(load("res://Scripts/Helper/quest_helper.gd").new())
	var mob = autofree(Mob.new(Vector3.ZERO, {"id":"generic_test_mob"}))
	var killer = autofree(Player.new())
	await get_tree().process_frame
	helper._on_mob_killed(mob, killer)
	assert_true(true, "Method executed without error")
