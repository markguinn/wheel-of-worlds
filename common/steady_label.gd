class_name SteadyLabel
extends Label

########################################################
## A label that floats above its parent element even when the 
## parent rotates. Whatever offset from the parent it has when
## it comes in will be maintained and the label will appear to
## have a rotation of 0.
########################################################


var target_offset: Vector2


func _ready() -> void:
	target_offset = position


func _process(_delta: float) -> void:
	if visible:
		rotation = -get_parent().global_rotation
		global_position = get_parent().global_position + target_offset
