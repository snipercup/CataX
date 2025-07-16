extends Node
# This class is the single point of control for all input events
# (TODO: move existing input logic from everywhere else to make this statement actually true)
# This class is responsible for listening for input events from the player, and converting them into
# signals usable by the rest of the scene.  This class should have limited knowledge about the current
# game state, merely mapping input to signal

var is_inventory_open: bool
signal run_pressed
signal run_released
signal interact_pressed


func _init():
	Helper.signal_broker.inventory_window_visibility_changed.connect(
		func(inventory: Control): is_inventory_open = inventory.visible
	)


func _process(_delta: float) -> void:
	process_mouse_press()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("run"):
		run_pressed.emit()
	elif event.is_action_released("run"):
		run_released.emit()

	if event.is_action_pressed("interact"):
		interact_pressed.emit()


func process_mouse_press() -> void:
	if is_inventory_open:
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		PlayerInputSignalBroker.try_activate_equipped_item(0).emit(0)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		PlayerInputSignalBroker.try_activate_equipped_item(1).emit(1)
