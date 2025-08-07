extends State
class_name MobTerminate

# This script is an extention of State. It's a state that a mob can be in.
# This is the final state of the mob and it will not transition back to another state
# This is useful to disable the mob before queueing it free
# That's why no code is executed in any meaningful function, so the mob doesn't do anything


func _ready():
	name = "MobTerminate"


func enter():
	print("Entering MobTerminate state")
	# Disable navigation and any other behaviors


func exit():
	pass


func physics_update(_delta: float):
	pass


func _on_detection_target_spotted(_entity):
	pass


func _on_detection_target_lost(_entity):
	pass
