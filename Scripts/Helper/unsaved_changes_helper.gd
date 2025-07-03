extends Node
class_name UnsavedChangesHelper

var dialog := ConfirmationDialog.new()
var _get_current_data : Callable
var _get_original_data : Callable
var _close_callback : Callable = func(): pass

func _init():
	dialog.dialog_text = "You have unsaved changes. Close without saving?"
	dialog.ok_button_text = "Close"
	dialog.get_cancel_button().text = "Cancel"
	dialog.connect("confirmed", _on_confirmed)
	dialog.connect("canceled", _on_canceled)
	dialog.hide()

func setup(parent: Node, get_current_data: Callable, get_original_data: Callable, close_callback: Callable) -> void:
	_get_current_data = get_current_data
	_get_original_data = get_original_data
	_close_callback = close_callback
	parent.add_child(dialog)

func request_close() -> void:
	if _has_unsaved_changes():
		dialog.popup_centered()
	else:
		_close_callback.call()

func _has_unsaved_changes() -> bool:
	if _get_current_data.is_null() or _get_original_data.is_null():
		return false
	var current = _get_current_data.call()
	var original = _get_original_data.call()
	return JSON.stringify(current) != JSON.stringify(original)

func _on_confirmed() -> void:
	_close_callback.call()

func _on_canceled() -> void:
	pass
