class_name PlayerInputSignalBroker
extends Object


static func try_activate_equipped_item(slot_index: int) -> Signal:
	return SignalFactory.get_signal_with_key(
		"try_activate_equipped_item", slot_index, ["slot_index", TYPE_INT]
	)


# Signal emitted when the run key is toggled
static func run_toggled() -> Signal:
	return SignalFactory.get_signal_with_key("run_toggled", 0, ["is_running", TYPE_BOOL])


# Signal emitted when the interact key is pressed
static func interact() -> Signal:
	return SignalFactory.get_signal_with_key("interact", 0)
