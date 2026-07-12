extends Node2D

@onready var mists: Array[Node2D] = [$Mist, $Mist2, $Mist3, $Mist4]
@export var speeds: Array[float] = [5.0, -6.0, 7.0, -8.0]

func _process(delta: float) -> void:
	for i in range(speeds.size()):
		mists[i].rotation_degrees += delta * speeds[i]
