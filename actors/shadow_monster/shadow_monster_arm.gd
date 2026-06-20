class_name ShadowMonsterArm
extends Node2D

var arm_global_position: Vector2 = Vector2.INF

func _physics_process(_delta: float) -> void:
	$Skin.points[1] = $Palm.position
