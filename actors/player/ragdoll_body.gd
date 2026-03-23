class_name PlayerRagdollBody
extends MoveableRigidBody2D


func _ready() -> void:
	if not debounce_impact_scope:
		debounce_impact_scope = "player"
	super._ready()
