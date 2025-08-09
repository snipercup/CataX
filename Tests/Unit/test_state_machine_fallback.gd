extends GutTest


class DummyState:
	extends State
	var spotted_target


func test_invalid_target_falls_back_to_idle() -> void:
	var machine := StateMachine.new()
	var idle := DummyState.new()
	var attack := DummyState.new()
	machine.states = {
		"mobidle": idle,
		"mobattack": attack,
	}
	machine.current_state = idle

	var target := Node3D.new()
	add_child(target)
	idle.spotted_target = target
	target.queue_free()
	await get_tree().process_frame

	machine.on_child_transition(idle, "mobattack")
	assert_eq(machine.current_state, idle, "Should fall back to mobidle when target is invalid")
