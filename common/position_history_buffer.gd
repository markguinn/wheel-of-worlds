class_name PositionHistoryBuffer
extends Node2D


@export var buffer_points := 100
@export var seconds_of_history := 1.0

var buffer_step: float
var buffer_idx := 0
var distance_traveled := 0.0

# ring buffer of the position of the first bone
var position_history: Array[Vector2] = []
# element i stores the distance between i and i+1 in position_history
var delta_history: Array[float] = []


func _ready() -> void:
	for i in range(buffer_points):
		position_history.append(global_position)
		delta_history.append(0.0)
	buffer_step = seconds_of_history / buffer_points


func _physics_process(delta: float) -> void:
	# fill in the ring buffer and update the bone positions
	# we use the delta here and interpolate between the current position and the last position
	# in order to keep the behavior consistent if the time scale slows
	var delta_idx := ceili(delta / buffer_step)
	var start_pos := position_history[buffer_idx]
	var last_pos := start_pos
	var last_idx := buffer_idx
	for i in range(delta_idx):
		distance_traveled -= delta_history[last_idx]
		var idx := (last_idx + 1) % buffer_points
		var progress := float(i + 1) / float(delta_idx + 1)
		# store the interpolated point (at 1.0 it will be where the node is now, at 0.0
		# where it was at the last physics tick)
		position_history[idx] = lerp(start_pos, global_position, progress)
		# store the distances between points to make calculations faster below, maybe? idk
		# this may be just overoptimization.
		delta_history[last_idx] = last_pos.distance_to(position_history[idx])
		distance_traveled += delta_history[last_idx]
		last_pos = position_history[idx]
		last_idx = idx
		buffer_idx = idx


func get_start() -> Vector2:
	return position_history[(buffer_idx + 1) % buffer_points]

func get_end() -> Vector2:
	return position_history[buffer_idx]

func get_position_diff() -> Vector2:
	return get_end() - get_start()

func get_average_velocity() -> Vector2:
	return get_position_diff() / seconds_of_history
