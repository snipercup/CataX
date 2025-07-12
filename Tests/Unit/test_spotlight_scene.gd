extends GutTest

var spotlight: SpotLight3D

func before_each():
	var scene: PackedScene = preload("res://spot_light_3d_main.tscn")
	spotlight = scene.instantiate()
	add_child(spotlight)
	await get_tree().process_frame

func after_each():
	if spotlight:
	    spotlight.queue_free()
	await get_tree().process_frame

func test_spotlight_parameters():
	assert_eq(spotlight.spot_range, 69.881, "Spot range should match player light")
	assert_eq(spotlight.spot_angle, 47.93, "Spot angle should match player light")
