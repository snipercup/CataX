extends GutTest

var spotlight_scene: PackedScene

func before_each():
	spotlight_scene = load("res://spot_light_3d_main.tscn")

func test_spotlight_defaults():
	var light = spotlight_scene.instantiate()
	assert_true(light is SpotLight3D, "Scene root should be SpotLight3D")
	assert_almost_eq(light.spot_range, 69.881, 0.001)
	assert_almost_eq(light.spot_angle, 47.93, 0.001)
	assert_almost_eq(light.spot_attenuation, -0.63, 0.001)
	await get_tree().process_frame
	light.queue_free()
