class_name PlayerRagdollBody
extends MoveableRigidBody2D


signal entered_kill_zone


func _ready() -> void:
	if not debounce_impact_scope:
		debounce_impact_scope = "player"
	super._ready()
